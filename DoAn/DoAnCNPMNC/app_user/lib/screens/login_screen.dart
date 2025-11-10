import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';
import '../utils/validation_utils.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false; // Tracks "Ghi nhớ đăng nhập" checkbox
  bool _isFormFilled = false; // Controls login button enabled state
  int _failedAttempts = 0; // Số lần đăng nhập thất bại
  DateTime? _lastFailedAttempt; // Thời gian lần thử thất bại cuối cùng
  bool _isAccountLocked = false; // Trạng thái khóa tài khoản

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Rebuild when users type to toggle the disabled/enabled state of the button.
    _emailController.addListener(_updateFormFilledState);
    _passwordController.addListener(_updateFormFilledState);
    _loadRememberedLogin();
  }

  Future<void> _loadRememberedLogin() async {
    final remember = await AuthService.getRememberMePreference();
    final rememberedEmail = remember ? await AuthService.getRememberedEmail() : null;

    if (remember && rememberedEmail != null && rememberedEmail.isNotEmpty) {
      _emailController.text = rememberedEmail;
    }

    if (!mounted) return;

    setState(() {
      _rememberMe = remember;
    });
  }

  void _updateFormFilledState() {
    final filled = _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;
    if (filled != _isFormFilled) {
      setState(() {
        _isFormFilled = filled;
      });
    }
  }

  /// Kiểm tra xem tài khoản có bị khóa không
  bool _checkAccountLocked() {
    if (!_isAccountLocked) {
      return false;
    }

    // Nếu đã qua 15 phút kể từ lần thử thất bại cuối, reset
    if (_lastFailedAttempt != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastFailedAttempt!);
      if (difference.inMinutes >= 15) {
        setState(() {
          _isAccountLocked = false;
          _failedAttempts = 0;
          _lastFailedAttempt = null;
        });
        return false;
      } else {
        final remainingMinutes = 15 - difference.inMinutes;
        return true;
      }
    }
    return false;
  }

  /// Ghi nhận lần đăng nhập thất bại
  void _recordFailedAttempt() {
    setState(() {
      _failedAttempts++;
      _lastFailedAttempt = DateTime.now();
      
      // Khóa tài khoản sau 5 lần thử thất bại
      if (_failedAttempts >= 5) {
        _isAccountLocked = true;
      }
    });
  }

  /// Reset số lần thử thất bại khi đăng nhập thành công
  void _resetFailedAttempts() {
    setState(() {
      _failedAttempts = 0;
      _lastFailedAttempt = null;
      _isAccountLocked = false;
    });
  }

  Future<void> _login() async {
    // Kiểm tra tài khoản có bị khóa không
    if (_checkAccountLocked()) {
      final now = DateTime.now();
      final difference = now.difference(_lastFailedAttempt!);
      final remainingMinutes = 15 - difference.inMinutes;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tài khoản đã bị khóa tạm thời do nhiều lần đăng nhập sai. Vui lòng thử lại sau $remainingMinutes phút.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await AuthService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );

        // Đăng nhập thành công - reset số lần thử thất bại
        _resetFailedAttempts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng nhập thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (e) {
        // Ghi nhận lần đăng nhập thất bại
        _recordFailedAttempt();
        
        if (mounted) {
          String errorMessage = 'Đăng nhập thất bại: ${e.toString()}';
          
          // Hiển thị cảnh báo nếu còn ít lần thử
          if (_failedAttempts >= 3 && _failedAttempts < 5) {
            final remainingAttempts = 5 - _failedAttempts;
            errorMessage += '\nCòn $remainingAttempts lần thử trước khi tài khoản bị khóa.';
          } else if (_failedAttempts >= 5) {
            errorMessage = 'Tài khoản đã bị khóa tạm thời do nhiều lần đăng nhập sai. Vui lòng thử lại sau 15 phút.';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: _failedAttempts >= 5 ? Colors.orange : Colors.red,
              duration: Duration(seconds: _failedAttempts >= 5 ? 5 : 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildHeroSection(bool isWide) {
    const primaryRed = AppTheme.primaryColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.local_shipping, color: primaryRed, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'J&T EXPRESS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: primaryRed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Giao nhận nhanh chóng,\ntrải nghiệm mượt mà.',
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.25,
            color: Color(0xFF181818),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Đăng nhập để theo dõi đơn hàng, đặt dịch vụ và tận hưởng các ưu đãi dành riêng cho bạn.',
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.black.withOpacity(0.6),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 32),
        AspectRatio(
          aspectRatio: isWide ? 4 / 3 : 16 / 11,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFCDD2),
                  Color(0xFFFFF1F2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(0, 12),
                  blurRadius: 32,
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: isWide ? 24 : 12,
                  bottom: 24,
                  right: isWide ? null : 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Tiết kiệm thời gian',
                        style: TextStyle(
                          color: primaryRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Theo dõi hành trình đơn hàng realtime\nvà dịch vụ giao nhận toàn quốc.',
                        style: TextStyle(
                          color: Color(0xFF3E3E3E),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: isWide ? 12 : 0,
                  bottom: 0,
                  top: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(26),
                      bottomRight: Radius.circular(26),
                    ),
                    child: Image.network(
                      'https://cdn.jtexpress.vn/themes/7/img/banner-hero.png',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      },
                      errorBuilder: (context, _, __) {
                        return const Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 92,
                            color: primaryRed,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context, double maxWidth) {
    final bool isLocked = _isAccountLocked && _lastFailedAttempt != null;
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 20),
            blurRadius: 45,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Đăng nhập',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                  ) ??
                  const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đăng nhập bằng email đã đăng ký',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                hint: 'Nhập email của bạn',
                icon: Icons.person_outline,
              ),
              validator: ValidationUtils.validateEmail,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _inputDecoration(
                hint: 'Nhập mật khẩu',
                icon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF7A7A7A),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox.adaptive(
                  value: _rememberMe,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (v) {
                    final newValue = v ?? false;
                    setState(() {
                      _rememberMe = newValue;
                    });
                    AuthService.setRememberMePreference(
                      newValue,
                      email: newValue ? _emailController.text.trim() : null,
                    );
                  },
                ),
                const Text(
                  'Ghi nhớ đăng nhập',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng Quên mật khẩu đang được phát triển')),
                    );
                  },
                  child: const Text(
                    'Quên mật khẩu',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (_failedAttempts > 0 && _failedAttempts < 5)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFA726)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA726), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bạn đã thử đăng nhập sai $_failedAttempts lần. Còn ${5 - _failedAttempts} lần thử.',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEE8F00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (isLocked)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE57373)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, color: Color(0xFFE53935), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tài khoản đã bị khóa tạm thời. Vui lòng thử lại sau 15 phút.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: (_isLoading || !_isFormFilled || _isAccountLocked) ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isAccountLocked ? 'Tài khoản đã bị khóa' : 'Đăng nhập',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
              child: const Text.rich(
                TextSpan(
                  text: 'Bạn chưa có tài khoản? ',
                  style: TextStyle(
                    color: Color(0xFF6B6B6B),
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: 'Đăng ký',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9C9C9C),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.only(left: 14, right: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE9EC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 22),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 54, minHeight: 54),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFFDFDFD),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFFFCDD2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFFFCDD2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppTheme.primaryColor,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE53935)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF5F5),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 960;
              final bool isTablet = constraints.maxWidth >= 640 && constraints.maxWidth < 960;
              final EdgeInsets pagePadding = EdgeInsets.symmetric(
                horizontal: isWide ? 72 : (isTablet ? 40 : 20),
                vertical: isWide ? 40 : 24,
              );

              return Center(
                child: SingleChildScrollView(
                  padding: pagePadding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 1100 : (isTablet ? 720 : double.infinity),
                    ),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 36),
                                  child: _buildHeroSection(true),
                                ),
                              ),
                              Expanded(
                                child: _buildFormCard(context, 460),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHeroSection(false),
                              const SizedBox(height: 36),
                              _buildFormCard(context, double.infinity),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

