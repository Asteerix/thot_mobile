import 'dart:convert';
import 'package:thot/features/media/utils/url_helper.dart';
import 'package:thot/features/posts/domain/entities/question.dart';
enum UserType { journalist, regular }
class UserPreferences {
  final List<String> topics;
  final NotificationPreferences notifications;
  final bool darkMode;
  const UserPreferences({
    this.topics = const [],
    required this.notifications,
    this.darkMode = true,
  });
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      topics: (json['topics'] as List?)?.map((e) => e.toString()).toList() ?? [],
      notifications: json['notifications'] != null
          ? NotificationPreferences.fromJson(json['notifications'])
          : const NotificationPreferences(),
      darkMode: json['darkMode'] ?? true,
    );
  }
  Map<String, dynamic> toJson() => {
        'topics': topics,
        'notifications': notifications.toJson(),
        'darkMode': darkMode,
      };
}
class NotificationPreferences {
  final bool enabled;
  final bool likes;
  final bool comments;
  final bool follows;
  final bool mentions;
  final bool posts;
  final bool polls;
  final bool sound;
  const NotificationPreferences({
    this.enabled = true,
    this.likes = true,
    this.comments = true,
    this.follows = true,
    this.mentions = true,
    this.posts = true,
    this.polls = true,
    this.sound = true,
  });
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      enabled: json['enabled'] ?? true,
      likes: json['likes'] ?? true,
      comments: json['comments'] ?? true,
      follows: json['follows'] ?? true,
      mentions: json['mentions'] ?? true,
      posts: json['posts'] ?? true,
      polls: json['polls'] ?? true,
      sound: json['sound'] ?? true,
    );
  }
  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'likes': likes,
        'comments': comments,
        'follows': follows,
        'mentions': mentions,
        'posts': posts,
        'polls': polls,
        'sound': sound,
      };
}
class UserProfile {
  final String id;
  final String username;
  final String email;
  final String? name;
  final String? bio;
  final String? location;
  final String? avatarUrl;
  final String? coverUrl;
  final UserType type;
  final String? role;
  final Map<String, String>? socialLinks;
  final bool isVerified;
  final int postsCount;
  final int commentsCount;
  final int reactionsCount;
  final int followersCount;
  final int followingCount;
  final List<String> highlightedStories;
  final bool isPrivate;
  final bool isFollowing;
  final bool isBlocked;
  final int notificationCount;
  final String? status;
  final String? banReason;
  final DateTime? bannedAt;
  final String? bannedBy;
  final DateTime? unbannedAt;
  final String? unbannedBy;
  final String? suspensionReason;
  final DateTime? suspendedAt;
  final String? suspendedBy;
  final DateTime? suspendedUntil;
  final DateTime? lastActive;
  final Map<String, String> politicalViews;
  final UserPreferences? preferences;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? journalistRole;
  final String? organization;
  final String? pressCard;
  final List<Formation>? formations;
  final List<Experience>? experience;
  final List<String>? specialties;
  final List<Question>? questions;
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.name,
    this.bio,
    this.location,
    this.avatarUrl,
    this.coverUrl,
    required this.type,
    this.role,
    this.isVerified = false,
    required this.postsCount,
    this.commentsCount = 0,
    this.reactionsCount = 0,
    required this.followersCount,
    required this.followingCount,
    this.highlightedStories = const [],
    this.isPrivate = false,
    this.isFollowing = false,
    this.isBlocked = false,
    this.notificationCount = 0,
    this.status,
    this.banReason,
    this.bannedAt,
    this.bannedBy,
    this.unbannedAt,
    this.unbannedBy,
    this.suspensionReason,
    this.suspendedAt,
    this.suspendedBy,
    this.suspendedUntil,
    this.lastActive,
    this.politicalViews = const {},
    this.preferences,
    this.createdAt,
    this.updatedAt,
    this.journalistRole,
    this.organization,
    this.pressCard,
    this.formations,
    this.experience,
    this.specialties,
    this.questions,
    this.socialLinks,
  });
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    int parseNumber(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      return [];
    }
    final typeStr = json['type']?.toString().toLowerCase();
    final UserType userType =
        typeStr == 'journalist' ? UserType.journalist : UserType.regular;
    Map<String, String>? socialLinks;
    if (json['socialLinks'] is Map) {
      socialLinks = Map<String, String>.from(json['socialLinks']);
    }
    Map<String, String> politicalViewsMap = {};
    if (json['politicalViews'] is Map) {
      (json['politicalViews'] as Map).forEach((key, value) {
        politicalViewsMap[key.toString()] = value.toString();
      });
    }
    return UserProfile(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      username: json['username']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      socialLinks: socialLinks,
      name: json['name']?.toString(),
      bio: json['bio']?.toString(),
      location: json['location']?.toString(),
      avatarUrl: json['avatarUrl'] != null
          ? UrlHelper.buildMediaUrl(json['avatarUrl'].toString())
          : null,
      coverUrl: json['coverUrl'] != null
          ? UrlHelper.buildMediaUrl(json['coverUrl'].toString())
          : null,
      type: userType,
      role: json['role']?.toString(),
      isVerified: json['isVerified'] == true,
      postsCount: parseNumber(json['postsCount']),
      commentsCount: parseNumber(json['commentsCount']),
      reactionsCount: parseNumber(json['reactionsCount']),
      followersCount: parseNumber(json['followersCount']),
      followingCount: parseNumber(json['followingCount']),
      highlightedStories: parseStringList(json['highlightedStories']),
      isPrivate: json['isPrivate'] == true,
      isFollowing: json['isFollowing'] == true,
      isBlocked: json['isBlocked'] == true,
      notificationCount: parseNumber(json['notificationCount']),
      status: json['status']?.toString(),
      banReason: json['banReason']?.toString(),
      bannedAt:
          json['bannedAt'] != null ? DateTime.parse(json['bannedAt']) : null,
      bannedBy: json['bannedBy']?.toString(),
      unbannedAt: json['unbannedAt'] != null
          ? DateTime.parse(json['unbannedAt'])
          : null,
      unbannedBy: json['unbannedBy']?.toString(),
      suspensionReason: json['suspensionReason']?.toString(),
      suspendedAt: json['suspendedAt'] != null
          ? DateTime.parse(json['suspendedAt'])
          : null,
      suspendedBy: json['suspendedBy']?.toString(),
      suspendedUntil: json['suspendedUntil'] != null
          ? DateTime.parse(json['suspendedUntil'])
          : null,
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'])
          : null,
      politicalViews: politicalViewsMap,
      preferences: json['preferences'] != null
          ? UserPreferences.fromJson(json['preferences'])
          : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      journalistRole: json['journalistRole']?.toString(),
      organization: json['organization']?.toString(),
      pressCard: json['pressCard']?.toString(),
      formations: _parseFormations(json['formations']),
      experience: _parseExperience(json['experience']),
      specialties: parseStringList(json['specialties']),
      questions: _parseQuestions(json['questions']),
    );
  }
  static List<Formation>? _parseFormations(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) {
            try {
              return Formation.fromJson(Map<String, dynamic>.from(e));
            } catch (_) {
              return null;
            }
          })
          .where((e) => e != null)
          .cast<Formation>()
          .toList();
    }
    return null;
  }
  static List<Experience>? _parseExperience(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) {
            try {
              return Experience.fromJson(Map<String, dynamic>.from(e));
            } catch (_) {
              return null;
            }
          })
          .where((e) => e != null)
          .cast<Experience>()
          .toList();
    }
    return null;
  }
  static List<Question>? _parseQuestions(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) {
            try {
              return Question.fromJson(Map<String, dynamic>.from(e));
            } catch (_) {
              return null;
            }
          })
          .where((e) => e != null)
          .cast<Question>()
          .toList();
    }
    return null;
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'bio': bio,
      'location': location,
      'avatarUrl': avatarUrl,
      'coverUrl': coverUrl,
      'type': type == UserType.journalist ? 'journalist' : 'regular',
      'role': role,
      'isVerified': isVerified,
      'postsCount': postsCount,
      'commentsCount': commentsCount,
      'reactionsCount': reactionsCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'highlightedStories': highlightedStories,
      'isPrivate': isPrivate,
      'isFollowing': isFollowing,
      'isBlocked': isBlocked,
      'notificationCount': notificationCount,
      'politicalViews': politicalViews,
      if (preferences != null) 'preferences': preferences!.toJson(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (lastActive != null) 'lastActive': lastActive!.toIso8601String(),
      if (journalistRole != null) 'journalistRole': journalistRole,
      if (organization != null) 'organization': organization,
      if (pressCard != null) 'pressCard': pressCard,
      if (formations != null)
        'formations': formations!.map((q) => q.toJson()).toList(),
      if (experience != null)
        'experience': experience!.map((e) => e.toJson()).toList(),
      if (specialties != null) 'specialties': specialties,
      if (questions != null)
        'questions': questions!.map((q) => q.toJson()).toList(),
      if (socialLinks != null) 'socialLinks': socialLinks,
      if (status != null) 'status': status,
      if (banReason != null) 'banReason': banReason,
      if (bannedAt != null) 'bannedAt': bannedAt!.toIso8601String(),
      if (bannedBy != null) 'bannedBy': bannedBy,
      if (unbannedAt != null) 'unbannedAt': unbannedAt!.toIso8601String(),
      if (unbannedBy != null) 'unbannedBy': unbannedBy,
      if (suspensionReason != null) 'suspensionReason': suspensionReason,
      if (suspendedAt != null) 'suspendedAt': suspendedAt!.toIso8601String(),
      if (suspendedBy != null) 'suspendedBy': suspendedBy,
      if (suspendedUntil != null)
        'suspendedUntil': suspendedUntil!.toIso8601String(),
    };
  }
  bool get isJournalist => type == UserType.journalist;
  bool get isBanned => status == 'banned';
  String get displayName => name ?? username;
  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    String? name,
    String? bio,
    String? location,
    String? avatarUrl,
    String? coverUrl,
    UserType? type,
    String? role,
    bool? isVerified,
    int? postsCount,
    int? commentsCount,
    int? reactionsCount,
    int? followersCount,
    int? followingCount,
    List<String>? highlightedStories,
    bool? isPrivate,
    bool? isFollowing,
    bool? isBlocked,
    int? notificationCount,
    String? status,
    String? banReason,
    DateTime? bannedAt,
    String? bannedBy,
    DateTime? unbannedAt,
    String? unbannedBy,
    String? suspensionReason,
    DateTime? suspendedAt,
    String? suspendedBy,
    DateTime? suspendedUntil,
    DateTime? lastActive,
    Map<String, String>? politicalViews,
    UserPreferences? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? journalistRole,
    String? organization,
    String? pressCard,
    List<Formation>? formations,
    List<Experience>? experience,
    List<String>? specialties,
    List<Question>? questions,
    Map<String, String>? socialLinks,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      type: type ?? this.type,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      postsCount: postsCount ?? this.postsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      highlightedStories: highlightedStories ?? this.highlightedStories,
      isPrivate: isPrivate ?? this.isPrivate,
      isFollowing: isFollowing ?? this.isFollowing,
      isBlocked: isBlocked ?? this.isBlocked,
      notificationCount: notificationCount ?? this.notificationCount,
      status: status ?? this.status,
      banReason: banReason ?? this.banReason,
      bannedAt: bannedAt ?? this.bannedAt,
      bannedBy: bannedBy ?? this.bannedBy,
      unbannedAt: unbannedAt ?? this.unbannedAt,
      unbannedBy: unbannedBy ?? this.unbannedBy,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      suspendedBy: suspendedBy ?? this.suspendedBy,
      suspendedUntil: suspendedUntil ?? this.suspendedUntil,
      lastActive: lastActive ?? this.lastActive,
      politicalViews: politicalViews ?? this.politicalViews,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      journalistRole: journalistRole ?? this.journalistRole,
      organization: organization ?? this.organization,
      pressCard: pressCard ?? this.pressCard,
      formations: formations ?? this.formations,
      experience: experience ?? this.experience,
      specialties: specialties ?? this.specialties,
      questions: questions ?? this.questions,
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }
}
class Experience {
  final String id;
  final String title;
  final String company;
  final String? location;
  final DateTime startDate;
  final DateTime? endDate;
  final bool current;
  final String? description;
  const Experience({
    required this.id,
    required this.title,
    required this.company,
    this.location,
    required this.startDate,
    this.endDate,
    this.current = false,
    this.description,
  });
  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      location: json['location']?.toString(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      current: json['current'] == true,
      description: json['description']?.toString(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'company': company,
      if (location != null) 'location': location,
      'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate?.toIso8601String(),
      'current': current,
      if (description != null) 'description': description,
    };
  }
}
class Formation {
  final String id;
  final String title;
  final String institution;
  final int year;
  final DateTime startDate;
  final DateTime? endDate;
  final bool current;
  final String? description;
  const Formation({
    required this.id,
    required this.title,
    required this.institution,
    required this.year,
    required this.startDate,
    this.endDate,
    this.current = false,
    this.description,
  });
  factory Formation.fromJson(Map<String, dynamic> json) {
    DateTime parseStartDate(dynamic value) {
      if (value != null && value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {}
      }
      final yearValue = json['year'] as int? ?? DateTime.now().year;
      return DateTime(yearValue, 1, 1);
    }

    DateTime? parseEndDate(dynamic value) {
      if (value != null && value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {}
      }
      return null;
    }

    return Formation(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      institution: json['institution']?.toString() ?? '',
      year: json['year'] as int? ?? DateTime.now().year,
      startDate: parseStartDate(json['startDate']),
      endDate: parseEndDate(json['endDate']),
      current: json['current'] == true,
      description: json['description']?.toString(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'institution': institution,
      'year': year,
      'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate?.toIso8601String(),
      'current': current,
      if (description != null) 'description': description,
    };
  }
}