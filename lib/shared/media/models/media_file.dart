import 'package:freezed_annotation/freezed_annotation.dart';
part 'media_file.freezed.dart';
part 'media_file.g.dart';
@freezed
class MediaFile with _$MediaFile {
  const factory MediaFile({
    required String id,
    required String url,
    required MediaType type,
    required String fileName,
    required int fileSize,
    String? mimeType,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) = _MediaFile;
  factory MediaFile.fromJson(Map<String, dynamic> json) =>
      _$MediaFileFromJson(json);
}
enum MediaType {
  image,
  video,
  audio,
  document,
}