import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      _fullNameController.text = authProvider.user!['full_name'] ?? '';
      _phoneController.text = authProvider.user!['phone'] ?? '';
      _addressController.text = authProvider.user!['address'] ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateProfile(
      _fullNameController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
    );

    if (success) {
      Fluttertoast.showToast(
        msg: 'Cập nhật hồ sơ thành công',
        backgroundColor: AppColors.success,
        textColor: Colors.white,
      );
      setState(() {
        _isEditing = false;
      });
    } else {
      Fluttertoast.showToast(
        msg: authProvider.error ?? 'Cập nhật thất bại',
        backgroundColor: AppColors.danger,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTexts.profile),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.user == null) {
            return const Center(
              child: Text('Không tìm thấy thông tin người dùng'),
            );
          }

          final user = authProvider.user!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            (user['full_name'] ?? 'U').substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user['full_name'] ?? 'Người dùng',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user['email'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            user['role'] ?? 'customer',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Profile Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin cá nhân',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _fullNameController,
                            enabled: _isEditing,
                            decoration: const InputDecoration(
                              labelText: 'Họ và tên',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) => AppValidators.required(value, 'Họ và tên'),
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: TextEditingController(text: user['email'] ?? ''),
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _phoneController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Số điện thoại',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            validator: AppValidators.phone,
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _addressController,
                            enabled: _isEditing,
                            decoration: const InputDecoration(
                              labelText: 'Địa chỉ',
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            maxLines: 2,
                          ),
                          
                          if (_isEditing) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = false;
                                      });
                                      _loadUserData(); // Reset form
                                    },
                                    child: const Text(AppTexts.cancel),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Consumer<AuthProvider>(
                                    builder: (context, authProvider, child) {
                                      return ElevatedButton(
                                        onPressed: authProvider.isLoading ? null : _updateProfile,
                                        child: authProvider.isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : const Text(AppTexts.save),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Account Actions
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.history, color: AppColors.primary),
                        title: const Text('Lịch sử đơn hàng'),
                        subtitle: const Text('Xem tất cả đơn hàng đã đặt'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.pushNamed(context, '/orders');
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help_outline, color: AppColors.warning),
                        title: const Text('Trợ giúp'),
                        subtitle: const Text('Câu hỏi thường gặp và hỗ trợ'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Fluttertoast.showToast(
                            msg: 'Tính năng trợ giúp sẽ được thêm sau',
                            backgroundColor: AppColors.warning,
                            textColor: Colors.white,
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline, color: AppColors.grey),
                        title: const Text('Về ứng dụng'),
                        subtitle: const Text('Thông tin phiên bản và nhà phát triển'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: AppTexts.appName,
                            applicationVersion: '1.0.0',
                            applicationLegalese: '© 2024 Food Delivery App',
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout, color: AppColors.danger),
                        title: const Text(AppTexts.logout),
                        subtitle: const Text('Đăng xuất khỏi tài khoản'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

