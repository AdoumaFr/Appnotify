import 'package:hive/hive.dart';

enum AppBlockStatus {
  active,
  alert,
  blocked,
  cooldown,
}

/// Etat runtime + persisté du jour (usage + blocage/cooldown).
class AppUsageState {
  AppUsageState({
    required this.appId,
    required this.usedSecondsToday,
    required this.status,
    required this.lastUpdatedAt,
    this.cooldownUntil,
    this.unlockedUntilMidnight = false,
    this.lastNotifiedThresholdSecondsRemaining,
    this.dayKey,
  });

  /// Référence vers `AppLimit.id`.
  final String appId;

  /// Usage cumulé du jour en secondes.
  final int usedSecondsToday;

  final AppBlockStatus status;

  /// Pour éviter de spammer: dernier seuil notifié (secondes restantes).
  final int? lastNotifiedThresholdSecondsRemaining;

  /// Cooldown en cours jusqu'à cette date.
  final DateTime? cooldownUntil;

  /// Après déblocage: on ne rebloque plus jusqu'à minuit.
  final bool unlockedUntilMidnight;

  /// Dernière mise à jour du state.
  final DateTime lastUpdatedAt;

  /// Clé du jour (ex: "2026-03-29") pour reset auto.
  final String? dayKey;

  AppUsageState copyWith({
    int? usedSecondsToday,
    AppBlockStatus? status,
    int? lastNotifiedThresholdSecondsRemaining,
    DateTime? cooldownUntil,
    bool? unlockedUntilMidnight,
    DateTime? lastUpdatedAt,
    String? dayKey,
  }) {
    return AppUsageState(
      appId: appId,
      usedSecondsToday: usedSecondsToday ?? this.usedSecondsToday,
      status: status ?? this.status,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      lastNotifiedThresholdSecondsRemaining:
          lastNotifiedThresholdSecondsRemaining ??
              this.lastNotifiedThresholdSecondsRemaining,
      cooldownUntil: cooldownUntil ?? this.cooldownUntil,
      unlockedUntilMidnight: unlockedUntilMidnight ?? this.unlockedUntilMidnight,
      dayKey: dayKey ?? this.dayKey,
    );
  }

  static String makeDayKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class AppBlockStatusAdapter extends TypeAdapter<AppBlockStatus> {
  @override
  final int typeId = 2;

  @override
  AppBlockStatus read(BinaryReader reader) {
    final value = reader.readByte();
    return switch (value) {
      0 => AppBlockStatus.active,
      1 => AppBlockStatus.alert,
      2 => AppBlockStatus.blocked,
      3 => AppBlockStatus.cooldown,
      _ => AppBlockStatus.active,
    };
  }

  @override
  void write(BinaryWriter writer, AppBlockStatus obj) {
    writer.writeByte(
      switch (obj) {
        AppBlockStatus.active => 0,
        AppBlockStatus.alert => 1,
        AppBlockStatus.blocked => 2,
        AppBlockStatus.cooldown => 3,
      },
    );
  }
}

class AppUsageStateAdapter extends TypeAdapter<AppUsageState> {
  @override
  final int typeId = 11;

  @override
  AppUsageState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return AppUsageState(
      appId: fields[0] as String,
      usedSecondsToday: fields[1] as int,
      status: fields[2] as AppBlockStatus,
      lastUpdatedAt: fields[3] as DateTime,
      cooldownUntil: fields[4] as DateTime?,
      unlockedUntilMidnight: (fields[5] as bool?) ?? false,
      lastNotifiedThresholdSecondsRemaining: fields[6] as int?,
      dayKey: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AppUsageState obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.appId)
      ..writeByte(1)
      ..write(obj.usedSecondsToday)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.lastUpdatedAt)
      ..writeByte(4)
      ..write(obj.cooldownUntil)
      ..writeByte(5)
      ..write(obj.unlockedUntilMidnight)
      ..writeByte(6)
      ..write(obj.lastNotifiedThresholdSecondsRemaining)
      ..writeByte(7)
      ..write(obj.dayKey);
  }
}

