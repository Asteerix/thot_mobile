import 'package:thot/core/utils/either.dart';
import 'package:thot/features/media/domain/entities/media_file.dart';
import 'package:thot/features/media/domain/failures/media_failure.dart';
abstract class MediaRepository {
  Future<Either<MediaFailure, String>> uploadImage(
      List<int> bytes, String fileName);
  Future<Either<MediaFailure, String>> uploadVideo(
      List<int> bytes, String fileName);
  Future<Either<MediaFailure, String>> uploadAudio(
      List<int> bytes, String fileName);
  Future<Either<MediaFailure, void>> deleteMedia(String mediaId);
  Future<Either<MediaFailure, MediaFile>> getMediaInfo(String mediaId);
}