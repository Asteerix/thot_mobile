import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thot/shared/widgets/navigation/bottom_nav_bar.dart';
import 'package:thot/features/admin/widgets/banned_user_overlay.dart';
import 'package:thot/shared/widgets/connectivity/connection_status_indicator.dart';
import 'package:thot/features/public/auth/shared/providers/auth_provider.dart';
import 'package:thot/features/app/profile/models/user_profile.dart';
import 'package:thot/features/public/auth/shared/mixins/auth_aware_mixin.dart';
import 'package:thot/core/services/logging/logger_service.dart';

class MainScreen extends StatefulWidget {
  final Widget child;
  const MainScreen({super.key, required this.child});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with AuthAwareMixin, SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late bool _isJournalist;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final _logger = LoggerService.instance;
  final Map<String, int> _authenticatedRouteToIndex = {
    '/feed': 0,
    '/subscriptions': 1,
    '/short': 2,
    '/explore': 3,
    '/profile': 4,
  };
  final Map<String, int> _unauthenticatedRouteToIndex = {
    '/feed': 0,
    '/short': 1,
    '/explore': 2,
    '/profile': 3,
  };
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateIndexFromRoute();
    });
  }

  void _updateIndexFromRoute() {
    final String location =
        GoRouter.of(context).routerDelegate.currentConfiguration.fullPath;
    final authProvider = context.read<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;
    final routeMap = isAuthenticated
        ? _authenticatedRouteToIndex
        : _unauthenticatedRouteToIndex;
    for (final entry in routeMap.entries) {
      if (location.startsWith(entry.key)) {
        if (_currentIndex != entry.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentIndex = entry.value;
              });
            }
          });
        }
        break;
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onNavTapped(int index) {
    _logger
        .info('Navigation tapped: index=$index, currentIndex=$_currentIndex');
    if (_currentIndex == index) {
      final controller = PrimaryScrollController.maybeOf(context);
      if (controller != null && controller.hasClients) {
        controller.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });
    final authProvider = context.read<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;
    _logger.info('Navigating with auth=$isAuthenticated to index=$index');
    _fadeController.reverse().then((_) {
      if (isAuthenticated) {
        String targetRoute;
        switch (index) {
          case 0:
            targetRoute = '/feed';
            break;
          case 1:
            targetRoute = '/subscriptions';
            break;
          case 2:
            targetRoute = '/short';
            break;
          case 3:
            targetRoute = '/explore';
            break;
          case 4:
            targetRoute = '/profile';
            break;
          default:
            targetRoute = '/feed';
        }
        _logger.info('Authenticated navigation: Going to $targetRoute');
        context.go(targetRoute);
      } else {
        switch (index) {
          case 0:
            context.go('/feed');
            break;
          case 1:
            context.go('/short');
            break;
          case 2:
            context.go('/explore');
            break;
          case 3:
            context.go('/profile');
            break;
        }
      }
      _fadeController.forward();
    });
  }

  @override
  void didUpdateWidget(MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateIndexFromRoute();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userProfile = authProvider.userProfile;
        _isJournalist = userProfile?.type == UserType.journalist;
        _updateIndexFromRoute();
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/');
            }
          });
          final theme = Theme.of(context);
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
          child: BannedUserOverlay(
            child: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              extendBody: false,
              extendBodyBehindAppBar: false,
              body: Stack(
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: widget.child,
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.scaffoldBackgroundColor.withOpacity(0.8),
                                theme.scaffoldBackgroundColor.withOpacity(0.0),
                              ],
                            ),
                          ),
                          child: const SafeArea(
                            bottom: false,
                            child: ConnectionStatusIndicator(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: BottomNavBar(
                currentIndex: _currentIndex,
                onTap: _onNavTapped,
                isAuthenticated: true,
              ),
            ),
          ),
        );
      },
    );
  }
}
