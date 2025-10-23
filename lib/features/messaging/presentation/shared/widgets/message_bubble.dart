import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
class MessageBubble extends StatelessWidget {
  final String message;
  final bool isSentByMe;
  final String? time;
  final double? maxWidth;
  const MessageBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
    this.time,
    this.maxWidth = 500,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: isMobile ? 8.0 : WebTheme.md,
        ),
        padding: EdgeInsets.all(isMobile ? 12.0 : WebTheme.md),
        constraints: BoxConstraints(maxWidth: maxWidth ?? 500),
        decoration: BoxDecoration(
          color: isSentByMe
              ? colorScheme.primaryContainer
              : (isMobile
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(
            isMobile ? 12.0 : WebTheme.borderRadiusMedium,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                color: colorScheme.onSurface,
              ),
            ),
            if (time != null) ...[
              const SizedBox(height: 4),
              Text(
                time!,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}