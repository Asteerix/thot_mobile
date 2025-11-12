import 'dart:io';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:thot/core/config/app_config.dart';
import 'package:thot/core/services/network/api_client.dart';
import 'package:thot/core/services/connectivity/connectivity_service.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/core/config/api_routes.dart';
import 'package:thot/core/services/logging/logger_service.dart';
final _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: false,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
  level: Level.debug,
);
class UploadService with ConnectivityAware {
  static const int hashChunkSize = 8192;
  final _loggerService = LoggerService.instance;
  Future<String> getFileHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return hex.encode(digest.bytes);
    } catch (e) {
      _loggerService.error('Error generating file hash: $e');
      throw Exception('Failed to generate file hash: $e');
    }
  }
  final ApiService _apiService = ServiceLocator.instance.apiService;
  UploadService();
  String _getMimeType(File file, String type) {
    final ext = extension(file.path).toLowerCase();
    if (type == 'podcast') {
      switch (ext) {
        case '.mp3':
          return 'audio/mpeg';
        case '.wav':
          return 'audio/wav';
        case '.ogg':
          return 'audio/ogg';
        case '.m4a':
          return 'audio/mp4';
        default:
          return 'audio/mpeg';
      }
    }
    if (ext == '.mp4') {
      return 'video/mp4';
    }
    return 'image/jpeg';
  }
  Future<String> _uploadFile(File file, String type,
      {void Function(double)? onProgress}) async {
    return withConnectivity(() async {
      try {
        _loggerService.info('Starting upload for type: $type');
        _logger.d('Starting file upload');
        final mimeType = _getMimeType(file, type);
        final filename = basename(file.path);
        _loggerService.info(
            'Uploading file: path=${file.path}, name=$filename, type=$type, mime=$mimeType');
        _loggerService.info('File: $filename, MIME: $mimeType');
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            file.path,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          ),
          'type': type,
        });
        final uploadUrl = ApiRoutes.buildPath('${ApiRoutes.upload}?type=$type');
        _loggerService.info('Upload URL: $uploadUrl');
        final response = await _apiService.dio.post(
          uploadUrl,
          data: formData,
          onSendProgress: onProgress != null
              ? (sent, total) {
                  if (total != -1) {
                    final progress = sent / total;
                    _loggerService.debug(
                        'Progress: ${(progress * 100).toStringAsFixed(1)}% ($sent/$total bytes)');
                    onProgress(progress);
                  }
                }
              : null,
        );
        _loggerService.debug('Response status: ${response.statusCode}');
        _loggerService.debug('Response data: ${response.data}');
        if (response.data['success'] == true && response.data['url'] != null) {
          final urlFromBackend = response.data['url'].toString();
          if (urlFromBackend.startsWith('http://') || urlFromBackend.startsWith('https://')) {
            _loggerService.info('File uploaded successfully: url=$urlFromBackend');
            return urlFromBackend;
          }
          final baseUrl = _apiService.dio.options.baseUrl;
          final cleanBase = baseUrl.endsWith('/')
              ? baseUrl.substring(0, baseUrl.length - 1)
              : baseUrl;
          final cleanPath =
              urlFromBackend.startsWith('/') ? urlFromBackend : '/$urlFromBackend';
          final fullUrl = '$cleanBase$cleanPath';
          _loggerService.info('File uploaded successfully: url=$fullUrl');
          return fullUrl;
        } else {
          final error = response.data['error'] ?? 'Failed to upload file';
          _loggerService.error('Upload failed: $error');
          throw Exception(error);
        }
      } catch (e) {
        _loggerService.error('Upload error: ${e.toString()}');
        _loggerService.error('Exception: $e');
        throw Exception('Failed to upload file: $e');
      }
    });
  }
  Future<String> uploadArticleImage(File imageFile,
      {void Function(double)? onProgress}) async {
    _loggerService.debug('Uploading article image');
    return _uploadFile(imageFile, 'article', onProgress: onProgress);
  }
  Future<String> uploadQuestionImage(File imageFile,
      {void Function(double)? onProgress}) async {
    _loggerService.debug('Uploading question image');
    return _uploadFile(imageFile, 'question', onProgress: onProgress);
  }
  Future<String> uploadThumbnail(File imageFile,
      {bool isShort = false, void Function(double)? onProgress}) async {
    _loggerService
        .info('uploadThumbnail called for ${isShort ? 'short' : 'video'}');
    _loggerService.debug('Thumbnail size: ${await imageFile.length()} bytes');
    _loggerService.debug('Uploading ${isShort ? 'short' : 'video'} thumbnail');
    final result = await _uploadFile(imageFile, isShort ? 'short' : 'video',
        onProgress: onProgress);
    _loggerService.info('uploadThumbnail returning full URL: $result');
    return result;
  }
  Future<String> uploadVideo(File videoFile,
      {bool isShort = false, void Function(double)? onProgress}) async {
    _loggerService
        .info('uploadVideo called for ${isShort ? 'short' : 'video'}');
    _loggerService.debug('Uploading ${isShort ? 'short' : 'video'} file');
    if (!videoFile.path.toLowerCase().endsWith('.mp4')) {
      _loggerService.warning('Video file is not MP4 format: ${videoFile.path}');
    }
    final fileSize = videoFile.lengthSync();
    _loggerService.info(
        'Video file details: size=${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
    _loggerService
        .debug('Video size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
    _loggerService.info('Calling _uploadFile...');
    _loggerService.debug('Video file size: ${await videoFile.length()} bytes');
    final result = await _uploadFile(videoFile, isShort ? 'short' : 'video',
        onProgress: onProgress);
    _loggerService.info('_uploadFile returned full URL: $result');
    if (onProgress != null) {
      _loggerService.debug('Calling onProgress(1.0) to signal completion');
      onProgress(1.0);
    }
    _loggerService.info('uploadVideo returning full URL: $result');
    return result;
  }
  Future<String> uploadPodcast(File audioFile,
      {void Function(double)? onProgress}) async {
    _loggerService.debug('Uploading podcast file');
    final fileSize = audioFile.lengthSync();
    _loggerService.info(
        'Podcast file details: size=${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
    return _uploadFile(audioFile, 'podcast', onProgress: onProgress);
  }
  Future<String> uploadPodcastThumbnail(File imageFile,
      {void Function(double)? onProgress}) async {
    _loggerService.debug('Uploading podcast thumbnail');
    return _uploadFile(imageFile, 'article',
        onProgress: onProgress);
  }
  Future<Map<String, dynamic>> uploadImage(File imageFile,
      {required String type, void Function(double)? onProgress}) async {
    _loggerService.debug('Uploading $type image');
    if (type == 'profile' || type == 'cover') {
      return await _uploadProfileOrCover(imageFile, type,
          onProgress: onProgress);
    }
    final url = await _uploadFile(imageFile, type, onProgress: onProgress);
    return {'url': url};
  }
  Future<Map<String, dynamic>> _uploadProfileOrCover(File file, String type,
      {void Function(double)? onProgress}) async {
    return withConnectivity(() async {
      try {
        _loggerService.debug('Starting $type upload');
        final mimeType = 'image/jpeg';
        final filename = basename(file.path);
        _loggerService.info(
            'Uploading $type: path=${file.path}, name=$filename, mime=$mimeType');
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            file.path,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          ),
        });
        final endpoint = type == 'profile'
            ? ApiRoutes.buildPath(ApiRoutes.uploadProfile)
            : ApiRoutes.buildPath(ApiRoutes.uploadCover);
        final response = await _apiService.dio.post(
          endpoint,
          data: formData,
          onSendProgress: onProgress != null
              ? (sent, total) {
                  if (total != -1) {
                    onProgress(sent / total);
                  }
                }
              : null,
        );
        if (response.data['success'] == true && response.data['url'] != null) {
          final url = response.data['url'].toString().startsWith('/')
              ? '${AppConfig.apiBaseUrl}${response.data['url']}'
              : response.data['url'].toString();
          _loggerService.info('$type uploaded successfully: url=$url');
          return {'url': url};
        } else {
          final error = response.data['error'] ?? 'Failed to upload $type';
          _loggerService.error('Upload failed: $error');
          throw Exception(error);
        }
      } catch (e) {
        _loggerService.error('Upload error: ${e.toString()}');
        throw Exception('Failed to upload $type: $e');
      }
    });
  }
}