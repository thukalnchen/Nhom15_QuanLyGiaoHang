/// Data models that describe Vietnamese administrative divisions.
///
/// The register flow relies on these classes to populate the province,
/// district, and ward search fields as well as the address autocomplete.
/// Keeping the models in a dedicated file (instead of in the service)
/// makes them easier to unit test and reuse elsewhere in the app.

/// Represents a province/city (tỉnh/thành phố) in Việt Nam.
class Province {
  Province({
    required this.code,
    required this.name,
    required this.nameWithType,
    required this.divisionType,
    required this.codename,
    required this.phoneCode,
    required this.districts,
  });

  final int code;
  final String name;
  final String nameWithType;
  final String divisionType;
  final String codename;
  final String? phoneCode;
  final List<District> districts;

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      code: json['code'] as int,
      name: json['name'] as String? ?? '',
      nameWithType: json['name_with_type'] as String? ?? json['name'] as String? ?? '',
      divisionType: json['division_type'] as String? ?? '',
      codename: json['codename'] as String? ?? '',
      phoneCode: json['phone_code']?.toString(),
      districts: (json['districts'] as List<dynamic>? ?? [])
          .map(
            (districtJson) => District.fromJson(
              districtJson as Map<String, dynamic>,
              provinceCode: json['code'] as int,
              provinceName: json['name'] as String? ?? '',
              provinceNameWithType: json['name_with_type'] as String? ?? json['name'] as String? ?? '',
            ),
          )
          .toList(),
    );
  }
}

/// Represents a district (quận/huyện/thị xã/thành phố thuộc tỉnh).
class District {
  District({
    required this.code,
    required this.name,
    required this.nameWithType,
    required this.divisionType,
    required this.codename,
    required this.path,
    required this.pathWithType,
    required this.provinceCode,
    required this.provinceName,
    required this.provinceNameWithType,
    required this.wards,
  });

  final int code;
  final String name;
  final String nameWithType;
  final String divisionType;
  final String codename;
  final String path;
  final String pathWithType;
  final int provinceCode;
  final String provinceName;
  final String provinceNameWithType;
  final List<Ward> wards;

  factory District.fromJson(
    Map<String, dynamic> json, {
    required int provinceCode,
    required String provinceName,
    required String provinceNameWithType,
  }) {
    return District(
      code: json['code'] as int,
      name: json['name'] as String? ?? '',
      nameWithType: json['name_with_type'] as String? ?? json['name'] as String? ?? '',
      divisionType: json['division_type'] as String? ?? '',
      codename: json['codename'] as String? ?? '',
      path: json['path'] as String? ?? '',
      pathWithType: json['path_with_type'] as String? ?? '',
      provinceCode: provinceCode,
      provinceName: provinceName,
      provinceNameWithType: provinceNameWithType,
      wards: (json['wards'] as List<dynamic>? ?? [])
          .map(
            (wardJson) => Ward.fromJson(
              wardJson as Map<String, dynamic>,
              districtCode: json['code'] as int,
              districtName: json['name'] as String? ?? '',
              districtNameWithType: json['name_with_type'] as String? ?? json['name'] as String? ?? '',
              provinceCode: provinceCode,
              provinceName: provinceName,
              provinceNameWithType: provinceNameWithType,
            ),
          )
          .toList(),
    );
  }
}

/// Represents a ward/commune (phường/xã/thị trấn/...) unit.
class Ward {
  Ward({
    required this.code,
    required this.name,
    required this.nameWithType,
    required this.divisionType,
    required this.codename,
    required this.path,
    required this.pathWithType,
    required this.districtCode,
    required this.districtName,
    required this.districtNameWithType,
    required this.provinceCode,
    required this.provinceName,
    required this.provinceNameWithType,
  });

  final int code;
  final String name;
  final String nameWithType;
  final String divisionType;
  final String codename;
  final String path;
  final String pathWithType;
  final int districtCode;
  final String districtName;
  final String districtNameWithType;
  final int provinceCode;
  final String provinceName;
  final String provinceNameWithType;

  factory Ward.fromJson(
    Map<String, dynamic> json, {
    required int districtCode,
    required String districtName,
    required String districtNameWithType,
    required int provinceCode,
    required String provinceName,
    required String provinceNameWithType,
  }) {
    return Ward(
      code: json['code'] as int,
      name: json['name'] as String? ?? '',
      nameWithType: json['name_with_type'] as String? ?? json['name'] as String? ?? '',
      divisionType: json['division_type'] as String? ?? '',
      codename: json['codename'] as String? ?? '',
      path: json['path'] as String? ?? '',
      pathWithType: json['path_with_type'] as String? ?? '',
      districtCode: districtCode,
      districtName: districtName,
      districtNameWithType: districtNameWithType,
      provinceCode: provinceCode,
      provinceName: provinceName,
      provinceNameWithType: provinceNameWithType,
    );
  }
}

/// Convenience wrapper returned by the address autocomplete service.
///
/// A single suggestion bundles the selected ward together with its parent
/// district and province, making it trivial for the UI to fill every field.
class AddressSuggestion {
  AddressSuggestion({
    required this.province,
    required this.district,
    required this.ward,
  });

  final Province province;
  final District district;
  final Ward ward;

  /// The text shown in the suggestion list. Prefer the fully qualified
  /// `pathWithType` when available because it includes the "phường/quận/tỉnh"
  /// prefixes that users expect. Fall back to a simple concatenation otherwise.
  String get displayText {
    if (ward.pathWithType.isNotEmpty) {
      return ward.pathWithType;
    }
    return '${ward.nameWithType}, ${district.nameWithType}, ${province.nameWithType}';
  }

  /// A condensed string used for accent-insensitive searches.
  String toSearchableText() {
    return [
      ward.name,
      ward.nameWithType,
      ward.path,
      ward.pathWithType,
      district.name,
      district.nameWithType,
      district.pathWithType,
      province.name,
      province.nameWithType,
    ].where((segment) => segment.isNotEmpty).join(' ');
  }
}


