// duration_dropdown.dart
import 'package:flutter/material.dart';

class DurationDropdown extends StatelessWidget {
  final int selectedDuration;
  final bool isDisabled;
  final Function(dynamic) onDurationChanged;
  final List<dynamic> durations;

  const DurationDropdown({
    Key? key,
    required this.selectedDuration,
    required this.onDurationChanged,
    this.isDisabled = false,
    this.durations = const [
      1,
      5,
      10,
      15,
      20,
      30,
      40,
      45,
      60,
      75,
      90,
      360,
      720,
      1440
    ],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: DropdownButton<dynamic>(
        value: selectedDuration,
        isExpanded: true,
        underline: Container(), // Removes the default underline
        icon: const Icon(Icons.arrow_drop_down),
        items: durations.map((duration) {
          return DropdownMenuItem<dynamic>(
            value: duration,
            child: Text(
              duration == 'daily' ? 'Daily' : '$duration min',
              style: TextStyle(
                fontSize: 16.0,
                color: isDisabled ? Colors.grey : Colors.black,
              ),
            ),
          );
        }).toList(),
        onChanged: isDisabled ? null : onDurationChanged,
        style: Theme.of(context).textTheme.bodyLarge,
        dropdownColor: Colors.white,
      ),
    );
  }
}
