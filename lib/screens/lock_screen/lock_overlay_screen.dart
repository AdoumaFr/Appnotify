import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../models/app_usage_state.dart';
import '../../providers/app_limits_provider.dart';
import '../../providers/usage_state_provider.dart';

class LockOverlayScreen extends ConsumerWidget {
  const LockOverlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // MVP: écran générique (dans une itération suivante, on passera appId en args).
    final limits = ref.watch(appLimitsProvider);
    final usage = ref.watch(usageStateProvider);

    final blocked = limits.where((l) {
      final u = usage[l.id];
      if (u == null) return false;
      return u.status == AppBlockStatus.blocked || u.status == AppBlockStatus.cooldown;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              const Icon(Icons.lock_outline, size: 56, color: AppColors.danger),
              const SizedBox(height: 16),
              const Text(
                'Accès bloqué',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                blocked.isEmpty
                    ? 'Aucune app bloquée actuellement.'
                    : 'Temps épuisé pour: ${blocked.first.displayName}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: blocked.isEmpty
                    ? const SizedBox.shrink()
                    : _CooldownPanel(appId: blocked.first.id),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CooldownPanel extends ConsumerWidget {
  const _CooldownPanel({required this.appId});
  final String appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(usageStateProvider)[appId];
    final now = DateTime.now();
    final until = usage?.cooldownUntil;
    final remaining = (until == null) ? 0 : until.difference(now).inSeconds;
    final canUnlock = remaining <= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _format(remaining),
              style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              canUnlock
                  ? 'Cooldown terminé. Tu peux débloquer.'
                  : 'Cooldown en cours avant déblocage.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.tonal(
              onPressed: canUnlock
                  ? () => ref.read(usageStateProvider.notifier).unlockUntilMidnight(appId)
                  : null,
              child: const Text('Débloquer maintenant'),
            ),
          ],
        ),
      ),
    );
  }

  String _format(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final m = s ~/ 60;
    final sec = s % 60;
    final mm = m % 60;
    final h = m ~/ 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    return '${mm.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}

