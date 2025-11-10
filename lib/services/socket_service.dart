import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  // Stream controllers for real-time events
  final _messageStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatUpdateStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _messagesReadStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _premiumNotificationStreamController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get chatUpdateStream => _chatUpdateStreamController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingStreamController.stream;
  Stream<Map<String, dynamic>> get messagesReadStream => _messagesReadStreamController.stream;
  Stream<Map<String, dynamic>> get premiumNotificationStream => _premiumNotificationStreamController.stream;

  bool get isConnected => _isConnected;

  void connect(String serverUrl, String userId) {
    if (_isConnected && _socket != null) {
      print('Socket already connected, ensuring user is joined');
      // Make sure user is joined even if already connected
      _socket!.emit('join', userId);
      // Ensure listeners are set up
      _setupSocketListeners();
      return;
    }

    try {
      _socket = IO.io(serverUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      // Set up listeners before connecting
      _setupSocketListeners();

      _socket!.connect();

      _socket!.onConnect((_) {
        print('🔔 Socket connected successfully');
        _isConnected = true;
        print('🔔 Joining user room: $userId');
        _socket!.emit('join', userId);
        print('🔔 Socket listeners set up, ready to receive messages');
        // Verify listeners are set up
        print('🔔 Verifying socket listeners are active...');
      });
      
      _socket!.onError((error) {
        print('🔔 Socket error: $error');
      });

      _socket!.onDisconnect((_) {
        print('Socket disconnected');
        _isConnected = false;
      });

    } catch (e) {
      print('Error connecting to socket: $e');
    }
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    // Set up listeners (socket.io handles duplicate listeners, so this is safe)
    _socket!.on('newMessage', (data) {
      print('🔔 ========== Socket: New message received ==========');
      print('🔔 Data: $data');
      print('🔔 Adding to message stream...');
      _messageStreamController.add(data);
      print('🔔 Message added to stream successfully');
      print('🔔 ================================================');
    });

    _socket!.on('chatUpdated', (data) {
      print('🔔 Socket: Chat updated: $data');
      _chatUpdateStreamController.add(data);
    });

    _socket!.on('userTyping', (data) {
      print('🔔 Socket: User typing: $data');
      _typingStreamController.add(data);
    });

    _socket!.on('messagesRead', (data) {
      print('🔔 Socket: Messages read: $data');
      _messagesReadStreamController.add(data);
    });

    _socket!.on('error', (data) {
      print('🔔 Socket: Error: $data');
    });

    _socket!.on('premiumMessageNotification', (data) {
      print('🔔 Socket: Premium message notification received: $data');
      _premiumNotificationStreamController.add(data);
    });
  }

  void joinChat(String chatId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('joinChat', chatId);
    }
  }

  void leaveChat(String chatId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leaveChat', chatId);
    }
  }

  void sendMessage(Map<String, dynamic> messageData) {
    if (_socket != null && _isConnected) {
      _socket!.emit('sendMessage', messageData);
    }
  }

  void sendTypingIndicator(String chatId, String userId, bool isTyping) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing', {
        'chatId': chatId,
        'userId': userId,
        'isTyping': isTyping,
      });
    }
  }

  void markAsRead(String chatId, String userId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('markAsRead', {
        'chatId': chatId,
        'userId': userId,
      });
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }
  }

  void dispose() {
    disconnect();
    _messageStreamController.close();
    _chatUpdateStreamController.close();
    _typingStreamController.close();
    _messagesReadStreamController.close();
    _premiumNotificationStreamController.close();
  }
}
