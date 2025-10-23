import 'dart:io';
import 'package:thot/core/utils/either.dart';
import 'package:thot/core/network/api_client.dart';
import 'package:thot/core/connectivity/connectivity_service.dart';
import 'package:thot/core/monitoring/logger_service.dart';
import 'package:thot/core/constants/api_routes.dart';
import 'package:thot/features/media/domain/entities/media_file.dart';
import 'package:thot/features/media/domain/failures/media_failure.dart';
import 'package:thot/features/media/domain/repositories/media_repository.dart';
import 'package:thot/features/media/data/services/media_save_service.dart';
import 'package:thot/features/media/data/services/video_compression_service.dart';
import 'package:thot/features/media/infrastructure/upload_service.dart';
class MediaRepositoryImpl with ConnectivityAware implements MediaRepository {
  final ApiService _apiService;
  final UploadService _uploadService;
  final MediaSaveService _mediaSaveService;
  final _logger = LoggerService.instance;
  MediaRepositoryImpl({
    required ApiService apiService,
    required UploadService uploadService,
    required MediaSaveService mediaSaveService,
  })  : _apiService = apiService,
        _uploadService = uploadService,
        _mediaSaveService = mediaSaveService;
  @override
  Future<Either<MediaFailure, String>> uploadImage(
    List<int> bytes,
    String fileName,
  ) async {
    return withConnectivity(() async {
      try {
        _logger.info('Uploading image: $fileName');
        final tempFile = File('${Directory.systemTemp.path}/$fileName');
        await tempFile.writeAsBytes(bytes);
        final result = await _uploadService.uploadImage(tempFile, type: 'image');
        final url = result['url'] as String;
        await tempFile.delete();
        return Right(url);
      } catch (e) {
        _logger.error('Failed to upload image: $e');
        return Left(MediaFailureServer(e.toString()));
      }
    });
  }
  @override
  Future<Either<MediaFailure, String>> uploadVideo(
    List<int> bytes,
    String fileName,
  ) async {
    return withConnectivity(() async {
      try {
        _logger.info('Uploading video: $fileName');
        final tempFile = File('${Directory.systemTemp.path}/$fileName');
        await tempFile.writeAsBytes(bytes);
        final url = await _uploadService.uploadVideo(tempFile);
        await tempFile.delete();
        return Right(url);
      } catch (e) {
        _logger.error('Failed to upload video: $e');
        return Left(MediaFailureServer(e.toString()));
      }
    });
  }
  @override
  Future<Either<MediaFailure, String>> uploadAudio(
    List<int> bytes,
    String fileName,
  ) async {
    return withConnectivity(() async {
      try {
        _logger.info('Uploading audio: $fileName');
        final tempFile = File('${Directory.systemTemp.path}/$fileName');
        await tempFile.writeAsBytes(bytes);
        final url = await _uploadService.uploadPodcast(tempFile);
        await tempFile.delete();
        return Right(url);
      } catch (e) {
        _logger.error('Failed to upload audio: $e');
        return Left(MediaFailureServer(e.toString()));
      }
    });
  }
  @override
  Future<Either<MediaFailure, void>> deleteMedia(String mediaId) async {
    return withConnectivity(() async {
      try {
        _logger.info('Deleting media: $mediaId');
        await _apiService.delete('/api/media/$mediaId');
        return const Right(null);
      } catch (e) {
        _logger.error('Failed to delete media: $e');
        return Left(MediaFailureServer(e.toString()));
      }
    });
  }
  @override
  Future<Either<MediaFailure, MediaFile>> getMediaInfo(String mediaId) async {
    return withConnectivity(() async {
      try {
        _logger.info('Getting media info: $mediaId');
        final response = await _apiService.get('/api/media/$mediaId');
        final data = response.data['data'] ?? response.data;
        final mediaFile = MediaFile.fromJson(data);
        return Right(mediaFile);
      } catch (e) {
        _logger.error('Failed to get media info: $e');
        return Left(MediaFailureServer(e.toString()));
      }
    });
  }
  Future<File?> compressVideo(
    File videoFile, {
    required String type,
    void Function(double)? onProgress,
  }) async {
    return VideoCompressionService.compressVideo(
      videoFile,
      type: type,
      onProgress: onProgress,
    );
  }
  Future<File?> generateThumbnail(
    File videoFile, {
    int position = 1000,
    int? maxHeight,
    int? maxWidth,
    int quality = 85,
  }) async {
    return VideoCompressionService.generateThumbnail(
      videoFile,
      position: position,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      quality: quality,
    );
  }
  Future<bool> savePost(String postId) async {
    return _mediaSaveService.togglePostSave(postId);
  }
  Future<bool> unsavePost(String postId) async {
    return _mediaSaveService.togglePostSave(postId);
  }
  Future<bool> saveShort(String shortId) async {
    return _mediaSaveService.toggleShortSave(shortId);
  }
  Future<bool> unsaveShort(String shortId) async {
    return _mediaSaveService.toggleShortSave(shortId);
  }
  bool isPostSaved(String postId) {
    return _mediaSaveService.isPostSaved(postId);
  }
  bool isShortSaved(String shortId) {
    return _mediaSaveService.isShortSaved(shortId);
  }
  Stream<SaveState> get saveEvents => _mediaSaveService.saveEvents;
}