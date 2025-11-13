import 'package:flutter/foundation.dart';
import 'package:thot/core/di/service_locator.dart';

class FollowStateProvider with ChangeNotifier {
  final _followStates = <String, bool>{};
  final _processingFollows = <String>{};

  bool isFollowing(String userId) => _followStates[userId] ?? false;

  bool isProcessing(String userId) => _processingFollows.contains(userId);

  void setFollowing(String userId, bool isFollowing) {
    _followStates[userId] = isFollowing;
    notifyListeners();
  }

  Future<void> toggleFollow(String userId) async {
    if (_processingFollows.contains(userId)) return;

    final wasFollowing = _followStates[userId] ?? false;

    _processingFollows.add(userId);
    _followStates[userId] = !wasFollowing;
    notifyListeners();

    try {
      final profileRepository = ServiceLocator.instance.profileRepository;

      final result = wasFollowing
          ? await profileRepository.unfollowUser(userId)
          : await profileRepository.followUser(userId);

      result.fold(
        (failure) {
          _followStates[userId] = wasFollowing;
          notifyListeners();
          throw Exception(failure.message);
        },
        (_) {
          debugPrint('✅ Follow state updated for $userId: ${!wasFollowing}');
        },
      );
    } catch (e) {
      _followStates[userId] = wasFollowing;
      notifyListeners();
      rethrow;
    } finally {
      _processingFollows.remove(userId);
      notifyListeners();
    }
  }

  void initializeFollowState(String userId, bool isFollowing) {
    if (!_followStates.containsKey(userId)) {
      _followStates[userId] = isFollowing;
    }
  }

  void clearState() {
    _followStates.clear();
    _processingFollows.clear();
    notifyListeners();
  }
}
