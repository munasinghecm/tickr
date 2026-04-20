import 'package:flutter/material.dart';
import 'state/todo_state.dart';
import 'screens/todo_screen.dart';

void main() {
  runApp(const TickrApp());
}

class TickrApp extends StatefulWidget {
  const TickrApp({super.key});

  @override
  State<TickrApp> createState() => _TickrAppState();
}

class _TickrAppState extends State<TickrApp> {
  // Initialize state here to persist it across hot reloads if possible, 
  // though for simple apps in main it resets on hot restart.
  final TodoState _todoState = TodoState();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tickr - Smart Todo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        // Add some typography styling
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system, // Support light/dark mode based on system
      home: TodoScreen(state: _todoState),
    );
  }
}
