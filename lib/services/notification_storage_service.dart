import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../models/notification_item.dart';

class NotificationStorageService {
  static const String _key = 'saved_notifications';
  static const int _maxStored = 100;

  /// Load notifications from local storage
  static Future<List<NotificationItem>> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final list = jsonDecode(jsonStr) as List<dynamic>?;
      if (list == null) return [];
      return list
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('❌ Error loading notifications from storage: $e');
      return [];
    }
  }

  /// Save notifications to local storage
  static Future<void> saveToStorage(List<NotificationItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = items.take(_maxStored).map((e) => e.toJson()).toList();
      await prefs.setString(_key, jsonEncode(list));
    } catch (e) {
      print('❌ Error saving notifications: $e');
    }
  }

  /// Add a new notification and persist
  static Future<void> addNotification(NotificationItem item) async {
    final list = await loadFromStorage();
    list.insert(0, item);
    await saveToStorage(list);
  }

  /// Mark notification as read
  static Future<void> markAsRead(String id) async {
    final list = await loadFromStorage();
    for (var i = 0; i < list.length; i++) {
      if (list[i].id == id) {
        list[i] = list[i].copyWith(isRead: true);
        break;
      }
    }
    await saveToStorage(list);
  }

  /// Mark all as read
  static Future<void> markAllAsRead() async {
    final list = await loadFromStorage();
    final updated = list.map((e) => e.copyWith(isRead: true)).toList();
    await saveToStorage(updated);
  }

  /// Fetch notifications from API (if backend supports it)
  static Future<List<NotificationItem>> fetchFromApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return await loadFromStorage();

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/notifications'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['notifications'] ?? data;
        if (items is List) {
          final notifications = items
              .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
              .toList();
          if (notifications.isNotEmpty) {
            await saveToStorage(notifications);
            return notifications..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }
        }
      }
    } catch (e) {
      print('⚠️ Could not fetch notifications from API: $e');
    }
    return await loadFromStorage();
  }

  /// Fetch all: try API first, then merge with local, dedupe, and save
  static Future<List<NotificationItem>> fetchAndSave() async {
    final local = await loadFromStorage();
    final fromApi = await fetchFromApi();
    if (fromApi.isEmpty) return local;

    final seen = <String>{};
    final merged = <NotificationItem>[];
    for (final n in fromApi) {
      if (seen.add(n.id)) merged.add(n);
    }
    for (final n in local) {
      if (seen.add(n.id)) merged.add(n);
    }
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await saveToStorage(merged.take(_maxStored).toList());
    return merged;
  }

  /// Get unread count
  static Future<int> getUnreadCount() async {
    final list = await loadFromStorage();
    return list.where((e) => !e.isRead).length;
  }
}
