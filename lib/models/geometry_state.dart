import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'geometry_object.dart';
import 'point.dart';
import 'line.dart';
import 'circle.dart';
import '../tools/geometry_tool.dart';

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

  // History management
  final List<List<GeometryObject>> _history = [];
  int _currentHistoryIndex = -1;

  // Constructor
  GeometryState() {
    // Initialize history with empty state
    _addToHistory([]);
  }

  // Updates the selection threshold based on screen size
  void updateSelectionThreshold(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final minDimension = math.min(size.width, size.height);
    _pointSelectionThreshold =
        minDimension * 0.03; // 3% of screen smallest dimension
  }

  // Add methods for undo/redo
  void _addToHistory(List<GeometryObject> objects) {
    // Remove any future history if we're not at the end
    if (_currentHistoryIndex < _history.length - 1) {
      _history.removeRange(_currentHistoryIndex + 1, _history.length);
    }

    // Add current state to history
    _history.add(List.from(objects));
    _currentHistoryIndex++;
  }

  void undo() {
    if (_currentHistoryIndex > 0) {
      _currentHistoryIndex--;
      _objects.clear();
      _objects.addAll(List.from(_history[_currentHistoryIndex]));
      _tempStartPoint = null;
      notifyListeners();
    }
  }

  void redo() {
    if (_currentHistoryIndex < _history.length - 1) {
      _currentHistoryIndex++;
      _objects.clear();
      _objects.addAll(List.from(_history[_currentHistoryIndex]));
      _tempStartPoint = null;
      notifyListeners();
    }
  }

  bool canUndo() {
    return _currentHistoryIndex > 0;
  }

  bool canRedo() {
    return _currentHistoryIndex < _history.length - 1;
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
      _selectedObject!.isSelected = false;
      _selectedObject = null;
      notifyListeners();
    }
  }

  void selectObject(GeometryObject? object) {
    clearSelection();
    if (object != null) {
      object.isSelected = true;
      _selectedObject = object;
      notifyListeners();
    }
  }

  // Object creation methods
  void addPoint(Offset position) {
    final canvasPosition = screenToCanvasCoordinates(position);
    _objects.add(Point(canvasPosition.dx, canvasPosition.dy));
    _addToHistory(_objects);
    notifyListeners();
  }

  void startLine(Offset position) {
    final canvasPosition = screenToCanvasCoordinates(position);
    final nearbyPoint = findNearbyPoint(position);

    if (nearbyPoint != null) {
      _tempStartPoint = nearbyPoint;
    } else {
      _tempStartPoint = Point(canvasPosition.dx, canvasPosition.dy);
      _objects.add(_tempStartPoint!);
      _addToHistory(_objects);
    }
    notifyListeners();
  }

  void completeLine(Offset position) {
    if (_tempStartPoint == null) return;

    final canvasPosition = screenToCanvasCoordinates(position);
    final nearbyPoint = findNearbyPoint(position);

    Point endPoint;
    if (nearbyPoint != null) {
      endPoint = nearbyPoint;
    } else {
      endPoint = Point(canvasPosition.dx, canvasPosition.dy);
      _objects.add(endPoint);
    }

    _objects.add(Line(_tempStartPoint!, endPoint));
    _tempStartPoint = null;
    _addToHistory(_objects);
    notifyListeners();
  }

  void startCircle(Offset position) {
    final canvasPosition = screenToCanvasCoordinates(position);
    final nearbyPoint = findNearbyPoint(position);

    if (nearbyPoint != null) {
      _tempStartPoint = nearbyPoint;
    } else {
      _tempStartPoint = Point(canvasPosition.dx, canvasPosition.dy);
      _objects.add(_tempStartPoint!);
      _addToHistory(_objects);
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
    _objects.add(Circle(_tempStartPoint!, radius));
    _tempStartPoint = null;
    _addToHistory(_objects);
    notifyListeners();
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

  // Drag handling methods
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
    notifyListeners();
  }

  void updateDrag(Offset position) {
    if (!_isDragging || _selectedObject == null || _lastDragPosition == null)
      return;

    final canvasPosition = screenToCanvasCoordinates(position);
    final delta = Offset(
      (canvasPosition.dx - _lastDragPosition!.dx),
      (canvasPosition.dy - _lastDragPosition!.dy),
    );

    // Pass the absolute position as well as delta
    _selectedObject!.applyDrag(delta, _currentDragMode, canvasPosition);
    _lastDragPosition = canvasPosition;
    notifyListeners();
  }

  void endDrag() {
    if (_isDragging) {
      _isDragging = false;
      _lastDragPosition = null;
      _currentDragMode = DragMode.none;
      // Add current state to history
      _addToHistory(_objects);
      notifyListeners();
    }
  }
}
