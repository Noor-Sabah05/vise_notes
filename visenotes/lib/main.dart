import 'package:flutter/material.dart';
import 'services/recording_service.dart';
import 'screens/home_screen.dart';
import 'screens/transcripts_screen.dart';
import 'screens/events_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/recordings_screen.dart';
import 'screens/save_screen.dart';
import 'screens/category_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RecordingService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ViseNotes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9859FF)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MainShell(),
      onGenerateRoute: (settings) {
        if (settings.name == '/save') {
          final args = settings.arguments;
          if (args is SaveScreenArguments) {
            return MaterialPageRoute(
              builder: (context) => SaveScreen(
                transcript: args.transcript,
                selectedFile: args.selectedFile,
                fileName: args.fileName,
                selectedCategory: args.selectedCategory,
              ),
            );
          }
          if (args is String?) {
            return MaterialPageRoute(
              builder: (context) => SaveScreen(transcript: args),
            );
          }
          return MaterialPageRoute(builder: (context) => const SaveScreen());
        }
        return null;
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    const HomeScreen(),
    const CategoryScreen(),
    const TranscriptsScreen(),
    const RecordingsScreen(),
    const EventsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Transcripts'),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Records'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        type: BottomNavigationBarType.shifting,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF9859FF),
        unselectedItemColor: Colors.grey,
        elevation: 8,
      ),
    );
  }
}
