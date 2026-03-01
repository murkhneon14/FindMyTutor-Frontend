import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class BannerService {
  /// Fetch banners near a given location
  static Future<List<Map<String, dynamic>>> getNearbyBanners({
    required double latitude,
    required double longitude,
    double radius = 50, // km — search radius for nearby banners
  }) async {
    try {
      final url = ApiConfig.bannersNearby;
      final body = jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      });

      print('🎯 ========== BANNER API CALL ==========');
      print('🎯 URL: $url');
      print('🎯 Request Body: $body');
      print('🎯 =====================================');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('📡 Banner API Response Status: ${response.statusCode}');
      print('📡 Banner API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Parsed data keys: ${data.keys.toList()}');
        print('✅ success: ${data['success']}');
        print('✅ banners: ${data['banners']}');
        print('✅ banners count: ${data['banners']?.length ?? 0}');

        if (data['success'] == true && data['banners'] != null) {
          final banners = List<Map<String, dynamic>>.from(data['banners']);
          print('✅ Returning ${banners.length} banners');
          for (int i = 0; i < banners.length; i++) {
            print('  📌 Banner $i: id=${banners[i]['_id']}, imageUrl=${banners[i]['imageUrl']}, title=${banners[i]['title']}');
          }
          return banners;
        } else {
          print('⚠️ success=${data['success']}, banners=${data['banners']} — not returning any banners');
        }
      } else {
        print('❌ Banner API returned non-200 status: ${response.statusCode}');
      }
      return [];
    } catch (e, stackTrace) {
      print('❌ Error fetching nearby banners: $e');
      print('❌ Stack trace: $stackTrace');
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
