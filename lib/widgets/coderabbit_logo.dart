import 'package:flutter/material.dart';

/// A vector logo widget for CodeRabbit that renders as a stylized
/// rabbit made from code elements, inside an indigo gradient circle.
class CodeRabbitLogo extends StatelessWidget {
  final double size;
  const CodeRabbitLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5C6BC0), Color(0xFF1A237E)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F51B5).withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _RabbitPainter(),
      ),
    );
  }
}

class _RabbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.12; // base unit

    // --- Rabbit Body (ellipse) ---
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + r * 0.8), width: r * 2.4, height: r * 2.2),
      paint,
    );

    // --- Rabbit Head (circle) ---
    canvas.drawCircle(Offset(cx, cy - r * 0.2), r * 1.2, paint);

    // --- Left Ear ---
    final leftEarPath = Path()
      ..moveTo(cx - r * 0.6, cy - r * 1.2)
      ..quadraticBezierTo(
          cx - r * 1.2, cy - r * 3.5, cx - r * 0.5, cy - r * 4.0)
      ..quadraticBezierTo(
          cx - r * 0.1, cy - r * 4.2, cx - r * 0.1, cy - r * 3.8)
      ..quadraticBezierTo(cx - r * 0.2, cy - r * 3.0, cx, cy - r * 1.4)
      ..close();
    canvas.drawPath(leftEarPath, paint);

    // --- Right Ear ---
    final rightEarPath = Path()
      ..moveTo(cx + r * 0.6, cy - r * 1.2)
      ..quadraticBezierTo(
          cx + r * 1.2, cy - r * 3.5, cx + r * 0.5, cy - r * 4.0)
      ..quadraticBezierTo(
          cx + r * 0.1, cy - r * 4.2, cx + r * 0.1, cy - r * 3.8)
      ..quadraticBezierTo(cx + r * 0.2, cy - r * 3.0, cx, cy - r * 1.4)
      ..close();
    canvas.drawPath(rightEarPath, paint);

    // Draw code details in the body using indigo paint
    final codePaint = Paint()
      ..color = const Color(0xFF3F51B5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round;

    // `</>` symbol on the body
    // Left angle bracket `<`
    canvas.drawLine(Offset(cx - r * 1.0, cy + r * 0.6),
        Offset(cx - r * 0.55, cy + r * 0.9), codePaint);
    canvas.drawLine(Offset(cx - r * 0.55, cy + r * 0.9),
        Offset(cx - r * 1.0, cy + r * 1.2), codePaint);

    // Slash `/`
    canvas.drawLine(Offset(cx + r * 0.2, cy + r * 0.5),
        Offset(cx - r * 0.2, cy + r * 1.3), codePaint);

    // Right angle bracket `>`
    canvas.drawLine(Offset(cx + r * 0.55, cy + r * 0.6),
        Offset(cx + r * 1.0, cy + r * 0.9), codePaint);
    canvas.drawLine(Offset(cx + r * 1.0, cy + r * 0.9),
        Offset(cx + r * 0.55, cy + r * 1.2), codePaint);

    // --- Eyes ---
    final eyePaint = Paint()
      ..color = const Color(0xFF3F51B5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - r * 0.45, cy - r * 0.3), r * 0.22, eyePaint);
    canvas.drawCircle(Offset(cx + r * 0.45, cy - r * 0.3), r * 0.22, eyePaint);

    // Eye shine
    final shinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(cx - r * 0.38, cy - r * 0.38), r * 0.08, shinePaint);
    canvas.drawCircle(
        Offset(cx + r * 0.52, cy - r * 0.38), r * 0.08, shinePaint);

    // --- Nose ---
    final nosePaint = Paint()
      ..color = const Color(0xFF7986CB)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + r * 0.25), width: r * 0.4, height: r * 0.25),
      nosePaint,
    );

    // --- Mouth ---
    final mouthPath = Path()
      ..moveTo(cx - r * 0.25, cy + r * 0.45)
      ..quadraticBezierTo(cx, cy + r * 0.75, cx + r * 0.25, cy + r * 0.45);
    canvas.drawPath(mouthPath, strokePaint..color = const Color(0xFF7986CB));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
