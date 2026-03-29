import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/app_limit.dart';

class PickedApp {
  const PickedApp({
    required this.platform,
    required this.identifier,
    required this.displayName,
    this.iconPngBytes,
    this.windowsProcessNames = const [],
  });

  final AppPlatform platform;
  final String identifier;
  final String displayName;
  final List<int>? iconPngBytes;
  final List<String> windowsProcessNames;
}

class AppPickerList extends StatefulWidget {
  const AppPickerList({
    super.key,
    required this.onPicked,
    required this.initialPlatform,
  });

  final AppPlatform initialPlatform;
  final ValueChanged<PickedApp> onPicked;

  @override
  State<AppPickerList> createState() => _AppPickerListState();
}

class _AppPickerListState extends State<AppPickerList> {
  late AppPlatform _platform = widget.initialPlatform;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWindows = !kIsWeb && Platform.isWindows;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choisir une application', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (isWindows)
              SegmentedButton<AppPlatform>(
                segments: const [
                  ButtonSegment(value: AppPlatform.windows, label: Text('Windows')),
                  ButtonSegment(value: AppPlatform.android, label: Text('Android')),
                ],
                selected: {_platform},
                onSelectionChanged: (s) => setState(() => _platform = s.first),
              ),
            if (isWindows) const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Recherche (MVP)',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _buildList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    // MVP:
    // - Windows: liste simple d'exécutables populaires + "custom".
    // - Android: placeholder (listera via device_apps).
    final q = _searchCtrl.text.trim().toLowerCase();

    final items = <PickedApp>[
      if (_platform == AppPlatform.windows) ...[
        const PickedApp(
          platform: AppPlatform.windows,
          identifier: 'chrome.exe',
          displayName: 'Google Chrome',
          windowsProcessNames: ['chrome.exe'],
        ),
        const PickedApp(
          platform: AppPlatform.windows,
          identifier: 'msedge.exe',
          displayName: 'Microsoft Edge',
          windowsProcessNames: ['msedge.exe'],
        ),
        const PickedApp(
          platform: AppPlatform.windows,
          identifier: 'discord.exe',
          displayName: 'Discord',
          windowsProcessNames: ['discord.exe'],
        ),
        const PickedApp(
          platform: AppPlatform.windows,
          identifier: 'steam.exe',
          displayName: 'Steam',
          windowsProcessNames: ['steam.exe'],
        ),
      ] else ...[
        const PickedApp(
          platform: AppPlatform.android,
          identifier: 'com.example.placeholder',
          displayName: 'Android (placeholder)',
        ),
      ],
    ].where((a) {
      if (q.isEmpty) return true;
      return a.displayName.toLowerCase().contains(q) || a.identifier.toLowerCase().contains(q);
    }).toList(growable: false);

    return Column(
      children: [
        for (final a in items)
          ListTile(
            title: Text(a.displayName),
            subtitle: Text(a.identifier),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => widget.onPicked(a),
          ),
      ],
    );
  }
}

