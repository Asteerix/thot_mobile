import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../shared/mixins/welcome_screen_mixin.dart';
import '../../shared/widgets/welcome_logo.dart';
import '../../shared/widgets/welcome_content.dart';
import '../../shared/widgets/welcome_footer.dart';
class WelcomeScreenWeb extends StatefulWidget {
  const WelcomeScreenWeb({super.key});
  @override
  State<WelcomeScreenWeb> createState() => _WelcomeScreenWebState();
}
class _WelcomeScreenWebState extends State<WelcomeScreenWeb>
    with SingleTickerProviderStateMixin, WelcomeScreenMixin<WelcomeScreenWeb> {
  @override
  Duration get animationDuration => const Duration(milliseconds: 1200);
  @override
  double get scaleBegin => 0.9;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(WebTheme.xxl),
                child: Card(
                  elevation: 8,
                  color: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(WebTheme.borderRadiusLarge),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(WebTheme.cardPaddingLarge),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const WelcomeLogo(
                          size: 100,
                          usePrimaryColor: false,
                          withHero: false,
                        ),
                        const SizedBox(height: WebTheme.xxl),
                        const WelcomeTitle(usePrimaryColor: false),
                        const SizedBox(height: WebTheme.md),
                        const WelcomeSubtitle(usePrimaryColor: false),
                        const SizedBox(height: WebTheme.xxl * 1.5),
                        _buildLoginButton(theme),
                        const SizedBox(height: WebTheme.lg),
                        _buildRegisterButton(theme),
                        const SizedBox(height: WebTheme.xxl),
                        const WelcomeFooter(usePrimaryColor: false),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildLoginButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: WebTheme.buttonHeightLarge,
      child: ElevatedButton(
        onPressed: isLoading ? null : navigateToLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.black,
                  ),
                ),
              )
            : Text(
                'Se connecter',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
  Widget _buildRegisterButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: WebTheme.buttonHeightLarge,
      child: OutlinedButton(
        onPressed: isLoading ? null : navigateToRegister,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.black,
          side: const BorderSide(
            color: Colors.white,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
          ),
        ),
        child: Text(
          'Créer un compte',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}