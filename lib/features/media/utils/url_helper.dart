import 'package:thot/core/network/api_config.dart';
class UrlHelper {
  static String? _cachedBaseUrl;
  static Future<void> initialize() async {
    _cachedBaseUrl = await ApiConfigService.getApiBaseUrl();
    if (_cachedBaseUrl != null && _cachedBaseUrl!.endsWith('/api')) {
      _cachedBaseUrl = _cachedBaseUrl!.substring(0, _cachedBaseUrl!.length - 4);
    }
  }
  static String _getBaseUrl() {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    final currentUrl = ApiConfigService.getCurrentUrl();
    if (currentUrl != null) {
      return currentUrl.endsWith('/api')
        ? currentUrl.substring(0, currentUrl.length - 4)
        : currentUrl;
    }
    return 'http://37.59.106.113';
  }
  static String? toAbsoluteUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) {
      final baseUrl = _getBaseUrl();
      return '$baseUrl$path';
    }
    final baseUrl = _getBaseUrl();
    return '$baseUrl/$path';
  }
  static String? getProfileImageUrl(String? path) {
    return toAbsoluteUrl(path);
  }
  static String? getPostImageUrl(String? path) {
    return toAbsoluteUrl(path);
  }
  static String? getVideoUrl(String? path) {
    return toAbsoluteUrl(path);
  }
  static String? getThumbnailUrl(String? path) {
    return toAbsoluteUrl(path);
  }
  static String? getAvatarUrl(String? path) {
    return toAbsoluteUrl(path);
  }
  static String? getCoverUrl(String? path) {
    return toAbsoluteUrl(path);
  }
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }
  static String removeQueryParameters(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.replace(queryParameters: {}).toString();
    } catch (_) {
      return url;
    }
  }
  static String addQueryParameter(String url, String key, String value) {
    try {
      final uri = Uri.parse(url);
      final params = Map<String, dynamic>.from(uri.queryParameters);
      params[key] = value;
      return uri.replace(queryParameters: params).toString();
    } catch (_) {
      return url;
    }
  }
  static String? buildMediaUrl(String? path) {
    return toAbsoluteUrl(path);
  }
}