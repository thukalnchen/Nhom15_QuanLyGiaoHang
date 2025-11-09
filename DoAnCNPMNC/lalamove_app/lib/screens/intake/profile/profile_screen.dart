import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/constants.dart';
import '../../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'N',
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.white,
                  fontSize: 36,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // User info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    label: 'Họ và tên',
                    value: user?.name ?? '',
                    icon: Icons.person,
                  ),
                  const Divider(),
                  _InfoRow(
                    label: 'Email',
                    value: user?.email ?? '',
                    icon: Icons.email,
                  ),
                  const Divider(),
                  _InfoRow(
                    label: 'Số điện thoại',
                    value: user?.phone ?? '',
                    icon: Icons.phone,
                  ),
                  const Divider(),
                  _InfoRow(
                    label: 'Vai trò',
                    value: 'Nhân viên nhận hàng',
                    icon: Icons.work,
                  ),
                  if (user?.warehouseName != null) ...[
                    const Divider(),
                    _InfoRow(
                      label: 'Kho',
                      value: user!.warehouseName!,
                      icon: Icons.warehouse,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Actions
          ListTile(
            leading: const Icon(Icons.lock, color: AppColors.primary),
            title: const Text('Đổi mật khẩu'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to change password screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng đang phát triển')),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.primary),
            title: const Text('Cập nhật thông tin'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to update profile screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng đang phát triển')),
              );
            },
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Logout button
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Version info
          Center(
            child: Text(
              'Version ${AppConfig.appVersion}',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

