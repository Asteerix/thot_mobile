class AppConstants {
  static const String appName = 'ThotMedia';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Social journalism platform';
  static const String baseUrl = 'https://app-b73e2919-0361-42d6-ba77-d154856cefb3.cleverapps.io/api';
  static const String apiVersion = 'v1';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 100;
}
class ApiEndpoints {
  const ApiEndpoints._();
  static const String auth = '/auth';
  static const String posts = '/posts';
  static const String users = '/users';
  static const String comments = '/comments';
  static const String notifications = '/notifications';
  static const String media = '/media';
  static const String search = '/search';
  static const String admin = '/admin';
  static const String analytics = '/analytics';
}
class UserTypes {
  const UserTypes._();
  static const String user = 'user';
  static const String journalist = 'journalist';
  static const String admin = 'admin';
}
class PostTypes {
  const PostTypes._();
  static const String article = 'article';
  static const String video = 'video';
  static const String podcast = 'podcast';
  static const String live = 'live';
  static const String short = 'short';
  static const String question = 'question';
}
class UIConstants {
  const UIConstants._();
  static const String defaultUserAvatarPath =
      'assets/images/defaults/default_user_avatar.png';
  static const String defaultJournalistAvatarPath =
      'assets/images/defaults/default_journalist_avatar.png';
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double radiusXS = 2.0;
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;
}