import 'package:flutter/material.dart';
import '../screens/chat_list_screen.dart';
import '../screens/start_chat_screen.dart';
import '../services/socket_service.dart';
import '../config/api.dart';

/// Example: How to integrate chat into your existing app
/// 
/// This file demonstrates various ways to integrate the chat system
/// into your FindMyTutor application.

class ChatIntegrationExample extends StatefulWidget {
  const ChatIntegrationExample({Key? key}) : super(key: key);

  @override
  State<ChatIntegrationExample> createState() => _ChatIntegrationExampleState();
}

class _ChatIntegrationExampleState extends State<ChatIntegrationExample> {
  final SocketService _socketService = SocketService();
  
  // Replace these with actual user data from your auth system
  final String currentUserId = "USER_ID_FROM_AUTH";
  final String currentUserName = "Current User Name";

  @override
  void initState() {
    super.initState();
    // Initialize socket connection when app starts
    _initializeSocket();
  }

  void _initializeSocket() {
    // Connect to socket server
    // URL is automatically configured from ApiConfig
    _socketService.connect(ApiConfig.socketUrl, currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Integration Examples'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExampleCard(
            title: '1. Open Chat List',
            description: 'Show all conversations for the current user',
            onTap: _openChatList,
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            title: '2. Start Chat with Teacher',
            description: 'Start a new chat with a specific teacher',
            onTap: _startChatWithTeacher,
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            title: '3. Start Chat with Student',
            description: 'Start a new chat with a specific student',
            onTap: _startChatWithStudent,
          ),
          const SizedBox(height: 24),
          const Text(
            'Integration Tips:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            '• Add a chat icon to your teacher/student profile pages',
          ),
          _buildTipCard(
            '• Show unread message count badge on navigation bar',
          ),
          _buildTipCard(
            '• Initialize socket connection after user login',
          ),
          _buildTipCard(
            '• Disconnect socket on logout',
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard({
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTipCard(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, size: 20, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tip),
          ),
        ],
      ),
    );
  }

  void _openChatList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatListScreen(
          currentUserId: currentUserId,
          currentUserName: currentUserName,
        ),
      ),
    );
  }

  void _startChatWithTeacher() {
    // Example: Start chat with a teacher
    // Replace with actual teacher data from your app
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartChatScreen(
          currentUserId: currentUserId,
          currentUserName: currentUserName,
          otherUserId: 'TEACHER_USER_ID',
          otherUserName: 'Teacher Name',
          otherUserRole: 'teacher',
        ),
      ),
    );
  }

  void _startChatWithStudent() {
    // Example: Start chat with a student
    // Replace with actual student data from your app
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartChatScreen(
          currentUserId: currentUserId,
          currentUserName: currentUserName,
          otherUserId: 'STUDENT_USER_ID',
          otherUserName: 'Student Name',
          otherUserRole: 'student',
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Disconnect socket when leaving the app
    // Note: You might want to do this on logout instead
    // _socketService.disconnect();
    super.dispose();
  }
}

/// Example: Add chat button to teacher profile
class TeacherProfileWithChat extends StatelessWidget {
  final String teacherId;
  final String teacherName;
  final String currentUserId;
  final String currentUserName;

  const TeacherProfileWithChat({
    Key? key,
    required this.teacherId,
    required this.teacherName,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(teacherName),
        actions: [
          // Add chat icon to app bar
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => _startChat(context),
            tooltip: 'Message Teacher',
          ),
        ],
      ),
      body: Column(
        children: [
          // Your existing teacher profile UI
          const Expanded(
            child: Center(
              child: Text('Teacher Profile Content'),
            ),
          ),
          
          // Chat button at bottom
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _startChat(context),
              icon: const Icon(Icons.chat_bubble),
              label: const Text('Message Teacher'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartChatScreen(
          currentUserId: currentUserId,
          currentUserName: currentUserName,
          otherUserId: teacherId,
          otherUserName: teacherName,
          otherUserRole: 'teacher',
        ),
      ),
    );
  }
}

/// Example: Navigation bar with unread count badge
class NavigationWithChatBadge extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;

  const NavigationWithChatBadge({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(key: key);

  @override
  State<NavigationWithChatBadge> createState() => _NavigationWithChatBadgeState();
}

class _NavigationWithChatBadgeState extends State<NavigationWithChatBadge> {
  final SocketService _socketService = SocketService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    
    // Listen to chat updates to update unread count
    _socketService.chatUpdateStream.listen((data) {
      setState(() {
        _unreadCount = data['unreadCount'] ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.chat),
              if (_unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Messages',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      onTap: (index) {
        if (index == 2) {
          // Navigate to chat list
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatListScreen(
                currentUserId: widget.currentUserId,
                currentUserName: widget.currentUserName,
              ),
            ),
          );
        }
      },
    );
  }
}
