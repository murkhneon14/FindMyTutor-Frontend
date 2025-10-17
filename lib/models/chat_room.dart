import 'chat_message.dart';

class ChatUser {
  final String id;
  final String name;
  final String email;
  final String role;

  ChatUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

class ChatRoom {
  final String id;
  final List<ChatUser> participants;
  final List<ChatMessage> messages;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatRoom({
    required this.id,
    required this.participants,
    this.messages = const [],
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    List<ChatUser> participantsList = [];
    if (json['participants'] != null) {
      final participants = json['participants'] as List;
      
      // Handle both string IDs and full user objects
      participantsList = participants.map((p) {
        if (p is String) {
          // If participant is just an ID string, create a minimal ChatUser
          final names = json['participantNames'] as List?;
          final index = participants.indexOf(p);
          final name = (names != null && index < names.length) 
              ? names[index].toString() 
              : 'User';
          
          return ChatUser(
            id: p,
            name: name,
            email: '',
            role: '',
          );
        } else if (p is Map<String, dynamic>) {
          // If participant is a full user object
          return ChatUser.fromJson(p);
        } else {
          // Fallback
          return ChatUser(id: '', name: 'Unknown', email: '', role: '');
        }
      }).toList();
    }

    List<ChatMessage> messagesList = [];
    if (json['messages'] != null) {
      messagesList = (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList();
    }

    Map<String, int> unreadCountMap = {};
    if (json['unreadCount'] != null) {
      final unreadData = json['unreadCount'];
      if (unreadData is Map) {
        unreadData.forEach((key, value) {
          unreadCountMap[key.toString()] = value is int ? value : 0;
        });
      }
    }

    return ChatRoom(
      id: json['_id'] ?? '',
      participants: participantsList,
      messages: messagesList,
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'])
          : null,
      unreadCount: unreadCountMap,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  ChatUser? getOtherParticipant(String currentUserId) {
    try {
      return participants.firstWhere((p) => p.id != currentUserId);
    } catch (e) {
      return null;
    }
  }

  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }
}
