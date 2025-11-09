import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/notification_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _orderNotifications = true;
  bool _paymentNotifications = true;
  bool _driverNotifications = true;
  bool _systemNotifications = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
      ),
      body: ListView(
        children: [
          _buildSection(
            'Thông báo đẩy',
            [
              _buildSwitchTile(
                'Bật thông báo đẩy',
                'Nhận thông báo khi có sự kiện mới',
                _pushNotifications,
                (value) async {
                  setState(() => _pushNotifications = value);
                  if (value) {
                    final provider = Provider.of<NotificationProvider>(context, listen: false);
                    await provider.requestPermission();
                  }
                },
              ),
            ],
          ),
          const Divider(height: 32),
          _buildSection(
            'Loại thông báo',
            [
              _buildSwitchTile(
                'Đơn hàng',
                'Cập nhật trạng thái đơn hàng',
                _orderNotifications,
                (value) => setState(() => _orderNotifications = value),
              ),
              _buildSwitchTile(
                'Thanh toán',
                'Thông báo về giao dịch thanh toán',
                _paymentNotifications,
                (value) => setState(() => _paymentNotifications = value),
              ),
              _buildSwitchTile(
                'Tài xế',
                'Cập nhật về tài xế giao hàng',
                _driverNotifications,
                (value) => setState(() => _driverNotifications = value),
              ),
              _buildSwitchTile(
                'Hệ thống',
                'Thông báo từ hệ thống',
                _systemNotifications,
                (value) => setState(() => _systemNotifications = value),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildSection(
            'Kênh thông báo',
            [
              _buildSwitchTile(
                'Email',
                'Nhận thông báo qua email',
                _emailNotifications,
                (value) => setState(() => _emailNotifications = value),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildSection(
            'Thao tác',
            [
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.red),
                title: const Text('Xóa tất cả thông báo'),
                subtitle: const Text('Xóa tất cả thông báo đã đọc'),
                onTap: _showDeleteAllDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF26522),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Lưu cài đặt', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF26522),
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFFF26522),
    );
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa tất cả thông báo đã đọc?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<NotificationProvider>(context, listen: false);
              // TODO: Implement delete all read notifications
              await provider.fetchNotifications(); // Refresh
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa tất cả thông báo đã đọc')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    // TODO: Save notification settings to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu cài đặt thông báo')),
    );
    Navigator.pop(context);
  }
}
