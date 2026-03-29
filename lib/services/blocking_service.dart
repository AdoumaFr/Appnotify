import '../models/app_limit.dart';
import '../models/app_usage_state.dart';

/// MVP: la logique d'overlay est gérée côté UI (route `/lock`).
/// Ce service fournit uniquement une décision "doit-on bloquer ?" pour une app.
class BlockingService {
  static bool shouldBlock({
    required AppLimit limit,
    required AppUsageState usage,
    required DateTime now,
  }) {
    if (usage.unlockedUntilMidnight) return false;

    if (usage.status == AppBlockStatus.cooldown) {
      final until = usage.cooldownUntil;
      return until == null ? true : now.isBefore(until);
    }

    return usage.status == AppBlockStatus.blocked;
  }
}

