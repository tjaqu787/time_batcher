// text_entry_box.dart
import 'package:flutter/material.dart';

class TextEntryBox extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;

  const TextEntryBox({
    Key? key,
    required this.controller,
    this.hintText = 'What did you accomplish?',
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the screen height to calculate 60%
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.6,
      width: double.infinity, // Takes full width
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: controller,
        maxLines: null, // Allows multiple lines
        expands: true, // Expands to fill the container
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          contentPadding: const EdgeInsets.all(16.0),
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}
