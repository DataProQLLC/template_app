// lib/features/puzzle/daily_puzzle_card.dart
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

/// Renders the `answer` half of GET /v1/puzzle at the top of the claims feed.
///
/// Answering is handled locally: on success the card flips to its locked
/// state rather than asking the parent to refetch, so the user isn't
/// interrupted by a full-page reload the moment they tap.
class DailyPuzzleCard extends StatefulWidget {
  const DailyPuzzleCard({super.key, required this.puzzle, this.onOpenPlay});

  final Map<String, dynamic>? puzzle;
  final VoidCallback? onOpenPlay;

  @override
  State<DailyPuzzleCard> createState() => _DailyPuzzleCardState();
}

class _DailyPuzzleCardState extends State<DailyPuzzleCard> {
  int? _selected;
  bool _submitting = false;
  int? _localAnswerId;
  String? _error;

  Map<String, dynamic>? get _answer =>
      widget.puzzle?['answer'] as Map<String, dynamic>?;

  Map<String, dynamic>? get _play =>
      widget.puzzle?['play'] as Map<String, dynamic>?;

  int? get _lockedId =>
      _localAnswerId ?? (_answer?['your_option_id'] as int?);

  bool get _locked =>
      _localAnswerId != null || (_answer?['already_answered'] as bool? ?? false);

  Future<void> _submit() async {
    final answer = _answer;
    final choice = _selected;
    if (answer == null || choice == null || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ApiClient.instance.dio.post('/v1/puzzle/answer', data: {
        'prompt_id': answer['prompt_id'],
        'option_id': choice,
      });
      if (!mounted) return;
      setState(() {
        _localAnswerId = choice;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not submit. Try again.';
      });
    }
  }

  String? _closesIn(String? iso) {
    if (iso == null) return null;
    final closes = DateTime.tryParse(iso)?.toLocal();
    if (closes == null) return null;
    final left = closes.difference(DateTime.now());
    if (left.isNegative) return 'Closed';
    if (left.inHours >= 1) return 'Closes in ${left.inHours}h';
    return 'Closes in ${left.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final answer = _answer;
    final play = _play;

    // Quiet day: nothing open, nothing frozen yet. Take up no space.
    if (answer == null && play == null) return const SizedBox.shrink();

    return Column(
      children: [
        if (answer != null) _buildAnswer(context, answer),
        if (play != null) _buildPlayTeaser(context, play),
      ],
    );
  }

  Widget _buildAnswer(BuildContext context, Map<String, dynamic> answer) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final options = (answer['options'] as List?) ?? const [];
    final setup = answer['setup'] as String?;
    final closes = _closesIn(answer['closes_at'] as String?);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: UltraColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('TODAY\'S PUZZLE', style: text.labelSmall),
              const Spacer(),
              if (closes != null)
                Text(closes,
                    style: text.labelSmall
                        ?.copyWith(color: UltraColors.textLow, letterSpacing: 0)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            (answer['question'] as String?) ?? '',
            style: text.titleSmall?.copyWith(height: 1.35),
          ),
          if (setup != null && setup.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(setup,
                style: text.bodySmall?.copyWith(color: UltraColors.textLow)),
          ],
          const SizedBox(height: 14),
          ...options.map((raw) {
            final o = Map<String, dynamic>.from(raw as Map);
            final id = o['option_id'] as int;
            final isLocked = _locked && _lockedId == id;
            final isSelected = !_locked && _selected == id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OptionTile(
                label: (o['label'] as String?) ?? '',
                selected: isSelected,
                locked: isLocked,
                dimmed: _locked && !isLocked,
                accent: scheme.primary,
                onTap: _locked || _submitting
                    ? null
                    : () => setState(() => _selected = id),
              ),
            );
          }),
          const SizedBox(height: 4),
          if (_locked)
            Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 16, color: UltraColors.accepted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Locked in. Results unlock when the pool closes.',
                    style:
                        text.bodySmall?.copyWith(color: UltraColors.textLow),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _selected == null || _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lock it in'),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: text.bodySmall?.copyWith(color: scheme.error)),
          ],
        ],
      ),
    );
  }

  /// Minimal entry point for the previous day's playable prompt.
  /// The reveal UI (distribution bars, win/loss, streak) is not built yet.
  Widget _buildPlayTeaser(BuildContext context, Map<String, dynamic> play) {
    final text = Theme.of(context).textTheme;
    final played = play['already_played'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onOpenPlay,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: UltraColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                played ? Icons.check_circle_outline : Icons.bar_chart,
                size: 18,
                color: played ? UltraColors.accepted : UltraColors.textLow,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  played
                      ? 'You played yesterday. See the breakdown.'
                      : 'Yesterday\'s results are in. Guess the crowd.',
                  style: text.bodySmall,
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: UltraColors.textLow),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.locked,
    required this.dimmed,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool locked;
  final bool dimmed;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final borderColor = locked
        ? UltraColors.accepted
        : selected
            ? accent
            : Colors.transparent;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: text.bodyMedium?.copyWith(
                  color: dimmed ? UltraColors.textLow : null,
                ),
              ),
            ),
            if (locked)
              const Icon(Icons.check, size: 16, color: UltraColors.accepted),
          ],
        ),
      ),
    );
  }
}