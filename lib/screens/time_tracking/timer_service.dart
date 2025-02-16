import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../database_operations/settings_model.dart';
import 'package:flutter/foundation.dart';

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
  bool _isCompleted = false;

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
      sound: RawResourceAndroidNotificationSound('sci_fi_alarm.mp3'),
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
      requestCriticalPermission: true,
      requestProvisionalPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        // Handle notification tapped logic here
      },
    );
  }

  bool get isRunning => _isRunning;
  bool get isCompleted => _isCompleted;
  int get currentDuration => _currentDuration;
  double get progress => _totalDurationSeconds == 0
      ? 0
      : 1 - (_currentDuration / _totalDurationSeconds);

  Future<void> startTimer(int durationInMinutes) async {
    _isRunning = true;
    _isCompleted = false;
    _totalDurationSeconds = durationInMinutes * 60;
    _currentDuration = _totalDurationSeconds;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentDuration > 0) {
        _currentDuration--;
        onTick();
      } else if (!_isCompleted) {
        _onTimerComplete();
      }
    });

    onRunningStateChanged(_isRunning);
  }

  Future<void> _showCompletionNotification() async {
    var androidDetails = AndroidNotificationDetails(
      'timer_notification_channel',
      'Timer Notifications',
      channelDescription: 'Notifications for timer completion',
      importance: Importance.max,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('sci_fi_alarm'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'sci_fi_alarm.wav',
      interruptionLevel: InterruptionLevel.critical,
    );

    var notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'Timer Complete!',
      'Enter what you accomplished!',
      notificationDetails,
    );
  }

  Future<void> _onTimerComplete() async {
    _isCompleted = true;
    if (settings?.isAlarmEnabled ?? false) {
      try {
        // Play alarm sound with correct path and volume
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play(AssetSource('sounds/sci-fi-alarm.mp3'));

        // Aggressive vibration pattern
        for (int i = 0; i < 3; i++) {
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (e) {
        debugPrint('Error playing alarm: $e');
      }

      // Show notification immediately
      if (settings?.areNotificationsEnabled ?? false) {
        await _showCompletionNotification();
      }
    }
    // Don't stop timer - keep running until submission
    onTick();
  }

  Future<void> stopTimer() async {
    _timer?.cancel();
    _isRunning = false;
    _isCompleted = false;
    _currentDuration = _totalDurationSeconds;

    // Cancel notification
    await _notifications.cancel(0);

    // Stop alarm if playing
    await _audioPlayer.stop();

    onRunningStateChanged(_isRunning);
    onTick();
  }

  void resetTimer() {
    _currentDuration = _totalDurationSeconds;
    _isCompleted = false;
    if (_isRunning) {
      startTimer(_totalDurationSeconds ~/ 60);
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
