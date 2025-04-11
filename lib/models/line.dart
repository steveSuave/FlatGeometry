import 'geometry_object.dart';
import 'point.dart';
import 'package:flutter/material.dart';

class Line extends GeometryObject {
  final Point start;
  final Point end;

  Line(this.start, this.end, {super.color});

  @override
  void draw(Canvas canvas, Size size, double zoomScale) {
    canvas.drawLine(
      Offset(start.x, start.y),
      Offset(end.x, end.y),
      createStrokePaint(size),
    );
  }
}
