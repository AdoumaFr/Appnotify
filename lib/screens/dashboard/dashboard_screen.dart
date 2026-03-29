import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router.dart';
import '../../models/app_limit.dart';
import '../../models/app_usage_state.dart';
import '../../models/model_helpers.dart';
import '../../providers/app_limits_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/usage_state_provider.dart';
import 'widgets/app_limit_card.dart';
import 'widgets/stats_header.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limits = ref.watch(appLimitsProvider);
    final usageById = ref.watch(usageStateProvider);
    final settings = ref.watch(settingsProvider);

    final blockedCount = limits.where((l) {
      final u = usageById[l.id];
      if (u == null) return false;
      return u.status == AppBlockStatus.blocked || u.status == AppBlockStatus.cooldown;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AppGuard'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(Routes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: settings.enabled
            ? () => Navigator.of(context).pushNamed(Routes.addApp)
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(appLimitsProvider.notifier).load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          children: [
            StatsHeader(
              totalWatched: limits.length,
              blockedToday: blockedCount,
              enabled: settings.enabled,
            ),
            const SizedBox(height: 12),
            if (limits.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Aucune application surveillée',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Appuie sur “Ajouter” pour choisir une application et définir une limite.',
                      ),
                    ],
                  ),
                ),
              ),
            for (final limit in limits) ...[
              _buildCard(context, ref, limit, usageById[limit.id]),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    AppLimit limit,
    AppUsageState? usage,
  ) {
    final now = DateTime.now();
    final u = usage ??
        AppUsageState(
          appId: limit.id,
          usedSecondsToday: 0,
          status: AppBlockStatus.active,
          lastUpdatedAt: now,
          dayKey: AppUsageState.makeDayKey(now),
        );

    final remaining = secondsRemaining(limit: limit, usage: u);
    final pct = limit.dailyLimitSeconds == 0
        ? 0.0
        : (u.usedSecondsToday / limit.dailyLimitSeconds).clamp(0.0, 1.0);

    return AppLimitCard(
      limit: limit,
      usage: u,
      progress: pct,
      remainingSeconds: remaining,
      onDelete: () async => ref.read(appLimitsProvider.notifier).remove(limit.id),
      onUnlock: u.status == AppBlockStatus.blocked
          ? () async => ref.read(usageStateProvider.notifier).unlockUntilMidnight(limit.id)
          : null,
    );
  }
}

