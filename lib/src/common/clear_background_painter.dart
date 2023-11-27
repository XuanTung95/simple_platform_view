import 'package:flutter/widgets.dart';

/// This CustomPainter is utilized to clear the content below the platform view
class ClearBackgroundPainter extends CustomPainter {

  static final Paint _paint = Paint()
    ..blendMode = BlendMode.clear
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}