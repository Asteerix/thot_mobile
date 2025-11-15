import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/app/profile/providers/follow_state_provider.dart';
import 'package:thot/core/utils/safe_navigation.dart';

class FollowButton extends StatelessWidget {
  final String userId;
  final bool initialIsFollowing;
  final bool compact;
  final bool fullWidth;

  const FollowButton({
    super.key,
    required this.userId,
    required bool isFollowing,
    this.compact = false,
    this.fullWidth = false,
  }) : initialIsFollowing = isFollowing;

  @override
  Widget build(BuildContext context) {
    return Consumer<FollowStateProvider>(
      builder: (context, followProvider, _) {
        followProvider.initializeFollowState(userId, initialIsFollowing);

        final isFollowing = followProvider.isFollowing(userId);
        final isProcessing = followProvider.isProcessing(userId);

        final button = ElevatedButton(
            onPressed: isProcessing
                ? null
                : () async {
                    HapticFeedback.lightImpact();
                    try {
                      await followProvider.toggleFollow(userId);
                    } catch (e) {
                      if (context.mounted) {
                        SafeNavigation.showSnackBar(
                          context,
                          SnackBar(
                            content: Text('Erreur: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.zero,
              minimumSize: fullWidth ? const Size(double.infinity, 40) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(fullWidth ? 12 : 18),
              ),
            ),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: isFollowing
                    ? const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Colors.purple, Colors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(fullWidth ? 12 : 18),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: fullWidth ? 10 : 6,
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isFollowing ? Icons.check : Icons.add,
                            size: compact ? 14 : 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: fullWidth ? 8 : 6),
                          Text(
                            isFollowing ? 'Abonné' : 'Suivre',
                            style: TextStyle(
                              fontSize: fullWidth ? 14 : (compact ? 12 : 14),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );

        if (fullWidth) {
          return SizedBox(
            height: 40,
            child: button,
          );
        } else if (compact) {
          return SizedBox(
            height: 32,
            width: 100,
            child: button,
          );
        } else {
          return SizedBox(
            height: 36,
            width: 110,
            child: button,
          );
        }
      },
    );
  }
}
