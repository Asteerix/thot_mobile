import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thot/core/config/app_config.dart';
import 'package:thot/features/public/auth/shared/providers/auth_repository_impl.dart';
import 'package:thot/core/services/logging/logger_service.dart';
import 'package:thot/core/services/storage/token_service.dart';
import 'package:thot/features/app/profile/models/user_profile.dart';
import 'package:thot/core/di/service_locator.dart';

class AuthProvider with ChangeNotifier {
  static AuthProvider of(BuildContext context) {
    return Provider.of<AuthProvider>(context, listen: false);
  }

  final AuthRepositoryImpl _authRepository;
  UserProfile? _userProfile;
  bool _isAdminMode = false;
  bool _isInitialized = false;
  bool _isLoading = true;
  AuthProvider({AuthRepositoryImpl? authRepository})
      : _authRepository =
            authRepository ?? ServiceLocator.instance.authRepository {
    _startPeriodicAuthCheck();
  }
  bool get isAuthenticated => _userProfile != null;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isJournalist => _userProfile?.isJournalist ?? false;
  bool get isVerifiedJournalist =>
      isJournalist && (_userProfile?.isVerified ?? false);
  bool get isAdmin => _userProfile?.role == 'admin';
  bool get isAdminMode => _isAdminMode;
  UserProfile? get userProfile => _userProfile;
  Future<void> checkAuthStatus() async {
    try {
      _isLoading = true;
      notifyListeners();
      final isAuthenticated = await _authRepository.isAuthenticated();
      if (AppConfig.bypassLogin && !isAuthenticated) {
        await login(
          email: 'journaliste@test.com',
          password: 'Elmer777?',
        );
        return;
      }
      if (!isAuthenticated) {
        await _handleAuthenticationFailure();
        return;
      }
      try {
        _userProfile = await _authRepository.getProfile();
        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
        try {} catch (e) {
          LoggerService.instance
              .error('Failed to start notification polling', e);
        }
        final context = ServiceLocator.instance.navigatorKey.currentContext;
        if (context != null && context.mounted) {
          final router = GoRouter.of(context);
          final currentLocation =
              router.routerDelegate.currentConfiguration.uri.toString();
          if (currentLocation == '/' || currentLocation.isEmpty) {
            router.go('/feed');
          }
        }
      } catch (e) {
        LoggerService.instance.error('❌ Profile fetch failed', e);
        await _handleAuthenticationFailure();
      }
    } catch (e) {
      LoggerService.instance.error('❌ Auth check failed', e);
      await _handleAuthenticationFailure();
    }
  }

  Future<void> _handleAuthenticationFailure() async {
    await _authRepository.logout();
    _userProfile = null;
    _isAdminMode = false;
    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
    final context = ServiceLocator.instance.navigatorKey.currentContext;
    if (context != null && context.mounted) {
      GoRouter.of(context).go('/welcome');
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final loginResponse = await _authRepository.loginWithCredentials(
        email: email,
        password: password,
      );
      _userProfile = loginResponse.userProfile;
      if (email.toLowerCase() == 'lucas@admin.com' &&
          _userProfile?.role == 'admin') {
        _isAdminMode = true;
      }
      await TokenService.saveToken(
        loginResponse.token,
        loginResponse.userProfile.isJournalist,
      );
      notifyListeners();
      LoggerService.instance.info('Login successful');
      try {
        LoggerService.instance.info('Notification polling started');
      } catch (e) {
        LoggerService.instance.error('Failed to start notification polling', e);
      }
      if (email.toLowerCase() == 'lucas@admin.com' &&
          _userProfile?.role == 'admin') {
        final context = ServiceLocator.instance.navigatorKey.currentContext;
        if (context != null && context.mounted) {
          GoRouter.of(context).go('/admin');
        }
      }
    } catch (e) {
      LoggerService.instance.error('Login failed', e);
      rethrow;
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required UserType type,
    String? name,
    String? organization,
  }) async {
    try {
      _userProfile = await _authRepository.register(
        username: username,
        email: email,
        password: password,
        type: type,
        name: name,
        organization: organization,
      );
      notifyListeners();
      LoggerService.instance.info('Registration successful');
    } catch (e) {
      LoggerService.instance.error('Registration failed', e);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      try {
        LoggerService.instance.info('Notification polling stopped');
      } catch (e) {
        LoggerService.instance.error('Failed to stop notification polling', e);
      }
      await _authRepository.logout();
      _userProfile = null;
      _isAdminMode = false;
      LoggerService.instance.info('Logout successful - state cleared');
      notifyListeners();
      Future.microtask(() {
        final context = ServiceLocator.instance.navigatorKey.currentContext;
        if (context != null && context.mounted) {
          LoggerService.instance
              .info('Forcing navigation to /welcome after logout');
          try {
            GoRouter.of(context).go('/welcome');
            LoggerService.instance.info('Navigation to /welcome completed');
          } catch (e) {
            LoggerService.instance.error('Navigation error during logout', e);
          }
        } else {
          LoggerService.instance
              .warning('Context not available for navigation');
        }
      });
    } catch (e) {
      LoggerService.instance.error('Logout failed', e);
      _userProfile = null;
      _isAdminMode = false;
      notifyListeners();
      Future.microtask(() {
        final context = ServiceLocator.instance.navigatorKey.currentContext;
        if (context != null && context.mounted) {
          LoggerService.instance
              .info('Logout failed but navigating to /welcome anyway');
          try {
            GoRouter.of(context).go('/welcome');
            LoggerService.instance
                .info('Navigation to /welcome completed (error recovery)');
          } catch (navError) {
            LoggerService.instance
                .error('Navigation error during logout fallback', navError);
          }
        } else {
          LoggerService.instance
              .warning('Context not available for navigation (error recovery)');
        }
      });
      if (!e.toString().contains('GoRouter') &&
          !e.toString().contains('Navigator')) {
        rethrow;
      }
    }
  }

