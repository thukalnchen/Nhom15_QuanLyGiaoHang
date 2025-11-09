class Order {
  final String id;
  final String orderCode;
  final String status;
  
  // Customer info
  final String customerId;
  final String customerName;
  final String customerPhone;
  
  // Pickup info
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String? pickupNote;
  
  // Delivery info
  final String deliveryAddress;
  final double deliveryLat;
  final double deliveryLng;
  final String? deliveryNote;
  final String recipientName;
  final String recipientPhone;
  
  // Package info
  final String? packageSize;
  final String? packageType;
  final double? weight;
  final String? description;
  final List<String>? images;
  
  // Customer estimates (what customer thinks before warehouse verification)
  final String? customerEstimatedSize;
  final String? customerRequestedVehicle;
  
  // Warehouse info
  final String? warehouseId;
  final String? warehouseName;
  final String? intakeStaffId;
  final String? intakeStaffName;
  final DateTime? receivedAt;
  final DateTime? classifiedAt;
  
  // Classification info
  final String? zone;
  final String? recommendedVehicle;
  
  // Driver info
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleType;
  final DateTime? assignedAt;
  
  // Payment info
  final double deliveryFee;
  final bool isCod;
  final double? codAmount;
  final String? codPaymentType; // 'sender_pays' or 'receiver_pays'
  final bool? codCollectedAtWarehouse;
  final DateTime? codCollectedAt;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  Order({
    required this.id,
    required this.orderCode,
    required this.status,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    this.pickupNote,
    required this.deliveryAddress,
    required this.deliveryLat,
    required this.deliveryLng,
    this.deliveryNote,
    required this.recipientName,
    required this.recipientPhone,
    this.packageSize,
    this.packageType,
    this.weight,
    this.description,
    this.images,
    this.customerEstimatedSize,
    this.customerRequestedVehicle,
    this.warehouseId,
    this.warehouseName,
    this.intakeStaffId,
    this.intakeStaffName,
    this.receivedAt,
    this.classifiedAt,
    this.zone,
    this.recommendedVehicle,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehicleType,
    this.assignedAt,
    required this.deliveryFee,
    this.isCod = false,
    this.codAmount,
    this.codPaymentType,
    this.codCollectedAtWarehouse,
    this.codCollectedAt,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      orderCode: json['order_code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      pickupAddress: json['pickup_address']?.toString() ?? '',
      pickupLat: _parseDouble(json['pickup_lat']) ?? 0.0,
      pickupLng: _parseDouble(json['pickup_lng']) ?? 0.0,
      pickupNote: json['pickup_note']?.toString(),
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      deliveryLat: _parseDouble(json['delivery_lat']) ?? 0.0,
      deliveryLng: _parseDouble(json['delivery_lng']) ?? 0.0,
      deliveryNote: json['delivery_note']?.toString(),
      recipientName: json['recipient_name']?.toString() ?? '',
      recipientPhone: json['recipient_phone']?.toString() ?? '',
      packageSize: json['package_size']?.toString(),
      packageType: json['package_type']?.toString(),
      weight: _parseDouble(json['weight']),
      description: json['description']?.toString(),
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : null,
      customerEstimatedSize: json['customer_estimated_size']?.toString(),
      customerRequestedVehicle: json['customer_requested_vehicle']?.toString(),
      warehouseId: json['warehouse_id']?.toString(),
      warehouseName: json['warehouse_name']?.toString(),
      intakeStaffId: json['intake_staff_id']?.toString(),
      intakeStaffName: json['intake_staff_name']?.toString(),
      receivedAt: json['received_at'] != null
          ? DateTime.parse(json['received_at'])
          : null,
      classifiedAt: json['classified_at'] != null
          ? DateTime.parse(json['classified_at'])
          : null,
      zone: json['zone']?.toString(),
      recommendedVehicle: json['recommended_vehicle']?.toString(),
      driverId: json['driver_id']?.toString(),
      driverName: json['driver_name']?.toString(),
      driverPhone: json['driver_phone']?.toString(),
      vehicleType: json['vehicle_type']?.toString(),
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'])
          : null,
      deliveryFee: _parseDouble(json['delivery_fee']) ?? 0.0,
      isCod: json['is_cod'] ?? false,
      codAmount: _parseDouble(json['cod_amount']),
      codPaymentType: json['cod_payment_type']?.toString(),
      codCollectedAtWarehouse: json['cod_collected_at_warehouse'],
      codCollectedAt: json['cod_collected_at'] != null
          ? DateTime.parse(json['cod_collected_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_code': orderCode,
      'status': status,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'pickup_address': pickupAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'pickup_note': pickupNote,
      'delivery_address': deliveryAddress,
      'delivery_lat': deliveryLat,
      'delivery_lng': deliveryLng,
      'delivery_note': deliveryNote,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'package_size': packageSize,
      'package_type': packageType,
      'weight': weight,
      'description': description,
      'images': images,
      'customer_estimated_size': customerEstimatedSize,
      'customer_requested_vehicle': customerRequestedVehicle,
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'intake_staff_id': intakeStaffId,
      'intake_staff_name': intakeStaffName,
      'received_at': receivedAt?.toIso8601String(),
      'classified_at': classifiedAt?.toIso8601String(),
      'zone': zone,
      'recommended_vehicle': recommendedVehicle,
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'vehicle_type': vehicleType,
      'assigned_at': assignedAt?.toIso8601String(),
      'delivery_fee': deliveryFee,
      'is_cod': isCod,
      'cod_amount': codAmount,
      'cod_payment_type': codPaymentType,
      'cod_collected_at_warehouse': codCollectedAtWarehouse,
      'cod_collected_at': codCollectedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Order copyWith({
    String? id,
    String? orderCode,
    String? status,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    String? pickupNote,
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
    String? deliveryNote,
    String? recipientName,
    String? recipientPhone,
    String? packageSize,
    String? packageType,
    double? weight,
    String? description,
    List<String>? images,
    String? customerEstimatedSize,
    String? customerRequestedVehicle,
    String? warehouseId,
    String? warehouseName,
    String? intakeStaffId,
    String? intakeStaffName,
    DateTime? receivedAt,
    DateTime? classifiedAt,
    String? zone,
    String? recommendedVehicle,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? vehicleType,
    DateTime? assignedAt,
    double? deliveryFee,
    bool? isCod,
    double? codAmount,
    String? codPaymentType,
    bool? codCollectedAtWarehouse,
    DateTime? codCollectedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderCode: orderCode ?? this.orderCode,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      pickupNote: pickupNote ?? this.pickupNote,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
      deliveryNote: deliveryNote ?? this.deliveryNote,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      packageSize: packageSize ?? this.packageSize,
      packageType: packageType ?? this.packageType,
      weight: weight ?? this.weight,
      description: description ?? this.description,
      images: images ?? this.images,
      customerEstimatedSize: customerEstimatedSize ?? this.customerEstimatedSize,
      customerRequestedVehicle: customerRequestedVehicle ?? this.customerRequestedVehicle,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      intakeStaffId: intakeStaffId ?? this.intakeStaffId,
      intakeStaffName: intakeStaffName ?? this.intakeStaffName,
      receivedAt: receivedAt ?? this.receivedAt,
      classifiedAt: classifiedAt ?? this.classifiedAt,
      zone: zone ?? this.zone,
      recommendedVehicle: recommendedVehicle ?? this.recommendedVehicle,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehicleType: vehicleType ?? this.vehicleType,
      assignedAt: assignedAt ?? this.assignedAt,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      isCod: isCod ?? this.isCod,
      codAmount: codAmount ?? this.codAmount,
      codPaymentType: codPaymentType ?? this.codPaymentType,
      codCollectedAtWarehouse: codCollectedAtWarehouse ?? this.codCollectedAtWarehouse,
      codCollectedAt: codCollectedAt ?? this.codCollectedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Helper method to parse double from dynamic (handles both num and String)
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
