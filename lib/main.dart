import 'package:flutter/material.dart';
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

enum GeometryTool { point, line, circle }

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
  final double _pointSelectionThreshold =
      20.0; // Distance threshold for point snapping

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
      body: GestureDetector(
        onTapDown: (details) => _handleTap(details, context),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: CustomPaint(
            painter: GeometryPainter(_objects),
            size: Size.infinite,
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
                  label: 'Point',
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
                  label: 'Line',
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
                  label: 'Circle',
                  isSelected: _currentTool == GeometryTool.circle,
                  onPressed:
                      () => setState(() => _currentTool = GeometryTool.circle),
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
    for (var object in _objects) {
      if (object is Point) {
        // Calculate distance between tap position and this point
        double distance = getDistance(position, object);

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
    // Check if there's a nearby existing point
    final nearbyPoint = _findNearbyPoint(position);

    switch (_currentTool) {
      case GeometryTool.point:
        setState(() {
          _objects.add(Point(position.dx, position.dy));
          _tempStartPoint = null;
        });
        break;
      case GeometryTool.line:
        if (_tempStartPoint == null) {
          setState(() {
            // Use nearby point or create a new one
            if (nearbyPoint != null) {
              _tempStartPoint = nearbyPoint;
            } else {
              _tempStartPoint = Point(position.dx, position.dy);
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
              endPoint = Point(position.dx, position.dy);
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
            // Use nearby point or create a new one for circle center
            if (nearbyPoint != null) {
              _tempStartPoint = nearbyPoint;
            } else {
              _tempStartPoint = Point(position.dx, position.dy);
              _objects.add(_tempStartPoint!);
            }
          });
        } else {
          Offset secondPoint =
              nearbyPoint != null
                  ? Offset(nearbyPoint.x, nearbyPoint.y)
                  : position;
          final radius = getDistance(secondPoint, _tempStartPoint!);
          setState(() {
            _objects.add(Circle(_tempStartPoint!, radius));
            _tempStartPoint = null;
          });
        }
        break;
    }
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
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: padding,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                size: 28,
              ),
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

  GeometryPainter(this.objects);

  @override
  void paint(Canvas canvas, Size size) {
    final pointPaint =
        Paint()
          ..color = Colors.blueGrey
          ..strokeWidth = 2
          ..style = PaintingStyle.fill;

    final linePaint =
        Paint()
          ..color = Colors.blueGrey
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final circlePaint =
        Paint()
          ..color = Colors.blueGrey
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    for (final object in objects) {
      if (object is Point) {
        canvas.drawCircle(Offset(object.x, object.y), 5, pointPaint);
      } else if (object is Line) {
        canvas.drawLine(
          Offset(object.start.x, object.start.y),
          Offset(object.end.x, object.end.y),
          linePaint,
        );
      } else if (object is Circle) {
        canvas.drawCircle(
          Offset(object.center.x, object.center.y),
          object.radius,
          circlePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(GeometryPainter oldDelegate) => true;
}

double getDistance(Offset position, Point point) {
  return math.sqrt(
    math.pow(position.dx - point.x, 2) + math.pow(position.dy - point.y, 2),
  );
}
