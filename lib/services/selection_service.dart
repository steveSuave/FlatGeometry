import 'package:flutter/material.dart';
import '../models/geometry_object.dart';
import '../models/point.dart';
import '../models/command.dart';

/// Service that centralizes selection-related logic for geometry objects
class SelectionService {
  /// Finds an object at the given canvas position using the specified threshold
  GeometryObject? findObjectAtPosition(
    List<GeometryObject> objects,
    Offset position,
    double threshold,
  ) {
    // Reverse the list to check from top to bottom (last drawn to first drawn)
    for (int i = objects.length - 1; i >= 0; i--) {
      final object = objects[i];
      if (object.containsPoint(position, threshold)) {
        return object;
      }
    }
    return null;
  }

  /// Finds a nearby point at the given canvas position
  Point? findNearbyPoint(
    List<GeometryObject> objects,
    Offset position,
    double threshold,
  ) {
    for (var object in objects) {
      if (object is Point) {
        // Calculate distance to point
        double distance = getDistance(position, object);
        if (distance <= threshold) {
          return object;
        }
      }
    }
    return null;
  }

  /// Creates a SelectObjectCommand to change the current selection
  SelectObjectCommand createSelectionCommand(
    GeometryObject? previousSelection,
    GeometryObject? newSelection,
  ) {
    return SelectObjectCommand(previousSelection, newSelection);
  }

  /// Determines if the selected object's control point is being interacted with
  bool isNearControlPoint(
    GeometryObject? object,
    Offset position,
    double threshold,
  ) {
    if (object == null) return false;
    return object.isNearControlPoint(position, threshold);
  }

  /// Captures the current state of an object for undo/redo functionality
  Map<String, dynamic> captureObjectState(GeometryObject object) {
    return object.captureState();
  }

  /// Checks if an object's state has changed between two state snapshots
  bool didStateChange(
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

  /// Helper method to calculate distance between a point and an offset
  double getDistance(Offset p1, Point p2) {
    return (p1 - Offset(p2.x, p2.y)).distance;
  }
}
