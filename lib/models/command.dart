import 'geometry_state.dart';
import 'geometry_object.dart';
import 'point.dart';
import 'line.dart';
import 'circle.dart';

/// Abstract command class that all commands should extend
abstract class Command {
  String get description;

  void execute(GeometryState state);
  void undo(GeometryState state);
}

/// Command to add a point to the canvas
class AddPointCommand implements Command {
  final Point point;

  AddPointCommand(this.point);

  @override
  String get description => 'Add Point';

  @override
  void execute(GeometryState state) {
    state.addObjectWithoutHistory(point);
  }

  @override
  void undo(GeometryState state) {
    state.removeObjectWithoutHistory(point);
  }
}

/// Command to add a line to the canvas
class AddLineCommand implements Command {
  final Line line;
  final Point? startPoint;
  final Point? endPoint;
  final bool shouldAddStartPoint;
  final bool shouldAddEndPoint;

  AddLineCommand(
    this.line, {
    this.startPoint,
    this.endPoint,
    this.shouldAddStartPoint = false,
    this.shouldAddEndPoint = false,
  });

  @override
  String get description => 'Add Line';

  @override
  void execute(GeometryState state) {
    if (shouldAddStartPoint && startPoint != null) {
      state.addObjectWithoutHistory(startPoint!);
    }

    if (shouldAddEndPoint && endPoint != null) {
      state.addObjectWithoutHistory(endPoint!);
    }

    state.addObjectWithoutHistory(line);
  }

  @override
  void undo(GeometryState state) {
    state.removeObjectWithoutHistory(line);

    if (shouldAddEndPoint && endPoint != null) {
      state.removeObjectWithoutHistory(endPoint!);
    }

    if (shouldAddStartPoint && startPoint != null) {
      state.removeObjectWithoutHistory(startPoint!);
    }
  }
}

/// Command to add a circle to the canvas
class AddCircleCommand implements Command {
  final Circle circle;
  final Point? centerPoint;
  final Point? radiusPoint;
  final bool shouldAddCenterPoint;
  final bool shouldAddRadiusPoint;

  AddCircleCommand(
    this.circle, {
    this.centerPoint,
    this.radiusPoint,
    this.shouldAddCenterPoint = false,
    this.shouldAddRadiusPoint = false,
  });

  @override
  String get description => 'Add Circle';

  @override
  void execute(GeometryState state) {
    if (shouldAddCenterPoint && centerPoint != null) {
      state.addObjectWithoutHistory(centerPoint!);
    }
    
    if (shouldAddRadiusPoint && radiusPoint != null) {
      state.addObjectWithoutHistory(radiusPoint!);
    }

    state.addObjectWithoutHistory(circle);
  }

  @override
  void undo(GeometryState state) {
    state.removeObjectWithoutHistory(circle);
    
    if (shouldAddRadiusPoint && radiusPoint != null) {
      state.removeObjectWithoutHistory(radiusPoint!);
    }

    if (shouldAddCenterPoint && centerPoint != null) {
      state.removeObjectWithoutHistory(centerPoint!);
    }
  }
}

/// Command to move/transform a geometry object
class TransformObjectCommand implements Command {
  final GeometryObject object;
  final Map<String, dynamic> oldState;
  final Map<String, dynamic> newState;
  final DragMode dragMode;

  TransformObjectCommand(
    this.object,
    this.oldState,
    this.newState,
    this.dragMode,
  );

  @override
  String get description =>
      dragMode == DragMode.move ? 'Move Object' : 'Transform Object';

  @override
  void execute(GeometryState state) {
    _applyState(object, newState);
    state.notifyListenersWithoutHistory();
  }

  @override
  void undo(GeometryState state) {
    _applyState(object, oldState);
    state.notifyListenersWithoutHistory();
  }

  void _applyState(GeometryObject object, Map<String, dynamic> state) {
    if (object is Point) {
      object.x = state['x'];
      object.y = state['y'];
    } else if (object is Line) {
      object.start.x = state['startX'];
      object.start.y = state['startY'];
      object.end.x = state['endX'];
      object.end.y = state['endY'];
    } else if (object is Circle) {
      object.center.x = state['centerX'];
      object.center.y = state['centerY'];
      object.radius = state['radius'];
      
      // Handle radius point
      if (state.containsKey('hasRadiusPoint')) {
        if (state['hasRadiusPoint'] > 0.5) { // Use numeric comparison instead of boolean
          // Restore or create radius point
          if (object.radiusPoint == null) {
            object.radiusPoint = Point(
              state['radiusPointX'], 
              state['radiusPointY']
            );
          } else {
            object.radiusPoint!.x = state['radiusPointX'];
            object.radiusPoint!.y = state['radiusPointY'];
          }
        } else {
          // Remove radius point if it shouldn't exist
          object.radiusPoint = null;
        }
      }
    }
  }
}

/// Command for selecting an object
class SelectObjectCommand implements Command {
  final GeometryObject? previousSelection;
  final GeometryObject? newSelection;

  SelectObjectCommand(this.previousSelection, this.newSelection);

  @override
  String get description =>
      newSelection == null ? 'Clear Selection' : 'Select Object';

  @override
  void execute(GeometryState state) {
    if (previousSelection != null) {
      previousSelection!.isSelected = false;
    }

    if (newSelection != null) {
      newSelection!.isSelected = true;
      state.setSelectedObjectWithoutNotifying(newSelection);
    } else {
      state.setSelectedObjectWithoutNotifying(null);
    }

    state.notifyListenersWithoutHistory();
  }

  @override
  void undo(GeometryState state) {
    if (newSelection != null) {
      newSelection!.isSelected = false;
    }

    if (previousSelection != null) {
      previousSelection!.isSelected = true;
      state.setSelectedObjectWithoutNotifying(previousSelection);
    } else {
      state.setSelectedObjectWithoutNotifying(null);
    }

    state.notifyListenersWithoutHistory();
  }
}

/// Command manager that handles execution, undo/redo functionality
class CommandManager {
  final List<Command> _commands = [];
  int _currentIndex = -1;

  void execute(Command command, GeometryState state) {
    // Remove any commands that would be redone
    if (_currentIndex < _commands.length - 1) {
      _commands.removeRange(_currentIndex + 1, _commands.length);
    }

    // Execute the command
    command.execute(state);

    // Add to history
    _commands.add(command);
    _currentIndex++;
  }

  bool canUndo() => _currentIndex >= 0;

  bool canRedo() => _currentIndex < _commands.length - 1;

  void undo(GeometryState state) {
    if (!canUndo()) return;

    _commands[_currentIndex].undo(state);
    _currentIndex--;
  }

  void redo(GeometryState state) {
    if (!canRedo()) return;

    _currentIndex++;
    _commands[_currentIndex].execute(state);
  }

  void clear() {
    _commands.clear();
    _currentIndex = -1;
  }
}
