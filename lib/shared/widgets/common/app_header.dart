import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/core/themes/app_colors.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/admin/presentation/shared/widgets/admin_mode_switch.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import '../logo_white.dart';

/// En-tête principale de l'application avec logo, notifications et paramètres
///
/// Utilisé dans :
/// - ProfileScreen : Affiche le username et les paramètres pour l'utilisateur courant
/// - ExploreScreen : Affichage simple avec notifications et paramètres
class AppHeader extends StatefulWidget {
  /// Nom d'utilisateur à afficher (optionnel, utilisé en mode profil)
  final String? username;

  /// Afficher l'icône des paramètres (true par défaut)
  final bool showSettingsIcon;

  /// Mode écran de profil (affiche le username sous le logo)
  final bool isProfileScreen;

  const AppHeader({
    super.key,
    this.username,
    this.showSettingsIcon = true,
    this.isProfileScreen = false,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  // Constantes de style
  static const double _iconSize = 22.0;
  static const double _iconPadding = 8.0;
  static const double _iconSplashRadius = 22.0;
  static const double _toolbarHeight = 64.0;
  static const double _horizontalSpacing = 8.0;

  // TODO: Implémenter le compteur de notifications non lues
  // via NotificationRepository quand disponible
  int _unreadCount = 0;

  // ========== Méthodes de construction des widgets ==========

  /// Badge de notification avec compteur animé
  Widget _buildNotificationBadge() {
    return Positioned(
      right: 6,
      top: 6,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.5, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.red, AppColors.red.withOpacity(0.8)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                _unreadCount.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Tailwind',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Bouton de notifications avec badge optionnel
  Widget _buildNotificationsButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildIconButton(
          icon: Icons.notifications_outlined,
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.go(RouteNames.notifications);
          },
        ),
        if (_unreadCount > 0) _buildNotificationBadge(),
      ],
    );
  }

  /// Bouton des paramètres
  Widget _buildSettingsButton() {
    return _buildIconButton(
      icon: Icons.settings_outlined,
      onPressed: () {
        HapticFeedback.mediumImpact();
        context.go(RouteNames.settings);
      },
    );
  }

  /// Bouton d'icône réutilisable avec style cohérent
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[900]!.withOpacity(0.5),
      ),
      child: IconButton(
        icon: Icon(icon, size: _iconSize, color: Colors.white),
        onPressed: onPressed,
        splashRadius: _iconSplashRadius,
        padding: EdgeInsets.all(_iconPadding),
      ),
    );
  }

  /// Section du logo avec username optionnel pour le mode profil
  Widget _buildLogoSection() {
    return Flexible(
      flex: 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: const LogoWhite(
              fontSize: 32,
              letterSpacing: 2,
              showSubtitle: false,
            ),
          ),
          if (widget.isProfileScreen && widget.username != null)
            Text(
              '@${widget.username}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[300],
                fontWeight: FontWeight.w600,
                fontFamily: 'Tailwind',
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
        ],
      ),
    );
  }

  /// Actions pour utilisateur authentifié (notifications, paramètres, admin)
  Widget _buildAuthenticatedActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildNotificationsButton(),
        SizedBox(width: _horizontalSpacing),
        if (widget.showSettingsIcon || widget.isProfileScreen) ...[
          _buildSettingsButton(),
          SizedBox(width: _horizontalSpacing),
        ],
        const AdminModeSwitch(),
        const SizedBox(width: 4),
      ],
    );
  }

  /// Bouton de connexion pour utilisateur non authentifié
  Widget _buildLoginButton() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[400]!, Colors.blue[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue[600]!.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          SafeNavigation.pushNamed(context, '/login');
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Se connecter',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  /// Bouton de retour si navigation possible
  Widget? _buildBackButton() {
    if (!SafeNavigation.canPop(context)) return null;

    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios_new,
        color: Colors.grey[400],
        size: 18,
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        SafeNavigation.pop(context);
      },
      padding: const EdgeInsets.only(left: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAuthenticated = authProvider.isAuthenticated;
        final canPop = SafeNavigation.canPop(context);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.black.withOpacity(0.95)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: _toolbarHeight,
              leadingWidth: canPop ? 40 : 0,
              leading: _buildBackButton(),
              titleSpacing: canPop ? 0 : 16,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLogoSection(),
                  if (isAuthenticated)
                    _buildAuthenticatedActions()
                  else
                    _buildLoginButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
