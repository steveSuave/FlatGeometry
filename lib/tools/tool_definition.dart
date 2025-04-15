import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'geometry_tool.dart';

class ToolDefinition {
  final ToolType type;
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

  bool matchesKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.character != null) {
      return event.character?.toLowerCase() == shortcutKey.toLowerCase();
    }
    return false;
  }
}
