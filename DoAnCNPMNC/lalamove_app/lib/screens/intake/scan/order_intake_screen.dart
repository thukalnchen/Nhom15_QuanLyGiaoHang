import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../models/order_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/warehouse_provider.dart';
import '../../../utils/constants.dart';

class OrderIntakeScreen extends StatefulWidget {
  final Order order;

  const OrderIntakeScreen({super.key, required this.order});

  @override
  State<OrderIntakeScreen> createState() => _OrderIntakeScreenState();
}

class _OrderIntakeScreenState extends State<OrderIntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedSize;
  String? _selectedType;
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Pre-fill with customer estimates if available
    _selectedSize = widget.order.customerEstimatedSize;
    _selectedType = widget.order.packageType;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tối đa 4 ảnh'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _images.add(image);
      });
    }
  }

  Future<void> _pickFromGallery() async {
    if (_images.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tối đa 4 ảnh'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _images.add(image);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submitReceive() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn kích thước gói hàng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn loại hàng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final warehouseProvider = context.read<WarehouseProvider>();

    if (authProvider.token == null) return;

    // TODO: Upload images to server and get URLs
    // For now, use local paths
    final imagePaths = _images.map((img) => img.path).toList();

    final success = await warehouseProvider.receiveOrder(
      token: authProvider.token!,
      orderId: widget.order.id,
      packageSize: _selectedSize!,
      packageType: _selectedType!,
      weight: double.parse(_weightController.text),
      description: _descriptionController.text.isNotEmpty 
          ? _descriptionController.text 
          : null,
      images: imagePaths,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã nhận đơn hàng thành công'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(warehouseProvider.errorMessage ?? 'Không thể nhận đơn hàng'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final warehouseProvider = context.watch<WarehouseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhận hàng'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.qr_code, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mã đơn hàng',
                                  style: AppTextStyles.bodySmall,
                                ),
                                Text(
                                  widget.order.orderCode,
                                  style: AppTextStyles.heading3,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: AppSpacing.lg),
                      _InfoRow(
                        icon: Icons.person,
                        label: 'Người gửi',
                        value: widget.order.customerName,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.location_on,
                        label: 'Địa chỉ lấy hàng',
                        value: widget.order.pickupAddress,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.place,
                        label: 'Địa chỉ giao hàng',
                        value: widget.order.deliveryAddress,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Customer estimate info (if available)
              if (widget.order.customerEstimatedSize != null || 
                  widget.order.customerRequestedVehicle != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.info.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Ước lượng từ khách hàng',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (widget.order.customerEstimatedSize != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Kích thước: ${PackageSize.getDisplayName(widget.order.customerEstimatedSize!)}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      if (widget.order.customerRequestedVehicle != null)
                        Text(
                          'Xe mong muốn: ${VehicleInfo.getDisplayName(widget.order.customerRequestedVehicle!)}',
                          style: AppTextStyles.bodySmall,
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '💡 Thông tin trên chỉ mang tính tham khảo. Vui lòng xác nhận lại.',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

              if (widget.order.customerEstimatedSize != null || 
                  widget.order.customerRequestedVehicle != null)
                const SizedBox(height: AppSpacing.lg),

              // Package information form
              Text(
                'Thông tin gói hàng',
                style: AppTextStyles.heading3,
              ),

              const SizedBox(height: AppSpacing.md),

              // Package size
              DropdownButtonFormField<String>(
                value: _selectedSize,
                decoration: const InputDecoration(
                  labelText: 'Kích thước gói hàng',
                  prefixIcon: Icon(Icons.straighten),
                ),
                items: PackageSize.getAllSizes().map((size) {
                  return DropdownMenuItem(
                    value: size,
                    child: Text(PackageSize.getDisplayName(size)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSize = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Vui lòng chọn kích thước';
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Package type
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Loại hàng',
                  prefixIcon: Icon(Icons.category),
                ),
                items: PackageType.getAllTypes().map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(PackageType.getIcon(type), size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(PackageType.getDisplayName(type)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Vui lòng chọn loại hàng';
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Weight
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cân nặng (kg)',
                  prefixIcon: Icon(Icons.scale),
                  suffixText: 'kg',
                ),
                validator: Validators.validateWeight,
              ),

              const SizedBox(height: AppSpacing.md),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Photos section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hình ảnh gói hàng (${_images.length}/4)',
                    style: AppTextStyles.heading3,
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt),
                        tooltip: 'Chụp ảnh',
                      ),
                      IconButton(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library),
                        tooltip: 'Chọn từ thư viện',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Image grid
              if (_images.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Image.file(
                            File(_images[index].path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            onPressed: () => _removeImage(index),
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.all(4),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              else
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.greyLight),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_photo_alternate,
                          size: 48,
                          color: AppColors.grey,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Chưa có ảnh',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.xl),

              // Submit button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: warehouseProvider.isLoading ? null : _submitReceive,
                  child: warehouseProvider.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Xác nhận nhận hàng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.grey),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
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
    );
  }
}

