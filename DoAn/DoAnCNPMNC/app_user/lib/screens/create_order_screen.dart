import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/location.dart';
import '../models/order.dart';
import '../models/order_form_data.dart';
import '../services/location_service.dart';
import '../services/order_service.dart';
import '../utils/validation_utils.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

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
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_focusNode.hasFocus && _showSuggestions) {
            setState(() {
              _showSuggestions = false;
            });
          }
        });
      } else {
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
    setState(() {
      _showSuggestions = false;
    });
    widget.onSelected(option);
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
              color: Colors.black.withAlpha((0.1 * 255).round()),
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
              color: Colors.black.withAlpha((0.1 * 255).round()),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            widget.noResultsText,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final option = _suggestions[index];
          return InkWell(
            onTap: () => _handleOptionSelected(option),
            child: widget.itemBuilder(context, option),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: Icon(widget.prefixIcon),
            suffixIcon: widget.suffixIcon,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        _buildSuggestionsList(),
      ],
    );
  }
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  static const double _shippingBaseFee = 18000;
  static const double _shippingStepFee = 5000;
  static const double _weightStep = 0.5;
  static const double _expressSurcharge = 12000;
  static const double _economyDiscount = 2000;
  static const double _insuranceRate = 0.005;
  static const double _insuranceThreshold = 3000000;

  final _formKeys = List.generate(3, (_) => GlobalKey<FormState>());
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Sender
  final _senderNameController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  final _senderAddressController = TextEditingController();
  final _senderCityController = TextEditingController();
  final _senderDistrictController = TextEditingController();
  final _senderWardController = TextEditingController();

  // Receiver
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _receiverAddressController = TextEditingController();
  final _receiverCityController = TextEditingController();
  final _receiverDistrictController = TextEditingController();
  final _receiverWardController = TextEditingController();

  // Parcel & Service
  String _packageType = 'Tài liệu';
  final List<String> _packageTypes = [
    'Tài liệu',
    'Hàng thời trang',
    'Điện tử - Phụ kiện',
    'Đồ gia dụng',
    'Thực phẩm khô',
    'Khác'
  ];
  final _weightController = TextEditingController(text: '1');
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _declaredValueController = TextEditingController();
  String _serviceType = 'standard';
  String _pickupType = 'door_to_door';
  final _pickupNotesController = TextEditingController();
  final _notesController = TextEditingController();

  // Payment
  String _paymentMethod = 'cod';
  final _codAmountController = TextEditingController();
  final _insuranceAmountController = TextEditingController();

  // Order items
  final List<OrderItemForm> _items = [];

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  // Location data & state
  List<Province> _provinces = <Province>[];
  bool _isLocationLoading = false;
  String? _locationError;

  Province? _senderProvince;
  District? _senderDistrict;
  Ward? _senderWard;
  String? _senderLocationError;
  String? _senderAddressError;
  String _senderManualAddressPrefix = '';
  bool _isUpdatingSenderAddressText = false;

  Province? _receiverProvince;
  District? _receiverDistrict;
  Ward? _receiverWard;
  String? _receiverLocationError;
  String? _receiverAddressError;
  String _receiverManualAddressPrefix = '';
  bool _isUpdatingReceiverAddressText = false;

  @override
  void initState() {
    super.initState();
    _senderAddressController.addListener(() => _handleAddressTextChanged(isSender: true));
    _receiverAddressController.addListener(() => _handleAddressTextChanged(isSender: false));
    _senderAddressController.addListener(() => _validateAddress(isSender: true));
    _receiverAddressController.addListener(() => _validateAddress(isSender: false));
    _loadLocationData();
  }

  @override
  void dispose() {
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _senderAddressController.dispose();
    _senderCityController.dispose();
    _senderDistrictController.dispose();
    _senderWardController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _receiverAddressController.dispose();
    _receiverCityController.dispose();
    _receiverDistrictController.dispose();
    _receiverWardController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _declaredValueController.dispose();
    _pickupNotesController.dispose();
    _notesController.dispose();
    _codAmountController.dispose();
    _insuranceAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationData() async {
    setState(() {
      _isLocationLoading = true;
      _locationError = null;
    });
    try {
      await LocationService.ensureInitialized();
      final provinces = await LocationService.getAllProvinces();
      if (!mounted) return;
      setState(() {
        _provinces = provinces;
      });
    } catch (e) {
      if (!mounted) return;
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

  Province? _getProvinceByCode(int code) {
    for (final province in _provinces) {
      if (province.code == code) {
        return province;
      }
    }
    return null;
  }

  District? _getDistrictByCode(int code, {int? provinceCode}) {
    if (provinceCode != null) {
      final province = _getProvinceByCode(provinceCode);
      if (province == null) return null;
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

  void _handleAddressTextChanged({required bool isSender}) {
    final isUpdating = isSender ? _isUpdatingSenderAddressText : _isUpdatingReceiverAddressText;
    if (isUpdating) return;
    final prefix = _extractStreetPrefix(isSender: isSender);
    setState(() {
      if (isSender) {
        _senderManualAddressPrefix = prefix;
      } else {
        _receiverManualAddressPrefix = prefix;
      }
    });
  }

  void _validateAddress({required bool isSender}) {
    final controller = isSender ? _senderAddressController : _receiverAddressController;
    final error = ValidationUtils.validateAddress(controller.text.trim());
    setState(() {
      if (isSender) {
        _senderAddressError = error;
      } else {
        _receiverAddressError = error;
      }
    });
  }

  String _buildLocationSuffix({required bool isSender}) {
    final ward = isSender ? _senderWard : _receiverWard;
    final district = isSender ? _senderDistrict : _receiverDistrict;
    final province = isSender ? _senderProvince : _receiverProvince;
    final segments = <String>[];
    if (ward != null && ward.nameWithType.isNotEmpty) {
      segments.add(ward.nameWithType);
    }
    if (district != null && district.nameWithType.isNotEmpty) {
      segments.add(district.nameWithType);
    }
    if (province != null && province.nameWithType.isNotEmpty) {
      segments.add(province.nameWithType);
    }
    return segments.join(', ');
  }

  String _extractStreetPrefix({
    required bool isSender,
    String? source,
    String? suffixOverride,
  }) {
    final controller = isSender ? _senderAddressController : _receiverAddressController;
    final text = (source ?? controller.text).trim();
    if (text.isEmpty) {
      return '';
    }
    final suffix = (suffixOverride ?? _buildLocationSuffix(isSender: isSender)).trim();
    if (suffix.isEmpty) {
      return text.replaceAll(RegExp(r',\s*$'), '').trim();
    }
    final lowerText = text.toLowerCase();
    final lowerSuffix = suffix.toLowerCase();
    final index = lowerText.lastIndexOf(lowerSuffix);
    if (index == -1) {
      return text.replaceAll(RegExp(r',\s*$'), '').trim();
    }
    final prefix = text.substring(0, index);
    return prefix.replaceAll(RegExp(r',\s*$'), '').trim();
  }

  void _updateAddressField({required bool isSender}) {
    final suffix = _buildLocationSuffix(isSender: isSender);
    final prefix = (isSender ? _senderManualAddressPrefix : _receiverManualAddressPrefix).trim();
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
    final controller = isSender ? _senderAddressController : _receiverAddressController;
    final newText = buffer.toString();
    if (isSender) {
      _isUpdatingSenderAddressText = true;
    } else {
      _isUpdatingReceiverAddressText = true;
    }
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    if (isSender) {
      _isUpdatingSenderAddressText = false;
      _senderAddressError = ValidationUtils.validateAddress(newText);
    } else {
      _isUpdatingReceiverAddressText = false;
      _receiverAddressError = ValidationUtils.validateAddress(newText);
    }
  }

  void _applyAddressSuggestion(AddressSuggestion suggestion, {required bool isSender}) {
    setState(() {
      if (isSender) {
        _senderProvince = suggestion.province;
        _senderCityController.text = suggestion.province.nameWithType;
        _senderDistrict = suggestion.district;
        _senderDistrictController.text = suggestion.district.nameWithType;
        _senderWard = suggestion.ward;
        _senderWardController.text = suggestion.ward.nameWithType;
        _senderLocationError = null;
      } else {
        _receiverProvince = suggestion.province;
        _receiverCityController.text = suggestion.province.nameWithType;
        _receiverDistrict = suggestion.district;
        _receiverDistrictController.text = suggestion.district.nameWithType;
        _receiverWard = suggestion.ward;
        _receiverWardController.text = suggestion.ward.nameWithType;
        _receiverLocationError = null;
      }
    });
    _updateAddressField(isSender: isSender);
  }

  double _parseDouble(String? value) {
    if (value == null || value.trim().isEmpty) return 0;
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  double _parseCurrency(String? value) {
    if (value == null || value.trim().isEmpty) return 0;
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  double _calculateChargeableWeight() {
    final weight = max(0.1, _parseDouble(_weightController.text));
    final length = _parseDouble(_lengthController.text);
    final width = _parseDouble(_widthController.text);
    final height = _parseDouble(_heightController.text);
    double volumetric = 0;
    if (length > 0 && width > 0 && height > 0) {
      volumetric = (length * width * height) / 6000;
    }
    return max(0.5, max(weight, volumetric));
  }

  double _calculateShippingFee() {
    final chargeableWeight = _calculateChargeableWeight();
    final steps = (chargeableWeight / _weightStep).ceil();
    double fee = _shippingBaseFee + max(0, steps - 1) * _shippingStepFee;
    switch (_serviceType) {
      case 'express':
        fee += _expressSurcharge;
        break;
      case 'economy':
        fee = max(12000, fee - _economyDiscount);
        break;
      default:
        break;
    }
    return fee;
  }

  double _calculateInsuranceFee() {
    final declaredValue = _parseDouble(_declaredValueController.text);
    if (declaredValue <= 0 || declaredValue < _insuranceThreshold) return 0;
    return declaredValue * _insuranceRate;
  }

  double _calculateTotal() {
    final shippingFee = _calculateShippingFee();
    final insuranceFee = _calculateInsuranceFee();
    final cod = _paymentMethod == 'cod' ? _parseDouble(_codAmountController.text) : 0;
    return shippingFee + insuranceFee + cod;
  }

  String _describeRemainingTime(DateTime target) {
    final now = DateTime.now();
    final difference = target.difference(now);
    if (difference.isNegative) {
      final minutes = difference.inMinutes.abs();
      if (minutes >= 60) {
        final hours = minutes ~/ 60;
        final remainMinutes = minutes % 60;
        return 'đã quá hạn ${hours}h${remainMinutes.toString().padLeft(2, '0')}p';
      }
      return 'đã quá hạn $minutes phút';
    }
    final minutes = difference.inMinutes;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainMinutes = minutes % 60;
      return 'còn khoảng ${hours}h${remainMinutes.toString().padLeft(2, '0')}p';
    }
    return 'còn khoảng $minutes phút';
  }

  Future<void> _copyText(String value, {String? message}) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Đã sao chép')),
    );
  }

  Future<void> _openPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở đường dẫn thanh toán')),
      );
    }
  }

  Future<void> _addItemDialog() async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final weightController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<OrderItemForm>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm hàng hóa'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên hàng hóa'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên hàng hóa';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Số lượng'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final qty = int.tryParse(value ?? '');
                  if (qty == null || qty < 1) {
                    return 'Số lượng tối thiểu là 1';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Khối lượng (kg)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập khối lượng';
                  }
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) {
                    return 'Khối lượng phải là số hợp lệ và lớn hơn 0';
                  }
                  if (parsed > 50) {
                    return 'Khối lượng tối đa 50 kg';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Giá trị (VND)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(
                  OrderItemForm(
                    name: nameController.text.trim(),
                    quantity: int.tryParse(quantityController.text.trim()) ?? 1,
                    weightKg: weightController.text.trim().isEmpty ? null : _parseDouble(weightController.text),
                    price: priceController.text.trim().isEmpty ? null : _parseDouble(priceController.text),
                  ),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _items.add(result);
      });
    }
  }

  Future<void> _showOnlinePaymentDialog(Order order) async {
    try {
      final payment = await OrderService.initiateOnlinePayment(order.id);
      if (!mounted) return;

      final expiresText = payment.expiresAt != null
          ? '${DateFormat('dd/MM/yyyy HH:mm').format(payment.expiresAt!)} (${_describeRemainingTime(payment.expiresAt!)})'
          : 'Không xác định';

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Yêu cầu thanh toán online'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đơn hàng: ${order.trackingNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text('Số tiền: ${_currencyFormat.format(payment.amount)}'),
                  const SizedBox(height: 6),
                  Text('Mã tham chiếu: ${payment.reference}'),
                  const SizedBox(height: 6),
                  if (payment.provider != null)
                    Text('Cổng thanh toán: ${payment.provider!.toUpperCase()}'),
                  const SizedBox(height: 6),
                  if (payment.status != null)
                    Text('Trạng thái phiên: ${payment.status}'),
                  const SizedBox(height: 6),
                  Text('Hết hạn: $expiresText'),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Thông tin chuyển khoản',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ngân hàng: Vietcombank - CN TP.HCM\n'
                    'Số tài khoản: 1023 4567 888\n'
                    'Tên thụ hưởng: CTY CP GIAO NHẬN J&T EXPRESS\n'
                    'Nội dung: ${payment.reference}',
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Url thanh toán (mở trong trình duyệt hoặc WebView):',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    payment.paymentUrl,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  if ((payment.signature ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Signature:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    SelectableText(
                      payment.signature!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Sau khi chuyển khoản, vui lòng nhấn "Thanh toán thành công" trên trang vừa mở để hoàn tất.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => _copyText(
                  payment.reference,
                  message: 'Đã sao chép mã tham chiếu',
                ),
                child: const Text('Copy mã tham chiếu'),
              ),
              TextButton(
                onPressed: () => _copyText(
                  payment.paymentUrl,
                  message: 'Đã sao chép URL thanh toán',
                ),
                child: const Text('Copy URL'),
              ),
              if ((payment.signature ?? '').isNotEmpty)
                TextButton(
                  onPressed: () => _copyText(
                    payment.signature!,
                    message: 'Đã sao chép signature',
                  ),
                  child: const Text('Copy signature'),
                ),
              ElevatedButton(
                onPressed: () => _openPaymentUrl(payment.paymentUrl),
                child: const Text('Mở trang thanh toán'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể khởi tạo thanh toán online: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất một mặt hàng')),
      );
      return;
    }

    final sender = OrderContactInfo(
      name: _senderNameController.text.trim(),
      phone: _senderPhoneController.text.trim(),
      address: _senderAddressController.text.trim(),
      city: _senderCityController.text.trim().isEmpty ? null : _senderCityController.text.trim(),
      district: _senderDistrictController.text.trim().isEmpty ? null : _senderDistrictController.text.trim(),
      ward: _senderWardController.text.trim().isEmpty ? null : _senderWardController.text.trim(),
    );

    final receiver = OrderContactInfo(
      name: _receiverNameController.text.trim(),
      phone: _receiverPhoneController.text.trim(),
      address: _receiverAddressController.text.trim(),
      city: _receiverCityController.text.trim().isEmpty ? null : _receiverCityController.text.trim(),
      district: _receiverDistrictController.text.trim().isEmpty ? null : _receiverDistrictController.text.trim(),
      ward: _receiverWardController.text.trim().isEmpty ? null : _receiverWardController.text.trim(),
    );

    final parcel = ParcelInfo(
      type: _packageType,
      weightKg: _parseDouble(_weightController.text),
      lengthCm: _lengthController.text.trim().isEmpty ? null : _parseDouble(_lengthController.text),
      widthCm: _widthController.text.trim().isEmpty ? null : _parseDouble(_widthController.text),
      heightCm: _heightController.text.trim().isEmpty ? null : _parseDouble(_heightController.text),
      declaredValue: _declaredValueController.text.trim().isEmpty ? null : _parseDouble(_declaredValueController.text),
    );

    final service = ServiceOption(
      type: _serviceType,
      pickupType: _pickupType,
      pickupNotes: _pickupNotesController.text.trim().isEmpty ? null : _pickupNotesController.text.trim(),
    );

    final payment = PaymentOption(
      method: _paymentMethod,
      codAmount: _paymentMethod == 'cod'
          ? (_codAmountController.text.trim().isEmpty ? 0 : _parseDouble(_codAmountController.text))
          : null,
    );

    final data = OrderFormData(
      sender: sender,
      receiver: receiver,
      parcel: parcel,
      service: service,
      payment: payment,
      items: _items,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      final order = await OrderService.createOrder(data);
      if (!mounted) return;

      if (order.paymentMethod.toLowerCase() == 'online') {
        await _showOnlinePaymentDialog(order);
        if (!mounted) return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tạo đơn hàng ${order.trackingNumber}'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(order);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  bool _validateStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < _formKeys.length) {
      final isValid = _formKeys[stepIndex].currentState?.validate() ?? false;
      if (!isValid) return false;
    }

    if (stepIndex == 0) {
      if (_locationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_locationError!)),
        );
        return false;
      }

      final senderAddressError =
          ValidationUtils.validateAddress(_senderAddressController.text.trim());
      final receiverAddressError =
          ValidationUtils.validateAddress(_receiverAddressController.text.trim());

      setState(() {
        _senderAddressError = senderAddressError;
        _receiverAddressError = receiverAddressError;
        _senderLocationError = (_senderProvince == null ||
                _senderDistrict == null ||
                _senderWard == null)
            ? 'Vui lòng chọn đầy đủ Tỉnh/Thành phố, Quận/Huyện và Phường/Xã'
            : null;
        _receiverLocationError = (_receiverProvince == null ||
                _receiverDistrict == null ||
                _receiverWard == null)
            ? 'Vui lòng chọn đầy đủ Tỉnh/Thành phố, Quận/Huyện và Phường/Xã'
            : null;
      });

      if (_senderAddressError != null ||
          _receiverAddressError != null ||
          _senderLocationError != null ||
          _receiverLocationError != null) {
        return false;
      }
    }

    if (stepIndex == 2 && _paymentMethod == 'cod') {
      final codAmount = _parseDouble(_codAmountController.text);
      if (codAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tiền thu hộ (COD) phải lớn hơn 0')),
        );
        return false;
      }
    }

    if (stepIndex == 1 && _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất một mặt hàng')),
      );
      return false;
    }

    return true;
  }

  void _onStepContinue() {
    if (_currentStep < 3) {
      if (_validateStep(_currentStep)) {
        setState(() {
          _currentStep += 1;
        });
      }
    } else {
      if (!_isSubmitting) {
        _submit();
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  StepState _buildStepState(int index) {
    if (_currentStep > index) {
      return StepState.complete;
    }
    if (_currentStep == index) {
      return StepState.editing;
    }
    return StepState.indexed;
  }

  Widget _buildSelectionTile({
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? AppTheme.primaryColor
              : AppTheme.textSecondaryColor
                  .withAlpha((0.2 * 255).round()),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: icon != null
            ? Icon(
                icon,
                color: selected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondaryColor,
              )
            : null,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                ),
              )
            : null,
        trailing: Icon(
          selected ? Icons.check_circle : Icons.circle_outlined,
          color:
              selected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
        ),
      ),
    );
  }

  Widget _buildPartyLocationSection({required bool isSender}) {
    final provinceController =
        isSender ? _senderCityController : _receiverCityController;
    final districtController =
        isSender ? _senderDistrictController : _receiverDistrictController;
    final wardController =
        isSender ? _senderWardController : _receiverWardController;
    final addressController =
        isSender ? _senderAddressController : _receiverAddressController;
    final selectedProvince = isSender ? _senderProvince : _receiverProvince;
    final selectedDistrict = isSender ? _senderDistrict : _receiverDistrict;
    final locationError =
        isSender ? _senderLocationError : _receiverLocationError;
    final addressError =
        isSender ? _senderAddressError : _receiverAddressError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AsyncAutocompleteField<Province>(
          controller: provinceController,
          hintText: 'Tỉnh/ Thành phố',
          prefixIcon: Icons.location_city_outlined,
          fetchSuggestions: LocationService.searchProvinces,
          itemBuilder: (context, province) => ListTile(
            title: Text(province.nameWithType),
            subtitle:
                province.nameWithType == province.name ? null : Text(province.name),
          ),
          onSelected: (province) {
            setState(() {
              if (isSender) {
                _senderProvince = province;
                _senderCityController.text = province.nameWithType;
                _senderDistrict = null;
                _senderWard = null;
                _senderDistrictController.clear();
                _senderWardController.clear();
                _senderLocationError = null;
              } else {
                _receiverProvince = province;
                _receiverCityController.text = province.nameWithType;
                _receiverDistrict = null;
                _receiverWard = null;
                _receiverDistrictController.clear();
                _receiverWardController.clear();
                _receiverLocationError = null;
              }
            });
            _updateAddressField(isSender: isSender);
          },
        ),
        const SizedBox(height: 12),
        _AsyncAutocompleteField<District>(
          controller: districtController,
          hintText: 'Quận/ Huyện',
          prefixIcon: Icons.map_outlined,
          fetchSuggestions: (pattern) => LocationService.searchDistricts(
            pattern,
            provinceCode: selectedProvince?.code,
          ),
          itemBuilder: (context, district) => ListTile(
            title: Text(district.nameWithType),
            subtitle: Text(district.provinceNameWithType),
          ),
          onSelected: (district) {
            final province = _getProvinceByCode(district.provinceCode);
            setState(() {
              if (isSender) {
                if (province != null) {
                  _senderProvince = province;
                  _senderCityController.text = province.nameWithType;
                }
                _senderDistrict = district;
                _senderDistrictController.text = district.nameWithType;
                _senderWard = null;
                _senderWardController.clear();
                _senderLocationError = null;
              } else {
                if (province != null) {
                  _receiverProvince = province;
                  _receiverCityController.text = province.nameWithType;
                }
                _receiverDistrict = district;
                _receiverDistrictController.text = district.nameWithType;
                _receiverWard = null;
                _receiverWardController.clear();
                _receiverLocationError = null;
              }
            });
            _updateAddressField(isSender: isSender);
          },
        ),
        const SizedBox(height: 12),
        _AsyncAutocompleteField<Ward>(
          controller: wardController,
          hintText: 'Phường/ Xã',
          prefixIcon: Icons.location_on_outlined,
          fetchSuggestions: (pattern) => LocationService.searchWards(
            pattern,
            provinceCode: selectedProvince?.code,
            districtCode: selectedDistrict?.code,
          ),
          itemBuilder: (context, ward) => ListTile(
            title: Text(ward.nameWithType),
            subtitle: Text('${ward.districtNameWithType}, ${ward.provinceNameWithType}'),
          ),
          onSelected: (ward) {
            final province = _getProvinceByCode(ward.provinceCode);
            final district = _getDistrictByCode(
              ward.districtCode,
              provinceCode: ward.provinceCode,
            );
            setState(() {
              if (isSender) {
                if (province != null) {
                  _senderProvince = province;
                  _senderCityController.text = province.nameWithType;
                }
                if (district != null) {
                  _senderDistrict = district;
                  _senderDistrictController.text = district.nameWithType;
                }
                _senderWard = ward;
                _senderWardController.text = ward.nameWithType;
                _senderLocationError = null;
              } else {
                if (province != null) {
                  _receiverProvince = province;
                  _receiverCityController.text = province.nameWithType;
                }
                if (district != null) {
                  _receiverDistrict = district;
                  _receiverDistrictController.text = district.nameWithType;
                }
                _receiverWard = ward;
                _receiverWardController.text = ward.nameWithType;
                _receiverLocationError = null;
              }
            });
            _updateAddressField(isSender: isSender);
          },
        ),
        if (locationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              locationError,
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ),
        const SizedBox(height: 12),
        _AsyncAutocompleteField<AddressSuggestion>(
          controller: addressController,
          hintText: 'Địa chỉ (Số nhà, toà nhà, tên đường...)',
          prefixIcon: Icons.home_outlined,
          showNoResultsMessage: false,
          fetchSuggestions: (pattern) => LocationService.searchAddressSuggestions(
            pattern,
            provinceCode: selectedProvince?.code,
            districtCode: selectedDistrict?.code,
          ),
          itemBuilder: (context, suggestion) => ListTile(
            title: Text(suggestion.displayText),
            subtitle: Text(
              suggestion.ward.path.isNotEmpty
                  ? suggestion.ward.path
                  : '${suggestion.district.nameWithType}, ${suggestion.province.nameWithType}',
            ),
          ),
          onSelected: (suggestion) {
            final currentText = addressController.text.trim();
            final existingSuffix = _buildLocationSuffix(isSender: isSender);
            final manualPrefix = existingSuffix.isNotEmpty &&
                    currentText.toLowerCase().endsWith(existingSuffix.toLowerCase())
                ? currentText
                    .substring(0, currentText.length - existingSuffix.length)
                    .replaceAll(RegExp(r',\s*$'), '')
                    .trim()
                : currentText.replaceAll(RegExp(r',\s*$'), '').trim();
            setState(() {
              if (isSender) {
                _senderManualAddressPrefix = manualPrefix;
              } else {
                _receiverManualAddressPrefix = manualPrefix;
              }
            });
            _applyAddressSuggestion(suggestion, isSender: isSender);
          },
        ),
        if (addressError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              addressError,
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shippingFee = _calculateShippingFee();
    final insuranceFee = _calculateInsuranceFee();
    final total = _calculateTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo đơn gửi hàng'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == 3;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isLastStep ? 'Hoàn tất' : 'Tiếp tục'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: Text(_currentStep == 0 ? 'Hủy' : 'Quay lại'),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Người gửi & nhận'),
            isActive: _currentStep >= 0,
            state: _buildStepState(0),
            content: Form(
              key: _formKeys[0],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLocationLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  if (_locationError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha((0.08 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _locationError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadLocationData,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  const Text(
                    'Thông tin người gửi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _senderNameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                    validator: ValidationUtils.validateFullName,
                  ),
                  TextFormField(
                    controller: _senderPhoneController,
                    decoration: const InputDecoration(labelText: 'Số điện thoại'),
                    keyboardType: TextInputType.phone,
                    validator: ValidationUtils.validatePhone,
                  ),
                  const SizedBox(height: 8),
                  _buildPartyLocationSection(isSender: true),
                  const SizedBox(height: 16),
                  const Text(
                    'Thông tin người nhận',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _receiverNameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                    validator: ValidationUtils.validateFullName,
                  ),
                  TextFormField(
                    controller: _receiverPhoneController,
                    decoration: const InputDecoration(labelText: 'Số điện thoại'),
                    keyboardType: TextInputType.phone,
                    validator: ValidationUtils.validatePhone,
                  ),
                  const SizedBox(height: 8),
                  _buildPartyLocationSection(isSender: false),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Kiện hàng & dịch vụ'),
            isActive: _currentStep >= 1,
            state: _buildStepState(1),
            content: Form(
              key: _formKeys[1],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _packageType,
                    decoration: const InputDecoration(labelText: 'Loại hàng hóa'),
                    items: _packageTypes
                        .map((type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _packageType = value);
                      }
                    },
                  ),
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: 'Khối lượng (kg)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập khối lượng';
                      }
                      final parsed = double.tryParse(value.replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) {
                        return 'Khối lượng phải là số hợp lệ và lớn hơn 0';
                      }
                      if (parsed > 50) {
                        return 'Khối lượng tối đa 50 kg';
                      }
                      return null;
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _lengthController,
                          decoration: const InputDecoration(labelText: 'Dài (cm)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _widthController,
                          decoration: const InputDecoration(labelText: 'Rộng (cm)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          decoration: const InputDecoration(labelText: 'Cao (cm)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loại hình dịch vụ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tiêu chuẩn'),
                        selected: _serviceType == 'standard',
                        onSelected: (_) => setState(() => _serviceType = 'standard'),
                      ),
                      ChoiceChip(
                        label: const Text('Hỏa tốc'),
                        selected: _serviceType == 'express',
                        onSelected: (_) => setState(() => _serviceType = 'express'),
                      ),
                      ChoiceChip(
                        label: const Text('Tiết kiệm'),
                        selected: _serviceType == 'economy',
                        onSelected: (_) => setState(() => _serviceType = 'economy'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hình thức nhận hàng',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildSelectionTile(
                    title: 'Nhân viên đến lấy (Door-to-door)',
                    subtitle: 'Phù hợp khi bạn muốn J&T đến tận nơi lấy hàng',
                    selected: _pickupType == 'door_to_door',
                    onTap: () => setState(() => _pickupType = 'door_to_door'),
                    icon: Icons.delivery_dining,
                  ),
                  _buildSelectionTile(
                    title: 'Gửi tại bưu cục (Drop-off)',
                    subtitle: 'Tiết kiệm thời gian giao nhận, tự mang hàng đến bưu cục',
                    selected: _pickupType == 'drop_off',
                    onTap: () => setState(() => _pickupType = 'drop_off'),
                    icon: Icons.storefront,
                  ),
                  TextFormField(
                    controller: _pickupNotesController,
                    decoration: const InputDecoration(labelText: 'Ghi chú lấy hàng (tuỳ chọn)'),
                    maxLines: 2,
                  ),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Ghi chú đơn hàng (tuỳ chọn)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hàng hóa gửi đi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _addItemDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm'),
                      ),
                    ],
                  ),
                  if (_items.isEmpty)
                    Text(
                      'Chưa có hàng hóa, vui lòng thêm thông tin mặt hàng.',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    )
                  else
                    Column(
                      children: _items
                          .asMap()
                          .entries
                          .map(
                            (entry) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                title: Text(entry.value.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Số lượng: ${entry.value.quantity}'),
                                    if (entry.value.weightKg != null)
                                      Text('Khối lượng: ${entry.value.weightKg} kg'),
                                    if (entry.value.price != null)
                                      Text('Giá trị: ${_currencyFormat.format(entry.value.price)}'),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () {
                                    setState(() {
                                      _items.removeAt(entry.key);
                                    });
                                  },
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Thanh toán'),
            isActive: _currentStep >= 2,
            state: _buildStepState(2),
            content: Form(
              key: _formKeys[2],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSelectionTile(
                    title: 'Thanh toán khi nhận hàng (COD)',
                    subtitle: 'Nhân viên giao hàng thu hộ tiền cho bạn',
                    selected: _paymentMethod == 'cod',
                    onTap: () => setState(() => _paymentMethod = 'cod'),
                    icon: Icons.payments_outlined,
                  ),
                  if (_paymentMethod == 'cod')
                    TextFormField(
                      controller: _codAmountController,
                      decoration: const InputDecoration(labelText: 'Thu hộ COD (₫)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        final sanitized = value.replaceAll('.', '').replaceAll(',', '').trim();
                        final parsed = double.tryParse(sanitized);
                        if (parsed == null || parsed < 0) {
                          return 'Giá trị phải là số hợp lệ';
                        }
                        return null;
                      },
                    ),
                  _buildSelectionTile(
                    title: 'Thanh toán online (Mô phỏng)',
                    subtitle: 'Nhận URL thanh toán giả lập sau khi tạo đơn',
                    selected: _paymentMethod == 'online',
                    onTap: () => setState(() => _paymentMethod = 'online'),
                    icon: Icons.credit_card,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _insuranceAmountController,
                    decoration: const InputDecoration(labelText: 'Giá trị hàng hóa (₫)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return null;
                      }
                      final sanitized = value.replaceAll('.', '').replaceAll(',', '').trim();
                      final parsed = double.tryParse(sanitized);
                      if (parsed == null || parsed < 0) {
                        return 'Giá trị phải là số hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor
                          .withAlpha((0.07 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tóm tắt phí dự kiến',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Phí vận chuyển', _currencyFormat.format(shippingFee)),
                        _buildSummaryRow('Phí bảo hiểm', _currencyFormat.format(insuranceFee)),
                        if (_paymentMethod == 'cod')
                          _buildSummaryRow(
                            'Thu hộ COD',
                            _currencyFormat.format(_parseDouble(_codAmountController.text)),
                          ),
                        const Divider(),
                        _buildSummaryRow('Tổng tạm tính', _currencyFormat.format(total)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Xác nhận'),
            isActive: _currentStep >= 3,
            state: _buildStepState(3),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vui lòng kiểm tra lại thông tin trước khi tạo đơn hàng.',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Người gửi', _senderNameController.text),
                _buildSummaryRow('Người nhận', _receiverNameController.text),
                _buildSummaryRow('Loại hàng', _packageType),
                _buildSummaryRow('Dịch vụ', _serviceType == 'express' ? 'Hỏa tốc' : _serviceType == 'economy' ? 'Tiết kiệm' : 'Tiêu chuẩn'),
                _buildSummaryRow('Phương thức thanh toán', _paymentMethod == 'online' ? 'Online (mock)' : 'Thanh toán COD'),
                const Divider(),
                _buildSummaryRow('Phí vận chuyển', _currencyFormat.format(shippingFee)),
                _buildSummaryRow('Phí bảo hiểm', _currencyFormat.format(insuranceFee)),
                if (_paymentMethod == 'cod')
                  _buildSummaryRow('Thu hộ COD', _currencyFormat.format(_parseDouble(_codAmountController.text))),
                _buildSummaryRow('Tổng dự kiến', _currencyFormat.format(total)),
                const SizedBox(height: 12),
                Text(
                  'Sau khi tạo đơn, bạn có thể theo dõi chi tiết trạng thái và thực hiện thanh toán online (đối với đơn online) trong phần Chi tiết đơn hàng.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
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


