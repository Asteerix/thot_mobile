import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thot/features/app/profile/utils/follow_utils.dart';
import 'package:thot/features/app/profile/models/user_profile.dart';
class FollowButton extends StatefulWidget {
  final String userId;
  final bool isFollowing;
  final Function(bool)? onFollowChanged;
  final bool compact;
  const FollowButton({
    super.key,
    required this.userId,
    required this.isFollowing,
    this.onFollowChanged,
    this.compact = false,
  });
  @override
  State<FollowButton> createState() => _FollowButtonState();
}
class _FollowButtonState extends State<FollowButton> {
  bool _isLoading = false;
  late bool _isFollowing;
  @override
  void initState() {
    super.initState();
    _isFollowing = widget.isFollowing;
  }
  @override
  void didUpdateWidget(FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFollowing != widget.isFollowing) {
      _isFollowing = widget.isFollowing;
    }
  }
  Future<void> _toggleFollow() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    HapticFeedback.lightImpact();
    final tempUser = UserProfile(
      id: widget.userId,
      username: '',
      email: '',
      type: UserType.journalist,
      postsCount: 0,
      followersCount: 0,
      followingCount: 0,
      isFollowing: _isFollowing,
    );
    await FollowUtils.handleFollowAction(
      tempUser,
      (updatedUser) {
        if (mounted) {
          setState(() {
            _isFollowing = updatedUser.isFollowing;
            _isLoading = false;
          });
          widget.onFollowChanged?.call(updatedUser.isFollowing);
        }
      },
      (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          FollowUtils.showErrorSnackBar(context, error);
        }
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: widget.compact ? 28 : 32,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _toggleFollow,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 12 : 16,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              gradient: _isFollowing
                  ? null
                  : const LinearGradient(
                      colors: [Colors.purple, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: _isFollowing ? Colors.grey[800] : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFollowing ? Colors.grey[700]! : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  SizedBox(
                    width: widget.compact ? 12 : 14,
                    height: widget.compact ? 12 : 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isFollowing ? Colors.white : Colors.white,
                      ),
                    ),
                  )
                else
                  Icon(
                    _isFollowing ? Icons.check : Icons.add,
                    size: widget.compact ? 14 : 16,
                    color: Colors.white,
                  ),
                SizedBox(width: widget.compact ? 4 : 6),
                Text(
                  _isFollowing ? 'Abonné' : 'S\'abonner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.compact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}