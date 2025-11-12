import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:image/image.dart' as img;
import 'package:thot/shared/media/config/media_config.dart';
import 'package:thot/shared/media/screens/image_crop_screen.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/core/services/logging/logger_service.dart';
class MediaProcessor {
  static final _logger = LoggerService.instance;
  static Future<File?> processImage(
      XFile imageFile, MediaType type, BuildContext context) async {
    try {
      final bytes = await imageFile.readAsBytes();
      if (bytes.isEmpty) {
        _logger.error('Image file is empty');
        return null;
      }
      final testImage = img.decodeImage(bytes);
      if (testImage == null) {
        _logger.error('Failed to decode image for validation');
        final file = File(imageFile.path);
        if (!await file.exists()) {
          _logger.error('Image file does not exist');
          return null;
        }
        final fileBytes = await file.readAsBytes();
        final retryImage = img.decodeImage(fileBytes);
        if (retryImage == null) {
          _logger.error('Failed to decode image from file');
          return null;
        }
      }
      final croppedBytes = await _cropImage(bytes, type, context);
      Uint8List? finalBytes = croppedBytes;
      if (finalBytes == null) {
        _logger.info('Using fallback image processing without crop UI');
        finalBytes = await _processImageFallback(bytes, type);
        if (finalBytes == null) return null;
      }
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final image = img.decodeImage(finalBytes);
      if (image == null) {
        _logger.error('Failed to decode final image');
        return null;
      }
      final maxDimension = 2048;
      img.Image resized = image;
      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width > image.height) {
          resized = img.copyResize(
            image,
            width: maxDimension,
            height: (maxDimension * image.height / image.width).round(),
            interpolation: img.Interpolation.linear,
          );
        } else {
          resized = img.copyResize(
            image,
            width: (maxDimension * image.width / image.height).round(),
            height: maxDimension,
            interpolation: img.Interpolation.linear,
          );
        }
      }
      final compressedBytes = img.encodeJpg(
        resized,
        quality: MediaConfig.jpegQuality,
      );
      await tempFile.writeAsBytes(compressedBytes);
      return tempFile;
    } catch (e) {
      _logger.error('Error processing image', e);
      return null;
    }
  }
  static Future<File?> processVideo(XFile videoFile, MediaType type) async {
    try {
      final controller = VideoPlayerController.file(File(videoFile.path));
      await controller.initialize();
      final duration = controller.value.duration;
      final maxDuration = type.maxVideoDuration;
      if (maxDuration != null && duration.inSeconds > maxDuration) {
        throw Exception('Video duration exceeds the maximum allowed length');
      }
      final file = File(videoFile.path);
      final fileSize = await file.length();
      if (fileSize > type.maxFileSize) {
        throw Exception('Video size exceeds the maximum allowed size');
      }
      if (type == MediaType.short) {
        final width = controller.value.size.width;
        final height = controller.value.size.height;
        if (width > height) {
          throw Exception('Short videos must be in portrait orientation');
        }
      }
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}',
      );
      await file.copy(tempFile.path);
      await controller.dispose();
      return tempFile;
    } catch (e) {
      _logger.error('Error processing video', e);
      return null;
    }
  }
  static Future<Uint8List?> _cropImage(
      Uint8List imageBytes, MediaType type, BuildContext context) async {
    try {
      if (!context.mounted) return null;
      if (imageBytes.isEmpty) {
        _logger.error('Cannot crop empty image');
        return null;
      }
      final testImage = img.decodeImage(imageBytes);
      if (testImage == null) {
        _logger.error('Image cannot be decoded for cropping');
        return null;
      }
      final pngBytes = img.encodePng(testImage);
      return await SafeNavigation.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (context) => ImageCropScreen(
            imageBytes: Uint8List.fromList(pngBytes),
            type: type,
          ),
        ),
      );
    } catch (e) {
      _logger.error('Error cropping image', e);
      return null;
    }
  }
  static Future<Uint8List?> _processImageFallback(
      Uint8List imageBytes, MediaType type) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;
      final aspectRatio = type.aspectRatio;
      int targetWidth, targetHeight;
      if (aspectRatio > 1) {
        targetWidth = image.width;
        targetHeight = (targetWidth / aspectRatio).round();
        if (targetHeight > image.height) {
          targetHeight = image.height;
          targetWidth = (targetHeight * aspectRatio).round();
        }
      } else {
        targetHeight = image.height;
        targetWidth = (targetHeight * aspectRatio).round();
        if (targetWidth > image.width) {
          targetWidth = image.width;
          targetHeight = (targetWidth / aspectRatio).round();
        }
      }
      final xOffset = (image.width - targetWidth) ~/ 2;
      final yOffset = (image.height - targetHeight) ~/ 2;
      final cropped = img.copyCrop(
        image,
        x: xOffset.clamp(0, image.width - 1),
        y: yOffset.clamp(0, image.height - 1),
        width: targetWidth.clamp(1, image.width),
        height: targetHeight.clamp(1, image.height),
      );
      return Uint8List.fromList(
          img.encodeJpg(cropped, quality: MediaConfig.jpegQuality));
    } catch (e) {
      _logger.error('Error in fallback image processing', e);
      return null;
    }
  }
  static Future<File?> processAudio(XFile audioFile, MediaType type) async {
    try {
      final file = File(audioFile.path);
      final fileSize = await file.length();
      if (fileSize > type.maxFileSize) {
        throw MediaProcessingException(
            'Audio size exceeds the maximum allowed size');
      }
      final player = AudioPlayer();
      await player.setFilePath(audioFile.path);
      final duration = player.duration;
      await player.dispose();
      if (duration == null) {
        throw MediaProcessingException('Could not determine audio duration');
      }
      return file;
    } catch (e) {
      _logger.error('Error processing audio', e);
      return null;
    }
  }
}
class MediaProcessingException implements Exception {
  final String message;
  MediaProcessingException(this.message);
  @override
  String toString() => message;
}
class MediaMetadata {
  final int size;
  final int duration;
  final String quality;
  final String originalName;
  final String originalExtension;
  MediaMetadata({
    required this.size,
    required this.duration,
    required this.quality,
    required this.originalName,
    required this.originalExtension,
  });
  Map<String, dynamic> toJson() => {
        'size': size,
        'duration': duration,
        'quality': quality,
        'original_name': originalName,
        'original_extension': originalExtension,
      };
}