import 'package:flutter/material.dart';
import '../models/point.dart';
import '../models/circle.dart';
import 'geometry_command.dart';
import 'geometry_canvas_context.dart';
import '../utils/math_utils.dart';

class CircleCommand implements GeometryCommand {
  Point? _centerPoint;
  
  @override
  void execute(
    GeometryCanvasContext context,
    Offset canvasPosition,
    Point? nearbyPoint,
  ) {
    if (_centerPoint == null) {
      // First click - set center point
      context.setState(() {
        if (nearbyPoint != null) {
          _centerPoint = nearbyPoint;
        } else {
          _centerPoint = Point(canvasPosition.dx, canvasPosition.dy);
          context.objects.add(_centerPoint!);
          context.addToHistory(context.objects);
        }
      });
    } else {
      // Second click - create circle
      Offset secondPoint = nearbyPoint != null
          ? Offset(nearbyPoint.x, nearbyPoint.y)
          : canvasPosition;
          
      final radius = getDistance(secondPoint, _centerPoint!);
      context.setState(() {
        context.objects.add(Circle(_centerPoint!, radius));
        context.addToHistory(context.objects);
      });
      reset(); // Reset after completing circle
    }
  }
  
  @override
  void reset() {
    _centerPoint = null;
  }
  
  @override
  bool isComplete() => _centerPoint == null;
  
  @override
  String get name => 'Create Circle';
}