// lib/features/profile/profile_tab.dart
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../auth/auth_repository.dart';
import '../auth/auth_screen.dart';

typedef ProfileData = ({
  Map<String, dynamic> user,
  Map<String, dynamic>? score,
});

Color _trustColor(double t) {
  if (t >= 0.90) return UltraColors.accepted;
  if (t >= 0.70) return UltraColors.contested;
  if (t >= 0.50) return const Color(0xFFE07B39);
  return UltraColors.rejected;
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab>
    with AutomaticKeepAliveClientMixin {
  late Future<ProfileData> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ProfileData> _load() async {
    final dio = ApiClient.instance.dio;
    final results = await Future.wait([
      dio.get('/v1/users/me'),
      dio.get('/v1/scores/me'),
    ]);
    return (
      user: Map<String, dynamic>.from(results[0].data),
      score: results[1].data == null
          ? null
          : Map<String, dynamic>.from(results[1].data),
    );
  }

  Future<void> _signout() async {
    await AuthRepository().signout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final text = Theme.of(context).textTheme;

    return FutureBuilder<ProfileData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || snap.data == null) {
          return Center(
            child: Text('Could not load profile.', style: text.bodySmall),
          );
        }

        final u = snap.data!.user;
        final s = snap.data!.score;
        final username = (u['username'] ?? '') as String;
        final joined = DateTime.tryParse(u['created_at'] ?? '');

        return RefreshIndicator(
          onRefresh: () async => setState(() {
            _future = _load();
          }),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              // identity
              Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: UltraColors.accepted.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: UltraColors.accepted,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username, style: text.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          joined != null
                              ? 'Member since ${_month(joined)} ${joined.year}'
                              : '',
                          style: text.bodySmall?.copyWith(
                            color: UltraColors.textLow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              _SectionLabel('Rating record'),
              const SizedBox(height: 10),
              _StatGrid(score: s),

              const SizedBox(height: 28),

              _SectionLabel('How scoring works'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: UltraColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: UltraColors.border),
                ),
                child: Text(
                  'Your record reflects two things: whether you spot views that '
                  'turn out to be more common than people expect, and how often '
                  'your calls hold up once a claim resolves.',
                  style: text.bodySmall?.copyWith(height: 1.55),
                ),
              ),

              const SizedBox(height: 28),

              _SectionLabel('Account'),
              const SizedBox(height: 10),
              _Tile(
                icon: Icons.notifications_none,
                label: 'Notifications',
                onTap: () {},
              ),
              _Tile(
                icon: Icons.shield_outlined,
                label: 'Privacy',
                onTap: () {},
              ),
              _Tile(
                icon: Icons.logout,
                label: 'Sign out',
                danger: true,
                onTap: _signout,
              ),

              // const SizedBox(height: 24),
              // Center(
              //   child: Text(
              //     'id ${u['id']}',
              //     style: text.bodySmall?.copyWith(
              //       color: UltraColors.textLow,
              //       fontSize: 11,
              //     ),
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }

  String _month(DateTime d) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][d.month - 1];
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) =>
      Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall);
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.score});
  final Map<String, dynamic>? score;

  @override
  Widget build(BuildContext context) {
    final s = score;
    final trust = (s?['trust_score'] as num?)?.toDouble();
    final rated = (s?['ratings_scored'] ?? 0) as int;
    final resolved = (s?['resolved_count'] ?? 0) as int;
    final accuracy = (s?['accuracy'] as num?)?.toDouble();
    final wins = (s?['contrarian_wins'] ?? 0) as int;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Stat(
                value: trust != null ? '${(trust * 100).round()}' : '—',
                label: 'Trust score',
                accent: trust != null ? _trustColor(trust) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(value: '$rated', label: 'Claims rated'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Stat(
                value: accuracy != null ? '${(accuracy * 100).round()}%' : '—',
                label: 'Called right',
                accent: accuracy != null ? _trustColor(accuracy) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                value: '$wins',
                label: 'Right vs the crowd',
                accent: wins > 0 ? UltraColors.contested : null,
              ),
            ),
          ],
        ),
        if (resolved > 0) ...[
          const SizedBox(height: 10),
          Text(
            'Based on $resolved resolved ${resolved == 1 ? "claim" : "claims"}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: UltraColors.textLow,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.accent});
  final String value;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UltraColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: UltraColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: accent ?? UltraColors.textHigh,
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: text.bodySmall?.copyWith(
              color: UltraColors.textLow,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: UltraColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Icon(icon, size: 19, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: color, fontSize: 14),
                  ),
                ),
                if (!danger)
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: UltraColors.textLow,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
