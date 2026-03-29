import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants.dart';
import '../models/app_limit.dart';
import '../models/app_usage_state.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  late final Box<AppLimit> _limitsBox;
  late final Box<AppUsageState> _usageBox;
  late final Box _settingsBox;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      final dir = await _appDataDir();
      Hive.init(dir.path);
    }

    Hive
      ..registerAdapter(AppPlatformAdapter())
      ..registerAdapter(AppBlockStatusAdapter())
      ..registerAdapter(AppLimitAdapter())
      ..registerAdapter(AppUsageStateAdapter());

    _limitsBox = await Hive.openBox<AppLimit>(StorageKeys.appLimitsBox);
    _usageBox = await Hive.openBox<AppUsageState>(StorageKeys.appUsageBox);
    _settingsBox = await Hive.openBox(StorageKeys.settingsBox);

    _initialized = true;
  }

  Future<Directory> _appDataDir() async {
    // Windows: %AppData%/AppGuard/ ; Android: app support dir.
    final base = await getApplicationSupportDirectory();
    final appDir = Directory('${base.path}${Platform.pathSeparator}AppGuard');
    if (!appDir.existsSync()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  List<AppLimit> getAllLimits() => _limitsBox.values.toList(growable: false);

  AppLimit? getLimit(String id) => _limitsBox.get(id);

  Future<void> upsertLimit(AppLimit limit) => _limitsBox.put(limit.id, limit);

  Future<void> deleteLimit(String id) async {
    await _limitsBox.delete(id);
    await _usageBox.delete(id);
  }

  AppUsageState? getUsage(String appId) => _usageBox.get(appId);

  Map<String, AppUsageState> getAllUsageByAppId() {
    return {for (final s in _usageBox.values) s.appId: s};
  }

  Future<void> upsertUsage(AppUsageState state) => _usageBox.put(state.appId, state);

  bool get appEnabled => (_settingsBox.get(SettingsKeys.appEnabled) as bool?) ?? true;

  Future<void> setAppEnabled(bool enabled) => _settingsBox.put(SettingsKeys.appEnabled, enabled);

  String get themeMode => (_settingsBox.get(SettingsKeys.themeMode) as String?) ?? 'dark';

  Future<void> setThemeMode(String mode) => _settingsBox.put(SettingsKeys.themeMode, mode);

  String get locale => (_settingsBox.get(SettingsKeys.locale) as String?) ?? 'fr';

  Future<void> setLocale(String value) => _settingsBox.put(SettingsKeys.locale, value);
}

