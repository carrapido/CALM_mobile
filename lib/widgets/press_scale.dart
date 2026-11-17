import 'package:flutter/material.dart';

/// Shrinks its child while a finger is on it: the design's press feedback.
/// A [Listener] does not join the gesture arena, so the child's own tap handling is untouched.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.pressedScale = 0.97});

  final Widget child;
  final double pressedScale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 160),
        curve: const Cubic(0.23, 1, 0.32, 1),
        child: widget.child,
      ),
    );
  }

  void _setPressed(bool isPressed) => setState(() => _isPressed = isPressed);
}
