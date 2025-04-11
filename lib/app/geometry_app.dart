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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Geometry',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: GeometryCanvas(toggleTheme: toggleTheme),
    );
  }
}
