import 'package:flutter/material.dart';
import 'geometry_tool.dart';
import '../models/geometry_state.dart';

class PointTool extends Tool {
  const PointTool() : super(ToolType.point);

  @override
  void onTapDown(TapDownDetails details, GeometryState state) {
    state.clearSelection();
    state.addPoint(details.localPosition);
  }

  @override
  void onScaleStart(ScaleStartDetails details, GeometryState state) {
    state.setBaseScaleFactor(state.zoomScale);
  }

  @override
  void onScaleUpdate(ScaleUpdateDetails details, GeometryState state) {
    if (details.scale != 1.0) {
      state.updateZoom(details.scale);
    }
  }

  @override
  void onScaleEnd(ScaleEndDetails details, GeometryState state) {
    // No specific action needed
  }
}

class LineTool extends Tool {
  const LineTool() : super(ToolType.line);

  @override
  void onTapDown(TapDownDetails details, GeometryState state) {
    state.clearSelection();
    if (state.tempStartPoint == null) {
      state.startLine(details.localPosition);
    } else {
      state.completeLine(details.localPosition);
    }
  }

  @override
  void onScaleStart(ScaleStartDetails details, GeometryState state) {
    state.setBaseScaleFactor(state.zoomScale);
  }

  @override
  void onScaleUpdate(ScaleUpdateDetails details, GeometryState state) {
    if (details.scale != 1.0) {
      state.updateZoom(details.scale);
    }
  }

  @override
  void onScaleEnd(ScaleEndDetails details, GeometryState state) {
    // No specific action needed
  }
}

class CircleTool extends Tool {
  const CircleTool() : super(ToolType.circle);

  @override
  void onTapDown(TapDownDetails details, GeometryState state) {
    state.clearSelection();
    if (state.tempStartPoint == null) {
      state.startCircle(details.localPosition);
    } else {
      state.completeCircle(details.localPosition);
    }
  }

  @override
  void onScaleStart(ScaleStartDetails details, GeometryState state) {
    state.setBaseScaleFactor(state.zoomScale);
  }

  @override
  void onScaleUpdate(ScaleUpdateDetails details, GeometryState state) {
    if (details.scale != 1.0) {
      state.updateZoom(details.scale);
    }
  }

  @override
  void onScaleEnd(ScaleEndDetails details, GeometryState state) {
    // No specific action needed
  }
}

class SelectTool extends Tool {
  const SelectTool() : super(ToolType.select);

  @override
  void onTapDown(TapDownDetails details, GeometryState state) {
    final selectedObject = state.findObjectAtPosition(details.localPosition);
    state.selectObject(selectedObject);
  }

  @override
  void onScaleStart(ScaleStartDetails details, GeometryState state) {
    state.setBaseScaleFactor(state.zoomScale);

    if (state.selectedObject != null) {
      state.startDrag(details.localFocalPoint);
    }
  }

  @override
  void onScaleUpdate(ScaleUpdateDetails details, GeometryState state) {
    if (state.isDragging &&
        state.selectedObject != null &&
        details.scale == 1.0) {
      state.updateDrag(details.localFocalPoint);
    } else if (details.scale != 1.0) {
      state.updateZoom(details.scale);
    }
  }

  @override
  void onScaleEnd(ScaleEndDetails details, GeometryState state) {
    if (state.isDragging) {
      state.endDrag();
    }
  }
}

class PanTool extends Tool {
  const PanTool() : super(ToolType.pan);

  @override
  void onTapDown(TapDownDetails details, GeometryState state) {
    state.clearSelection();
  }

  @override
  void onScaleStart(ScaleStartDetails details, GeometryState state) {
    state.setBaseScaleFactor(state.zoomScale);
  }

  @override
  void onScaleUpdate(ScaleUpdateDetails details, GeometryState state) {
    if (details.scale != 1.0) {
      state.updateZoom(details.scale);
    } else {
      state.updatePan(details.focalPointDelta);
    }
  }

  @override
  void onScaleEnd(ScaleEndDetails details, GeometryState state) {
    // No specific action needed
  }
}
