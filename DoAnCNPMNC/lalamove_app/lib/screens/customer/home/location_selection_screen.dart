import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../utils/constants.dart';
import '../../../services/maps_service.dart';
import 'dart:async';

class LocationSelectionScreen extends StatefulWidget {
  final String locationType; // 'pickup' or 'dropoff'
  final String? currentLocation;
  final double? currentLat;
  final double? currentLng;

  const LocationSelectionScreen({
    super.key,
    required this.locationType,
    this.currentLocation,
    this.currentLat,
    this.currentLng,
  });

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedAddress;
  double? _selectedLat;
  double? _selectedLng;
  
  final MapController _mapController = MapController();
  LatLng _currentPosition = LatLng(10.8231, 106.6297); // Default: Ho Chi Minh City
  final List<Marker> _markers = [];
  bool _isLoadingLocation = false;
  
  final List<Map<String, dynamic>> _savedAddresses = [
    {
      'name': 'Đại học Huflit',
      'address': '190-192 Lý Chính Thắng, Phường Võ Thị Sáu, Quận 3, TP.HCM',
      'lat': 10.7829,
      'lng': 106.6893,
    },
    {
      'name': 'Landmark 81',
      'address': '720A Đ. Điện Biên Phủ, Vinhomes Tân Cảng, Bình Thạnh, TP.HCM',
      'lat': 10.7946,
      'lng': 106.7218,
    },
    {
      'name': '373/155 Lý Thường Kiệt',
      'address': '373/155 Lý Thường Kiệt, Phường 9, Tân Bình, Hồ Chí Minh 700000, Vietnam',
      'lat': 10.7987,
      'lng': 106.6525,
    },
    {
      'name': 'HQC Hóc Môn',
      'address': 'Khu công nghiệp Tân Tạo, Hóc Môn, Hồ Chí Minh',
      'lat': 10.8627,
      'lng': 106.5948,
    },
  ];

