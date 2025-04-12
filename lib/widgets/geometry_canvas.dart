import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geometry_app/commands/geometry_canvas_context.dart';
import 'dart:math' as math;
import '../models/geometry_object.dart';
import '../models/point.dart';
import '../tools/geometry_tool.dart';
import '../tools/tool_registry.dart';
import '../painters/geometry_painter.dart';
import '../utils/math_utils.dart';
import 'tool_button.dart';
import '../commands/geometry_command.dart';
import '../commands/point_command.dart';
import '../commands/line_command.dart';
import '../commands/circle_command.dart';
import '../commands/pan_command.dart';

class GeometryCanvas extends StatefulWidget {
  final VoidCallback toggleTheme;

  const GeometryCanvas({super.key, required this.toggleTheme});

  @override
  State<GeometryCanvas> createState() => _GeometryCanvasState();
}

class _GeometryCanvasState extends State<GeometryCanvas> implements GeometryCanvasContext {
  // Make objects and addToHistory accessible to commands
  @override
  List<GeometryObject> get objects => _objects;
  @override
  void addToHistory(List<GeometryObject> objects) => _addToHistory(objects);

  // Get the tool registry
  final _toolRegistry = ToolRegistry.instance;
  GeometryTool _currentTool = GeometryTool.point;
  final List<GeometryObject> _objects = [];
  late double _pointSelectionThreshold;

  // Command pattern implementation
  late final Map<GeometryTool, GeometryCommand> _commands;

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

    // Initialize commands
    _commands = {
      GeometryTool.point: PointCommand(),
      GeometryTool.line: LineCommand(),
      GeometryTool.circle: CircleCommand(),
      GeometryTool.pan: PanCommand(),
    };

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

        // Reset all commands when undoing
        _commands.values.forEach((command) => command.reset());
      });
    }
  }

  void _redo() {
    if (_currentHistoryIndex < _history.length - 1) {
      setState(() {
        _currentHistoryIndex++;
        _objects.clear();
        _objects.addAll(List.from(_history[_currentHistoryIndex]));

        // Reset all commands when redoing
        _commands.values.forEach((command) => command.reset());
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

  // Method to change tools
  void _selectTool(GeometryTool tool) {
    if (_currentTool != tool) {
      // Reset the current command when changing tools
      _commands[_currentTool]!.reset();
      setState(() => _currentTool = tool);
    }
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
        title: const Text('Flat Geometry'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
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
          IconButton(
            icon: const Icon(Icons.crop_free),
            onPressed: _resetZoom,
            tooltip: 'Reset zoom',
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _currentHistoryIndex > 0 ? _undo : null,
            tooltip: 'Undo (<-)',
          ),
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

            // Handle undo/redo shortcuts
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _undo();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _redo();
              return KeyEventResult.handled;
            }

            // Handle tool shortcuts using registry
            final tool = _toolRegistry.findToolForKeyEvent(event);
            if (tool != null) {
              setState(() => _currentTool = tool.type);
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
              key: const Key('geometry_canvas'), // Add this key
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
              children: _toolRegistry.tools.map((tool) {
                return ToolButton(
                  padding: EdgeInsets.symmetric(
                    vertical: verticalPadding,
                    horizontal: constraints.maxWidth * 0.02,
                  ),
                  icon: tool.icon,
                  label: tool.tooltip,
                  isSelected: _currentTool == tool.type,
                  onPressed: () => _selectTool(tool.type),
                );
              }).toList(),
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
        double distance = getDistance(canvasPosition, object);

        if (distance <= adjustedThreshold) {
          return object;
        }
      }
    }
    return null;
  }

  // Updated to use command pattern
  void _handleTap(TapDownDetails details, BuildContext context) {
    final position = details.localPosition;
    final canvasPosition = _screenToCanvasCoordinates(position);
    final nearbyPoint = _findNearbyPoint(position);

    // Use the command for the current tool
    _commands[_currentTool]?.execute(this, canvasPosition, nearbyPoint);
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
