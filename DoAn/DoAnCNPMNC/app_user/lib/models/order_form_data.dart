class OrderContactInfo {
  final String name;
  final String phone;
  final String address;
  final String? city;
  final String? district;
  final String? ward;

  OrderContactInfo({
    required this.name,
    required this.phone,
    required this.address,
    this.city,
    this.district,
    this.ward,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'district': district,
      'ward': ward,
    };
  }
}

class ParcelInfo {
  final String? type;
  final double? weightKg;
  final double? lengthCm;
  final double? widthCm;
  final double? heightCm;
  final double? declaredValue;

  ParcelInfo({
    this.type,
    this.weightKg,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
    this.declaredValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'weightKg': weightKg,
      'lengthCm': lengthCm,
      'widthCm': widthCm,
      'heightCm': heightCm,
      'declaredValue': declaredValue,
    };
  }
}

class ServiceOption {
  final String? type;
  final String? pickupType;
  final String? pickupNotes;

  ServiceOption({
    this.type,
    this.pickupType,
    this.pickupNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'pickupType': pickupType,
      'pickupNotes': pickupNotes,
    };
  }
}

class PaymentOption {
  final String method;
  final double? codAmount;

  PaymentOption({
    required this.method,
    this.codAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'codAmount': codAmount,
    };
  }
}

class OrderItemForm {
  final String name;
  final int quantity;
  final double? weightKg;
  final double? price;

  OrderItemForm({
    required this.name,
    required this.quantity,
    this.weightKg,
    this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'weightKg': weightKg,
      'price': price,
    };
  }
}

class OrderFormData {
  final OrderContactInfo sender;
  final OrderContactInfo receiver;
  final ParcelInfo parcel;
  final ServiceOption service;
  final PaymentOption payment;
  final List<OrderItemForm> items;
  final String? notes;

  OrderFormData({
    required this.sender,
    required this.receiver,
    required this.parcel,
    required this.service,
    required this.payment,
    required this.items,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'sender': sender.toJson(),
      'receiver': receiver.toJson(),
      'parcel': parcel.toJson(),
      'service': service.toJson(),
      'payment': payment.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes,
    };
  }
}


