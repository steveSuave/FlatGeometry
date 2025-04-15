import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geometry_app/models/geometry_state.dart';
import 'package:geometry_app/tools/geometry_tool.dart';
import 'package:geometry_app/tools/tool_factory.dart';
import 'package:geometry_app/tools/tool_registry.dart';
import 'package:geometry_app/tools/tools.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([GeometryState])
import 'tool_test.mocks.dart';

void main() {
  group('Tool Factory Pattern Tests', () {
    late ToolFactory toolFactory;
    late ToolRegistry toolRegistry;

    setUp(() {
      toolFactory = const ToolFactory();
      toolRegistry = ToolRegistry(toolFactory: toolFactory);
    });

    test('ToolFactory creates correct tool instances', () {
      final pointTool = toolFactory.createTool(ToolType.point);
      final lineTool = toolFactory.createTool(ToolType.line);
      final circleTool = toolFactory.createTool(ToolType.circle);
      final selectTool = toolFactory.createTool(ToolType.select);
      final panTool = toolFactory.createTool(ToolType.pan);

      expect(pointTool, isA<PointTool>());
      expect(lineTool, isA<LineTool>());
      expect(circleTool, isA<CircleTool>());
      expect(selectTool, isA<SelectTool>());
      expect(panTool, isA<PanTool>());

      expect(pointTool.type, equals(ToolType.point));
      expect(lineTool.type, equals(ToolType.line));
      expect(circleTool.type, equals(ToolType.circle));
      expect(selectTool.type, equals(ToolType.select));
      expect(panTool.type, equals(ToolType.pan));
    });

    test('ToolRegistry creates tools using factory', () {
      final pointTool = toolRegistry.createTool(ToolType.point);
      final lineTool = toolRegistry.createTool(ToolType.line);

      expect(pointTool, isA<PointTool>());
      expect(lineTool, isA<LineTool>());
    });

    test('ToolRegistry finds tool definitions correctly', () {
      final pointToolDef = toolRegistry.getToolByType(ToolType.point);
      final lineToolDef = toolRegistry.getToolByType(ToolType.line);

      expect(pointToolDef.type, equals(ToolType.point));
      expect(pointToolDef.label, equals('Point'));
      expect(pointToolDef.shortcutKey, equals('p'));

      expect(lineToolDef.type, equals(ToolType.line));
      expect(lineToolDef.label, equals('Line'));
      expect(lineToolDef.shortcutKey, equals('l'));
    });
  });

  group('Tool Behavior Tests', () {
    late MockGeometryState mockState;
    late ToolFactory toolFactory;

    setUp(() {
      mockState = MockGeometryState();
      toolFactory = const ToolFactory();
    });

    test('PointTool calls addPoint on tap', () {
      final pointTool = toolFactory.createTool(ToolType.point);
      final details = TapDownDetails(
        globalPosition: const Offset(10, 10),
        localPosition: const Offset(10, 10),
      );

      // Set up expectations
      when(mockState.clearSelection()).thenReturn(null);
      when(mockState.addPoint(any)).thenReturn(null);

      // Execute tool action
      pointTool.onTapDown(details, mockState);

      // Verify the expected methods were called
      verify(mockState.clearSelection()).called(1);
      verify(mockState.addPoint(details.localPosition)).called(1);
    });

    test('LineTool starts line on first tap', () {
      final lineTool = toolFactory.createTool(ToolType.line);
      final details = TapDownDetails(
        globalPosition: const Offset(10, 10),
        localPosition: const Offset(10, 10),
      );

      // Set up expectations
      when(mockState.clearSelection()).thenReturn(null);
      when(mockState.tempStartPoint).thenReturn(null);
      when(mockState.startLine(any)).thenReturn(null);

      // Execute tool action
      lineTool.onTapDown(details, mockState);

      // Verify the expected methods were called
      verify(mockState.clearSelection()).called(1);
      verify(mockState.tempStartPoint).called(1);
      verify(mockState.startLine(details.localPosition)).called(1);
      verifyNever(mockState.completeLine(any));
    });

    test('SelectTool selects object on tap', () {
      final selectTool = toolFactory.createTool(ToolType.select);
      final details = TapDownDetails(
        globalPosition: const Offset(10, 10),
        localPosition: const Offset(10, 10),
      );

      // Set up expectations
      when(mockState.findObjectAtPosition(any)).thenReturn(null);
      when(mockState.selectObject(any)).thenReturn(null);

      // Execute tool action
      selectTool.onTapDown(details, mockState);

      // Verify the expected methods were called
      verify(mockState.findObjectAtPosition(details.localPosition)).called(1);
      verify(mockState.selectObject(null)).called(1);
    });
  });
}
