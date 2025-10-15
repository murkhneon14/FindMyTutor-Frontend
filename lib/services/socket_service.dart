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

  Stream<Map<String, dynamic>> get messageStream => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get chatUpdateStream => _chatUpdateStreamController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingStreamController.stream;
  Stream<Map<String, dynamic>> get messagesReadStream => _messagesReadStreamController.stream;

  bool get isConnected => _isConnected;

  void connect(String serverUrl, String userId) {
    if (_isConnected) {
      print('Socket already connected');
      return;
    }

    try {
      _socket = IO.io(serverUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket!.connect();

      _socket!.onConnect((_) {
        print('Socket connected');
        _isConnected = true;
        _socket!.emit('join', userId);
      });

      _socket!.onDisconnect((_) {
        print('Socket disconnected');
        _isConnected = false;
      });

      _socket!.on('newMessage', (data) {
        print('New message received: $data');
        _messageStreamController.add(data);
      });

      _socket!.on('chatUpdated', (data) {
        print('Chat updated: $data');
        _chatUpdateStreamController.add(data);
      });

      _socket!.on('userTyping', (data) {
        print('User typing: $data');
        _typingStreamController.add(data);
      });

      _socket!.on('messagesRead', (data) {
        print('Messages read: $data');
        _messagesReadStreamController.add(data);
      });

      _socket!.on('error', (data) {
        print('Socket error: $data');
      });

    } catch (e) {
      print('Error connecting to socket: $e');
    }
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
  }
}
