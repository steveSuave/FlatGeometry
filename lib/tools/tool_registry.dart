import 'package:flutter/material.dart';
import 'tool_definition.dart';
import 'geometry_tool.dart';
import 'tool_factory.dart';

class ToolRegistry {
  final ToolFactory _toolFactory;

  ToolRegistry({ToolFactory? toolFactory})
    : _toolFactory = toolFactory ?? const ToolFactory();

  // Singleton pattern
  static final ToolRegistry _instance = ToolRegistry();
  static ToolRegistry get instance => _instance;

  // Define all tools here - this is now the SINGLE place to add new tools
  final List<ToolDefinition> tools = [
    const ToolDefinition(
      type: ToolType.point,
      label: 'Point',
      icon: Icons.fiber_manual_record,
      shortcutKey: 'p',
      tooltip: 'Point (P)',
    ),
    const ToolDefinition(
      type: ToolType.line,
      label: 'Line',
      icon: Icons.horizontal_rule,
      shortcutKey: 'l',
      tooltip: 'Line (L)',
    ),
    const ToolDefinition(
      type: ToolType.circle,
      label: 'Circle',
      icon: Icons.circle_outlined,
      shortcutKey: 'c',
      tooltip: 'Circle (C)',
    ),
    const ToolDefinition(
      type: ToolType.select,
      label: 'Select',
      icon: Icons.touch_app,
      shortcutKey: 's',
      tooltip: 'Select & Drag (S)',
    ),
    const ToolDefinition(
      type: ToolType.pan,
      label: 'Translate',
      icon: Icons.pan_tool,
      shortcutKey: 't',
      tooltip: 'Translate (T)',
    ),
  ];

  // Find a tool by type
  ToolDefinition getToolByType(ToolType type) {
    return tools.firstWhere((tool) => tool.type == type);
  }

  // Find a tool by keyboard event
  ToolDefinition? findToolForKeyEvent(KeyEvent event) {
    for (var tool in tools) {
      if (tool.matchesKeyEvent(event)) {
        return tool;
      }
    }
    return null;
  }

  // Create a concrete tool implementation by type
  Tool createTool(ToolType type) {
    return _toolFactory.createTool(type);
  }
}
