import 'package:json_annotation/json_annotation.dart';
import 'package:thot/features/app/content/shared/models/post_metadata.dart';
import 'package:flutter/foundation.dart';
import 'package:thot/shared/media/utils/url_helper.dart';
part 'post.g.dart';

enum PostType {
  article,
  video,
  podcast,
  short,
  question,
  live,
  poll,
  testimony,
  documentation,
  opinion
}

enum ContentStatus { draft, published, archived, hidden, deleted }

@JsonEnum(fieldRename: FieldRename.snake)
enum PoliticalOrientation {
  extremelyConservative,
  conservative,
  neutral,
  progressive,
  extremelyProgressive
}

enum PostDomain {
  politique,
  economie,
  science,
  international,
  juridique,
  philosophie,
  societe,
  psychologie,
  sport,
  technologie
}

extension PostDomainExtension on PostDomain {
  String get name {
    switch (this) {
      case PostDomain.politique:
        return 'politique';
      case PostDomain.economie:
        return 'economie';
      case PostDomain.science:
        return 'science';
      case PostDomain.international:
        return 'international';
      case PostDomain.juridique:
        return 'juridique';
      case PostDomain.philosophie:
        return 'philosophie';
      case PostDomain.societe:
        return 'societe';
      case PostDomain.psychologie:
        return 'psychologie';
      case PostDomain.sport:
        return 'sport';
      case PostDomain.technologie:
        return 'technologie';
    }
  }
}

class PoliticalVoter {
  final String userId;
  final PoliticalOrientation view;
  final DateTime votedAt;
  const PoliticalVoter({
    required this.userId,
    required this.view,
    required this.votedAt,
  });
  factory PoliticalVoter.fromJson(Map<String, dynamic> json) {
    return PoliticalVoter(
      userId: json['userId']?.toString() ?? '',
      view: PoliticalOrientationData._orientationFromJson(json['view']),
      votedAt: json['votedAt'] != null
          ? DateTime.parse(json['votedAt'])
          : DateTime.now(),
    );
  }
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'view': view.toString().split('.').last,
        'votedAt': votedAt.toIso8601String(),
      };
}

@JsonSerializable()
class PoliticalOrientationData {
  @JsonKey(fromJson: _orientationFromJson)
  final PoliticalOrientation journalistChoice;
  final Map<String, int> userVotes;
  final double finalScore;
  @JsonKey(fromJson: _orientationFromJsonNullable)
  final PoliticalOrientation? dominantView;
  @JsonKey(defaultValue: false)
  final bool hasVoted;
  @JsonKey(defaultValue: [])
  final List<PoliticalVoter> voters;
  const PoliticalOrientationData({
    required this.journalistChoice,
    required this.userVotes,
    required this.finalScore,
    this.dominantView,
    this.hasVoted = false,
    this.voters = const [],
  });
  static PoliticalOrientation _orientationFromJson(dynamic json) {
    if (json is String) {
      switch (json) {
        case 'extremelyConservative':
        case 'extremely_conservative':
          return PoliticalOrientation.extremelyConservative;
        case 'conservative':
          return PoliticalOrientation.conservative;
        case 'neutral':
          return PoliticalOrientation.neutral;
        case 'progressive':
          return PoliticalOrientation.progressive;
        case 'extremelyProgressive':
        case 'extremely_progressive':
          return PoliticalOrientation.extremelyProgressive;
        default:
          return PoliticalOrientation.neutral;
      }
    }
    return PoliticalOrientation.neutral;
  }

  static PoliticalOrientation? _orientationFromJsonNullable(dynamic json) {
    if (json == null) return null;
    return _orientationFromJson(json);
  }

  PoliticalOrientation get displayOrientation {
    return dominantView ?? journalistChoice;
  }

