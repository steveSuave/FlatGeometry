import 'package:flutter/material.dart';
import '../models/point.dart';
import 'geometry_canvas_context.dart';

abstract class GeometryCommand {
  void execute(
    GeometryCanvasContext context,
    Offset canvasPosition,
    Point? nearbyPoint,
  );
  
  void reset();
  bool isComplete();
  String get name;
}