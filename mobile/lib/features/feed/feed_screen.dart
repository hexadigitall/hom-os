import 'package:flutter/material.dart';
import '../../data/feed_store.dart';
import '../../models/activity_log.dart';
import '../../utils/theme.dart';

/// Shared, real-time departmental activity feed. Every department appends
/// entries (F&B, housekeeping, engineering, security, front desk, ...) and the
/// cloud sync keeps every device on the same live stream.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String? _deptFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: FeedStore.instance,
        builder: (context, _) {
          final logs = FeedStore.logs;
          final depts = <String>{
            for (final l in logs)
              if (l.dept.isNotEmpty) l.dept,
          }.toList();
          final visible = _deptFilter == null
              ? logs
              : logs.where((l) => l.dept == _deptFilter).toList();
          return Column(children: [
            if (depts.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _chip('All', _deptFilter == null, () =>
                        setState(() => _deptFilter = null)),
                    for (final d in depts)
                      _chip(d, _deptFilter == d,
                          () => setState(() => _deptFilter = d)),
                  ],
                ),
              ),
            Expanded(
              child: visible.isEmpty
                  ? const Center(
                      child: Text('No activity yet',
                          style: TextStyle(color: AppColors.grey500)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: visible.length,
                      itemBuilder: (context, i) => _FeedTile(log: visible[i]),
                    ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.white : AppColors.grey700)),
        selected: active,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.white,
        side: BorderSide(
            color: active ? AppColors.primary : AppColors.grey500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  final ActivityLog log;
  const _FeedTile({required this.log});

  static const Map<String, Color> _deptColors = {
    'restaurants': Color(0xFF0E9F6E),
    'kitchen': Color(0xFFF43F5E),
    'banqueting': Color(0xFFB45309),
    'housekeeping': Color(0xFF8B5CF6),
    'laundry': Color(0xFF7C3AED),
    'engineering': Color(0xFFF59E0B),
    'reception': Color(0xFF06B6D4),
    'reservations': Color(0xFF0EA5E9),
    'concierge': Color(0xFF14B8A6),
    'security': Color(0xFFEF4444),
    'accounts': Color(0xFF3B82F6),
    'procurement': Color(0xFF6366F1),
    'management': Color(0xFF0E9F6E),
  };

  @override
  Widget build(BuildContext context) {
    final color = _deptColors[log.dept] ?? AppColors.grey700;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Icon(Icons.circle, size: 8, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_deptLabel(log.dept),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ),
              const Spacer(),
              Text(_timeAgo(log.createdAt),
                  style: const TextStyle(fontSize: 10, color: AppColors.grey500)),
            ]),
            const SizedBox(height: 6),
            Text(log.message,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey700)),
            const SizedBox(height: 4),
            Text(log.actor,
                style: const TextStyle(fontSize: 11, color: AppColors.grey500)),
          ]),
        ),
      ]),
    );
  }

  static String _deptLabel(String dept) {
    const labels = {
      'restaurants': 'Restaurants',
      'kitchen': 'Kitchen',
      'banqueting': 'Banqueting',
      'housekeeping': 'Housekeeping',
      'laundry': 'Laundry',
      'engineering': 'Engineering',
      'reception': 'Reception',
      'reservations': 'Reservations',
      'concierge': 'Concierge',
      'security': 'Security',
      'accounts': 'Accounts',
      'procurement': 'Procurement',
      'management': 'Management',
    };
    return labels[dept] ?? dept;
  }

  static String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${t.day}/${t.month}/${t.year}';
  }
}
