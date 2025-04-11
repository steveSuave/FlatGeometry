import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:io'; // Add this import for Platform

void main() {
  runApp(const GeometryApp());
}

class GeometryApp extends StatefulWidget {
  const GeometryApp({super.key});

  @override
  State<GeometryApp> createState() => _GeometryAppState();
}

class _GeometryAppState extends State<GeometryApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Geometry',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: GeometryCanvas(toggleTheme: toggleTheme),
    );
  }
}

enum GeometryTool { point, line, circle, pan }

class GeometryCanvas extends StatefulWidget {
  final VoidCallback toggleTheme;

  const GeometryCanvas({super.key, required this.toggleTheme});

  @override
  State<GeometryCanvas> createState() => _GeometryCanvasState();
}

class _GeometryCanvasState extends State<GeometryCanvas> {
  GeometryTool _currentTool = GeometryTool.point;
  final List<GeometryObject> _objects = [];
  Point? _tempStartPoint;
  late double _pointSelectionThreshold;

  // Add variables for panning
  Offset _panOffset = Offset.zero;
  bool _isPanning = false;

  // Add variables for zooming
  double _zoomScale = 1.0;
  final double _minZoom = 0.1;
  final double _maxZoom = 5.0;
  double _baseScaleFactor = 1.0;

  // Add variables for undo/redo
  final List<List<GeometryObject>> _history = [];
  int _currentHistoryIndex = -1;

  // Add a FocusNode to handle keyboard events
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize history with empty state
    _addToHistory([]);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Add undo/redo methods
  void _addToHistory(List<GeometryObject> objects) {
    // Remove any future history if we're not at the end
    if (_currentHistoryIndex < _history.length - 1) {
      _history.removeRange(_currentHistoryIndex + 1, _history.length);
    }

    // Add current state to history
    _history.add(List.from(objects));
    _currentHistoryIndex++;
  }

  void _undo() {
    if (_currentHistoryIndex > 0) {
      setState(() {
        _currentHistoryIndex--;
        _objects.clear();
        _objects.addAll(List.from(_history[_currentHistoryIndex]));
        _tempStartPoint = null;
      });
    }
  }

  void _redo() {
    if (_currentHistoryIndex < _history.length - 1) {
      setState(() {
        _currentHistoryIndex++;
        _objects.clear();
        _objects.addAll(List.from(_history[_currentHistoryIndex]));
        _tempStartPoint = null;
      });
    }
  }

