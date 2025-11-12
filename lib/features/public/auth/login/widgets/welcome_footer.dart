import 'package:flutter/material.dart';

class WelcomeFooter extends StatelessWidget {
  final bool usePrimaryColor;
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyTap;
  const WelcomeFooter({
    super.key,
    this.usePrimaryColor = false,
    this.onTermsTap,
    this.onPrivacyTap,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor =
        usePrimaryColor ? colorScheme.onSurfaceVariant : Colors.white;
    return Column(
      children: [
        Text(
          'En continuant, vous acceptez nos',
          style: TextStyle(
            color: baseColor.withOpacity(usePrimaryColor ? 0.7 : 0.5),
            fontSize: 12,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFooterLink(
              'Conditions',
              onTermsTap ?? () {},
              baseColor,
              colorScheme,
            ),
            Text(
              ' • ',
              style: TextStyle(
                color: baseColor.withOpacity(0.3),
                fontSize: 12,
              ),
            ),
            _buildFooterLink(
              'Confidentialité',
              onPrivacyTap ?? () {},
              baseColor,
              colorScheme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterLink(
    String text,
    VoidCallback onTap,
    Color baseColor,
    ColorScheme colorScheme,
  ) {
    final linkColor = usePrimaryColor ? colorScheme.primary : baseColor;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          text,
          style: TextStyle(
            color: linkColor.withOpacity(usePrimaryColor ? 1.0 : 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
            decorationColor: usePrimaryColor
                ? colorScheme.primary
                : baseColor.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}
