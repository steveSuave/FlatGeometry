import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geometry_app/painters/geometry_painter.dart';

class GeometryObjectsFinder extends MatchFinder {
  final int expectedCount;

  GeometryObjectsFinder({required this.expectedCount});

  @override
  String get description => 'Geometry objects with count: $expectedCount';

  @override
  bool matches(Element candidate) {
    if (candidate.widget is CustomPaint) {
      final customPaint = candidate.widget as CustomPaint;
      if (customPaint.painter is GeometryPainter) {
        final painter = customPaint.painter as GeometryPainter;
        return painter.state.objects.length == expectedCount;
      }
    }
    return false;
  }
}

Finder findGeometryObjects({required int count}) =>
    GeometryObjectsFinder(expectedCount: count);

Finder findGeometryObjectOfType({required Type type, int atIndex = 0}) {
  return find.byWidgetPredicate((widget) {
    if (widget is CustomPaint && widget.painter is GeometryPainter) {
      final painter = widget.painter as GeometryPainter;
      return painter.state.objects.length > atIndex &&
          painter.state.objects[atIndex].runtimeType == type;
    }
    return false;
  });
}
