import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'socket_service.dart';
import 'notification_service.dart';
import '../models/chat_message.dart';

class GlobalNotificationManager {
  static final GlobalNotificationManager _instance = GlobalNotificationManager._internal();
  factory GlobalNotificationManager() => _instance;
  GlobalNotificationManager._internal();

  final SocketService _socketService = SocketService();
  bool _isInitialized = false;
  String? _currentUserId;
  String? _currentChatId; // Track which chat is currently open
  BuildContext? _context;

  void initialize(BuildContext context) async {
    if (_isInitialized) return;

    _context = context;
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id');

    if (_currentUserId != null) {
      // Connect to socket
      if (!_socketService.isConnected) {
        _socketService.connect(
          'https://findmy-tutor-backend.onrender.com',
          _currentUserId!,
        );
      }

      // Listen for new messages
      _socketService.messageStream.listen((data) {
        if (_context != null && _context!.mounted) {
          final message = ChatMessage.fromJson(data['message']);
          final chatId = data['chatId'] as String?;

          // Only show notification if:
          // 1. Message is not from current user
          // 2. User is not currently in that specific chat
          if (message.senderId != _currentUserId && chatId != _currentChatId) {
            NotificationService.showMessageNotification(
              context: _context!,
              senderName: message.senderName,
              message: message.text,
              onTap: () {
                // Navigation will be handled by the app
                print('Notification tapped for chat: $chatId');
              },
            );
          }
        }
      });

      _isInitialized = true;
    }
  }

  void setCurrentChatId(String? chatId) {
    _currentChatId = chatId;
  }

  void updateContext(BuildContext context) {
    _context = context;
  }

  void dispose() {
    _isInitialized = false;
    _currentChatId = null;
    _context = null;
  }
}
