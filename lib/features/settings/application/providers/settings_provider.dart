import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thot/features/settings/domain/entities/app_settings.dart';
import 'package:thot/features/settings/domain/repositories/settings_repository.dart';
import 'package:thot/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ServiceLocator.instance.apiService);
});
class SettingsState {
  final AppSettings? settings;
  final bool isLoading;
  final String? error;
  final bool isUpdating;
  const SettingsState({
    this.settings,
    this.isLoading = false,
    this.error,
    this.isUpdating = false,
  });
  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
    String? error,
    bool? isUpdating,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}
class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;
  SettingsNotifier(this._repository) : super(const SettingsState()) {
    _loadSettings();
  }
  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.getSettings();
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (settings) => state = state.copyWith(
        isLoading: false,
        settings: settings,
        error: null,
      ),
    );
  }
  Future<void> updateSettings(AppSettings settings) async {
    state = state.copyWith(isUpdating: true, error: null);
    final result = await _repository.updateSettings(settings);
    result.fold(
      (failure) => state = state.copyWith(
        isUpdating: false,
        error: failure.message,
      ),
      (_) => state = state.copyWith(
        isUpdating: false,
        settings: settings,
        error: null,
      ),
    );
  }
  Future<void> resetSettings() async {
    state = state.copyWith(isUpdating: true, error: null);
    final result = await _repository.resetSettings();
    result.fold(
      (failure) => state = state.copyWith(
        isUpdating: false,
        error: failure.message,
      ),
      (_) {
        state = state.copyWith(isUpdating: false, error: null);
        _loadSettings();
      },
    );
  }
  Future<void> exportData() async {
    state = state.copyWith(isUpdating: true, error: null);
    final result = await _repository.exportData();
    result.fold(
      (failure) => state = state.copyWith(
        isUpdating: false,
        error: failure.message,
      ),
      (_) => state = state.copyWith(
        isUpdating: false,
        error: null,
      ),
    );
  }
  Future<void> deleteAccount() async {
    state = state.copyWith(isUpdating: true, error: null);
    final result = await _repository.deleteAccount();
    result.fold(
      (failure) => state = state.copyWith(
        isUpdating: false,
        error: failure.message,
      ),
      (_) => state = state.copyWith(
        isUpdating: false,
        error: null,
      ),
    );
  }
  Future<void> refresh() async {
    await _loadSettings();
  }
  Future<void> updateTheme(String theme) async {
    if (state.settings != null) {
      final updatedSettings = state.settings!.copyWith(theme: theme);
      await updateSettings(updatedSettings);
    }
  }
  Future<void> updateLanguage(String language) async {
    if (state.settings != null) {
      final updatedSettings = state.settings!.copyWith(language: language);
      await updateSettings(updatedSettings);
    }
  }
  Future<void> updateNotificationsEnabled(bool enabled) async {
    if (state.settings != null) {
      final updatedSettings =
          state.settings!.copyWith(notificationsEnabled: enabled);
      await updateSettings(updatedSettings);
    }
  }
  Future<void> updatePrivacyMode(bool enabled) async {
    if (state.settings != null) {
      final updatedSettings = state.settings!.copyWith(privacyMode: enabled);
      await updateSettings(updatedSettings);
    }
  }
}
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});
final currentThemeProvider = Provider<String>((ref) {
  final settingsState = ref.watch(settingsProvider);
  return settingsState.settings?.theme ?? 'system';
});
final notificationsEnabledProvider = Provider<bool>((ref) {
  final settingsState = ref.watch(settingsProvider);
  return settingsState.settings?.notificationsEnabled ?? true;
});
final privacyModeProvider = Provider<bool>((ref) {
  final settingsState = ref.watch(settingsProvider);
  return settingsState.settings?.privacyMode ?? false;
});