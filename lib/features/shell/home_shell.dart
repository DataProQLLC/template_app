import 'package:flutter/material.dart';
import '../auth/auth_repository.dart';
import '../auth/auth_screen.dart';
import '../activity/activity_tab.dart';
import 'dart:ui';
import '../../core/theme.dart';
import '../notifications/notification_bell.dart';
import 'app_drawer.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  Future<void> _signout() async {
    await AuthRepository().signout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      drawer: const AppDrawer(),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accepted.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Text('U',
                style: TextStyle(
                  color: AppColors.accepted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                )),
          ),
          const SizedBox(width: 10),
          const Text('Ultra', style: TextStyle(fontSize: 17)),
        ]),
        actions: [
          NotificationBell(),
          SizedBox(width: 6),
          if (_index == 3)
            IconButton(icon: const Icon(Icons.logout), onPressed: _signout),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [ActivityTab()],
      ),
      bottomNavigationBar: _FloatingNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Home'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 62,
decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_items.length, (i) {
                final (outline, filled, label) = _items[i];
                final selected = i == index;
                return Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? filled : outline,
                          size: 21,
                          color: selected
                              ? AppColors.accepted
                              : AppColors.textLow,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.2,
                            color: selected
                                ? AppColors.accepted
                                : AppColors.textLow,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}