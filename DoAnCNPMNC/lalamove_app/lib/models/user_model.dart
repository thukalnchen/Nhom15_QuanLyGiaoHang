class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'customer', 'intake_staff', 'driver', 'admin'
  final String? address;
  final String? warehouseId;
  final String? warehouseName;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.address,
    this.warehouseId,
    this.warehouseName,
    this.isActive = true,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'customer',
      address: json['address']?.toString(),
      warehouseId: json['warehouse_id']?.toString(),
      warehouseName: json['warehouse_name']?.toString(),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'address': address,
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? address,
    String? warehouseId,
    String? warehouseName,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      address: address ?? this.address,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  bool get isCustomer => role == 'customer';
  bool get isIntakeStaff => role == 'intake_staff';
  bool get isDriver => role == 'driver';
  bool get isAdmin => role == 'admin';
  
  // [] operator for backward compatibility with old code
  dynamic operator [](String key) {
    switch (key) {
      case 'id':
        return id;
      case 'name':
      case 'full_name':
        return name;
      case 'email':
        return email;
      case 'phone':
        return phone;
      case 'role':
        return role;
      case 'address':
        return address;
      case 'warehouse_id':
        return warehouseId;
      case 'warehouse_name':
        return warehouseName;
      case 'is_active':
        return isActive;
      case 'created_at':
        return createdAt.toIso8601String();
      default:
        return null;
    }
  }
}
