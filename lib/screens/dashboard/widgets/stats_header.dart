import 'package:flutter/material.dart';

class StatsHeader extends StatelessWidget {
  const StatsHeader({
    super.key,
    required this.totalWatched,
    required this.blockedToday,
    required this.enabled,
  });

  final int totalWatched;
  final int blockedToday;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    enabled ? 'Surveillance active' : 'Surveillance en pause',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: enabled ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  enabled ? Icons.shield_outlined : Icons.pause_circle_outline,
                  color: enabled ? cs.primary : cs.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _pill(context, 'Apps surveillées', '$totalWatched'),
                _pill(context, 'Bloquées aujourd\'hui', '$blockedToday'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(width: 10),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

