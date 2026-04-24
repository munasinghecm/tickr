import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'state/todo_state.dart';
import 'screens/auth_screen.dart';
import 'screens/todo_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TickrApp());
}

class TickrApp extends StatefulWidget {
  const TickrApp({super.key});

  @override
  State<TickrApp> createState() => _TickrAppState();
}

class _TickrAppState extends State<TickrApp> {
  final TodoState _todoState = TodoState();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _todoState,
      builder: (context, _) {
        return MaterialApp(
          title: 'Tickr - Smart Todo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.dark,
            ),
          ),
          themeMode: ThemeMode.system,
          home: _todoState.isAuthenticated
              ? TodoScreen(state: _todoState)
              : AuthScreen(state: _todoState),
        );
      },
    );
  }
}
