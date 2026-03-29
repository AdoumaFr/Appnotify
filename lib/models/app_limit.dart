import 'package:hive/hive.dart';

enum AppPlatform {
  android,
  windows,
}

/// Configuration persistée d'une app surveillée.
class AppLimit {
  AppLimit({
    required this.id,
    required this.platform,
    required this.identifier,
    required this.displayName,
    required this.dailyLimitSeconds,
    required this.cooldownSeconds,
    required this.notificationsEnabled,
    required this.notificationThresholdsSeconds,
    required this.createdAt,
    this.iconPngBytes,
    this.windowsProcessNames = const [],
  });

  /// Identifiant interne stable (UUID/slug).
  final String id;

  /// Plateforme cible de cette entrée.
  final AppPlatform platform;

  /// Android: packageName. Windows: nom logique (ex: "chrome") ou exe principal.
  final String identifier;

  final String displayName;

  /// Limite journalière en secondes.
  final int dailyLimitSeconds;

  /// Cooldown après expiration (en secondes).
  final int cooldownSeconds;

  final bool notificationsEnabled;

  /// Seuils de notifications (en secondes restantes), ex: [600, 300, 60]
  final List<int> notificationThresholdsSeconds;

  /// PNG (Android via `device_apps`, optionnel).
  final List<int>? iconPngBytes;

  /// Windows: liste de process à matcher (ex: ["chrome.exe"]).
  final List<String> windowsProcessNames;

  final DateTime createdAt;

  AppLimit copyWith({
    AppPlatform? platform,
    String? identifier,
    String? displayName,
    int? dailyLimitSeconds,
    int? cooldownSeconds,
    bool? notificationsEnabled,
    List<int>? notificationThresholdsSeconds,
    List<int>? iconPngBytes,
    List<String>? windowsProcessNames,
  }) {
    return AppLimit(
      id: id,
      platform: platform ?? this.platform,
      identifier: identifier ?? this.identifier,
      displayName: displayName ?? this.displayName,
      dailyLimitSeconds: dailyLimitSeconds ?? this.dailyLimitSeconds,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationThresholdsSeconds:
          notificationThresholdsSeconds ?? this.notificationThresholdsSeconds,
      createdAt: createdAt,
      iconPngBytes: iconPngBytes ?? this.iconPngBytes,
      windowsProcessNames: windowsProcessNames ?? this.windowsProcessNames,
    );
  }

  @override
  String toString() {
    return 'AppLimit(id=$id, platform=$platform, identifier=$identifier, '
        'displayName=$displayName, dailyLimitSeconds=$dailyLimitSeconds, '
        'cooldownSeconds=$cooldownSeconds)';
  }
}

class AppPlatformAdapter extends TypeAdapter<AppPlatform> {
  @override
  final int typeId = 1;

  @override
  AppPlatform read(BinaryReader reader) {
    final value = reader.readByte();
    return switch (value) {
      0 => AppPlatform.android,
      1 => AppPlatform.windows,
      _ => AppPlatform.android,
    };
  }

  @override
  void write(BinaryWriter writer, AppPlatform obj) {
    writer.writeByte(
      switch (obj) {
        AppPlatform.android => 0,
        AppPlatform.windows => 1,
      },
    );
  }
}

class AppLimitAdapter extends TypeAdapter<AppLimit> {
  @override
  final int typeId = 10;

  @override
  AppLimit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return AppLimit(
      id: fields[0] as String,
      platform: fields[1] as AppPlatform,
      identifier: fields[2] as String,
      displayName: fields[3] as String,
      dailyLimitSeconds: fields[4] as int,
      cooldownSeconds: fields[5] as int,
      notificationsEnabled: fields[6] as bool,
      notificationThresholdsSeconds:
          (fields[7] as List).cast<int>().toList(growable: false),
      createdAt: fields[8] as DateTime,
      iconPngBytes: (fields[9] as List?)?.cast<int>(),
      windowsProcessNames:
          (fields[11] as List?)?.cast<String>().toList(growable: false) ??
              const [],
    );
  }

  @override
  void write(BinaryWriter writer, AppLimit obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.platform)
      ..writeByte(2)
      ..write(obj.identifier)
      ..writeByte(3)
      ..write(obj.displayName)
      ..writeByte(4)
      ..write(obj.dailyLimitSeconds)
      ..writeByte(5)
      ..write(obj.cooldownSeconds)
      ..writeByte(6)
      ..write(obj.notificationsEnabled)
      ..writeByte(7)
      ..write(obj.notificationThresholdsSeconds)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.iconPngBytes)
      ..writeByte(11)
      ..write(obj.windowsProcessNames);
  }
}
