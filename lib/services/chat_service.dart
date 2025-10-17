import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../config/api.dart';

class ChatService {

  // Get or create a chat between two users
  Future<ChatRoom?> getOrCreateChat(String userId, String otherUserId) async {
    try {
      print('Creating chat: userId=$userId, otherUserId=$otherUserId');
      final response = await http.post(
        Uri.parse(ApiConfig.chatCreate),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'otherUserId': otherUserId,
        }),
      );

      print('Chat creation response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ChatRoom.fromJson(data['chat']);
      } else {
        print('❌ Error creating chat: ${response.body}');
        print('❌ Your user ID: $userId');
        print('❌ Other user ID: $otherUserId');
        print('⚠️ One of these users does not exist in the backend database');
        return null;
      }
    } catch (e) {
      print('Error in getOrCreateChat: $e');
      return null;
    }
  }

  // Get all chats for a user
  Future<List<ChatRoom>> getUserChats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.chatUser(userId)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> chatsJson = data['chats'];
        return chatsJson.map((json) => ChatRoom.fromJson(json)).toList();
      } else {
        print('Error getting user chats: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error in getUserChats: $e');
      return [];
    }
  }

  // Get messages from a specific chat
  Future<List<ChatMessage>> getChatMessages(
    String chatId, {
    int limit = 50,
    int skip = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.chatMessages(chatId)}?limit=$limit&skip=$skip'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> messagesJson = data['messages'];
        return messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        print('Error getting chat messages: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error in getChatMessages: $e');
      return [];
    }
  }

  // Send a message (HTTP fallback)
  Future<ChatMessage?> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String type = 'text',
    String? fileUrl,
    String? fileName,
    int? fileSize,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.chatSendMessage),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chatId': chatId,
          'senderId': senderId,
          'text': text,
          'type': type,
          'fileUrl': fileUrl,
          'fileName': fileName,
          'fileSize': fileSize,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ChatMessage.fromJson(data['message']);
      } else {
        print('Error sending message: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error in sendMessage: $e');
      return null;
    }
  }

  // Mark messages as read
  Future<bool> markAsRead(String chatId, String userId) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.chatMarkAsRead),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chatId': chatId,
          'userId': userId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error in markAsRead: $e');
      return false;
    }
  }

  // Delete a chat
  Future<bool> deleteChat(String chatId) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.chatDelete(chatId)),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error in deleteChat: $e');
      return false;
    }
  }
}
