import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'geometry_tool.dart';

class ToolDefinition {
  final GeometryTool type;
  final String label;
  final IconData icon;
  final String shortcutKey;
  final String tooltip;

  const ToolDefinition({
    required this.type,
    required this.label,
    required this.icon,
    required this.shortcutKey,
    required this.tooltip,
  });

  // Check if a KeyEvent matches this tool's shortcut
  bool matchesKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.character != null) {
      return event.character?.toLowerCase() == shortcutKey.toLowerCase();
    }
    return false;
  }
}
