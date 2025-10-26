import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../config/api.dart';

class ChatService {

  // Get or create a chat between two users
  Future<ChatRoom?> getOrCreateChat(String userId, String otherUserId) async {
    try {
      print('💬 ========== CREATING CHAT ==========');
      print('💬 Your user ID: $userId');
      print('💬 Other user ID: $otherUserId');
      
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        print('❌ No auth token found');
        throw Exception('AUTH_ERROR: No authentication token found. Please login again.');
      }
      
      print('💬 Auth token: ${token.substring(0, 20)}...');
      print('💬 Endpoint: ${ApiConfig.chatCreate}');
      
      final response = await http.post(
        Uri.parse(ApiConfig.chatCreate),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'otherUserId': otherUserId,
        }),
      );

      print('💬 Chat creation response: ${response.statusCode}');
      print('💬 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Chat created successfully');
        return ChatRoom.fromJson(data['chat']);
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Premium subscription required';
        print('❌ Premium subscription required: $message');
        throw Exception('PREMIUM_REQUIRED: $message');
      } else if (response.statusCode == 404) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'User not found';
        print('❌ Error: $message');
        print('❌ Your user ID: $userId');
        print('❌ Other user ID: $otherUserId');
        print('⚠️ This means one or both users do not exist in the backend database.');
        print('⚠️ Solution: Both users need to complete their profile setup (student/teacher profile).');
        throw Exception('USER_NOT_FOUND: One or both users have not completed their profile. Please ensure both users have filled out their student or teacher profile.');
      } else {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Failed to create chat';
        print('❌ Error creating chat: $message');
        print('❌ Your user ID: $userId');
        print('❌ Other user ID: $otherUserId');
        throw Exception('CHAT_ERROR: $message');
      }
    } catch (e) {
      print('❌ Exception in getOrCreateChat: $e');
      rethrow;
    }
  }

  // Get all chats for a user
  Future<List<ChatRoom>> getUserChats(String userId) async {
    try {
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.get(
        Uri.parse(ApiConfig.chatUser(userId)),
        headers: headers,
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
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.get(
        Uri.parse('${ApiConfig.chatMessages(chatId)}?limit=$limit&skip=$skip'),
        headers: headers,
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
