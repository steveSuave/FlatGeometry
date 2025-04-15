import 'package:flutter/material.dart';
import '../models/geometry_state.dart';

enum ToolType { point, line, circle, pan, select }

abstract class Tool {
  final ToolType type;

  const Tool(this.type);

  void onTapDown(TapDownDetails details, GeometryState state);
  void onScaleStart(ScaleStartDetails details, GeometryState state);
  void onScaleUpdate(ScaleUpdateDetails details, GeometryState state);
  void onScaleEnd(ScaleEndDetails details, GeometryState state);
}
