import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:geometry_app/app/geometry_app.dart';
import 'package:geometry_app/widgets/geometry_canvas.dart';
import 'package:geometry_app/widgets/tool_button.dart';
import 'package:geometry_app/painters/geometry_painter.dart';
import 'package:geometry_app/models/point.dart';
import 'package:geometry_app/models/line.dart';
import 'package:geometry_app/utils/math_utils.dart';
import 'dart:math' as math;

void main() {
  group('GeometryApp', () {
    testWidgets('should render with light theme by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const GeometryApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.light);
    });

    testWidgets('should toggle theme when theme button is pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const GeometryApp());

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
    testWidgets('should start with point tool selected by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: GeometryCanvas(toggleTheme: () {})),
      );

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
      await tester.pumpWidget(
        MaterialApp(home: GeometryCanvas(toggleTheme: () {})),
      );

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
      await tester.pumpWidget(
        MaterialApp(home: GeometryCanvas(toggleTheme: () {})),
      );

      // Find the canvas using the key
      final canvasFinder = find.byKey(const Key('geometry_canvas'));

      // Tap on the canvas
      await tester.tap(canvasFinder);
      await tester.pump();

      // Find the CustomPaint widget
      final customPaint = tester.widget<CustomPaint>(
        find.byKey(const Key('geometry_canvas')),
      );
      final painter = customPaint.painter as GeometryPainter;

      // Verify a point was created
      expect(painter.objects.length, 1);
      expect(painter.objects.first is Point, true);
    });

    testWidgets('should handle keyboard shortcuts for tools', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: GeometryCanvas(toggleTheme: () {})),
      );

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
      await tester.pumpWidget(
        MaterialApp(home: GeometryCanvas(toggleTheme: () {})),
      );

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

      // Get the CustomPaint widget and its painter
      final customPaint = tester.widget<CustomPaint>(
        find.byKey(const Key('geometry_canvas')),
      );
      final painter = customPaint.painter as GeometryPainter;

      // Verify objects were created (2 points + 1 line = 3 objects)
      expect(painter.objects.length, 3);
      expect(painter.objects.last is Line, true);
    });

    testWidgets('should handle undo correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: GeometryCanvas(toggleTheme: () {})),
      );

      // Create a point using the keyed canvas
      final canvasFinder = find.byKey(const Key('geometry_canvas'));
      await tester.tap(canvasFinder);
      await tester.pump();

      // Find and tap the undo button
      final undoButton = find.byTooltip('Undo (<-)');
      await tester.tap(undoButton);
      await tester.pump();

      // Get the CustomPaint widget and its painter
      final customPaint = tester.widget<CustomPaint>(
        find.byKey(const Key('geometry_canvas')),
      );
      final painter = customPaint.painter as GeometryPainter;

      // Verify the point was removed
      expect(painter.objects.isEmpty, true);
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
    test('shouldRepaint returns true when inputs change', () {
      final objects1 = [Point(0, 0)];
      final objects2 = [Point(10, 10)];
      final offset1 = Offset.zero;
      final offset2 = const Offset(5, 5);

      final painter1 = GeometryPainter(objects1, offset1, 1.0);

      // Test objects change
      expect(
        painter1.shouldRepaint(GeometryPainter(objects2, offset1, 1.0)),
        true,
      );

      // Test pan offset change
      expect(
        painter1.shouldRepaint(GeometryPainter(objects1, offset2, 1.0)),
        true,
      );

      // Test zoom change
      expect(
        painter1.shouldRepaint(GeometryPainter(objects1, offset1, 2.0)),
        true,
      );

      // Test no change
      expect(
        painter1.shouldRepaint(GeometryPainter(objects1, offset1, 1.0)),
        false,
      );
    });
  });
}
