import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';

class AppSettings {
  const AppSettings({
    required this.enabled,
    required this.themeMode,
    required this.localeCode,
  });

  final bool enabled;
  final ThemeMode themeMode;
  final String localeCode; // 'fr'|'en'

  AppSettings copyWith({
    bool? enabled,
    ThemeMode? themeMode,
    String? localeCode,
  }) {
    return AppSettings(
      enabled: enabled ?? this.enabled,
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier()..load();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier()
      : super(const AppSettings(
          enabled: true,
          themeMode: ThemeMode.dark,
          localeCode: 'fr',
        ));

  Future<void> load() async {
    await StorageService.instance.init();

    final themeStr = StorageService.instance.themeMode;
    final theme = switch (themeStr) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };

    state = AppSettings(
      enabled: StorageService.instance.appEnabled,
      themeMode: theme,
      localeCode: StorageService.instance.locale,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    await StorageService.instance.setAppEnabled(enabled);
    state = state.copyWith(enabled: enabled);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      _ => 'dark',
    };
    await StorageService.instance.setThemeMode(str);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLocale(String code) async {
    await StorageService.instance.setLocale(code);
    state = state.copyWith(localeCode: code);
  }
}

