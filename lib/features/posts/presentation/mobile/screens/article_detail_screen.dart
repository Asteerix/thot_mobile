import 'package:thot/core/themes/app_colors.dart' as colors;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/core/themes/ui_tokens.dart';
import 'package:thot/core/constants/app_constants.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/features/media/presentation/shared/widgets/video_player_widget.dart';
import 'package:thot/features/media/utils/image_utils.dart';
import 'package:thot/features/profile/presentation/shared/widgets/badges.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/posts/presentation/shared/widgets/voting_dialog.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'package:thot/features/comments/presentation/shared/widgets/comment_sheet.dart';
class ArticleDetailScreen extends StatefulWidget {
  final String postId;
  final bool? isSaved;
  final bool? isShort;
  final bool showTabs;
  const ArticleDetailScreen({
    super.key,
    required this.postId,
    this.isSaved,
    this.isShort,
    this.showTabs = true,
  });
  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}
class _ArticleDetailScreenState extends State<ArticleDetailScreen>
    with SingleTickerProviderStateMixin {
  late final PostRepositoryImpl _postRepository =
      ServiceLocator.instance.postRepository;
  late TabController _tabController;
  Post? _post;
  bool _isLoading = true;
  String? _error;
  bool _isFollowing = false;
  bool _isProcessingFollow = false;
  bool _isLiked = false;
  bool _isProcessingLike = false;
  int _optimisticLikes = 0;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPost();
  }
  Future<void> _loadPost() async {
    try {
      final postData = await _postRepository.getPost(widget.postId);
      final post = Post.fromJson(postData);
      final isFollowing = false;
      if (!mounted) return;
      setState(() {
        _post = post;
        _isFollowing = isFollowing;
        _optimisticLikes = post.interactions.likes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  Future<void> _handleFollowToggle() async {
    if (_isProcessingFollow ||
        _post == null ||
        !mounted ||
        _post!.journalist == null) {
      return;
    }
    final wasFollowing = _isFollowing;
    setState(() {
      _isFollowing = !_isFollowing;
      _isProcessingFollow = true;
    });
    try {
      if (wasFollowing) {
        await _postRepository.unfollowJournalist(_post!.journalist!.id!);
      } else {
        await _postRepository.followJournalist(_post!.journalist!.id!);
      }
    } catch (e) {
      setState(() {
        _isFollowing = wasFollowing;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Échec ${wasFollowing ? 'du désabonnement' : 'de l\'abonnement'}: ${e.toString()}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingFollow = false;
        });
      }
    }
  }
  Future<void> _handleLikeToggle() async {
    if (_isProcessingLike || _post == null || !mounted) return;
    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _optimisticLikes += _isLiked ? 1 : -1;
      _isProcessingLike = true;
    });
    try {
      await _postRepository.interactWithPost(
          widget.postId, 'like', _isLiked ? 'add' : 'remove');
    } catch (e) {
      setState(() {
        _isLiked = wasLiked;
        _optimisticLikes += wasLiked ? 1 : -1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de l\'interaction: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingLike = false;
        });
      }
    }
  }
  Future<void> _handleInteraction(String type, String action) async {
    if (!mounted) return;
    if (type == 'comment' && action == 'add') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CommentsBottomSheet(postId: widget.postId),
      );
      return;
    }
    try {
      await _postRepository.interactWithPost(widget.postId, type, action);
      await _loadPost();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de l\'interaction: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(child: _buildLoadingSkeleton()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: _buildErrorState(colorScheme),
      );
    }
    if (_post == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Text(
            'Article non trouvé',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: _post!.type == PostType.video ? 300 : 250,
            pinned: true,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: colorScheme.surfaceTint,
            flexibleSpace: Stack(
              children: [
                FlexibleSpaceBar(
                  background: _post!.type == PostType.video
                      ? VideoPlayerWidget(videoUrl: _post!.videoUrl!)
                      : Hero(
                          tag: 'post-image-${_post!.id}',
                          child: _post!.imageUrl != null
                              ? Image.network(
                                  _post!.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.error_outline,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                        ),
                ),
                _buildTypeOverlay(colorScheme),
              ],
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new),
                iconSize: 20,
                color: Colors.white,
                onPressed: () => SafeNavigation.pop(context),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.showTabs)
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Perspective divergente'),
                    Tab(text: 'Suggestions'),
                  ],
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  indicatorColor: colorScheme.primary,
                ),
              ),
            ),
        ],
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildArticleHeader(colorScheme),
                    if (_post!.content.isNotEmpty)
                      _buildArticleContent(colorScheme),
                    if (widget.showTabs)
                      SizedBox(
                        height: 400,
                        child: TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildPerspectiveTab(colorScheme),
                            _buildSuggestionsTab(colorScheme),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _buildBottomActions(colorScheme),
          ],
        ),
      ),
    );
  }
  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: EdgeInsets.all(UIConstants.paddingM),
      child: Column(
        children: [
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: UITokens.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(UIConstants.radiusM),
            ),
          ),
          const SizedBox(height: UIConstants.paddingM),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: UITokens.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: UIConstants.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: UITokens.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(UIConstants.radiusS),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 14,
                      width: 80,
                      decoration: BoxDecoration(
                        color: UITokens.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(UIConstants.radiusS),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: UIConstants.paddingM),
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: UITokens.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(UIConstants.radiusS),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(UIConstants.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: UIConstants.paddingM),
            Text(
              'Erreur lors du chargement de l\'article',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.paddingS),
            Text(
              _error ?? 'Erreur inconnue',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.paddingL),
            FilledButton.icon(
              onPressed: _loadPost,
              icon: Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildArticleHeader(ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.all(UIConstants.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (_post!.journalist?.id != null) {
                    context.push('/profile/${_post!.journalist!.id}');
                  }
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: _post!.journalist?.avatarUrl?.isNotEmpty ==
                          true
                      ? NetworkImage(
                          ImageUtils.getAvatarUrl(_post!.journalist!.avatarUrl!))
                      : const AssetImage(UIConstants.defaultJournalistAvatarPath)
                          as ImageProvider,
                ),
              ),
              const SizedBox(width: UIConstants.paddingM),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_post!.journalist?.id != null) {
                      context.push('/profile/${_post!.journalist!.id}');
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _post!.journalist?.name ?? 'Inconnu',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        '@${_post!.journalist?.username ?? 'unknown'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_post!.journalist?.isVerified ?? false)
                const VerificationBadge(size: 20),
              const SizedBox(width: UIConstants.paddingS),
              _buildPublicOpinionBadge(colorScheme),
              const SizedBox(width: UIConstants.paddingS),
              _buildFollowButton(colorScheme),
            ],
          ),
          const SizedBox(height: UIConstants.paddingM),
          Text(
            _post!.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: UIConstants.paddingS),
          Row(
            children: [
              Icon(Icons.visibility,
                  size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                formatViews(_post!.stats.views),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: UIConstants.paddingM),
              Icon(
                _isLiked ? Icons.thumb_up : Icons.thumb_up,
                size: 16,
                color: _isLiked
                    ? _getPoliticalViewColor(
                        _post!.politicalOrientation.journalistChoice)
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '$_optimisticLikes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _isLiked
                          ? _getPoliticalViewColor(
                              _post!.politicalOrientation.journalistChoice)
                          : colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: UIConstants.paddingM),
              Icon(Icons.comment,
                  size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${_post!.interactions.comments}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              if (_post!.content.isNotEmpty) ...[
                const SizedBox(width: UIConstants.paddingM),
                Icon(Icons.schedule,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  readingTime(_post!.content),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  String formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }
  String readingTime(String content) {
    const wordsPerMinute = 200;
    final wordCount = content.split(' ').length;
    final minutes = (wordCount / wordsPerMinute).ceil();
    return '$minutes min';
  }
  final TextStyle tBody = const TextStyle(fontSize: 16, height: 1.6);
  Widget _buildArticleContent(ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.all(UIConstants.paddingM),
      child: Text(
        _post!.content,
        style: tBody,
      ),
    );
  }
  Widget _buildFollowButton(ColorScheme colorScheme) {
    final currentUserId = context.watch<AuthProvider>().userProfile?.id;
    final isOwnPost = currentUserId != null &&
                      _post?.journalist?.id != null &&
                      currentUserId == _post!.journalist!.id;
    if (isOwnPost) {
      return const SizedBox.shrink();
    }
    return FilledButton(
      onPressed: _post!.journalist != null ? _handleFollowToggle : null,
      style: FilledButton.styleFrom(
        backgroundColor: _isFollowing
            ? colorScheme.surfaceContainerHighest
            : colorScheme.primary,
        foregroundColor:
            _isFollowing ? colorScheme.onSurface : colorScheme.onPrimary,
        minimumSize: const Size(80, 32),
        padding: EdgeInsets.symmetric(horizontal: UIConstants.paddingM),
      ),
      child: _isProcessingFollow
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _isFollowing
                    ? colorScheme.onSurface
                    : colorScheme.onPrimary,
              ),
            )
          : Text(
              _isFollowing ? 'Abonné' : 'S\'abonner',
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Tailwind',
              ),
            ),
    );
  }
  Widget _buildBottomActions(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: UIConstants.paddingM,
        vertical: UIConstants.paddingS,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            _isLiked ? Icons.thumb_up : Icons.thumb_up,
            '$_optimisticLikes',
            _handleLikeToggle,
            colorScheme,
            isActive: _isLiked,
            isLoading: _isProcessingLike,
          ),
          _buildActionButton(
            Icons.comment,
            '${_post!.interactions.comments}',
            () => _handleInteraction('comment', 'add'),
            colorScheme,
          ),
        ],
      ),
    );
  }
  Widget _buildActionButton(
    IconData icon,
    String count,
    VoidCallback onPressed,
    ColorScheme colorScheme, {
    bool isActive = false,
    bool isLoading = false,
  }) {
    final color = isActive
        ? _getPoliticalViewColor(_post!.politicalOrientation.journalistChoice)
        : colorScheme.onSurface;
    return TextButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          : Icon(icon, color: color),
      label: Text(
        count,
        style: TextStyle(
          color: color,
          fontFamily: 'Tailwind',
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusL),
        ),
      ),
    );
  }
  Widget _buildPerspectiveTab(ColorScheme colorScheme) {
    if (_post?.oppositions.isEmpty ?? true) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(UIConstants.paddingM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.balance,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: UIConstants.paddingM),
              Text(
                'Aucune publication en opposition',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(UIConstants.paddingM),
      itemCount: _post!.oppositions.length,
      itemBuilder: (context, index) {
        final oppositionPost = _post!.oppositions[index];
        return Card(
          margin: EdgeInsets.only(bottom: UIConstants.paddingS),
          child: ListTile(
            leading: FutureBuilder<Map<String, dynamic>>(
              future: _postRepository.getPost(oppositionPost.postId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data?['imageUrl'] != null) {
                  return CircleAvatar(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    child: ClipOval(
                      child: Image.network(
                        snapshot.data!['imageUrl'],
                        fit: BoxFit.cover,
                        width: 40,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.article,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                return CircleAvatar(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.article,
                    color: colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
            title: FutureBuilder<Map<String, dynamic>>(
              future: _postRepository.getPost(oppositionPost.postId),
              builder: (context, snapshot) {
                return Text(
                  snapshot.hasData ? snapshot.data!['title'] : 'Chargement...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                );
              },
            ),
            subtitle: Text(
              oppositionPost.description?.isNotEmpty == true
                  ? oppositionPost.description!
                  : 'Cette publication s\'oppose à l\'article',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            onTap: () {
              if (oppositionPost.postId.isNotEmpty) {
                context.push(
                  '/post/${oppositionPost.postId}',
                  extra: {
                    'postId': oppositionPost.postId,
                    'isFromProfile': false,
                    'isFromFeed': false,
                  },
                );
              }
            },
          ),
        );
      },
    );
  }
  Widget _buildSuggestionsTab(ColorScheme colorScheme) {
    final suggestions = _post?.metadata?.article?.relatedArticles ?? [];
    if (suggestions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(UIConstants.paddingM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: UIConstants.paddingM),
              Text(
                'Aucune suggestion disponible',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(UIConstants.paddingM),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return Card(
          margin: EdgeInsets.only(bottom: UIConstants.paddingS),
          child: ListTile(
            leading: Icon(
              Icons.lightbulb_outline,
              color: colorScheme.primary,
            ),
            title: Text(
              suggestion,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildTypeOverlay(ColorScheme colorScheme) {
    return Positioned(
      top: UIConstants.paddingS,
      left: UIConstants.paddingM,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: UIConstants.paddingS,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(UIConstants.radiusXS),
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        ),
        child: Text(
          _getTypeLabel(_post!.type),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
        ),
      ),
    );
  }
  String _getTypeLabel(PostType type) {
    switch (type) {
      case PostType.article:
        return 'ARTICLE';
      case PostType.video:
        return 'VIDÉO';
      case PostType.podcast:
        return 'PODCAST';
      case PostType.live:
        return 'LIVE';
      case PostType.poll:
        return 'SONDAGE';
      case PostType.testimony:
        return 'TÉMOIGNAGE';
      case PostType.documentation:
        return 'DOCUMENTATION';
      case PostType.opinion:
        return 'OPINION';
      case PostType.short:
        return 'SHORT';
      case PostType.question:
        return 'QUESTION';
    }
  }
  Widget _buildPublicOpinionBadge(ColorScheme colorScheme) {
    return InkWell(
      onTap: () => _showVotingDialog(colorScheme),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _getPoliticalViewColor(
                  _post!.politicalOrientation.journalistChoice)
              .withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: _getPoliticalViewIcon(
              _post!.politicalOrientation.journalistChoice),
        ),
      ),
    );
  }
  void _showVotingDialog(ColorScheme colorScheme) {
    if (_post == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VotingDialog(
        post: _post!,
        onVoteChanged: (updatedPost) {
          setState(() {
            _post = updatedPost;
          });
        },
      ),
    );
  }
  Widget _getPoliticalViewIcon(PoliticalOrientation? view) {
    return Icon(
      Icons.public,
      size: 20,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
  Color _getPoliticalViewColor(PoliticalOrientation? view) {
    return switch (view) {
      PoliticalOrientation.extremelyProgressive =>
        colors.AppColors.extremelyProgressive,
      PoliticalOrientation.progressive => colors.AppColors.progressive,
      PoliticalOrientation.extremelyConservative =>
        colors.AppColors.extremelyConservative,
      PoliticalOrientation.conservative => colors.AppColors.conservative,
      PoliticalOrientation.neutral => colors.AppColors.neutral,
      null => colors.AppColors.neutral,
    };
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }
  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}