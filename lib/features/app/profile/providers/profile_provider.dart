import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thot/features/app/profile/models/user_profile.dart';
final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  return ProfileNotifier();
});
class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  ProfileNotifier() : super(const AsyncValue.loading());
  Future<void> loadProfile(String userId) async {
  }
  Future<void> updateProfile(UserProfile profile) async {
  }
}