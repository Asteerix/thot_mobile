class AppConfig {
  const AppConfig._();
  static const String appName = 'ThotMedia';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Social journalism platform';
  static const String apiBaseUrl = 'https://app-b73e2919-0361-42d6-ba77-d154856cefb3.cleverapps.io/api';
  static const String apiVersion = 'v1';
  static const int apiTimeout = 30000;
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const bool bypassLogin = false;
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 100;
  static const String defaultUserAvatarPath =
      'assets/images/defaults/default_user_avatar.png';
  static const String defaultJournalistAvatarPath =
      'assets/images/defaults/default_journalist_avatar.png';
}