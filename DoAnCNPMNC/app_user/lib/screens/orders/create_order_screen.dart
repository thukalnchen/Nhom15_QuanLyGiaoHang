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
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant Information
              const Text(
                'Thông tin nhà hàng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _restaurantController,
                decoration: const InputDecoration(
                  labelText: 'Tên nhà hàng',
                  hintText: AppTexts.enterRestaurantName,
                  prefixIcon: Icon(Icons.restaurant),
                ),
                validator: (value) => AppValidators.required(value, 'Tên nhà hàng'),
              ),
              const SizedBox(height: 24),
              
              // Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sản phẩm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text(AppTexts.addItem),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (_items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.grey.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_shopping_cart,
                        size: 48,
                        color: AppColors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có sản phẩm nào',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nhấn "Thêm sản phẩm" để bắt đầu',
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
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item['name']),
                      subtitle: Text('${item['quantity']} x ${AppUtils.formatCurrency(item['price'])}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppUtils.formatCurrency(item['price'] * item['quantity']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.danger),
                            onPressed: () => _removeItem(index),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              
              const SizedBox(height: 24),
              
              // Delivery Information
              const Text(
                'Thông tin giao hàng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _deliveryAddressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ giao hàng',
                  hintText: AppTexts.enterDeliveryAddress,
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
      title: const Text(AppTexts.addItem),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên sản phẩm',
                hintText: AppTexts.enterItemName,
              ),
              validator: (value) => AppValidators.required(value, 'Tên sản phẩm'),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Giá',
                hintText: AppTexts.enterPrice,
                prefixText: '₫ ',
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
