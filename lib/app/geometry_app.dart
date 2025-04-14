import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/geometry_canvas.dart';
import '../models/theme_state.dart';

class GeometryApp extends StatelessWidget {
  const GeometryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<ThemeState>(context);

    return MaterialApp(
      title: 'Dynamic Geometry',
      themeMode: themeState.themeMode,
      theme: themeState.buildLightTheme(),
      darkTheme: themeState.buildDarkTheme(),
      home: const GeometryCanvas(),
    );
  }
}
