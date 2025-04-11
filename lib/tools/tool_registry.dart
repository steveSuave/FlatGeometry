import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tool_definition.dart';
import 'geometry_tool.dart';

class ToolRegistry {
  // Private constructor to prevent instantiation
  ToolRegistry._();

  // Singleton instance
  static final ToolRegistry instance = ToolRegistry._();

  // Define all tools here - this is now the SINGLE place to add new tools
  final List<ToolDefinition> tools = [
    const ToolDefinition(
      type: GeometryTool.point,
      label: 'Point',
      icon: Icons.fiber_manual_record,
      shortcutKey: 'p',
      tooltip: 'Point (P)',
    ),
    const ToolDefinition(
      type: GeometryTool.line,
      label: 'Line',
      icon: Icons.horizontal_rule,
      shortcutKey: 'l',
      tooltip: 'Line (L)',
    ),
    const ToolDefinition(
      type: GeometryTool.circle,
      label: 'Circle',
      icon: Icons.circle_outlined,
      shortcutKey: 'c',
      tooltip: 'Circle (C)',
    ),
    const ToolDefinition(
      type: GeometryTool.pan,
      label: 'Translate',
      icon: Icons.pan_tool,
      shortcutKey: 't',
      tooltip: 'Translate (T)',
    ),
  ];

  // Find a tool by type
  ToolDefinition getToolByType(GeometryTool type) {
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
}
