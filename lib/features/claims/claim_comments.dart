import 'package:flutter/material.dart';
import '../../core/db.dart';
import '../../core/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class ClaimComments extends StatefulWidget {
  const ClaimComments({
    super.key,
    required this.claimId,
    required this.enabled,
  });

  final int claimId;
  final bool enabled;

  @override
  State<ClaimComments> createState() => _ClaimCommentsState();
}

class _ClaimCommentsState extends State<ClaimComments> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  Stream<List<Map<String, dynamic>>>? _stream;
  Stream<List<Map<String, dynamic>>>? _likeStream;
  Map<int, String> _names = {};
  int? _me;
  bool _sending = false;
  bool _expanded = false;

  final Set<int> _collapsed = {};
  bool _seededCollapse = false;

  int? _replyingTo;
  String? _replyingToName;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _init();
  }

  @override
  void didUpdateWidget(ClaimComments old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !old.enabled) _init();
  }

  void _init() {
    _stream = sb
        .from('claim_comments')
        .stream(primaryKey: ['id'])
        .eq('claim_id', widget.claimId)
        .order('created_at');
    _likeStream =
        sb.from('comment_likes').stream(primaryKey: ['comment_id', 'user_id']);
    _loadNames();
  }

  Future<void> _loadNames() async {
    try {
      final rows = await sb.from('profiles').select('id, username, user_id');
      final uid = sb.auth.currentUser?.id;
      final map = <int, String>{};
      int? me;
      for (final r in rows as List) {
        map[r['id'] as int] = (r['username'] ?? 'unknown') as String;
        if (uid != null && r['user_id'] == uid) me = r['id'] as int;
      }
      if (mounted) {
        setState(() {
          _names = map;
          _me = me;
        });
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await sb.from('claim_comments').insert({
        'claim_id': widget.claimId,
        'body': body,
        if (_replyingTo != null) 'parent_id': _replyingTo,
      });
      _controller.clear();
      setState(() {
        if (_replyingTo != null) _collapsed.remove(_replyingTo);
        _replyingTo = null;
        _replyingToName = null;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleLike(int commentId, bool liked) async {
    if (_me == null) return;
    try {
      if (liked) {
        await sb
            .from('comment_likes')
            .delete()
            .eq('comment_id', commentId)
            .eq('user_id', _me!);
      } else {
        await sb.from('comment_likes').insert({'comment_id': commentId});
      }
    } catch (_) {}
  }

  Future<void> _delete(int commentId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: UltraColors.surface,
        title: const Text('Delete comment?'),
        content: const Text('Any replies to it will stay in the thread.'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await sb
          .from('claim_comments')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', commentId);
    } catch (_) {}
  }

  void _startReply(int id, String name) {
    setState(() {
      _replyingTo = id;
      _replyingToName = name;
      _collapsed.remove(id);
    });
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    if (!widget.enabled) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: UltraColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.lock_outline, size: 18, color: UltraColors.textLow),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Rate this claim to join the discussion.',
                style: text.bodySmall),
          ),
        ]),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        final all = snap.data ?? [];
        final visibleCount = all.where((c) => c['deleted_at'] == null).length;

        if (!_seededCollapse && all.isNotEmpty) {
          _seededCollapse = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final parents =
                all.map((c) => c['parent_id'] as int?).whereType<int>().toSet();
            if (mounted && parents.isNotEmpty) {
              setState(() => _collapsed.addAll(parents));
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Text('DISCUSSION', style: text.labelSmall),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: UltraColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$visibleCount',
                        style: text.labelSmall?.copyWith(letterSpacing: 0)),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down,
                        size: 20, color: UltraColors.textLow),
                  ),
                ]),
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              if (all.isEmpty)
                const Expanded(child: SizedBox())
              else
                Expanded(
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      primary: false,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.only(right: 4),
                      child: _thread(all),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              if (_replyingTo != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: UltraColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.reply,
                        size: 15, color: UltraColors.textLow),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Replying to $_replyingToName',
                          style: text.bodySmall?.copyWith(fontSize: 12)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _replyingTo = null;
                        _replyingToName = null;
                      }),
                      child: const Icon(Icons.close,
                          size: 15, color: UltraColors.textLow),
                    ),
                  ]),
                ),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style:
                        text.bodyMedium?.copyWith(color: UltraColors.textHigh),
                    decoration: InputDecoration(
                      hintText: _replyingTo != null
                          ? 'Write a reply…'
                          : 'Add evidence or reasoning…',
                      hintStyle:
                          text.bodySmall?.copyWith(color: UltraColors.textLow),
                      filled: true,
                      fillColor: UltraColors.surfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.arrow_upward, size: 19),
                  style: IconButton.styleFrom(
                    backgroundColor: UltraColors.accepted,
                    foregroundColor: UltraColors.ink,
                    padding: const EdgeInsets.all(11),
                  ),
                ),
              ]),
            ],
          ],
        );
      },
    );
  }

  Widget _thread(List<Map<String, dynamic>> all) {
    final byParent = <int?, List<Map<String, dynamic>>>{};
    int directReplies(int id) => (byParent[id] ?? []).length;
    for (final c in all) {
      byParent.putIfAbsent(c['parent_id'] as int?, () => []).add(c);
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _likeStream,
      builder: (context, likeSnap) {
        final counts = <int, int>{};
        final mine = <int>{};
        for (final l in likeSnap.data ?? []) {
          final cid = l['comment_id'] as int;
          counts[cid] = (counts[cid] ?? 0) + 1;
          if (l['user_id'] == _me) mine.add(cid);
        }

        // int descendants(int id) {
        //   final kids = byParent[id] ?? [];
        //   return kids.fold(0, (n, k) => n + 1 + descendants(k['id'] as int));
        // }

        List<Widget> walk(int? parentId, int depth, String? replyTo) {
          final out = <Widget>[];
          for (final c in byParent[parentId] ?? []) {
            final id = c['id'] as int;
            final uid = c['user_id'] as int?;
            final name = _names[uid] ?? 'someone';
            final isMine = uid != null && uid == _me;
            final isDeleted = c['deleted_at'] != null;
            //final kids = descendants(id);
            final kids = directReplies(id);
            final isCollapsed = _collapsed.contains(id);

            out.add(_Comment(
              username: name,
              body: c['body'] ?? '',
              createdAt: DateTime.tryParse(c['created_at'] ?? ''),
              isMe: isMine,
              depth: depth,
              replyingToName: replyTo,
              isDeleted: isDeleted,
              likeCount: counts[id] ?? 0,
              likedByMe: mine.contains(id),
              replyCount: kids,
              collapsed: isCollapsed,
              onToggleReplies: kids > 0
                  ? () => setState(() => isCollapsed
                      ? _collapsed.remove(id)
                      : _collapsed.add(id))
                  : null,
              onLike: (isMine || isDeleted)
                  ? null
                  : () => _toggleLike(id, mine.contains(id)),
              onReply:
                  (isMine || isDeleted) ? null : () => _startReply(id, name),
              onDelete: (isMine && !isDeleted) ? () => _delete(id) : null,
            ));

            if (!isCollapsed) {
              out.addAll(walk(id, depth + 1, depth >= 1 ? name : null));
            }
          }
          return out;
        }

        return Column(children: walk(null, 0, null));
      },
    );
  }
}

