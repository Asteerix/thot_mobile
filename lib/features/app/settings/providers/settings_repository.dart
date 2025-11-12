import 'package:thot/core/utils/either.dart';
import 'package:thot/features/app/settings/models/app_settings.dart';
import 'package:thot/features/app/settings/models/settings_failure.dart';

abstract class SettingsRepository {
  Future<Either<SettingsFailure, AppSettings>> getSettings();
  Future<Either<SettingsFailure, void>> updateSettings(AppSettings settings);
  Future<Either<SettingsFailure, void>> resetSettings();
  Future<Either<SettingsFailure, void>> exportData();
  Future<Either<SettingsFailure, void>> deleteAccount();
  Future<Either<SettingsFailure, void>> updateTheme(String theme);
  Future<Either<SettingsFailure, void>> updateLanguage(String language);
  Future<Either<SettingsFailure, void>> updateNotificationsEnabled(
      bool enabled);
  Future<Either<SettingsFailure, void>> updatePrivacyMode(bool enabled);
}
