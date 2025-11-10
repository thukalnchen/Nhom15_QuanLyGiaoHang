import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/location.dart';

/// Provides cached access to Vietnamese administrative divisions and exposes
/// helper search methods for the address autocomplete feature.
///
/// This service downloads the full province/district/ward tree once from
/// https://provinces.open-api.vn/ and keeps it in memory for subsequent lookups.
/// The dataset is small (~1.3 MB) and changes rarely, so caching in memory keeps
/// lookups instant without adding local storage complexity.
class LocationService {
  LocationService._();

  static const String _endpoint = 'https://provinces.open-api.vn/api/?depth=3';

  static List<Province> _provincesCache = <Province>[];
  static List<AddressSuggestion> _wardSuggestionsCache = <AddressSuggestion>[];

  /// Fetches and caches the full administrative tree if it has not been loaded.
  static Future<void> ensureInitialized() async {
    if (_provincesCache.isNotEmpty && _wardSuggestionsCache.isNotEmpty) {
      return;
    }

    final response = await http.get(Uri.parse(_endpoint));
    if (response.statusCode != 200) {
      throw Exception('Không thể tải danh sách tỉnh/thành phố (HTTP ${response.statusCode}).');
    }

    final decoded = json.decode(response.body) as List<dynamic>;
    _provincesCache = decoded
        .map((provinceJson) => Province.fromJson(provinceJson as Map<String, dynamic>))
        .toList();

    _wardSuggestionsCache = <AddressSuggestion>[
      for (final province in _provincesCache)
        for (final district in province.districts)
          for (final ward in district.wards)
            AddressSuggestion(
              province: province,
              district: district,
              ward: ward,
            ),
    ];
  }

  /// Returns every province. `ensureInitialized` is automatically called.
  static Future<List<Province>> getAllProvinces() async {
    await ensureInitialized();
    return _provincesCache;
  }

  /// Accent-insensitive search helper used by the UI. Matching is performed
  /// against `name` and `nameWithType` for each province.
  static Future<List<Province>> searchProvinces(String query) async {
    await ensureInitialized();
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      // Trả về toàn bộ danh sách 63 tỉnh/thành đã được cache để người dùng
      // dễ dàng thấy được sự đa dạng địa lý ngay cả khi chưa nhập từ khóa.
      return List<Province>.unmodifiable(_provincesCache);
    }
    final Iterable<Province> matches = _provincesCache.where((province) {
      final searchable = _normalize('${province.name} ${province.nameWithType}');
      return searchable.contains(normalizedQuery);
    });
    // Giữ giới hạn hợp lý cho danh sách gợi ý khi có từ khóa để tránh làm tràn UI,
    // nhưng vẫn đảm bảo đủ đa dạng kết quả.
    return matches.take(30).toList();
  }

  /// Accent-insensitive search across districts. Optionally limit the results
  /// to a single province using `provinceCode`.
  static Future<List<District>> searchDistricts(
    String query, {
    int? provinceCode,
  }) async {
    await ensureInitialized();
    final normalizedQuery = _normalize(query);
    final Iterable<District> districts = _provincesCache
        .where((province) => provinceCode == null || province.code == provinceCode)
        .expand((province) => province.districts);

    if (normalizedQuery.isEmpty) {
      return districts.take(20).toList();
    }

    return districts.where((district) {
      final searchable = _normalize(
        '${district.name} ${district.nameWithType} ${district.pathWithType} ${district.provinceNameWithType}',
      );
      return searchable.contains(normalizedQuery);
    }).take(20).toList();
  }

  /// Accent-insensitive search across wards/communes. Optionally limit the
  /// results using `provinceCode` and/or `districtCode`.
  static Future<List<Ward>> searchWards(
    String query, {
    int? provinceCode,
    int? districtCode,
  }) async {
    await ensureInitialized();
    final normalizedQuery = _normalize(query);
    final Iterable<Ward> wards = _provincesCache
        .where((province) => provinceCode == null || province.code == provinceCode)
        .expand((province) => province.districts)
        .where((district) => districtCode == null || district.code == districtCode)
        .expand((district) => district.wards);

    if (normalizedQuery.isEmpty) {
      return wards.take(20).toList();
    }

    return wards.where((ward) {
      final searchable = _normalize(ward.pathWithType.isNotEmpty
          ? ward.pathWithType
          : '${ward.nameWithType}, ${ward.districtNameWithType}, ${ward.provinceNameWithType}');
      return searchable.contains(normalizedQuery);
    }).take(20).toList();
  }

  /// Returns address suggestions with the full ward/district/province chain.
  /// The UI uses this for the free-form address field.
  static Future<List<AddressSuggestion>> searchAddressSuggestions(
    String query, {
    int? provinceCode,
    int? districtCode,
  }) async {
    await ensureInitialized();
    final normalizedQuery = _normalize(query);

    Iterable<AddressSuggestion> pool = _wardSuggestionsCache;
    if (provinceCode != null) {
      pool = pool.where((suggestion) => suggestion.province.code == provinceCode);
    }
    if (districtCode != null) {
      pool = pool.where((suggestion) => suggestion.district.code == districtCode);
    }

    if (normalizedQuery.isEmpty) {
      return pool.take(20).toList();
    }

    return pool.where((suggestion) {
      final searchable = _normalize(suggestion.toSearchableText());
      return searchable.contains(normalizedQuery);
    }).take(20).toList();
  }

  /// Utility: convert Vietnamese strings to lowercase ASCII for fuzzy search.
  static String _normalize(String value) {
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final character = String.fromCharCode(rune);
      buffer.write(_diacriticMap[character] ?? character);
    }
    return buffer.toString().trim();
  }

  /// Mapping of Vietnamese diacritics to their ASCII equivalents.
  static const Map<String, String> _diacriticMap = <String, String>{
    'à': 'a',
    'á': 'a',
    'ả': 'a',
    'ã': 'a',
    'ạ': 'a',
    'ă': 'a',
    'ằ': 'a',
    'ắ': 'a',
    'ẳ': 'a',
    'ẵ': 'a',
    'ặ': 'a',
    'â': 'a',
    'ầ': 'a',
    'ấ': 'a',
    'ẩ': 'a',
    'ẫ': 'a',
    'ậ': 'a',
    'è': 'e',
    'é': 'e',
    'ẻ': 'e',
    'ẽ': 'e',
    'ẹ': 'e',
    'ê': 'e',
    'ề': 'e',
    'ế': 'e',
    'ể': 'e',
    'ễ': 'e',
    'ệ': 'e',
    'ì': 'i',
    'í': 'i',
    'ỉ': 'i',
    'ĩ': 'i',
    'ị': 'i',
    'ò': 'o',
    'ó': 'o',
    'ỏ': 'o',
    'õ': 'o',
    'ọ': 'o',
    'ô': 'o',
    'ồ': 'o',
    'ố': 'o',
    'ổ': 'o',
    'ỗ': 'o',
    'ộ': 'o',
    'ơ': 'o',
    'ờ': 'o',
    'ớ': 'o',
    'ở': 'o',
    'ỡ': 'o',
    'ợ': 'o',
    'ù': 'u',
    'ú': 'u',
    'ủ': 'u',
    'ũ': 'u',
    'ụ': 'u',
    'ư': 'u',
    'ừ': 'u',
    'ứ': 'u',
    'ử': 'u',
    'ữ': 'u',
    'ự': 'u',
    'ỳ': 'y',
    'ý': 'y',
    'ỷ': 'y',
    'ỹ': 'y',
    'ỵ': 'y',
    'đ': 'd',
  };
}


