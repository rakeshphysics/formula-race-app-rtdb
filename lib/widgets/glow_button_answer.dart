import 'package:flutter/material.dart';

class GlowButtonAnswer extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final Color glowColor;

  const GlowButtonAnswer({
    Key? key,
    required this.label,
    required this.onPressed,
    this.glowColor = Colors.cyan,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<GlowButtonAnswer> createState() => _GlowButtonAnswerState();
}

class _GlowButtonAnswerState extends State<GlowButtonAnswer> {
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
    return AnimatedScale(
      duration: const Duration(milliseconds: 100),
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        clipBehavior: Clip.hardEdge, // important to confine ripple
        child: InkWell(
          onTap: widget.onPressed,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          borderRadius: BorderRadius.circular(4),
          splashColor: widget.glowColor.withOpacity(0.2),
          child: Container(
            width: widget.width,
            height: widget.height,
            //margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: (widget.glowColor == Colors.green || widget.glowColor == Colors.red)
                  ? widget.glowColor.withOpacity(0.85)
                  : Colors.grey[900],
              gradient: (widget.glowColor == Colors.green || widget.glowColor == Colors.red)
                  ? null
                  : LinearGradient(
                colors: [
                  widget.glowColor.withOpacity(0.3),
                  widget.glowColor.withOpacity(0.15),
                  widget.glowColor.withOpacity(0.01),
                ],
                stops: const [0.0, 0.4, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: Border.all(
                color: widget.glowColor.withOpacity(0.6),
                width: 1.3,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
          )
    ),
      ),
    );
  }
}
