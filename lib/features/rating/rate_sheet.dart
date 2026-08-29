// lib/features/rating/rate_sheet.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';

Future<bool?> showRateSheet(BuildContext context, Map<String, dynamic> claim) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _RateSheet(claim: claim),
    ),
  );
}

class _RateSheet extends StatefulWidget {
  const _RateSheet({required this.claim});
  final Map<String, dynamic> claim;

  @override
  State<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<_RateSheet> {
  final _opened = DateTime.now();

  String? _belief;
  double _predicted = 50;
  int? _confidence;
  bool _busy = false;
  String? _error;

  bool get _canSubmit => _belief != null && !_busy;

  Future<void> _submit() async {
    setState(() { _busy = true; _error = null; });
    try {
      await ApiClient.instance.dio.post('/v1/ratings/add', data: {
        'claim_id': widget.claim['id'],
        'belief': _belief,
        'predicted_pct': _predicted.roundToDouble(),
        'confidence': _confidence,
        'time_spent_ms': DateTime.now().difference(_opened).inMilliseconds,
      });
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      setState(() => _error = code == 409
          ? "You've already rated this claim."
          : 'Could not save your rating.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;


    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.claim['name'] ?? '', style: text.titleMedium),
            const SizedBox(height: 24),

            Text('Do you think this is supported by the evidence?',
                style: text.titleSmall),
            const SizedBox(height: 10),
            Row(
              children: [
                _BeliefChip(
                  label: 'Supported',
                  value: 'supported',
                  selected: _belief,
                  onTap: (v) => setState(() => _belief = v),
                ),
                const SizedBox(width: 8),
                _BeliefChip(
                  label: 'Disputed',
                  value: 'disputed',
                  selected: _belief,
                  onTap: (v) => setState(() => _belief = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _BeliefChip(
              label: "Can't be established either way",
              value: 'unverifiable',
              selected: _belief,
              fullWidth: true,
              onTap: (v) => setState(() => _belief = v),
            ),

            const SizedBox(height: 28),

            Text('Out of 100 other people, how many will say supported?',
                style: text.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Your best guess about everyone else — not how sure you are.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _predicted,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${_predicted.round()}',
                    onChanged: (v) => setState(() => _predicted = v),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text('${_predicted.round()}',
                      textAlign: TextAlign.end, style: text.titleMedium),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text('How confident are you? (optional)', style: text.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                final n = i + 1;
                final on = _confidence == n;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$n'),
                    selected: on,
                    onSelected: (_) =>
                        setState(() => _confidence = on ? null : n),
                  ),
                );
              }),
            ),

            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSubmit ? _submit : null,
                child: _busy
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit rating'),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "You'll see the consensus after you submit.",
                style:
                    text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeliefChip extends StatelessWidget {
  const _BeliefChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final String? selected;
  final ValueChanged<String> onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final chip = ChoiceChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => onTap(value),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: chip)
                     : Expanded(child: chip);
  }
}