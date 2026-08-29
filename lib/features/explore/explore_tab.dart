import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../claims/claim_card.dart';
import '../claims/claim_detail_screen.dart';

const _pageSize = 20;

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();

  List<Map<String, dynamic>> _claims = [];
  List<Map<String, dynamic>> _categories = [];
  int _total = 0;
  int _offset = 0;
  bool _loading = false;
  bool _initialLoad = true;

  String? _category;
  String? _state;
  String? _rated = "unrated";
  bool _savedOnly = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >
              _scroll.position.maxScrollExtent - 400 &&
          !_loading &&
          _claims.length < _total) {
        _load();
      }
    });
    _loadFilters();
    _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final r = await ApiClient.instance.dio.get('/v1/claims/filters');
      // final r = await ApiClient.instance.dio.get('/v1/claims/filters', queryParameters: {
      //   'rated': 'unrated',
      // });
      if (mounted) {
        setState(() => _categories =
            List<Map<String, dynamic>>.from(r.data['categories'] ?? []));
      }
    } catch (_) {}
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    if (reset) _offset = 0;

    try {
      final r = await ApiClient.instance.dio.get('/v1/claims', queryParameters: {
        if (_category != null) 'category': _category,
        if (_state != null) 'state': _state,
        if (_rated != null) 'rated': _rated,
        if (_savedOnly) 'saved_only': true,
        'limit': _pageSize,
        'offset': _offset,
      });
      final fetched =
          List<Map<String, dynamic>>.from(r.data['claims'] ?? []);
      if (!mounted) return;
      setState(() {
        _total = r.data['total'] ?? 0;
        _claims = reset ? fetched : [..._claims, ...fetched];
        _offset += fetched.length;
        _initialLoad = false;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setFilter(void Function() change) {
    setState(change);
    _load(reset: true);
  }

  Future<void> _open(Map<String, dynamic> c) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ClaimDetailScreen(claim: c)),
    );
    if (changed == true && mounted) _load(reset: true);
  }

Future<void> _toggleSave(Map<String, dynamic> claim) async {
    final id = claim['id'];
    final wasSaved = claim['is_saved'] == true;
    setState(() {
      final i = _claims.indexWhere((c) => c['id'] == id);
      if (i != -1) _claims[i] = {..._claims[i], 'is_saved': !wasSaved};
    });
    try {
      await ApiClient.instance.dio.post('/v1/claims/$id/save');
    } catch (_) {
      if (mounted) {
        setState(() {
          final i = _claims.indexWhere((c) => c['id'] == id);
          if (i != -1) _claims[i] = {..._claims[i], 'is_saved': wasSaved};
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final text = Theme.of(context).textTheme;

    return Column(
      children: [
        // filter rows
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              _Chip(
                label: 'Saved',
                icon: Icons.bookmark_border,
                selected: _savedOnly,
                onTap: () => _setFilter(() => _savedOnly = !_savedOnly),
              ),
              _Chip(
                label: 'Unrated',
                selected: _rated == 'unrated',
                onTap: () => _setFilter(
                    () => _rated = _rated == 'unrated' ? null : 'unrated'),
              ),
              _Chip(
                label: 'Contested',
                selected: _state == 'established',
                onTap: () => _setFilter(() =>
                    _state = _state == 'established' ? null : 'established'),
              ),
              const SizedBox(width: 6),
              Container(width: 1, height: 18, color: UltraColors.border,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 12)),
              ..._categories.map((c) => _Chip(
                    label: '${c['value']}',
                    count: c['count'] as int?,
                    selected: _category == c['value'],
                    onTap: () => _setFilter(() => _category =
                        _category == c['value'] ? null : c['value'] as String),
                  )),
            ],
          ),
        ),

        if (!_initialLoad)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(children: [
              Text('$_total ${_total == 1 ? "claim" : "claims"}',
                  style: text.labelSmall),
            ]),
          ),

        Expanded(
          child: _initialLoad
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async => _load(reset: true),
                  child: _claims.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 100),
                          Center(
                            child: Text('Nothing matches those filters.',
                                style: text.bodySmall
                                    ?.copyWith(color: UltraColors.textLow)),
                          ),
                        ])
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: _claims.length + 1,
                          itemBuilder: (context, i) {
                            if (i == _claims.length) {
                              return Padding(
                                padding: const EdgeInsets.all(20),
                                child: Center(
                                  child: _claims.length < _total
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : Text('End of results',
                                          style: text.bodySmall?.copyWith(
                                              color: UltraColors.textLow)),
                                ),
                              );
                            }
                            return ClaimCard(
                              claim: _claims[i],
                              onTap: () => _open(_claims[i]),
                              onToggleSave: () => _toggleSave(_claims[i]),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? UltraColors.accepted.withValues(alpha: 0.16)
                : UltraColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? UltraColors.accepted.withValues(alpha: 0.5)
                  : UltraColors.border,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: selected
                      ? UltraColors.accepted
                      : UltraColors.textLow),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      selected ? UltraColors.accepted : UltraColors.textMid,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                )),
            if (count != null) ...[
              const SizedBox(width: 5),
              Text('$count',
                  style: const TextStyle(
                      fontSize: 11, color: UltraColors.textLow)),
            ],
          ]),
        ),
      ),
    );
  }
}