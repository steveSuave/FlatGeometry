import 'package:flutter_test/flutter_test.dart';
import 'package:geometry_app/models/coordinate_system.dart';

void main() {
  group('CoordinateSystem', () {
    test('should initialize with default values', () {
      final coordSystem = CoordinateSystem();

      expect(coordSystem.panOffset, equals(Offset.zero));
      expect(coordSystem.zoomScale, equals(1.0));
      expect(coordSystem.baseScaleFactor, equals(1.0));
    });

    test('should zoom in and out correctly', () {
      final coordSystem = CoordinateSystem();
      final initialZoom = coordSystem.zoomScale;

      // Zoom in and verify
      coordSystem.zoomIn();
      expect(coordSystem.zoomScale, greaterThan(initialZoom));

      // Zoom out and verify
      final afterZoomIn = coordSystem.zoomScale;
      coordSystem.zoomOut();
      expect(coordSystem.zoomScale, lessThan(afterZoomIn));
    });

    test('should reset view correctly', () {
      final coordSystem = CoordinateSystem();

      // Change zoom and pan
      coordSystem.zoomIn();
      coordSystem.updatePan(const Offset(100, 100));

      // Reset view
      coordSystem.resetView();

      // Verify reset
      expect(coordSystem.zoomScale, equals(1.0));
      expect(coordSystem.panOffset, equals(Offset.zero));
    });

    test('should convert between screen and canvas coordinates correctly', () {
      final coordSystem = CoordinateSystem();

      // Set some zoom and pan
      coordSystem.updateZoom(2.0);
      coordSystem.updatePan(const Offset(10, 20));

      // Test point
      const screenPoint = Offset(100, 150);

      // Convert to canvas coordinates
      final canvasPoint = coordSystem.screenToCanvasCoordinates(screenPoint);

      // Convert back to screen coordinates
      final screenPointAgain = coordSystem.canvasToScreenCoordinates(
        canvasPoint,
      );

      // Should be approximately the same (allowing for floating point precision)
      expect((screenPointAgain - screenPoint).distance, lessThan(0.001));
    });

    test('should update zoom with scale correctly', () {
      final coordSystem = CoordinateSystem();

      // Set base scale factor
      coordSystem.setBaseScaleFactor(1.0);

      // Apply scaling
      coordSystem.updateZoom(2.0);
      expect(coordSystem.zoomScale, equals(2.0));

      // Should respect min/max zoom
      coordSystem.updateZoom(10.0); // Beyond max
      expect(coordSystem.zoomScale, equals(5.0)); // Max zoom

      coordSystem.updateZoom(0.05); // Below min
      expect(coordSystem.zoomScale, equals(0.1)); // Min zoom
    });

    test('should update pan correctly', () {
      final coordSystem = CoordinateSystem();

      // Initial pan should be zero
      expect(coordSystem.panOffset, equals(Offset.zero));

      // Apply panning
      coordSystem.updatePan(const Offset(10, 20));
      expect(coordSystem.panOffset, equals(const Offset(10, 20)));

      // Pan should be cumulative
      coordSystem.updatePan(const Offset(5, 10));
      expect(coordSystem.panOffset, equals(const Offset(15, 30)));
    });
  });
}
