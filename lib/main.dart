import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/geometry_app.dart';
import 'models/geometry_state.dart';
import 'models/theme_state.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GeometryState()),
        ChangeNotifierProvider(create: (_) => ThemeState()),
      ],
      child: const GeometryApp(),
    ),
  );
}
