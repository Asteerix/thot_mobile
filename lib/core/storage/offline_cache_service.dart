import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
class OfflineCacheService {
  static OfflineCacheService? _instance;
  late SharedPreferences _prefs;
  OfflineCacheService._();
  static Future<OfflineCacheService> getInstance() async {
    if (_instance == null) {
      _instance = OfflineCacheService._();
      await _instance!._init();
    }
    return _instance!;
  }
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  Future<void> cacheData(String key, dynamic data) async {
    await _prefs.setString(key, jsonEncode(data));
  }
  dynamic getCachedData(String key) {
    final data = _prefs.getString(key);
    return data != null ? jsonDecode(data) : null;
  }
  Future<void> clearCache() async {
    await _prefs.clear();
  }
  Future<void> cachePosts(List<dynamic> posts) async {
    await cacheData('cached_posts', posts);
  }
  Future<List<dynamic>> getCachedPosts() async {
    final data = getCachedData('cached_posts');
    return data != null ? List<dynamic>.from(data) : [];
  }
}