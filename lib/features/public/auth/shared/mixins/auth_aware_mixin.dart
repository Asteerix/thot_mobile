import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/public/auth/shared/providers/auth_provider.dart';
import 'package:thot/core/services/logging/logger_service.dart';

mixin AuthAwareMixin<T extends StatefulWidget> on State<T> {
  late AuthProvider _authProvider;
  bool _isCheckingAuth = false;
  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    if (_isCheckingAuth || !mounted) return;
    _isCheckingAuth = true;
    try {
      if (!_authProvider.isAuthenticated) {
        LoggerService.instance
            .info('User not authenticated on ${widget.runtimeType}');
        _navigateToWelcome();
      }
    } finally {
      _isCheckingAuth = false;
    }
  }

  void _navigateToWelcome() {
    if (!mounted) return;
    GoRouter.of(context).go('/');
  }

  @override
  void dispose() {
    super.dispose();
  }
}
