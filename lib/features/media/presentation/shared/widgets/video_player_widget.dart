import 'package:flutter/material.dart';
class VideoPlayerWidget extends StatelessWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool showControls;
  final VoidCallback? onTap;
  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.showControls = true,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Text(
              'Video Player',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            if (showControls)
              const Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 64,
              ),
          ],
        ),
      ),
    );
  }
}