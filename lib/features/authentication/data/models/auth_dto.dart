class LoginRequestDto {
  final String email;
  final String password;
  const LoginRequestDto({
    required this.email,
    required this.password,
  });
  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
  factory LoginRequestDto.fromJson(Map<String, dynamic> json) =>
      LoginRequestDto(
        email: json['email'] as String,
        password: json['password'] as String,
      );
}
class RegisterRequestDto {
  final String email;
  final String password;
  final String name;
  const RegisterRequestDto({
    required this.email,
    required this.password,
    required this.name,
  });
  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'name': name,
      };
  factory RegisterRequestDto.fromJson(Map<String, dynamic> json) =>
      RegisterRequestDto(
        email: json['email'] as String,
        password: json['password'] as String,
        name: json['name'] as String,
      );
}
class AuthResponseDto {
  final String token;
  final String refreshToken;
  final UserDto user;
  const AuthResponseDto({
    required this.token,
    required this.refreshToken,
    required this.user,
  });
  Map<String, dynamic> toJson() => {
        'token': token,
        'refreshToken': refreshToken,
        'user': user.toJson(),
      };
  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      AuthResponseDto(
        token: json['token'] as String,
        refreshToken: json['refreshToken'] as String,
        user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
      );
}
class UserDto {
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
  final bool isAdmin;
  final bool? isJournalist;
  final int postsCount;
  final int commentsCount;
  final int reactionsCount;
  final int followersCount;
  final int followingCount;
  final String? organization;
  final String? pressCard;
  final String? journalistRole;
  final Map<String, String?>? socialLinks;
  final List<Map<String, dynamic>>? formations;
  final List<Map<String, dynamic>>? experience;
  final List<String>? specialties;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const UserDto({
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
    required this.isAdmin,
    this.isJournalist,
    this.postsCount = 0,
    this.commentsCount = 0,
    this.reactionsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.organization,
    this.pressCard,
    this.journalistRole,
    this.socialLinks,
    this.formations,
    this.experience,
    this.specialties,
    this.createdAt,
    this.updatedAt,
  });
  Map<String, dynamic> toJson() => {
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
        'isAdmin': isAdmin,
        if (isJournalist != null) 'isJournalist': isJournalist,
        'postsCount': postsCount,
        'commentsCount': commentsCount,
        'reactionsCount': reactionsCount,
        'followersCount': followersCount,
        'followingCount': followingCount,
        if (organization != null) 'organization': organization,
        if (pressCard != null) 'pressCard': pressCard,
        if (journalistRole != null) 'journalistRole': journalistRole,
        if (socialLinks != null) 'socialLinks': socialLinks,
        if (formations != null) 'formations': formations,
        if (experience != null) 'experience': experience,
        if (specialties != null) 'specialties': specialties,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
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
        isAdmin: json['isAdmin'] as bool? ?? false,
        isJournalist: json['isJournalist'] as bool?,
        postsCount: json['postsCount'] as int? ?? 0,
        commentsCount: json['commentsCount'] as int? ?? 0,
        reactionsCount: json['reactionsCount'] as int? ?? 0,
        followersCount: json['followersCount'] as int? ?? 0,
        followingCount: json['followingCount'] as int? ?? 0,
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
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
}