import 'dart:async';
import 'dart:collection';
import 'package:thot/core/config/api_routes.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/models/short.dart';
import 'package:thot/core/services/network/api_client.dart';
import 'package:thot/core/services/logging/logger_service.dart';
import 'package:thot/core/services/connectivity/connectivity_service.dart';
enum MediaKind { post, short }
class SaveState {
  final String id;
  final MediaKind kind;
  final bool saved;
  final DateTime updatedAt;
  const SaveState({
    required this.id,
    required this.kind,
    required this.saved,
    required this.updatedAt,
  });
  @override
  int get hashCode =>
      Object.hash(id, kind, saved, updatedAt.millisecondsSinceEpoch);
  @override
  bool operator ==(Object other) =>
      other is SaveState &&
      other.id == id &&
      other.kind == kind &&
      other.saved == saved &&
      other.updatedAt.millisecondsSinceEpoch ==
          updatedAt.millisecondsSinceEpoch;
  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'saved': saved,
        'updatedAt': updatedAt.toIso8601String(),
      };
  SaveState copyWith({bool? saved}) => SaveState(
        id: id,
        kind: kind,
        saved: saved ?? this.saved,
        updatedAt: DateTime.now(),
      );
}
class MediaSaveService with ConnectivityAware {
  final ApiService _apiService;
  final _logger = LoggerService.instance;
  final Set<String> _savedPostIds = <String>{};
  final Set<String> _savedShortIds = <String>{};
  final StreamController<SaveState> _saveEventsCtrl =
      StreamController<SaveState>.broadcast();
  Stream<SaveState> get saveEvents => _saveEventsCtrl.stream;
  UnmodifiableSetView<String> get savedPostsSnapshot =>
      UnmodifiableSetView(_savedPostIds);
  UnmodifiableSetView<String> get savedShortsSnapshot =>
      UnmodifiableSetView(_savedShortIds);
  final Map<String, Future<bool>> _inFlight = <String, Future<bool>>{};
  MediaSaveService({required ApiService apiService}) : _apiService = apiService;
  Future<bool> togglePostSave(
    String postId, {
    bool optimistic = true,
  }) {
    return _toggle(
      kind: MediaKind.post,
      id: postId,
      endpoint: '${ApiRoutes.posts}/$postId/save',
      optimistic: optimistic,
    );
  }
  Future<bool> toggleShortSave(
    String shortId, {
    bool optimistic = true,
  }) {
    return _toggle(
      kind: MediaKind.short,
      id: shortId,
      endpoint: ApiRoutes.saveShort(shortId),
      optimistic: optimistic,
    );
  }
  Future<List<Post>> getSavedPosts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final url = '${ApiRoutes.userSavedPosts}?page=$page&limit=$limit';
      final response = await _apiService.get(url);
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final container = (data['data'] ?? data) as Map;
        final list = (container['posts'] as List?) ?? const [];
        for (final item in list) {
          final id = _extractId(item);
          if (id != null) _savedPostIds.add(id);
        }
        return list
            .map<Post>((json) => Post.fromJson(_asMap(json)))
            .toList(growable: false);
      }
      return const <Post>[];
    } catch (e) {
      _logger.error('Error fetching saved posts: $e');
      return const <Post>[];
    }
  }
  Future<List<Short>> getSavedShorts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final url = '${ApiRoutes.userSavedShorts}?page=$page&limit=$limit';
      final response = await _apiService.get(url);
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final container = (data['data'] ?? data) as Map;
        final list = (container['shorts'] as List?) ?? const [];
        for (final item in list) {
          final id = _extractId(item);
          if (id != null) _savedShortIds.add(id);
        }
        return list
            .map<Short>((json) => Short.fromJson(_asMap(json)))
            .toList(growable: false);
      }
      return const <Short>[];
    } catch (e) {
      _logger.error('Error fetching saved shorts: $e');
      return const <Short>[];
    }
  }
  Future<Map<String, List<dynamic>>> getAllSavedContent({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final results = await Future.wait([
        getSavedPosts(page: page, limit: limit),
        getSavedShorts(page: page, limit: limit),
      ]);
      final posts = results[0] as List<Post>;
      final shorts = results[1] as List<Short>;
      final articles = posts
          .where((p) => p.type == PostType.article)
          .toList(growable: false);
      final videos =
          posts.where((p) => p.type == PostType.video).toList(growable: false);
      final podcasts = posts
          .where((p) => p.type == PostType.podcast)
          .toList(growable: false);
      return {
        'articles': articles,
        'videos': videos,
        'podcasts': podcasts,
        'shorts': shorts,
      };
    } catch (e) {
      _logger.error('Error fetching all saved content: $e');
      return {
        'articles': const <Post>[],
        'videos': const <Post>[],
        'podcasts': const <Post>[],
        'shorts': const <Short>[],
      };
    }
  }
  bool isPostSaved(String postId) => _savedPostIds.contains(postId);
  bool isShortSaved(String shortId) => _savedShortIds.contains(shortId);
  void clearCache() {
    final now = DateTime.now();
    for (final id in _savedPostIds.toList()) {
      _saveEventsCtrl.add(SaveState(
        id: id,
        kind: MediaKind.post,
        saved: false,
        updatedAt: now,
      ));
    }
    for (final id in _savedShortIds.toList()) {
      _saveEventsCtrl.add(SaveState(
        id: id,
        kind: MediaKind.short,
        saved: false,
        updatedAt: now,
      ));
    }
    _savedPostIds.clear();
    _savedShortIds.clear();
  }
  Future<void> preloadSavedStatus() async {
    try {
      await getAllSavedContent(page: 1, limit: 50);
    } catch (e) {
      _logger.error('Error preloading saved status: $e');
    }
  }
  Map<String, dynamic> exportCache() => {
        'posts': _savedPostIds.toList(growable: false),
        'shorts': _savedShortIds.toList(growable: false),
        'exportedAt': DateTime.now().toIso8601String(),
      };
  void importCache(Map<String, dynamic> json, {bool notify = false}) {
    final posts = (json['posts'] as List?)?.cast<String>() ?? const <String>[];
    final shorts =
        (json['shorts'] as List?)?.cast<String>() ?? const <String>[];
    _savedPostIds
      ..clear()
      ..addAll(posts);
    _savedShortIds
      ..clear()
      ..addAll(shorts);
    if (notify) {
      final now = DateTime.now();
      for (final id in posts) {
        _saveEventsCtrl.add(SaveState(
          id: id,
          kind: MediaKind.post,
          saved: true,
          updatedAt: now,
        ));
      }
      for (final id in shorts) {
        _saveEventsCtrl.add(SaveState(
          id: id,
          kind: MediaKind.short,
          saved: true,
          updatedAt: now,
        ));
      }
    }
  }
  void dispose() {
    _saveEventsCtrl.close();
  }
  Future<bool> _toggle({
    required MediaKind kind,
    required String id,
    required String endpoint,
    required bool optimistic,
  }) async {
    final key = '${kind.name}:$id';
    final existing = _inFlight[key];
    if (existing != null) return existing;
    final completer = Completer<bool>();
    _inFlight[key] = completer.future;
    final wasSaved = _isSaved(kind, id);
    final optimisticSaved = !wasSaved;
    _logger.info('Toggling save status for ${kind.name}: $id');
    if (optimistic) {
      _applyLocal(kind, id, optimisticSaved, notify: true);
    }
    try {
      final response = await _apiService.post(endpoint, data: const {});
      final serverSaved =
          _parseSavedFlag(response.data, fallback: optimisticSaved);
      _applyLocal(
        kind,
        id,
        serverSaved,
        notify: !optimistic || serverSaved != optimisticSaved,
      );
      _logger.info('${kind.name} $id save status: $serverSaved');
      completer.complete(serverSaved);
      return serverSaved;
    } catch (e, st) {
      _logger.error('Error toggling ${kind.name} save: $e');
      if (optimistic) {
        _applyLocal(kind, id, wasSaved, notify: true);
      }
      completer.completeError(e, st);
      rethrow;
    } finally {
      _inFlight.remove(key);
    }
  }
  void _applyLocal(
    MediaKind kind,
    String id,
    bool saved, {
    required bool notify,
  }) {
    final set = kind == MediaKind.post ? _savedPostIds : _savedShortIds;
    if (saved) {
      set.add(id);
    } else {
      set.remove(id);
    }
    if (notify) {
      _saveEventsCtrl.add(SaveState(
        id: id,
        kind: kind,
        saved: saved,
        updatedAt: DateTime.now(),
      ));
    }
  }
  bool _isSaved(MediaKind kind, String id) => kind == MediaKind.post
      ? _savedPostIds.contains(id)
      : _savedShortIds.contains(id);
  static bool _truthy(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase().trim();
    return s == 'true' || s == '1' || s == 'yes' || s == 'y';
  }
  static String? _extractId(dynamic json) {
    final map = _asMap(json);
    final id = map['_id'] ?? map['id'] ?? map['uuid'] ?? map['slug'];
    return id?.toString();
  }
  static Map<String, dynamic> _asMap(dynamic json) {
    if (json is Map<String, dynamic>) return json;
    if (json is Map) {
      return json.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }
  bool _parseSavedFlag(dynamic data, {required bool fallback}) {
    try {
      final map = _asMap(data);
      final container = _asMap(map['data'] ?? map['result']);
      final candidate =
          container['saved'] ?? map['saved'] ?? container['isSaved'];
      if (candidate != null) return _truthy(candidate);
      if (map['success'] == true && candidate == null) return fallback;
      return fallback;
    } catch (_) {
      return fallback;
    }
  }
}