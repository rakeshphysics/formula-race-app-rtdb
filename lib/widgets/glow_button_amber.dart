import 'package:flutter/material.dart';

class GlowButtonamber extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final Color glowColor;

  const GlowButtonamber({
    Key? key,
    required this.label,
    required this.onPressed,
    this.glowColor = Colors.amber,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<GlowButtonamber> createState() => _GlowButtonamberState();
}

class _GlowButtonamberState extends State<GlowButtonamber> {
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
    final screenWidth = MediaQuery.of(context).size.width;
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
          splashColor: Colors.amberAccent.withOpacity(0.2),
          child: Container(
            width: widget.width,
            height: widget.height,
           // margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [
                  Colors.amberAccent.withOpacity(0.15),
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: Border.all(
                color: Colors.amberAccent.withOpacity(0.6),
                width: 1.3,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: screenWidth*0.044,
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
