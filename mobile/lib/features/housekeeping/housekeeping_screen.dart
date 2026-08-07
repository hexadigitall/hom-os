import 'package:flutter/material.dart';
import '../../main.dart' as app;
import '../../models/housekeeping.dart';
import '../../data/housekeeping_store.dart';
import '../../data/feed_store.dart';
import '../../widgets/hom_widgets.dart';
import '../../models/role.dart';
import '../../utils/role_gate.dart';
import '../../utils/theme.dart';

final Color _primary = AppColors.primary;

class HousekeepingScreen extends StatefulWidget {
  const HousekeepingScreen({super.key});
  @override
  State<HousekeepingScreen> createState() => _HousekeepingScreenState();
}

class _HousekeepingScreenState extends State<HousekeepingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Material(
          color: AppColors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: _primary,
            labelColor: _primary,
            unselectedLabelColor: AppColors.grey500,
            tabs: const [
              Tab(
                  text: 'Tasks',
                  icon: Icon(Icons.cleaning_services_rounded, size: 15)),
              Tab(
                  text: 'Laundry',
                  icon: Icon(Icons.local_laundry_service_rounded, size: 15)),
              Tab(
                  text: 'Lost & Found',
                  icon: Icon(Icons.search_rounded, size: 15)),
              Tab(text: 'Linen', icon: Icon(Icons.bed_rounded, size: 15)),
            ],
          ),
        ),
        Expanded(
            child: TabBarView(controller: _tabController, children: [
          _TasksTab(onChange: () => setState(() {})),
          _LaundryTab(onChange: () => setState(() {})),
          _LostFoundTab(onChange: () => setState(() {})),
          _LinenTab(onChange: () => setState(() {})),
        ])),
      ]),
    );
  }
}

// ═══════════════════════════ TASKS TAB ═══════════════════════════

