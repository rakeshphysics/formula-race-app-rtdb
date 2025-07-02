import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_fonts/google_fonts.dart';

class GlowButtonRed extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GlowButtonRed({
    Key? key,
    required this.text,
    this.onPressed,
    this.borderColor = Colors.redAccent, // 🔴 red by default
    this.borderWidth = 2.0,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor.withOpacity(isDisabled ? 0.3 : 1),
            width: borderWidth,
          ),
          boxShadow: isDisabled
              ? []
              : [
            BoxShadow(
              color: borderColor.withOpacity(0.6),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Math.tex(
            text,
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              color: isDisabled ? Colors.white30 : Colors.white,
              fontWeight: FontWeight.bold,
            ),
            mathStyle: MathStyle.text,
          ),
        ),
      ),
    );
  }
}
