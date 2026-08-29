import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../rating/rate_sheet.dart';
import '../claims/claim_comments.dart';

class ClaimDetailScreen extends StatefulWidget {
  const ClaimDetailScreen({super.key, required this.claim});
  final Map<String, dynamic> claim;

  @override
  State<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends State<ClaimDetailScreen> {
  late Map<String, dynamic> _claim = widget.claim;
  bool _changed = false;

  bool get _hasRated => _claim['has_rated'] == true;
  bool get _isInformed => _claim['is_informed'] == true;
  bool get _canSee => _hasRated || _isInformed;

  String get _state => _claim['consensus_state'] ?? 'collecting';
  int get _count => (_claim['rating_count'] ?? 0) as int;
  double? get _supported => (_claim['actual_supported'] as num?)?.toDouble();
  double? get _predicted => (_claim['predicted_supported'] as num?)?.toDouble();
  double? get _infoDisputed => (_claim['info_disputed'] as num?)?.toDouble();

  ({String label, String blurb, Color color}) get _verdict {
    if (_state == 'collecting') {
      final needed = (15 - _count).clamp(0, 15);
      return (
        label: 'Collecting ratings',
        blurb: '$needed more ratings before a consensus appears.',
        color: UltraColors.collecting,
      );
    }
    if (_state == 'emerging') {
      return (
        label: 'Early signal',
        blurb: 'Based on $_count ratings — still provisional.',
        color: UltraColors.collecting,
      );
    }
    final s = _supported ?? 0;
    if (s >= 0.75) {
      return (
        label: 'Widely accepted',
        blurb:
            'Most raters accept this, including people who usually disagree.',
        color: UltraColors.accepted,
      );
    }
    if (s <= 0.25) {
      return (
        label: 'Widely rejected',
        blurb: 'Most raters reject this across the board.',
        color: UltraColors.rejected,
      );
    }
    return (
      label: 'Contested',
      blurb: (_infoDisputed ?? 0) > 0.1
          ? 'More people dispute this than the crowd expected.'
          : 'Raters are genuinely split on this one.',
      color: UltraColors.contested,
    );
  }

  Future<void> _reload() async {
    final r = await ApiClient.instance.dio.get('/v1/claims');
    final list = (r.data['claims'] as List?) ?? [];
    final found = list.cast<Map<String, dynamic>>().firstWhere(
          (c) => c['id'] == _claim['id'],
          orElse: () => _claim,
        );
    if (mounted) {
      setState(() {
        _claim = found;
        _changed = true;
      });
    }
  }

  Future<void> _rate() async {
    final saved = await showRateSheet(context, _claim);
    if (saved == true) await _reload();
  }

  Future<void> _reveal() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: UltraColors.surface,
        title: const Text('View without rating?'),
        content: const Text(
          "You'll see the consensus, but your rating on this claim won't count toward it.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Show me'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ApiClient.instance.dio.post('/v1/claims/${_claim['id']}/view');
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final v = _verdict;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, __) {},
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          title: Text(_claim['category'] ?? 'Claim',
              style: text.titleSmall?.copyWith(color: UltraColors.textMid)),
        ),
        body: Column(
          children: [
            Expanded(
              flex: _hasRated ? 1 : 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_claim['name'] ?? '', style: text.titleLarge),
                    if (_claim['description'] != null &&
                        _claim['description'] != _claim['name']) ...[
                      const SizedBox(height: 12),
                      Text(_claim['description'], style: text.bodyMedium),
                    ],
                    const SizedBox(height: 28),

                    if (_canSee)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: UltraColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: v.color.withValues(alpha: 0.55)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.label,
                                style: text.titleMedium
                                    ?.copyWith(color: v.color)),
                            const SizedBox(height: 8),
                            Text(v.blurb, style: text.bodySmall),
                            if (_supported != null) ...[
                              const SizedBox(height: 18),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: SizedBox(
                                  height: 6,
                                  child: Row(children: [
                                    Expanded(
                                      flex: (_supported! * 100)
                                          .round()
                                          .clamp(1, 99),
                                      child: ColoredBox(color: v.color),
                                    ),
                                    Expanded(
                                      flex: ((1 - _supported!) * 100)
                                          .round()
                                          .clamp(1, 99),
                                      child: const ColoredBox(
                                          color: UltraColors.border),
                                    ),
                                  ]),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _Stat('Supported',
                                  '${(_supported! * 100).round()}%'),
                              _Stat('Raters', '$_count'),
                              if (_predicted != null)
                                _Stat('Crowd expected',
                                    '${(_predicted! * 100).round()}%'),
                            ],
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: UltraColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          const Icon(Icons.visibility_off_outlined,
                              size: 18, color: UltraColors.textLow),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Rate this first — your rating counts toward the '
                              'consensus, and unlocks the discussion.',
                              style: text.bodySmall,
                            ),
                          ),
                        ]),
                      ),

                    const SizedBox(height: 24),

                    if (!_hasRated) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _rate,
                          style: FilledButton.styleFrom(
                            backgroundColor: UltraColors.accepted,
                            foregroundColor: UltraColors.ink,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Rate it',
                              style:
                                  TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      if (!_isInformed) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _reveal,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: UltraColors.textMid,
                              side: const BorderSide(
                                  color: UltraColors.border),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Just show me'),
                          ),
                        ),
                      ],
                    ] else
                      Row(children: [
                        const Icon(Icons.check_circle,
                            size: 16, color: UltraColors.accepted),
                        const SizedBox(width: 8),
                        Text('You rated this',
                            style: text.bodySmall
                                ?.copyWith(color: UltraColors.accepted)),
                      ]),
                  ],
                ),
              ),
            ),

            // ── bottom half ───────────────────────────────────────
            if (_hasRated)
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: ClaimComments(
                      claimId: _claim['id'], enabled: true),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: text.bodySmall?.copyWith(color: UltraColors.textLow)),
          Text(value,
              style: text.bodySmall?.copyWith(color: UltraColors.textHigh)),
        ],
      ),
    );
  }
}