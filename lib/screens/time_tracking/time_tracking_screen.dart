// time_tracker_screen.dart
import 'package:flutter/material.dart';
import 'timer_service.dart';
import '../../database_operations/db_operations.dart';
import '../../database_operations/time_entry_model.dart';
import '../../database_operations/settings_model.dart';
import '../../components/rating_button.dart';
import '../../components/custom_text_input.dart';
import '../../components/timer_dropdown.dart';

class TimeTrackerScreen extends StatefulWidget {
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

  @override
  void initState() {
    super.initState();
    _setupTimer();
    _loadSettings();
    _setupAnimation();
  }

  void _setupTimer() {
    _timerService = TimerService(
      onRunningStateChanged: (isRunning) {
        if (isRunning) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      },
      onTick: () {
        setState(() {
          _currentTime = _timerService.formatTime();
        });
      },
    );
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadSettings() async {
    _settings = await _dbOps.getSettings();
    setState(() {
      selectedDuration = _settings?.defaultTimerDuration ?? 30;
    });
  }

  void _toggleTimer() {
    if (!_timerService.isRunning) {
      _timerService.startTimer(selectedDuration);
    } else {
      _timerService.stopTimer();
    }
  }

  void _handleSubmit() async {
    if (_textController.text.isEmpty || selectedRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
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
      _textController.clear();
      setState(() {
        selectedRating = null;
      });

      _timerService.resetTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entry saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving entry: $e')),
      );
    }
  }

  void _onRatingSelected(int rating) {
    setState(() {
      selectedRating = rating;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                              SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _timerService.isRunning
                                      ? Colors.red
                                      : Colors.green,
                                  minimumSize: Size(double.infinity, 50),
                                ),
                                onPressed: _toggleTimer,
                                child: Text(
                                    _timerService.isRunning ? 'Stop' : 'Start'),
                              ),
                            ],
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
                                ),
                                SizedBox(height: 16),
                                TextEntryBox(
                                  controller: _textController,
                                  hintText: 'What did you accomplish?',
                                  onChanged: (value) {},
                                ),
                                SizedBox(height: 16),
                                RatingSelector(
                                  onRatingSelected: _onRatingSelected,
                                  currentRating: selectedRating,
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(double.infinity, 50),
                                  ),
                                  onPressed: _handleSubmit,
                                  child: Text('Submit'),
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
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _animationController.dispose();
    _timerService.dispose();
    super.dispose();
  }
}
