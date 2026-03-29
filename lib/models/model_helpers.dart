import 'app_limit.dart';
import 'app_usage_state.dart';

int secondsRemaining({
  required AppLimit limit,
  required AppUsageState usage,
}) {
  final remaining = limit.dailyLimitSeconds - usage.usedSecondsToday;
  return remaining < 0 ? 0 : remaining;
}

AppBlockStatus deriveStatus({
  required AppLimit limit,
  required AppUsageState usage,
  required DateTime now,
}) {
  if (usage.unlockedUntilMidnight) return AppBlockStatus.active;

  final cooldownUntil = usage.cooldownUntil;
  if (cooldownUntil != null && now.isBefore(cooldownUntil)) {
    return AppBlockStatus.cooldown;
  }

  final remaining = secondsRemaining(limit: limit, usage: usage);
  if (remaining <= 0) return AppBlockStatus.blocked;

  final thresholds = limit.notificationThresholdsSeconds
      .where((s) => s > 0)
      .toList(growable: false)
    ..sort((a, b) => a.compareTo(b));
  if (thresholds.isEmpty) return AppBlockStatus.active;

  // Alert quand on est sous le plus grand seuil (ex: <= 10min).
  final largest = thresholds.last;
  return remaining <= largest ? AppBlockStatus.alert : AppBlockStatus.active;
}

