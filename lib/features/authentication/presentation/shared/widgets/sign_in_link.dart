import 'package:flutter/material.dart';
import 'package:thot/core/navigation/app_router.dart';
import 'package:thot/core/navigation/route_names.dart';
class SignInLink extends StatelessWidget {
  const SignInLink({
    super.key,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.question = 'Already have an account?',
    this.cta = 'Sign in',
    this.alignment = WrapAlignment.center,
  });
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final String question;
  final String cta;
  final WrapAlignment alignment;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);
    return Padding(
      padding: padding,
      child: Semantics(
        container: true,
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: alignment,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              question,
              textAlign: TextAlign.center,
              textScaler: textScaler,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Semantics(
                link: true,
                label: cta,
                child: TextButton(
                  onPressed: onTap ??
                      () => AppRouter.navigateTo(context, RouteNames.login),
                  style: ButtonStyle(
                    minimumSize: WidgetStateProperty.all(const Size(48, 48)),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.disabled)) {
                        return scheme.onSurface.withOpacity(0.38);
                      }
                      return scheme.primary;
                    }),
                    overlayColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.pressed)) {
                        return scheme.primary.withOpacity(0.12);
                      }
                      if (states.contains(WidgetState.hovered) ||
                          states.contains(WidgetState.focused)) {
                        return scheme.primary.withOpacity(0.08);
                      }
                      return null;
                    }),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    textStyle: WidgetStateProperty.resolveWith((states) {
                      final base = theme.textTheme.labelLarge!;
                      if (states.contains(WidgetState.hovered) ||
                          states.contains(WidgetState.focused)) {
                        return base.copyWith(
                            decoration: TextDecoration.underline);
                      }
                      return base;
                    }),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.standard,
                  ),
                  child: Text(cta),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}