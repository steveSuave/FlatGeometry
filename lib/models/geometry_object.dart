import 'package:flutter/material.dart';
import 'dart:math' as math;

abstract class GeometryObject {
  // Default color for geometry objects
  final Color color;

  GeometryObject({this.color = Colors.blueGrey});

  void draw(Canvas canvas, Size size, double zoomScale);

  // Common method to create stroke paint
  Paint createStrokePaint(Size size) {
    final minDimension = math.min(size.width, size.height);
    return Paint()
      ..color = color
      ..strokeWidth = minDimension * 0.003
      ..style = PaintingStyle.stroke;
  }

  // Common method to create fill paint
  Paint createFillPaint(Size size) {
    final minDimension = math.min(size.width, size.height);
    return Paint()
      ..color = color
      ..strokeWidth = minDimension * 0.003
      ..style = PaintingStyle.fill;
  }

  // Utility method for common calculations
  double getRelativeSize(Size size, double factor) {
    final minDimension = math.min(size.width, size.height);
    return minDimension * factor;
  }
}
