// timer_service.dart
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../database_operations/settings_model.dart';

class TimerService {
  Timer? _timer;
  bool _isRunning = false;
  int _currentDuration = 0;
  late int _totalDurationSeconds;
  final Function(bool) onRunningStateChanged;
  final Function() onTick;
  Settings? settings;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  TimerService({
    required this.onRunningStateChanged,
    required this.onTick,
  }) {
    tz.initializeTimeZones();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'timer_notification_channel',
      'Timer Notifications',
      description: 'Notifications for timer completion',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    // Create the channel on Android
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize notifications and request permissions
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        // Handle notification tapped logic here
      },
    );

    // Request permissions for iOS
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  bool get isRunning => _isRunning;
  int get currentDuration => _currentDuration;
  double get progress => _totalDurationSeconds == 0
      ? 0
      : 1 - (_currentDuration / _totalDurationSeconds);

  Future<void> startTimer(int durationInMinutes) async {
    _isRunning = true;
    _totalDurationSeconds = durationInMinutes * 60;
    _currentDuration = _totalDurationSeconds;

    // Schedule notification if enabled in settings
    if (settings?.areNotificationsEnabled ?? false) {
      await _scheduleNotification(durationInMinutes);
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentDuration > 0) {
        _currentDuration--;
        onTick();
      } else {
        _onTimerComplete();
      }
    });

    onRunningStateChanged(_isRunning);
  }

  Future<void> _scheduleNotification(int durationInMinutes) async {
    const androidDetails = AndroidNotificationDetails(
      'timer_notification_channel',
      'Timer Notifications',
      channelDescription: 'Notifications for timer completion',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      0,
      'Timer Complete!',
      'Your timer for $durationInMinutes minutes has finished',
      tz.TZDateTime.now(tz.local).add(Duration(minutes: durationInMinutes)),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _onTimerComplete() async {
    if (settings?.isAlarmEnabled ?? false) {
      try {
        // Play alarm sound
        await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));

        // Vibrate device with pattern
        await HapticFeedback.heavyImpact();
        await Future.delayed(Duration(milliseconds: 200));
        await HapticFeedback.heavyImpact();
      } catch (e) {
        print('Error playing alarm: $e');
      }

      // Show notification
      if (settings?.areNotificationsEnabled ?? false) {
        await _scheduleNotification(_totalDurationSeconds ~/ 60);
      }
    }

    stopTimer();
  }

  Future<void> stopTimer() async {
    _timer?.cancel();
    _isRunning = false;
    _currentDuration = _totalDurationSeconds;

    // Cancel scheduled notification
    await _notifications.cancel(0);

    // Stop alarm if it's playing
    await _audioPlayer.stop();

    onRunningStateChanged(_isRunning);
    onTick();
  }

  void resetTimer() {
    _currentDuration = _totalDurationSeconds;
    if (_isRunning) {
      startTimer(_totalDurationSeconds ~/ 60); // Convert back to minutes
    }
    onTick();
  }

  String formatTime() {
    int minutes = _currentDuration ~/ 60;
    int seconds = _currentDuration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _audioPlayer.dispose();
  }
}
