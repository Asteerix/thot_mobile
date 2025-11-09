import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
class EmptyMessagesState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? subtitle;
  const EmptyMessagesState({
    super.key,
    this.message = 'Select a conversation',
    this.icon = Icons.forum,
    this.subtitle,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24.0 : WebTheme.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isMobile ? 48 : 64,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: isMobile ? 16 : WebTheme.md),
            Text(
              message,
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                color: colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}