  factory PoliticalOrientationData.fromJson(Map<String, dynamic> json) =>
      _$PoliticalOrientationDataFromJson(json);
  Map<String, dynamic> toJson() => _$PoliticalOrientationDataToJson(this);
  PoliticalOrientationData copyWith({
    PoliticalOrientation? journalistChoice,
    Map<String, int>? userVotes,
    double? finalScore,
    PoliticalOrientation? dominantView,
    bool? hasVoted,
    List<PoliticalVoter>? voters,
  }) {
    return PoliticalOrientationData(
      journalistChoice: journalistChoice ?? this.journalistChoice,
      userVotes: userVotes ?? this.userVotes,
      finalScore: finalScore ?? this.finalScore,
      dominantView: dominantView ?? this.dominantView,
      hasVoted: hasVoted ?? this.hasVoted,
      voters: voters ?? this.voters,
    );
  }
}

@JsonSerializable()
class PostStats {
  final int views;
  @JsonKey(name: 'responses', defaultValue: 0)
  final int responses;
  @JsonKey(name: 'shares', defaultValue: 0)
  final int? shares;
  final int? readTime;
  final double completion;
  final double engagement;
  const PostStats({
    required this.views,
    required this.responses,
    this.shares,
    this.readTime,
    this.completion = 0,
    this.engagement = 0,
  });
  factory PostStats.fromJson(Map<String, dynamic> json) =>
      _$PostStatsFromJson(json);
  Map<String, dynamic> toJson() => _$PostStatsToJson(this);
}

@JsonSerializable()
class UserInteractions {
  @JsonKey(fromJson: _interactionCountFromJson)
  final int likes;
  @JsonKey(fromJson: _interactionCountFromJson)
  final int dislikes;
  @JsonKey(fromJson: _interactionCountFromJson)
  final int comments;
  @JsonKey(fromJson: _interactionCountFromJson)
  final int reports;
  @JsonKey(fromJson: _interactionCountFromJson)
  final int bookmarks;
  @JsonKey(defaultValue: false)
  final bool isLiked;
  @JsonKey(defaultValue: false)
  final bool isDisliked;
  @JsonKey(defaultValue: false, name: 'isBookmarked')
  final bool isSaved;
  static int _interactionCountFromJson(dynamic value) {
    if (value == null) return 0;
    if (value is int) {
      return value;
    }
    if (value is Map) {
      final count = value['count'];
      if (count is int) return count;
      if (count is String) return int.tryParse(count) ?? 0;
      final users = value['users'];
      if (users is List) return users.length;
    }
    if (kDebugMode) {
      print('WARNING: Unexpected interaction format');
    }
    return 0;
  }

