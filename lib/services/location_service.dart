import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // In-memory cache — survives navigation, resets on app restart
  static Position? _cachedPosition;

  // Get current location with permission handling
  static Future<Position?> getCurrentLocation() async {
    // Return cached position instantly if available
    if (_cachedPosition != null) {
      print('📍 Using cached position (instant): ${_cachedPosition!.latitude}, ${_cachedPosition!.longitude}');
      return _cachedPosition;
    }

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable location services.');
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in settings.');
      }

      // Fetch with high accuracy
      print('📍 Fetching fresh location (high accuracy)...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Cache it for the rest of this app session
      _cachedPosition = position;
      print('📍 Location cached: ${position.latitude}, ${position.longitude}');

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // Open app settings
  static Future<void> openLocationSettings() async {
    await openAppSettings();
  }

  // Calculate distance between two points in kilometers
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        ) /
        1000; // Convert meters to kilometers
  }
}
