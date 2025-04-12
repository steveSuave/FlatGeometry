import 'package:flutter/material.dart';
import '../models/geometry_object.dart';

/// Interface defining the operations commands can perform on the canvas
abstract class GeometryCanvasContext {
  /// Access to the objects in the canvas
  List<GeometryObject> get objects;
  
  /// Method to update canvas state
  void setState(VoidCallback fn);
  
  /// Add current objects to history
  void addToHistory(List<GeometryObject> objects);
}