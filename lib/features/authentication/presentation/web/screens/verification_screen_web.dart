import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
class VerificationScreenWeb extends StatelessWidget {
  final String email;
  final VoidCallback? onResendCode;
  final VoidCallback? onBackToLogin;
  const VerificationScreenWeb({
    super.key,
    required this.email,
    this.onResendCode,
    this.onBackToLogin,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: ResponsiveLayout(
        builder: (context, deviceType) {
          return Center(
            child: SingleChildScrollView(
              child: Container(
                constraints:
                    const BoxConstraints(maxWidth: WebTheme.maxFormWidth),
                padding: const EdgeInsets.all(WebTheme.xxl),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(WebTheme.borderRadiusLarge),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(WebTheme.cardPaddingLarge),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(WebTheme.xl),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mail_outline,
                            size: 64,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: WebTheme.xl),
                        Text(
                          'Verify Your Email',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: WebTheme.md),
                        Text(
                          'We sent a verification link to',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: WebTheme.xs),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: WebTheme.xl),
                        Container(
                          padding: const EdgeInsets.all(WebTheme.md),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(
                                WebTheme.borderRadiusMedium),
                          ),
                          child: Text(
                            'Please check your inbox and click the verification link to activate your account.',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: WebTheme.xl),
                        if (onResendCode != null)
                          TextButton.icon(
                            onPressed: onResendCode,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Resend Verification Email'),
                          ),
                        const SizedBox(height: WebTheme.md),
                        if (onBackToLogin != null)
                          OutlinedButton(
                            onPressed: onBackToLogin,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(
                                  double.infinity, WebTheme.buttonHeight),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    WebTheme.borderRadiusMedium),
                              ),
                            ),
                            child: const Text('Back to Login'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}