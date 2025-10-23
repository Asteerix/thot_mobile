class MediaDto {
  final String id;
  final String url;
  final String type;
  final String fileName;
  final int fileSize;
  final String? mimeType;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  const MediaDto({
    required this.id,
    required this.url,
    required this.type,
    required this.fileName,
    required this.fileSize,
    this.mimeType,
    this.metadata,
    this.createdAt,
  });
  factory MediaDto.fromJson(Map<String, dynamic> json) {
    return MediaDto(
      id: json['id'] as String,
      url: json['url'] as String,
      type: json['type'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      mimeType: json['mimeType'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'type': type,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'metadata': metadata,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}