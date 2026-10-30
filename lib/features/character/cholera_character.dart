import 'package:flutter/material.dart';

/// Lightweight, replaceable Cholera rendering surface for the Android MVP.
/// Future sprite/Lottie/Rive animation can keep this widget's public API.
class CholeraCharacter extends StatelessWidget {
  const CholeraCharacter({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _CholeraPainter()),
  );
}

class _CholeraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120;
    canvas.save();
    canvas.scale(scale);
    final body = Paint()..color = const Color(0xFFFFC96C);
    final cheek = Paint()..color = const Color(0xFFEE9C82);
    final ink = Paint()
      ..color = const Color(0xFF493A35)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final silhouette = Path()
      ..moveTo(21, 95)
      ..cubicTo(11, 84, 16, 70, 21, 62)
      ..cubicTo(13, 41, 28, 18, 51, 15)
      ..cubicTo(79, 9, 101, 25, 101, 51)
      ..cubicTo(115, 66, 112, 91, 98, 101)
      ..cubicTo(80, 113, 37, 111, 21, 95)
      ..close();
    canvas.drawPath(silhouette, body);

    final shine = Paint()..color = const Color(0xFFFFD995);
    canvas.drawOval(const Rect.fromLTWH(28, 25, 24, 12), shine);
    canvas.drawCircle(
      const Offset(44, 60),
      3.6,
      ink..style = PaintingStyle.fill,
    );
    canvas.drawCircle(const Offset(76, 60), 3.6, ink);
    ink.style = PaintingStyle.fill;
    canvas.drawOval(const Rect.fromLTWH(25, 68, 18, 9), cheek);
    canvas.drawOval(const Rect.fromLTWH(77, 68, 18, 9), cheek);
    ink.style = PaintingStyle.stroke;
    canvas.drawArc(const Rect.fromLTWH(49, 63, 22, 16), .2, 2.7, false, ink);

    final leaf = Paint()..color = const Color(0xFF6C9874);
    final leafPath = Path()
      ..moveTo(59, 17)
      ..cubicTo(49, 5, 53, 0, 65, 10)
      ..cubicTo(75, 0, 84, 5, 70, 18)
      ..close();
    canvas.drawPath(leafPath, leaf);
    canvas.drawLine(
      const Offset(66, 14),
      const Offset(71, 7),
      ink..strokeWidth = 1.2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
