import 'package:flutter/material.dart';

class GlowButtonCyan extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final Color glowColor;

  const GlowButtonCyan({
    Key? key,
    required this.label,
    required this.onPressed,
    this.glowColor = Colors.cyan,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<GlowButtonCyan> createState() => _GlowButtonCyanState();
}

class _GlowButtonCyanState extends State<GlowButtonCyan> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = 0.97;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0;
    });
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
   // final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return AnimatedScale(
      duration: const Duration(milliseconds: 100),
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          //onTap: widget.onPressed,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          borderRadius: BorderRadius.circular(4),
          splashColor: Colors.cyanAccent.withOpacity(0.2),
          child: Container(
            width: widget.width,
            height: widget.height,
           // margin: const EdgeInsets.symmetric(vertical: 10),
            padding: EdgeInsets.symmetric(vertical: screenHeight*0.004, horizontal: screenWidth*0.04),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [
                  Colors.cyanAccent.withOpacity(0.15),
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: Border.all(
                color: Colors.cyanAccent.withOpacity(0.6),
                width: 1.3,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: screenWidth * 0.044,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
