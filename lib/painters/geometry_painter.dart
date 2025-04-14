import 'package:flutter/material.dart';
import '../models/geometry_state.dart';

class GeometryPainter extends CustomPainter {
  final GeometryState state;

  GeometryPainter(this.state) : super(repaint: state);

  @override
  void paint(Canvas canvas, Size size) {
    // Apply transformations
    canvas.translate(state.panOffset.dx, state.panOffset.dy);
    canvas.scale(state.zoomScale, state.zoomScale);

    // Let each object draw itself
    for (final object in state.objects) {
      object.draw(canvas, size, state.zoomScale);
    }
  }

  @override
  bool shouldRepaint(GeometryPainter oldDelegate) => true; // State is a Listenable
}
