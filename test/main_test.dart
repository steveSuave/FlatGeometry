import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geometry_app/app/geometry_app.dart';
import 'package:geometry_app/widgets/geometry_canvas.dart';
import 'package:geometry_app/widgets/tool_button.dart';
import 'package:geometry_app/models/geometry_state.dart';
import 'package:geometry_app/models/theme_state.dart';
import 'package:geometry_app/models/point.dart';
import 'package:geometry_app/models/line.dart';
import 'package:geometry_app/models/circle.dart';
import 'package:geometry_app/utils/math_utils.dart';
import 'package:geometry_app/painters/geometry_painter.dart';
import 'dart:math' as math;

void main() {
  group('GeometryApp', () {
    testWidgets('should render with light theme by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => GeometryState()),
            ChangeNotifierProvider(create: (_) => ThemeState()),
          ],
          child: const GeometryApp(),
        ),
      );

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.light);
    });

    testWidgets('should toggle theme when theme button is pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => GeometryState()),
            ChangeNotifierProvider(create: (_) => ThemeState()),
          ],
          child: const GeometryApp(),
        ),
      );

      // Find and tap the theme toggle button
      final themeButtonFinder = find.byTooltip('Toggle theme');
      await tester.tap(themeButtonFinder);
      await tester.pump();

      // Verify the theme has changed
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.dark);
    });
  });

  group('GeometryCanvas', () {
    Widget createTestApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GeometryState()),
          ChangeNotifierProvider(create: (_) => ThemeState()),
        ],
        child: const MaterialApp(home: GeometryCanvas()),
      );
    }

    testWidgets('should start with point tool selected by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());

      // Find tool buttons
      final pointToolButton = find.text('Point (P)');

      // Check that point tool is selected
      final pointButtonIcon = tester.widget<Icon>(
        find.descendant(
          of: find.ancestor(
            of: pointToolButton,
            matching: find.byType(ToolButton),
          ),
          matching: find.byType(Icon),
        ),
      );
      expect(pointButtonIcon.color, isNot(Colors.grey));
    });

    testWidgets('should change tool when tool button is pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());

      // Find the line tool button and tap it
      final lineToolButton = find.text('Line (L)');
      await tester.tap(lineToolButton);
      await tester.pump();

      // Check that line tool is now selected
      final lineButtonIcon = tester.widget<Icon>(
        find.descendant(
          of: find.ancestor(
            of: lineToolButton,
            matching: find.byType(ToolButton),
          ),
          matching: find.byType(Icon),
        ),
      );
      expect(lineButtonIcon.color, isNot(Colors.grey));
    });

    testWidgets('should create point on canvas tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());

      // Find the canvas using the key
      final canvasFinder = find.byKey(const Key('geometry_canvas'));

      // Tap on the canvas
      await tester.tap(canvasFinder);
      await tester.pump();

      // Get the state directly
      final state =
          tester.element(find.byType(GeometryCanvas)).read<GeometryState>();

      // Verify a point was created
      expect(state.objects.length, 1);
      expect(state.objects.first is Point, true);
    });

    testWidgets('should handle keyboard shortcuts for tools', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());

      // Focus the canvas
      final canvas = find.byType(Focus).first;
      await tester.tap(canvas);
      await tester.pump();

      // Send 'l' key event for line tool
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await tester.pump();

      // Instead of checking the private _currentTool property directly,
      // verify that the line tool button is now selected
      final lineToolButton = find.text('Line (L)');
      final lineButtonIcon = tester.widget<Icon>(
        find.descendant(
          of: find.ancestor(
            of: lineToolButton,
            matching: find.byType(ToolButton),
          ),
          matching: find.byType(Icon),
        ),
      );

      // Verify the line tool button is highlighted (selected)
      expect(lineButtonIcon.color, isNot(Colors.grey));
    });

    testWidgets('should create line with two taps', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());

      // Change to line tool
      final lineToolButton = find.text('Line (L)');
      await tester.tap(lineToolButton);
      await tester.pump();

      // Find the canvas with the key
      final canvasFinder = find.byKey(const Key('geometry_canvas'));

      // First tap for start point
      await tester.tap(canvasFinder);
      await tester.pump();

      // Second tap for end point - use a different position
      final canvasCenter = tester.getCenter(canvasFinder);
      await tester.tapAt(canvasCenter.translate(50, 50));
      await tester.pump();

      // Get the state directly
      final state =
          tester.element(find.byType(GeometryCanvas)).read<GeometryState>();

      // Verify objects were created (2 points + 1 line = 3 objects)
      expect(state.objects.length, 3);
      expect(state.objects.last is Line, true);
    });

    testWidgets('should handle undo correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      // Create a point using the keyed canvas
      final canvasFinder = find.byKey(const Key('geometry_canvas'));
      await tester.tap(canvasFinder);
      await tester.pump();

      // Find and tap the undo button
      final undoButton = find.byTooltip('Undo (<-)');
      await tester.tap(undoButton);
      await tester.pump();

      // Get the state directly
      final state =
          tester.element(find.byType(GeometryCanvas)).read<GeometryState>();

      // Verify the point was removed
      expect(state.objects.isEmpty, true);
    });

    testWidgets('should create circle with two taps', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());

      // Switch to circle tool
      final circleToolButton = find.text('Circle (C)');
      await tester.tap(circleToolButton);
      await tester.pump();

      // Find the canvas
      final canvasFinder = find.byKey(const Key('geometry_canvas'));

      // First tap for center point
      await tester.tap(canvasFinder);
      await tester.pump();

      // Second tap for radius
      final canvasCenter = tester.getCenter(canvasFinder);
      await tester.tapAt(canvasCenter.translate(70, 0)); // 70px to the right
      await tester.pump();

      // Get the state directly
      final state =
          tester.element(find.byType(GeometryCanvas)).read<GeometryState>();

      // Verify objects were created (1 center point + 1 circle = 2 objects)
      expect(state.objects.length, 2);
      expect(state.objects.last is Circle, true);
    });

    testWidgets('should select and handle object selection', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());

      // First create a point
      final canvasFinder = find.byKey(const Key('geometry_canvas'));
      await tester.tap(canvasFinder);
      await tester.pump();

      // Switch to selection tool
      final selectToolButton = find.text('Select & Drag (S)');
      await tester.tap(selectToolButton);
      await tester.pump();

      // Select the created point
      await tester.tap(canvasFinder);
      await tester.pump();

      // Get the state directly
      final state =
          tester.element(find.byType(GeometryCanvas)).read<GeometryState>();

      // Verify an object is selected
      expect(state.selectedObject, isNotNull);
      expect(state.selectedObject is Point, true);
      expect(state.selectedObject!.isSelected, true);
    });

    testWidgets('should handle redo after undo', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      // Create a point
      final canvasFinder = find.byKey(const Key('geometry_canvas'));
      await tester.tap(canvasFinder);
      await tester.pump();

      // Undo the point creation
      final undoButton = find.byTooltip('Undo (<-)');
      await tester.tap(undoButton);
      await tester.pump();

      // Verify the point was removed
      var state =
          tester.element(find.byType(GeometryCanvas)).read<GeometryState>();
      expect(state.objects.isEmpty, true);

      // Redo the point creation
      final redoButton = find.byTooltip('Redo (->)');
      await tester.tap(redoButton);
      await tester.pump();

      // Verify the point was restored
      state = tester.element(find.byType(GeometryCanvas)).read<GeometryState>();
      expect(state.objects.length, 1);
      expect(state.objects.first is Point, true);
    });

    testWidgets('should handle zoom operations', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      // Get initial zoom state
      var state =
          tester.element(find.byType(GeometryCanvas)).read<GeometryState>();
      final initialZoom = state.zoomScale;

      // Zoom in
      final zoomInButton = find.byTooltip('Zoom in (+)');
      await tester.tap(zoomInButton);
      await tester.pump();

      // Verify zoom increased
      state = tester.element(find.byType(GeometryCanvas)).read<GeometryState>();
      expect(state.zoomScale, greaterThan(initialZoom));

      // Zoom out
      final zoomOutButton = find.byTooltip('Zoom out (-)');
      await tester.tap(zoomOutButton);
      await tester.pump();

      // Reset zoom and pan
      final resetButton = find.byTooltip('Reset zoom');
      await tester.tap(resetButton);
      await tester.pump();

      // Verify zoom was reset
      state = tester.element(find.byType(GeometryCanvas)).read<GeometryState>();
      expect(state.zoomScale, equals(1.0));
      expect(state.panOffset, equals(Offset.zero));
    });
  });

  group('ToolButton', () {
    testWidgets('should show selected state when isSelected is true', (
      WidgetTester tester,
    ) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolButton(
              icon: Icons.circle_outlined,
              label: 'Circle',
              isSelected: true,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      // Find the icon in selected state
      final icon = tester.widget<Icon>(find.byType(Icon));

      // Get the theme's primary color from context
      final BuildContext context = tester.element(find.byType(Icon));
      final Color primaryColor = Theme.of(context).colorScheme.primary;

      // Check that icon color is primary (selected state)
      expect(icon.color, primaryColor);

      // Tap the button and verify callback was called
      await tester.tap(find.text('Circle'));
      expect(pressed, true);
    });

    testWidgets('should not be highlighted when not selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolButton(
              icon: Icons.circle_outlined,
              label: 'Circle',
              isSelected: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Get the icon and its container
      final icon = tester.widget<Icon>(find.byType(Icon));
      final container =
          find
                  .ancestor(
                    of: find.byType(Icon),
                    matching: find.byType(Container),
                  )
                  .evaluate()
                  .first
                  .widget
              as Container;

      // Get theme onSurface color
      final BuildContext context = tester.element(find.byType(Icon));
      final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;

      // Verify non-selected state
      expect(icon.color, onSurfaceColor);
      expect(container.decoration, isNull);
    });
  });

  group('Helper Functions', () {
    test('getDistance should calculate distance correctly', () {
      // Create test data
      final point = Point(10, 10);
      final position = Offset(13, 14);

      // Calculate expected result using Pythagorean theorem
      final expected = math.sqrt(math.pow(13 - 10, 2) + math.pow(14 - 10, 2));

      // Test the function
      final result = getDistance(position, point);

      // Verify result
      expect(result, expected);
    });
  });

  group('GeometryPainter', () {
    test('shouldRepaint always returns true since it uses Listenable', () {
      final state1 = GeometryState();
      final state2 = GeometryState();

      final painter1 = GeometryPainter(state1) as CustomPainter;
      final painter2 = GeometryPainter(state2) as CustomPainter;

      // Test with different states
      expect(painter1.shouldRepaint(painter2), true);

      // Test with same state
      expect(painter1.shouldRepaint(painter1), true);
    });
  });
}
