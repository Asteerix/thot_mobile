import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/core/realtime/event_bus.dart';
import 'package:thot/features/posts/application/providers/posts_state_provider.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'political_orientation_utils.dart';
import 'political_voters_sheet.dart';
import 'package:thot/core/utils/safe_navigation.dart';
class VotingDialog extends StatefulWidget {
  final Post post;
  final Function(Post)? onVoteChanged;
  const VotingDialog({
    super.key,
    required this.post,
    this.onVoteChanged,
  });
  @override
  State<VotingDialog> createState() => _VotingDialogState();
}
class _VotingDialogState extends State<VotingDialog> {
  late Post _currentPost;
  bool _isVoting = false;
  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
  }
  PoliticalOrientation? _getCurrentUserVote(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userProfile?.id;
    if (currentUserId == null) return null;
    try {
      final voter = _currentPost.politicalOrientation.voters.firstWhere(
        (v) => v.userId == currentUserId,
      );
      return voter.view;
    } catch (e) {
      return null;
    }
  }
  String _getOrientationValue(PoliticalOrientation orientation) {
    switch (orientation) {
      case PoliticalOrientation.extremelyConservative:
        return 'extremelyConservative';
      case PoliticalOrientation.conservative:
        return 'conservative';
      case PoliticalOrientation.neutral:
        return 'neutral';
      case PoliticalOrientation.progressive:
        return 'progressive';
      case PoliticalOrientation.extremelyProgressive:
        return 'extremelyProgressive';
    }
  }
  PoliticalOrientation _calculateMedian() {
    final votes = _currentPost.politicalOrientation.userVotes;
    final frequencies = [
      votes['extremelyConservative'] ?? 0,
      votes['conservative'] ?? 0,
      votes['neutral'] ?? 0,
      votes['progressive'] ?? 0,
      votes['extremelyProgressive'] ?? 0,
    ];
    final totalVotes = frequencies.fold(0, (sum, freq) => sum + freq);
    if (totalVotes == 0) return PoliticalOrientation.neutral;
    final medianPosition = totalVotes / 2;
    var cumulative = 0;
    for (var i = 0; i < frequencies.length; i++) {
      cumulative += frequencies[i];
      if (cumulative > medianPosition) {
        switch (i) {
          case 0:
            return PoliticalOrientation.extremelyConservative;
          case 1:
            return PoliticalOrientation.conservative;
          case 2:
            return PoliticalOrientation.neutral;
          case 3:
            return PoliticalOrientation.progressive;
          case 4:
            return PoliticalOrientation.extremelyProgressive;
        }
      } else if (cumulative == medianPosition && totalVotes % 2 == 0) {
        for (var j = i + 1; j < frequencies.length; j++) {
          if (frequencies[j] > 0) {
            final score1 = i - 2;
            final score2 = j - 2;
            final avgScore = (score1 + score2) / 2;
            final median = avgScore > 0 ? avgScore.floor() : avgScore.ceil();
            switch (median + 2) {
              case 0:
                return PoliticalOrientation.extremelyConservative;
              case 1:
                return PoliticalOrientation.conservative;
              case 2:
                return PoliticalOrientation.neutral;
              case 3:
                return PoliticalOrientation.progressive;
              case 4:
                return PoliticalOrientation.extremelyProgressive;
              default:
                return PoliticalOrientation.neutral;
            }
          }
        }
        switch (i) {
          case 0:
            return PoliticalOrientation.extremelyConservative;
          case 1:
            return PoliticalOrientation.conservative;
          case 2:
            return PoliticalOrientation.neutral;
          case 3:
            return PoliticalOrientation.progressive;
          case 4:
            return PoliticalOrientation.extremelyProgressive;
        }
      }
    }
    return PoliticalOrientation.neutral;
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Orientation politique',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: IgnorePointer(
                ignoring: _isVoting,
                child: ListView(
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: PoliticalOrientation.values.map((orientation) {
                    final color =
                        PoliticalOrientationUtils.getColor(orientation);
                    final voteCount = _currentPost.politicalOrientation
                            .userVotes[_getOrientationValue(orientation)] ??
                        0;
                    final isMedian = orientation == _calculateMedian();
                    final currentUserVote = _getCurrentUserVote(context);
                    final isMyVote = currentUserVote == orientation;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isMyVote
                            ? color.withOpacity(isDark ? 0.25 : 0.2)
                            : (isMedian
                                ? color.withOpacity(isDark ? 0.15 : 0.1)
                                : (isDark
                                    ? const Color(0xFF1C1C1E)
                                    : Colors.grey[100])),
                        borderRadius: BorderRadius.circular(12),
                        border: isMyVote
                            ? Border.all(color: color, width: 2.5)
                            : (isMedian
                                ? Border.all(
                                    color: color.withOpacity(0.5), width: 2)
                                : null),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Stack(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: PoliticalOrientationUtils.getIcon(
                                    orientation),
                              ),
                            ),
                            if (isMedian)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.warning,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          isDark ? Colors.black : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(Icons.star,
                                      size: 10, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                PoliticalOrientationUtils.getLabel(orientation),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: isMyVote
                                      ? FontWeight.w700
                                      : (isMedian
                                          ? FontWeight.w600
                                          : FontWeight.w500),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isMyVote)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Mon vote',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (isMedian)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: color.withOpacity(0.4)),
                                ),
                                child: Text(
                                  'Médiane',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: GestureDetector(
                          onTap: voteCount > 0
                              ? () {
                                  HapticFeedback.lightImpact();
                                  SafeNavigation.pop(context);
                                  PoliticalVotersSheet.show(
                                    context,
                                    _currentPost.id,
                                    _getOrientationValue(orientation),
                                  );
                                }
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$voteCount vote${voteCount > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: voteCount > 0
                                    ? (isDark
                                        ? Colors.blue[300]
                                        : Colors.blue[700])
                                    : (isDark
                                        ? Colors.grey[600]
                                        : Colors.grey[500]),
                                decoration: voteCount > 0
                                    ? TextDecoration.underline
                                    : null,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        onTap: _isVoting
                            ? null
                            : () async {
                                debugPrint(
                                    '🎯 [VOTING_DIALOG] Vote button pressed | orientation: ${_getOrientationValue(orientation)}, isVoting: $_isVoting');
                                if (_isVoting) {
                                  debugPrint(
                                      '⚠️ [VOTING_DIALOG] Already voting, ignoring click');
                                  return;
                                }
                                _isVoting = true;
                                setState(() {});
                                debugPrint('🔒 [VOTING_DIALOG] Voting locked');
                                HapticFeedback.lightImpact();
                                final orientationValue =
                                    _getOrientationValue(orientation);
                                try {
                                  final postsStateProvider =
                                      context.read<PostsStateProvider>();
                                  await postsStateProvider
                                      .votePoliticalOrientation(
                                    _currentPost.id,
                                    orientationValue,
                                  );
                                  if (mounted) {
                                    SafeNavigation.pop(context);
                                  }
                                  final updatedPost = postsStateProvider
                                      .getPost(_currentPost.id);
                                  if (updatedPost != null) {
                                    if (mounted) {
                                      setState(() {
                                        _currentPost = updatedPost;
                                      });
                                    }
                                    final eventBus = EventBus();
                                    final medianOrientation =
                                        _calculateMedian();
                                    final dominantView =
                                        _getOrientationValue(medianOrientation);
                                    eventBus.fire(PostVotedEvent(
                                      postId: updatedPost.id,
                                      vote: orientationValue,
                                      dominantView: dominantView,
                                      voteDistribution: updatedPost
                                          .politicalOrientation.userVotes,
                                    ));
                                    if (widget.onVoteChanged != null) {
                                      widget.onVoteChanged!(updatedPost);
                                    }
                                  }
                                } catch (e) {
                                  debugPrint(
                                      '❌ [VOTING_DIALOG] Vote error | error: $e');
                                  if (!mounted) return;
                                  SafeNavigation.showSnackBar(
                                    context,
                                    SnackBar(
                                      content: Text(
                                          'Erreur lors du vote: ${e.toString()}'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isVoting = false;
                                    });
                                    debugPrint(
                                        '🔓 [VOTING_DIALOG] Voting unlocked');
                                  }
                                }
                              },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}