  const UserInteractions({
    required this.likes,
    required this.dislikes,
    required this.comments,
    required this.reports,
    required this.bookmarks,
    this.isLiked = false,
    this.isDisliked = false,
    this.isSaved = false,
  });
  factory UserInteractions.fromJson(Map<String, dynamic> json) {
    return _$UserInteractionsFromJson(json);
  }
  Map<String, dynamic> toJson() => _$UserInteractionsToJson(this);
  UserInteractions copyWith({
    int? likes,
    int? dislikes,
    int? comments,
    int? reports,
    int? bookmarks,
    bool? isLiked,
    bool? isDisliked,
    bool? isSaved,
  }) {
    return UserInteractions(
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      comments: comments ?? this.comments,
      reports: reports ?? this.reports,
      bookmarks: bookmarks ?? this.bookmarks,
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

@JsonSerializable()
class JournalistProfile {
  @JsonKey(name: 'id', defaultValue: null)
  final String? id;
  final String name;
  final String? username;
  @JsonKey(fromJson: _urlFromJson)
  final String? avatarUrl;
  @JsonKey(defaultValue: [])
  final List<String> specialties;
  final String? history;
  final bool isVerified;
  final bool isFollowing;
  @JsonKey(defaultValue: 0)
  final int followersCount;
  final String? pressCard;
  const JournalistProfile({
    this.id,
    required this.name,
    this.username,
    this.avatarUrl,
    this.specialties = const [],
    this.history,
    this.isVerified = false,
    this.isFollowing = false,
    this.followersCount = 0,
    this.pressCard,
  });
  static String? _urlFromJson(dynamic value) {
    if (value == null) return null;
    final String? url = value?.toString();
    if (url == null || url.isEmpty || url.trim().isEmpty) return null;
    return url;
  }

  factory JournalistProfile.fromJson(Map<String, dynamic> json) =>
      _$JournalistProfileFromJson(json);
  Map<String, dynamic> toJson() => _$JournalistProfileToJson(this);
}

class OppositionPost {
  final String postId;
  final String title;
  final String? imageUrl;
  final String? description;
  OppositionPost({
    required this.postId,
    required this.title,
    String? imageUrl,
    this.description,
  }) : imageUrl = imageUrl != null ? UrlHelper.buildMediaUrl(imageUrl) : null;
  factory OppositionPost.fromJson(Map<String, dynamic> json) {
    print('🔥 OppositionPost.fromJson called with: $json');
    final postIdData = json['postId'];
    print('🔥 postIdData type: ${postIdData.runtimeType}, value: $postIdData');
    String extractedPostId;
    String extractedTitle;
    String? extractedImageUrl;
    if (postIdData is Map<String, dynamic>) {
      print('🔥 postIdData is Map');
      extractedPostId = postIdData['_id'] as String? ?? '';
      extractedTitle =
          postIdData['title'] as String? ?? json['title'] as String? ?? '';
      extractedImageUrl =
          postIdData['imageUrl'] as String? ?? json['imageUrl'] as String?;
    } else {
      print('🔥 postIdData is String: $postIdData');
      extractedPostId = postIdData as String? ?? '';
      extractedTitle = json['title'] as String? ?? '';
      extractedImageUrl = json['imageUrl'] as String?;
    }
    print('🔥 Final values - postId: $extractedPostId, title: $extractedTitle');
    return OppositionPost(
      postId: extractedPostId,
      title: extractedTitle,
      imageUrl: extractedImageUrl,
      description: json['description'] as String?,
    );
  }
  Map<String, dynamic> toJson() => {
        'postId': postId,
        'title': title,
        'imageUrl': imageUrl,
        'description': description,
      };
}

@JsonSerializable(explicitToJson: true)
class Post {
  @JsonKey(name: '_id', readValue: _readIdValue, fromJson: _idFromJson)
  final String id;
  final String title;
  @JsonKey(fromJson: _urlFromJson)
  final String? imageUrl;
  @JsonKey(fromJson: _urlFromJson)
  final String? thumbnailUrl;
  @JsonKey(fromJson: _urlFromJson)
  final String? videoUrl;
  @JsonKey(unknownEnumValue: PostType.article)
  final PostType type;
  @JsonKey(unknownEnumValue: PostDomain.politique)
  final PostDomain domain;
  @JsonKey(unknownEnumValue: ContentStatus.draft)
  final ContentStatus status;
  final PoliticalOrientationData politicalOrientation;
  @JsonKey(fromJson: _journalistFromJson, readValue: _readJournalistValue)
  final JournalistProfile? journalist;
  @JsonKey(fromJson: _statsFromJson)
  final PostStats stats;
  static PostStats _statsFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PostStats(views: 0, responses: 0);
    }
    return PostStats.fromJson(json);
  }

  final UserInteractions interactions;
  @JsonKey(fromJson: _dateTimeFromJson)
  final DateTime createdAt;
  static dynamic _readIdValue(Map json, String key) {
    return json['_id'] ?? json['id'];
  }

  static dynamic _readJournalistValue(Map json, String key) {
    if (json['journalist'] != null) {
      return json['journalist'];
    }
    if (json['author'] != null) {
      final author = json['author'];
      if (author is Map<String, dynamic>) {
        return {
          'id': author['_id'] ?? author['id'],
          'name': author['fullName'] ?? author['name'],
          'username': author['username'],
          'avatarUrl': author['profileImage'] ?? author['avatarUrl'],
          'verified': author['isVerified'] ?? author['verified'] ?? false,
          'isVerified': author['isVerified'] ?? author['verified'] ?? false,
          'organization': author['organization'],
          'specialties': author['specialties'] ?? [],
          'history': author['history'] ?? '',
          'isFollowing': author['isFollowing'] ?? false,
        };
      }
      return author;
    }
    return null;
  }

  static String _idFromJson(dynamic idValue) {
    String? id;
    if (idValue != null) {
      id = idValue.toString();
    }
    if (id != null) {
      id = id.trim();
      if (id.isNotEmpty && id != 'null' && id != 'undefined' && id != '0') {
        return id;
      }
    }
    if (kDebugMode) {
      print('ERROR: Post without valid ID');
    }
    return 'invalid_post_id_${DateTime.now().millisecondsSinceEpoch}';
  }

  static DateTime _dateTimeFromJson(dynamic json) {
    try {
      if (json is String) {
        return DateTime.parse(json);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  static DateTime? _dateTimeFromJsonNullable(dynamic json) {
    if (json == null) return null;
    try {
      if (json is String) {
        return DateTime.parse(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  final String content;
  @JsonKey(fromJson: _metadataFromJson)
  final PostMetadata? metadata;
  final List<String> tags;
  final List<String> hashtags;
  final List<String> sources;
  final List<Post>? relatedPosts;
  final List<OppositionPost>? opposingPosts;
  final List<OppositionPost>? opposedByPosts;
  @JsonKey(fromJson: _dateTimeFromJsonNullable)
  final DateTime? updatedAt;
  final bool isDeleted;
  @JsonKey(fromJson: _dateTimeFromJsonNullable)
  final DateTime? deletedAt;
  const Post({
    required this.id,
    required this.title,
    this.imageUrl,
    this.thumbnailUrl,
    this.videoUrl,
    required this.type,
    required this.domain,
    required this.status,
    required this.politicalOrientation,
    this.journalist,
    required this.stats,
    required this.interactions,
    required this.createdAt,
    required this.content,
    this.metadata,
    required this.tags,
    this.hashtags = const [],
    required this.sources,
    this.relatedPosts,
    this.opposingPosts,
    this.opposedByPosts,
    this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  });
  List<OppositionPost> get oppositions =>
      [...?opposingPosts, ...?opposedByPosts];
  bool get hasOppositions =>
      (opposingPosts?.isNotEmpty ?? false) ||
      (opposedByPosts?.isNotEmpty ?? false);
  bool get isLiked => interactions.isLiked;
  bool get isDisliked => interactions.isDisliked;
  bool get isSaved => interactions.isSaved;
  int get likesCount => interactions.likes;
  int get dislikesCount => interactions.dislikes;
  int get commentsCount => interactions.comments;
  String? get politicalOpinion {
    switch (politicalOrientation.dominantView ??
        politicalOrientation.journalistChoice) {
      case PoliticalOrientation.extremelyConservative:
        return 'conservateur';
      case PoliticalOrientation.conservative:
        return 'conservateur';
      case PoliticalOrientation.neutral:
        return 'neutre';
      case PoliticalOrientation.progressive:
        return 'progressiste';
      case PoliticalOrientation.extremelyProgressive:
        return 'progressiste';
    }
  }

  Post copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? thumbnailUrl,
    String? videoUrl,
    PostType? type,
    PostDomain? domain,
    ContentStatus? status,
    PoliticalOrientationData? politicalOrientation,
    JournalistProfile? journalist,
    PostStats? stats,
    UserInteractions? interactions,
    DateTime? createdAt,
    String? content,
    PostMetadata? metadata,
    List<String>? tags,
    List<String>? hashtags,
    List<String>? sources,
    List<Post>? relatedPosts,
    List<OppositionPost>? opposingPosts,
    List<OppositionPost>? opposedByPosts,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      type: type ?? this.type,
      domain: domain ?? this.domain,
      status: status ?? this.status,
      politicalOrientation: politicalOrientation ?? this.politicalOrientation,
      journalist: journalist ?? this.journalist,
      stats: stats ?? this.stats,
      interactions: interactions ?? this.interactions,
      createdAt: createdAt ?? this.createdAt,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      hashtags: hashtags ?? this.hashtags,
      sources: sources ?? this.sources,
      relatedPosts: relatedPosts ?? this.relatedPosts,
      opposingPosts: opposingPosts ?? this.opposingPosts,
      opposedByPosts: opposedByPosts ?? this.opposedByPosts,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
  static JournalistProfile? _journalistFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return JournalistProfile.fromJson(json);
  }

  static PostMetadata? _metadataFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return PostMetadata.fromJson(json);
  }

  static String? _urlFromJson(dynamic value) {
    if (value == null) return null;
    final String? url = value?.toString();
    if (url == null || url.isEmpty || url.trim().isEmpty) return null;
    return url;
  }
}