  // Add zoom methods
  void _zoomIn() {
    setState(() {
      _zoomScale = (_zoomScale * 1.05).clamp(_minZoom, _maxZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomScale = (_zoomScale / 1.05).clamp(_minZoom, _maxZoom);
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomScale = 1.0;
      _panOffset = Offset.zero;
    });
  }

  // Helper method to convert screen to canvas coordinates
  Offset _screenToCanvasCoordinates(Offset screenPosition) {
    final panAdjusted = Offset(
      screenPosition.dx - _panOffset.dx,
      screenPosition.dy - _panOffset.dy,
    );

    return Offset(panAdjusted.dx / _zoomScale, panAdjusted.dy / _zoomScale);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Add these lines to make selection threshold responsive
    final size = MediaQuery.of(context).size;
    final minDimension = math.min(size.width, size.height);
    _pointSelectionThreshold =
        minDimension * 0.03; // 3% of screen smallest dimension

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Geometry'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          // Add zoom out button
          // Add zoom in button
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: _zoomIn,
            tooltip: 'Zoom in (+)',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: _zoomOut,
            tooltip: 'Zoom out (-)',
          ),
          // Add zoom reset button
          IconButton(
            icon: const Icon(Icons.crop_free),
            onPressed: _resetZoom,
            tooltip: 'Reset zoom',
          ),
          // Existing buttons
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _currentHistoryIndex > 0 ? _undo : null,
            tooltip: 'Undo (<-)',
          ),
          // Add redo button
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed:
                _currentHistoryIndex < _history.length - 1 ? _redo : null,
            tooltip: 'Redo (->)',
          ),
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            // Check for zoom shortcuts - now just using plus/minus without modifiers
            if (event.logicalKey == LogicalKeyboardKey.equal ||
                event.logicalKey == LogicalKeyboardKey.add) {
              _zoomIn();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.minus ||
                event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
              _zoomOut();
              return KeyEventResult.handled;
            }

            // Handle existing keyboard shortcuts
            if (event.character?.toLowerCase() == 'p') {
              setState(() => _currentTool = GeometryTool.point);
              return KeyEventResult.handled;
            } else if (event.character?.toLowerCase() == 'l') {
              setState(() => _currentTool = GeometryTool.line);
              return KeyEventResult.handled;
            } else if (event.character?.toLowerCase() == 'c') {
              setState(() => _currentTool = GeometryTool.circle);
              return KeyEventResult.handled;
            } else if (event.character?.toLowerCase() == 't') {
              setState(() => _currentTool = GeometryTool.pan);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _undo();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _redo();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTapDown: (details) => _handleTap(details, context),
          // Add scale gesture handlers
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          onScaleEnd: _handleScaleEnd,
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: CustomPaint(
              painter: GeometryPainter(_objects, _panOffset, _zoomScale),
              size: Size.infinite,
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate vertical padding as 20% of the BottomAppBar's height
            final verticalPadding = constraints.maxHeight * 0.2;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ToolButton(
                  padding: EdgeInsets.symmetric(
                    vertical: verticalPadding,
                    horizontal: 16.0,
                  ),
                  icon: Icons.fiber_manual_record,
                  label: 'Point (P)',
                  isSelected: _currentTool == GeometryTool.point,
                  onPressed:
                      () => setState(() => _currentTool = GeometryTool.point),
                ),
                ToolButton(
                  padding: EdgeInsets.symmetric(
                    vertical: verticalPadding,
                    horizontal: 16.0,
                  ),
                  icon: Icons.horizontal_rule,
                  label: 'Line (L)',
                  isSelected: _currentTool == GeometryTool.line,
                  onPressed:
                      () => setState(() => _currentTool = GeometryTool.line),
                ),
                ToolButton(
                  padding: EdgeInsets.symmetric(
                    vertical: verticalPadding,
                    horizontal: 16.0,
                  ),
                  icon: Icons.circle_outlined,
                  label: 'Circle (C)',
                  isSelected: _currentTool == GeometryTool.circle,
                  onPressed:
                      () => setState(() => _currentTool = GeometryTool.circle),
                ),
                // Add the pan tool button
                ToolButton(
                  padding: EdgeInsets.symmetric(
                    vertical: verticalPadding,
                    horizontal: 16.0,
                  ),
                  icon: Icons.pan_tool,
                  label: 'Translate (T)',
                  isSelected: _currentTool == GeometryTool.pan,
                  onPressed:
                      () => setState(() => _currentTool = GeometryTool.pan),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper method to find nearby points
  Point? _findNearbyPoint(Offset position) {
    // Convert screen position to canvas coordinates
    final canvasPosition = _screenToCanvasCoordinates(position);

    // Adjust the threshold for zoom level
    final adjustedThreshold = _pointSelectionThreshold / _zoomScale;

    for (var object in _objects) {
      if (object is Point) {
        // Calculate distance using canvas coordinates
        double distance = math.sqrt(
          math.pow(canvasPosition.dx - object.x, 2) +
              math.pow(canvasPosition.dy - object.y, 2),
        );

        if (distance <= adjustedThreshold) {
          return object;
        }
      }
    }
    return null;
  }

  void _handleTap(TapDownDetails details, BuildContext context) {
    final position = details.localPosition;
    final canvasPosition = _screenToCanvasCoordinates(position);

    // Check for nearby points using the original position
    final nearbyPoint = _findNearbyPoint(position);

    switch (_currentTool) {
      case GeometryTool.point:
        setState(() {
          // Use canvas coordinates for creating new points
          _objects.add(Point(canvasPosition.dx, canvasPosition.dy));
          _tempStartPoint = null;
          _addToHistory(_objects);
        });
        break;
      case GeometryTool.line:
        if (_tempStartPoint == null) {
          setState(() {
            // Use nearby point or create a new one with canvas coordinates
            if (nearbyPoint != null) {
              _tempStartPoint = nearbyPoint;
            } else {
              _tempStartPoint = Point(canvasPosition.dx, canvasPosition.dy);
              _objects.add(_tempStartPoint!);
              _addToHistory(_objects);
            }
          });
        } else {
          setState(() {
            // Use nearby point or create a new one for end point
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
          });
        }
        break;
      case GeometryTool.circle:
        if (_tempStartPoint == null) {
          setState(() {
            // Use nearby point or create a new one with canvas coordinates
            if (nearbyPoint != null) {
              _tempStartPoint = nearbyPoint;
            } else {
              _tempStartPoint = Point(canvasPosition.dx, canvasPosition.dy);
              _objects.add(_tempStartPoint!);
              _addToHistory(_objects);
            }
          });
        } else {
          Offset secondPoint =
              nearbyPoint != null
                  ? Offset(nearbyPoint.x, nearbyPoint.y)
                  : canvasPosition;
          final radius = getDistance(secondPoint, _tempStartPoint!);
          setState(() {
            _objects.add(Circle(_tempStartPoint!, radius));
            _tempStartPoint = null;
            _addToHistory(_objects);
          });
        }
        break;
      case GeometryTool.pan:
        // Do nothing for pan tool on tap
        break;
    }
  }

  // Add methods for pan handling
  void _handlePanStart(DragStartDetails details) {
    if (_currentTool == GeometryTool.pan) {
      setState(() {
        _isPanning = true;
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_currentTool == GeometryTool.pan && _isPanning) {
      setState(() {
        _panOffset += details.delta;
      });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _isPanning = false;
    });
  }

  // Add methods for scale handling
  void _handleScaleStart(ScaleStartDetails details) {
    _baseScaleFactor = _zoomScale;
    _isPanning = false;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (details.scale != 1.0) {
        // Handle zooming
        _zoomScale = (_baseScaleFactor * details.scale).clamp(
          _minZoom,
          _maxZoom,
        );
      } else if (_currentTool == GeometryTool.pan) {
        // Handle panning
        _isPanning = true;
        _panOffset += details.focalPointDelta;
      }
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _isPanning = false;
  }
}

class ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final EdgeInsets padding;

  const ToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
  });

  @override
  Widget build(BuildContext context) {
    // Add these lines for responsive measurements
    final size = MediaQuery.of(context).size;
    final minDimension = math.min(size.width, size.height);

    // Calculate responsive sizes
    final iconSize = minDimension * 0.05;
    final borderWidth = minDimension * 0.004;
    final borderRadius = minDimension * 0.015;
    final innerPadding = minDimension * 0.008;
    final verticalSpacing = minDimension * 0.008;

    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: padding,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration:
                    isSelected
                        ? BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: borderWidth, // Responsive border width
                          ),
                          borderRadius: BorderRadius.circular(
                            borderRadius,
                          ), // Responsive border radius
                        )
                        : null,
                padding:
                    isSelected
                        ? EdgeInsets.all(innerPadding)
                        : EdgeInsets.zero, // Responsive padding
                child: Icon(
                  icon,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                  size: iconSize, // Responsive icon size
                ),
              ),
              SizedBox(height: verticalSpacing), // Responsive spacing
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract class GeometryObject {}

