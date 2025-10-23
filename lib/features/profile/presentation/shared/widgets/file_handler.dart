import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'profile_logger.dart';
class FileUploadData {
  final Uint8List? bytes;
  final String? path;
  final String filename;
  final String mimeType;
  final Map<String, dynamic>? metadata;
  FileUploadData({
    this.bytes,
    this.path,
    required this.filename,
    required this.mimeType,
    this.metadata,
  });
  bool get isWeb => bytes != null;
}
class FileHandler {
  static Future<FileUploadData> handleImageFile(XFile file,
      {bool isProfile = true, bool isShortThumbnail = false}) async {
    try {
      ProfileLogger.d('Starting image file handling');
      ProfileLogger.i(
          'File details: name=${file.name}, mime_type=${file.mimeType}, is_profile=$isProfile');
      final extension = file.name.split('.').last.toLowerCase();
      final prefix =
          isProfile ? 'profile' : (isShortThumbnail ? 'short' : 'cover');
      final filename =
          '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      ProfileLogger.d('Generated filename: $filename');
      if (kIsWeb) {
        ProfileLogger.d('Processing for web platform');
        try {
          final bytes = await file.readAsBytes();
          ProfileLogger.i(
              'Web file processed successfully: size=${(bytes.length / 1024 / 1024).toStringAsFixed(2)}MB');
          return FileUploadData(
            bytes: bytes,
            filename: filename,
            mimeType: file.mimeType ?? 'image/jpeg',
          );
        } catch (e) {
          ProfileLogger.e('Web file processing failed', error: e);
          rethrow;
        }
      }
      ProfileLogger.d('Processing for mobile platform');
      try {
        final tempDir = await getTemporaryDirectory();
        final tempPath = '${tempDir.path}/$filename';
        final bytes = await file.readAsBytes();
        if (isShortThumbnail) {
          final image = img.decodeImage(bytes);
          if (image != null) {
            final resized = img.copyResize(image,
                width: 1080,
                height: 1920,
                interpolation: img.Interpolation.linear);
            final processedBytes = img.encodeJpg(resized, quality: 85);
            await File(tempPath).writeAsBytes(processedBytes);
          } else {
            throw Exception('Failed to decode image');
          }
        } else {
          await File(tempPath).writeAsBytes(bytes);
        }
        final tempFile = File(tempPath);
        final fileSize = tempFile.lengthSync();
        ProfileLogger.i(
            'Image file processed successfully: path=${tempFile.path}, size=${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB, extension=$extension');
        return FileUploadData(
          path: tempFile.path,
          filename: filename,
          mimeType: file.mimeType ?? 'image/jpeg',
          metadata: {
            'size': fileSize,
            'extension': extension,
          },
        );
      } catch (e) {
        ProfileLogger.e('Mobile file processing failed', error: e);
        rethrow;
      }
    } catch (e) {
      ProfileLogger.f('Fatal error handling image file', error: e);
      rethrow;
    }
  }
  static Future<FileUploadData> handleVideoFile(XFile file) async {
    try {
      ProfileLogger.d('Starting video file handling');
      final originalExt = file.name.split('.').last.toLowerCase();
      ProfileLogger.i(
          'File details: name=${file.name}, mime_type=${file.mimeType}, original_extension=$originalExt');
      final filename = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      ProfileLogger.d('Generated filename: $filename');
      if (kIsWeb) {
        ProfileLogger.d('Processing for web platform');
        try {
          final bytes = await file.readAsBytes();
          ProfileLogger.i(
              'Web file processed successfully: size=${(bytes.length / 1024 / 1024).toStringAsFixed(2)}MB');
          return FileUploadData(
            bytes: bytes,
            filename: filename,
            mimeType: 'video/mp4',
          );
        } catch (e) {
          ProfileLogger.e('Web file processing failed', error: e);
          rethrow;
        }
      }
      ProfileLogger.d('Processing for mobile platform');
      try {
        final tempDir = await getTemporaryDirectory();
        final tempPath = '${tempDir.path}/$filename';
        final bytes = await file.readAsBytes();
        final tempFile = await File(tempPath).writeAsBytes(bytes);
        final fileSize = tempFile.lengthSync();
        ProfileLogger.i(
            'Video file processed successfully: path=${tempFile.path}, size=${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB, original_name=${file.name}, original_extension=$originalExt');
        return FileUploadData(
          path: tempFile.path,
          filename: filename,
          mimeType: 'video/mp4',
          metadata: {
            'size': fileSize,
            'original_name': file.name,
            'original_extension': originalExt,
          },
        );
      } catch (e) {
        ProfileLogger.e('Mobile file processing failed', error: e);
        rethrow;
      }
    } catch (e) {
      ProfileLogger.f('Fatal error handling video file', error: e);
      rethrow;
    }
  }
  static Future<FileUploadData> handleAudioFile(XFile file) async {
    try {
      ProfileLogger.d('Starting audio file handling');
      final originalExt = file.name.split('.').last.toLowerCase();
      ProfileLogger.i(
          'File details: name=${file.name}, mime_type=${file.mimeType}, original_extension=$originalExt');
      final filename =
          'podcast_${DateTime.now().millisecondsSinceEpoch}.$originalExt';
      ProfileLogger.d('Generated filename: $filename');
      if (kIsWeb) {
        ProfileLogger.d('Processing for web platform');
        try {
          final bytes = await file.readAsBytes();
          ProfileLogger.i(
              'Web file processed successfully: size=${(bytes.length / 1024 / 1024).toStringAsFixed(2)}MB');
          return FileUploadData(
            bytes: bytes,
            filename: filename,
            mimeType: file.mimeType ?? 'audio/mpeg',
          );
        } catch (e) {
          ProfileLogger.e('Web file processing failed', error: e);
          rethrow;
        }
      }
      ProfileLogger.d('Processing for mobile platform');
      try {
        final tempDir = await getTemporaryDirectory();
        final tempPath = '${tempDir.path}/$filename';
        final bytes = await file.readAsBytes();
        final tempFile = await File(tempPath).writeAsBytes(bytes);
        final fileSize = tempFile.lengthSync();
        ProfileLogger.i(
            'Audio file processed successfully: path=${tempFile.path}, size=${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB, original_name=${file.name}, original_extension=$originalExt');
        return FileUploadData(
          path: tempFile.path,
          filename: filename,
          mimeType: file.mimeType ?? 'audio/mpeg',
          metadata: {
            'size': fileSize,
            'original_name': file.name,
            'original_extension': originalExt,
          },
        );
      } catch (e) {
        ProfileLogger.e('Mobile file processing failed', error: e);
        rethrow;
      }
    } catch (e) {
      ProfileLogger.f('Fatal error handling audio file', error: e);
      rethrow;
    }
  }
}