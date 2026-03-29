import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_limit.dart';
import '../../providers/app_limits_provider.dart';
import 'app_picker_list.dart';

class AddAppScreen extends ConsumerStatefulWidget {
  const AddAppScreen({super.key});

  @override
  ConsumerState<AddAppScreen> createState() => _AddAppScreenState();
}

class _AddAppScreenState extends ConsumerState<AddAppScreen> {
  AppPlatform _platform = kIsWeb
      ? AppPlatform.android
      : (Platform.isWindows ? AppPlatform.windows : AppPlatform.android);

  String? _identifier;
  String? _displayName;
  List<int>? _iconBytes;
  List<String> _windowsProcessNames = const [];

  int _limitMinutes = 60;
  int _cooldownMinutes = 15;
  bool _notificationsEnabled = true;
  final _thresholds = <int>[10, 5, 1]; // minutes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une app')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppPickerList(
            initialPlatform: _platform,
            onPicked: (picked) {
              setState(() {
                _platform = picked.platform;
                _identifier = picked.identifier;
                _displayName = picked.displayName;
                _iconBytes = picked.iconPngBytes;
                _windowsProcessNames = picked.windowsProcessNames;
              });
            },
          ),
          const SizedBox(height: 16),
          _sectionTitle('Configuration'),
          const SizedBox(height: 10),
          _sliderTile(
            label: 'Temps limite (minutes)',
            value: _limitMinutes,
            min: 5,
            max: 240,
            onChanged: (v) => setState(() => _limitMinutes = v),
          ),
          const SizedBox(height: 10),
          _sliderTile(
            label: 'Cooldown (minutes)',
            value: _cooldownMinutes,
            min: 0,
            max: 120,
            onChanged: (v) => setState(() => _cooldownMinutes = v),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
            title: const Text('Notifications'),
            subtitle: const Text('Seuils: 10m, 5m, 1m (MVP)'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: (_identifier == null || _displayName == null)
                ? null
                : () async {
                    final id = ref.read(appLimitsProvider.notifier).newId();
                    final limit = AppLimit(
                      id: id,
                      platform: _platform,
                      identifier: _identifier!,
                      displayName: _displayName!,
                      dailyLimitSeconds: _limitMinutes * 60,
                      cooldownSeconds: _cooldownMinutes * 60,
                      notificationsEnabled: _notificationsEnabled,
                      notificationThresholdsSeconds: _thresholds.map((m) => m * 60).toList(),
                      createdAt: DateTime.now(),
                      iconPngBytes: _iconBytes,
                      windowsProcessNames: _windowsProcessNames,
                    );
                    await ref.read(appLimitsProvider.notifier).addOrUpdate(limit);
                    if (context.mounted) Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.check),
            label: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16));
  }

  Widget _sliderTile({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
                Text('$value'),
              ],
            ),
            Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: (max - min),
              onChanged: (d) => onChanged(d.round()),
            ),
          ],
        ),
      ),
    );
  }
}

