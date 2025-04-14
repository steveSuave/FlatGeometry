import 'geometry_object.dart';
import 'point.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class Circle extends GeometryObject {
  final Point center;
  double radius;
  
  // Flag to track if the radius is being resized
  bool _isResizingRadius = false;

  Circle(this.center, this.radius, {super.color});
  
  // Get perimeter point at specified angle
  Offset getPointOnPerimeter(double angle) {
    return Offset(
      center.x + radius * math.cos(angle),
      center.y + radius * math.sin(angle),
    );
  }

  @override
  void draw(Canvas canvas, Size size, double zoomScale) {
    // Draw the circle
    canvas.drawCircle(
      Offset(center.x, center.y),
      radius,
      createStrokePaint(size),
    );
    
    // Draw selection indicator when selected
    if (isSelected) {
      final highlightPaint = Paint()
        ..color = Colors.red.withAlpha(76) // ~0.3 opacity
        ..strokeWidth = createStrokePaint(size).strokeWidth * 2
        ..style = PaintingStyle.stroke;
      
      canvas.drawCircle(
        Offset(center.x, center.y),
        radius,
        highlightPaint,
      );
      
      // Draw center point
      final controlPointRadius = getRelativeSize(size, 0.008);
      final controlPointPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(center.x, center.y), 
        controlPointRadius, 
        controlPointPaint
      );
      
      // Draw a handle on the perimeter for resizing
      final handlePoint = getPointOnPerimeter(math.pi / 4);
      canvas.drawCircle(
        handlePoint, 
        controlPointRadius, 
        controlPointPaint
      );
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
    final distanceToCenter = math.sqrt(
      math.pow(point.dx - center.x, 2) + math.pow(point.dy - center.y, 2),
    );
    
    // Check if we're near the perimeter handle (at 45 degrees)
    final handlePoint = getPointOnPerimeter(math.pi / 4);
    final distanceToHandle = math.sqrt(
      math.pow(point.dx - handlePoint.dx, 2) + math.pow(point.dy - handlePoint.dy, 2),
    );
    
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
          vectorToMouse.dx * vectorToMouse.dx + vectorToMouse.dy * vectorToMouse.dy,
        );
        
        // Only update if the new radius is positive
        if (newRadius > 0) {
          radius = newRadius;
        }
      }
    } else if (mode == DragMode.move) {
      // Move mode - move the entire circle
      center.x += delta.dx;
      center.y += delta.dy;
    }
  }
  
  // Helper method to check if a point is near the perimeter
  bool _isPointNearPerimeter(Offset point, double threshold) {
    // Calculate distance from point to center
    final distanceToCenter = math.sqrt(
      math.pow(point.dx - center.x, 2) + math.pow(point.dy - center.y, 2),
    );
    
    // Calculate distance from point to perimeter
    final distanceToPerimeter = (distanceToCenter - radius).abs();
    
    return distanceToPerimeter <= threshold;
  }
}