class _Comment extends StatelessWidget {
  const _Comment({
    required this.username,
    required this.body,
    required this.createdAt,
    required this.isMe,
    required this.depth,
    required this.replyingToName,
    required this.isDeleted,
    required this.likeCount,
    required this.likedByMe,
    required this.replyCount,
    required this.collapsed,
    required this.onToggleReplies,
    required this.onLike,
    required this.onReply,
    required this.onDelete,
  });

  final String username;
  final String body;
  final DateTime? createdAt;
  final bool isMe;
  final int depth;
  final String? replyingToName;
  final bool isDeleted;
  final int likeCount;
  final bool likedByMe;
  final int replyCount;
  final bool collapsed;
  final VoidCallback? onToggleReplies;
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;

  String get _initial => username.isNotEmpty ? username[0].toUpperCase() : '?';
  double get _indent => depth.clamp(0, 2) * 30.0;
  bool get _small => depth > 0;

  String get _ago {
    if (createdAt == null) return '';
    final d = DateTime.now().difference(createdAt!.toLocal());
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${createdAt!.toLocal().month}/${createdAt!.toLocal().day}';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = isMe ? UltraColors.accepted : UltraColors.collecting;
    final size = _small ? 24.0 : 30.0;

    if (isDeleted) {
      return Padding(
        padding: EdgeInsets.only(bottom: 16, left: _indent),
        child: Row(children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: UltraColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 11),
          Text('Comment deleted',
              style: text.bodySmall?.copyWith(
                color: UltraColors.textLow,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              )),
        ]),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16, left: _indent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Text(_initial,
                style: TextStyle(
                  color: accent,
                  fontSize: _small ? 11 : 13,
                  fontWeight: FontWeight.w600,
                )),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        isMe ? 'You' : username,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: UltraColors.textHigh,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_ago,
                        style: text.bodySmall?.copyWith(
                            color: UltraColors.textLow, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 3),
_LinkedText(
                  body: body,
                  replyingToName: replyingToName,
                  baseStyle: text.bodySmall
                      ?.copyWith(color: UltraColors.textMid, height: 1.45),
                ),
                const SizedBox(height: 7),
                Row(children: [
                  if (onLike != null)
                    GestureDetector(
                      onTap: onLike,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(right: 16, top: 2, bottom: 2),
                        child: Row(children: [
                          Icon(
                            likedByMe ? Icons.favorite : Icons.favorite_border,
                            size: 14,
                            color: likedByMe
                                ? UltraColors.rejected
                                : UltraColors.textLow,
                          ),
                          if (likeCount > 0) ...[
                            const SizedBox(width: 5),
                            Text('$likeCount',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: likedByMe
                                      ? UltraColors.rejected
                                      : UltraColors.textLow,
                                )),
                          ],
                        ]),
                      ),
                    )
                  else if (likeCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(children: [
                        const Icon(Icons.favorite,
                            size: 14, color: UltraColors.textLow),
                        const SizedBox(width: 5),
                        Text('$likeCount',
                            style: const TextStyle(
                                fontSize: 12, color: UltraColors.textLow)),
                      ]),
                    ),
                  if (onReply != null)
                    GestureDetector(
                      onTap: onReply,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 16, top: 2, bottom: 2),
                        child: Text('Reply',
                            style: TextStyle(
                                fontSize: 12, color: UltraColors.textLow)),
                      ),
                    ),
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 16, top: 2, bottom: 2),
                        child: Text('Delete',
                            style: TextStyle(
                                fontSize: 12, color: UltraColors.textLow)),
                      ),
                    ),
                  if (onToggleReplies != null)
                    GestureDetector(
                      onTap: onToggleReplies,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Icon(
                            collapsed
                                ? Icons.keyboard_arrow_right
                                : Icons.keyboard_arrow_down,
                            size: 15,
                            color: UltraColors.textLow,
                          ),
                          Text(
                            '$replyCount ${replyCount == 1 ? "reply" : "replies"}',
                            style: const TextStyle(
                                fontSize: 12, color: UltraColors.textLow),
                          ),
                        ]),
                      ),
                    ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedText extends StatelessWidget {
  const _LinkedText({
    required this.body,
    required this.replyingToName,
    required this.baseStyle,
  });

  final String body;
  final String? replyingToName;
  final TextStyle? baseStyle;

  static final _urlRegex = RegExp(
    r'(https?:\/\/[^\s]+)',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];

    if (replyingToName != null) {
      spans.add(TextSpan(
        text: '@$replyingToName ',
        style: const TextStyle(
          color: UltraColors.collecting,
          fontWeight: FontWeight.w600,
        ),
      ));
    }

    var last = 0;
    for (final m in _urlRegex.allMatches(body)) {
      if (m.start > last) {
        spans.add(TextSpan(text: body.substring(last, m.start)));
      }
      final url = m.group(0)!;
      spans.add(TextSpan(
        text: _display(url),
        style: const TextStyle(
          color: UltraColors.collecting,
          decoration: TextDecoration.underline,
          decorationColor: UltraColors.collecting,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              ),
      ));
      last = m.end;
    }
    if (last < body.length) {
      spans.add(TextSpan(text: body.substring(last)));
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

  /// Trim to host + a little path so long URLs don't blow out the layout.
  String _display(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final host = uri.host.replaceFirst('www.', '');
    if (uri.path.length <= 1) return host;
    final path = uri.path.length > 20
        ? '${uri.path.substring(0, 20)}…'
        : uri.path;
    return '$host$path';
  }
}