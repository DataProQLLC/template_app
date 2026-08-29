// lib/features/activity/activity_tab.dart
import 'package:flutter/material.dart';
import '../../shared/emptytab.dart';

class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context) => const EmptyTab(
        icon: Icons.timeline,
        title: 'Activity',
        body: 'Your ratings, revisions, and how your calls turned out.',
      );
}