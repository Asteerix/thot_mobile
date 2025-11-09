import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;

  static List<String> _cachedRecentSearches = [];
  static bool _hasLoaded = false;

  static Future<void> _ensureLoaded() async {
    if (_hasLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_recentSearchesKey) ?? [];
      _cachedRecentSearches = stored;
      _hasLoaded = true;
      developer.log(
        'Loaded ${_cachedRecentSearches.length} recent searches',
        name: 'SearchHistoryService',
      );
    } catch (e) {
      developer.log(
        'Error loading recent searches',
        name: 'SearchHistoryService',
        error: e,
      );
      _cachedRecentSearches = [];
      _hasLoaded = true;
    }
  }

  static Future<void> addRecentSearch(String query) async {
    try {
      await _ensureLoaded();

      final trimmed = query.trim();
      if (trimmed.isEmpty) return;

      _cachedRecentSearches.remove(trimmed);
      _cachedRecentSearches.insert(0, trimmed);

      if (_cachedRecentSearches.length > _maxRecentSearches) {
        _cachedRecentSearches = _cachedRecentSearches.take(_maxRecentSearches).toList();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, _cachedRecentSearches);

      developer.log(
        'Added recent search: $trimmed',
        name: 'SearchHistoryService',
      );
    } catch (e) {
      developer.log(
        'Error saving recent search',
        name: 'SearchHistoryService',
        error: e,
      );
    }
  }

  static Future<List<String>> getRecentSearches() async {
    await _ensureLoaded();
    return List<String>.from(_cachedRecentSearches);
  }

  static Future<void> removeRecentSearch(String query) async {
    try {
      await _ensureLoaded();

      _cachedRecentSearches.remove(query);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, _cachedRecentSearches);

      developer.log(
        'Removed recent search: $query',
        name: 'SearchHistoryService',
      );
    } catch (e) {
      developer.log(
        'Error removing recent search',
        name: 'SearchHistoryService',
        error: e,
      );
    }
  }

  static Future<void> clearRecentSearches() async {
    try {
      _cachedRecentSearches.clear();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);

      developer.log(
        'Cleared all recent searches',
        name: 'SearchHistoryService',
      );
    } catch (e) {
      developer.log(
        'Error clearing recent searches',
        name: 'SearchHistoryService',
        error: e,
      );
    }
  }

  static Future<List<String>> getSuggestions(String query) async {
    await _ensureLoaded();

    if (query.isEmpty) {
      return List<String>.from(_cachedRecentSearches);
    }

    return _cachedRecentSearches
        .where((search) => search.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
