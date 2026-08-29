// lib/features/claims/claims_tab.dart
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../scores/score_header.dart';
import '../puzzle/daily_puzzle_card.dart';
import 'claim_card.dart';
import 'claim_detail_screen.dart';

typedef ClaimsData = ({
  List<dynamic> claims,
  List<dynamic> saved,
  List<dynamic> rated,
  Map<String, dynamic>? score,
  Map<String, dynamic>? puzzle,
});

class ClaimsTab extends StatefulWidget {
  const ClaimsTab({super.key});

  @override
  State<ClaimsTab> createState() => _ClaimsTabState();
}

class _ClaimsTabState extends State<ClaimsTab>
    with AutomaticKeepAliveClientMixin {
  late Future<ClaimsData> _future;
  bool _ratedExpanded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Fetched separately from the Future.wait below so a puzzle outage
  /// degrades to "no puzzle card" instead of taking the whole feed down.
  Future<Map<String, dynamic>?> _loadPuzzle() async {
    try {
      final res = await ApiClient.instance.dio.get('/v1/puzzle');
      return res.data == null ? null : Map<String, dynamic>.from(res.data);
    } catch (_) {
      return null;
    }
  }

  Future<ClaimsData> _load() async {
    final dio = ApiClient.instance.dio;

    // Kick off first so it runs alongside the two required calls.
    final puzzleFuture = _loadPuzzle();

    final results = await Future.wait([
      dio.get('/v1/claims', queryParameters: {
        'view': 'home',
      }),
      dio.get('/v1/scores/me'),
    ]);

    return (
      claims: (results[0].data['claims'] as List?) ?? [],
      saved: (results[0].data['saved'] as List?) ?? [],
      rated: (results[0].data['recently_rated'] as List?) ?? [],
      score: results[1].data == null
          ? null
          : Map<String, dynamic>.from(results[1].data),
      puzzle: await puzzleFuture,
    );
  }

  Future<void> _toggleSave(Map<String, dynamic> claim) async {
    try {
      await ApiClient.instance.dio.post('/v1/claims/${claim['id']}/save');
      if (mounted) _refresh();
    } catch (_) {}
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _open(Map<String, dynamic> claim) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ClaimDetailScreen(claim: claim)),
    );
    if (changed == true && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<ClaimsData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snap.data;
        final rated = (data?.rated ?? []).cast<Map<String, dynamic>>();
        final saved = (data?.saved ?? []).cast<Map<String, dynamic>>();

        return Column(
          children: [
            // pinned — outside the scroll view
            ScoreHeader(score: data?.score),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: snap.hasError
                    ? ListView(children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Text('Could not load claims.\n${snap.error}',
                              textAlign: TextAlign.center),
                        ),
                      ])
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 100),
                        children: [
                          // top of the feed
                          DailyPuzzleCard(
                            key: ValueKey(
                                data?.puzzle?['answer']?['prompt_id']),
                            puzzle: data?.puzzle,
                          ),

                          if (saved.isNotEmpty) ...[
                            _SectionLabel(
                              'Waiting on your rating',
                              trailing: '${saved.length}',
                            ),
                            ...saved.map((c) => ClaimCard(
                                  claim: c,
                                  onTap: () => _open(c),
                                  onToggleSave: () => _toggleSave(c),
                                )),
                          ] else
                            // const _AllCaughtUp(),

                          if (rated.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _CollapsibleHeader(
                              label: 'Recently rated by you',
                              count: rated.length,
                              expanded: _ratedExpanded,
                              onTap: () => setState(
                                  () => _ratedExpanded = !_ratedExpanded),
                            ),
                            if (_ratedExpanded)
                              ...rated.map((c) => ClaimCard(
                                    claim: c,
                                    onTap: () => _open(c),
                                    onToggleSave: () => _toggleSave(c),
                                  )),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {this.trailing});
  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: text.labelSmall),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: UltraColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(trailing!,
                  style: text.labelSmall?.copyWith(letterSpacing: 0)),
            ),
          ],
        ],
      ),
    );
  }
}

class _CollapsibleHeader extends StatelessWidget {
  const _CollapsibleHeader({
    required this.label,
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Row(
          children: [
            Text(label.toUpperCase(), style: text.labelSmall),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: UltraColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: text.labelSmall?.copyWith(letterSpacing: 0)),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: const Icon(Icons.keyboard_arrow_down,
                  size: 20, color: UltraColors.textLow),
            ),
          ],
        ),
      ),
    );
  }
}

// class _AllCaughtUp extends StatelessWidget {
//   const _AllCaughtUp();

//   @override
//   Widget build(BuildContext context) {
//     final text = Theme.of(context).textTheme;
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(20, 44, 20, 32),
//       child: Column(
//         children: [
//           // const Icon(Icons.check_circle_outline,
//           //     size: 34, color: UltraColors.accepted),
//           // const SizedBox(height: 14),
//           // Text("You're caught up", style: text.titleSmall),
//           // const SizedBox(height: 6),
//           // Text(
//           //   'Nothing new to rate right now.',
//           //   textAlign: TextAlign.center,
//           //   style: text.bodySmall?.copyWith(color: UltraColors.textLow),
//           // ),
//         ],
//       ),
//     );
//   }
// }