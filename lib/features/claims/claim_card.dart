import 'package:flutter/material.dart';
import '../../core/theme.dart';

class ClaimCard extends StatelessWidget {
  const ClaimCard({
    super.key,
    required this.claim,
    required this.onTap,
    this.onToggleSave,
  });

  final Map<String, dynamic> claim;
  final VoidCallback onTap;
  final VoidCallback? onToggleSave;

  bool get _hasRated => claim['has_rated'] == true;
  bool get _isSaved => claim['is_saved'] == true;
  // ... rest of getters unchanged

  bool get _isInformed => claim['is_informed'] == true;
  bool get _canSee => _hasRated || _isInformed;

  String get _state => claim['consensus_state'] ?? 'collecting';
  int get _count => (claim['rating_count'] ?? 0) as int;
  double? get _supported => (claim['actual_supported'] as num?)?.toDouble();

  ({String label, Color color}) get _verdict {
    if (_state == 'collecting') {
      return (label: 'Collecting', color: UltraColors.collecting);
    }
    if (_state == 'emerging') {
      return (label: 'Early signal', color: UltraColors.collecting);
    }
    final s = _supported ?? 0;
    if (s >= 0.75) return (label: 'Widely accepted', color: UltraColors.accepted);
    if (s <= 0.25) return (label: 'Widely rejected', color: UltraColors.rejected);
    return (label: 'Contested', color: UltraColors.contested);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final v = _verdict;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Material(
        color: UltraColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: v.color.withValues(alpha: 0.55)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: v.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(v.label.toUpperCase(),
                              style: text.labelSmall
                                  ?.copyWith(color: v.color, fontSize: 10)),
                          if (claim['category'] != null) ...[
                            Text('  ·  ',
                                style: text.labelSmall?.copyWith(fontSize: 10)),
                            Flexible(
                              child: Text(
                                claim['category'].toString().toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: text.labelSmall?.copyWith(fontSize: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        claim['name'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(fontSize: 15, height: 1.3),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_canSee && _supported != null) ...[
                            Text('${(_supported! * 100).round()}% supported',
                                style: text.bodySmall?.copyWith(
                                    fontSize: 12, color: UltraColors.textLow)),
                            Text('  ·  ',
                                style: text.bodySmall?.copyWith(
                                    fontSize: 12, color: UltraColors.textLow)),
                          ],
                          Text('$_count raters',
                              style: text.bodySmall?.copyWith(
                                  fontSize: 12, color: UltraColors.textLow)),
                          if (_hasRated) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.check_circle,
                                size: 12, color: UltraColors.accepted),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // const Icon(Icons.chevron_right,
                //     size: 20, color: UltraColors.textLow),
const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_hasRated && onToggleSave != null)
                      GestureDetector(
                        onTap: onToggleSave,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            _isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 19,
                            color: _isSaved
                                ? UltraColors.contested
                                : UltraColors.textLow,
                          ),
                        ),
                      ),
                    const Icon(Icons.chevron_right,
                        size: 20, color: UltraColors.textLow),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}