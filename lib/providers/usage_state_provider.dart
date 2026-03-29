import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_usage_state.dart';
import '../services/storage_service.dart';
import '../services/usage_monitor_service.dart';

final usageStateProvider =
    StateNotifierProvider<UsageStateNotifier, Map<String, AppUsageState>>((ref) {
  final notifier = UsageStateNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier..init();
});

class UsageStateNotifier extends StateNotifier<Map<String, AppUsageState>> {
  UsageStateNotifier() : super(const {});

  StreamSubscription? _sub;

  Future<void> init() async {
    await StorageService.instance.init();
    state = StorageService.instance.getAllUsageByAppId();

    UsageMonitorService.instance.setOnUpdate((data) {
      state = Map<String, AppUsageState>.unmodifiable(data);
    });
    await UsageMonitorService.instance.start();
  }

  Future<void> resetToday() => UsageMonitorService.instance.resetToday();

  Future<void> unlockUntilMidnight(String appId) async {
    final now = DateTime.now();
    final current = StorageService.instance.getUsage(appId);
    if (current == null) return;

    final next = current.copyWith(
      status: AppBlockStatus.active,
      unlockedUntilMidnight: true,
      lastUpdatedAt: now,
    );
    await StorageService.instance.upsertUsage(next);
    state = {...state, appId: next};
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

