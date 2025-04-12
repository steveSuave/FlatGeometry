import 'package:flutter/material.dart';
import '../models/point.dart';
import 'geometry_command.dart';
import 'geometry_canvas_context.dart';

class PanCommand implements GeometryCommand {
  @override
  void execute(
    GeometryCanvasContext context,
    Offset canvasPosition,
    Point? nearbyPoint,
  ) {
    // Pan is handled by gesture detectors, not tap events
  }
  
  @override
  void reset() {} // No state to reset
  
  @override
  bool isComplete() => true;
  
  @override
  String get name => 'Pan Canvas';
}