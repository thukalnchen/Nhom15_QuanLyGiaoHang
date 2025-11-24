import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../providers/complaint_provider.dart';
import '../../../providers/auth_provider.dart';

class CreateComplaintScreen extends StatefulWidget {
  final int orderId;
  final String orderCode;

  const CreateComplaintScreen({
    Key? key,
    required this.orderId,
    required this.orderCode,
  }) : super(key: key);

  @override
  State<CreateComplaintScreen> createState() => _CreateComplaintScreenState();
}

class _CreateComplaintScreenState extends State<CreateComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'delivery_issue';
  String _selectedPriority = 'medium';
  List<File> _selectedImages = [];
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _complaintTypes = [
    {'value': 'delivery_issue', 'label': 'Vấn đề giao hàng', 'icon': Icons.local_shipping},
    {'value': 'product_issue', 'label': 'Vấn đề hàng hóa', 'icon': Icons.inventory},
    {'value': 'driver_issue', 'label': 'Vấn đề tài xế', 'icon': Icons.person},
    {'value': 'payment_issue', 'label': 'Vấn đề thanh toán', 'icon': Icons.payment},
    {'value': 'service_issue', 'label': 'Vấn đề dịch vụ', 'icon': Icons.support_agent},
    {'value': 'other', 'label': 'Khác', 'icon': Icons.help_outline},
  ];

  final List<Map<String, String>> _priorities = [
    {'value': 'low', 'label': 'Thấp', 'color': '4CAF50'},
    {'value': 'medium', 'label': 'Trung bình', 'color': 'FF9800'},
    {'value': 'high', 'label': 'Cao', 'color': 'FF5722'},
    {'value': 'urgent', 'label': 'Khẩn cấp', 'color': 'F44336'},
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa 4 ảnh')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null) {
      setState(() {
        for (var image in images) {
          if (_selectedImages.length < 4) {
            _selectedImages.add(File(image.path));
          }
        }
      });
    }
  }

  Future<void> _takePicture() async {
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa 4 ảnh')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _selectedImages.add(File(photo.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final token = authProvider.token ?? '';
      if (token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phiên đăng nhập đã hết hạn'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }
      
      final success = await complaintProvider.createComplaint(
        orderId: widget.orderId,
        complaintType: _selectedType,
        subject: _subjectController.text,
        description: _descriptionController.text,
        priority: _selectedPriority,
        evidenceImages: _selectedImages,
        token: token,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Khiếu nại đã được gửi thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(complaintProvider.errorMessage ?? 'Không thể gửi khiếu nại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo khiếu nại'),
        backgroundColor: const Color(0xFFF26522),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Order info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.receipt, color: Color(0xFFF26522)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Đơn hàng', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          widget.orderCode,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Complaint type
            const Text('Loại khiếu nại *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...List.generate(_complaintTypes.length, (index) {
              final type = _complaintTypes[index];
              return RadioListTile<String>(
                value: type['value'] as String,
                groupValue: _selectedType,
                onChanged: (value) => setState(() => _selectedType = value!),
                title: Row(
                  children: [
                    Icon(type['icon'] as IconData, color: const Color(0xFFF26522), size: 20),
                    const SizedBox(width: 8),
                    Text(type['label'] as String),
                  ],
                ),
                activeColor: const Color(0xFFF26522),
              );
            }),
            const SizedBox(height: 16),

            // Priority
            const Text('Mức độ ưu tiên *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _priorities.map((priority) {
                final isSelected = _selectedPriority == priority['value'];
                final color = Color(int.parse('FF${priority['color']}', radix: 16));
                return ChoiceChip(
                  label: Text(priority['label']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedPriority = priority['value']!);
                    }
                  },
                  selectedColor: color.withOpacity(0.3),
                  labelStyle: TextStyle(
                    color: isSelected ? color : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Subject
            const Text('Tiêu đề *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                hintText: 'Nhập tiêu đề khiếu nại',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tiêu đề';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            const Text('Mô tả chi tiết *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Mô tả chi tiết vấn đề bạn gặp phải...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mô tả';
                }
                if (value.length < 20) {
                  return 'Mô tả phải có ít nhất 20 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Evidence images
            const Text('Ảnh minh chứng (tối đa 4 ảnh)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_selectedImages[index], fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Chọn ảnh'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Chụp ảnh'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitComplaint,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF26522),
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Gửi khiếu nại', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
