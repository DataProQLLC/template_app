import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../auth/auth_repository.dart';
import '../auth/auth_screen.dart';
import '../profile/profile_tab.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

Future<void> _signout(BuildContext context) async {
    final nav = Navigator.of(context, rootNavigator: true);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: UltraColors.surface,
        title: const Text('Sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: UltraColors.rejected,
              foregroundColor: UltraColors.ink,
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await AuthRepository().signout();

    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.62,
      backgroundColor: UltraColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
              child: Row(children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: UltraColors.accepted.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Text('U',
                      style: TextStyle(
                        color: UltraColors.accepted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      )),
                ),
                const SizedBox(width: 10),
                Text('Ultra', style: text.titleMedium),
              ]),
            ),
            _Item(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Profile')),
                      body: const ProfileTab(),
                    ),
                  ),
                );
              },
            ),
            // _Item(
            //   icon: Icons.bookmark_border,
            //   label: 'Saved claims',
            //   onTap: () => Navigator.pop(context),
            // ),
            // _Item(
            //   icon: Icons.settings_outlined,
            //   label: 'Settings',
            //   onTap: () => Navigator.pop(context),
            // ),
            const Spacer(),
            const Divider(height: 1, color: UltraColors.border),
            _Item(
              icon: Icons.logout,
              label: 'Sign out',
              danger: true,
              onTap: () {
                Navigator.pop(context);
                _signout(context);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: Text('v0.1.0',
                  style: text.bodySmall
                      ?.copyWith(color: UltraColors.textLow, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? UltraColors.rejected : UltraColors.textMid;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(color: color, fontSize: 14.5)),
        ]),
      ),
    );
  }
}