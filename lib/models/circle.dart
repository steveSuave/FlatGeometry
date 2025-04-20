import 'package:geometry_app/utils/math_utils.dart';

import 'geometry_object.dart';
import 'point.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class Circle extends GeometryObject {
  final Point center;
  double radius;
  Point? radiusPoint;

  // Flag to track if the radius is being resized
  bool _isResizingRadius = false;

  Circle(this.center, this.radius, {this.radiusPoint, super.color});

  // Get perimeter point at specified angle
  Offset getPointOnPerimeter(double angle) {
    return Offset(
      center.x + radius * math.cos(angle),
      center.y + radius * math.sin(angle),
    );
  }
  
  // Update or create the radius point
  void updateRadiusPoint() {
    if (radiusPoint == null) {
      // Create a radius point at 45 degrees if not exists
      final perimeterPoint = getPointOnPerimeter(math.pi / 4);
      radiusPoint = Point(perimeterPoint.dx, perimeterPoint.dy);
    } else {
      // Check if radius point has been moved
      final distanceFromCenter = math.sqrt(
        math.pow(radiusPoint!.x - center.x, 2) + 
        math.pow(radiusPoint!.y - center.y, 2)
      );
      
      if ((distanceFromCenter - radius).abs() > 0.1) {
        // Update radius point to match current radius
        final angle = math.atan2(radiusPoint!.y - center.y, radiusPoint!.x - center.x);
        final perimeterPoint = getPointOnPerimeter(angle);
        radiusPoint!.x = perimeterPoint.dx;
        radiusPoint!.y = perimeterPoint.dy;
      }
    }
  }

  @override
  void draw(Canvas canvas, Size size, double zoomScale) {
    // Update radius point if it exists
    if (radiusPoint != null) {
      updateRadiusPoint();
    }
    
    // Draw the circle
    canvas.drawCircle(
      Offset(center.x, center.y),
      radius,
      createStrokePaint(size),
    );
    
    // Draw line from center to radius point if it exists
    if (radiusPoint != null) {
      final radiusLinePaint = Paint()
        ..color = color.withAlpha(128) // 0.5 opacity
        ..strokeWidth = createStrokePaint(size).strokeWidth * 0.5
        ..style = PaintingStyle.stroke;
        
      canvas.drawLine(
        Offset(center.x, center.y),
        Offset(radiusPoint!.x, radiusPoint!.y),
        radiusLinePaint,
      );
    }

    // Draw selection indicator when selected
    if (isSelected) {
      final highlightPaint =
          Paint()
            ..color = Colors.red.withAlpha(76) // ~0.3 opacity
            ..strokeWidth = createStrokePaint(size).strokeWidth * 2
            ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset(center.x, center.y), radius, highlightPaint);

      // Draw center point
      final controlPointRadius = getRelativeSize(size, 0.008);
      final controlPointPaint =
          Paint()
            ..color = Colors.red
            ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(center.x, center.y),
        controlPointRadius,
        controlPointPaint,
      );

      // Draw a handle on the perimeter for resizing
      final handlePoint = radiusPoint != null 
          ? Offset(radiusPoint!.x, radiusPoint!.y)
          : getPointOnPerimeter(math.pi / 4);
      canvas.drawCircle(handlePoint, controlPointRadius, controlPointPaint);
    }
  }

  @override
  bool containsPoint(Offset point, double threshold) {
    // First check if we're near the center or perimeter handle
    if (isNearControlPoint(point, threshold)) {
      return true;
    }

    // Check if we're near the perimeter for movement
    return _isPointNearPerimeter(point, threshold);
  }

  @override
  bool isNearControlPoint(Offset point, double threshold) {
    // Check if we're near the center
    final distanceToCenter = getDistance(point, center);

    // Check if we're near the radius point or default handle
    double distanceToHandle;
    
    if (radiusPoint != null) {
      // Use the actual radius point
      distanceToHandle = getDistance(point, radiusPoint!);
    } else {
      // Use the default handle at 45 degrees
      final handlePoint = getPointOnPerimeter(math.pi / 4);
      distanceToHandle = getOffsetDistance(point, handlePoint);
    }

    // Set flags for which part is being dragged
    _isResizingRadius = distanceToHandle <= threshold;

    return distanceToCenter <= threshold || _isResizingRadius;
  }

  @override
  void applyDrag(Offset delta, DragMode mode, [Offset? absolutePosition]) {
    if (mode == DragMode.transform) {
      // Transform mode - modify radius
      if (_isResizingRadius && absolutePosition != null) {
        // Calculate vector from center to absolute mouse position
        final vectorToMouse = Offset(
          absolutePosition.dx - center.x,
          absolutePosition.dy - center.y,
        );

        // Update radius based on the actual distance from center to mouse
        final newRadius = math.sqrt(
          vectorToMouse.dx * vectorToMouse.dx +
              vectorToMouse.dy * vectorToMouse.dy,
        );

        // Only update if the new radius is positive
        if (newRadius > 0) {
          radius = newRadius;
          
          // Update radius point if it exists or create one
          if (radiusPoint != null) {
            // Keep the current angle but update the distance
            final angle = math.atan2(radiusPoint!.y - center.y, radiusPoint!.x - center.x);
            radiusPoint!.x = center.x + radius * math.cos(angle);
            radiusPoint!.y = center.y + radius * math.sin(angle);
          } else {
            // Create a new radius point at the cursor position
            radiusPoint = Point(absolutePosition.dx, absolutePosition.dy);
          }
        }
      }
    } else if (mode == DragMode.move) {
      // Move mode - move the entire circle
      center.x += delta.dx;
      center.y += delta.dy;
      
      // Move the radius point if it exists
      if (radiusPoint != null) {
        radiusPoint!.x += delta.dx;
        radiusPoint!.y += delta.dy;
      }
    }
  }

  @override
  Map<String, dynamic> captureState() {
    final state = {'centerX': center.x, 'centerY': center.y, 'radius': radius};
    
    // Add radius point state if it exists
    if (radiusPoint != null) {
      state['radiusPointX'] = radiusPoint!.x;
      state['radiusPointY'] = radiusPoint!.y;
      state['hasRadiusPoint'] = 1.0;  // Using 1.0 instead of true
    } else {
      state['hasRadiusPoint'] = 0.0;  // Using 0.0 instead of false
    }
    
    return state;
  }

  // Helper method to check if a point is near the perimeter
  bool _isPointNearPerimeter(Offset point, double threshold) {
    // Calculate distance from point to center
    final distanceToCenter = getDistance(point, center);

    // Calculate distance from point to perimeter
    final distanceToPerimeter = (distanceToCenter - radius).abs();

    return distanceToPerimeter <= threshold;
  }
}
