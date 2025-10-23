class ReportDto {
  final String id;
  final String reporterId;
  final String contentId;
  final String contentType;
  final String reason;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  const ReportDto({
    required this.id,
    required this.reporterId,
    required this.contentId,
    required this.contentType,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });
  factory ReportDto.fromJson(Map<String, dynamic> json) => ReportDto(
        id: json['id'] as String,
        reporterId: json['reporterId'] as String,
        contentId: json['contentId'] as String,
        contentType: json['contentType'] as String,
        reason: json['reason'] as String,
        description: json['description'] as String?,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'] as String)
            : null,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'reporterId': reporterId,
        'contentId': contentId,
        'contentType': contentType,
        'reason': reason,
        'description': description,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
      };
}