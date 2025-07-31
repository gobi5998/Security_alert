import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check and request location permissions
  Future<bool> requestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current location
  Future<LatLng?> getCurrentLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return _formatAddress(place);
      }
      
      return null;
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return null;
    }
  }

  /// Get coordinates from address
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        Location location = locations[0];
        return LatLng(location.latitude, location.longitude);
      }
      
      return null;
    } catch (e) {
      print('Error getting coordinates from address: $e');
      return null;
    }
  }

  /// Calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Get location updates stream
  Stream<Position> getLocationUpdates() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  /// Check if location is within a specific radius
  bool isLocationWithinRadius(LatLng center, LatLng point, double radiusInMeters) {
    double distance = calculateDistance(center, point);
    return distance <= radiusInMeters;
  }

  /// Format address from Placemark
  String _formatAddress(Placemark place) {
    List<String> addressParts = [];
    
    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      addressParts.add(place.postalCode!);
    }
    
    if (place.country != null && place.country!.isNotEmpty) {
      addressParts.add(place.country!);
    }
    
    return addressParts.join(', ');
  }

  /// Get detailed location information
  Future<Map<String, dynamic>?> getDetailedLocationInfo(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return {
          'address': _formatAddress(place),
          'street': place.street,
          'locality': place.locality,
          'administrativeArea': place.administrativeArea,
          'postalCode': place.postalCode,
          'country': place.country,
          'latitude': location.latitude,
          'longitude': location.longitude,
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting detailed location info: $e');
      return null;
    }
  }

  /// Create a custom marker
  Marker createCustomMarker({
    required String markerId,
    required LatLng position,
    String? title,
    String? snippet,
    BitmapDescriptor? icon,
  }) {
    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(
        title: title ?? 'Location',
        snippet: snippet,
      ),
      icon: icon ?? BitmapDescriptor.defaultMarker,
    );
  }

  /// Create a polygon
  Polygon createPolygon({
    required String polygonId,
    required List<LatLng> points,
    Color? fillColor,
    Color? strokeColor,
    int? strokeWidth,
  }) {
    return Polygon(
      polygonId: PolygonId(polygonId),
      points: points,
      fillColor: fillColor ?? Colors.blue.withOpacity(0.3),
      strokeColor: strokeColor ?? Colors.blue,
      strokeWidth: strokeWidth ?? 2,
    );
  }

  /// Create a polyline
  Polyline createPolyline({
    required String polylineId,
    required List<LatLng> points,
    Color? color,
    int? width,
  }) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: color ?? Colors.red,
      width: width ?? 3,
    );
  }
} 