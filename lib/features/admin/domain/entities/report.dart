import 'package:thot/features/profile/domain/entities/user_profile.dart';
class Report {
  final String id;
  final String targetType;
  final String targetId;
  final UserProfile? reportedBy;
  final String reason;
  final String? description;
  final String status;
  final UserProfile? reviewedBy;
  final DateTime? reviewedAt;
  final String? actionTaken;
  final DateTime createdAt;
  final Map<String, dynamic>? target;
  Report({
    required this.id,
    required this.targetType,
    required this.targetId,
    this.reportedBy,
    required this.reason,
    this.description,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.actionTaken,
    required this.createdAt,
    this.target,
  });
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['_id'] ?? json['id'] ?? '',
      targetType: json['targetType'] ?? '',
      targetId: json['targetId'] ?? '',
      reportedBy: json['reportedBy'] != null
          ? UserProfile.fromJson(json['reportedBy'])
          : null,
      reason: json['reason'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'pending',
      reviewedBy: json['reviewedBy'] != null
          ? UserProfile.fromJson(json['reviewedBy'])
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'])
          : null,
      actionTaken: json['actionTaken'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      target: json['target'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetType': targetType,
      'targetId': targetId,
      'reportedBy': reportedBy?.toJson(),
      'reason': reason,
      'description': description,
      'status': status,
      'reviewedBy': reviewedBy?.toJson(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'actionTaken': actionTaken,
      'createdAt': createdAt.toIso8601String(),
      'target': target,
    };
  }
}