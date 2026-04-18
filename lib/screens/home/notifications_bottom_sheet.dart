import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../models/chat_room.dart';
import '../../models/notification_item.dart';
import '../../services/chat_service.dart';
import '../../services/notification_storage_service.dart';
import '../chat_screen.dart';
import '../subscription/subscription_screen.dart';
import '../../services/subscription_service.dart';
import 'main_navigation.dart';

class NotificationsBottomSheet extends StatefulWidget {
  const NotificationsBottomSheet({super.key});

  @override
  State<NotificationsBottomSheet> createState() =>
      _NotificationsBottomSheetState();
}

class _NotificationsBottomSheetState extends State<NotificationsBottomSheet> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  bool _isPremium = false;
  final SubscriptionService _subscriptionService = SubscriptionService();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final isPremium = await _subscriptionService.isPremiumUser();
    final list = await NotificationStorageService.fetchAndSave();
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    await NotificationStorageService.markAllAsRead();
    await _loadNotifications();
  }

  Future<void> _onNotificationTap(NotificationItem item) async {
    await NotificationStorageService.markAsRead(item.id);
    if (!mounted) return;
    Navigator.of(context).pop();

    if (item.chatId != null) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userName = prefs.getString('user_name') ?? 'User';
      if (userId == null) return;
      final isPremium = await _subscriptionService.isPremiumUser();
      if (!isPremium && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SubscriptionScreen(),
          ),
        ).then((_) => _loadNotifications());
      } else if (isPremium && userId.isNotEmpty && mounted) {
        try {
          final chats = await ChatService().getUserChats(userId);
          ChatRoom? chat;
          for (final c in chats) {
            if (c.id == item.chatId) {
              chat = c;
              break;
            }
          }
          final otherUser = chat?.getOtherParticipant(userId);
          if (mounted && otherUser != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatId: item.chatId!,
                  currentUserId: userId,
                  currentUserName: userName,
                  otherUser: otherUser,
                ),
              ),
            );
          } else if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MainNavigation(initialIndex: 0),
              ),
            );
          }
        } catch (_) {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MainNavigation(initialIndex: 0),
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                if (_notifications.isNotEmpty)
                  TextButton(
                    onPressed: _isLoading ? null : _markAllRead,
                    child: const Text('Mark all read'),
                  ),
              ],
            ),
          ),
          Flexible(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final n = _notifications[index];
                          return ListTile(
                            onTap: () => _onNotificationTap(n),
                            leading: CircleAvatar(
                              backgroundColor: n.isRead
                                  ? (isDarkMode
                                      ? Colors.grey[700]
                                      : Colors.grey[300])
                                  : AppTheme.primaryColor.withOpacity(0.2),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                color: n.isRead
                                    ? Colors.grey
                                    : AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              (!_isPremium && n.chatId != null) 
                                  ? (n.title.startsWith('Message from ') 
                                      ? n.title.replaceAll('Message from ', '') 
                                      : n.title)
                                  : n.title,
                              style: TextStyle(
                                fontWeight:
                                    n.isRead ? FontWeight.normal : FontWeight.w600,
                                color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              (!_isPremium && n.chatId != null)
                                  ? "wants to send you a message. Tap to subscribe."
                                  : n.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: !_isPremium && n.chatId != null
                                    ? AppTheme.primaryColor
                                    : (isDarkMode ? Colors.white70 : Colors.grey[600]),
                                fontWeight: !_isPremium && n.chatId != null
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: Text(
                              _formatTime(n.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return DateFormat.Hm().format(dt);
    if (diff.inDays < 7) return DateFormat.E().format(dt);
    return DateFormat.Md().format(dt);
  }
}
