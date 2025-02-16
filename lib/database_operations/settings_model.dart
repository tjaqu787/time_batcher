// settings.dart
class Settings {
  final int? id;
  final int defaultTimerDuration; // in minutes
  final bool isAlarmEnabled;
  final bool areNotificationsEnabled;
  final DateTime updatedAt;

  Settings({
    this.id,
    required this.defaultTimerDuration,
    required this.isAlarmEnabled,
    required this.areNotificationsEnabled,
    required this.updatedAt,
  });

  // Convert Settings to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'default_timer_duration': defaultTimerDuration,
      'is_alarm_enabled': isAlarmEnabled ? 1 : 0,
      'are_notifications_enabled': areNotificationsEnabled ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create Settings from Map (database row)
  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      id: map['id'],
      defaultTimerDuration: map['default_timer_duration'],
      isAlarmEnabled: map['is_alarm_enabled'] == 1,
      areNotificationsEnabled: map['are_notifications_enabled'] == 1,
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Create a copy of Settings with some fields updated
  Settings copyWith({
    int? defaultTimerDuration,
    bool? isAlarmEnabled,
    bool? areNotificationsEnabled,
  }) {
    return Settings(
      id: this.id,
      defaultTimerDuration: defaultTimerDuration ?? this.defaultTimerDuration,
      isAlarmEnabled: isAlarmEnabled ?? this.isAlarmEnabled,
      areNotificationsEnabled:
          areNotificationsEnabled ?? this.areNotificationsEnabled,
      updatedAt: DateTime.now(),
    );
  }
}
