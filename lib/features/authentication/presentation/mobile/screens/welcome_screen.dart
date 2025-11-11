import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/mixins/welcome_screen_mixin.dart';
import '../../shared/widgets/welcome_logo.dart';
import '../../shared/widgets/welcome_content.dart';
import '../../shared/widgets/welcome_footer.dart';
import 'package:thot/shared/widgets/common/connection_status_indicator.dart';
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}
class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin, WelcomeScreenMixin<WelcomeScreen> {
  late Animation<Offset> _slideAnimation;
  @override
  void initState() {
    super.initState();
    _initializeSlideAnimation();
  }
  void _initializeSlideAnimation() {
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
  }
  @override
  Curve get fadeCurve => const Interval(0.0, 0.6, curve: Curves.easeOut);
  @override
  double get scaleBegin => 0.8;
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: ConnectionStatusIndicator(
                    showPersistentBanner: true,
                    showRetryButton: true,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      FadeTransition(
                        opacity: fadeAnimation,
                        child: ScaleTransition(
                          scale: scaleAnimation,
                          child: const WelcomeLogo(size: 80),
                        ),
                      ),
                      const SizedBox(height: 60),
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: fadeAnimation,
                          child: const Column(
                            children: [
                              WelcomeTitle(),
                              SizedBox(height: 16),
                              WelcomeSubtitle(),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 3),
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: fadeAnimation,
                          child: Column(
                            children: [
                              _buildLoginButton(),
                              const SizedBox(height: 16),
                              _buildRegisterButton(),
                              const SizedBox(height: 40),
                              const WelcomeFooter(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              if (isLoading) _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : navigateToLogin,
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Text(
              'Se connecter',
              style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        color: Colors.black,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : navigateToRegister,
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Text(
              'Créer un compte',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildLoadingOverlay() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: Colors.black.withOpacity(0.7),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 2,
        ),
      ),
    );
  }
}