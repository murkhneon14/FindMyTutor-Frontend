import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class BannerService {
  /// Fetch banners near a given location
  static Future<List<Map<String, dynamic>>> getNearbyBanners({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.bannersNearby),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['banners'] != null) {
          return List<Map<String, dynamic>>.from(data['banners']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching nearby banners: $e');
      return [];
    }
  }

  /// Track banner impression
  static Future<void> trackImpression(String bannerId) async {
    try {
      await http.post(
        Uri.parse(ApiConfig.bannerImpression(bannerId)),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // Silently fail — non-critical
    }
  }

  /// Track banner click
  static Future<void> trackClick(String bannerId) async {
    try {
      await http.post(
        Uri.parse(ApiConfig.bannerClick(bannerId)),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // Silently fail — non-critical
    }
  }
}
