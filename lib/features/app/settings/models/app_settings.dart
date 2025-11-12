import 'package:freezed_annotation/freezed_annotation.dart';
part 'app_settings.freezed.dart';

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(true) bool notificationsEnabled,
    @Default(true) bool pushNotificationsEnabled,
    @Default(false) bool darkMode,
    @Default('en') String language,
    @Default(true) bool autoplayVideos,
    @Default(true) bool saveToGallery,
    @Default(false) bool offlineMode,
    Map<String, dynamic>? preferences,
  }) = _AppSettings;
}
