import 'package:flutter/material.dart';
import 'screens/order_screen.dart';
import 'screens/belt_screen.dart';
import 'services/quote_service.dart';

void main() {
  runApp(const MidtermApiApp());
}

class MidtermApiApp extends StatelessWidget {
  const MidtermApiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CC 105 - REST API Integration',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // DWCL deep royal blue
          secondary: const Color(0xFFD97706), // warm amber
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          clipBehavior: Clip.antiAlias,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          secondary: const Color(0xFFF59E0B),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          clipBehavior: Clip.antiAlias,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final QuoteService _quoteService = QuoteService();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      OrderScreen(quoteService: _quoteService),
      BeltScreen(quoteService: _quoteService),
    ];
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF1E3A8A)),
            SizedBox(width: 8),
            Text('CC 105 Activity Info'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Future, Stream & REST API Integration',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• API: DummyJSON Quotes API'),
              Text('• Auth: None (No API key, No credit card)'),
              Text('• Screen 1 (The Order): FutureBuilder (fetches list once)'),
              Text('• Screen 2 (The Belt): StreamBuilder (auto-updates every 5s)'),
              Text('• Survives Airplane Mode without crashing'),
              Text('• All responses parsed into typed Dart objects with fromJson'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'info_fab',
        tooltip: 'Activity Info',
        onPressed: _showInfoDialog,
        child: const Icon(Icons.info_outline),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'The Order (Future)',
          ),
          NavigationDestination(
            icon: Icon(Icons.sync_rounded),
            selectedIcon: Icon(Icons.sync),
            label: 'The Belt (Stream)',
          ),
        ],
      ),
    );
  }
}
