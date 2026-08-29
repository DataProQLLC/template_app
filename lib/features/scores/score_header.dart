// lib/features/scores/score_header.dart
import 'package:flutter/material.dart';
import '../../core/theme.dart';

const _minRatings = 4;

Color _trustColor(double t) {
  if (t >= 0.90) return UltraColors.accepted;
  if (t >= 0.70) return UltraColors.contested;
  if (t >= 0.50) return const Color(0xFFE07B39);  // orange
  return UltraColors.rejected;
}

class ScoreHeader extends StatelessWidget {
  const ScoreHeader({super.key, required this.score});
  final Map<String, dynamic>? score;

  @override
  Widget build(BuildContext context) {
    final s = score;
    if (s == null) return const SizedBox.shrink();

    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    // final trust = (s['trust_score'] as num?)?.toDouble();
    // final rated = (s['ratings_scored'] ?? 0) as int;
    // final remaining = (_minRatings - rated).clamp(0, _minRatings);

    final trust = (s['trust_score'] as num?)?.toDouble();
    final rated = (s['ratings_scored'] ?? 0) as int;
    final remaining = (_minRatings - rated).clamp(0, _minRatings);
    final color = trust != null ? _trustColor(trust) : UltraColors.textLow;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: UltraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: UltraColors.border),
      ),
      child: trust != null
          ? Row(
                            children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          value: trust,
                          strokeWidth: 5,
                          backgroundColor: UltraColors.border,
                          color: color,
                        ),
                      ),
                      Text('${(trust * 100).round()}',
                          style: text.titleMedium?.copyWith(color: color)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trust score', style: text.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        '$rated claims rated · scored on how well your calls hold up',
                        style: text.bodySmall
                            ?.copyWith(color: UltraColors.textLow),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Building your record', style: text.titleSmall),
                const SizedBox(height: 6),
                Text(
                  remaining > 0
                      ? 'Rate $remaining more ${remaining == 1 ? "claim" : "claims"} to see your score.'
                      : 'Your score will appear after the next scoring run.',
                  style: text.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (rated / _minRatings).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: scheme.outlineVariant,
                  ),
                ),
              ],
            ),
    );
  }
}