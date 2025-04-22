import 'geometry_object.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class Point extends GeometryObject {
  // Make coordinates mutable for dragging
  double x;
  double y;

  Point(this.x, this.y, {super.color});

  @override
  void draw(Canvas canvas, Size size, double zoomScale) {
    final pointRadius = getRelativeSize(size, 0.005);
    canvas.drawCircle(Offset(x, y), pointRadius, createFillPaint(size));

    // Draw selection indicator when selected
    if (isSelected) {
      final highlightRadius = pointRadius * 1.5;
      final highlightPaint =
          Paint()
            ..color = Colors.yellow.withAlpha(76) // ~0.3 opacity
            ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), highlightRadius, highlightPaint);
    }
  }

  @override
  bool containsPoint(Offset point, double threshold) {
    final distance = math.sqrt(
      math.pow(point.dx - x, 2) + math.pow(point.dy - y, 2),
    );
    return distance <= threshold;
  }

  @override
  void applyDrag(Offset delta, DragMode mode, [Offset? absolutePosition]) {
    // Points only support move mode
    if (mode == DragMode.move) {
      x += delta.dx;
      y += delta.dy;
    }
  }

  // Allow other objects to observe when this point moves
  void registerObserver(Function(Point) observer) {
    // In a more complex implementation, we'd maintain a list of observers
    // For now we don't need this as we directly access the point references
  }

  @override
  Map<String, dynamic> captureState() {
    return {'x': x, 'y': y};
  }
}
