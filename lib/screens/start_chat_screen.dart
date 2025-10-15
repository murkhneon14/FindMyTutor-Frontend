import 'package:flutter/material.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class StartChatScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String otherUserId;
  final String otherUserName;
  final String otherUserRole;

  const StartChatScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
  }) : super(key: key);

  @override
  State<StartChatScreen> createState() => _StartChatScreenState();
}

class _StartChatScreenState extends State<StartChatScreen> {
  final ChatService _chatService = ChatService();
  bool _isLoading = false;

  Future<void> _startChat() async {
    setState(() {
      _isLoading = true;
    });

    final chatRoom = await _chatService.getOrCreateChat(
      widget.currentUserId,
      widget.otherUserId,
    );

    setState(() {
      _isLoading = false;
    });

    if (chatRoom != null && mounted) {
      final otherUser = ChatUser(
        id: widget.otherUserId,
        name: widget.otherUserName,
        email: '',
        role: widget.otherUserRole,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatRoom.id,
            currentUserId: widget.currentUserId,
            currentUserName: widget.currentUserName,
            otherUser: otherUser,
          ),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start chat. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Automatically start chat when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startChat();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Starting Chat'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Starting chat with ${widget.otherUserName}...',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
