import 'package:flutter/material.dart';
import '../../models/app_notification.dart';
import '../../data/notification_store.dart';
import '../../utils/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  NotificationType? _filter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _filter = switch (_tabController.index) { 0 => null, 1 => NotificationType.alarm, 2 => NotificationType.operational, 3 => NotificationType.deadline, _ => null };
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<AppNotification> get _notifications {
    var list = _filter == null ? NotificationStore.all : NotificationStore.filterByType(_filter);
    list = list.where((n) => !(_tabController.index == 0 && n.read)).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _notifications;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (NotificationStore.unreadCount > 0)
            TextButton(
              onPressed: () { NotificationStore.markAllRead(); setState(() {}); },
              child: const Text('Mark All Read'),
            ),
          if (notifications.isNotEmpty)
            IconButton(
              onPressed: () { NotificationStore.clear(); setState(() {}); },
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.all_inclusive_rounded, size: 16)),
            Tab(text: 'Alarms', icon: Icon(Icons.warning_rounded, size: 16)),
            Tab(text: 'Operational', icon: Icon(Icons.sync_rounded, size: 16)),
            Tab(text: 'Deadlines', icon: Icon(Icons.schedule_rounded, size: 16)),
          ],
        ),
      ),
      body: notifications.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('No notifications', style: TextStyle(color: Colors.grey.shade500)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: notifications.length,
              itemBuilder: (ctx, i) {
                final n = notifications[i];
                return _NotificationCard(
                  notification: n,
                  onTap: () {
                    NotificationStore.markRead(n.id);
                    setState(() {});
                  },
                  onDelete: () { NotificationStore.remove(n.id); setState(() {}); },
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({required this.notification, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final Color accent;
    switch (n.urgency) {
      case Urgency.high: accent = Colors.red; break;
      case Urgency.medium: accent = Colors.orange; break;
      case Urgency.low: accent = AppColors.primary; break;
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: n.read ? null : accent.withValues(alpha: 0.03),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(n.type.icon, size: 18, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (!n.read) Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                  Flexible(child: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w600 : FontWeight.w800, fontSize: 13), overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 2),
                Text(n.body, style: TextStyle(fontSize: 12, color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Text(_ago(n.timestamp), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                  if (n.actionLabel != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(n.actionLabel!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: accent)),
                    ),
                  ],
                ]),
              ]),
            ),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey)),
          ]),
        ),
      ),
    );
  }

  String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
