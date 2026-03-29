import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/app_limit.dart';
import '../models/app_usage_state.dart';
import '../models/model_helpers.dart';
import 'notification_service.dart';
import 'storage_service.dart';

typedef UsageUpdateCallback = void Function(
  Map<String, AppUsageState> usageByAppId,
);

class UsageMonitorService {
  UsageMonitorService._();

  static final UsageMonitorService instance = UsageMonitorService._();

  Timer? _tickTimer;
  Timer? _dailyResetTimer;
  UsageUpdateCallback? _onUpdate;

  bool _running = false;

  void setOnUpdate(UsageUpdateCallback cb) {
    _onUpdate = cb;
  }

  Future<void> start() async {
    if (_running) return;
    await StorageService.instance.init();
    await NotificationService.instance.init();

    _running = true;
    _scheduleDailyReset();

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!StorageService.instance.appEnabled) return;
      await _tickOnce();
    });
  }

  Future<void> stop() async {
    _tickTimer?.cancel();
    _dailyResetTimer?.cancel();
    _running = false;
  }

  Future<void> resetToday() async {
    final now = DateTime.now();
    final dayKey = AppUsageState.makeDayKey(now);
    final limits = StorageService.instance.getAllLimits();

    for (final limit in limits) {
      final current = StorageService.instance.getUsage(limit.id);
      final next = (current ??
              AppUsageState(
                appId: limit.id,
                usedSecondsToday: 0,
                status: AppBlockStatus.active,
                lastUpdatedAt: now,
              ))
          .copyWith(
        usedSecondsToday: 0,
        status: AppBlockStatus.active,
        cooldownUntil: null,
        unlockedUntilMidnight: false,
        lastNotifiedThresholdSecondsRemaining: null,
        lastUpdatedAt: now,
        dayKey: dayKey,
      );
      await StorageService.instance.upsertUsage(next);
    }

    _emitUpdate();
  }

  Future<void> _tickOnce() async {
    final now = DateTime.now();
    final dayKey = AppUsageState.makeDayKey(now);

    final limits = StorageService.instance.getAllLimits();
    final usageByAppId = StorageService.instance.getAllUsageByAppId();

    // Reset auto si on a changé de jour.
    bool dayChanged = false;
    for (final limit in limits) {
      final u = usageByAppId[limit.id];
      if (u != null && u.dayKey != null && u.dayKey != dayKey) {
        dayChanged = true;
        break;
      }
    }
    if (dayChanged) {
      await resetToday();
      return;
    }

    final activeAppIds = await _detectActiveApps(limits);

    for (final limit in limits) {
      final existing = usageByAppId[limit.id] ??
          AppUsageState(
            appId: limit.id,
            usedSecondsToday: 0,
            status: AppBlockStatus.active,
            lastUpdatedAt: now,
            dayKey: dayKey,
          );

      final updated = await _updateOne(
        limit: limit,
        state: existing,
        now: now,
        isActive: activeAppIds.contains(limit.id),
        dayKey: dayKey,
      );

      usageByAppId[limit.id] = updated;
      await StorageService.instance.upsertUsage(updated);
    }

    _emitUpdate(usageByAppId: usageByAppId);
  }

  Future<AppUsageState> _updateOne({
    required AppLimit limit,
    required AppUsageState state,
    required DateTime now,
    required bool isActive,
    required String dayKey,
  }) async {
    var used = state.usedSecondsToday;

    // Si l'app est active en "foreground" (approx Windows) on incrémente.
    if (isActive) {
      // Même pendant cooldown/bloqué: on peut ignorer l'usage (l'app est censée être bloquée).
      final derived = deriveStatus(limit: limit, usage: state, now: now);
      final shouldCount = derived == AppBlockStatus.active || derived == AppBlockStatus.alert;
      if (shouldCount) used += 1;
    }

    final base = state.copyWith(
      usedSecondsToday: used,
      lastUpdatedAt: now,
      dayKey: dayKey,
    );

    final derivedStatus = deriveStatus(limit: limit, usage: base, now: now);
    final remaining = secondsRemaining(limit: limit, usage: base);

    // Transition vers blocked -> démarre cooldown
    if (derivedStatus == AppBlockStatus.blocked &&
        (state.status == AppBlockStatus.active ||
            state.status == AppBlockStatus.alert)) {
      final cooldownUntil = now.add(Duration(seconds: limit.cooldownSeconds));
      final next = base.copyWith(
        status: AppBlockStatus.cooldown,
        cooldownUntil: cooldownUntil,
      );
      await NotificationService.instance.showBlocked(limit: limit);
      return next;
    }

    // Cooldown terminé -> reste "blocked" jusqu'à unlock manuel.
    if (state.status == AppBlockStatus.cooldown &&
        state.cooldownUntil != null &&
        !now.isBefore(state.cooldownUntil!)) {
      return base.copyWith(
        status: AppBlockStatus.blocked,
        cooldownUntil: state.cooldownUntil,
      );
    }

    // Notifications de seuil (si pas déjà notifié)
    if (limit.notificationsEnabled &&
        (derivedStatus == AppBlockStatus.alert ||
            derivedStatus == AppBlockStatus.active)) {
      final thresholds = limit.notificationThresholdsSeconds
          .where((t) => t > 0)
          .toList(growable: false)
        ..sort((a, b) => b.compareTo(a)); // check du plus grand au plus petit

      for (final t in thresholds) {
        if (remaining <= t) {
          final already = state.lastNotifiedThresholdSecondsRemaining;
          if (already == null || already > t) {
            await NotificationService.instance.showThreshold(
              limit: limit,
              secondsRemaining: remaining,
            );
            return base.copyWith(
              status: derivedStatus,
              lastNotifiedThresholdSecondsRemaining: t,
            );
          }
        }
      }
    }

    return base.copyWith(status: derivedStatus);
  }

  Future<Set<String>> _detectActiveApps(List<AppLimit> limits) async {
    final active = <String>{};

    if (!kIsWeb && Platform.isWindows) {
      final output = await _tasklistCsv();
      for (final limit in limits.where((l) => l.platform == AppPlatform.windows)) {
        final names = limit.windowsProcessNames.isNotEmpty
            ? limit.windowsProcessNames
            : _defaultWindowsProcessNames(limit.identifier);
        final hit = names.any((n) => output.contains(n.toLowerCase()));
        if (hit) active.add(limit.id);
      }
      return active;
    }

    // Android monitoring "réel" (UsageStats + Accessibility) sera ajouté ensuite.
    return active;
  }

  List<String> _defaultWindowsProcessNames(String identifier) {
    final id = identifier.trim().toLowerCase();
    if (id.endsWith('.exe')) return [id];
    return ['$id.exe'];
  }

  Future<String> _tasklistCsv() async {
    try {
      final result = await Process.run(
        'tasklist',
        ['/FO', 'CSV', '/NH'],
        runInShell: true,
      );
      final raw = (result.stdout ?? '').toString();
      // Normalize lowercase for contains()
      return raw.toLowerCase();
    } catch (_) {
      return '';
    }
  }

  void _scheduleDailyReset() {
    _dailyResetTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now);

    _dailyResetTimer = Timer(delay, () async {
      await resetToday();
      _scheduleDailyReset();
    });
  }

  void _emitUpdate({Map<String, AppUsageState>? usageByAppId}) {
    final data = usageByAppId ?? StorageService.instance.getAllUsageByAppId();
    _onUpdate?.call(data);
  }
}

