import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/point.dart';

double getDistance(Offset position, Point point) {
  return math.sqrt(
    math.pow(position.dx - point.x, 2) + math.pow(position.dy - point.y, 2),
  );
}
