import 'package:flutter/material.dart';

class AuthLoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final double? width;
  final double height;
  final bool isPrimary;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  const AuthLoadingButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.isPrimary = true,
    this.icon,
    this.padding,
  });
  @override
  Widget build(BuildContext context) {
    Widget buttonChild;
    if (isLoading) {
      buttonChild = SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isPrimary ? Colors.black : Colors.white,
          ),
        ),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    } else {
      buttonChild = Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );
    }
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: isPrimary
          ? ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white.withOpacity(0.6),
                disabledForegroundColor: Colors.black.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: isLoading ? 0 : 2,
                padding: padding,
              ),
              child: buttonChild,
            )
          : OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color:
                      isLoading ? Colors.white.withOpacity(0.3) : Colors.white,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: padding,
              ),
              child: buttonChild,
            ),
    );
  }
}
