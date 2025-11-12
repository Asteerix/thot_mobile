class ProfileDto {
  final String id;
  final String email;
  final String name;
  final String? username;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? location;
  final String? role;
  final bool isVerified;
  final bool isJournalist;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int commentsCount;
  final int reactionsCount;
  final bool isFollowing;
  final String? organization;
  final String? pressCard;
  final String? journalistRole;
  final Map<String, String?>? socialLinks;
  final List<Map<String, dynamic>>? formations;
  final List<Map<String, dynamic>>? experience;
  final List<String>? specialties;
  final DateTime? createdAt;
  const ProfileDto({
    required this.id,
    required this.email,
    required this.name,
    this.username,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.location,
    this.role,
    required this.isVerified,
    this.isJournalist = false,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    this.commentsCount = 0,
    this.reactionsCount = 0,
    required this.isFollowing,
    this.organization,
    this.pressCard,
    this.journalistRole,
    this.socialLinks,
    this.formations,
    this.experience,
    this.specialties,
    this.createdAt,
  });
  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    final followersCount = json['followersCount'] as int? ??
        json['stats']?['followersCount'] as int? ?? 0;
    final followingCount = json['followingCount'] as int? ??
        json['stats']?['followingCount'] as int? ?? 0;
    final postsCount = json['postsCount'] as int? ??
        json['stats']?['postsCount'] as int? ?? 0;
    final commentsCount = json['commentsCount'] as int? ??
        json['stats']?['commentsCount'] as int? ?? 0;
    final reactionsCount = json['reactionsCount'] as int? ??
        json['stats']?['reactionsCount'] as int? ?? 0;
    return ProfileDto(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      role: json['role'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      isJournalist: json['isJournalist'] as bool? ?? false,
      followersCount: followersCount,
      followingCount: followingCount,
      postsCount: postsCount,
      commentsCount: commentsCount,
      reactionsCount: reactionsCount,
      isFollowing: json['isFollowing'] as bool? ?? false,
      organization: json['organization'] as String?,
      pressCard: json['pressCard'] as String?,
      journalistRole: json['journalistRole'] as String?,
      socialLinks: json['socialLinks'] != null
          ? Map<String, String?>.from(json['socialLinks'] as Map)
          : null,
      formations: json['formations'] != null
          ? List<Map<String, dynamic>>.from(json['formations'] as List)
          : null,
      experience: json['experience'] != null
          ? List<Map<String, dynamic>>.from(json['experience'] as List)
          : null,
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'] as List)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      if (username != null) 'username': username,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (bio != null) 'bio': bio,
      if (location != null) 'location': location,
      if (role != null) 'role': role,
      'isVerified': isVerified,
      'isJournalist': isJournalist,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'commentsCount': commentsCount,
      'reactionsCount': reactionsCount,
      'isFollowing': isFollowing,
      if (organization != null) 'organization': organization,
      if (pressCard != null) 'pressCard': pressCard,
      if (journalistRole != null) 'journalistRole': journalistRole,
      if (socialLinks != null) 'socialLinks': socialLinks,
      if (formations != null) 'formations': formations,
      if (experience != null) 'experience': experience,
      if (specialties != null) 'specialties': specialties,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}