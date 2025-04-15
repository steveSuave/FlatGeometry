import 'geometry_tool.dart';
import 'tools.dart';

class ToolFactory {
  const ToolFactory();

  Tool createTool(ToolType type) {
    switch (type) {
      case ToolType.point:
        return const PointTool();
      case ToolType.line:
        return const LineTool();
      case ToolType.circle:
        return const CircleTool();
      case ToolType.select:
        return const SelectTool();
      case ToolType.pan:
        return const PanTool();
    }
  }
}
