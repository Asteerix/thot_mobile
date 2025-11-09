import 'package:flutter/material.dart';
import '../../../../../core/navigation/route_names.dart';
import '../../../../../core/navigation/app_router.dart';
mixin WelcomeScreenMixin<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  AnimationController get animationController => _animationController;
  Animation<double> get fadeAnimation => _fadeAnimation;
  Animation<double> get scaleAnimation => _scaleAnimation;
  Duration get animationDuration => const Duration(milliseconds: 1500);
  Curve get fadeCurve => Curves.easeOut;
  double get scaleBegin => 0.8;
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: animationDuration,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: fadeCurve,
    );
    _scaleAnimation = Tween<double>(
      begin: scaleBegin,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  Future<void> navigateToLogin() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    AppRouter.replaceAllTo(context, RouteNames.login);
    if (mounted) setState(() => _isLoading = false);
  }
  Future<void> navigateToRegister() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    AppRouter.replaceAllTo(context, RouteNames.modeSelection);
    if (mounted) setState(() => _isLoading = false);
  }
}