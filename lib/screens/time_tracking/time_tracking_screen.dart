// time_tracking_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'timer_service.dart';
import '../../database_operations/db_operations.dart';
import '../../database_operations/time_entry_model.dart';
import '../../database_operations/settings_model.dart';
import '../../components/rating_button.dart';
import '../../components/custom_text_input.dart';
import '../../components/timer_dropdown.dart';

class TimeTrackerScreen extends StatefulWidget {
  const TimeTrackerScreen({Key? key}) : super(key: key);

  @override
  _TimeTrackerScreenState createState() => _TimeTrackerScreenState();
}

class _TimeTrackerScreenState extends State<TimeTrackerScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  late TimerService _timerService;

  int? selectedRating;
  int selectedDuration = 15;
  Settings? _settings;
  final DatabaseOperations _dbOps = DatabaseOperations();
  String _currentTime = "00:00";
  bool _showSubmitForm = false;

  @override
  void initState() {
    super.initState();
    _setupTimer();
    _loadSettings();
    _setupAnimation();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
            provisional: true,
          );
    } else if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  void _setupTimer() {
    _timerService = TimerService(
      onRunningStateChanged: (isRunning) {
        setState(() {
          if (isRunning) {
            _animationController.forward();
          } else if (!_showSubmitForm) {
            _animationController.reverse();
          }
        });
      },
      onTick: () {
        setState(() {
          _currentTime = _timerService.formatTime();
          if (_timerService.isCompleted && !_showSubmitForm) {
            _showSubmitForm = true;
            _animationController.forward();
          }
        });
      },
    );
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadSettings() async {
    final settings = await _dbOps.getSettings();
    setState(() {
      _settings = settings;
      selectedDuration = settings.defaultTimerDuration;
      _timerService.settings = settings;
    });
  }

  void _toggleTimer() {
    if (!_timerService.isRunning) {
      _timerService.startTimer(selectedDuration);
    } else {
      _timerService.stopTimer();
      setState(() {
        _showSubmitForm = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_textController.text.isEmpty || selectedRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final entry = TimeEntry(
        timestamp: DateTime.now(),
        description: _textController.text,
        rating: selectedRating!,
        createdAt: DateTime.now(),
      );

      await _dbOps.addTimeEntry(entry);

      // Clear form and reset state
      _textController.clear();
      setState(() {
        selectedRating = null;
        _showSubmitForm = false;
      });

      // Stop current timer and start a new one
      await _timerService.stopTimer();
      _timerService.startTimer(selectedDuration);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving entry: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_showSubmitForm) {
          // Prevent back navigation when submit form is shown
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Timer setup form
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                                0,
                                _animation.value *
                                    -MediaQuery.of(context).size.height),
                            child: Opacity(
                              opacity: 1 - _animation.value,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  DurationDropdown(
                                    selectedDuration: selectedDuration,
                                    isDisabled: _timerService.isRunning,
                                    onDurationChanged: (newValue) {
                                      setState(() {
                                        selectedDuration = newValue ?? 15;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _timerService.isRunning
                                          ? Colors.red
                                          : Colors.green,
                                      minimumSize:
                                          const Size(double.infinity, 50),
                                    ),
                                    onPressed: _toggleTimer,
                                    child: Text(_timerService.isRunning
                                        ? 'Stop'
                                        : 'Start'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Entry form
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                                0,
                                (1 - _animation.value) *
                                    MediaQuery.of(context).size.height),
                            child: Opacity(
                              opacity: _animation.value,
                              child: Column(
                                children: [
                                  Text(
                                    _currentTime,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  TextEntryBox(
                                    controller: _textController,
                                    hintText: 'What did you accomplish?',
                                    onChanged: (value) {},
                                  ),
                                  const SizedBox(height: 16),
                                  RatingSelector(
                                    onRatingSelected: (rating) {
                                      setState(() {
                                        selectedRating = rating;
                                      });
                                    },
                                    currentRating: selectedRating,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize:
                                          const Size(double.infinity, 50),
                                    ),
                                    onPressed: _handleSubmit,
                                    child: const Text('Submit'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _animationController.dispose();
    _timerService.dispose();
  }
}
