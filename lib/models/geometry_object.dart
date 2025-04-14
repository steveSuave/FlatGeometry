import 'package:flutter/material.dart';
import 'dart:math' as math;

enum DragMode { none, move, transform }

abstract class GeometryObject {
  // Default color for geometry objects
  final Color color;

  // Flag to track selection state
  bool isSelected = false;

  GeometryObject({this.color = Colors.blueGrey});

  void draw(Canvas canvas, Size size, double zoomScale);

  // New hit testing methods
  bool containsPoint(Offset point, double threshold);

  // Method to handle dragging
  void applyDrag(Offset delta, DragMode mode, [Offset? absolutePosition]);

  // Method to check if we're near a control point for transformation
  bool isNearControlPoint(Offset point, double threshold) {
    return false;
  }

  // Common method to create stroke paint
  Paint createStrokePaint(Size size) {
    final minDimension = math.min(size.width, size.height);
    return Paint()
      ..color = isSelected ? Colors.red : color
      ..strokeWidth = minDimension * 0.003
      ..style = PaintingStyle.stroke;
  }

  // Common method to create fill paint
  Paint createFillPaint(Size size) {
    final minDimension = math.min(size.width, size.height);
    return Paint()
      ..color = isSelected ? Colors.red : color
      ..strokeWidth = minDimension * 0.003
      ..style = PaintingStyle.fill;
  }

  // Utility method for common calculations
  double getRelativeSize(Size size, double factor) {
    final minDimension = math.min(size.width, size.height);
    return minDimension * factor;
  }
}
