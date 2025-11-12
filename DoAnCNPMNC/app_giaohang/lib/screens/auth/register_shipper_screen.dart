import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class RegisterShipperScreen extends StatefulWidget {
  static const String routeName = '/register-shipper';

  const RegisterShipperScreen({super.key});

  @override
  State<RegisterShipperScreen> createState() => _RegisterShipperScreenState();
}

class _RegisterShipperScreenState extends State<RegisterShipperScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _driverLicenseController = TextEditingController();
  final _identityCardController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedVehicleType = 'motorcycle';
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  final List<Map<String, String>> _vehicleOptions = const [
    {'value': 'motorcycle', 'label': 'Xe máy'},
    {'value': 'car', 'label': 'Ô tô'},
    {'value': 'van', 'label': 'Van nhỏ'},
    {'value': 'truck', 'label': 'Xe tải'},
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _vehiclePlateController.dispose();
    _driverLicenseController.dispose();
    _identityCardController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();
    final success = await auth.registerShipper(
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _fullNameController.text,
      phone: _phoneController.text,
      address: _addressController.text.isEmpty ? null : _addressController.text,
      vehicleType: _selectedVehicleType,
      vehiclePlate: _vehiclePlateController.text,
      driverLicenseNumber: _driverLicenseController.text,
      identityCardNumber: _identityCardController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppTexts.registerSuccessMessage)),
      );
      Navigator.pop(context);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTexts.registerShipperTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Thông tin tài khoản',
                    style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: AppTexts.fullName,
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập họ tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: AppTexts.email,
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: AppTexts.phone,
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập số điện thoại';
                      }
                      if (!RegExp(r'^[0-9]{9,11}$').hasMatch(value.trim())) {
                        return 'Số điện thoại không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ (tùy chọn)',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      labelText: AppTexts.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _hidePassword = !_hidePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value.length < 6) {
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _hideConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_hideConfirmPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _hideConfirmPassword = !_hideConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập lại mật khẩu';
                      }
                      if (value != _passwordController.text) {
                        return 'Mật khẩu không trùng khớp';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Thông tin phương tiện',
                    style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedVehicleType,
                    decoration: const InputDecoration(
                      labelText: AppTexts.vehicleType,
                      prefixIcon: Icon(Icons.two_wheeler_outlined),
                    ),
                    items: _vehicleOptions
                        .map((item) => DropdownMenuItem(
                              value: item['value'],
                              child: Text(item['label']!),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _selectedVehicleType = value;
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _vehiclePlateController,
                    decoration: const InputDecoration(
                      labelText: AppTexts.vehiclePlate,
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập biển số xe';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _driverLicenseController,
                    decoration: const InputDecoration(
                      labelText: AppTexts.driverLicense,
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập số giấy phép lái xe';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _identityCardController,
                    decoration: const InputDecoration(
                      labelText: AppTexts.identityCard,
                      prefixIcon: Icon(Icons.credit_card_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập số CCCD/CMND';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: AppTexts.optionalNotes,
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text(AppTexts.createAccount),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('${AppTexts.haveAccount} ${AppTexts.goToLogin}'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


