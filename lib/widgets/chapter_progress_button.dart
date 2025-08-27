// lib/widgets/chapter_progress_button.dart
import 'package:flutter/material.dart';

class ChapterProgressButton extends StatelessWidget {
  final String chapterName;
  final double percentage;
  final VoidCallback onPressed;
  final Color highlightColor;

  const ChapterProgressButton({
    super.key,
    required this.chapterName,
    required this.percentage,
    required this.onPressed,
    this.highlightColor = Colors.greenAccent, // Default to cyanAccent
  });

  Color _getFillColor(double percentage) {
    if (percentage < 40) {
      return Colors.red;
    } else if (percentage >= 40 && percentage <= 70) {
      return Colors.orangeAccent;
    } else {
      return highlightColor; // Use the provided highlightColor (defaulting to cyanAccent)
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Define responsive dimensions for the button
    // You can adjust these multipliers (e.g., 0.9 for width, 0.075 for height)
    // to fit your desired aesthetic.
    final buttonWidth = screenWidth * 0.88; // Keeping it consistent with ChapterSelectionScreen
    final buttonHeight = screenHeight * 0.075;

    final Color baseFillColor = _getFillColor(percentage);// Approximately 7.5% of screen height

    return GestureDetector( // Handles taps for the entire Container area
      onTap: onPressed,
      child: Container(
        height: buttonHeight, // Use responsive height
        width: buttonWidth, // Use responsive width
        decoration: BoxDecoration(
          color: Colors.black, // Background color for the unfilled part
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.cyanAccent, // Outer border of the button
            width: 1,
          ),
        ),
        child: Stack( // Stack allows us to layer the progress fill and the text on top
          children: [
            // The actual progress fill.
            Align( // Aligns this fill to the left within the Stack
              alignment: Alignment.centerLeft,
              child: Container(
                // Calculate width based on the button's calculated width
                width: buttonWidth * (percentage / 100),
                height: buttonHeight, // Match parent button height
                decoration: BoxDecoration(
                  color: baseFillColor.withOpacity(0.43), // Fill color with transparency
                  borderRadius: BorderRadius.circular(4), // Apply border radius to the fill
                  border: Border.all( // Optional: Border for the fill color itself
                    color: Colors.white.withOpacity(0.1), // Subtle internal border
                    width: 1.0,
                  ),
                ),
              ),
            ),
            // The chapter name text, centered on top of the fill
            Center(
              child: Padding(
                // Adjust vertical padding relative to buttonHeight for consistent text centering
                padding: EdgeInsets.symmetric(vertical: buttonHeight * 0.2, horizontal: 24),
                child: Text(
                  chapterName,
                  style:  TextStyle(
                    fontSize: screenWidth*0.041,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}