  Future<void> deleteAccount() async {
    try {
      try {
        LoggerService.instance
            .info('Notification polling stopped before account deletion');
      } catch (e) {
        LoggerService.instance.error('Failed to stop notification polling', e);
      }
      await _authRepository.deleteAccount();
      _userProfile = null;
      _isAdminMode = false;
      LoggerService.instance
          .info('Account deletion successful - state cleared');
      notifyListeners();
      Future.microtask(() {
        final context = ServiceLocator.instance.navigatorKey.currentContext;
        if (context != null && context.mounted) {
          LoggerService.instance
              .info('Forcing navigation to /welcome after account deletion');
          try {
            GoRouter.of(context).go('/welcome');
            LoggerService.instance.info('Navigation to /welcome completed');
          } catch (e) {
            LoggerService.instance
                .error('Navigation error after account deletion', e);
          }
        } else {
          LoggerService.instance
              .warning('Context not available for navigation');
        }
      });
    } catch (e) {
      LoggerService.instance.error('Account deletion failed', e);
      rethrow;
    }
  }

  Future<void> setAdminMode(bool enabled) async {
    if (isAdmin && _isAdminMode != enabled) {
      try {
        if (enabled) {
          _userProfile = await _authRepository.getProfile();
          if (isAdmin) {
            _isAdminMode = enabled;
            notifyListeners();
            LoggerService.instance.info('Admin mode enabled');
          } else {
            throw Exception('User is not an admin');
          }
        } else {
          _isAdminMode = enabled;
          notifyListeners();
          LoggerService.instance.info('Admin mode disabled');
        }
      } catch (e) {
        LoggerService.instance.error('Failed to switch admin mode', e);
        rethrow;
      }
    }
  }

  void setUserProfile(UserProfile profile) {
    _userProfile = profile;
    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
    LoggerService.instance.info('User profile set directly after registration');
  }

  Future<void> refreshProfile() async {
    try {
      _userProfile = await _authRepository.getProfile();
      notifyListeners();
      LoggerService.instance.info('Profile refreshed');
    } catch (e) {
      LoggerService.instance.error('Failed to refresh profile', e);
      rethrow;
    }
  }

  Future<void> handleApiError(dynamic error) async {
    if (error.toString().contains('401') ||
        error.toString().contains('Unauthorized') ||
        error.toString().contains('Token expired') ||
        error.toString().contains('Invalid token') ||
        error.toString().contains('User not found')) {
      LoggerService.instance.error('Authentication error detected', error);
      await _handleAuthenticationFailure();
    }
  }

  void _startPeriodicAuthCheck() {
    Future.delayed(const Duration(minutes: 5), () async {
      if (!isAuthenticated) return;
      try {
        final stillAuthenticated = await _authRepository.isAuthenticated();
        if (!stillAuthenticated) {
          await _handleAuthenticationFailure();
        }
      } catch (e) {
        LoggerService.instance.error('Periodic auth check failed', e);
      }
      _startPeriodicAuthCheck();
    });
  }
}
