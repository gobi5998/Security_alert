import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomGoogleMap extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final double? zoom;
  final bool showCurrentLocation;
  final bool showLocationPicker;
  final Function(LatLng)? onLocationSelected;
  final Function(String)? onAddressSelected;
  final Set<Marker>? markers;
  final Set<Polygon>? polygons;
  final Set<Polyline>? polylines;
  final bool showMyLocationButton;
  final bool showZoomControls;
  final MapType mapType;
  final Color? mapStyle;
  final double height;
  final double width;

  const CustomGoogleMap({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.zoom = 15.0,
    this.showCurrentLocation = true,
    this.showLocationPicker = false,
    this.onLocationSelected,
    this.onAddressSelected,
    this.markers,
    this.polygons,
    this.polylines,
    this.showMyLocationButton = true,
    this.showZoomControls = true,
    this.mapType = MapType.normal,
    this.mapStyle,
    this.height = 300,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  State<CustomGoogleMap> createState() => _CustomGoogleMapState();
}

class _CustomGoogleMapState extends State<CustomGoogleMap> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _currentAddress;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Request location permissions
      await _requestLocationPermission();
      
      // Get current location
      if (widget.showCurrentLocation) {
        await _getCurrentLocation();
      }

      // Set initial location
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        _currentLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      } else if (_currentLocation == null) {
        // Default to a central location if no location available
        _currentLocation = const LatLng(0.0, 0.0);
      }

      // Add custom markers if provided
      if (widget.markers != null) {
        _markers.addAll(widget.markers!);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing map: $e');
      setState(() {
        _isLoading = false;
        _currentLocation = const LatLng(0.0, 0.0);
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // Get address for current location
      await _getAddressFromLatLng(_currentLocation!);
      
      // Animate to current location
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, widget.zoom!),
        );
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.street}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}';
        setState(() {
          _currentAddress = address;
        });
        
        if (widget.onAddressSelected != null) {
          widget.onAddressSelected!(address);
        }
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Apply custom map style if provided
    if (widget.mapStyle != null) {
      // You can load custom map styles from JSON files here
    }
  }

  void _onCameraMove(CameraPosition position) {
    if (widget.showLocationPicker) {
      setState(() {
        _selectedLocation = position.target;
      });
    }
  }

  void _onMapTap(LatLng latLng) {
    if (widget.showLocationPicker) {
      setState(() {
        _selectedLocation = latLng;
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('selected_location'),
            position: latLng,
            infoWindow: const InfoWindow(title: 'Selected Location'),
          ),
        );
      });
      
      if (widget.onLocationSelected != null) {
        widget.onLocationSelected!(latLng);
      }
      
      _getAddressFromLatLng(latLng);
    }
  }

  void _goToCurrentLocation() {
    if (_currentLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, widget.zoom!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentLocation!,
                zoom: widget.zoom!,
              ),
              onCameraMove: _onCameraMove,
              onTap: _onMapTap,
              markers: _markers,
              polygons: widget.polygons ?? {},
              polylines: widget.polylines ?? {},
              mapType: widget.mapType,
              myLocationEnabled: widget.showCurrentLocation,
              myLocationButtonEnabled: false, // We'll create custom button
              zoomControlsEnabled: widget.showZoomControls,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
            ),
            
            // Custom location button
            if (widget.showMyLocationButton)
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: _goToCurrentLocation,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  child: const Icon(Icons.my_location),
                ),
              ),
            
            // Location picker indicator
            if (widget.showLocationPicker && _selectedLocation != null)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Location Selected',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// Location Picker Widget
class LocationPickerWidget extends StatefulWidget {
  final Function(LatLng, String) onLocationPicked;
  final double height;
  final double width;

  const LocationPickerWidget({
    Key? key,
    required this.onLocationPicked,
    this.height = 400,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  LatLng? _selectedLocation;
  String? _selectedAddress;

  void _onLocationSelected(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _onAddressSelected(String address) {
    setState(() {
      _selectedAddress = address;
    });
  }

  void _confirmLocation() {
    if (_selectedLocation != null && _selectedAddress != null) {
      widget.onLocationPicked(_selectedLocation!, _selectedAddress!);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomGoogleMap(
              height: widget.height,
              width: widget.width,
              showLocationPicker: true,
              onLocationSelected: _onLocationSelected,
              onAddressSelected: _onAddressSelected,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedAddress != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedAddress!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _selectedLocation != null ? _confirmLocation : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Confirm Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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