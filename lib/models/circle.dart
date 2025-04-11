import 'geometry_object.dart';
import 'point.dart';
import 'package:flutter/material.dart';

class Circle extends GeometryObject {
  final Point center;
  final double radius;

  Circle(this.center, this.radius, {super.color});

  @override
  void draw(Canvas canvas, Size size, double zoomScale) {
    canvas.drawCircle(
      Offset(center.x, center.y),
      radius,
      createStrokePaint(size),
    );
  }
}
