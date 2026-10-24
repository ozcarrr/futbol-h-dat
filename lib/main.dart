import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameProvider()..loadInitialState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GameProvider? gameProvider;

  const MyApp({super.key, this.gameProvider});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'FutboLE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A1118),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676), // Pitch neon green
          secondary: Color(0xFFFFD54F), // Trophy Gold
          surface: Color(0xFF14212D),
          error: Color(0xFFFF5252),
          onPrimary: Colors.black,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1A24),
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF15222E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF223545), width: 1),
          ),
        ),
      ),
      home: const HomeScreen(),
    );

    if (_hasAncestorProvider(context)) {
      return app;
    }

    return ChangeNotifierProvider(
      create: (_) => gameProvider ?? (GameProvider()..loadInitialState()),
      child: app,
    );
  }

  bool _hasAncestorProvider(BuildContext context) {
    try {
      Provider.of<GameProvider>(context, listen: false);
      return true;
    } catch (_) {
      return false;
    }
  }
}
