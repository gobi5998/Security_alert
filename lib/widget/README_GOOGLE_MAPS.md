# Google Maps Integration for Security Alert App

This directory contains reusable Google Maps widgets and services for the Security Alert Flutter application.

## Features

- **CustomGoogleMap**: A reusable Google Maps widget with multiple customization options
- **LocationPickerWidget**: A full-screen location picker with address selection
- **LocationService**: A service class for handling location-related operations
- **Permission Handling**: Automatic location permission requests
- **Geocoding**: Convert coordinates to addresses and vice versa
- **Custom Markers**: Support for custom markers, polygons, and polylines
- **Multiple Map Types**: Normal, satellite, terrain, and hybrid maps

## Setup Instructions

### 1. Dependencies

The following dependencies have been added to `pubspec.yaml`:

```yaml
dependencies:
  google_maps_flutter: ^2.5.3
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  permission_handler: ^11.1.0
```

### 2. Android Configuration

Add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

Add your Google Maps API key to `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_GOOGLE_MAPS_API_KEY" />
</application>
```

### 3. iOS Configuration

Add the following permissions to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location when open to show your current location on the map.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs access to location when in the background to track your location.</string>
```

Add your Google Maps API key to `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 4. Get Google Maps API Key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Maps SDK for Android and iOS
4. Create credentials (API Key)
5. Restrict the API key to your app's package name for security

## Usage Examples

### Basic Map

```dart
import 'package:your_app/widget/google_maps_widget.dart';

CustomGoogleMap(
  height: 300,
  showCurrentLocation: true,
  showMyLocationButton: true,
)
```

### Map with Custom Markers

```dart
Set<Marker> markers = {
  Marker(
    markerId: MarkerId('location_1'),
    position: LatLng(37.7749, -122.4194),
    infoWindow: InfoWindow(title: 'San Francisco'),
  ),
};

CustomGoogleMap(
  height: 300,
  markers: markers,
  initialLatitude: 37.7749,
  initialLongitude: -122.4194,
  zoom: 13.0,
)
```

### Location Picker

```dart
void _openLocationPicker() {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => LocationPickerWidget(
        onLocationPicked: (location, address) {
          print('Selected location: $location');
          print('Address: $address');
        },
      ),
    ),
  );
}
```

### Using Location Service

```dart
import 'package:your_app/services/location_service.dart';

final LocationService locationService = LocationService();

// Get current location
LatLng? currentLocation = await locationService.getCurrentLocation();

// Get address from coordinates
String? address = await locationService.getAddressFromCoordinates(
  latitude,
  longitude,
);

// Calculate distance between two points
double distance = locationService.calculateDistance(point1, point2);
```

## Widget Properties

### CustomGoogleMap

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `initialLatitude` | `double?` | `null` | Initial latitude |
| `initialLongitude` | `double?` | `null` | Initial longitude |
| `zoom` | `double` | `15.0` | Initial zoom level |
| `showCurrentLocation` | `bool` | `true` | Show current location dot |
| `showLocationPicker` | `bool` | `false` | Enable location picking mode |
| `onLocationSelected` | `Function(LatLng)?` | `null` | Callback when location is selected |
| `onAddressSelected` | `Function(String)?` | `null` | Callback when address is resolved |
| `markers` | `Set<Marker>?` | `null` | Custom markers to display |
| `polygons` | `Set<Polygon>?` | `null` | Polygons to display |
| `polylines` | `Set<Polyline>?` | `null` | Polylines to display |
| `showMyLocationButton` | `bool` | `true` | Show my location button |
| `showZoomControls` | `bool` | `true` | Show zoom controls |
| `mapType` | `MapType` | `MapType.normal` | Type of map to display |
| `height` | `double` | `300` | Height of the map |
| `width` | `double` | `double.infinity` | Width of the map |

### LocationPickerWidget

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `onLocationPicked` | `Function(LatLng, String)` | Required | Callback when location is confirmed |
| `height` | `double` | `400` | Height of the map |
| `width` | `double` | `double.infinity` | Width of the map |

## Location Service Methods

- `requestLocationPermission()`: Request location permissions
- `getCurrentLocation()`: Get current device location
- `getAddressFromCoordinates()`: Convert coordinates to address
- `getCoordinatesFromAddress()`: Convert address to coordinates
- `calculateDistance()`: Calculate distance between two points
- `getLocationUpdates()`: Stream of location updates
- `isLocationWithinRadius()`: Check if location is within radius
- `getDetailedLocationInfo()`: Get detailed location information
- `createCustomMarker()`: Create custom map marker
- `createPolygon()`: Create map polygon
- `createPolyline()`: Create map polyline

## Security Considerations

1. **API Key Security**: Always restrict your Google Maps API key to your app's package name
2. **Location Permissions**: Request only necessary location permissions
3. **Data Privacy**: Handle location data according to privacy regulations
4. **Error Handling**: Implement proper error handling for location services

## Troubleshooting

### Common Issues

1. **Map not loading**: Check if API key is correctly configured
2. **Location not working**: Ensure location permissions are granted
3. **Address not resolving**: Check internet connectivity
4. **Build errors**: Run `flutter clean` and `flutter pub get`

### Debug Tips

- Enable location services on device
- Check API key restrictions
- Verify package name matches API key configuration
- Test on physical device (location services may not work on emulator)

## Example Implementation

See `lib/examples/google_maps_example.dart` for a complete implementation example with all features demonstrated. 