  final List<Map<String, dynamic>> _recentLocations = [
    {
      'name': 'HQC Hóc Môn',
      'address': 'Khu công nghiệp Tân Tạo, Hóc Môn, Hồ Chí Minh',
      'lat': 10.8627,
      'lng': 106.5948,
    },
  ];

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.currentLocation != null) {
      _searchController.text = widget.currentLocation!;
      _selectedAddress = widget.currentLocation!;
    }
    if (widget.currentLat != null && widget.currentLng != null) {
      _selectedLat = widget.currentLat;
      _selectedLng = widget.currentLng;
      _currentPosition = LatLng(widget.currentLat!, widget.currentLng!);
      _addMarker(_currentPosition);
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await GoogleMapsService.getCurrentLocation();
      if (position != null) {
        final latLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentPosition = latLng;
          _selectedLat = position.latitude;
          _selectedLng = position.longitude;
        });
        _addMarker(latLng);
        _mapController.move(latLng, 15);
        
        // Get address from coordinates using Nominatim
        final address = await GoogleMapsService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (address != null) {
          setState(() {
            _selectedAddress = address;
            _searchController.text = address;
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _addMarker(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          width: 40,
          height: 40,
          point: position,
          child: const Icon(
            Icons.location_on,
            color: AppColors.primary,
            size: 40,
          ),
        ),
      );
    });
  }

  Future<void> _onMapTapped(LatLng position) async {
    _addMarker(position);
    setState(() {
      _selectedLat = position.latitude;
      _selectedLng = position.longitude;
      _isLoadingLocation = true;
    });

    // Get address from tapped coordinates
    final address = await GoogleMapsService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );
    
    setState(() {
      if (address != null) {
        _selectedAddress = address;
        _searchController.text = address;
      }
      _isLoadingLocation = false;
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      // Try Google Places API first
      final suggestions = await GoogleMapsService.getAddressSuggestions(query);
      
      if (suggestions.isNotEmpty) {
        if (mounted) {
          setState(() {
            _searchResults = suggestions;
            _isSearching = false;
          });
        }
      } else {
        // Fallback: search in saved addresses
        final filtered = _savedAddresses
            .where((addr) =>
                addr['name']!.toLowerCase().contains(query.toLowerCase()) ||
                addr['address']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
        if (mounted) {
          setState(() {
            _searchResults = filtered.map((addr) => {
              'main_text': addr['name'],
              'secondary_text': addr['address'],
              'place_id': null,
              'lat': addr['lat'],
              'lng': addr['lng'],
            }).toList();
            _isSearching = false;
          });
        }
      }
    });
  }

  Future<void> _selectSearchResult(Map<String, dynamic> result) async {
    // Nominatim already includes lat/lng in search results!
    if (result['lat'] != null && result['lng'] != null) {
      final latLng = LatLng(result['lat'], result['lng']);
      setState(() {
        _selectedAddress = result['description'] ?? result['secondary_text'];
        _selectedLat = result['lat'];
        _selectedLng = result['lng'];
        _searchController.text = result['description'] ?? result['main_text'];
        _searchResults = [];
        _currentPosition = latLng;
      });
      _addMarker(latLng);
      _mapController.move(latLng, 15);
    }
  }

  void _selectLocation(Map<String, dynamic> location) {
    Navigator.pop(context, {
      'name': location['name'],
      'address': location['address'],
      'fullAddress': '${location['name']}, ${location['address']}',
      'lat': location['lat'],
      'lng': location['lng'],
    });
  }

  void _confirmLocation() {
    if (_selectedAddress != null) {
      Navigator.pop(context, {
        'name': _selectedAddress!.split(',').first,
        'address': _selectedAddress!,
        'fullAddress': _selectedAddress!,
        'lat': _selectedLat ?? 10.8231,
        'lng': _selectedLng ?? 106.6297,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPickup = widget.locationType == 'pickup';
    final title = isPickup ? 'Pick-up location' : 'Where to...';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.dark),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightGrey, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isPickup ? Icons.circle_outlined : Icons.location_on,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: title,
                        hintStyle: TextStyle(
                          color: AppColors.grey,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
                ],
              ),
            ),
          ),
          
          // OpenStreetMap - 100% FREE, no API key needed!
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightGrey),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition,
                      initialZoom: 15,
                      onTap: (tapPosition, point) => _onMapTapped(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.lalamove.delivery',
                        maxZoom: 19,
                      ),
                      MarkerLayer(
                        markers: _markers,
                      ),
                    ],
                  ),
                  
                  // Current Location Button
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: _getCurrentLocation,
                      child: _isLoadingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            )
                          : const Icon(Icons.my_location, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content based on search
          Expanded(
            flex: 1,
            child: _searchController.text.isNotEmpty && (_searchResults.isNotEmpty || _isSearching)
                ? _buildSearchResults()
                : _buildDefaultContent(),
          ),

          // Confirm Button
          if (_selectedAddress != null && _searchResults.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No results found',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildLocationItem(
          icon: Icons.location_on,
          name: result['main_text'] ?? result['description'] ?? '',
          address: result['secondary_text'] ?? '',
          onTap: () => _selectSearchResult(result),
        );
      },
    );
  }

  Widget _buildDefaultContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Location Access Banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightGrey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.gps_off,
                color: AppColors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location access is off',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap here to turn on',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Saved Addresses
        _buildSectionItem(
          icon: Icons.bookmark,
          iconColor: AppColors.primary,
          title: 'Saved addresses',
          trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
          onTap: () {},
        ),
        const Divider(height: 1),

        const SizedBox(height: 24),

        // Recent Locations
        if (_recentLocations.isNotEmpty) ...[
          ..._recentLocations.map((location) => Column(
                children: [
                  _buildLocationItem(
                    icon: Icons.access_time,
                    name: location['name']!,
                    address: location['address']!,
                    onTap: () => _selectLocation(location),
                  ),
                  const Divider(height: 1),
                ],
              )),
        ],

        const SizedBox(height: 16),

        // Saved Addresses List
        ..._savedAddresses.map((location) => Column(
              children: [
                _buildLocationItem(
                  icon: Icons.bookmark_border,
                  name: location['name']!,
                  address: location['address']!,
                  onTap: () => _selectLocation(location),
                ),
                const Divider(height: 1),
              ],
            )),
      ],
    );
  }

  Widget _buildSectionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.dark,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required String name,
    required String address,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.grey, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

