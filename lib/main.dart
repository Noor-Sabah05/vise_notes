import 'package:flutter/material.dart';
import 'screens/category_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NoteTakerApp());
}

class NoteTakerApp extends StatelessWidget {
  const NoteTakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Note Taker',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Serif', // Matches the formal text style in your screenshots
      ),
      home: CategoryScreen(),
    );
  }
}