import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6C63FF);
  static const surface = Color(0xFF1E1E2E);
  static const danger = Color(0xFFFF4C4C);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFA726);
}

class StorageKeys {
  static const appLimitsBox = 'app_limits';
  static const appUsageBox = 'app_usage_state';
  static const settingsBox = 'settings';
}

class SettingsKeys {
  static const appEnabled = 'app_enabled';
  static const themeMode = 'theme_mode'; // system|dark|light
  static const locale = 'locale'; // fr|en
}

