// lib/widgets/formula_option_button.dart
// Improved polished version with uniform size + padding + rounded corners

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class FormulaOptionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;

  const FormulaOptionButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
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
            side: const BorderSide(color: Color(0xFFFFA500), width: 1),// nicely rounded corners
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: onPressed,
        child: Math.tex(
          text,
          textStyle: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.normal),
        ),
      ),
    );
  }
}
