import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';
import '../services/global_notification_manager.dart';
import '../config/api.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String currentUserName;
  final ChatUser otherUser;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.currentUserId,
    required this.currentUserName,
    required this.otherUser,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final SocketService _socketService = SocketService();
  final GlobalNotificationManager _notificationManager =
      GlobalNotificationManager();
  final List<types.Message> _messages = [];
  late types.User _currentUser;
  late types.User _otherUser;
  bool _isLoading = true;
  bool _isOtherUserTyping = false;

  @override
  void initState() {
    super.initState();
    // Tell notification manager we're in this chat
    _notificationManager.setCurrentChatId(widget.chatId);
    _initializeChat();
  }

  void _initializeChat() {
    // Initialize users
    _currentUser = types.User(
      id: widget.currentUserId,
      firstName: widget.currentUserName,
    );

    _otherUser = types.User(
      id: widget.otherUser.id,
      firstName: widget.otherUser.name,
    );

    // Connect to socket if not already connected
    if (!_socketService.isConnected) {
      print('Connecting to socket: ${ApiConfig.socketUrl}');
      _socketService.connect(ApiConfig.socketUrl, widget.currentUserId);

      // Wait a bit for connection to establish, then join chat
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_socketService.isConnected) {
          _socketService.joinChat(widget.chatId);
          print('Joined chat: ${widget.chatId}');
        } else {
          print('Socket not connected yet, retrying...');
          Future.delayed(const Duration(seconds: 1), () {
            _socketService.joinChat(widget.chatId);
          });
        }
      });
    } else {
      // Already connected, join immediately
      _socketService.joinChat(widget.chatId);
      print('Joined chat: ${widget.chatId}');
    }

    // Listen to new messages
    _socketService.messageStream.listen((data) {
      if (data['chatId'] == widget.chatId) {
        final message = ChatMessage.fromJson(data['message']);
        // Only add messages from other users (not your own sent messages)
        if (message.senderId != widget.currentUserId) {
          _addMessage(message);
        }
      }
    });

    // Listen to typing indicators
    _socketService.typingStream.listen((data) {
      if (data['userId'] != widget.currentUserId) {
        setState(() {
          _isOtherUserTyping = data['isTyping'] ?? false;
        });
      }
    });

    // Load messages
    _loadMessages();

    // Mark messages as read
    _socketService.markAsRead(widget.chatId, widget.currentUserId);
  }

  Future<void> _loadMessages() async {
    final messages = await _chatService.getChatMessages(
      widget.chatId,
      userId: widget.currentUserId,
    );
    setState(() {
      _messages.clear();
      for (var msg in messages.reversed) {
        _messages.add(_convertToFlutterChatMessage(msg));
      }
      _isLoading = false;
    });
  }

  types.Message _convertToFlutterChatMessage(ChatMessage message) {
    return types.TextMessage(
      author: types.User(id: message.senderId, firstName: message.senderName),
      createdAt: message.createdAt.millisecondsSinceEpoch,
      id: message.id,
      text: message.text,
      status: _getMessageStatus(message.status),
    );
  }

  types.Status? _getMessageStatus(String status) {
    switch (status) {
      case 'sent':
        return types.Status.sent;
      case 'delivered':
        return types.Status.delivered;
      case 'read':
        return types.Status.seen;
      default:
        return types.Status.sent;
    }
  }

  void _addMessage(ChatMessage message) {
    final flutterMessage = _convertToFlutterChatMessage(message);
    setState(() {
      _messages.insert(0, flutterMessage);
    });
  }

  void _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: _currentUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
      status: types.Status.sending,
    );

    setState(() {
      _messages.insert(0, textMessage);
    });

    // Try to send via socket first
    if (_socketService.isConnected) {
      print('Sending message via socket...');
      _socketService.sendMessage({
        'chatId': widget.chatId,
        'senderId': widget.currentUserId,
        'text': message.text,
        'type': 'text',
      });

      // Update status to sent after a short delay (socket doesn't return confirmation immediately)
      Future.delayed(const Duration(milliseconds: 500), () {
        final index = _messages.indexWhere((m) => m.id == textMessage.id);
        if (index != -1 && mounted) {
          final updatedMessage = textMessage.copyWith(
            status: types.Status.sent,
          );
          setState(() {
            _messages[index] = updatedMessage;
          });
        }
      });
    } else {
      // Fallback to HTTP if socket is not connected
      print('Socket not connected, sending via HTTP...');
      try {
        final sentMessage = await _chatService.sendMessage(
          chatId: widget.chatId,
          senderId: widget.currentUserId,
          text: message.text,
        );

        if (sentMessage != null) {
          // Remove the temporary message and add the real one from server
          final index = _messages.indexWhere((m) => m.id == textMessage.id);
          if (index != -1) {
            final realMessage = _convertToFlutterChatMessage(sentMessage);
            setState(() {
              _messages[index] = realMessage;
            });
          }
          print('Message sent successfully via HTTP');
        } else {
          // Failed to send - update status to error
          print('Failed to send message via HTTP');
          final index = _messages.indexWhere((m) => m.id == textMessage.id);
          if (index != -1 && mounted) {
            final errorMessage = textMessage.copyWith(
              status: types.Status.error,
            );
            setState(() {
              _messages[index] = errorMessage;
            });
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to send message. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('Error sending message: $e');
        // Update status to error
        final index = _messages.indexWhere((m) => m.id == textMessage.id);
        if (index != -1 && mounted) {
          final errorMessage = textMessage.copyWith(status: types.Status.error);
          setState(() {
            _messages[index] = errorMessage;
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUser.name),
            if (_isOtherUserTyping)
              const Text(
                'typing...',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              )
            else
              Text(widget.otherUser.role, style: const TextStyle(fontSize: 12)),
          ],
        ),
        elevation: 1,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Chat(
              messages: _messages,
              onSendPressed: _handleSendPressed,
              onPreviewDataFetched: _handlePreviewDataFetched,
              user: _currentUser,
              showUserAvatars: true,
              showUserNames: false,
              theme: DefaultChatTheme(
                backgroundColor: Colors.grey[100]!,
                primaryColor: Theme.of(context).primaryColor,
                secondaryColor: Colors.grey[300]!,
                inputBackgroundColor: Colors.white,
                inputTextColor: Colors.black87,
                receivedMessageBodyTextStyle: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                sentMessageBodyTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              emptyState: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No messages yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start the conversation!',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    // Tell notification manager we left this chat
    _notificationManager.setCurrentChatId(null);
    _socketService.leaveChat(widget.chatId);
    super.dispose();
  }
}
