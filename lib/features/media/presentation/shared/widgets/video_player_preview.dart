import 'package:thot/core/themes/app_colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:thot/features/media/domain/config/media_config.dart';
class VideoPlayerPreview extends StatefulWidget {
  final File videoFile;
  final double height;
  final double width;
  final bool autoPlay;
  final bool looping;
  final MediaType? type;
  const VideoPlayerPreview({
    super.key,
    required this.videoFile,
    this.height = 200,
    this.width = double.infinity,
    this.autoPlay = false,
    this.looping = true,
    this.type,
  });
  @override
  State<VideoPlayerPreview> createState() => _VideoPlayerPreviewState();
}
class _VideoPlayerPreviewState extends State<VideoPlayerPreview> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }
  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.file(widget.videoFile);
      await _videoPlayerController.initialize();
      final videoAspectRatio = _videoPlayerController.value.size.width /
          _videoPlayerController.value.size.height;
      double expectedAspectRatio = videoAspectRatio;
      if (widget.type == MediaType.short) {
        expectedAspectRatio = MediaConfig.shortAspectRatio;
      } else if (widget.type == MediaType.video) {
        expectedAspectRatio = MediaConfig.videoAspectRatio;
      }
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        aspectRatio: videoAspectRatio,
        showControls: true,
        allowFullScreen: false,
        placeholder: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Erreur de lecture vidéo',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      );
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _isInitialized = false;
      });
    }
  }
  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: _isInitialized
          ? widget.type == MediaType.short
              ? Center(
                  child: AspectRatio(
                    aspectRatio:
                        MediaConfig.shortAspectRatio,
                    child: Chewie(controller: _chewieController!),
                  ),
                )
              : Chewie(controller: _chewieController!)
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}