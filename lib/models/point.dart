import 'geometry_object.dart';
import 'package:flutter/material.dart';

class Point extends GeometryObject {
  final double x;
  final double y;

  Point(this.x, this.y, {super.color});

  @override
  void draw(Canvas canvas, Size size, double zoomScale) {
    final pointRadius = getRelativeSize(size, 0.005);
    canvas.drawCircle(Offset(x, y), pointRadius, createFillPaint(size));
  }
}
