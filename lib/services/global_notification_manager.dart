import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'socket_service.dart';
import 'notification_service.dart';
import 'notification_storage_service.dart';
import '../models/chat_message.dart';
import '../models/notification_item.dart';
import '../screens/subscription/subscription_screen.dart';
import 'subscription_service.dart';
import '../config/navigator_key.dart';

class GlobalNotificationManager {
  static final GlobalNotificationManager _instance = GlobalNotificationManager._internal();
  factory GlobalNotificationManager() => _instance;
  GlobalNotificationManager._internal();

  final SocketService _socketService = SocketService();
  bool _isInitialized = false;
  String? _currentUserId;
  String? _currentChatId; // Track which chat is currently open
  BuildContext? _context;
  final Map<String, int> _lastNotifiedUnreadCount = {}; // Track last notified unread count per chat

  void initialize(BuildContext context) async {
    try {
      print('🔔 ========== GlobalNotificationManager.initialize() called ==========');
      _context = context;
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('user_id');

      print('🔔 GlobalNotificationManager initializing...');
      print('🔔 User ID: $_currentUserId');
      print('🔔 Context mounted: ${context.mounted}');

      if (_currentUserId != null) {
        // Connect to socket
        if (!_socketService.isConnected) {
          print('🔔 Connecting to socket...');
          _socketService.connect(
            'https://findmy-tutor-backend.onrender.com',
            _currentUserId!,
          );
        } else {
          print('🔔 Socket already connected');
        }

        // Listen for new messages (only set up once)
        if (!_isInitialized) {
          print('🔔 Setting up message stream listener...');
          _socketService.messageStream.listen((data) {
            print('🔔 ========== Message received in stream ==========');
            print('🔔 Message received in stream: $data');
            try {
              final message = ChatMessage.fromJson(data['message']);
              final chatId = data['chatId'] as String?;

              print('🔔 Processing message - Sender: ${message.senderId}, Current User: $_currentUserId');
              print('🔔 Chat ID: $chatId, Current Chat: $_currentChatId');

              // Only show notification if:
              // 1. Message is not from current user
              // 2. User is not currently in that specific chat
              print('🔔 Checking notification conditions...');
              print('🔔 Message sender ID: ${message.senderId}');
              print('🔔 Current user ID: $_currentUserId');
              print('🔔 Message chat ID: $chatId');
              print('🔔 Current chat ID: $_currentChatId');
              
              if (message.senderId != _currentUserId && chatId != _currentChatId) {
                print('🔔 ✅ Conditions met - Showing notification for message from ${message.senderName}');

                // Save to notification storage
                NotificationStorageService.addNotification(NotificationItem(
                  id: 'msg_${message.id}_${DateTime.now().millisecondsSinceEpoch}',
                  title: message.senderName,
                  body: message.text,
                  createdAt: DateTime.now(),
                  chatId: chatId,
                  senderId: message.senderId,
                  type: 'chat',
                ));

                // Use navigatorKey context if available, otherwise use stored context
                final notificationContext = navigatorKey.currentContext ?? _context;
                print('🔔 Notification context check:');
                print('🔔 navigatorKey.currentContext: ${navigatorKey.currentContext}');
                print('🔔 _context: $_context');
                print('🔔 Final notificationContext: $notificationContext');
                
                if (notificationContext != null && notificationContext.mounted) {
                  print('🔔 ✅ Context is valid and mounted - Calling NotificationService');
                  NotificationService.showMessageNotification(
                    context: notificationContext,
                    senderName: message.senderName,
                    message: message.text,
                    onTap: () async {
                      print('🔔 Notification tapped');
                      // Check if user is premium before navigating to chat
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
                      
                      final navContext = navigatorKey.currentContext ?? _context;
                      if (!isPremium && navContext != null) {
                        print('🔔 User is NOT premium - Redirecting to subscription page');
                        // Redirect to subscription page if not premium
                        Navigator.of(navContext).push(
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionScreen(),
                          ),
                        );
                      } else if (isPremium && navContext != null) {
                        // Navigate to chat if premium (this will be handled by the app's navigation)
                        print('🔔 User IS premium - Notification tapped for chat: $chatId');
                        // TODO: Add navigation to chat screen here if needed
                      }
                    },
                  );
                } else {
                  print('⚠️ No valid context available to show notification');
                  print('⚠️ Context is null: ${notificationContext == null}');
                  if (notificationContext != null) {
                    print('⚠️ Context is not mounted: ${!notificationContext.mounted}');
                  }
                }
              } else {
                print('🔔 Notification filtered - Sender is current user or user is in chat');
              }
            } catch (e, stackTrace) {
              print('❌ Error processing message: $e');
              print('❌ Stack trace: $stackTrace');
            }
          });
          print('🔔 Message stream listener set up successfully');

          // Listen for chat updates (fallback if newMessage events don't work)
          _socketService.chatUpdateStream.listen((data) {
            print('🔔 Chat update received: $data');
            // Check if this is a new message (unread count increased)
            final unreadCount = data['unreadCount'] as int? ?? 0;
            final lastMessage = data['lastMessage'] as String?;
            final chatId = data['chatId'] as String?;
            
            print('🔔 Chat update - unreadCount: $unreadCount, lastMessage: $lastMessage, chatId: $chatId');
            
            // Only show notification if:
            // 1. There are unread messages
            // 2. User is not currently in that chat
            // 3. Last message exists
            // 4. Unread count has increased since last notification
            final lastNotifiedCount = _lastNotifiedUnreadCount[chatId] ?? 0;
            final unreadIncreased = unreadCount > lastNotifiedCount;
            
            if (unreadCount > 0 && 
                chatId != null &&
                chatId != _currentChatId && 
                lastMessage != null && 
                lastMessage.isNotEmpty &&
                unreadIncreased) {
              print('🔔 ✅ Chat update conditions met - Showing notification');
              // Update last notified count
              _lastNotifiedUnreadCount[chatId] = unreadCount;

              // Save to notification storage
              NotificationStorageService.addNotification(NotificationItem(
                id: 'chat_${chatId}_${DateTime.now().millisecondsSinceEpoch}',
                title: 'New Message',
                body: lastMessage,
                createdAt: DateTime.now(),
                chatId: chatId,
                type: 'chat',
              ));

              final notificationContext = navigatorKey.currentContext ?? _context;
              if (notificationContext != null && notificationContext.mounted) {
                // Show a generic notification for chat update
                NotificationService.showMessageNotification(
                  context: notificationContext,
                  senderName: 'New Message',
                  message: lastMessage,
                  onTap: () async {
                    print('🔔 Chat update notification tapped');
                    final subscriptionService = SubscriptionService();
                    final prefs = await SharedPreferences.getInstance();
                    final userId = prefs.getString('user_id');
                    
                    final localIsPremium = await subscriptionService.isPremiumUser();
                    bool isPremium = localIsPremium;
                    if (userId != null) {
                      try {
                        final status = await subscriptionService.getSubscriptionStatus(userId);
                        isPremium = status['isPremium'] ?? false;
                      } catch (e) {
                        print('⚠️ Could not verify premium status: $e');
                      }
                    }
                    
                    final navContext = navigatorKey.currentContext ?? _context;
                    if (!isPremium && navContext != null) {
                      Navigator.of(navContext).push(
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionScreen(),
                        ),
                      );
                    }
                  },
                );
              }
            }
          });

          // Listen for premium message notifications
          _socketService.premiumNotificationStream.listen((data) {
            print('🔔 Premium notification received: $data');
            final notificationContext = navigatorKey.currentContext ?? _context;
            if (notificationContext != null) {
              _showPremiumNotificationDialog(data);
            } else {
              print('⚠️ No context available to show premium notification dialog');
            }
          });

          _isInitialized = true;
          print('✅ GlobalNotificationManager initialized successfully');
          print('🔔 Socket connected: ${_socketService.isConnected}');
        } else {
          print('🔔 GlobalNotificationManager already initialized, updating context');
          // Still update context even if already initialized
          _context = context;
        }
      } else {
        print('⚠️ No user ID found, cannot initialize notifications');
      }
    } catch (e, stackTrace) {
      print('❌ Error initializing GlobalNotificationManager: $e');
      print('❌ Stack trace: $stackTrace');
    }
    print('🔔 ========== GlobalNotificationManager.initialize() completed ==========');
  }

  void setCurrentChatId(String? chatId) {
    _currentChatId = chatId;
    // Clear notification tracking when user opens a chat
    if (chatId != null) {
      _lastNotifiedUnreadCount.remove(chatId);
    }
  }

  void updateContext(BuildContext context) {
    _context = context;
  }

  void _showPremiumNotificationDialog(Map<String, dynamic> data) {
    final dialogContext = navigatorKey.currentContext ?? _context;
    if (dialogContext == null) {
      print('⚠️ No context available to show premium notification dialog');
      return;
    }

    final message = data['message'] ?? 'Someone is trying to connect with you! To see who and read their message, subscribe now!';

    print('🔔 Showing premium notification dialog');

    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.orange, size: 28),
            const SizedBox(width: 10),
            const Expanded(child: Text('New Connection Request')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Subscribe to see who sent you a message and read it!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              final navContext = navigatorKey.currentContext ?? _context;
              if (navContext != null) {
                Navigator.of(navContext).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Subscribe Now',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void dispose() {
    _isInitialized = false;
    _currentChatId = null;
    _context = null;
  }
}
