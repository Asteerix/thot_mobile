import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:thot/features/app/content/shared/models/political_view.dart';
import 'package:thot/features/app/profile/models/user_profile.dart';
import 'package:thot/shared/media/utils/url_helper.dart';

class Short {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final String imageUrl;
  final UserProfile author;
  final int likes;
  final int dislikes;
  final int comments;
  final int views;
  final int duration;
  final List<String> hashtags;
  final String category;
  final PoliticalView politicalView;
  final DateTime createdAt;
  final bool isLiked;
  final bool isDisliked;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletionReason;
  final String? domain;
  Short({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.imageUrl,
    required this.author,
    this.likes = 0,
    this.dislikes = 0,
    this.comments = 0,
    this.views = 0,
    required this.duration,
    this.hashtags = const [],
    this.category = 'general',
    required this.politicalView,
    required this.createdAt,
    this.isLiked = false,
    this.isDisliked = false,
    this.isDeleted = false,
    this.deletedAt,
    this.deletionReason,
    this.domain,
  });
  factory Short.fromJson(Map<String, dynamic> json) {
    PoliticalView parsePoliticalView(String? value) {
      if (value == null) return PoliticalView.neutral;
      switch (value) {
        case 'extremelyConservative':
        case 'extremely_conservative':
          return PoliticalView.extremelyConservative;
        case 'conservative':
          return PoliticalView.conservative;
        case 'neutral':
          return PoliticalView.neutral;
        case 'progressive':
          return PoliticalView.progressive;
        case 'extremelyProgressive':
        case 'extremely_progressive':
          return PoliticalView.extremelyProgressive;
        default:
          return PoliticalView.neutral;
      }
    }

    List<String> parseHashtags(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      return [];
    }

    final authorData = json['author'] ?? json['journalist'];
    if (authorData == null) {
      throw FormatException(
          'Missing author/journalist data for short ${json['_id']}');
    }
    return Short(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description:
          json['description'] as String? ?? json['content'] as String? ?? '',
      videoUrl: json['videoUrl'] != null
          ? (UrlHelper.buildMediaUrl(json['videoUrl'].toString()) ?? '')
          : '',
      thumbnailUrl: json['thumbnailUrl'] != null
          ? (UrlHelper.buildMediaUrl(json['thumbnailUrl'].toString()) ?? '')
          : '',
      imageUrl: json['imageUrl'] != null
          ? (UrlHelper.buildMediaUrl(json['imageUrl'].toString()) ?? '')
          : '',
      author: UserProfile.fromJson(authorData as Map<String, dynamic>),
      likes: (json['likes'] is List)
          ? (json['likes'] as List).length
          : (json['likes'] as int? ?? 0),
      dislikes: (json['dislikes'] is List)
          ? (json['dislikes'] as List).length
          : (json['dislikes'] as int? ?? 0),
      comments: (json['comments'] is List)
          ? (json['comments'] as List).length
          : (json['comments'] as int? ?? 0),
      views: json['views'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
      hashtags: parseHashtags(json['hashtags']),
      category: json['category'] as String? ?? 'general',
      politicalView: parsePoliticalView(json['politicalView'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isLiked: json['isLiked'] == true,
      isDisliked: json['isDisliked'] == true,
      isDeleted: json['isDeleted'] == true,
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      deletionReason: json['deletionReason'] as String?,
      domain: json['domain'] as String?,
    );
  }
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'imageUrl': imageUrl,
        'author': author.toJson(),
        'likes': likes,
        'dislikes': dislikes,
        'comments': comments,
        'views': views,
        'duration': duration,
        'hashtags': hashtags,
        'category': category,
        'politicalView': politicalView.toString().split('.').last,
        'createdAt': createdAt.toIso8601String(),
        'isLiked': isLiked,
        'isDisliked': isDisliked,
        'isDeleted': isDeleted,
        if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
        if (deletionReason != null) 'deletionReason': deletionReason,
        if (domain != null) 'domain': domain,
      };
  Color getPoliticalViewColor() {
    switch (politicalView) {
      case PoliticalView.none:
        return AppColors.neutral;
      case PoliticalView.neutral:
        return AppColors.neutral;
      case PoliticalView.progressive:
        return AppColors.progressive;
      case PoliticalView.extremelyProgressive:
        return AppColors.extremelyProgressive;
      case PoliticalView.left:
        return AppColors.progressive;
      case PoliticalView.farLeft:
        return AppColors.extremelyProgressive;
      case PoliticalView.centerLeft:
        return AppColors.progressive;
      case PoliticalView.center:
        return AppColors.neutral;
      case PoliticalView.centerRight:
        return AppColors.conservative;
      case PoliticalView.right:
        return AppColors.conservative;
      case PoliticalView.farRight:
        return AppColors.extremelyConservative;
      case PoliticalView.conservative:
        return AppColors.conservative;
      case PoliticalView.extremelyConservative:
        return AppColors.extremelyConservative;
      case PoliticalView.nonPolitical:
        return AppColors.neutral;
    }
  }
}
