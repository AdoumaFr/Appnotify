import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_limit.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: android);
    await _plugin.initialize(init);
    _initialized = true;
  }

  Future<void> showThreshold({
    required AppLimit limit,
    required int secondsRemaining,
  }) async {
    if (!limit.notificationsEnabled) return;
    if (!_initialized) await init();

    final title = 'AppGuard — ${limit.displayName}';
    final body =
        'Temps restant: ${_formatRemaining(secondsRemaining)} (limite journalière)';

    if (!kIsWeb && Platform.isAndroid) {
      await _plugin.show(
        _stableId(limit, 'threshold_$secondsRemaining'),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'appguard_limits',
            'Limites d\'applications',
            channelDescription: 'Alertes de seuils avant blocage',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } else {
      // Sur Windows, le plugin peut être non disponible selon config.
      // On garde l'API prête sans casser le runtime.
      try {
        await _plugin.show(
          _stableId(limit, 'threshold_$secondsRemaining'),
          title,
          body,
          const NotificationDetails(),
        );
      } catch (_) {}
    }
  }

  Future<void> showBlocked({required AppLimit limit}) async {
    if (!limit.notificationsEnabled) return;
    if (!_initialized) await init();

    final title = 'AppGuard — ${limit.displayName}';
    const body = 'Temps écoulé: application bloquée (cooldown en cours).';

    try {
      await _plugin.show(
        _stableId(limit, 'blocked'),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'appguard_blocked',
            'Blocages',
            channelDescription: 'Notifications de blocage',
            importance: Importance.max,
            priority: Priority.max,
          ),
        ),
      );
    } catch (_) {}
  }

  int _stableId(AppLimit limit, String suffix) {
    return (limit.id.hashCode ^ suffix.hashCode) & 0x7fffffff;
  }

  String _formatRemaining(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final m = s ~/ 60;
    final sec = s % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final mm = m % 60;
      return '${h}h ${mm}m';
    }
    if (m > 0) return '${m}m ${sec}s';
    return '${sec}s';
  }
}

