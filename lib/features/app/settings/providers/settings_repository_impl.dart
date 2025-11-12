import 'package:shared_preferences/shared_preferences.dart';
import 'package:thot/core/utils/either.dart';
import 'package:thot/features/app/settings/models/app_settings.dart';
import 'package:thot/features/app/settings/models/settings_failure.dart';
import 'package:thot/features/app/settings/providers/settings_repository.dart';
import 'package:thot/core/services/network/api_client.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final ApiService _apiService;
  static const String _settingsKey = 'app_settings';
  SettingsRepositoryImpl(this._apiService);
  @override
  Future<Either<SettingsFailure, AppSettings>> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        return const Right(AppSettings());
      }
      final response = await _apiService.get('/settings');
      final settings = const AppSettings();
      await _cacheSettings(settings);
      return Right(settings);
    } catch (e) {
      return const Right(AppSettings());
    }
  }

  @override
  Future<Either<SettingsFailure, void>> updateSettings(
      AppSettings settings) async {
    try {
      final data = {
        'notificationsEnabled': settings.notificationsEnabled,
        'pushNotificationsEnabled': settings.pushNotificationsEnabled,
        'darkMode': settings.darkMode,
        'language': settings.language,
        'autoplayVideos': settings.autoplayVideos,
        'saveToGallery': settings.saveToGallery,
        'offlineMode': settings.offlineMode,
      };
      await _apiService.put('/settings', data: data);
      await _cacheSettings(settings);
      return const Right(null);
    } catch (e) {
      return Left(SettingsFailureServer(e.toString()));
    }
  }

  @override
  Future<Either<SettingsFailure, void>> resetSettings() async {
    try {
      await _apiService.delete('/settings');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_settingsKey);
      return const Right(null);
    } catch (e) {
      return Left(SettingsFailureServer(e.toString()));
    }
  }

  @override
  Future<Either<SettingsFailure, void>> exportData() async {
    try {
      await _apiService.post('/settings/export');
      return const Right(null);
    } catch (e) {
      return Left(SettingsFailureServer(e.toString()));
    }
  }

  @override
  Future<Either<SettingsFailure, void>> deleteAccount() async {
    try {
      await _apiService.delete('/account');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return const Right(null);
    } catch (e) {
      return Left(SettingsFailureServer(e.toString()));
    }
  }

  @override
  Future<Either<SettingsFailure, void>> updateTheme(String theme) async {
    try {
      final settingsResult = await getSettings();
      return settingsResult.fold(
        (failure) => Left(failure),
        (currentSettings) async {
          final updatedSettings = AppSettings(
            notificationsEnabled: currentSettings.notificationsEnabled,
            pushNotificationsEnabled: currentSettings.pushNotificationsEnabled,
            darkMode: theme == 'dark',
            language: currentSettings.language,
            autoplayVideos: currentSettings.autoplayVideos,
            saveToGallery: currentSettings.saveToGallery,
            offlineMode: currentSettings.offlineMode,
            preferences: currentSettings.preferences,
          );
          return updateSettings(updatedSettings);
        },
      );
    } catch (e) {
      return Left(SettingsFailureServer(e.toString()));
    }
  }

  @override
  Future<Either<SettingsFailure, void>> updateLanguage(String language) async {
    try {
      final settingsResult = await getSettings();
      return settingsResult.fold(
        (failure) => Left(failure),
        (currentSettings) async {
          final updatedSettings = AppSettings(
            notificationsEnabled: currentSettings.notificationsEnabled,
            pushNotificationsEnabled: currentSettings.pushNotificationsEnabled,
            darkMode: currentSettings.darkMode,
            language: language,
            autoplayVideos: currentSettings.autoplayVideos,
            saveToGallery: currentSettings.saveToGallery,
            offlineMode: currentSettings.offlineMode,
            preferences: currentSettings.preferences,
          );
          return updateSettings(updatedSettings);
        },
      );
    } catch (e) {
      return Left(SettingsFailureServer(e.toString()));
    }
  }

  @override
  Future<Either<SettingsFailure, void>> updateNotificationsEnabled(
      bool enabled) async {
    try {
      final settingsResult = await getSettings();
      return settingsResult.fold(
        (failure) => Left(failure),
        (currentSettings) async {
          final updatedSettings = AppSettings(
            notificationsEnabled: enabled,
            pushNotificationsEnabled: currentSettings.pushNotificationsEnabled,
            darkMode: currentSettings.darkMode,
            language: currentSettings.language,
            autoplayVideos: currentSettings.autoplayVideos,
            saveToGallery: currentSettings.saveToGallery,
            offlineMode: currentSettings.offlineMode,
            preferences: currentSettings.preferences,
          );
          return updateSettings(updatedSettings);
        },
      );
    } catch (e) {
      return Left(SettingsFailureServer(e.toString()));
    }
  }

  @override
  Future<Either<SettingsFailure, void>> updatePrivacyMode(bool enabled) async {
    try {
      final settingsResult = await getSettings();
      return settingsResult.fold(
        (failure) => Left(failure),
        (currentSettings) async {
          final updatedPreferences = Map<String, dynamic>.from(
            currentSettings.preferences ?? {},
          );
          updatedPreferences['privacyMode'] = enabled;
          final updatedSettings = AppSettings(
            notificationsEnabled: currentSettings.notificationsEnabled,
            pushNotificationsEnabled: currentSettings.pushNotificationsEnabled,
            darkMode: currentSettings.darkMode,
            language: currentSettings.language,
            autoplayVideos: currentSettings.autoplayVideos,
            saveToGallery: currentSettings.saveToGallery,
            offlineMode: currentSettings.offlineMode,
            preferences: updatedPreferences,
          );
          return updateSettings(updatedSettings);
        },
      );
    } catch (e) {
      return Left(SettingsFailureServer(e.toString()));
    }
  }

  Future<void> _cacheSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsMap = {
        'notificationsEnabled': settings.notificationsEnabled,
        'pushNotificationsEnabled': settings.pushNotificationsEnabled,
        'darkMode': settings.darkMode,
        'language': settings.language,
        'autoplayVideos': settings.autoplayVideos,
        'saveToGallery': settings.saveToGallery,
        'offlineMode': settings.offlineMode,
        'preferences': settings.preferences,
      };
      await prefs.setString(_settingsKey, settingsMap.toString());
    } catch (e) {
      // Silently fail settings save
    }
  }
}
