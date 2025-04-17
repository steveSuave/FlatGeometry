import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/point.dart';

// Calculate distance between two points
double getPointDistance(Point a, Point b) {
  return math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
}

// Calculate distance between an offset and a point
double getDistance(Offset position, Point point) {
  return math.sqrt(
    math.pow(position.dx - point.x, 2) + math.pow(position.dy - point.y, 2),
  );
}

// Calculate distance between two offsets
double getOffsetDistance(Offset a, Offset b) {
  return math.sqrt(math.pow(a.dx - b.dx, 2) + math.pow(a.dy - b.dy, 2));
}
