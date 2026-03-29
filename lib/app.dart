import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'providers/settings_provider.dart';
import 'screens/add_app/add_app_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/lock_screen/lock_overlay_screen.dart';
import 'screens/settings/settings_screen.dart';

class AppGuardApp extends ConsumerWidget {
  const AppGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'AppGuard',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(brightness: Brightness.light),
      darkTheme: buildTheme(brightness: Brightness.dark),
      themeMode: settings.themeMode,
      locale: Locale(settings.localeCode),
      routes: {
        Routes.dashboard: (_) => const DashboardScreen(),
        Routes.addApp: (_) => const AddAppScreen(),
        Routes.settings: (_) => const SettingsScreen(),
        Routes.lockOverlay: (_) => const LockOverlayScreen(),
      },
    );
  }
}

