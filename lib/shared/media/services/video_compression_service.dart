import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:logger/logger.dart';
class VideoCompressionService {
  static final _logger = Logger();
  static final _videoCompress = VideoCompress;
  static Future<File?> compressVideo(
    File videoFile, {
    required String type,
    void Function(double)? onProgress,
  }) async {
    return compressVideoSimple(videoFile, type: type, onProgress: onProgress);
  }
  static Future<File?> compressVideoSimple(
    File videoFile, {
    required String type,
    void Function(double)? onProgress,
  }) async {
    try {
      _logger.i('Starting simple video compression for type: $type');
      if (onProgress != null) {
        _videoCompress.compressProgress$.subscribe((progress) {
          onProgress(progress / 100);
        });
      }
      final quality = type == 'short'
          ? VideoQuality.MediumQuality
          : VideoQuality.DefaultQuality;
      final info = await _videoCompress.compressVideo(
        videoFile.path,
        quality: quality,
        deleteOrigin: false,
        includeAudio: true,
      );
      if (info != null && info.file != null) {
        _logger.i('Simple compression completed');
        _logger.i(
            'Original size: ${(videoFile.lengthSync() / 1024 / 1024).toStringAsFixed(2)}MB');
        _logger.i(
            'Compressed size: ${(info.filesize! / 1024 / 1024).toStringAsFixed(2)}MB');
        return info.file;
      }
      return null;
    } catch (e) {
      _logger.e('Simple video compression error: $e');
      return null;
    } finally {
      await _videoCompress.deleteAllCache();
    }
  }
  static Future<File?> generateThumbnail(
    File videoFile, {
    int position = 1000,
    int? maxHeight,
    int? maxWidth,
    int quality = 85,
  }) async {
    try {
      _logger.i('Generating video thumbnail');
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: maxHeight ?? (videoFile.path.contains('short') ? 1280 : 720),
        maxWidth: maxWidth ?? (videoFile.path.contains('short') ? 720 : 1280),
        timeMs: position,
        quality: quality,
      );
      if (thumbnailPath != null) {
        _logger.i('Thumbnail generated: $thumbnailPath');
        return File(thumbnailPath);
      }
      return null;
    } catch (e) {
      _logger.e('Thumbnail generation error: $e');
      return null;
    }
  }
  static Future<VideoMetadata?> getVideoMetadata(File videoFile) async {
    try {
      final info = await _videoCompress.getMediaInfo(videoFile.path);
      return VideoMetadata(
        duration: info.duration?.toInt() ?? 0,
        width: info.width?.toDouble() ?? 0,
        height: info.height?.toDouble() ?? 0,
        filesize: info.filesize ?? 0,
        path: info.path ?? '',
        title: info.title,
        author: info.author,
        orientation: info.orientation ?? 0,
      );
    } catch (e) {
      _logger.e('Error getting video metadata: $e');
      return null;
    }
  }
  static Future<VideoValidationResult> validateVideo(
    File videoFile, {
    required String type,
  }) async {
    try {
      final metadata = await getVideoMetadata(videoFile);
      if (metadata == null) {
        return VideoValidationResult(
          isValid: false,
          errors: ['Could not read video metadata'],
        );
      }
      final errors = <String>[];
      if (type == 'short' && metadata.duration > 60000) {
        errors.add('Short videos must be 60 seconds or less');
      } else if (type == 'video' && metadata.duration > 300000) {
        errors.add('Videos must be 5 minutes or less');
      }
      if (type == 'short') {
        final aspectRatio = metadata.width / metadata.height;
        if (aspectRatio > 1) {
          errors.add('Short videos must be in portrait orientation');
        }
      }
      final maxSize = type == 'short' ? 100 : 500;
      if (metadata.filesize > maxSize * 1024 * 1024) {
        errors.add('Video size must be less than ${maxSize}MB');
      }
      return VideoValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        metadata: metadata,
      );
    } catch (e) {
      _logger.e('Video validation error: $e');
      return VideoValidationResult(
        isValid: false,
        errors: ['Validation failed: ${e.toString()}'],
      );
    }
  }
}
class VideoMetadata {
  final int duration;
  final double width;
  final double height;
  final int filesize;
  final String path;
  final String? title;
  final String? author;
  final int orientation;
  VideoMetadata({
    required this.duration,
    required this.width,
    required this.height,
    required this.filesize,
    required this.path,
    this.title,
    this.author,
    required this.orientation,
  });
  double get aspectRatio => width / height;
  bool get isPortrait => aspectRatio < 1;
  bool get isLandscape => aspectRatio > 1;
  String get sizeInMB => (filesize / 1024 / 1024).toStringAsFixed(2);
  String get durationFormatted {
    final seconds = duration ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
class VideoValidationResult {
  final bool isValid;
  final List<String> errors;
  final VideoMetadata? metadata;
  VideoValidationResult({
    required this.isValid,
    required this.errors,
    this.metadata,
  });
}