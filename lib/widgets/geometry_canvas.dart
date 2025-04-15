import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/geometry_state.dart';
import '../models/theme_state.dart';
import '../tools/tool_registry.dart';
import '../painters/geometry_painter.dart';
import 'tool_button.dart';

class GeometryCanvas extends StatefulWidget {
  const GeometryCanvas({super.key});

  @override
  State<GeometryCanvas> createState() => _GeometryCanvasState();
}

class _GeometryCanvasState extends State<GeometryCanvas> {
  // Get the tool registry
  final _toolRegistry = ToolRegistry.instance;

  // Add a FocusNode to handle keyboard events
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get state providers
    final geometryState = Provider.of<GeometryState>(context);
    final themeState = Provider.of<ThemeState>(context);

    // Update the selection threshold based on screen size
    geometryState.updateSelectionThreshold(context);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flat Geometry'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => geometryState.zoomIn(),
            tooltip: 'Zoom in (+)',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => geometryState.zoomOut(),
            tooltip: 'Zoom out (-)',
          ),
          IconButton(
            icon: const Icon(Icons.crop_free),
            onPressed: () => geometryState.resetView(),
            tooltip: 'Reset zoom',
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed:
                geometryState.canUndo() ? () => geometryState.undo() : null,
            tooltip: 'Undo (<-)',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed:
                geometryState.canRedo() ? () => geometryState.redo() : null,
            tooltip: 'Redo (->)',
          ),
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeState.toggleTheme(),
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
              geometryState.zoomIn();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.minus ||
                event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
              geometryState.zoomOut();
              return KeyEventResult.handled;
            }

            // Handle undo/redo shortcuts
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              geometryState.undo();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              geometryState.redo();
              return KeyEventResult.handled;
            }

            // Handle tool shortcuts using registry
            final tool = _toolRegistry.findToolForKeyEvent(event);
            if (tool != null) {
              geometryState.setTool(tool.type);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTapDown: (details) => _handleTapDown(details, geometryState),
          // Use scale gesture handlers for both scaling and panning
          onScaleStart: (details) => _handleScaleStart(details, geometryState),
          onScaleUpdate:
              (details) => _handleScaleUpdate(details, geometryState),
          onScaleEnd: (details) => _handleScaleEnd(details, geometryState),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: CustomPaint(
              key: const Key('geometry_canvas'),
              painter: GeometryPainter(geometryState),
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
              children:
                  _toolRegistry.tools.map((tool) {
                    return ToolButton(
                      padding: EdgeInsets.symmetric(
                        vertical: verticalPadding,
                        horizontal: constraints.maxWidth * 0.02,
                      ),
                      icon: tool.icon,
                      label: tool.tooltip,
                      isSelected: geometryState.currentToolType == tool.type,
                      onPressed: () => geometryState.setTool(tool.type),
                    );
                  }).toList(),
            );
          },
        ),
      ),
    );
  }

  // Delegate gesture handlers to the current tool
  void _handleTapDown(TapDownDetails details, GeometryState state) {
    state.currentTool.onTapDown(details, state);
  }

  void _handleScaleStart(ScaleStartDetails details, GeometryState state) {
    state.currentTool.onScaleStart(details, state);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, GeometryState state) {
    state.currentTool.onScaleUpdate(details, state);
  }

  void _handleScaleEnd(ScaleEndDetails details, GeometryState state) {
    state.currentTool.onScaleEnd(details, state);
  }
}
