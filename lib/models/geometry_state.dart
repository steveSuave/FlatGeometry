import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'geometry_object.dart';
import 'point.dart';
import 'line.dart';
import 'circle.dart';
import '../tools/geometry_tool.dart';
import 'command.dart';

class GeometryState extends ChangeNotifier {
  // Tool management
  GeometryTool _currentTool = GeometryTool.point;
  GeometryTool get currentTool => _currentTool;
  void setTool(GeometryTool tool) {
    _currentTool = tool;
    notifyListeners();
  }

  // Object management
  final List<GeometryObject> _objects = [];
  List<GeometryObject> get objects => List.unmodifiable(_objects);
  Point? _tempStartPoint;
  Point? get tempStartPoint => _tempStartPoint;

  // Selection management
  GeometryObject? _selectedObject;
  GeometryObject? get selectedObject => _selectedObject;
  bool _isDragging = false;
  bool get isDragging => _isDragging;
  Offset? _lastDragPosition;
  Offset? get lastDragPosition => _lastDragPosition;
  DragMode _currentDragMode = DragMode.none;
  DragMode get currentDragMode => _currentDragMode;

  // Command management
  final CommandManager _commandManager = CommandManager();

  // View transformations
  Offset _panOffset = Offset.zero;
  Offset get panOffset => _panOffset;
  double _zoomScale = 1.0;
  double get zoomScale => _zoomScale;
  final double _minZoom = 0.1;
  final double _maxZoom = 5.0;
  double _baseScaleFactor = 1.0;
  double get baseScaleFactor => _baseScaleFactor;

  // Selection threshold
  late double _pointSelectionThreshold = 10.0;
  double get pointSelectionThreshold => _pointSelectionThreshold;

  // Constructor
  GeometryState();

  // Updates the selection threshold based on screen size
  void updateSelectionThreshold(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final minDimension = math.min(size.width, size.height);
    _pointSelectionThreshold =
        minDimension * 0.03; // 3% of screen smallest dimension
  }

  // Command pattern methods
  void executeCommand(Command command) {
    _commandManager.execute(command, this);
  }

  void undo() {
    if (_commandManager.canUndo()) {
      _commandManager.undo(this);
    }
  }

  void redo() {
    if (_commandManager.canRedo()) {
      _commandManager.redo(this);
    }
  }

  bool canUndo() {
    return _commandManager.canUndo();
  }

  bool canRedo() {
    return _commandManager.canRedo();
  }

  // Methods needed by commands for state manipulation without history tracking
  void addObjectWithoutHistory(GeometryObject object) {
    _objects.add(object);
    notifyListeners();
  }

  void removeObjectWithoutHistory(GeometryObject object) {
    _objects.remove(object);
    notifyListeners();
  }

  void setSelectedObjectWithoutNotifying(GeometryObject? object) {
    _selectedObject = object;
  }

  void notifyListenersWithoutHistory() {
    notifyListeners();
  }

  // Add zoom methods
  void zoomIn() {
    _zoomScale = (_zoomScale * 1.05).clamp(_minZoom, _maxZoom);
    notifyListeners();
  }

  void zoomOut() {
    _zoomScale = (_zoomScale / 1.05).clamp(_minZoom, _maxZoom);
    notifyListeners();
  }

  void resetView() {
    _zoomScale = 1.0;
    _panOffset = Offset.zero;
    notifyListeners();
  }

  void updateZoom(double scale) {
    _zoomScale = (_baseScaleFactor * scale).clamp(_minZoom, _maxZoom);
    notifyListeners();
  }

  void updatePan(Offset delta) {
    _panOffset += delta;
    notifyListeners();
  }

  void setBaseScaleFactor(double factor) {
    _baseScaleFactor = factor;
  }

  // Helper method to convert screen to canvas coordinates
  Offset screenToCanvasCoordinates(Offset screenPosition) {
    final panAdjusted = Offset(
      screenPosition.dx - _panOffset.dx,
      screenPosition.dy - _panOffset.dy,
    );

    return Offset(panAdjusted.dx / _zoomScale, panAdjusted.dy / _zoomScale);
  }

  // Selection methods
  void clearSelection() {
    if (_selectedObject != null) {
      final command = SelectObjectCommand(_selectedObject, null);
      executeCommand(command);
    }
  }

  void selectObject(GeometryObject? object) {
    if (object != _selectedObject) {
      final command = SelectObjectCommand(_selectedObject, object);
      executeCommand(command);
    }
  }

  // Object creation methods
  void addPoint(Offset position) {
    final canvasPosition = screenToCanvasCoordinates(position);
    final point = Point(canvasPosition.dx, canvasPosition.dy);

    final command = AddPointCommand(point);
    executeCommand(command);
  }

  void startLine(Offset position) {
    final canvasPosition = screenToCanvasCoordinates(position);
    final nearbyPoint = findNearbyPoint(position);

    if (nearbyPoint != null) {
      _tempStartPoint = nearbyPoint;
    } else {
      _tempStartPoint = Point(canvasPosition.dx, canvasPosition.dy);
      final command = AddPointCommand(_tempStartPoint!);
      executeCommand(command);
    }
    notifyListeners();
  }

