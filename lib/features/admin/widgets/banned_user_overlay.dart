import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/public/auth/shared/providers/auth_provider.dart';
import 'package:thot/core/utils/safe_navigation.dart';

class BannedUserOverlay extends StatelessWidget {
  final Widget child;
  final String? banReason;
  final DateTime? bannedAt;
  final String? suspensionReason;
  final DateTime? suspendedUntil;
  final String? status;
  const BannedUserOverlay({
    super.key,
    required this.child,
    this.banReason,
    this.bannedAt,
    this.suspensionReason,
    this.suspendedUntil,
    this.status,
  });
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final userProfile = authProvider.userProfile;
        final userStatus = status ?? userProfile?.status;
        if (userProfile != null &&
            (userStatus == 'suspended' || userStatus == 'banned')) {
          final colorScheme = Theme.of(context).colorScheme;
          return Stack(
            children: [
              child,
              Container(
                color: colorScheme.surface.withOpacity(0.8),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          userStatus == 'banned' ? Icons.block : Icons.warning,
                          size: 64,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userStatus == 'banned'
                              ? 'Compte banni'
                              : 'Compte suspendu',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.surface,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userStatus == 'banned'
                              ? 'Votre compte a été définitivement banni.'
                              : 'Votre compte a été temporairement suspendu.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: colorScheme.surface.withOpacity(0.87),
                              ),
                        ),
                        if (suspensionReason != null ||
                            banReason != null ||
                            userProfile.suspensionReason != null ||
                            userProfile.banReason != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.outline.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Raison :',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.surface,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  suspensionReason ??
                                      banReason ??
                                      userProfile.suspensionReason ??
                                      userProfile.banReason ??
                                      'Non spécifiée',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.surface
                                            .withOpacity(0.87),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (userStatus == 'suspended' &&
                            (suspendedUntil != null ||
                                userProfile.suspendedUntil != null)) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Suspension jusqu\'au :',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.surface,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(
                                suspendedUntil ?? userProfile.suspendedUntil),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.surface.withOpacity(0.87),
                                ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await authProvider.logout();
                              if (context.mounted) {
                                SafeNavigation.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (route) => false,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.error,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Se déconnecter',
                              style: TextStyle(color: colorScheme.onError),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return child;
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non spécifiée';
    return DateFormat('dd/MM/yyyy à HH:mm').format(date);
  }
}
