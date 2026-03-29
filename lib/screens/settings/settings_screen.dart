import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';
import '../../providers/usage_state_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.enabled,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setEnabled(v),
                  title: const Text('Activer AppGuard'),
                  subtitle: const Text('Pause globale de la surveillance'),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Thème'),
                  subtitle: Text(settings.themeMode.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickTheme(context, ref, settings.themeMode),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Langue'),
                  subtitle: Text(settings.localeCode.toUpperCase()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickLocale(context, ref, settings.localeCode),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Reset aujourd\'hui'),
                  subtitle: const Text('Réinitialise usage + blocages pour toutes les apps'),
                  trailing: const Icon(Icons.restart_alt),
                  onTap: () async => ref.read(usageStateProvider.notifier).resetToday(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTheme(BuildContext context, WidgetRef ref, ThemeMode current) async {
    final picked = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              value: ThemeMode.system,
              groupValue: current,
              onChanged: (v) => Navigator.of(ctx).pop(v),
              title: const Text('Système'),
            ),
            RadioListTile(
              value: ThemeMode.dark,
              groupValue: current,
              onChanged: (v) => Navigator.of(ctx).pop(v),
              title: const Text('Sombre'),
            ),
            RadioListTile(
              value: ThemeMode.light,
              groupValue: current,
              onChanged: (v) => Navigator.of(ctx).pop(v),
              title: const Text('Clair'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).setThemeMode(picked);
    }
  }

  Future<void> _pickLocale(BuildContext context, WidgetRef ref, String current) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              value: 'fr',
              groupValue: current,
              onChanged: (v) => Navigator.of(ctx).pop(v),
              title: const Text('Français'),
            ),
            RadioListTile(
              value: 'en',
              groupValue: current,
              onChanged: (v) => Navigator.of(ctx).pop(v),
              title: const Text('English'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).setLocale(picked);
    }
  }
}

