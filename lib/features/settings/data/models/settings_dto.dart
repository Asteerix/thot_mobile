class SettingsDto {
  final bool notificationsEnabled;
  final bool pushNotificationsEnabled;
  final bool darkMode;
  final String language;
  final bool autoplayVideos;
  final bool saveToGallery;
  final bool offlineMode;
  final Map<String, dynamic>? preferences;
  const SettingsDto({
    required this.notificationsEnabled,
    required this.pushNotificationsEnabled,
    required this.darkMode,
    required this.language,
    required this.autoplayVideos,
    required this.saveToGallery,
    required this.offlineMode,
    this.preferences,
  });
  factory SettingsDto.fromJson(Map<String, dynamic> json) {
    return SettingsDto(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      pushNotificationsEnabled:
          json['pushNotificationsEnabled'] as bool? ?? true,
      darkMode: json['darkMode'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
      autoplayVideos: json['autoplayVideos'] as bool? ?? true,
      saveToGallery: json['saveToGallery'] as bool? ?? false,
      offlineMode: json['offlineMode'] as bool? ?? false,
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'darkMode': darkMode,
      'language': language,
      'autoplayVideos': autoplayVideos,
      'saveToGallery': saveToGallery,
      'offlineMode': offlineMode,
      'preferences': preferences,
    };
  }
}