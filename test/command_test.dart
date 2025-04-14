import 'package:flutter_test/flutter_test.dart';
import 'package:geometry_app/models/command.dart';
import 'package:geometry_app/models/geometry_state.dart';
import 'package:geometry_app/models/point.dart';
import 'package:geometry_app/models/line.dart';
import 'package:geometry_app/models/circle.dart';
import 'package:geometry_app/models/geometry_object.dart';

void main() {
  group('Command Pattern', () {
    late GeometryState state;
    late CommandManager commandManager;

    setUp(() {
      state = GeometryState();
      commandManager = CommandManager();
    });

    test('AddPointCommand should add a point and be undoable', () {
      // Create test point
      final point = Point(100, 100);
      final command = AddPointCommand(point);

      // Execute command
      command.execute(state);

      // Verify point was added
      expect(state.objects.length, 1);
      expect(state.objects.first, point);

      // Undo command
      command.undo(state);

      // Verify point was removed
      expect(state.objects.length, 0);
    });

    test('AddLineCommand should add a line and points if needed', () {
      // Create points and line
      final startPoint = Point(10, 10);
      final endPoint = Point(50, 50);
      final line = Line(startPoint, endPoint);

      // Create command that adds both points and the line
      final command = AddLineCommand(
        line,
        startPoint: startPoint,
        endPoint: endPoint,
        shouldAddStartPoint: true,
        shouldAddEndPoint: true,
      );

      // Execute command
      command.execute(state);

      // Verify all objects were added
      expect(state.objects.length, 3);
      expect(state.objects[0], startPoint);
      expect(state.objects[1], endPoint);
      expect(state.objects[2], line);

      // Undo command
      command.undo(state);

      // Verify all objects were removed
      expect(state.objects.length, 0);
    });

    test('AddCircleCommand should add a circle and center point if needed', () {
      // Create center point and circle
      final centerPoint = Point(100, 100);
      final circle = Circle(centerPoint, 50);

      // Create command that adds both center point and circle
      final command = AddCircleCommand(
        circle,
        centerPoint: centerPoint,
        shouldAddCenterPoint: true,
      );

      // Execute command
      command.execute(state);

      // Verify objects were added
      expect(state.objects.length, 2);
      expect(state.objects[0], centerPoint);
      expect(state.objects[1], circle);

      // Undo command
      command.undo(state);

      // Verify objects were removed
      expect(state.objects.length, 0);
    });

    test(
      'TransformObjectCommand should apply and revert object transformations',
      () {
        // Add a point to transform
        final point = Point(100, 100);
        state.addObjectWithoutHistory(point);

        // Create old and new states
        final oldState = {'x': 100.0, 'y': 100.0};
        final newState = {'x': 150.0, 'y': 75.0};

        // Create transform command
        final command = TransformObjectCommand(
          point,
          oldState,
          newState,
          DragMode.move,
        );

        // Execute command
        command.execute(state);

        // Verify point was transformed
        expect(point.x, 150.0);
        expect(point.y, 75.0);

        // Undo command
        command.undo(state);

        // Verify point was restored
        expect(point.x, 100.0);
        expect(point.y, 100.0);
      },
    );

    test('SelectObjectCommand should select and deselect objects', () {
      // Add two objects
      final point1 = Point(100, 100);
      final point2 = Point(200, 200);
      state.addObjectWithoutHistory(point1);
      state.addObjectWithoutHistory(point2);

      // Select first point
      final selectCommand = SelectObjectCommand(null, point1);
      selectCommand.execute(state);

      // Verify selection
      expect(state.selectedObject, point1);
      expect(point1.isSelected, true);
      expect(point2.isSelected, false);

      // Change selection to second point
      final changeSelectionCommand = SelectObjectCommand(point1, point2);
      changeSelectionCommand.execute(state);

      // Verify new selection
      expect(state.selectedObject, point2);
      expect(point1.isSelected, false);
      expect(point2.isSelected, true);

      // Undo selection change
      changeSelectionCommand.undo(state);

      // Verify original selection is restored
      expect(state.selectedObject, point1);
      expect(point1.isSelected, true);
      expect(point2.isSelected, false);

      // Clear selection
      final clearSelectionCommand = SelectObjectCommand(point1, null);
      clearSelectionCommand.execute(state);

      // Verify selection cleared
      expect(state.selectedObject, null);
      expect(point1.isSelected, false);
      expect(point2.isSelected, false);
    });

    test('CommandManager should manage undo/redo stack correctly', () {
      // Create test points
      final point1 = Point(100, 100);
      final point2 = Point(200, 200);
      final point3 = Point(300, 300);

      // Create commands
      final command1 = AddPointCommand(point1);
      final command2 = AddPointCommand(point2);
      final command3 = AddPointCommand(point3);

      // Execute commands through manager
      commandManager.execute(command1, state);
      commandManager.execute(command2, state);
      commandManager.execute(command3, state);

      // Verify all points are added
      expect(state.objects.length, 3);

      // Verify undo/redo state
      expect(commandManager.canUndo(), true);
      expect(commandManager.canRedo(), false);

      // Undo last command
      commandManager.undo(state);

      // Verify point3 is removed
      expect(state.objects.length, 2);
      expect(state.objects.contains(point3), false);

      // Verify undo/redo state
      expect(commandManager.canUndo(), true);
      expect(commandManager.canRedo(), true);

      // Redo the command
      commandManager.redo(state);

      // Verify point3 is back
      expect(state.objects.length, 3);
      expect(state.objects.contains(point3), true);

      // Undo back to the beginning
      commandManager.undo(state);
      commandManager.undo(state);
      commandManager.undo(state);

      // Verify all points are removed
      expect(state.objects.length, 0);
      expect(commandManager.canUndo(), false);
      expect(commandManager.canRedo(), true);

      // Redo all commands
      commandManager.redo(state);
      commandManager.redo(state);
      commandManager.redo(state);

      // Verify all points are back
      expect(state.objects.length, 3);
      expect(commandManager.canUndo(), true);
      expect(commandManager.canRedo(), false);
    });

    test('CommandManager should handle branching history correctly', () {
      // Create test points
      final point1 = Point(100, 100);
      final point2 = Point(200, 200);
      final point3 = Point(300, 300);
      final point4 = Point(400, 400);

      // Create and execute commands
      commandManager.execute(AddPointCommand(point1), state);
      commandManager.execute(AddPointCommand(point2), state);
      commandManager.execute(AddPointCommand(point3), state);

      // Undo back to point1
      commandManager.undo(state);
      commandManager.undo(state);

      // Execute new command to create branch
      commandManager.execute(AddPointCommand(point4), state);

      // Verify we have point1 and point4
      expect(state.objects.length, 2);
      expect(state.objects.contains(point1), true);
      expect(state.objects.contains(point4), true);
      expect(state.objects.contains(point2), false);
      expect(state.objects.contains(point3), false);

      // Verify redo is not possible (history was rewritten)
      expect(commandManager.canRedo(), false);
    });
  });
}
