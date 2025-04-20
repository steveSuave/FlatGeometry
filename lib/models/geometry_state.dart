import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'geometry_object.dart';
import 'point.dart';
import 'line.dart';
import 'circle.dart';
import '../tools/geometry_tool.dart';
import 'command.dart';
import 'coordinate_system.dart';
import '../services/selection_service.dart';
import '../tools/tool_registry.dart';

class GeometryState extends ChangeNotifier {
  // Tool registry
  final ToolRegistry _toolRegistry;

  // Tool management
  ToolType _currentToolType = ToolType.point;
  ToolType get currentToolType => _currentToolType;

  Tool? _currentTool;
  Tool get currentTool {
    _currentTool ??= _toolRegistry.createTool(_currentToolType);
    return _currentTool!;
  }

  void setTool(ToolType type) {
    _currentToolType = type;
    _currentTool = _toolRegistry.createTool(type);
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

  // Selection service
  final SelectionService _selectionService;

  // Command management
  final CommandManager _commandManager;

  // Coordinate system
  final CoordinateSystem _coordinateSystem;
  CoordinateSystem get coordinateSystem => _coordinateSystem;

  // Viewport transformations - delegates to coordinate system
  Offset get panOffset => _coordinateSystem.panOffset;
  double get zoomScale => _coordinateSystem.zoomScale;
  double get baseScaleFactor => _coordinateSystem.baseScaleFactor;

  // Selection threshold
  late double _pointSelectionThreshold = 10.0;
  double get pointSelectionThreshold => _pointSelectionThreshold;

  // Constructor with dependency injection
  GeometryState({
    ToolRegistry? toolRegistry,
    SelectionService? selectionService,
    CommandManager? commandManager,
    CoordinateSystem? coordinateSystem,
  }) : _toolRegistry = toolRegistry ?? ToolRegistry.instance,
       _selectionService = selectionService ?? SelectionService(),
       _commandManager = commandManager ?? CommandManager(),
       _coordinateSystem = coordinateSystem ?? CoordinateSystem() {
    // Listen to coordinate system changes to notify state listeners
    _coordinateSystem.addListener(() {
      notifyListeners();
    });

    // Initialize current tool
    _currentTool = _toolRegistry.createTool(_currentToolType);
  }

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

  // View transformation methods - delegate to coordinate system
  void zoomIn() {
    _coordinateSystem.zoomIn();
  }

  void zoomOut() {
    _coordinateSystem.zoomOut();
  }

  void resetView() {
    _coordinateSystem.resetView();
  }

  void updateZoom(double scale) {
    _coordinateSystem.updateZoom(scale);
  }

  void updatePan(Offset delta) {
    _coordinateSystem.updatePan(delta);
  }

  void setBaseScaleFactor(double factor) {
    _coordinateSystem.setBaseScaleFactor(factor);
  }

  // Helper method to convert screen to canvas coordinates
  Offset screenToCanvasCoordinates(Offset screenPosition) {
    return _coordinateSystem.screenToCanvasCoordinates(screenPosition);
  }

  // Selection methods
  void clearSelection() {
    if (_selectedObject != null) {
      final command = _selectionService.createSelectionCommand(
        _selectedObject,
        null,
      );
      executeCommand(command);
    }
  }

  void selectObject(GeometryObject? object) {
    if (object != _selectedObject) {
      final command = _selectionService.createSelectionCommand(
        _selectedObject,
        object,
      );
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

    Point? radiusPoint;
    Offset secondPoint;
    
    if (nearbyPoint != null) {
      radiusPoint = nearbyPoint;
      secondPoint = Offset(nearbyPoint.x, nearbyPoint.y);
    } else {
      // Create a new point at the radius position
      secondPoint = canvasPosition;
      radiusPoint = Point(canvasPosition.dx, canvasPosition.dy);
    }

    final radius = _selectionService.getDistance(secondPoint, _tempStartPoint!);
    final circle = Circle(_tempStartPoint!, radius, radiusPoint: radiusPoint);

    final command = AddCircleCommand(
      circle,
      radiusPoint: nearbyPoint == null ? radiusPoint : null,
      shouldAddRadiusPoint: nearbyPoint == null,
    );
    
    executeCommand(command);
    _tempStartPoint = null;
  }

  // Helper methods
  Point? findNearbyPoint(Offset position) {
    // Convert screen position to canvas coordinates
    final canvasPosition = screenToCanvasCoordinates(position);

    // Adjust the threshold for zoom level
    final adjustedThreshold = _pointSelectionThreshold / zoomScale;

    return _selectionService.findNearbyPoint(
      _objects,
      canvasPosition,
      adjustedThreshold,
    );
  }

  GeometryObject? findObjectAtPosition(Offset position) {
    final canvasPosition = screenToCanvasCoordinates(position);

    // Adjust the threshold for zoom level
    final adjustedThreshold = _pointSelectionThreshold / zoomScale;

    return _selectionService.findObjectAtPosition(
      _objects,
      canvasPosition,
      adjustedThreshold,
    );
  }

  // Drag handling methods with command pattern
  void startDrag(Offset position) {
    if (_selectedObject == null) return;

    final canvasPosition = screenToCanvasCoordinates(position);
    _lastDragPosition = canvasPosition;
    _isDragging = true;

    // Adjust the threshold for zoom level
    final adjustedThreshold = _pointSelectionThreshold / zoomScale;

    // Determine the drag mode
    if (_selectionService.isNearControlPoint(
      _selectedObject,
      canvasPosition,
      adjustedThreshold,
    )) {
      _currentDragMode = DragMode.transform;
    } else {
      _currentDragMode = DragMode.move;
    }

    // Store the initial state for the command
    _initialState = _selectedObject!.captureState();

    notifyListeners();
  }

  Map<String, dynamic>? _initialState;

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
      final finalState = _selectedObject!.captureState();

      // Only create a command if the object actually changed
      if (_selectionService.didStateChange(_initialState!, finalState)) {
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

  // Cleanup method
  @override
  void dispose() {
    _coordinateSystem.dispose();
    super.dispose();
  }
}
