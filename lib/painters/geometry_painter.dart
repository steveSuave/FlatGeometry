import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/geometry_object.dart';
import '../models/point.dart';
import '../models/line.dart';
import '../models/circle.dart';

class GeometryPainter extends CustomPainter {
  final List<GeometryObject> objects;
  final Offset panOffset;
  final double zoomScale;

  GeometryPainter(this.objects, this.panOffset, this.zoomScale);

  @override
  void paint(Canvas canvas, Size size) {
    // Add responsive calculations
    final minDimension = math.min(size.width, size.height);
    final pointRadius = minDimension * 0.005;
    final strokeWidth = minDimension * 0.003;

    final pointPaint =
        Paint()
          ..color = Colors.blueGrey
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.fill;

    final linePaint =
        Paint()
          ..color = Colors.blueGrey
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final circlePaint =
        Paint()
          ..color = Colors.blueGrey
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    // Apply transformations: first translate, then scale
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomScale, zoomScale);

    for (final object in objects) {
      if (object is Point) {
        canvas.drawCircle(
          Offset(object.x, object.y),
          pointRadius,
          pointPaint,
        ); // Responsive point size
      } else if (object is Line) {
        // Line drawing remains the same
        canvas.drawLine(
          Offset(object.start.x, object.start.y),
          Offset(object.end.x, object.end.y),
          linePaint,
        );
      } else if (object is Circle) {
        // Circle drawing remains the same
        canvas.drawCircle(
          Offset(object.center.x, object.center.y),
          object.radius,
          circlePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(GeometryPainter oldDelegate) =>
      oldDelegate.objects != objects ||
      oldDelegate.panOffset != panOffset ||
      oldDelegate.zoomScale != zoomScale;
}
