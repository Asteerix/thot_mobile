import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:thot/core/config/app_config.dart';

class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: padding ?? EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.darkBackground.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.neutralGrey, width: 1),
        boxShadow: [
          BoxShadow(
              color: AppColors.blue.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

class DomainChip extends StatelessWidget {
  const DomainChip({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.blue.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue.withOpacity(0.35), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.tag, size: 16, color: AppColors.blue),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class PublishBar extends StatelessWidget {
  const PublishBar({
    super.key,
    required this.enabled,
    required this.isSubmitting,
    required this.onSubmit,
    required this.primaryLabel,
    this.leading,
    this.primaryColor = AppColors.blue,
  });
  final bool enabled;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final String primaryLabel;
  final Widget? leading;
  final Color primaryColor;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.darkBackground.withOpacity(0.95),
          border: Border(top: BorderSide(color: AppColors.neutralGrey)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 12, offset: Offset(0, -6))
          ],
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              Expanded(child: leading!),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: enabled ? onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      enabled ? primaryColor : AppColors.darkBackground,
                  foregroundColor:
                      enabled ? AppColors.textPrimary : AppColors.textSecondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textPrimary)),
                      )
                    : Text(primaryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
