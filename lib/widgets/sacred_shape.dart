import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

class SacredShape extends StatefulWidget {
  final ShapeType type;
  final Color color;
  final double size;
  final bool animate;
  final Duration animationDuration;

  const SacredShape({
    super.key,
    this.type = ShapeType.circle,
    this.color = const Color(0xFF8B6B9E),
    this.size = 50,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 2000),
  });

  @override
  State<SacredShape> createState() => _SacredShapeState();
}

enum ShapeType {
  circle,
  triangle,
  square,
  pentagon,
  hexagon,
  spiral,
  mandala,
  flowerOfLife,
}

class _SacredShapeState extends State<SacredShape>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    _pulseAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.1),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.1, end: 1.0),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    if (widget.animate) {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: widget.animate ? _rotationAnimation.value : 0,
          child: Transform.scale(
            scale: widget.animate ? _pulseAnimation.value : 1.0,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _SacredShapePainter(
                type: widget.type,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SacredShapePainter extends CustomPainter {
  final ShapeType type;
  final Color color;

  _SacredShapePainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.8),
          color.withOpacity(0.3),
          color.withOpacity(0.1),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final fillPaint = Paint()
      ..color = color.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final innerPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    switch (type) {
      case ShapeType.circle:
        _drawSacredCircle(canvas, center, radius, paint, fillPaint, innerPaint);
        break;
      case ShapeType.triangle:
        _drawSacredTriangle(canvas, center, radius, paint, fillPaint);
        break;
      case ShapeType.square:
        _drawSacredSquare(canvas, center, radius, paint, fillPaint);
        break;
      case ShapeType.pentagon:
        _drawSacredPentagon(canvas, center, radius, paint, fillPaint);
        break;
      case ShapeType.hexagon:
        _drawSacredHexagon(canvas, center, radius, paint, fillPaint);
        break;
      case ShapeType.spiral:
        _drawSacredSpiral(canvas, center, radius, paint);
        break;
      case ShapeType.mandala:
        _drawSacredMandala(canvas, center, radius, paint, innerPaint);
        break;
      case ShapeType.flowerOfLife:
        _drawFlowerOfLife(canvas, center, radius, paint, innerPaint);
        break;
    }
  }

  void _drawSacredCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    Paint fillPaint,
    Paint innerPaint,
  ) {
    // Cercle principal
    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, paint);

    // Cercles intérieurs
    for (int i = 1; i <= 3; i++) {
      final innerRadius = radius * (0.8 - i * 0.2);
      canvas.drawCircle(center, innerRadius, innerPaint);
    }

    // Points sacrés
    for (int i = 0; i < 8; i++) {
      final angle = 2 * pi * i / 8;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawCircle(point, 3, Paint()..color = color.withOpacity(0.8));
    }
  }

  void _drawSacredTriangle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    Paint fillPaint,
  ) {
    final path = Path();

    for (int i = 0; i < 3; i++) {
      final angle = 2 * pi * i / 3 - pi / 2;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Triangle inversé intérieur
    final innerPath = Path();
    final innerRadius = radius * 0.5;

    for (int i = 0; i < 3; i++) {
      final angle = 2 * pi * i / 3 - pi / 2 + pi;
      final point = Offset(
        center.dx + innerRadius * cos(angle),
        center.dy + innerRadius * sin(angle),
      );

      if (i == 0) {
        innerPath.moveTo(point.dx, point.dy);
      } else {
        innerPath.lineTo(point.dx, point.dy);
      }
    }

    innerPath.close();
    canvas.drawPath(
      innerPath,
      Paint()
        ..color = color.withOpacity(0.1)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawSacredSquare(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    Paint fillPaint,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final roundedRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius * 0.2),
    );

    canvas.drawRRect(roundedRect, fillPaint);
    canvas.drawRRect(roundedRect, paint);

    // Croix intérieure
    canvas.drawLine(
      Offset(center.dx - radius * 0.7, center.dy),
      Offset(center.dx + radius * 0.7, center.dy),
      Paint()
        ..color = color.withOpacity(0.3)
        ..strokeWidth = 1.0,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.7),
      Offset(center.dx, center.dy + radius * 0.7),
      Paint()
        ..color = color.withOpacity(0.3)
        ..strokeWidth = 1.0,
    );
  }

  void _drawSacredPentagon(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    Paint fillPaint,
  ) {
    final path = Path();

    for (int i = 0; i < 5; i++) {
      final angle = 2 * pi * i / 5 - pi / 2;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
  }

  void _drawSacredHexagon(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    Paint fillPaint,
  ) {
    final path = Path();

    for (int i = 0; i < 6; i++) {
      final angle = 2 * pi * i / 6;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
  }

  void _drawSacredSpiral(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final path = Path();
    const double turns = 3;
    const int points = 500;

    for (int i = 0; i <= points; i++) {
      final t = i / points;
      final angle = 2 * pi * turns * t;
      final currentRadius = radius * (1 - t * 0.8);

      final point = Offset(
        center.dx + currentRadius * cos(angle),
        center.dy + currentRadius * sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawSacredMandala(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    Paint innerPaint,
  ) {
    // Cercle principal
    canvas.drawCircle(center, radius, paint);

    // Cercles concentriques
    for (int i = 1; i <= 4; i++) {
      final innerRadius = radius * (0.8 - i * 0.15);
      canvas.drawCircle(center, innerRadius, innerPaint);
    }

    // Pétales
    const int petals = 12;
    for (int i = 0; i < petals; i++) {
      final angle = 2 * pi * i / petals;
      final petalPath = Path();

      final startPoint = Offset(
        center.dx + radius * 0.3 * cos(angle - pi / petals),
        center.dy + radius * 0.3 * sin(angle - pi / petals),
      );

      final endPoint = Offset(
        center.dx + radius * 0.8 * cos(angle + pi / petals),
        center.dy + radius * 0.8 * sin(angle + pi / petals),
      );

      final controlPoint1 = Offset(
        center.dx + radius * 0.6 * cos(angle),
        center.dy + radius * 0.6 * sin(angle),
      );

      final controlPoint2 = Offset(
        center.dx + radius * 0.5 * cos(angle),
        center.dy + radius * 0.5 * sin(angle),
      );

      petalPath.moveTo(startPoint.dx, startPoint.dy);
      petalPath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        endPoint.dx,
        endPoint.dy,
      );

      canvas.drawPath(petalPath, paint);
    }
  }

  void _drawFlowerOfLife(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    Paint innerPaint,
  ) {
    const int circles = 7;
    final baseRadius = radius / 3;

    // Cercle central
    canvas.drawCircle(center, baseRadius, paint);

    // Cercles autour
    for (int i = 0; i < 6; i++) {
      final angle = 2 * pi * i / 6;
      final circleCenter = Offset(
        center.dx + baseRadius * 1.732 * cos(angle),
        center.dy + baseRadius * 1.732 * sin(angle),
      );

      canvas.drawCircle(circleCenter, baseRadius, paint);
    }

    // Cercles extérieurs
    for (int i = 0; i < 6; i++) {
      final angle = 2 * pi * i / 6 + pi / 6;
      final circleCenter = Offset(
        center.dx + baseRadius * 3 * cos(angle),
        center.dy + baseRadius * 3 * sin(angle),
      );

      canvas.drawCircle(circleCenter, baseRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
