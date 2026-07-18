// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/app_provider.dart';
import 'screens/budget_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/learning_screen.dart';
import 'services/notification_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // init() never throws, but guard anyway so the app always reaches runApp().
  try {
    await NotificationService.instance.init();
  } catch (_) {}
  runApp(ChangeNotifierProvider(create: (_) => AppProvider()..load(), child: const DisciplineApp()));
}

class DisciplineApp extends StatelessWidget {
  const DisciplineApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discipline',
      theme: appTheme(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR')],
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadName();
    // Request notification + exact-alarm permission once the UI is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.requestPermissions();
    });
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString('user_name') ?? '');
    if (_userName.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _askName(first: true));
    }
  }

  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    setState(() => _userName = name);
  }

  void _askName({bool first = false}) {
    final ctrl = TextEditingController(text: _userName);
    showDialog(
      context: context,
      barrierDismissible: !first,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(first ? 'Bienvenue ! 👋' : 'Modifier mon nom complet',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (first)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Comment puis-je t\'appeler ?',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54)),
              ),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Ton prénom', hintText: 'Judicael', prefixIcon: Icon(Icons.person_outline)),
            ),
          ],
        ),
        actions: [
          if (!first) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) { _saveName(name); Navigator.pop(context); }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  final _screens = const [BudgetScreen(), TasksScreen(), LearningScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bandeau nom utilisateur sur le premier onglet
          // if (_index == 0 && _userName.isNotEmpty)
          //   Container(
          //     width: double.infinity,
          //     color: kDark,
          //     padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          //     child: Row(
          //       children: [
          //         Text('${_greeting()}, $_userName 👋',
          //             style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
          //         const Spacer(),
          //         GestureDetector(
          //           onTap: () => _askName(),
          //           child: const Icon(Icons.edit, color: Colors.white38, size: 16),
          //         ),
          //       ],
          //     ),
          //   ),
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x15000000), width: 0.5))),
            child: BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Budget'),
                BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: 'Tâches'),
                BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'Apprentissage'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
