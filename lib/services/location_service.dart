import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';

class LocationService {
  // In-memory cache — survives navigation, resets on app restart
  static Position? _cachedPosition;

  // Distance threshold in km — warn user if they've moved more than this
  static const double _driftThresholdKm = 5.0;

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

  // Force a fresh location fetch (bypasses cache)
  static Future<Position?> getFreshLocation() async {
    _cachedPosition = null;
    return getCurrentLocation();
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

  /// Check if the user has drifted significantly from their stored profile location.
  ///
  /// [storedCoordinates] — GeoJSON coordinates from profile: [longitude, latitude]
  ///
  /// Returns the distance in km if drift exceeds threshold, or null if within range
  /// or if current location could not be determined.
  static Future<double?> checkLocationDrift(List<dynamic> storedCoordinates) async {
    try {
      if (storedCoordinates.length < 2) return null;

      final storedLon = (storedCoordinates[0] as num).toDouble();
      final storedLat = (storedCoordinates[1] as num).toDouble();

      // If stored location is [0,0] (default/never set), skip the check
      if (storedLat == 0.0 && storedLon == 0.0) {
        print('📍 Profile location is default [0,0] — skipping drift check');
        return null;
      }

      final current = await getFreshLocation();
      if (current == null) return null;

      final distanceKm = calculateDistance(
        storedLat,
        storedLon,
        current.latitude,
        current.longitude,
      );

      print('📍 Location drift: ${distanceKm.toStringAsFixed(2)} km '
          '(threshold: $_driftThresholdKm km)');

      if (distanceKm > _driftThresholdKm) {
        return distanceKm;
      }
      return null;
    } catch (e) {
      print('❌ Drift check failed: $e');
      return null;
    }
  }

  /// Update the user's profile location on the backend.
  ///
  /// [role] — "teacher" or "student"
  /// Uses the currently cached/fresh GPS position.
  static Future<bool> updateProfileLocation(String role) async {
    try {
      final position = await getCurrentLocation();
      if (position == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return false;

      final endpoint = role == 'teacher'
          ? ApiConfig.updateTeacherLocation
          : ApiConfig.updateStudentLocation;

      final response = await http.put(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Profile location updated: ${position.latitude}, ${position.longitude}');
        return true;
      } else {
        print('❌ Location update failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ updateProfileLocation error: $e');
      return false;
    }
  }
}
