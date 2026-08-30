import 'package:flutter/material.dart';
import '../../core/db.dart';
import '../../core/theme.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late final Stream<List<Map<String, dynamic>>> _stream = sb
      .from('notifications')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  Future<void> _markRead(List<Map<String, dynamic>> unread) async {
    if (unread.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    for (final n in unread) {
      await sb
          .from('notifications')
          .update({'read_at': now}).eq('id', n['id']);
    }
  }

  void _open(List<Map<String, dynamic>> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _Sheet(items: items),
    ).then((_) => _markRead(
        items.where((n) => n['read_at'] == null).toList()));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        final items = snap.data ?? [];
        final unread = items.where((n) => n['read_at'] == null).length;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, size: 23),
              color: AppColors.textMid,
              onPressed: () => _open(items),
            ),
            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                    color: AppColors.rejected,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.ink, width: 1.5),
                  ),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.35,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('Notifications', style: text.titleMedium),
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Text('Nothing new.',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textLow)),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    final unread = n['read_at'] == null;
                    return Container(
                      color: unread
                          ? AppColors.collecting.withValues(alpha: 0.06)
                          : null,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n['title'] ?? '',
                              style: text.titleSmall?.copyWith(fontSize: 14)),
                          if (n['body'] != null) ...[
                            const SizedBox(height: 4),
                            Text(n['body'], style: text.bodySmall),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}