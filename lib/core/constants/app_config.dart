class AppConfig {
  const AppConfig._();
  static const String apiBaseUrl = 'https://app-b73e2919-0361-42d6-ba77-d154856cefb3.cleverapps.io/api';
  static const int apiTimeout = 30000;
  static const int defaultPageSize = 20;
  static const bool bypassLogin = false;
  static const String defaultUserAvatarPath =
      'assets/images/defaults/default_user_avatar.png';
  static const String defaultJournalistAvatarPath =
      'assets/images/defaults/default_journalist_avatar.png';
}