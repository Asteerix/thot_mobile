import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/core/utils/number_formatter.dart';
import 'package:thot/core/utils/date_formatter.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/features/posts/presentation/shared/widgets/post_content.dart';
class VideoPost extends StatefulWidget {
  final Post post;
  final bool isVideoPlaying;
  final Function(bool) onVideoPlayingChanged;
  const VideoPost({
    super.key,
    required this.post,
    required this.isVideoPlaying,
    required this.onVideoPlayingChanged,
  });
  @override
  State<VideoPost> createState() => _VideoPostState();
}
class _VideoPostState extends State<VideoPost>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  String _formatViews(int views) {
    return '${NumberFormatter.format(views)} vues';
  }
  String _getTimeAgo(DateTime dateTime) {
    return DateFormatter.timeAgoFrench(dateTime);
  }
  void _playVideo() {
    widget.onVideoPlayingChanged(true);
    Future.microtask(() {
      if (context.mounted) {
        SafeNavigation.showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => PopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) {
                await SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                ]);
                await SystemChrome.setEnabledSystemUIMode(
                    SystemUiMode.edgeToEdge);
                widget.onVideoPlayingChanged(false);
              }
            },
            child: Dialog.fullscreen(
              backgroundColor: Colors.black,
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.landscapeLeft,
                        DeviceOrientation.landscapeRight,
                      ]);
                      SystemChrome.setEnabledSystemUIMode(
                          SystemUiMode.immersiveSticky);
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        color: Theme.of(context).colorScheme.onSurface,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: PostContent(
                              post: widget.post,
                              isDetailView: true,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.surface,
                        size: 28,
                      ),
                      onPressed: () => SafeNavigation.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height:
                MediaQuery.of(context).size.width * 9 / 16,
            color: Theme.of(context).colorScheme.onSurface,
            child: Stack(
              fit: StackFit.expand,
              children: [
                (widget.post.thumbnailUrl != null ||
                        widget.post.imageUrl != null)
                    ? Image.network(
                        widget.post.thumbnailUrl ?? widget.post.imageUrl ?? '',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: Center(
                              child: Icon(
                                Icons.video_library_outlined,
                                color: Theme.of(context).colorScheme.outline,
                                size: 64,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.surface,
                        child: Center(
                          child: Icon(
                            Icons.video_library_outlined,
                            color: Theme.of(context).colorScheme.outline,
                            size: 64,
                          ),
                        ),
                      ),
                if (!widget.isVideoPlaying)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => _playVideo(),
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Theme.of(context).colorScheme.surface,
                              size: 44,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      height: 1.2,
                      fontFamily: 'Tailwind',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        _formatViews(widget.post.stats.views),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '•',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getTimeAgo(widget.post.createdAt),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (widget.post.content.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description_outlined,
                                  size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                'Description',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.post.content,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 15,
                              height: 1.6,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}