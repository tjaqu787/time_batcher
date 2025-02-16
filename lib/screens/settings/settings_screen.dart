// settings_screen.dart
import 'package:flutter/material.dart';
import '../../database_operations/db_operations.dart';
import '../../database_operations/settings_model.dart';
import '../../components/timer_dropdown.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseOperations _dbOps = DatabaseOperations();
  Settings? _settings;
  bool _isLoading = true;
  late int selectedDuration;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _dbOps.getSettings();
    setState(() {
      _settings = settings;
      selectedDuration = settings.defaultTimerDuration;
      _isLoading = false;
    });
  }

  Future<void> _updateSettings(Settings newSettings) async {
    setState(() => _isLoading = true);
    await _dbOps.updateSettings(newSettings);
    setState(() {
      _settings = newSettings;
      _isLoading = false;
    });
  }

  void _handleDurationChange(dynamic value) {
    if (value != null) {
      final intValue = value as int;
      setState(() {
        selectedDuration = intValue;
      });

      final newSettings = _settings!.copyWith(
        defaultTimerDuration: intValue,
      );
      _updateSettings(newSettings);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _settings == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Timer Duration Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DurationDropdown(
              selectedDuration: selectedDuration,
              isDisabled: false,
              onDurationChanged: _handleDurationChange,
            ),
          ),
          const Divider(),

          // Alarm Toggle
          SwitchListTile(
            title: const Text('Alarm Sound'),
            subtitle: const Text('Play sound when timer completes'),
            value: _settings!.isAlarmEnabled,
            onChanged: (bool value) {
              final newSettings = _settings!.copyWith(
                isAlarmEnabled: value,
              );
              _updateSettings(newSettings);
            },
          ),
          const Divider(),

          // Notifications Toggle
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Show notifications when timer completes'),
            value: _settings!.areNotificationsEnabled,
            onChanged: (bool value) {
              final newSettings = _settings!.copyWith(
                areNotificationsEnabled: value,
              );
              _updateSettings(newSettings);
            },
          ),
          const Divider(),

          // Last Updated Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Last updated: ${_settings!.updatedAt.toString()}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
