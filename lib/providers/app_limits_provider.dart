import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_limit.dart';
import '../services/storage_service.dart';

final appLimitsProvider =
    StateNotifierProvider<AppLimitsNotifier, List<AppLimit>>((ref) {
  return AppLimitsNotifier()..load();
});

class AppLimitsNotifier extends StateNotifier<List<AppLimit>> {
  AppLimitsNotifier() : super(const []);

  Future<void> load() async {
    await StorageService.instance.init();
    state = StorageService.instance.getAllLimits()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  Future<void> addOrUpdate(AppLimit limit) async {
    await StorageService.instance.upsertLimit(limit);
    await load();
  }

  Future<void> remove(String id) async {
    await StorageService.instance.deleteLimit(id);
    await load();
  }

  String newId() {
    final rnd = Random();
    final now = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final salt = (rnd.nextInt(1 << 32)).toRadixString(16);
    return '$now-$salt';
  }
}

