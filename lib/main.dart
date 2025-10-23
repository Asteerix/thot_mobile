import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:thot/core/constants/timeago_config.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'package:thot/core/navigation/app_router.dart';
import 'package:thot/core/providers/theme_provider.dart';
import 'package:thot/core/monitoring/logger_service.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/core/utils/keyboard_service.dart';
import 'package:thot/features/media/utils/url_helper.dart';
import 'package:thot/core/config/env.dart';
import 'package:thot/core/network/api_config.dart';
import 'package:thot/core/realtime/socket_service.dart';
import 'package:thot/shared/widgets/common/connection_status_indicator.dart';

void main() async {
  initTimeagoLocales();
  try {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize logger first
    LoggerService.instance.info('Starting application...');

    // Initialize environment configuration
    debugPrint('[Bootstrap] Starting initialization...');
    try {
      // 1. Charger les variables d'environnement
      await EnvConfig.load();

      // 2. Initialiser et obtenir l'URL de l'API
      await ApiConfig.getApiBaseUrl();
      debugPrint('[Bootstrap] API configured');

      // 3. Initialiser UrlHelper avec l'URL de l'API
      await UrlHelper.initialize();
      debugPrint('[Bootstrap] UrlHelper initialized');

      debugPrint('[Bootstrap] Initialization complete');

      // Afficher la configuration en mode debug
      if (kDebugMode) {
        debugPrint('=== API Configuration ===');
        debugPrint(
            'Base URL: ${ApiConfig.getCurrentUrl() ?? 'Not configured'}');
        debugPrint('========================');
      }
    } catch (e) {
      debugPrint('[Bootstrap] Failed: $e');
      // En cas d'échec, continuer avec les valeurs par défaut
    }

    // Initialize service locator
    await ServiceLocator.instance.initialize();
    LoggerService.instance.info('✅ Services initialized');

    // Initialize WebSocket service
    final socketService = SocketService();
    await socketService.initialize();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set up error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      // Ignore keyboard-related errors in debug mode
      if (details.toString().contains('KeyUpEvent') &&
          details.toString().contains('_pressedKeys.containsKey')) {
        LoggerService.instance
            .warning('Ignoring keyboard event error in debug mode');
        return;
      }

      FlutterError.presentError(details);
      LoggerService.instance.error('Flutter Error', details.toString());
    };

    // Handle platform channel errors
    PlatformDispatcher.instance.onError = (error, stack) {
      // Ignore keyboard-related errors
      if (error.toString().contains('KeyUpEvent') ||
          error.toString().contains('_pressedKeys')) {
        LoggerService.instance.warning('Ignoring keyboard platform error');
        return true;
      }

      LoggerService.instance.error('Platform Error', error, stack);
      return true;
    };

    // Set up global keyboard handler to prevent inconsistent key events
    final keyboardService = KeyboardService();
    HardwareKeyboard.instance.addHandler((event) {
      return keyboardService.handleKeyEvent(event);
    });

    // Application initialisée avec succès
    runApp(const ThotApp());
  } catch (e, stackTrace) {
    LoggerService.instance
        .error('❌ Error during initialization', e, stackTrace);
    rethrow;
  }
}

class ThotApp extends StatefulWidget {
  const ThotApp({super.key});

  @override
  State<ThotApp> createState() => _ThotAppState();
}

class _ThotAppState extends State<ThotApp> {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: ServiceLocator.wrapWithProviders(
        provider.Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final themeProvider = context.watch<ThemeProvider>();

            return _ThotAppRouter(
              authProvider: authProvider,
              theme: themeProvider.currentTheme,
            );
          },
        ),
      ),
    );
  }
}

// Separate widget to isolate router creation
class _ThotAppRouter extends StatefulWidget {
  final AuthProvider authProvider;
  final ThemeData theme;

  const _ThotAppRouter({
    required this.authProvider,
    required this.theme,
  });

  @override
  State<_ThotAppRouter> createState() => _ThotAppRouterState();
}

class _ThotAppRouterState extends State<_ThotAppRouter> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(widget.authProvider);

    // Check auth status on app startup for persistence
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.authProvider.checkAuthStatus();
    });
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Thot',
      theme: widget.theme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: ConnectionStatusIndicator(),
              ),
            ),
          ],
        );
      },
    );
  }
}
