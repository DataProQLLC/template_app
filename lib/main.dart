// lib/main.dart
import 'package:flutter/material.dart';
import 'package:ultra_app/features/shell/home_shell.dart';
import 'core/config.dart';
import 'core/db.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/auth_screen.dart';
import 'core/theme.dart';

// flutter run --dart-define=ENV=local
// flutter run --dart-define=ENV=dev
// flutter run --dart-define=ENV=stage
// build out device..
// flutter run --release -d "Joseph's iPhone" --dart-define=ENV=dev

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const UltraApp());
}

class UltraApp extends StatelessWidget {
  const UltraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ultra',
      debugShowCheckedModeBanner: !AppConfig.isProd,
      theme: ultraTheme(),
      darkTheme: ultraTheme(),
      themeMode: ThemeMode.dark,
      home: const _Launch(),
    );
  }
}

class _Launch extends StatefulWidget {
  const _Launch();
  @override
  State<_Launch> createState() => _LaunchState();
}

class _LaunchState extends State<_Launch> {
  final _repo = AuthRepository();
  late Future<bool> _session;

  @override
  void initState() {
    super.initState();
    _session = _repo.hasValidSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _session,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snap.data == true ? const HomeShell() : const AuthScreen();
      },
    );
  }
}