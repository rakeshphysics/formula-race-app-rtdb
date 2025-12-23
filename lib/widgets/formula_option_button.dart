// lib/widgets/formula_option_button.dart
// Improved polished version with uniform size + padding + rounded corners

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class FormulaOptionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color? borderColor;

  const FormulaOptionButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.color,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    //final double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8), // spacing between buttons
      width: double.infinity, // full width button
      height: 64, // uniform height
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(
              color: borderColor ?? Colors.grey.shade700, // Use borderColor if available, otherwise default to grey
              width: 1.2,
            ),// nicely rounded corners
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: onPressed,
    child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const BouncingScrollPhysics(),
        child: Math.tex(
          text,
          textStyle: TextStyle(color: const Color(0xD9FFFFFF),fontSize: screenWidth * 0.045, fontWeight: FontWeight.normal),
        ),
    ),
      ),
    );
  }
}