class _TasksTab extends StatelessWidget {
  final VoidCallback onChange;
  const _TasksTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final overdue = HousekeepingStore.overdueTasks;
    final pending = HousekeepingStore.pendingTasks;
    return Scaffold(
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.grey50,
          child: Wrap(children: [
            HomMetricCard(
                label: 'Pending',
                value: '${pending.length}',
                color: AppColors.orange),
            HomMetricCard(
                label: 'Overdue',
                value: '${overdue.length}',
                color: AppColors.red),
            HomMetricCard(
                label: 'Completed',
                value: '${HousekeepingStore.tasks.length - pending.length}',
                color: _primary),
          ]),
        ),
        Expanded(
          child: pending.isEmpty
              ? const Center(child: Text('All tasks completed'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: pending.length,
                  itemBuilder: (ctx, i) {
                    final t = pending[i];
                    final isOverdue = overdue.contains(t);
                    final icon = t.priority == HousekeepingPriority.vipSetup
                        ? Icons.star_rounded
                        : t.priority == HousekeepingPriority.deepClean
                            ? Icons.auto_fix_high
                            : t.priority == HousekeepingPriority.turndown
                                ? Icons.nightlight_round
                                : Icons.cleaning_services_rounded;
                    return Card(
                      color: isOverdue ? AppColors.red50 : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isOverdue ? AppColors.red : _primary,
                          child: Icon(icon, color: AppColors.white, size: 18),
                        ),
                        title: Text('Room ${t.roomNumber}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${t.assignedTo}  •  ${t.priorityLabel}  •  ${t.scheduledDate.toIso8601String().substring(0, 10)}',
                            style: const TextStyle(fontSize: 11)),
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          RoleGate(
                              requiredPermission:
                                  Permission.assignRoomAttendants,
                              child: IconButton(
                                icon: Icon(Icons.check_circle, color: _primary),
                                onPressed: () {
                                  HousekeepingStore.updateTask(
                                      t.id,
                                      HousekeepingTask(
                                          id: t.id,
                                          roomNumber: t.roomNumber,
                                          assignedTo: t.assignedTo,
                                          notes: t.notes,
                                          priority: t.priority,
                                          scheduledDate: t.scheduledDate,
                                          completedDate: DateTime.now(),
                                          completed: true));
                                  FeedStore.log(
                                    dept: 'housekeeping',
                                    action: 'task.completed',
                                    message:
                                        'Completed housekeeping task — Room ${t.roomNumber} (${t.priorityLabel})',
                                    refId: t.id,
                                  );
                                  onChange();
                                },
                              )),
                          RoleGate(
                              requiredPermission:
                                  Permission.assignRoomAttendants,
                              child: PopupMenuButton<String>(
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete',
                                          style:
                                              TextStyle(color: AppColors.red))),
                                ],
                                onSelected: (v) {
                                  if (v == 'edit')
                                    _showTaskForm(context, task: t);
                                  if (v == 'delete') {
                                    HousekeepingStore.removeTask(t.id);
                                    onChange();
                                  }
                                },
                              )),
                        ]),
                        onTap: () => _showTaskForm(context, task: t),
                      ),
                    );
                  }),
        ),
      ]),
      floatingActionButton: RoleGate(
          requiredPermission: Permission.assignRoomAttendants,
          child: FloatingActionButton(
            backgroundColor: _primary,
            foregroundColor: AppColors.white,
            child: const Icon(Icons.add),
            onPressed: () => _showTaskForm(context),
          )),
    );
  }

  void _showTaskForm(BuildContext context, {HousekeepingTask? task}) {
    final assignCtl = TextEditingController(text: task?.assignedTo ?? '');
    final notesCtl = TextEditingController(text: task?.notes ?? '');
    String room = task?.roomNumber ?? '101';
    HousekeepingPriority priority =
        task?.priority ?? HousekeepingPriority.routine;
    DateTime date = task?.scheduledDate ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(task == null ? 'New Task' : 'Edit Task',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                    controller: assignCtl,
                    decoration: const InputDecoration(
                        labelText: 'Assigned To',
                        border: OutlineInputBorder())),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: room,
                  decoration: const InputDecoration(
                      labelText: 'Room', border: OutlineInputBorder()),
                  items: [
                    ...app.HOMData.rooms.map((r) => r.number).toSet(),
                    if (!app.HOMData.rooms.any((r) => r.number == room))
                      room,
                  ]
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheet(() => room = v);
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<HousekeepingPriority>(
                  initialValue: priority,
                  decoration: const InputDecoration(
                      labelText: 'Priority', border: OutlineInputBorder()),
                  items: HousekeepingPriority.values
                      .map((p) =>
                          DropdownMenuItem(value: p, child: Text(p.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheet(() => priority = v);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: notesCtl,
                    decoration: const InputDecoration(
                        labelText: 'Notes', border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 8),
                ListTile(
                  title:
                      Text('Date: ${date.toIso8601String().substring(0, 10)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 30)));
                    if (picked != null) setSheet(() => date = picked);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      if (assignCtl.text.isEmpty) return;
                      final t = HousekeepingTask(
                        id: task?.id ??
                            'hk_${DateTime.now().millisecondsSinceEpoch}',
                        roomNumber: room,
                        assignedTo: assignCtl.text,
                        notes: notesCtl.text.isEmpty ? null : notesCtl.text,
                        priority: priority,
                        scheduledDate: date,
                      );
                      if (task != null) {
                        HousekeepingStore.updateTask(task.id, t);
                      } else {
                        HousekeepingStore.addTask(t);
                      }
                      Navigator.pop(ctx);
                      onChange();
                    },
                    child: Text(task == null ? 'Create Task' : 'Update'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════ LAUNDRY TAB ═══════════════════════════

class _LaundryTab extends StatelessWidget {
  final VoidCallback onChange;
  const _LaundryTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final items = HousekeepingStore.laundry;
    return Scaffold(
      body: items.isEmpty
          ? const Center(child: Text('No laundry records'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final l = items[i];
                return Card(
                    child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: l.status == LaundryStatus.delivered
                        ? _primary
                        : l.status == LaundryStatus.ready
                            ? AppColors.blue
                            : AppColors.orange,
                    child: Text(l.status.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                  title: Text(l.itemDescription,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      '${l.guestName} — Room ${l.roomNumber}  •  ${l.statusLabel}  •  ${l.type.name}',
                      style: const TextStyle(fontSize: 11)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (l.chargeAmount != null && l.chargeAmount! > 0)
                      Text('₦${l.chargeAmount!.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _primary,
                              fontSize: 12)),
                    RoleGate(
                        requiredPermission: Permission.manageLaundry,
                        child: PopupMenuButton<String>(
                          itemBuilder: (_) => LaundryStatus.values
                              .where((s) => s != l.status)
                              .map((s) => PopupMenuItem(
                                  value: s.name, child: Text(s.name)))
                              .toList()
                            ..add(const PopupMenuItem(
                                value: 'edit', child: Text('Edit')))
                            ..add(const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete',
                                    style: TextStyle(color: AppColors.red)))),
                          onSelected: (v) {
                            if (v == 'edit') {
                              _showLaundryEditForm(context, laundry: l);
                              return;
                            }
                            if (v == 'delete') {
                              HousekeepingStore.removeLaundry(l.id);
                              onChange();
                              return;
                            }
                            final next = LaundryStatus.values.byName(v);
                            HousekeepingStore.updateLaundry(
                                l.id,
                                LaundryItem(
                                    id: l.id,
                                    guestName: l.guestName,
                                    roomNumber: l.roomNumber,
                                    itemDescription: l.itemDescription,
                                    status: next,
                                    type: l.type,
                                    receivedDate: l.receivedDate,
                                    readyDate: next == LaundryStatus.delivered
                                        ? DateTime.now()
                                        : null,
                                    chargeAmount: l.chargeAmount));
                            onChange();
                          },
                        )),
                  ]),
                ));
              }),
      floatingActionButton: RoleGate(
          requiredPermission: Permission.manageLaundry,
          child: FloatingActionButton(
            backgroundColor: _primary,
            foregroundColor: AppColors.white,
            child: const Icon(Icons.add),
            onPressed: () => _showLaundryForm(context),
          )),
    );
  }

  void _showLaundryForm(BuildContext context) {
    final guestCtl = TextEditingController();
    final roomCtl = TextEditingController();
    final descCtl = TextEditingController();
    final amtCtl = TextEditingController();
    LaundryType type = LaundryType.guestCharge;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Log Laundry',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                    controller: guestCtl,
                    decoration: const InputDecoration(
                        labelText: 'Guest Name', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(
                    controller: roomCtl,
                    decoration: const InputDecoration(
                        labelText: 'Room Number',
                        border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(
                    controller: descCtl,
                    decoration: const InputDecoration(
                        labelText: 'Items', border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 8),
                DropdownButtonFormField<LaundryType>(
                  initialValue: type,
                  decoration: const InputDecoration(
                      labelText: 'Service Type', border: OutlineInputBorder()),
                  items: LaundryType.values
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheet(() => type = v);
                  },
                ),
                if (type != LaundryType.selfService) ...[
                  const SizedBox(height: 8),
                  TextField(
                      controller: amtCtl,
                      decoration: const InputDecoration(
                          labelText: 'Charge (₦)',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      if (guestCtl.text.isEmpty || descCtl.text.isEmpty) return;
                      final item = LaundryItem(
                        id: 'hk_${DateTime.now().millisecondsSinceEpoch}',
                        guestName: guestCtl.text,
                        roomNumber: roomCtl.text,
                        itemDescription: descCtl.text,
                        type: type,
                        chargeAmount: double.tryParse(amtCtl.text),
                      );
                      HousekeepingStore.addLaundry(item);
                      Navigator.pop(ctx);
                      onChange();
                    },
                    child: const Text('Log Laundry'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _showLaundryEditForm(BuildContext context,
      {required LaundryItem laundry}) {
    final guestCtl = TextEditingController(text: laundry.guestName);
    final roomCtl = TextEditingController(text: laundry.roomNumber);
    final descCtl = TextEditingController(text: laundry.itemDescription);
    final amtCtl = TextEditingController(
        text: laundry.chargeAmount?.toStringAsFixed(0) ?? '');
    LaundryType type = laundry.type;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Edit Laundry',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                    controller: guestCtl,
                    decoration: const InputDecoration(
                        labelText: 'Guest Name', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(
                    controller: roomCtl,
                    decoration: const InputDecoration(
                        labelText: 'Room Number',
                        border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(
                    controller: descCtl,
                    decoration: const InputDecoration(
                        labelText: 'Items', border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 8),
                DropdownButtonFormField<LaundryType>(
                  initialValue: type,
                  decoration: const InputDecoration(
                      labelText: 'Service Type', border: OutlineInputBorder()),
                  items: LaundryType.values
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheet(() => type = v);
                  },
                ),
                if (type != LaundryType.selfService) ...[
                  const SizedBox(height: 8),
                  TextField(
                      controller: amtCtl,
                      decoration: const InputDecoration(
                          labelText: 'Charge (₦)',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      if (guestCtl.text.isEmpty || descCtl.text.isEmpty) return;
                      final item = LaundryItem(
                        id: laundry.id,
                        guestName: guestCtl.text,
                        roomNumber: roomCtl.text,
                        itemDescription: descCtl.text,
                        type: type,
                        status: laundry.status,
                        receivedDate: laundry.receivedDate,
                        readyDate: laundry.readyDate,
                        chargeAmount: double.tryParse(amtCtl.text),
                      );
                      HousekeepingStore.updateLaundry(laundry.id, item);
                      Navigator.pop(ctx);
                      onChange();
                    },
                    child: const Text('Update'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════ LOST & FOUND TAB ═══════════════════════════

class _LostFoundTab extends StatelessWidget {
  final VoidCallback onChange;
  const _LostFoundTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final items = HousekeepingStore.lostFound;
    final unclaimed = HousekeepingStore.unclaimed;
    return Scaffold(
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.grey50,
          child: Wrap(children: [
            HomMetricCard(
                label: 'Unclaimed',
                value: '${unclaimed.length}',
                color: AppColors.red),
            HomMetricCard(
                label: 'Returned',
                value: '${items.length - unclaimed.length}',
                color: _primary),
            HomMetricCard(
                label: 'Total',
                value: '${items.length}',
                color: AppColors.blue),
          ]),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No lost & found items'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final lf = items[i];
                    return Card(
                      color:
                          lf.returned ? _primary.withValues(alpha: 0.05) : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              lf.returned ? AppColors.grey500 : AppColors.amber,
                          child: Icon(
                            lf.category == LostFoundCategory.electronics
                                ? Icons.phone_android_rounded
                                : lf.category == LostFoundCategory.jewelry
                                    ? Icons.diamond_rounded
                                    : lf.category == LostFoundCategory.documents
                                        ? Icons.description_rounded
                                        : Icons.search_rounded,
                            color: AppColors.white,
                            size: 18,
                          ),
                        ),
                        title: Text(lf.itemName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${lf.locationFound}  •  ${lf.category.name}  •  ${lf.foundDate.toIso8601String().substring(0, 10)}',
                            style: const TextStyle(fontSize: 11)),
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          if (!lf.returned)
                            RoleGate(
                                requiredPermission:
                                    Permission.manageLostAndFound,
                                child: IconButton(
                                  icon:
                                      Icon(Icons.check_circle, color: _primary),
                                  tooltip: 'Mark returned',
                                  onPressed: () {
                                    HousekeepingStore.updateLostFound(
                                        lf.id,
                                        LostFoundItem(
                                            id: lf.id,
                                            itemName: lf.itemName,
                                            foundBy: lf.foundBy,
                                            locationFound: lf.locationFound,
                                            guestName: lf.guestName,
                                            notes: lf.notes,
                                            category: lf.category,
                                            foundDate: lf.foundDate,
                                            claimedDate: DateTime.now(),
                                            returned: true));
                                    onChange();
                                  },
                                )),
                          RoleGate(
                              requiredPermission: Permission.manageLostAndFound,
                              child: IconButton(
                                icon: Icon(Icons.edit_rounded,
                                    size: 18, color: AppColors.grey500),
                                onPressed: () =>
                                    _showLostFoundEditForm(context, item: lf),
                              )),
                          RoleGate(
                              requiredPermission: Permission.manageLostAndFound,
                              child: PopupMenuButton<String>(
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'detail',
                                      child: Text('View Details')),
                                  const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete',
                                          style:
                                              TextStyle(color: AppColors.red))),
                                ],
                                onSelected: (v) {
                                  if (v == 'detail') _showDetail(context, lf);
                                  if (v == 'delete') {
                                    HousekeepingStore.removeLostFound(lf.id);
                                    onChange();
                                  }
                                },
                              )),
                        ]),
                      ),
                    );
                  }),
        ),
      ]),
      floatingActionButton: RoleGate(
          requiredPermission: Permission.manageLostAndFound,
          child: FloatingActionButton(
            backgroundColor: _primary,
            foregroundColor: AppColors.white,
            child: const Icon(Icons.add),
            onPressed: () => _showForm(context),
          )),
    );
  }

  void _showDetail(BuildContext context, LostFoundItem lf) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              scrollable: true,
              title: Text(lf.itemName),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Category', lf.category.name),
                    _row('Found By', lf.foundBy),
                    _row('Location', lf.locationFound),
                    _row('Date',
                        lf.foundDate.toIso8601String().substring(0, 10)),
                    if (lf.guestName != null) _row('Guest', lf.guestName!),
                    if (lf.claimedBy != null) _row('Claimed By', lf.claimedBy!),
                    if (lf.notes != null) _row('Notes', lf.notes!),
                    _row('Status', lf.returned ? 'Returned' : 'Unclaimed'),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'))
              ],
            ));
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Text('$label: ',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 13)))
        ]),
      );

  void _showForm(BuildContext context) {
    final nameCtl = TextEditingController();
    final foundCtl = TextEditingController();
    final locCtl = TextEditingController();
    final guestCtl = TextEditingController();
    final notesCtl = TextEditingController();
    LostFoundCategory cat = LostFoundCategory.other;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Log Found Item',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(
                        labelText: 'Item Name', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(
                    controller: foundCtl,
                    decoration: const InputDecoration(
                        labelText: 'Found By', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(
                    controller: locCtl,
                    decoration: const InputDecoration(
                        labelText: 'Location Found',
                        border: OutlineInputBorder())),
                const SizedBox(height: 8),
                DropdownButtonFormField<LostFoundCategory>(
                  initialValue: cat,
                  decoration: const InputDecoration(
                      labelText: 'Category', border: OutlineInputBorder()),
                  items: LostFoundCategory.values
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheet(() => cat = v);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: guestCtl,
                    decoration: const InputDecoration(
                        labelText: 'Guest Name (if known)',
                        border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(
                    controller: notesCtl,
                    decoration: const InputDecoration(
                        labelText: 'Notes', border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      if (nameCtl.text.isEmpty || foundCtl.text.isEmpty) return;
                      final item = LostFoundItem(
                        id: 'hk_${DateTime.now().millisecondsSinceEpoch}',
                        itemName: nameCtl.text,
                        foundBy: foundCtl.text,
                        locationFound: locCtl.text,
                        guestName: guestCtl.text.isEmpty ? null : guestCtl.text,
                        notes: notesCtl.text.isEmpty ? null : notesCtl.text,
                        category: cat,
                      );
                      HousekeepingStore.addLostFound(item);
                      Navigator.pop(ctx);
                      onChange();
                    },
                    child: const Text('Log Item'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _showLostFoundEditForm(BuildContext context,
      {required LostFoundItem item}) {
    final nameCtl = TextEditingController(text: item.itemName);
    final locCtl = TextEditingController(text: item.locationFound);
    final guestCtl = TextEditingController(text: item.guestName ?? '');
    final claimCtl = TextEditingController(text: item.claimedBy ?? '');
    final notesCtl = TextEditingController(text: item.notes ?? '');
    LostFoundCategory cat = item.category;
    bool returned = item.returned;
    DateTime foundDate = item.foundDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Edit Lost & Found Item',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(
                        labelText: 'Item Name', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(
                    controller: locCtl,
                    decoration: const InputDecoration(
                        labelText: 'Location Found',
                        border: OutlineInputBorder())),
                const SizedBox(height: 8),
                DropdownButtonFormField<LostFoundCategory>(
                  initialValue: cat,
                  decoration: const InputDecoration(
                      labelText: 'Category', border: OutlineInputBorder()),
                  items: LostFoundCategory.values
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheet(() => cat = v);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(
                      'Date Found: ${foundDate.toIso8601String().substring(0, 10)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                        context: context,
                        initialDate: foundDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now());
                    if (picked != null) setSheet(() => foundDate = picked);
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Returned'),
                  value: returned,
                  onChanged: (v) => setSheet(() => returned = v),
                ),
                if (returned) ...[
                  const SizedBox(height: 8),
                  TextField(
                      controller: claimCtl,
                      decoration: const InputDecoration(
                          labelText: 'Claimed By',
                          border: OutlineInputBorder())),
                ],
                const SizedBox(height: 8),
                TextField(
                    controller: guestCtl,
                    decoration: const InputDecoration(
                        labelText: 'Guest Name', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(
                    controller: notesCtl,
                    decoration: const InputDecoration(
                        labelText: 'Description / Notes',
                        border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      if (nameCtl.text.isEmpty) return;
                      final updated = LostFoundItem(
                        id: item.id,
                        itemName: nameCtl.text,
                        foundBy: item.foundBy,
                        locationFound: locCtl.text,
                        guestName: guestCtl.text.isEmpty ? null : guestCtl.text,
                        claimedBy: claimCtl.text.isEmpty ? null : claimCtl.text,
                        notes: notesCtl.text.isEmpty ? null : notesCtl.text,
                        category: cat,
                        foundDate: foundDate,
                        claimedDate: returned
                            ? (item.claimedDate ?? DateTime.now())
                            : null,
                        returned: returned,
                      );
                      HousekeepingStore.updateLostFound(item.id, updated);
                      Navigator.pop(ctx);
                      onChange();
                    },
                    child: const Text('Update'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════ LINEN TAB ═══════════════════════════

class _LinenTab extends StatelessWidget {
  final VoidCallback onChange;
  const _LinenTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final items = HousekeepingStore.linenDamages;
    final condemned = HousekeepingStore.condemnedCount;
    final replCost = HousekeepingStore.totalReplacementCost;
    return Scaffold(
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.grey50,
          child: Wrap(children: [
            HomMetricCard(
                label: 'Damaged Items',
                value: '${items.length}',
                color: AppColors.orange),
            HomMetricCard(
                label: 'Condemned', value: '$condemned', color: AppColors.red),
            HomMetricCard(
                label: 'Replacement Cost',
                value: '₦${replCost.toStringAsFixed(0)}',
                color: _primary),
          ]),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No linen damage records'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final l = items[i];
                    return Card(
                        child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: l.condition == LinenCondition.condemned
                            ? AppColors.red
                            : l.condition == LinenCondition.stained ||
                                    l.condition == LinenCondition.torn
                                ? AppColors.orange
                                : AppColors.blue,
                        child: Text('${l.quantity}',
                            style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                      title: Text(l.itemName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${l.category.name}  •  ${l.condition.name}  •  ${l.dateRecorded.toIso8601String().substring(0, 10)}${l.roomNumber != null ? '  •  Room ${l.roomNumber}' : ''}',
                          style: const TextStyle(fontSize: 11)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (l.replacementCost != null)
                          Text(
                              '₦${(l.replacementCost! * l.quantity).toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.redAccent,
                                  fontSize: 12)),
                        RoleGate(
                            requiredPermission: Permission.logLinenDamage,
                            child: HomTileAction(
                              icon: Icons.edit_rounded,
                              color: AppColors.grey500,
                              onPressed: () =>
                                  _showLinenEditForm(context, item: l),
                            )),
                        RoleGate(
                            requiredPermission: Permission.logLinenDamage,
                            child: HomTileAction(
                              icon: Icons.delete_rounded,
                              color: AppColors.redAccent,
                              onPressed: () {
                                HousekeepingStore.removeLinenDamage(l.id);
                                onChange();
                              },
                            )),
                      ]),
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                                  scrollable: true,
                                  title: Text(l.itemName),
                                  content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _row('Category', l.category.name),
                                        _row('Condition', l.condition.name),
                                        _row('Quantity', '${l.quantity}'),
                                        if (l.roomNumber != null)
                                          _row('Room', l.roomNumber!),
                                        if (l.replacementCost != null)
                                          _row('Replacement Cost',
                                              '₦${l.replacementCost!.toStringAsFixed(0)}'),
                                        if (l.notes != null)
                                          _row('Notes', l.notes!),
                                      ]),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Close'))
                                  ],
                                ));
                      },
                    ));
                  }),
        ),
      ]),
      floatingActionButton: RoleGate(
          requiredPermission: Permission.logLinenDamage,
          child: FloatingActionButton(
            backgroundColor: _primary,
            foregroundColor: AppColors.white,
            child: const Icon(Icons.add),
            onPressed: () => _showForm(context),
          )),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Text('$label: ',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 13)))
        ]),
      );

  void _showForm(BuildContext context) {
    final nameCtl = TextEditingController();
    final roomCtl = TextEditingController();
    final qtyCtl = TextEditingController(text: '1');
    final costCtl = TextEditingController();
    final notesCtl = TextEditingController();
    LinenCategory cat = LinenCategory.bedsheet;
    LinenCondition condition = LinenCondition.stained;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Log Linen Damage',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(
                        labelText: 'Item Name', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: DropdownButtonFormField<LinenCategory>(
                    initialValue: cat,
                    decoration: const InputDecoration(
                        labelText: 'Category', border: OutlineInputBorder()),
                    items: LinenCategory.values
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheet(() => cat = v);
                    },
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                      child: DropdownButtonFormField<LinenCondition>(
                    initialValue: condition,
                    decoration: const InputDecoration(
                        labelText: 'Condition', border: OutlineInputBorder()),
                    items: LinenCondition.values
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheet(() => condition = v);
                    },
                  )),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: qtyCtl,
                          decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: costCtl,
                          decoration: const InputDecoration(
                              labelText: 'Unit Cost (₦)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 8),
                TextField(
                    controller: roomCtl,
                    decoration: const InputDecoration(
                        labelText: 'Room (optional)',
                        border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(
                    controller: notesCtl,
                    decoration: const InputDecoration(
                        labelText: 'Notes', border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      if (nameCtl.text.isEmpty) return;
                      final item = LinenDamage(
                        id: 'hk_${DateTime.now().millisecondsSinceEpoch}',
                        itemName: nameCtl.text,
                        roomNumber: roomCtl.text.isEmpty ? null : roomCtl.text,
                        notes: notesCtl.text.isEmpty ? null : notesCtl.text,
                        category: cat,
                        condition: condition,
                        quantity: int.tryParse(qtyCtl.text) ?? 1,
                        replacementCost: double.tryParse(costCtl.text),
                      );
                      HousekeepingStore.addLinenDamage(item);
                      Navigator.pop(ctx);
                      onChange();
                    },
                    child: const Text('Log Damage'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _showLinenEditForm(BuildContext context, {required LinenDamage item}) {
    final nameCtl = TextEditingController(text: item.itemName);
    final roomCtl = TextEditingController(text: item.roomNumber ?? '');
    final qtyCtl = TextEditingController(text: item.quantity.toString());
    final costCtl = TextEditingController(
        text: item.replacementCost?.toStringAsFixed(0) ?? '');
    final notesCtl = TextEditingController(text: item.notes ?? '');
    LinenCategory cat = item.category;
    LinenCondition condition = item.condition;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Edit Linen Damage',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(
                        labelText: 'Item Name', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: DropdownButtonFormField<LinenCategory>(
                    initialValue: cat,
                    decoration: const InputDecoration(
                        labelText: 'Category', border: OutlineInputBorder()),
                    items: LinenCategory.values
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheet(() => cat = v);
                    },
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                      child: DropdownButtonFormField<LinenCondition>(
                    initialValue: condition,
                    decoration: const InputDecoration(
                        labelText: 'Condition', border: OutlineInputBorder()),
                    items: LinenCondition.values
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheet(() => condition = v);
                    },
                  )),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: qtyCtl,
                          decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: costCtl,
                          decoration: const InputDecoration(
                              labelText: 'Unit Cost (₦)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 8),
                TextField(
                    controller: roomCtl,
                    decoration: const InputDecoration(
                        labelText: 'Room (optional)',
                        border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(
                    controller: notesCtl,
                    decoration: const InputDecoration(
                        labelText: 'Notes', border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      if (nameCtl.text.isEmpty) return;
                      final updated = LinenDamage(
                        id: item.id,
                        itemName: nameCtl.text,
                        roomNumber: roomCtl.text.isEmpty ? null : roomCtl.text,
                        notes: notesCtl.text.isEmpty ? null : notesCtl.text,
                        category: cat,
                        condition: condition,
                        quantity: int.tryParse(qtyCtl.text) ?? 1,
                        replacementCost: double.tryParse(costCtl.text),
                        dateRecorded: item.dateRecorded,
                      );
                      HousekeepingStore.updateLinenDamage(item.id, updated);
                      Navigator.pop(ctx);
                      onChange();
                    },
                    child: const Text('Update'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
