import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

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
  // Remove the fixed value
  late double _pointSelectionThreshold;

  // Add variables for panning
  Offset _panOffset = Offset.zero;
  bool _isPanning = false;

  // Add a FocusNode to handle keyboard events
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
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
            // Handle keyboard shortcuts
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
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTapDown: (details) => _handleTap(details, context),
          // Add pan gesture handlers
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: CustomPaint(
              painter: GeometryPainter(_objects, _panOffset),
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
    // Adjust the position by the inverse of the pan offset
    final adjustedPosition = Offset(
      position.dx - _panOffset.dx,
      position.dy - _panOffset.dy,
    );

    for (var object in _objects) {
      if (object is Point) {
        // Calculate distance between the adjusted tap position and this point
        double distance = getDistance(adjustedPosition, object);

        // If the tap is close enough to this point, return it
        if (distance <= _pointSelectionThreshold) {
          return object;
        }
      }
    }
    // No nearby point found
    return null;
  }

  void _handleTap(TapDownDetails details, BuildContext context) {
    final position = details.localPosition;
    // Adjust the position by the inverse of the pan offset
    final adjustedPosition = Offset(
      position.dx - _panOffset.dx,
      position.dy - _panOffset.dy,
    );

    // Check if there's a nearby existing point using the original position
    final nearbyPoint = _findNearbyPoint(position);

    switch (_currentTool) {
      case GeometryTool.point:
        setState(() {
          // Use the adjusted position for creating new points
          _objects.add(Point(adjustedPosition.dx, adjustedPosition.dy));
          _tempStartPoint = null;
        });
        break;
      case GeometryTool.line:
        if (_tempStartPoint == null) {
          setState(() {
            // Use nearby point or create a new one with adjusted position
            if (nearbyPoint != null) {
              _tempStartPoint = nearbyPoint;
            } else {
              _tempStartPoint = Point(adjustedPosition.dx, adjustedPosition.dy);
              _objects.add(_tempStartPoint!);
            }
          });
        } else {
          setState(() {
            // Use nearby point or create a new one for end point
            Point endPoint;
            if (nearbyPoint != null) {
              endPoint = nearbyPoint;
            } else {
              endPoint = Point(adjustedPosition.dx, adjustedPosition.dy);
              _objects.add(endPoint);
            }
            _objects.add(Line(_tempStartPoint!, endPoint));
            _tempStartPoint = null;
          });
        }
        break;
      case GeometryTool.circle:
        if (_tempStartPoint == null) {
          setState(() {
            // Use nearby point or create a new one with adjusted position
            if (nearbyPoint != null) {
              _tempStartPoint = nearbyPoint;
            } else {
              _tempStartPoint = Point(adjustedPosition.dx, adjustedPosition.dy);
              _objects.add(_tempStartPoint!);
            }
          });
        } else {
          Offset secondPoint =
              nearbyPoint != null
                  ? Offset(nearbyPoint.x, nearbyPoint.y)
                  : adjustedPosition;
          final radius = getDistance(secondPoint, _tempStartPoint!);
          setState(() {
            _objects.add(Circle(_tempStartPoint!, radius));
            _tempStartPoint = null;
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

  GeometryPainter(this.objects, this.panOffset);

  @override
  void paint(Canvas canvas, Size size) {
    // Add responsive calculations
    final minDimension = math.min(size.width, size.height);
    final pointRadius = minDimension * 0.005;
    final strokeWidth = minDimension * 0.003;

    final pointPaint =
        Paint()
          ..color = Colors.blueGrey
          ..strokeWidth =
              strokeWidth // Responsive stroke width
          ..style = PaintingStyle.fill;

    final linePaint =
        Paint()
          ..color = Colors.blueGrey
          ..strokeWidth =
              strokeWidth // Responsive stroke width
          ..style = PaintingStyle.stroke;

    final circlePaint =
        Paint()
          ..color = Colors.blueGrey
          ..strokeWidth =
              strokeWidth // Responsive stroke width
          ..style = PaintingStyle.stroke;

    canvas.translate(panOffset.dx, panOffset.dy);

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
      oldDelegate.objects != objects || oldDelegate.panOffset != panOffset;
}

double getDistance(Offset position, Point point) {
  return math.sqrt(
    math.pow(position.dx - point.x, 2) + math.pow(position.dy - point.y, 2),
  );
}