  void completeLine(Offset position) {
    if (_tempStartPoint == null) return;

    final canvasPosition = screenToCanvasCoordinates(position);
    final nearbyPoint = findNearbyPoint(position);

    Point endPoint;
    bool shouldAddEndPoint = false;

    if (nearbyPoint != null) {
      endPoint = nearbyPoint;
    } else {
      endPoint = Point(canvasPosition.dx, canvasPosition.dy);
      shouldAddEndPoint = true;
    }

    final line = Line(_tempStartPoint!, endPoint);
    final command = AddLineCommand(
      line,
      endPoint: shouldAddEndPoint ? endPoint : null,
      shouldAddEndPoint: shouldAddEndPoint,
    );

    executeCommand(command);
    _tempStartPoint = null;
  }

  void startCircle(Offset position) {
    final canvasPosition = screenToCanvasCoordinates(position);
    final nearbyPoint = findNearbyPoint(position);

    if (nearbyPoint != null) {
      _tempStartPoint = nearbyPoint;
    } else {
      _tempStartPoint = Point(canvasPosition.dx, canvasPosition.dy);
      final command = AddPointCommand(_tempStartPoint!);
      executeCommand(command);
    }
    notifyListeners();
  }

  void completeCircle(Offset position) {
    if (_tempStartPoint == null) return;

    final canvasPosition = screenToCanvasCoordinates(position);
    final nearbyPoint = findNearbyPoint(position);

    Offset secondPoint =
        nearbyPoint != null
            ? Offset(nearbyPoint.x, nearbyPoint.y)
            : canvasPosition;

    final radius = getDistance(secondPoint, _tempStartPoint!);
    final circle = Circle(_tempStartPoint!, radius);

    final command = AddCircleCommand(circle);
    executeCommand(command);
    _tempStartPoint = null;
  }

  // Helper methods
  double getDistance(Offset p1, Point p2) {
    return math.sqrt(math.pow(p1.dx - p2.x, 2) + math.pow(p1.dy - p2.y, 2));
  }

  Point? findNearbyPoint(Offset position) {
    // Convert screen position to canvas coordinates
    final canvasPosition = screenToCanvasCoordinates(position);

    // Adjust the threshold for zoom level
    final adjustedThreshold = _pointSelectionThreshold / _zoomScale;

    for (var object in _objects) {
      if (object is Point) {
        // Calculate distance using canvas coordinates
        double distance = getDistance(canvasPosition, object);

        if (distance <= adjustedThreshold) {
          return object;
        }
      }
    }
    return null;
  }

  GeometryObject? findObjectAtPosition(Offset position) {
    final canvasPosition = screenToCanvasCoordinates(position);

    // Reverse the list to check from top to bottom (last drawn to first drawn)
    for (int i = _objects.length - 1; i >= 0; i--) {
      final object = _objects[i];
      if (object.containsPoint(
        canvasPosition,
        _pointSelectionThreshold / _zoomScale,
      )) {
        return object;
      }
    }
    return null;
  }

  // Drag handling methods with command pattern
  void startDrag(Offset position) {
    if (_selectedObject == null) return;

    final canvasPosition = screenToCanvasCoordinates(position);
    _lastDragPosition = canvasPosition;
    _isDragging = true;

    // Determine the drag mode
    if (_selectedObject!.isNearControlPoint(
      canvasPosition,
      _pointSelectionThreshold / _zoomScale,
    )) {
      _currentDragMode = DragMode.transform;
    } else {
      _currentDragMode = DragMode.move;
    }

    // Store the initial state for the command
    _initialState = _captureObjectState(_selectedObject!);

    notifyListeners();
  }

  Map<String, dynamic>? _initialState;

  Map<String, dynamic> _captureObjectState(GeometryObject object) {
    if (object is Point) {
      return {'x': object.x, 'y': object.y};
    } else if (object is Line) {
      return {
        'startX': object.start.x,
        'startY': object.start.y,
        'endX': object.end.x,
        'endY': object.end.y,
      };
    } else if (object is Circle) {
      return {
        'centerX': object.center.x,
        'centerY': object.center.y,
        'radius': object.radius,
      };
    }
    return {};
  }

  void updateDrag(Offset position) {
    if (!_isDragging || _selectedObject == null || _lastDragPosition == null) {
      return;
    }

    final canvasPosition = screenToCanvasCoordinates(position);
    final delta = Offset(
      (canvasPosition.dx - _lastDragPosition!.dx),
      (canvasPosition.dy - _lastDragPosition!.dy),
    );

    // Apply the drag without recording a command
    _selectedObject!.applyDrag(delta, _currentDragMode, canvasPosition);
    _lastDragPosition = canvasPosition;
    notifyListeners();
  }

  void endDrag() {
    if (_isDragging && _selectedObject != null && _initialState != null) {
      final finalState = _captureObjectState(_selectedObject!);

      // Only create a command if the object actually changed
      if (_didStateChange(_initialState!, finalState)) {
        final command = TransformObjectCommand(
          _selectedObject!,
          _initialState!,
          finalState,
          _currentDragMode,
        );

        // We don't use executeCommand here because the change is already applied
        // We just want to record it in the command history
        _commandManager.execute(command, this);
      }

      _isDragging = false;
      _lastDragPosition = null;
      _currentDragMode = DragMode.none;
      _initialState = null;
      notifyListeners();
    }
  }

  bool _didStateChange(
    Map<String, dynamic> oldState,
    Map<String, dynamic> newState,
  ) {
    for (final key in oldState.keys) {
      if (oldState[key] != newState[key]) {
        return true;
      }
    }
    return false;
  }
}
