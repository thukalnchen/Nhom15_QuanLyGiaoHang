import 'dart:math';

void main() {
  // Tọa độ Đại học Huflit
  final huflitLat = 10.7829;
  final huflitLng = 106.6893;
  
  // Tọa độ Landmark 81
  final landmark81Lat = 10.7946;
  final landmark81Lng = 106.7218;
  
  print('════════════════════════════════════════════════════════');
  print('📍 TÍNH KHOẢNG CÁCH VÀ GIÁ TIỀN');
  print('════════════════════════════════════════════════════════');
  print('');
  print('🏫 Pickup:  Đại học Huflit');
  print('   Địa chỉ: 190-192 Lý Chính Thắng, Q.3, TP.HCM');
  print('   Tọa độ: $huflitLat, $huflitLng');
  print('');
  print('🏢 Dropoff: Landmark 81');
  print('   Địa chỉ: 720A Điện Biên Phủ, Bình Thạnh, TP.HCM');
  print('   Tọa độ: $landmark81Lat, $landmark81Lng');
  print('');
  print('════════════════════════════════════════════════════════');
  
  // Tính khoảng cách bằng Haversine formula
  final distanceInMeters = calculateDistance(
    huflitLat, huflitLng,
    landmark81Lat, landmark81Lng,
  );
  
  final distanceInKm = distanceInMeters / 1000;
  final durationInMinutes = (distanceInMeters / 500).round(); // 30km/h avg
  
  print('📏 KHOẢNG CÁCH:');
  print('   ${distanceInKm.toStringAsFixed(2)} km (đường chim bay)');
  print('   ~${(distanceInKm * 1.3).toStringAsFixed(2)} km (ước tính đường đi thực tế)');
  print('');
  print('⏱️  THỜI GIAN DỰ KIẾN:');
  print('   $durationInMinutes phút (tốc độ TB: 30km/h)');
  print('');
  print('════════════════════════════════════════════════════════');
  print('💰 TÍNH GIÁ THEO TỪNG LOẠI XE:');
  print('════════════════════════════════════════════════════════');
  print('');
  
  // Tính giá cho từng loại xe
  calculatePriceForVehicle('Xe máy (Motorcycle)', 'motorcycle', distanceInMeters);
  calculatePriceForVehicle('Van 500kg', 'van_500', distanceInMeters);
  calculatePriceForVehicle('Van 750kg', 'van_750', distanceInMeters);
  calculatePriceForVehicle('Van 1000kg', 'van_1000', distanceInMeters);
  
  print('');
  print('════════════════════════════════════════════════════════');
  print('📋 VÍ DỤ VỚI DỊCH VỤ THÊM:');
  print('════════════════════════════════════════════════════════');
  print('');
  
  // Ví dụ với services
  final motorcyclePrice = calculateDetailedPrice('motorcycle', distanceInMeters, {
    'train_station': true,
    'round_trip': false,
  });
  
  print('🏍️  Xe máy + Giao bến xe:');
  print('   Base fare:     ${formatPrice(motorcyclePrice['baseFare']!)}');
  print('   Train station: +20,000đ');
  print('   ─────────────────────────────');
  print('   TOTAL:         ${formatPrice(motorcyclePrice['total']!)} ✅');
  print('');
  
  final vanPrice = calculateDetailedPrice('van_500', distanceInMeters, {
    'helper': true,
    'round_trip': true,
  });
  
  print('🚚 Van 500kg + Người phụ + Khứ hồi:');
  print('   Base fare:     ${formatPrice(vanPrice['baseFare']!)}');
  print('   Helper:        +50,000đ');
  print('   Subtotal:      ${formatPrice(vanPrice['subtotal']!)}');
  print('   Round trip:    +${formatPrice(vanPrice['roundTripCost']!)} (70%)');
  print('   ─────────────────────────────');
  print('   TOTAL:         ${formatPrice(vanPrice['total']!)} ✅');
  print('');
  print('════════════════════════════════════════════════════════');
}

// Haversine formula - tính khoảng cách giữa 2 điểm trên trái đất
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000; // Bán kính trái đất (meters)
  
  final phi1 = lat1 * pi / 180;
  final phi2 = lat2 * pi / 180;
  final deltaPhi = (lat2 - lat1) * pi / 180;
  final deltaLambda = (lon2 - lon1) * pi / 180;
  
  final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
      cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
  
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  
  return R * c;
}

void calculatePriceForVehicle(String name, String vehicleId, double distanceInMeters) {
  const basePricePerKm = {
    'motorcycle': 5000.0,
    'van_500': 8000.0,
    'van_750': 10000.0,
    'van_1000': 12000.0,
  };
  
  const minimumFare = {
    'motorcycle': 15000.0,
    'van_500': 30000.0,
    'van_750': 40000.0,
    'van_1000': 50000.0,
  };
  
  final distanceInKm = distanceInMeters / 1000;
  final pricePerKm = basePricePerKm[vehicleId]!;
  final minFare = minimumFare[vehicleId]!;
  
  var baseFare = distanceInKm * pricePerKm;
  if (baseFare < minFare) {
    baseFare = minFare;
  }
  
  final emoji = vehicleId == 'motorcycle' ? '🏍️' : '🚚';
  
  print('$emoji  $name:');
  print('   ${distanceInKm.toStringAsFixed(2)} km × ${formatPrice(pricePerKm)}/km = ${formatPrice(baseFare)}');
  if (distanceInKm * pricePerKm < minFare) {
    print('   (Áp dụng giá tối thiểu: ${formatPrice(minFare)})');
  }
  print('');
}

Map<String, double> calculateDetailedPrice(String vehicleId, double distanceInMeters, Map<String, bool> services) {
  const basePricePerKm = {
    'motorcycle': 5000.0,
    'van_500': 8000.0,
    'van_750': 10000.0,
    'van_1000': 12000.0,
  };
  
  const minimumFare = {
    'motorcycle': 15000.0,
    'van_500': 30000.0,
    'van_750': 40000.0,
    'van_1000': 50000.0,
  };
  
  final distanceInKm = distanceInMeters / 1000;
  final pricePerKm = basePricePerKm[vehicleId]!;
  final minFare = minimumFare[vehicleId]!;
  
  var baseFare = distanceInKm * pricePerKm;
  if (baseFare < minFare) {
    baseFare = minFare;
  }
  
  var servicesCost = 0.0;
  
  if (services['train_station'] == true) {
    servicesCost += 20000;
  }
  
  if (services['helper'] == true) {
    servicesCost += vehicleId == 'van_1000' ? 70000 : 50000;
  }
  
  final subtotal = baseFare + servicesCost;
  
  var roundTripCost = 0.0;
  if (services['round_trip'] == true) {
    roundTripCost = subtotal * 0.7;
  }
  
  final total = subtotal + roundTripCost;
  
  return {
    'baseFare': baseFare,
    'servicesCost': servicesCost,
    'subtotal': subtotal,
    'roundTripCost': roundTripCost,
    'total': total,
  };
}

String formatPrice(double price) {
  return '${price.round().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  )}đ';
}
