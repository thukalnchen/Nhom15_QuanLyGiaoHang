import 'dart:async';

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/location.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../utils/validation_utils.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();

  List<Province> _provinces = <Province>[];
  Province? _selectedProvince;
  District? _selectedDistrict;
  Ward? _selectedWard;
  bool _isLocationLoading = false;
  String? _locationError;
  String _manualAddressPrefix = '';
  bool _isUpdatingAddressText = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreePolicy = false; // Checkbox: Tôi đã đọc và đồng ý...
  bool _isFormFilled = false; // Controls "Hoàn tất" enabled state
  Map<String, dynamic> _passwordStrength = {}; // Password strength analysis
  String? _addressError; // Address validation error

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Update enabled state when any field changes
    _emailController.addListener(_updateFormFilledState);
    _passwordController.addListener(_updatePasswordStrength);
    _passwordController.addListener(_updateFormFilledState);
    _confirmPasswordController.addListener(_updateFormFilledState);
    _phoneController.addListener(_updateFormFilledState);
    _fullNameController.addListener(_updateFormFilledState);
    _addressController.addListener(_handleAddressTextChanged);
    _addressController.addListener(_validateAddress);
    _loadLocationData();
  }

  /// Validate address in real-time
  void _validateAddress() {
    final error = ValidationUtils.validateAddress(_addressController.text.trim());
    if (error != _addressError) {
      setState(() {
        _addressError = error;
      });
    }
  }

  /// Cập nhật phân tích độ mạnh mật khẩu khi người dùng nhập
  void _updatePasswordStrength() {
    final password = _passwordController.text;
    if (password.isNotEmpty) {
      setState(() {
        _passwordStrength = ValidationUtils.analyzePasswordStrength(password);
      });
    } else {
      setState(() {
        _passwordStrength = {};
      });
    }
  }

  void _updateFormFilledState() {
    final filled = _fullNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _addressController.text.isNotEmpty &&
        _agreePolicy;
    if (filled != _isFormFilled) {
      setState(() {
        _isFormFilled = filled;
      });
    }
  }

  /// Keeps track of the free-form street portion so that we can re-append it
  /// after the user selects a ward/district/province suggestion.
  void _handleAddressTextChanged() {
    if (_isUpdatingAddressText) {
      return;
    }
    _manualAddressPrefix = _extractStreetPrefix();
  }

  /// Loads the province/district/ward dataset from the remote open API.
  /// The data is cached by [LocationService] but we track the loading state
  /// here to surface progress and retry messages in the UI.
  Future<void> _loadLocationData() async {
    setState(() {
      _isLocationLoading = true;
      _locationError = null;
    });

    try {
      await LocationService.ensureInitialized();
      final provinces = await LocationService.getAllProvinces();
      if (!mounted) {
        return;
      }
      setState(() {
        _provinces = provinces;
        _locationError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _locationError = 'Không thể tải dữ liệu địa chỉ. Vui lòng kiểm tra kết nối và thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  /// Synchronizes every location-related controller when the user taps an
  /// address suggestion and then rebuilds the combined address string.
  void _applyAddressSuggestion(AddressSuggestion suggestion) {
    setState(() {
      _selectedProvince = suggestion.province;
      _provinceController.text = suggestion.province.nameWithType;
      _selectedDistrict = suggestion.district;
      _districtController.text = suggestion.district.nameWithType;
      _selectedWard = suggestion.ward;
      _wardController.text = suggestion.ward.nameWithType;
    });
    _updateAddressField();
  }

  /// Combines the manually typed street prefix (if any) with the currently
  /// selected ward/district/province and pushes the result into the text field.
  void _updateAddressField() {
    final suffix = _buildLocationSuffix();
    final prefix = _manualAddressPrefix.trim();
    final buffer = StringBuffer();
    if (prefix.isNotEmpty) {
      buffer.write(prefix);
      if (suffix.isNotEmpty) {
        buffer.write(', ');
      }
    }
    if (suffix.isNotEmpty) {
      buffer.write(suffix);
    }

    _isUpdatingAddressText = true;
    final newText = buffer.toString();
    _addressController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    _isUpdatingAddressText = false;
  }

  /// Generates the location suffix string used inside the main address field.
  String _buildLocationSuffix() {
    final segments = <String>[];
    if (_selectedWard != null) {
      segments.add(_selectedWard!.nameWithType);
    }
    if (_selectedDistrict != null) {
      segments.add(_selectedDistrict!.nameWithType);
    }
    if (_selectedProvince != null) {
      segments.add(_selectedProvince!.nameWithType);
    }
    return segments.join(', ');
  }

  /// Extracts the part of the address string that does not belong to the
  /// administrative suffix. This allows users to prepend street/house numbers
  /// while still benefiting from autocomplete.
  String _extractStreetPrefix({String? source, String? suffixOverride}) {
    final text = (source ?? _addressController.text).trim();
    if (text.isEmpty) {
      return '';
    }

    final suffix = (suffixOverride ?? _buildLocationSuffix()).trim();
    if (suffix.isEmpty) {
      return text.replaceAll(RegExp(r',\s*$'), '').trim();
    }

    final lowerText = text.toLowerCase();
    final lowerSuffix = suffix.toLowerCase();
    final index = lowerText.indexOf(lowerSuffix);
    if (index == -1) {
      return text.replaceAll(RegExp(r',\s*$'), '').trim();
    }

    final prefix = text.substring(0, index);
    return prefix.replaceAll(RegExp(r',\s*$'), '').trim();
  }

  /// Returns the province that owns the provided [code].
  Province? _getProvinceByCode(int code) {
    for (final province in _provinces) {
      if (province.code == code) {
        return province;
      }
    }
    return null;
  }

  /// Returns the district by [code]. When [provinceCode] is supplied the lookup
  /// is limited to that province for efficiency.
  District? _getDistrictByCode(int code, {int? provinceCode}) {
    if (provinceCode != null) {
      final province = _getProvinceByCode(provinceCode);
      if (province == null) {
        return null;
      }
      for (final district in province.districts) {
        if (district.code == code) {
          return district;
        }
      }
      return null;
    }

    for (final province in _provinces) {
      for (final district in province.districts) {
        if (district.code == code) {
          return district;
        }
      }
    }
    return null;
  }

  /// Builds an [InputDecoration] with the consistent styling used on the screen.
  InputDecoration _buildFilledInputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
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
        child: Icon(prefixIcon, color: AppTheme.primaryColor, size: 22),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 54, minHeight: 54),
      suffixIcon: suffixIcon,
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

  /// Xây dựng widget hiển thị độ mạnh mật khẩu
  Widget _buildPasswordStrengthIndicator() {
    if (_passwordStrength.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = _passwordStrength['strength'] as PasswordStrength;
    final score = _passwordStrength['score'] as int;
    final missingRequirements = _passwordStrength['missingRequirements'] as List<String>;

    Color strengthColor;
    String strengthText;
    double strengthPercent;

    switch (strength) {
      case PasswordStrength.weak:
        strengthColor = Colors.red;
        strengthText = 'Yếu';
        strengthPercent = 0.25;
        break;
      case PasswordStrength.medium:
        strengthColor = Colors.orange;
        strengthText = 'Trung bình';
        strengthPercent = 0.5;
        break;
      case PasswordStrength.strong:
        strengthColor = Colors.lightGreen;
        strengthText = 'Mạnh';
        strengthPercent = 0.75;
        break;
      case PasswordStrength.veryStrong:
        strengthColor = Colors.green;
        strengthText = 'Rất mạnh';
        strengthPercent = 1.0;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: strengthPercent,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                strengthText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: strengthColor,
                ),
              ),
            ],
          ),
          if (missingRequirements.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Cần thêm: ${missingRequirements.join(', ')}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  /// Xây dựng item hiển thị yêu cầu mật khẩu
  Widget _buildRequirementItem(String text, bool isPlaceholder) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    // Validate address separately since _AsyncAutocompleteField doesn't support validator
    final addressError = ValidationUtils.validateAddress(_addressController.text.trim());
    if (addressError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(addressError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate form
    if (_formKey.currentState!.validate()) {
      // Kiểm tra password strength một lần nữa trước khi đăng ký
      final passwordAnalysis = ValidationUtils.analyzePasswordStrength(_passwordController.text);
      if (!passwordAnalysis['isValid'] as bool) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mật khẩu chưa đủ mạnh. Vui lòng kiểm tra lại các yêu cầu.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Gọi API đăng ký
        await AuthService.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
        );

        // Hiển thị thông báo đăng ký thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Điều hướng đến trang đăng nhập sau khi đăng ký thành công
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đăng ký thất bại: ${e.toString()}'),
              backgroundColor: Colors.red,
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
    final crossAxis = isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = isWide ? TextAlign.left : TextAlign.center;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxis,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(0, 10),
                    blurRadius: 26,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.local_shipping_outlined, color: primaryRed, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'J&T EXPRESS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: primaryRed,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          'Sẵn sàng tăng tốc đơn hàng cùng J&T',
          textAlign: textAlign,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Đăng ký ngay để quản lý đơn hàng, nhận ưu đãi dành riêng cho doanh nghiệp và cá nhân.',
          textAlign: textAlign,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Colors.black.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 32),
        AspectRatio(
          aspectRatio: isWide ? 4 / 3 : 16 / 11,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFCDD2),
                  Color(0xFFFFF0F2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(0, 16),
                  blurRadius: 36,
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: isWide ? 28 : 18,
                  top: 28,
                  right: isWide ? null : 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        '30.000+ DOANH NGHIỆP TIN DÙNG',
                        style: TextStyle(
                          color: primaryRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Hệ thống quản lý đơn hàng thông minh,\nđồng bộ dữ liệu và đối soát chính xác.',
                        style: TextStyle(
                          color: Color(0xFF3E3E3E),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  top: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    child: Image.network(
                      'https://cdn.jtexpress.vn/themes/7/img/banner-hero.png',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, _, __) {
                        return const Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: primaryRed,
                            size: 96,
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

  Widget _buildFormContainer(BuildContext context, double maxWidth) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 24),
            blurRadius: 48,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            TextFormField(
              controller: _fullNameController,
              decoration: _buildFilledInputDecoration(
                hint: 'Họ và tên (hoặc tên cửa hàng)',
                prefixIcon: Icons.person_outline,
              ),
              validator: ValidationUtils.validateFullName,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _buildFilledInputDecoration(
                hint: 'Nhập email',
                prefixIcon: Icons.email_outlined,
              ),
              validator: ValidationUtils.validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _buildFilledInputDecoration(
                hint: 'Số điện thoại (bắt đầu bằng 0)',
                prefixIcon: Icons.phone_outlined,
              ),
              validator: ValidationUtils.validatePhone,
            ),
            const SizedBox(height: 16),
            _AsyncAutocompleteField<Province>(
              controller: _provinceController,
              hintText: 'Tỉnh/ Thành phố',
              prefixIcon: Icons.location_city_outlined,
              noResultsText: 'Không tìm thấy tỉnh/thành phố phù hợp',
              fetchSuggestions: LocationService.searchProvinces,
              itemBuilder: (context, province) {
                return ListTile(
                  title: Text(province.nameWithType),
                  subtitle: province.nameWithType == province.name ? null : Text(province.name),
                );
              },
              onSelected: (province) {
                setState(() {
                  _selectedProvince = province;
                  _provinceController.text = province.nameWithType;
                  if (_selectedDistrict != null && _selectedDistrict!.provinceCode != province.code) {
                    _selectedDistrict = null;
                    _districtController.clear();
                  }
                  _selectedWard = null;
                  _wardController.clear();
                });
                _updateAddressField();
              },
            ),
            const SizedBox(height: 16),
            _AsyncAutocompleteField<District>(
              controller: _districtController,
              hintText: 'Quận/ Huyện',
              prefixIcon: Icons.map_outlined,
              noResultsText: 'Không tìm thấy quận/huyện phù hợp',
              fetchSuggestions: (pattern) {
                return LocationService.searchDistricts(
                  pattern,
                  provinceCode: _selectedProvince?.code,
                );
              },
              itemBuilder: (context, district) {
                return ListTile(
                  title: Text(district.nameWithType),
                  subtitle: Text(district.provinceNameWithType),
                );
              },
              onSelected: (district) {
                final province = _getProvinceByCode(district.provinceCode);
                setState(() {
                  if (province != null) {
                    _selectedProvince = province;
                    _provinceController.text = province.nameWithType;
                  }
                  _selectedDistrict = district;
                  _districtController.text = district.nameWithType;
                  if (_selectedWard != null && _selectedWard!.districtCode != district.code) {
                    _selectedWard = null;
                    _wardController.clear();
                  }
                });
                _updateAddressField();
              },
            ),
            const SizedBox(height: 16),
            _AsyncAutocompleteField<Ward>(
              controller: _wardController,
              hintText: 'Phường/ Xã',
              prefixIcon: Icons.location_on_outlined,
              noResultsText: 'Không tìm thấy phường/xã phù hợp',
              fetchSuggestions: (pattern) {
                return LocationService.searchWards(
                  pattern,
                  provinceCode: _selectedProvince?.code,
                  districtCode: _selectedDistrict?.code,
                );
              },
              itemBuilder: (context, ward) {
                return ListTile(
                  title: Text(ward.nameWithType),
                  subtitle: Text('${ward.districtNameWithType}, ${ward.provinceNameWithType}'),
                );
              },
              onSelected: (ward) {
                final province = _getProvinceByCode(ward.provinceCode);
                final district = _getDistrictByCode(
                  ward.districtCode,
                  provinceCode: ward.provinceCode,
                );

                setState(() {
                  if (province != null) {
                    _selectedProvince = province;
                    _provinceController.text = province.nameWithType;
                  }
                  if (district != null) {
                    _selectedDistrict = district;
                    _districtController.text = district.nameWithType;
                  }
                  _selectedWard = ward;
                  _wardController.text = ward.nameWithType;
                });
                _updateAddressField();
              },
            ),
            const SizedBox(height: 16),
            _AsyncAutocompleteField<AddressSuggestion>(
              controller: _addressController,
              hintText: 'Địa chỉ (Số nhà, toà nhà, tên đường...)',
              prefixIcon: Icons.home_outlined,
              suffixIcon: _isLocationLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              maxLines: 2,
              noResultsText: 'Không tìm thấy địa điểm phù hợp',
              showNoResultsMessage: false,
              fetchSuggestions: (pattern) {
                return LocationService.searchAddressSuggestions(
                  pattern,
                  provinceCode: _selectedProvince?.code,
                  districtCode: _selectedDistrict?.code,
                );
              },
              itemBuilder: (context, suggestion) {
                final secondaryText = suggestion.ward.path.isNotEmpty
                    ? suggestion.ward.path
                    : '${suggestion.district.nameWithType}, ${suggestion.province.nameWithType}';
                return ListTile(
                  title: Text(suggestion.displayText),
                  subtitle: Text(secondaryText),
                );
              },
              onSelected: (suggestion) {
                final currentText = _addressController.text.trim();
                final existingSuffix = _buildLocationSuffix();
                if (existingSuffix.isNotEmpty && currentText.endsWith(existingSuffix)) {
                  final prefixEnd = currentText.length - existingSuffix.length;
                  _manualAddressPrefix =
                      currentText.substring(0, prefixEnd).replaceAll(RegExp(r',\s*$'), '').trim();
                } else {
                  _manualAddressPrefix = currentText.replaceAll(RegExp(r',\s*$'), '').trim();
                }
                _applyAddressSuggestion(suggestion);
              },
            ),
            if (_addressError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: Text(
                  _addressError!,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            if (_locationError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _locationError!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadLocationData,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _buildFilledInputDecoration(
                hint: 'Mật khẩu mới',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
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
              validator: (value) => ValidationUtils.validatePassword(value, showDetailedError: true),
            ),
            if (_passwordStrength.isNotEmpty) _buildPasswordStrengthIndicator(),
            if (_passwordController.text.isEmpty ||
                (_passwordStrength.isNotEmpty &&
                 (_passwordStrength['strength'] == PasswordStrength.weak ||
                  _passwordStrength['strength'] == PasswordStrength.medium)))
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mật khẩu phải chứa:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    _buildRequirementItem('Ít nhất 8 ký tự', true),
                    _buildRequirementItem('Chữ hoa (A-Z)', true),
                    _buildRequirementItem('Chữ thường (a-z)', true),
                    _buildRequirementItem('Số (0-9)', true),
                    _buildRequirementItem('Ký tự đặc biệt (!@#\$%^&*)', true),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: _buildFilledInputDecoration(
                hint: 'Xác nhận mật khẩu',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF7A7A7A),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              validator: (value) => ValidationUtils.validateConfirmPassword(value, _passwordController.text),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: _agreePolicy,
                  onChanged: (v) {
                    setState(() {
                      _agreePolicy = v ?? false;
                    });
                    _updateFormFilledState();
                  },
                ),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.black87),
                      children: [
                        TextSpan(text: 'Tôi đã đọc và đồng ý với '),
                        TextSpan(
                          text: 'Chính sách bảo mật thông tin',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: (_isLoading || !_isFormFilled) ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  disabledBackgroundColor: const Color(0xFFE0E0E0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                    : const Text(
                        'Hoàn tất',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: const Text(
                'Đã có tài khoản? Đăng nhập',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
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
              final bool isWide = constraints.maxWidth >= 1024;
              final bool isTablet = constraints.maxWidth >= 720 && constraints.maxWidth < 1024;
              final EdgeInsets pagePadding = EdgeInsets.symmetric(
                horizontal: isWide ? 72 : (isTablet ? 44 : 20),
                vertical: isWide ? 40 : 24,
              );

              return Center(
                child: SingleChildScrollView(
                  padding: pagePadding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 1230 : (isTablet ? 860 : double.infinity),
                    ),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 48),
                                  child: _buildHeroSection(true),
                                ),
                              ),
                              Expanded(
                                child: _buildFormContainer(context, 580),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHeroSection(false),
                              const SizedBox(height: 36),
                              _buildFormContainer(context, double.infinity),
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


/// Lightweight async autocomplete widget that mimics the behaviour of
/// `TypeAheadFormField` without external dependencies. It fetches suggestions
/// using the provided asynchronous callback and renders them inside an overlay
/// anchored to the text field.
class _AsyncAutocompleteField<T> extends StatefulWidget {
  const _AsyncAutocompleteField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.fetchSuggestions,
    required this.itemBuilder,
    required this.onSelected,
    this.noResultsText = 'Không có dữ liệu phù hợp',
    this.showNoResultsMessage = true,
    this.suffixIcon,
    this.maxLines = 1,
    this.debounceDuration = const Duration(milliseconds: 250),
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final Future<List<T>> Function(String query) fetchSuggestions;
  final Widget Function(BuildContext context, T option) itemBuilder;
  final ValueChanged<T> onSelected;
  final String noResultsText;
  final bool showNoResultsMessage;
  final int maxLines;
  final Duration debounceDuration;

  @override
  State<_AsyncAutocompleteField<T>> createState() => _AsyncAutocompleteFieldState<T>();
}

class _AsyncAutocompleteFieldState<T> extends State<_AsyncAutocompleteField<T>> {
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  List<T> _suggestions = <T>[];
  bool _isLoading = false;
  int _requestId = 0;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Delay ẩn suggestions để user có thể click vào item
        // Delay đủ lâu để tap event được xử lý
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_focusNode.hasFocus && _showSuggestions) {
            setState(() {
              _showSuggestions = false;
            });
          }
        });
      } else {
        // Hiển thị suggestions ngay khi có focus
        if (!_showSuggestions) {
          setState(() {
            _showSuggestions = true;
          });
        }
        _triggerFetch();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _AsyncAutocompleteField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.controller.removeListener(_handleTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (!_focusNode.hasFocus) {
      return;
    }
    _triggerFetch();
  }

  void _triggerFetch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () async {
      final query = widget.controller.text;
      final currentId = ++_requestId;

      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
        _showSuggestions = _focusNode.hasFocus;
      });

      try {
        final results = await widget.fetchSuggestions(query);
        if (!mounted || currentId != _requestId) {
          return;
        }
        setState(() {
          _suggestions = results;
          _isLoading = false;
          _showSuggestions = _focusNode.hasFocus &&
              (results.isNotEmpty || (widget.showNoResultsMessage && query.isNotEmpty));
        });
      } catch (_) {
        if (!mounted || currentId != _requestId) {
          return;
        }
        setState(() {
          _suggestions = <T>[];
          _isLoading = false;
        });
      }
    });
  }

  void _handleOptionSelected(T option) {
    // Ẩn suggestions ngay lập tức
    setState(() {
      _showSuggestions = false;
    });
    // Gọi callback để cập nhật dữ liệu
    widget.onSelected(option);
    // Không unfocus ngay, để user có thể tiếp tục chỉnh sửa nếu cần
    // Focus sẽ tự mất khi user click vào chỗ khác
  }

  Widget _buildSuggestionsList() {
    if (!_showSuggestions) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      if (!widget.showNoResultsMessage) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(widget.noResultsText),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: _suggestions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final option = _suggestions[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleOptionSelected(option),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(index == 0 ? 12 : 0),
                bottom: Radius.circular(index == _suggestions.length - 1 ? 12 : 0),
              ),
              child: widget.itemBuilder(context, option),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hintText,
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
              child: Icon(widget.prefixIcon, color: AppTheme.primaryColor, size: 22),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 54, minHeight: 54),
            suffixIcon: widget.suffixIcon,
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
          ),
        ),
        _buildSuggestionsList(),
      ],
    );
  }
}

