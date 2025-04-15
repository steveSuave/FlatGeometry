import 'package:flutter/material.dart';

/// A class that handles the coordinate system and viewport transformations
/// for the geometry canvas.
class CoordinateSystem extends ChangeNotifier {
  // View transformations
  Offset _panOffset = Offset.zero;
  Offset get panOffset => _panOffset;

  double _zoomScale = 1.0;
  double get zoomScale => _zoomScale;

  final double _minZoom = 0.1;
  final double _maxZoom = 5.0;

  double _baseScaleFactor = 1.0;
  double get baseScaleFactor => _baseScaleFactor;

  CoordinateSystem();

  /// Helper method to convert screen coordinates to canvas coordinates
  Offset screenToCanvasCoordinates(Offset screenPosition) {
    final panAdjusted = Offset(
      screenPosition.dx - _panOffset.dx,
      screenPosition.dy - _panOffset.dy,
    );

    return Offset(panAdjusted.dx / _zoomScale, panAdjusted.dy / _zoomScale);
  }

  /// Helper method to convert canvas coordinates to screen coordinates
  Offset canvasToScreenCoordinates(Offset canvasPosition) {
    final zoomAdjusted = Offset(
      canvasPosition.dx * _zoomScale,
      canvasPosition.dy * _zoomScale,
    );

    return Offset(
      zoomAdjusted.dx + _panOffset.dx,
      zoomAdjusted.dy + _panOffset.dy,
    );
  }

  /// Zooms in by a fixed factor
  void zoomIn() {
    _zoomScale = (_zoomScale * 1.05).clamp(_minZoom, _maxZoom);
    notifyListeners();
  }

  /// Zooms out by a fixed factor
  void zoomOut() {
    _zoomScale = (_zoomScale / 1.05).clamp(_minZoom, _maxZoom);
    notifyListeners();
  }

  /// Resets the view to the default position and zoom
  void resetView() {
    _zoomScale = 1.0;
    _panOffset = Offset.zero;
    notifyListeners();
  }

  /// Updates the zoom scale based on a gesture scale factor
  void updateZoom(double scale) {
    _zoomScale = (_baseScaleFactor * scale).clamp(_minZoom, _maxZoom);
    notifyListeners();
  }

  /// Updates the pan offset based on a gesture delta
  void updatePan(Offset delta) {
    _panOffset += delta;
    notifyListeners();
  }

  /// Sets the base scale factor for zoom operations
  void setBaseScaleFactor(double factor) {
    _baseScaleFactor = factor;
  }

  /// Applies the coordinate system transformations to a canvas
  void applyTransform(Canvas canvas) {
    canvas.translate(_panOffset.dx, _panOffset.dy);
    canvas.scale(_zoomScale, _zoomScale);
  }
}
