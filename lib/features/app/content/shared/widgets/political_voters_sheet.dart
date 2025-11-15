import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/core/routing/route_names.dart';
import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/shared/widgets/images/app_avatar.dart';
import 'package:thot/features/app/profile/widgets/follow_button.dart';
import '../widgets/political_orientation_utils.dart';

class PoliticalVotersSheet extends StatefulWidget {
  final String postId;
  final String orientation;
  final String title;
  const PoliticalVotersSheet({
    super.key,
    required this.postId,
    required this.orientation,
    required this.title,
  });
  static void show(BuildContext context, String postId, String orientation) {
    final label = PoliticalOrientationUtils.getLabel(
      PoliticalOrientation.values.firstWhere(
        (o) => o.toString().split('.').last == orientation,
      ),
    );
    SafeNavigation.showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PoliticalVotersSheet(
        postId: postId,
        orientation: orientation,
        title: 'Votes pour $label',
      ),
    );
  }

  @override
  State<PoliticalVotersSheet> createState() => _PoliticalVotersSheetState();
}

class _PoliticalVotersSheetState extends State<PoliticalVotersSheet> {
  final PostRepositoryImpl _postRepository =
      ServiceLocator.instance.postRepository;
  List<Map<String, dynamic>> _voters = [];
  bool _isLoading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadVoters();
  }

  Future<void> _loadVoters() async {
    try {
      final result = await _postRepository.getPoliticalVoters(
        widget.postId,
        widget.orientation,
      );
      if (mounted) {
        setState(() {
          _voters = List<Map<String, dynamic>>.from(result['voters'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!_isLoading)
                      Text(
                        '${_voters.length}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 0.5,
                color: Colors.white.withOpacity(0.1),
              ),
              Expanded(
                child: _buildContent(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadVoters,
              child: const Text(
                'Réessayer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
    if (_voters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.how_to_vote,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun vote',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _voters.length + _getSeparatorCount(),
      itemBuilder: (context, index) {
        if (_shouldShowSeparator(index)) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 0.5,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Utilisateurs',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 0.5,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          );
        }
        final voterIndex = _getUserIndex(index);
        final voter = _voters[voterIndex];
        return InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            SafeNavigation.pop(context);
            context.replaceNamed(
              RouteNames.profile,
              extra: {
                'userId': voter['_id'] ?? voter['id'],
                'forceReload': true
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: AppAvatar(
                        avatarUrl: voter['avatarUrl'],
                        radius: 24,
                        isJournalist: voter['isJournalist'] ?? false,
                        backgroundColor: Colors.grey[900],
                      ),
                    ),
                    if (voter['verified'] == true)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              voter['name'] ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (voter['isJournalist'] == true) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.4),
                                  width: 0.5,
                                ),
                              ),
                              child: const Text(
                                'Journaliste',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${voter['username'] ?? ''}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (voter['_id'] != null || voter['id'] != null)
                  FollowButton(
                    userId: voter['_id'] ?? voter['id'],
                    isFollowing: voter['isFollowing'] ?? false,
                    compact: true,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _getSeparatorCount() {
    final journalistCount =
        _voters.where((v) => v['isJournalist'] == true).length;
    final userCount = _voters.length - journalistCount;
    return (journalistCount > 0 && userCount > 0) ? 1 : 0;
  }

  bool _shouldShowSeparator(int index) {
    if (_getSeparatorCount() == 0) return false;
    final journalistCount =
        _voters.where((v) => v['isJournalist'] == true).length;
    return index == journalistCount;
  }

  int _getUserIndex(int listIndex) {
    if (_getSeparatorCount() == 0) return listIndex;
    final journalistCount =
        _voters.where((v) => v['isJournalist'] == true).length;
    if (listIndex <= journalistCount) return listIndex;
    return listIndex - 1;
  }
}
