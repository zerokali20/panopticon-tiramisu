import 'package:flutter/material.dart';

/// Custom painter replicating the Panopticon SVG logo:
///   outer circle (stroke) → ellipse orbit (stroke) → center dot (fill)
class LogoPainter extends CustomPainter {
  final Color color;

  const LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final strokeOuter = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final strokeOrbit = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final fillDot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Outer circle
    canvas.drawCircle(Offset(cx, cy), r - 0.6, strokeOuter);

    // Ellipse orbit (rx = r*11/13, ry = r*6/13)
    final orbitRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: (r * 11 / 13) * 2,
      height: (r * 6 / 13) * 2,
    );
    canvas.drawOval(orbitRect, strokeOrbit);

    // Center dot (radius = r*3/13)
    canvas.drawCircle(Offset(cx, cy), r * 3 / 13, fillDot);
  }

  @override
  bool shouldRepaint(LogoPainter old) => old.color != color;
}

class PanopticonLogo extends StatelessWidget {
  final double size;
  final Color color;

  const PanopticonLogo({
    super.key,
    this.size = 28,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: LogoPainter(color: color),
    );
  }
}
