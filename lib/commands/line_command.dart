import 'package:flutter/material.dart';
import '../models/point.dart';
import '../models/line.dart';
import 'geometry_command.dart';
import 'geometry_canvas_context.dart';

class LineCommand implements GeometryCommand {
  Point? _startPoint;
  
  @override
  void execute(
    GeometryCanvasContext context,
    Offset canvasPosition,
    Point? nearbyPoint,
  ) {
    if (_startPoint == null) {
      // First click - set start point
      context.setState(() {
        if (nearbyPoint != null) {
          _startPoint = nearbyPoint;
        } else {
          _startPoint = Point(canvasPosition.dx, canvasPosition.dy);
          context.objects.add(_startPoint!);
          context.addToHistory(context.objects);
        }
      });
    } else {
      // Second click - create line
      context.setState(() {
        Point endPoint;
        if (nearbyPoint != null) {
          endPoint = nearbyPoint;
        } else {
          endPoint = Point(canvasPosition.dx, canvasPosition.dy);
          context.objects.add(endPoint);
        }
        context.objects.add(Line(_startPoint!, endPoint));
        context.addToHistory(context.objects);
      });
      reset(); // Reset after completing line
    }
  }
  
  @override
  void reset() {
    _startPoint = null;
  }
  
  @override
  bool isComplete() => _startPoint == null;
  
  @override
  String get name => 'Create Line';
}