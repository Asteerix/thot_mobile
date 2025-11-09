import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/core/navigation/app_router.dart';
class ProfileSpeedDial extends StatelessWidget {
  final bool showSpeedDial;
  final Animation<double> rotationAnimation;
  final VoidCallback onLoadProfile;
  const ProfileSpeedDial({
    super.key,
    required this.showSpeedDial,
    required this.rotationAnimation,
    required this.onLoadProfile,
  });
  Widget _buildSpeedDialItem(
      String label, IconData icon, Future<void> Function() onTap,
      {int index = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: showSpeedDial ? 1.0 : 0.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(100 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Material(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                splashColor: Colors.blue.withOpacity(0.3),
                highlightColor: Colors.blue.withOpacity(0.1),
                hoverColor: Colors.blue.withOpacity(0.05),
                onTap: () async {
                  await onTap();
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.info,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: showSpeedDial ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return IgnorePointer(
          ignoring: !showSpeedDial,
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.only(bottom: 100, right: 16),
              alignment: Alignment.bottomRight,
              child: Transform.translate(
                offset: Offset(100 * (1 - value), 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildSpeedDialItem(
                      'Nouvelle publication',
                      Icons.note_add,
                      () async {
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        if (!authProvider.isAuthenticated ||
                            authProvider.userProfile == null) {
                          AppRouter.navigateTo(context, RouteNames.welcome);
                          return;
                        }
                        final userId = authProvider.userProfile!.id;
                        if (userId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erreur: ID utilisateur manquant'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        AppRouter.navigateTo(
                          context,
                          RouteNames.newPublication,
                          arguments: {
                            'journalistId': userId,
                          },
                        );
                        onLoadProfile();
                      },
                      index: 0,
                    ),
                    const SizedBox(height: 16),
                    _buildSpeedDialItem(
                      'Nouveau short',
                      Icons.videocamPlus,
                      () async {
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        if (!authProvider.isAuthenticated ||
                            authProvider.userProfile == null) {
                          AppRouter.navigateTo(context, RouteNames.welcome);
                          return;
                        }
                        final userId = authProvider.userProfile!.id;
                        if (userId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erreur: ID utilisateur manquant'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        AppRouter.navigateTo(
                          context,
                          RouteNames.newVideo,
                          arguments: {
                            'journalistId': userId,
                            'domain': 'journalism',
                          },
                        );
                        onLoadProfile();
                      },
                      index: 1,
                    ),
                    const SizedBox(height: 16),
                    _buildSpeedDialItem(
                      'Nouvelle question',
                      Icons.help_outline,
                      () async {
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        if (!authProvider.isAuthenticated ||
                            authProvider.userProfile == null) {
                          AppRouter.navigateTo(context, RouteNames.welcome);
                          return;
                        }
                        final userId = authProvider.userProfile!.id;
                        if (userId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erreur: ID utilisateur manquant'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        context.push(
                          '/question-type-selection',
                          extra: {
                            'journalistId': userId,
                          },
                        ).then((_) {
                          onLoadProfile();
                        });
                      },
                      index: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}