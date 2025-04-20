import 'package:flutter_test/flutter_test.dart';
import 'package:geometry_app/models/point.dart';
import 'package:geometry_app/models/line.dart';
import 'package:geometry_app/models/circle.dart';
import 'package:geometry_app/models/geometry_object.dart';
import 'package:geometry_app/models/command.dart';
import 'package:geometry_app/services/selection_service.dart';

void main() {
  group('SelectionService', () {
    late SelectionService selectionService;
    late List<GeometryObject> objects;
    late Point point1;
    late Point point2;
    late Line line;
    late Circle circle;

    setUp(() {
      selectionService = SelectionService();
      point1 = Point(50, 50);
      point2 = Point(150, 150);
      line = Line(point1, point2);
      circle = Circle(point1, 50);
      objects = [point1, point2, line, circle];
    });

    test('findObjectAtPosition returns the topmost object at position', () {
      // The objects are checked from last to first, so circle (index 3) has highest priority
      final foundObject = selectionService.findObjectAtPosition(
        objects,
        Offset(50, 50), // Position of point1 and circle center
        10,
      );

      // Should return the circle (last added object) since it's on top
      expect(foundObject, equals(circle));
    });

    test('findNearbyPoint returns the closest point', () {
      final foundPoint = selectionService.findNearbyPoint(
        objects,
        Offset(53, 53), // Close to point1 (50, 50)
        10,
      );

      expect(foundPoint, equals(point1));
    });

    test('findNearbyPoint returns null if no point is close enough', () {
      final foundPoint = selectionService.findNearbyPoint(
        objects,
        Offset(100, 100), // Far from any point
        5,
      );

      expect(foundPoint, isNull);
    });

    test('createSelectionCommand creates appropriate command', () {
      final command = selectionService.createSelectionCommand(point1, point2);

      expect(command, isA<SelectObjectCommand>());
      expect(command.previousSelection, equals(point1));
      expect(command.newSelection, equals(point2));
    });

    test('isNearControlPoint delegates to object', () {
      // Create a circle with center at 100,100 and radius 50
      final testCircle = Circle(Point(100, 100), 50);

      // Test point near center
      final result1 = selectionService.isNearControlPoint(
        testCircle,
        Offset(102, 98), // Near center
        10,
      );
      expect(result1, isTrue);

      // Test point away from control points
      final result2 = selectionService.isNearControlPoint(
        testCircle,
        Offset(130, 130), // Away from control points
        5,
      );
      expect(result2, isFalse);
    });

    test('captureObjectState returns correct state for Point', () {
      final point = Point(42, 24);
      final state = point.captureState();

      expect(state, equals({'x': 42, 'y': 24}));
    });

    test('captureObjectState returns correct state for Line', () {
      final start = Point(10, 10);
      final end = Point(20, 30);
      final line = Line(start, end);
      final state = line.captureState();

      expect(
        state,
        equals({'startX': 10, 'startY': 10, 'endX': 20, 'endY': 30}),
      );
    });

    test('captureObjectState returns correct state for Circle', () {
      final center = Point(50, 60);
      final circle = Circle(center, 40);
      final state = circle.captureState();

      expect(state, equals({'centerX': 50.0, 'centerY': 60.0, 'radius': 40.0, 'hasRadiusPoint': 0.0}));
    });

    test('didStateChange detects changes', () {
      final oldState = {'x': 10, 'y': 20};
      final newState = {'x': 10, 'y': 30};

      expect(selectionService.didStateChange(oldState, newState), isTrue);
    });

    test('didStateChange returns false for identical states', () {
      final oldState = {'x': 10, 'y': 20};
      final newState = {'x': 10, 'y': 20};

      expect(selectionService.didStateChange(oldState, newState), isFalse);
    });
  });
}
