import 'package:flutter/material.dart';
import '../widgets/geometry_canvas.dart';

class GeometryApp extends StatefulWidget {
  const GeometryApp({super.key});

  @override
  State<GeometryApp> createState() => _GeometryAppState();
}

class _GeometryAppState extends State<GeometryApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  ThemeData _buildThemeData(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      ),
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Geometry',
      themeMode: _themeMode,
      theme: _buildThemeData(Brightness.light),
      darkTheme: _buildThemeData(Brightness.dark),
      home: GeometryCanvas(toggleTheme: toggleTheme),
    );
  }
}
