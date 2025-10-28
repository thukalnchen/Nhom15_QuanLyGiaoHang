class VehicleType {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String dimensions;
  final String maxWeight;
  final String availability;
  final List<AdditionalService> additionalServices;

  VehicleType({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.dimensions,
    required this.maxWeight,
    required this.availability,
    this.additionalServices = const [],
  });
}

class AdditionalService {
  final String id;
  final String name;
  final double price; // Changed to double for calculations
  final String? description;
  final bool isPercentage;

  AdditionalService({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.isPercentage = false,
  });
}

class VehicleData {
  static final List<VehicleType> vehicles = [
    VehicleType(
      id: 'motorcycle',
      name: 'Motorcycle',
      icon: '🏍️',
      description: 'Goods worth up to 3 million VND and no cash on delivery',
      dimensions: '0.5 x 0.4 x 0.5 Meter',
      maxWeight: 'Up to 30 kg',
      availability: 'Available Now',
      additionalServices: [
        AdditionalService(
          id: 'train_station',
          name: 'Delivery to train/bus station (include entrance fee)',
          price: 20000,
        ),
        AdditionalService(
          id: 'extra_weight',
          name: 'Extra weight',
          price: 10000, // Base price per kg
        ),
        AdditionalService(
          id: 'round_trip',
          name: 'Round trip',
          price: 70, // Percentage value
          isPercentage: true,
        ),
      ],
    ),
    VehicleType(
      id: 'van_500',
      name: 'Van 500 kg',
      icon: '🚐',
      description: 'Available At All Hours',
      dimensions: '1.7 x 1.2 x 1.2 Meter',
      maxWeight: 'Up to 500 kg',
      availability: 'Available At All Hours',
      additionalServices: [
        AdditionalService(
          id: 'helper',
          name: 'Helper',
          price: 50000,
        ),
        AdditionalService(
          id: 'round_trip',
          name: 'Round trip',
          price: 70,
          isPercentage: true,
        ),
      ],
    ),
    VehicleType(
      id: 'van_750',
      name: 'Van 750 kg',
      icon: '🚐',
      description: 'Available At All Hours',
      dimensions: '1.9 x 1.3 x 1.3 Meter',
      maxWeight: 'Up to 750 kg',
      availability: 'Available At All Hours',
      additionalServices: [
        AdditionalService(
          id: 'helper',
          name: 'Helper',
          price: 50000,
        ),
        AdditionalService(
          id: 'round_trip',
          name: 'Round trip',
          price: 70,
          isPercentage: true,
        ),
      ],
    ),
    VehicleType(
      id: 'van_1000',
      name: 'Van 1000 kg',
      icon: '🚚',
      description: 'Available At All Hours',
      dimensions: '2.4 x 1.4 x 1.4 Meter',
      maxWeight: 'Up to 1000 kg',
      availability: 'Available At All Hours',
      additionalServices: [
        AdditionalService(
          id: 'helper',
          name: 'Helper',
          price: 70000,
        ),
        AdditionalService(
          id: 'round_trip',
          name: 'Round trip',
          price: 70,
          isPercentage: true,
        ),
      ],
    ),
  ];
}
