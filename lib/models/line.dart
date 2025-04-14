import 'geometry_object.dart';
import 'point.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class Line extends GeometryObject {
  final Point start;
  final Point end;

  // Track which end is being dragged
  bool _isDraggingStart = false;
  bool _isDraggingEnd = false;

  Line(this.start, this.end, {super.color});

  // Get length of the line
  double get length {
    return math.sqrt(
      math.pow(end.x - start.x, 2) + math.pow(end.y - start.y, 2),
    );
  }

  // Get midpoint of the line
  Offset get midpoint {
    return Offset((start.x + end.x) / 2, (start.y + end.y) / 2);
  }

  @override
  void draw(Canvas canvas, Size size, double zoomScale) {
    // Draw the line
    canvas.drawLine(
      Offset(start.x, start.y),
      Offset(end.x, end.y),
      createStrokePaint(size),
    );

    // Draw selection indicator when selected
    if (isSelected) {
      final highlightPaint =
          Paint()
            ..color = Colors.red.withAlpha(76) // ~0.3 opacity
            ..strokeWidth = createStrokePaint(size).strokeWidth * 2
            ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(start.x, start.y),
        Offset(end.x, end.y),
        highlightPaint,
      );

      // Draw control points at endpoints for transformation
      final controlPointRadius = getRelativeSize(size, 0.008);
      final controlPointPaint =
          Paint()
            ..color = Colors.red
            ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(start.x, start.y),
        controlPointRadius,
        controlPointPaint,
      );
      canvas.drawCircle(
        Offset(end.x, end.y),
        controlPointRadius,
        controlPointPaint,
      );
    }
  }

  @override
  bool containsPoint(Offset point, double threshold) {
    // First check if we're near the endpoints for transformation
    if (isNearControlPoint(point, threshold)) {
      return true;
    }

    // If not, check if we're near the line for movement
    return _isPointNearLine(point, threshold);
  }

  @override
  bool isNearControlPoint(Offset point, double threshold) {
    // Check if we're near the start or end point
    final distanceToStart = math.sqrt(
      math.pow(point.dx - start.x, 2) + math.pow(point.dy - start.y, 2),
    );

    final distanceToEnd = math.sqrt(
      math.pow(point.dx - end.x, 2) + math.pow(point.dy - end.y, 2),
    );

    _isDraggingStart = distanceToStart <= threshold;
    _isDraggingEnd = distanceToEnd <= threshold;

    return _isDraggingStart || _isDraggingEnd;
  }

  @override
  void applyDrag(Offset delta, DragMode mode, [Offset? absolutePosition]) {
    // Keep existing implementation
    if (mode == DragMode.move) {
      // Move both points
      start.x += delta.dx;
      start.y += delta.dy;
      end.x += delta.dx;
      end.y += delta.dy;
    } else if (mode == DragMode.transform) {
      // Move only the control point being dragged
      if (_isDraggingStart) {
        start.x += delta.dx;
        start.y += delta.dy;
      } else if (_isDraggingEnd) {
        end.x += delta.dx;
        end.y += delta.dy;
      }
    }
  }

  // Helper method to check if a point is near the line segment
  bool _isPointNearLine(Offset point, double threshold) {
    // Vector from line start to end
    final dx = end.x - start.x;
    final dy = end.y - start.y;

    // Length of the line
    final lineLength = math.sqrt(dx * dx + dy * dy);

    // If the line is too short, treat it as a point
    if (lineLength < 0.0001) {
      return math.sqrt(
            math.pow(point.dx - start.x, 2) + math.pow(point.dy - start.y, 2),
          ) <=
          threshold;
    }

    // Calculate the projection of the point onto the line
    final t =
        ((point.dx - start.x) * dx + (point.dy - start.y) * dy) /
        (lineLength * lineLength);

    // If t is outside [0,1], the projection falls outside the line segment
    if (t < 0) {
      return math.sqrt(
            math.pow(point.dx - start.x, 2) + math.pow(point.dy - start.y, 2),
          ) <=
          threshold;
    } else if (t > 1) {
      return math.sqrt(
            math.pow(point.dx - end.x, 2) + math.pow(point.dy - end.y, 2),
          ) <=
          threshold;
    }

    // Calculate the projection point
    final projX = start.x + t * dx;
    final projY = start.y + t * dy;

    // Calculate distance from point to line
    return math.sqrt(
          math.pow(point.dx - projX, 2) + math.pow(point.dy - projY, 2),
        ) <=
        threshold;
  }
}
