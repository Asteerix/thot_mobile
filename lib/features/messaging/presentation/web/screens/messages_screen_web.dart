import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../shared/widgets/widgets.dart';
class MessagesScreenWeb extends StatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const MessagesScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  State<MessagesScreenWeb> createState() => _MessagesScreenWebState();
}
class _MessagesScreenWebState extends State<MessagesScreenWeb> {
  String? _selectedConversation;
  final _messageController = TextEditingController();
  final List<_ConversationData> _conversations = [
    _ConversationData(
      id: 'conv1',
      name: 'Jane Smith',
      username: '@janesmith',
      lastMessage: 'Hey, how are you doing?',
      time: '2m ago',
      unreadCount: 2,
      isOnline: true,
    ),
    _ConversationData(
      id: 'conv2',
      name: 'Mike Chen',
      username: '@mikechen',
      lastMessage: 'Thanks for the help!',
      time: '1h ago',
      unreadCount: 0,
      isOnline: false,
    ),
    _ConversationData(
      id: 'conv3',
      name: 'Sarah Wilson',
      username: '@sarahw',
      lastMessage: 'Let me know when you\'re free',
      time: '3h ago',
      unreadCount: 0,
      isOnline: false,
    ),
  ];
  final List<_MessageData> _messages = [
    _MessageData(
      message: 'Hey, how are you doing?',
      isSentByMe: false,
      time: '10:30 AM',
    ),
    _MessageData(
      message: 'I\'m great! Thanks for asking',
      isSentByMe: true,
      time: '10:32 AM',
    ),
    _MessageData(
      message: 'Want to grab lunch later?',
      isSentByMe: false,
      time: '10:35 AM',
    ),
  ];
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  void _handleSendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty || _selectedConversation == null) return;
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
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }
  _ConversationData? get _selectedConversationData {
    if (_selectedConversation == null) return null;
    return _conversations.firstWhere(
      (conv) => conv.id == _selectedConversation,
      orElse: () => _conversations.first,
    );
  }
  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      currentRoute: widget.currentRoute,
      onNavigate: widget.onNavigate,
      showSidebar: false,
      body: Row(
        children: [
          SizedBox(
            width: 320,
            child: _buildConversationsList(),
          ),
          Expanded(
            child: _selectedConversation != null
                ? _buildChatArea()
                : const EmptyMessagesState(),
          ),
          if (_selectedConversation != null)
            SizedBox(
              width: 280,
              child: _buildInfoSidebar(),
            ),
        ],
      ),
    );
  }
  Widget _buildConversationsList() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(WebTheme.lg),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                  },
                  tooltip: 'New message',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(WebTheme.md),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search messages',
                prefixIcon: Icon(Icons.search, size: 20),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(WebTheme.borderRadiusLarge),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: WebTheme.md,
                  vertical: WebTheme.sm,
                ),
              ),
              onChanged: (query) {
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final conversation = _conversations[index];
                return ConversationListItem(
                  id: conversation.id,
                  name: conversation.name,
                  username: conversation.username,
                  lastMessage: conversation.lastMessage,
                  time: conversation.time,
                  unreadCount: conversation.unreadCount,
                  isOnline: conversation.isOnline,
                  isSelected: _selectedConversation == conversation.id,
                  onTap: () => setState(() => _selectedConversation = conversation.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildChatArea() {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedConv = _selectedConversationData;
    if (selectedConv == null) {
      return const EmptyMessagesState();
    }
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
      ),
      child: Column(
        children: [
          ChatHeader(
            name: selectedConv.name,
            username: selectedConv.username,
            onVideoCall: () {
            },
            onVoiceCall: () {
            },
            onInfo: () {
            },
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(WebTheme.lg),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(
                  message: message.message,
                  isSentByMe: message.isSentByMe,
                  time: message.time,
                );
              },
            ),
          ),
          MessageInputField(
            controller: _messageController,
            onSend: _handleSendMessage,
            showAttachmentButtons: true,
            onAttach: () {
            },
            onImage: () {
            },
          ),
        ],
      ),
    );
  }
  Widget _buildInfoSidebar() {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedConv = _selectedConversationData;
    if (selectedConv == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          left: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(WebTheme.lg),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 40,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: WebTheme.md),
          Text(
            selectedConv.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            selectedConv.username ?? '',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WebTheme.xl),
          Divider(color: colorScheme.outline),
          const SizedBox(height: WebTheme.md),
          Text(
            'Shared Media',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: WebTheme.sm),
          Text(
            'No shared media yet',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
class _ConversationData {
  final String id;
  final String name;
  final String? username;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  _ConversationData({
    required this.id,
    required this.name,
    this.username,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.isOnline = false,
  });
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