class Point extends GeometryObject {
  final double x;
  final double y;

  Point(this.x, this.y);
}

class Line extends GeometryObject {
  final Point start;
  final Point end;

  Line(this.start, this.end);
}

class Circle extends GeometryObject {
  final Point center;
  final double radius;

  Circle(this.center, this.radius);
}

class GeometryPainter extends CustomPainter {
  final List<GeometryObject> objects;
  final Offset panOffset;
  final double zoomScale;

  GeometryPainter(this.objects, this.panOffset, this.zoomScale);

  @override
  void paint(Canvas canvas, Size size) {
    // Add responsive calculations
    final minDimension = math.min(size.width, size.height);
    final pointRadius = minDimension * 0.005;
    final strokeWidth = minDimension * 0.003;

    final pointPaint =
        Paint()
          ..color = Colors.blueGrey
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.fill;

    final linePaint =
        Paint()
          ..color = Colors.blueGrey
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final circlePaint =
        Paint()
          ..color = Colors.blueGrey
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    // Apply transformations: first translate, then scale
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomScale, zoomScale);

    for (final object in objects) {
      if (object is Point) {
        canvas.drawCircle(
          Offset(object.x, object.y),
          pointRadius,
          pointPaint,
        ); // Responsive point size
      } else if (object is Line) {
        // Line drawing remains the same
        canvas.drawLine(
          Offset(object.start.x, object.start.y),
          Offset(object.end.x, object.end.y),
          linePaint,
        );
      } else if (object is Circle) {
        // Circle drawing remains the same
        canvas.drawCircle(
          Offset(object.center.x, object.center.y),
          object.radius,
          circlePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(GeometryPainter oldDelegate) =>
      oldDelegate.objects != objects ||
      oldDelegate.panOffset != panOffset ||
      oldDelegate.zoomScale != zoomScale;
}

double getDistance(Offset position, Point point) {
  return math.sqrt(
    math.pow(position.dx - point.x, 2) + math.pow(position.dy - point.y, 2),
  );
}
