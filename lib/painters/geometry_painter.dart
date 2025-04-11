import 'package:flutter/material.dart';
import '../models/geometry_object.dart';

class GeometryPainter extends CustomPainter {
  final List<GeometryObject> objects;
  final Offset panOffset;
  final double zoomScale;

  GeometryPainter(this.objects, this.panOffset, this.zoomScale);

  @override
  void paint(Canvas canvas, Size size) {
    // Apply transformations
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomScale, zoomScale);

    // Let each object draw itself
    for (final object in objects) {
      object.draw(canvas, size, zoomScale);
    }
  }

  @override
  bool shouldRepaint(GeometryPainter oldDelegate) =>
      oldDelegate.objects != objects ||
      oldDelegate.panOffset != panOffset ||
      oldDelegate.zoomScale != zoomScale;
}
