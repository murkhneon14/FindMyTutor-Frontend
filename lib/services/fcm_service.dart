import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/api.dart';
import '../config/navigator_key.dart';
import '../screens/subscription/subscription_screen.dart';
import 'subscription_service.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  RemoteMessage? _pendingInitialMessage; // Store initial message from terminated state

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ User granted provisional notification permission');
      } else {
        print('❌ User declined notification permission');
        return;
      }

      // Initialize local notifications for foreground messages
      await _initializeLocalNotifications();

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      print('📱 FCM Token: $_fcmToken');

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('🔄 FCM Token refreshed: $newToken');
        // You should update the token on your server here
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // Check if app was opened from a terminated state
      // Store the message but don't handle it yet - wait for app to initialize
      _pendingInitialMessage = await _firebaseMessaging.getInitialMessage();
      if (_pendingInitialMessage != null) {
        print('🔔 App opened from terminated state with notification');
        print('🔔 Pending initial message: ${_pendingInitialMessage!.data}');
      }

      print('✅ FCM Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }

  /// Initialize local notifications for foreground messages
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          _handleNotificationTap(details.payload!);
        }
      },
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('📩 Foreground message received: ${message.notification?.title}');

    // Show local notification when app is in foreground
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'New Message',
        body: message.notification!.body ?? '',
        payload: message.data['chatId'],
      );
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handle notification tap (from background)
  void _handleMessageTap(RemoteMessage message) async {
    print('🔔 Notification tapped: ${message.data}');
    final chatId = message.data['chatId'];
    if (chatId != null && navigatorKey.currentContext != null) {
      // Check if user is premium before navigating
      final subscriptionService = SubscriptionService();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      print('🔔 Checking premium status for user: $userId');
      
      // First check local cache
      final localIsPremium = await subscriptionService.isPremiumUser();
      print('🔔 Local premium status: $localIsPremium');
      
      // Verify with server to ensure accuracy
      bool isPremium = localIsPremium;
      if (userId != null) {
        try {
          final status = await subscriptionService.getSubscriptionStatus(userId);
          isPremium = status['isPremium'] ?? false;
          print('🔔 Server premium status: $isPremium');
        } catch (e) {
          print('⚠️ Could not verify premium status from server: $e');
          // Fall back to local value
        }
      }
      
      if (!isPremium) {
        print('🔔 User is NOT premium - Redirecting to subscription page');
        // Redirect to subscription page if not premium
        Navigator.of(navigatorKey.currentContext!).push(
          MaterialPageRoute(
            builder: (context) => const SubscriptionScreen(),
          ),
        );
      } else {
        // Navigate to chat if premium
        print('🔔 User IS premium - Navigate to chat: $chatId');
        // TODO: Add navigation to chat screen here if needed
      }
    } else {
      print('⚠️ No navigator context or chatId available');
    }
  }

  /// Handle local notification tap
  void _handleNotificationTap(String payload) async {
    print('🔔 Local notification tapped: $payload');
    if (navigatorKey.currentContext != null) {
      // Check if user is premium before navigating
      final subscriptionService = SubscriptionService();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      print('🔔 Checking premium status for user: $userId');
      
      // First check local cache
      final localIsPremium = await subscriptionService.isPremiumUser();
      print('🔔 Local premium status: $localIsPremium');
      
      // Verify with server to ensure accuracy
      bool isPremium = localIsPremium;
      if (userId != null) {
        try {
          final status = await subscriptionService.getSubscriptionStatus(userId);
          isPremium = status['isPremium'] ?? false;
          print('🔔 Server premium status: $isPremium');
        } catch (e) {
          print('⚠️ Could not verify premium status from server: $e');
          // Fall back to local value
        }
      }
      
      if (!isPremium) {
        print('🔔 User is NOT premium - Redirecting to subscription page');
        // Redirect to subscription page if not premium
        Navigator.of(navigatorKey.currentContext!).push(
          MaterialPageRoute(
            builder: (context) => const SubscriptionScreen(),
          ),
        );
      } else {
        // Navigate to chat if premium
        print('🔔 User IS premium - Navigate to chat: $payload');
        // TODO: Add navigation to chat screen here if needed
      }
    } else {
      print('⚠️ No navigator context available');
    }
  }

  /// Handle pending initial message (called after app is fully initialized)
  Future<void> handlePendingInitialMessage() async {
    if (_pendingInitialMessage != null) {
      print('🔔 Handling pending initial message after app initialization');
      // Wait a bit for navigator to be ready
      await Future.delayed(const Duration(milliseconds: 500));
      _handleMessageTap(_pendingInitialMessage!);
      _pendingInitialMessage = null; // Clear after handling
    }
  }

  /// Send FCM token to backend
  Future<bool> sendTokenToServer(String userId) async {
    if (_fcmToken == null) {
      print('❌ No FCM token available');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/user/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'fcmToken': _fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ FCM token sent to server successfully');
        return true;
      } else {
        print('❌ Failed to send FCM token: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending FCM token to server: $e');
      return false;
    }
  }

  /// Remove FCM token from backend (on logout)
  Future<bool> removeTokenFromServer(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/user/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ FCM token removed from server successfully');
        return true;
      } else {
        print('❌ Failed to remove FCM token: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error removing FCM token from server: $e');
      return false;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('✅ Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('✅ Unsubscribed from topic: $topic');
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Background message received: ${message.notification?.title}');
  // Handle background message here
}
