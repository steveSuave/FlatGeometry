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
  // Constants for layout
  static const double _toolbarVerticalPaddingFactor = 0.2;
  static const double _toolbarHorizontalPaddingFactor = 0.02;

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

    return Scaffold(
      appBar: _buildAppBar(context, geometryState, themeState),
      body: _buildCanvasArea(geometryState),
      bottomNavigationBar: _buildToolbar(context, geometryState),
    );
  }

  /// Builds the application bar with zoom controls and theme toggle
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    GeometryState geometryState,
    ThemeState themeState,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
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
    );
  }

  /// Builds the interactive canvas area with gesture detection
  Widget _buildCanvasArea(GeometryState geometryState) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) => _handleKeyEvent(event, geometryState),
      child: GestureDetector(
        onTapDown: (details) => _handleTapDown(details, geometryState),
        onScaleStart: (details) => _handleScaleStart(details, geometryState),
        onScaleUpdate: (details) => _handleScaleUpdate(details, geometryState),
        onScaleEnd: (details) => _handleScaleEnd(details, geometryState),
        child: _buildCustomPaint(context, geometryState),
      ),
    );
  }

  /// Builds the custom paint area for geometry rendering
  Widget _buildCustomPaint(BuildContext context, GeometryState geometryState) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: CustomPaint(
        key: const Key('geometry_canvas'),
        painter: GeometryPainter(geometryState),
        size: Size.infinite,
      ),
    );
  }

  /// Builds the bottom toolbar with drawing tool buttons
  Widget _buildToolbar(BuildContext context, GeometryState geometryState) {
    return BottomAppBar(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate padding based on container dimensions
          final verticalPadding =
              constraints.maxHeight * _toolbarVerticalPaddingFactor;
          final horizontalPadding =
              constraints.maxWidth * _toolbarHorizontalPaddingFactor;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                _toolRegistry.tools.map((tool) {
                  return ToolButton(
                    padding: EdgeInsets.symmetric(
                      vertical: verticalPadding,
                      horizontal: horizontalPadding,
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
    );
  }

  /// Handles keyboard events and performs corresponding actions
  KeyEventResult _handleKeyEvent(KeyEvent event, GeometryState geometryState) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Handle zoom shortcuts
    if (_handleZoomKeyEvents(event, geometryState)) {
      return KeyEventResult.handled;
    }

    // Handle undo/redo shortcuts
    if (_handleUndoRedoKeyEvents(event, geometryState)) {
      return KeyEventResult.handled;
    }

    // Handle tool selection shortcuts
    if (_handleToolSelectionKeyEvents(event, geometryState)) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Handles zoom-related keyboard shortcuts
  bool _handleZoomKeyEvents(KeyEvent event, GeometryState geometryState) {
    if (event.logicalKey == LogicalKeyboardKey.equal ||
        event.logicalKey == LogicalKeyboardKey.add) {
      geometryState.zoomIn();
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.minus ||
        event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
      geometryState.zoomOut();
      return true;
    }
    return false;
  }

  /// Handles undo/redo keyboard shortcuts
  bool _handleUndoRedoKeyEvents(KeyEvent event, GeometryState geometryState) {
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      geometryState.undo();
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      geometryState.redo();
      return true;
    }
    return false;
  }

  /// Handles tool selection keyboard shortcuts
  bool _handleToolSelectionKeyEvents(
    KeyEvent event,
    GeometryState geometryState,
  ) {
    final tool = _toolRegistry.findToolForKeyEvent(event);
    if (tool != null) {
      geometryState.setTool(tool.type);
      return true;
    }
    return false;
  }

  /// Handles tap gesture on canvas
  void _handleTapDown(TapDownDetails details, GeometryState state) {
    state.currentTool.onTapDown(details, state);
  }

  /// Handles scale/pan start gesture on canvas
  void _handleScaleStart(ScaleStartDetails details, GeometryState state) {
    state.currentTool.onScaleStart(details, state);
  }

  /// Handles scale/pan update gesture on canvas
  void _handleScaleUpdate(ScaleUpdateDetails details, GeometryState state) {
    state.currentTool.onScaleUpdate(details, state);
  }

  /// Handles scale/pan end gesture on canvas
  void _handleScaleEnd(ScaleEndDetails details, GeometryState state) {
    state.currentTool.onScaleEnd(details, state);
  }
}
