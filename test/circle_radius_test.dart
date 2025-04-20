import 'package:flutter_test/flutter_test.dart';
import 'package:geometry_app/models/circle.dart';
import 'package:geometry_app/models/point.dart';
import 'package:geometry_app/models/command.dart';
import 'package:geometry_app/models/geometry_state.dart';
import 'package:geometry_app/models/geometry_object.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

void main() {
  group('Circle with Radius Point Tests', () {
    late Point centerPoint;
    late Point radiusPoint;
    late Circle circle;
    
    setUp(() {
      centerPoint = Point(100, 100);
      radiusPoint = Point(150, 100);
      circle = Circle(centerPoint, 50, radiusPoint: radiusPoint);
    });
    
    test('Circle constructor should accept and store radius point', () {
      expect(circle.radiusPoint, isNotNull);
      expect(circle.radiusPoint, equals(radiusPoint));
      expect(circle.radius, equals(50));
    });
    
    test('updateRadiusPoint should create radius point if null', () {
      final testCircle = Circle(centerPoint, 50);
      expect(testCircle.radiusPoint, isNull);
      
      testCircle.updateRadiusPoint();
      
      expect(testCircle.radiusPoint, isNotNull);
      
      // Radius point should be at pi/4 radians (45 degrees)
      final expectedX = centerPoint.x + 50 * math.cos(math.pi / 4);
      final expectedY = centerPoint.y + 50 * math.sin(math.pi / 4);
      
      expect(testCircle.radiusPoint!.x, closeTo(expectedX, 0.001));
      expect(testCircle.radiusPoint!.y, closeTo(expectedY, 0.001));
    });
    
    test('updateRadiusPoint should update existing radius point', () {
      // Initially, radius point is at (150, 100) = (center.x + radius, center.y)
      expect(circle.radiusPoint!.x, equals(150));
      expect(circle.radiusPoint!.y, equals(100));
      
      // Change the radius and update the radius point
      circle.radius = 75;
      circle.updateRadiusPoint();
      
      // Radius point should maintain its angle but update its distance
      // Initial angle is 0 radians (point on positive x-axis)
      expect(circle.radiusPoint!.x, closeTo(175, 0.1)); // center.x + new radius
      expect(circle.radiusPoint!.y, closeTo(100, 0.1)); // center.y (unchanged)
    });

    test('moving circle should move both center and radius points', () {
      final delta = Offset(25, 25);
      
      // Initially at (100, 100) center and (150, 100) radius point
      expect(centerPoint.x, equals(100));
      expect(centerPoint.y, equals(100));
      expect(radiusPoint.x, equals(150));
      expect(radiusPoint.y, equals(100));
      
      // Apply drag in move mode
      circle.applyDrag(delta, DragMode.move);
      
      // Center should now be at (125, 125)
      expect(centerPoint.x, equals(125));
      expect(centerPoint.y, equals(125));
      
      // Radius point should also have moved by the same amount
      expect(radiusPoint.x, equals(175));
      expect(radiusPoint.y, equals(125));
    });
    
    test('state capture and restoration should handle radius point properly', () {
      // Capture the state
      final state = circle.captureState();
      
      // Verify state includes radius point data
      expect(state['centerX'], equals(100));
      expect(state['centerY'], equals(100));
      expect(state['radius'], equals(50));
      expect(state['radiusPointX'], equals(150));
      expect(state['radiusPointY'], equals(100));
      expect(state['hasRadiusPoint'], equals(1.0)); // Using 1.0 instead of true
      
      // Create a new circle and center point
      final newCenter = Point(200, 200);
      final newCircle = Circle(newCenter, 30);
      expect(newCircle.radiusPoint, isNull);
      
      // Apply the captured state to the new circle
      final command = TransformObjectCommand(
        newCircle, 
        newCircle.captureState(),
        state, 
        DragMode.move
      );
      
      // Execute state restoration manually
      final geomState = GeometryState();
      command.execute(geomState);
      
      // Verify radius point was restored
      expect(newCircle.radiusPoint, isNotNull);
      expect(newCircle.radius, equals(50));
      expect(newCircle.center.x, equals(100));
      expect(newCircle.center.y, equals(100));
      expect(newCircle.radiusPoint!.x, equals(150));
      expect(newCircle.radiusPoint!.y, equals(100));
    });
    
    test('circle with radius point should have visual connection', () {
      // Create a test canvas and size to check drawing
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(500, 500);
      
      // Draw the circle
      circle.draw(canvas, size, 1.0);
      
      // We can't verify the exact drawing operations in this test
      // This is more of a visual test that would need UI testing
      // But we can at least verify it doesn't throw errors
      
      // Convert to picture and validate
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
  
  group('Circle Creation Command Tests', () {
    test('AddCircleCommand should handle radius point creation', () {
      final geometryState = GeometryState();
      final centerPoint = Point(100, 100);
      final radiusPoint = Point(150, 100);
      final circle = Circle(centerPoint, 50, radiusPoint: radiusPoint);
      
      // Create command that adds both center point, radius point and circle
      final command = AddCircleCommand(
        circle,
        centerPoint: centerPoint,
        radiusPoint: radiusPoint,
        shouldAddCenterPoint: true,
        shouldAddRadiusPoint: true,
      );
      
      // Execute command
      command.execute(geometryState);
      
      // Verify all objects were added
      expect(geometryState.objects.length, 3);
      expect(geometryState.objects[0], centerPoint);
      expect(geometryState.objects[1], radiusPoint);
      expect(geometryState.objects[2], circle);
      
      // Undo command
      command.undo(geometryState);
      
      // Verify all objects were removed
      expect(geometryState.objects.length, 0);
    });
  });
}