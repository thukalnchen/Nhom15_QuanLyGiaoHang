class ShipperUser {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String status;

  const ShipperUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    this.phone,
  });

  factory ShipperUser.fromJson(Map<String, dynamic> json) {
    return ShipperUser(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : json['id'] ?? 0,
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'shipper',
      status: json['status']?.toString() ?? 'pending',
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
       'status': status,
      'phone': phone,
    };
  }

  bool get isShipper => role == 'shipper';
  bool get isApproved => status == 'approved';
}


