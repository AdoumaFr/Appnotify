import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../models/app_limit.dart';
import '../../../models/app_usage_state.dart';

class AppLimitCard extends StatelessWidget {
  const AppLimitCard({
    super.key,
    required this.limit,
    required this.usage,
    required this.progress,
    required this.remainingSeconds,
    required this.onDelete,
    this.onUnlock,
  });

  final AppLimit limit;
  final AppUsageState usage;
  final double progress;
  final int remainingSeconds;
  final VoidCallback onDelete;
  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = usage.status;

    final barColor = switch (status) {
      AppBlockStatus.active => AppColors.success,
      AppBlockStatus.alert => AppColors.warning,
      AppBlockStatus.blocked => AppColors.danger,
      AppBlockStatus.cooldown => AppColors.danger,
    };

    final subtitle = _subtitleFor(status, remainingSeconds, usage.cooldownUntil);
    final icon = _buildIcon(cs);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        limit.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _chip(context, _statusLabel(status)),
                const Spacer(),
                if (onUnlock != null)
                  FilledButton(
                    onPressed: onUnlock,
                    child: const Text('Débloquer'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildIcon(ColorScheme cs) {
    final bytes = limit.iconPngBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          Uint8List.fromList(bytes),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        limit.platform == AppPlatform.android
            ? Icons.android_outlined
            : Icons.desktop_windows_outlined,
        color: cs.primary,
      ),
    );
  }

  String _statusLabel(AppBlockStatus s) {
    return switch (s) {
      AppBlockStatus.active => 'Actif',
      AppBlockStatus.alert => 'Alerte',
      AppBlockStatus.blocked => 'Bloqué',
      AppBlockStatus.cooldown => 'Cooldown',
    };
  }

  String _subtitleFor(AppBlockStatus s, int remainingSeconds, DateTime? cooldownUntil) {
    final limitText = 'Limite: ${_fmt(limit.dailyLimitSeconds)}';

    return switch (s) {
      AppBlockStatus.active => '$limitText • Restant: ${_fmt(remainingSeconds)}',
      AppBlockStatus.alert => '$limitText • Restant: ${_fmt(remainingSeconds)}',
      AppBlockStatus.blocked => '$limitText • Temps épuisé',
      AppBlockStatus.cooldown => cooldownUntil == null
          ? '$limitText • Cooldown en cours'
          : '$limitText • Cooldown jusqu\'à ${_hhmm(cooldownUntil)}',
    };
  }

  String _fmt(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final m = s ~/ 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final mm = m % 60;
      return '${h}h ${mm}m';
    }
    return '${m}m';
  }

  String _hhmm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

