import 'package:flutter/material.dart';
import 'package:thot/features/profile/domain/entities/user_profile.dart';
import '../../shared/widgets/widgets.dart';
class MessagesScreen extends StatefulWidget {
  final UserProfile recipient;
  const MessagesScreen({
    super.key,
    required this.recipient,
  });
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}
class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<_MessageData> _messages = [];
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  void _handleSendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    setState(() {
      _messages.add(_MessageData(
        message: message,
        isSentByMe: true,
        time: _formatTime(DateTime.now()),
      ));
    });
    _messageController.clear();
  }
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipient.username),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
            },
            tooltip: 'Conversation info',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const EmptyMessagesState(
                    message: 'No messages yet',
                    subtitle: 'Start the conversation!',
                    icon: Icons.comment,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final messageData = _messages[index];
                      return MessageBubble(
                        message: messageData.message,
                        isSentByMe: messageData.isSentByMe,
                        time: messageData.time,
                      );
                    },
                  ),
          ),
          MessageInputField(
            controller: _messageController,
            onSend: _handleSendMessage,
            hintText: 'Type a message...',
          ),
        ],
      ),
    );
  }
}
class _MessageData {
  final String message;
  final bool isSentByMe;
  final String time;
  _MessageData({
    required this.message,
    required this.isSentByMe,
    required this.time,
  });
}