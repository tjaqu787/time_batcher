import 'package:flutter/material.dart';

class RatingSelector extends StatelessWidget {
  final Function(int) onRatingSelected;
  final int? currentRating;

  const RatingSelector({
    Key? key,
    required this.onRatingSelected,
    this.currentRating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(10, (index) {
          final rating = index + 1;
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 2.0), // Reduced padding between buttons
            child: SizedBox(
              width: 32, // Fixed width for each button
              height: 32, // Fixed height for each button
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentRating == rating
                      ? Theme.of(context).primaryColor
                      : null,
                  padding: EdgeInsets.zero, // Remove internal padding
                  minimumSize: Size.zero, // Allow button to be smaller
                  tapTargetSize: MaterialTapTargetSize
                      .shrinkWrap, // Reduce tap target size
                ),
                onPressed: () => onRatingSelected(rating),
                child: Text(
                  rating.toString(),
                  style: TextStyle(
                    fontSize: 14, // Smaller font size
                    color: currentRating == rating ? Colors.white : null,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
