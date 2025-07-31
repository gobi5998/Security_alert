import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widget/google_maps_widget.dart';
import '../services/location_service.dart';

class GoogleMapsExample extends StatefulWidget {
  const GoogleMapsExample({Key? key}) : super(key: key);

  @override
  State<GoogleMapsExample> createState() => _GoogleMapsExampleState();
}

class _GoogleMapsExampleState extends State<GoogleMapsExample> {
  final LocationService _locationService = LocationService();
  LatLng? _selectedLocation;
  String? _selectedAddress;
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadExampleData();
  }

  void _loadExampleData() {
    // Add some example markers
    _markers.add(
      _locationService.createCustomMarker(
        markerId: 'example_1',
        position: const LatLng(37.7749, -122.4194), // San Francisco
        title: 'Example Location 1',
        snippet: 'This is an example marker',
      ),
    );

    _markers.add(
      _locationService.createCustomMarker(
        markerId: 'example_2',
        position: const LatLng(37.7849, -122.4094),
        title: 'Example Location 2',
        snippet: 'Another example marker',
      ),
    );

    // Add example polygon
    _polygons.add(
      _locationService.createPolygon(
        polygonId: 'example_polygon',
        points: const [
          LatLng(37.7749, -122.4194),
          LatLng(37.7849, -122.4194),
          LatLng(37.7849, -122.4094),
          LatLng(37.7749, -122.4094),
        ],
        fillColor: Colors.blue.withOpacity(0.3),
        strokeColor: Colors.blue,
      ),
    );

    // Add example polyline
    _polylines.add(
      _locationService.createPolyline(
        polylineId: 'example_polyline',
        points: const [
          LatLng(37.7749, -122.4194),
          LatLng(37.7849, -122.4094),
        ],
        color: Colors.red,
        width: 3,
      ),
    );
  }

  void _onLocationPicked(LatLng location, String address) {
    setState(() {
      _selectedLocation = location;
      _selectedAddress = address;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location selected: $address'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _openLocationPicker() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationPickerWidget(
          onLocationPicked: _onLocationPicked,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Examples'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Basic Map Example
            _buildSectionTitle('Basic Map'),
            const SizedBox(height: 8),
            const CustomGoogleMap(
              height: 200,
              showCurrentLocation: true,
              showMyLocationButton: true,
            ),
            const SizedBox(height: 24),

            // Map with Custom Markers
            _buildSectionTitle('Map with Custom Markers'),
            const SizedBox(height: 8),
            CustomGoogleMap(
              height: 200,
              markers: _markers,
              initialLatitude: 37.7749,
              initialLongitude: -122.4194,
              zoom: 13.0,
            ),
            const SizedBox(height: 24),

            // Map with Polygons and Polylines
            _buildSectionTitle('Map with Polygons and Polylines'),
            const SizedBox(height: 8),
            CustomGoogleMap(
              height: 200,
              markers: _markers,
              polygons: _polygons,
              polylines: _polylines,
              initialLatitude: 37.7749,
              initialLongitude: -122.4194,
              zoom: 13.0,
            ),
            const SizedBox(height: 24),

            // Satellite Map
            _buildSectionTitle('Satellite Map'),
            const SizedBox(height: 8),
            const CustomGoogleMap(
              height: 200,
              mapType: MapType.satellite,
              showCurrentLocation: true,
            ),
            const SizedBox(height: 24),

            // Location Picker Button
            _buildSectionTitle('Location Picker'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _openLocationPicker,
              icon: const Icon(Icons.location_on),
              label: const Text('Pick Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selected Location Display
            if (_selectedLocation != null) ...[
              _buildSectionTitle('Selected Location'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coordinates:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedAddress != null) ...[
                      Text(
                        'Address:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedAddress!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Location Service Examples
            _buildSectionTitle('Location Service Examples'),
            const SizedBox(height: 8),
            _buildServiceExampleButton(
              'Get Current Location',
              Icons.my_location,
              () async {
                LatLng? location = await _locationService.getCurrentLocation();
                if (location != null) {
                  String? address = await _locationService.getAddressFromCoordinates(
                    location.latitude,
                    location.longitude,
                  );
                  _showLocationDialog('Current Location', location, address);
                } else {
                  _showErrorDialog('Could not get current location');
                }
              },
            ),
            const SizedBox(height: 8),
            _buildServiceExampleButton(
              'Calculate Distance',
              Icons.straighten,
              () async {
                LatLng? location1 = await _locationService.getCurrentLocation();
                if (location1 != null) {
                  LatLng location2 = const LatLng(37.7749, -122.4194); // San Francisco
                  double distance = _locationService.calculateDistance(location1, location2);
                  _showInfoDialog(
                    'Distance Calculation',
                    'Distance from current location to San Francisco: ${distance.toStringAsFixed(2)} meters',
                  );
                } else {
                  _showErrorDialog('Could not get current location');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildServiceExampleButton(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showLocationDialog(String title, LatLng location, String? address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latitude: ${location.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${location.longitude.toStringAsFixed(6)}'),
            if (address != null) ...[
              const SizedBox(height: 8),
              Text('Address: $address'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 