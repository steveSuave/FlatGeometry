import 'package:flutter/material.dart';
import '../models/point.dart';
import 'geometry_command.dart';
import 'geometry_canvas_context.dart';

class PointCommand implements GeometryCommand {
  @override
  void execute(
    GeometryCanvasContext context,
    Offset canvasPosition,
    Point? nearbyPoint,
  ) {
    context.setState(() {
      context.objects.add(Point(canvasPosition.dx, canvasPosition.dy));
      context.addToHistory(context.objects);
    });
  }
  
  @override
  void reset() {}
  
  @override
  bool isComplete() => true;
  
  @override
  String get name => 'Create Point';
}