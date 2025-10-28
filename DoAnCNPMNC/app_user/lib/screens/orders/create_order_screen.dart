import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _deliveryPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  List<Map<String, dynamic>> _items = [];
  double _deliveryFee = 15000;

  @override
  void dispose() {
    _restaurantController.dispose();
    _deliveryAddressController.dispose();
    _deliveryPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        onAdd: (item) {
          setState(() {
            _items.add(item);
          });
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double _calculateTotal() {
    double subtotal = _items.fold(0, (sum, item) {
      return sum + (item['price'] * item['quantity']);
    });
    return subtotal + _deliveryFee;
  }

  Widget _buildSectionHeader({required IconData icon, required String title, required Color color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
      ],
    );
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Vui lòng thêm ít nhất một sản phẩm',
        backgroundColor: AppColors.danger,
        textColor: Colors.white,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    final success = await orderProvider.createOrder(
      restaurantName: _restaurantController.text.trim(),
      items: _items,
      totalAmount: _calculateTotal(),
      deliveryAddress: _deliveryAddressController.text.trim(),
      deliveryFee: _deliveryFee,
      deliveryPhone: _deliveryPhoneController.text.trim().isNotEmpty 
          ? _deliveryPhoneController.text.trim() 
          : null,
      notes: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
      token: authProvider.token,
    );

    if (success) {
      Fluttertoast.showToast(
        msg: 'Tạo đơn hàng thành công',
        backgroundColor: AppColors.success,
        textColor: Colors.white,
      );
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(
        msg: orderProvider.error ?? 'Tạo đơn hàng thất bại',
        backgroundColor: AppColors.danger,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTexts.createOrder),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pickup Information (Sender)
              _buildSectionHeader(
                icon: Icons.upload_rounded,
                title: 'Thông tin người gửi',
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _restaurantController,
                decoration: const InputDecoration(
                  labelText: 'Tên người gửi',
                  hintText: AppTexts.enterSenderName,
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => AppValidators.required(value, 'Tên người gửi'),
              ),
              const SizedBox(height: 24),
              
              // Packages Section
              _buildSectionHeader(
                icon: Icons.inventory_2_outlined,
                title: 'Thông tin kiện hàng',
                color: AppColors.warning,
              ),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_items.length} kiện hàng',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(AppTexts.addPackage),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (_items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.lightGrey,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có kiện hàng nào',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nhấn "Thêm kiện hàng" để bắt đầu',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.lightGrey, width: 1),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        item['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'SL: ${item['quantity']} | Giá: ${AppUtils.formatCurrency(item['price'])}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppUtils.formatCurrency(item['price'] * item['quantity']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                            onPressed: () => _removeItem(index),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              
              const SizedBox(height: 24),
              
              // Delivery Information
              _buildSectionHeader(
                icon: Icons.location_on_outlined,
                title: 'Thông tin giao hàng',
                color: AppColors.success,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _deliveryAddressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ giao hàng',
                  hintText: 'Nhập địa chỉ nhận hàng',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (value) => AppValidators.required(value, 'Địa chỉ giao hàng'),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _deliveryPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  hintText: AppTexts.enterDeliveryPhone,
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: AppValidators.phone,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  hintText: AppTexts.enterNotes,
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              // Order Summary
              if (_items.isNotEmpty) ...[
                const Text(
                  'Tóm tắt đơn hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ..._items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${item['name']} x${item['quantity']}'),
                                Text(AppUtils.formatCurrency(item['price'] * item['quantity'])),
                              ],
                            ),
                          );
                        }).toList(),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(AppTexts.deliveryFee),
                            Text(AppUtils.formatCurrency(_deliveryFee)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              AppTexts.total,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              AppUtils.formatCurrency(_calculateTotal()),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Create Order Button
              SizedBox(
                width: double.infinity,
                child: Consumer<OrderProvider>(
                  builder: (context, orderProvider, child) {
                    return ElevatedButton(
                      onPressed: orderProvider.isLoading ? null : _createOrder,
                      child: orderProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Tạo đơn hàng',
                              style: TextStyle(fontSize: 16),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  const _AddItemDialog({required this.onAdd});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (!_formKey.currentState!.validate()) return;

    final item = {
      'name': _nameController.text.trim(),
      'price': double.parse(_priceController.text),
      'quantity': int.parse(_quantityController.text),
    };

    widget.onAdd(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(AppTexts.addPackage),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên kiện hàng',
                hintText: AppTexts.enterPackageName,
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (value) => AppValidators.required(value, 'Tên kiện hàng'),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Giá trị hàng hóa',
                hintText: AppTexts.enterPrice,
                prefixText: '₫ ',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: AppValidators.price,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số lượng',
                hintText: AppTexts.enterQuantity,
              ),
              validator: AppValidators.quantity,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppTexts.cancel),
        ),
        ElevatedButton(
          onPressed: _addItem,
          child: const Text(AppTexts.addItem),
        ),
      ],
    );
  }
}
