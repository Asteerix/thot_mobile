import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
class ChatHeader extends StatelessWidget {
  final String name;
  final String? username;
  final String? avatarUrl;
  final VoidCallback? onVideoCall;
  final VoidCallback? onVoiceCall;
  final VoidCallback? onInfo;
  final bool showActions;
  const ChatHeader({
    super.key,
    required this.name,
    this.username,
    this.avatarUrl,
    this.onVideoCall,
    this.onVoiceCall,
    this.onInfo,
    this.showActions = true,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : WebTheme.lg),
      decoration: BoxDecoration(
        color: isMobile ? Theme.of(context).appBarTheme.backgroundColor : null,
        border: Border(
          bottom: BorderSide(
            color: isMobile
                ? Theme.of(context).dividerColor
                : colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 18 : 20,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Icon(
                    Icons.person,
                    size: isMobile ? 18 : 20,
                    color: colorScheme.onPrimaryContainer,
                  )
                : null,
          ),
          SizedBox(width: isMobile ? 12.0 : WebTheme.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (username != null)
                  Text(
                    username!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (showActions) ...[
            if (onVideoCall != null)
              IconButton(
                icon: Icon(Icons.videocam),
                onPressed: onVideoCall,
                tooltip: 'Video call',
              ),
            if (onVoiceCall != null)
              IconButton(
                icon: const Icon(Icons.phone),
                onPressed: onVoiceCall,
                tooltip: 'Voice call',
              ),
            if (onInfo != null)
              IconButton(
                icon: Icon(Icons.info),
                onPressed: onInfo,
                tooltip: 'Info',
              ),
          ],
        ],
      ),
    );
  }
}