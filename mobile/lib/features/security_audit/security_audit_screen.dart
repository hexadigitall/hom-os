import 'package:flutter/material.dart';
import '../../models/security_audit.dart';
import '../../data/security_audit_store.dart';
import '../../widgets/hom_widgets.dart';
import '../../models/role.dart';
import '../../utils/role_gate.dart';
import '../../utils/theme.dart';

final Color _primary = AppColors.primary;

class SecurityAuditScreen extends StatefulWidget {
  const SecurityAuditScreen({super.key});
  @override
  State<SecurityAuditScreen> createState() => _SecurityAuditScreenState();
}

class _SecurityAuditScreenState extends State<SecurityAuditScreen>
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
      appBar: AppBar(
        title: const Text('Security & Audit'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: _primary,
          labelColor: _primary,
          unselectedLabelColor: AppColors.grey500,
          tabs: const [
            Tab(
                text: 'Night Audit',
                icon: Icon(Icons.nightlight_round, size: 15)),
            Tab(text: 'Security', icon: Icon(Icons.security_rounded, size: 15)),
            Tab(
                text: 'Visitors',
                icon: Icon(Icons.person_pin_rounded, size: 15)),
            Tab(text: 'Shifts', icon: Icon(Icons.swap_horiz_rounded, size: 15)),
          ],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [
        _NightAuditTab(onChange: () => setState(() {})),
        _SecurityTab(onChange: () => setState(() {})),
        _VisitorsTab(onChange: () => setState(() {})),
        _ShiftTab(onChange: () => setState(() {})),
      ]),
    );
  }
}

// ═══════════════════════════ NIGHT AUDIT ═══════════════════════════

class _NightAuditTab extends StatelessWidget {
  final VoidCallback onChange;
  const _NightAuditTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final audits = SecurityAuditStore.nightAudits;
    final today = SecurityAuditStore.todayAudit;
    final locked = SecurityAuditStore.isTodayLocked;

    return ListView(padding: const EdgeInsets.all(16), children: [
      if (today != null)
        Card(
          color: _primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.nightlight_round, color: _primary),
                const SizedBox(width: 8),
                Text(
                    'Today\'s Audit (${today.businessDate.toIso8601String().substring(0, 10)})',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: locked ? AppColors.green100 : AppColors.orange100,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(locked ? 'Locked' : 'Open',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: locked ? AppColors.green : AppColors.orange)),
                ),
              ]),
              const SizedBox(height: 12),
              _auditRow('Total Revenue', '₦${_fmt(today.totalRevenue)}'),
              _auditRow('Room Revenue', '₦${_fmt(today.roomRevenue)}'),
              _auditRow('F&B Revenue', '₦${_fmt(today.fnbRevenue)}'),
              _auditRow('Other Revenue', '₦${_fmt(today.otherRevenue)}'),
              const Divider(),
              _auditRow('Cash Drops',
                  '${today.cashDropCount} (₦${_fmt(today.cashDropTotal)})'),
              if (today.closedBy != null)
                _auditRow('Closed By', today.closedBy!),
              if (!locked)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: RoleGate(
                        requiredPermission: Permission.closeNightAudit,
                        child: ElevatedButton.icon(
                          onPressed: () => _closeAudit(context, today),
                          icon: const Icon(Icons.lock_rounded, size: 16),
                          label: const Text('Close & Lock Day'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: AppColors.white),
                        )),
                  ),
                ),
            ]),
          ),
        )
      else
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const Icon(Icons.nightlight_round,
                  size: 40, color: AppColors.grey500),
              const SizedBox(height: 8),
              const Text('No audit for today',
                  style: TextStyle(color: AppColors.grey500)),
              const SizedBox(height: 12),
              RoleGate(
                  requiredPermission: Permission.closeNightAudit,
                  child: ElevatedButton.icon(
                    onPressed: () => _startAudit(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Start Today\'s Audit'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppColors.white),
                  )),
            ]),
          ),
        ),
      const SizedBox(height: 16),
      Text('Audit History (${audits.length})',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      const SizedBox(height: 8),
      ...audits.map((a) => Card(
              child: ListTile(
            leading: CircleAvatar(
              backgroundColor: a.locked ? _primary : AppColors.orange,
              child: Icon(
                  a.locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: AppColors.white,
                  size: 16),
            ),
            title: Text(a.businessDate.toIso8601String().substring(0, 10),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                'Revenue: ₦${_fmt(a.totalRevenue)}  •  Cash: ₦${_fmt(a.cashDropTotal)}  •  ${a.closedBy ?? 'Open'}',
                style: const TextStyle(fontSize: 11)),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                        title: Text(
                            'Night Audit — ${a.businessDate.toIso8601String().substring(0, 10)}'),
                        content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _row('Total Revenue', '₦${_fmt(a.totalRevenue)}'),
                              _row('Room Revenue', '₦${_fmt(a.roomRevenue)}'),
                              _row('F&B Revenue', '₦${_fmt(a.fnbRevenue)}'),
                              _row('Other Revenue', '₦${_fmt(a.otherRevenue)}'),
                              _row('Cash Drops',
                                  '${a.cashDropCount} (₦${_fmt(a.cashDropTotal)})'),
                              if (a.closedBy != null)
                                _row('Closed By', a.closedBy!),
                              _row('Status', a.locked ? 'Locked' : 'Open'),
                              if (a.notes != null) _row('Notes', a.notes!),
                            ]),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Close'))
                        ],
                      ));
            },
            trailing: RoleGate(
                requiredPermission: Permission.closeNightAudit,
                child: IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.red300),
                  tooltip: 'Delete',
                  onPressed: () {
                    SecurityAuditStore.removeNightAudit(a.id);
                    onChange();
                  },
                )),
          ))),
    ]);
  }

  Widget _auditRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Text('$label: ',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13))
        ]),
      );

  void _startAudit(BuildContext context) {
    final roomCtl = TextEditingController(text: '0');
    final fnbCtl = TextEditingController(text: '0');
    final otherCtl = TextEditingController(text: '0');
    final cashCtl = TextEditingController(text: '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Start Night Audit',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: roomCtl,
                      decoration: const InputDecoration(
                          labelText: 'Room Revenue (₦)',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: fnbCtl,
                      decoration: const InputDecoration(
                          labelText: 'F&B Revenue (₦)',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: otherCtl,
                      decoration: const InputDecoration(
                          labelText: 'Other Revenue (₦)',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: cashCtl,
                      decoration: const InputDecoration(
                          labelText: 'Cash Drop Total (₦)',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  final room = double.tryParse(roomCtl.text) ?? 0;
                  final fnb = double.tryParse(fnbCtl.text) ?? 0;
                  final other = double.tryParse(otherCtl.text) ?? 0;
                  final cash = double.tryParse(cashCtl.text) ?? 0;
                  final total = room + fnb + other;
                  SecurityAuditStore.addNightAudit(NightAuditLog(
                    id: 'sa_${DateTime.now().millisecondsSinceEpoch}',
                    businessDate: DateTime.now(),
                    totalRevenue: total,
                    roomRevenue: room,
                    fnbRevenue: fnb,
                    otherRevenue: other,
                    cashDropTotal: cash,
                    cashDropCount: cash > 0 ? 1 : 0,
                  ));
                  Navigator.pop(ctx);
                  onChange();
                },
                child: const Text('Start Audit'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _closeAudit(BuildContext context, NightAuditLog audit) {
    final notesCtl = TextEditingController();
    final cashCtl = TextEditingController(text: '0');
    final nameCtl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Close & Lock Day',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
                controller: nameCtl,
                decoration: const InputDecoration(
                    labelText: 'Closed By', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(
                controller: cashCtl,
                decoration: const InputDecoration(
                    labelText: 'Additional Cash Drop (₦)',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(
                controller: notesCtl,
                decoration: const InputDecoration(
                    labelText: 'Shift Handover Notes',
                    border: OutlineInputBorder()),
                maxLines: 3),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  final cash = double.tryParse(cashCtl.text) ?? 0;
                  SecurityAuditStore.updateNightAudit(
                      audit.id,
                      NightAuditLog(
                        id: audit.id,
                        businessDate: audit.businessDate,
                        totalRevenue: audit.totalRevenue,
                        roomRevenue: audit.roomRevenue,
                        fnbRevenue: audit.fnbRevenue,
                        otherRevenue: audit.otherRevenue,
                        cashDropCount: audit.cashDropCount + (cash > 0 ? 1 : 0),
                        cashDropTotal: audit.cashDropTotal + cash,
                        closedBy: nameCtl.text.isEmpty ? null : nameCtl.text,
                        notes: notesCtl.text.isEmpty ? null : notesCtl.text,
                        closedAt: DateTime.now(),
                        locked: true,
                      ));
                  Navigator.pop(ctx);
                  onChange();
                },
                child: const Text('Lock Day'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════ SECURITY ═══════════════════════════

class _SecurityTab extends StatelessWidget {
  final VoidCallback onChange;
  const _SecurityTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final incidents = SecurityAuditStore.incidents;
    final open = SecurityAuditStore.openIncidents;
    return Scaffold(
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.grey50,
          child: Wrap(children: [
            HomMetricCard(
                label: 'Open', value: '${open.length}', color: AppColors.red),
            HomMetricCard(
                label: 'Investigating',
                value:
                    '${incidents.where((i) => i.status == IncidentStatus.investigating).length}',
                color: AppColors.orange),
            HomMetricCard(
                label: 'Total',
                value: '${incidents.length}',
                color: AppColors.blue),
          ]),
        ),
        Expanded(
          child: incidents.isEmpty
              ? const Center(child: Text('No security incidents'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: incidents.length,
                  itemBuilder: (ctx, i) {
                    final inc = incidents[i];
                    return Card(
                      color: inc.status == IncidentStatus.resolved
                          ? null
                          : inc.status == IncidentStatus.investigating
                              ? AppColors.orange50
                              : AppColors.red50,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: inc.status == IncidentStatus.resolved
                              ? _primary
                              : inc.status == IncidentStatus.investigating
                                  ? AppColors.orange
                                  : AppColors.red,
                          child: Icon(
                            inc.type == IncidentType.theft
                                ? Icons.visibility_off_rounded
                                : inc.type == IncidentType.fire
                                    ? Icons.local_fire_department_rounded
                                    : inc.type == IncidentType.medical
                                        ? Icons.medical_services_rounded
                                        : inc.type == IncidentType.intruder
                                            ? Icons.person_off_rounded
                                            : Icons.warning_rounded,
                            color: AppColors.white,
                            size: 18,
                          ),
                        ),
                        title: Text(inc.type.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${inc.location ?? 'N/A'}  •  ${inc.dateReported.toIso8601String().substring(0, 10)}  •  ${inc.reportedBy ?? 'N/A'}',
                            style: const TextStyle(fontSize: 11)),
                        trailing: RoleGate(
                            requiredPermission:
                                Permission.manageIncidentReports,
                            child: PopupMenuButton<String>(
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: 'detail', child: Text('View')),
                                const PopupMenuItem(
                                    value: 'edit', child: Text('Edit')),
                                if (inc.status == IncidentStatus.open)
                                  const PopupMenuItem(
                                      value: 'investigate',
                                      child: Text('Mark Investigating')),
                                if (inc.status != IncidentStatus.resolved)
                                  const PopupMenuItem(
                                      value: 'resolve',
                                      child: Text('Mark Resolved')),
                                const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete',
                                        style:
                                            TextStyle(color: AppColors.red))),
                              ],
                              onSelected: (v) {
                                if (v == 'detail') {
                                  showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                            title: Text(inc.type.name),
                                            content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _row('Type', inc.type.name),
                                                  if (inc.location != null)
                                                    _row('Location',
                                                        inc.location!),
                                                  if (inc.description != null)
                                                    _row('Description',
                                                        inc.description!),
                                                  _row('Reported By',
                                                      inc.reportedBy ?? 'N/A'),
                                                  _row(
                                                      'Date',
                                                      inc.dateReported
                                                          .toIso8601String()
                                                          .substring(0, 10)),
                                                  _row('Status',
                                                      inc.status.name),
                                                  if (inc.resolvedBy != null)
                                                    _row('Resolved By',
                                                        inc.resolvedBy!),
                                                  if (inc.notes != null)
                                                    _row('Notes', inc.notes!),
                                                ]),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: const Text('Close'))
                                            ],
                                          ));
                                } else if (v == 'edit') {
                                  _editIncident(context, inc);
                                } else if (v == 'investigate') {
                                  SecurityAuditStore.updateIncident(
                                      inc.id,
                                      SecurityIncident(
                                          id: inc.id,
                                          location: inc.location,
                                          description: inc.description,
                                          reportedBy: inc.reportedBy,
                                          type: inc.type,
                                          status: IncidentStatus.investigating,
                                          dateReported: inc.dateReported));
                                  onChange();
                                } else if (v == 'resolve') {
                                  SecurityAuditStore.updateIncident(
                                      inc.id,
                                      SecurityIncident(
                                          id: inc.id,
                                          location: inc.location,
                                          description: inc.description,
                                          reportedBy: inc.reportedBy,
                                          type: inc.type,
                                          status: IncidentStatus.resolved,
                                          dateReported: inc.dateReported,
                                          dateResolved: DateTime.now()));
                                  onChange();
                                } else if (v == 'delete') {
                                  SecurityAuditStore.removeIncident(inc.id);
                                  onChange();
                                }
                              },
                            )),
                      ),
                    );
                  }),
        ),
      ]),
      floatingActionButton: RoleGate(
          requiredPermission: Permission.manageIncidentReports,
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
    final locCtl = TextEditingController();
    final descCtl = TextEditingController();
    final repCtl = TextEditingController();
    IncidentType type = IncidentType.other;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Report Incident',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              DropdownButtonFormField<IncidentType>(
                initialValue: type,
                decoration: const InputDecoration(
                    labelText: 'Incident Type', border: OutlineInputBorder()),
                items: IncidentType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSheet(() => type = v);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                  controller: locCtl,
                  decoration: const InputDecoration(
                      labelText: 'Location', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: descCtl,
                  decoration: const InputDecoration(
                      labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2),
              const SizedBox(height: 8),
              TextField(
                  controller: repCtl,
                  decoration: const InputDecoration(
                      labelText: 'Reported By', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    if (descCtl.text.isEmpty) return;
                    SecurityAuditStore.addIncident(SecurityIncident(
                      id: 'sa_${DateTime.now().millisecondsSinceEpoch}',
                      location: locCtl.text.isEmpty ? null : locCtl.text,
                      description: descCtl.text,
                      reportedBy: repCtl.text.isEmpty ? null : repCtl.text,
                      type: type,
                    ));
                    Navigator.pop(ctx);
                    onChange();
                  },
                  child: const Text('Report Incident'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _editIncident(BuildContext context, SecurityIncident inc) {
    final locCtl = TextEditingController(text: inc.location ?? '');
    final descCtl = TextEditingController(text: inc.description ?? '');
    final repCtl = TextEditingController(text: inc.reportedBy ?? '');
    final notesCtl = TextEditingController(text: inc.notes ?? '');
    IncidentType type = inc.type;
    IncidentStatus status = inc.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Edit Incident',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              DropdownButtonFormField<IncidentType>(
                initialValue: type,
                decoration: const InputDecoration(
                    labelText: 'Incident Type', border: OutlineInputBorder()),
                items: IncidentType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSheet(() => type = v);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                  controller: locCtl,
                  decoration: const InputDecoration(
                      labelText: 'Location', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: descCtl,
                  decoration: const InputDecoration(
                      labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2),
              const SizedBox(height: 8),
              TextField(
                  controller: repCtl,
                  decoration: const InputDecoration(
                      labelText: 'Reported By', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              DropdownButtonFormField<IncidentStatus>(
                initialValue: status,
                decoration: const InputDecoration(
                    labelText: 'Status', border: OutlineInputBorder()),
                items: IncidentStatus.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSheet(() => status = v);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                  controller: notesCtl,
                  decoration: const InputDecoration(
                      labelText: 'Action Taken / Notes',
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
                    SecurityAuditStore.updateIncident(
                        inc.id,
                        SecurityIncident(
                          id: inc.id,
                          location: locCtl.text.isEmpty ? null : locCtl.text,
                          description:
                              descCtl.text.isEmpty ? null : descCtl.text,
                          reportedBy: repCtl.text.isEmpty ? null : repCtl.text,
                          type: type,
                          status: status,
                          dateReported: inc.dateReported,
                          dateResolved: status == IncidentStatus.resolved
                              ? (inc.dateResolved ?? DateTime.now())
                              : null,
                          resolvedBy: status == IncidentStatus.resolved
                              ? (inc.resolvedBy ??
                                  (repCtl.text.isEmpty ? null : repCtl.text))
                              : null,
                          notes: notesCtl.text.isEmpty ? null : notesCtl.text,
                        ));
                    Navigator.pop(ctx);
                    onChange();
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════ VISITORS ═══════════════════════════

class _VisitorsTab extends StatelessWidget {
  final VoidCallback onChange;
  const _VisitorsTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final passes = SecurityAuditStore.visitorPasses;
    final active = SecurityAuditStore.activeVisitors;
    return Scaffold(
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.grey50,
          child: Wrap(children: [
            HomMetricCard(
                label: 'On-Site', value: '${active.length}', color: _primary),
            HomMetricCard(
                label: 'Checked Out',
                value: '${passes.length - active.length}',
                color: AppColors.grey500),
            HomMetricCard(
                label: 'Total Today',
                value: '${passes.length}',
                color: AppColors.blue),
          ]),
        ),
        Expanded(
          child: passes.isEmpty
              ? const Center(child: Text('No visitor passes'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: passes.length,
                  itemBuilder: (ctx, i) {
                    final v = passes[i];
                    return Card(
                      color: v.active ? _primary.withValues(alpha: 0.05) : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              v.active ? _primary : AppColors.grey500,
                          child: Text(v.visitorName[0],
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700)),
                        ),
                        title: Text(v.visitorName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${v.purpose}  •  Host: ${v.hostName}  •  ${v.checkIn.toIso8601String().substring(11, 16)}${v.badgeNumber != null ? '  •  Badge: ${v.badgeNumber}' : ''}',
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          if (v.active)
                            RoleGate(
                                requiredPermission:
                                    Permission.manageVisitorPasses,
                                child: IconButton(
                                  icon: Icon(Icons.logout_rounded,
                                      color: _primary),
                                  tooltip: 'Check Out',
                                  onPressed: () {
                                    SecurityAuditStore.updateVisitorPass(
                                        v.id,
                                        VisitorPass(
                                            id: v.id,
                                            visitorName: v.visitorName,
                                            purpose: v.purpose,
                                            hostName: v.hostName,
                                            badgeNumber: v.badgeNumber,
                                            notes: v.notes,
                                            checkIn: v.checkIn,
                                            checkOut: DateTime.now(),
                                            active: false));
                                    onChange();
                                  },
                                )),
                          RoleGate(
                              requiredPermission:
                                  Permission.manageVisitorPasses,
                              child: PopupMenuButton<String>(
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'detail', child: Text('View')),
                                  const PopupMenuItem(
                                      value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete',
                                          style:
                                              TextStyle(color: AppColors.red))),
                                ],
                                onSelected: (v2) {
                                  if (v2 == 'detail') {
                                    showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                              title: Text(v.visitorName),
                                              content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _row('Visitor',
                                                        v.visitorName),
                                                    _row('Purpose', v.purpose),
                                                    _row('Host', v.hostName),
                                                    if (v.badgeNumber != null)
                                                      _row('Badge',
                                                          v.badgeNumber!),
                                                    _row(
                                                        'Check In',
                                                        v.checkIn
                                                            .toIso8601String()
                                                            .substring(0, 16)),
                                                    if (v.checkOut != null)
                                                      _row(
                                                          'Check Out',
                                                          v.checkOut!
                                                              .toIso8601String()
                                                              .substring(
                                                                  0, 16)),
                                                    if (v.notes != null)
                                                      _row('Notes', v.notes!),
                                                    _row(
                                                        'Status',
                                                        v.active
                                                            ? 'On-Site'
                                                            : 'Checked Out'),
                                                  ]),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx),
                                                    child: const Text('Close'))
                                              ],
                                            ));
                                  }
                                  if (v2 == 'edit') {
                                    _editVisitor(context, v);
                                  }
                                  if (v2 == 'delete') {
                                    SecurityAuditStore.removeVisitorPass(v.id);
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
          requiredPermission: Permission.manageVisitorPasses,
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
    final purposeCtl = TextEditingController();
    final hostCtl = TextEditingController();
    final badgeCtl = TextEditingController();
    final notesCtl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Issue Visitor Pass',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
                controller: nameCtl,
                decoration: const InputDecoration(
                    labelText: 'Visitor Name', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(
                controller: purposeCtl,
                decoration: const InputDecoration(
                    labelText: 'Purpose of Visit',
                    border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(
                controller: hostCtl,
                decoration: const InputDecoration(
                    labelText: 'Host Name', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(
                controller: badgeCtl,
                decoration: const InputDecoration(
                    labelText: 'Badge Number', border: OutlineInputBorder())),
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
                  if (nameCtl.text.isEmpty ||
                      purposeCtl.text.isEmpty ||
                      hostCtl.text.isEmpty) return;
                  SecurityAuditStore.addVisitorPass(VisitorPass(
                    id: 'sa_${DateTime.now().millisecondsSinceEpoch}',
                    visitorName: nameCtl.text,
                    purpose: purposeCtl.text,
                    hostName: hostCtl.text,
                    badgeNumber: badgeCtl.text.isEmpty ? null : badgeCtl.text,
                    notes: notesCtl.text.isEmpty ? null : notesCtl.text,
                  ));
                  Navigator.pop(ctx);
                  onChange();
                },
                child: const Text('Issue Pass'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _editVisitor(BuildContext context, VisitorPass v) {
    final nameCtl = TextEditingController(text: v.visitorName);
    final purposeCtl = TextEditingController(text: v.purpose);
    final hostCtl = TextEditingController(text: v.hostName);
    final badgeCtl = TextEditingController(text: v.badgeNumber ?? '');
    final notesCtl = TextEditingController(text: v.notes ?? '');
    bool active = v.active;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Edit Visitor Pass',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(
                      labelText: 'Visitor Name', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: purposeCtl,
                  decoration: const InputDecoration(
                      labelText: 'Purpose of Visit',
                      border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: hostCtl,
                  decoration: const InputDecoration(
                      labelText: 'Host Name', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: badgeCtl,
                  decoration: const InputDecoration(
                      labelText: 'Badge Number', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: notesCtl,
                  decoration: const InputDecoration(
                      labelText: 'Notes', border: OutlineInputBorder()),
                  maxLines: 2),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Active (On-Site)'),
                value: active,
                activeThumbColor: _primary,
                onChanged: (val) => setSheet(() => active = val),
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
                    if (nameCtl.text.isEmpty ||
                        purposeCtl.text.isEmpty ||
                        hostCtl.text.isEmpty) return;
                    SecurityAuditStore.updateVisitorPass(
                        v.id,
                        VisitorPass(
                          id: v.id,
                          visitorName: nameCtl.text,
                          purpose: purposeCtl.text,
                          hostName: hostCtl.text,
                          badgeNumber:
                              badgeCtl.text.isEmpty ? null : badgeCtl.text,
                          notes: notesCtl.text.isEmpty ? null : notesCtl.text,
                          checkIn: v.checkIn,
                          checkOut: active
                              ? v.checkOut
                              : (v.checkOut ?? DateTime.now()),
                          active: active,
                        ));
                    Navigator.pop(ctx);
                    onChange();
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════ SHIFTS ═══════════════════════════

class _ShiftTab extends StatelessWidget {
  final VoidCallback onChange;
  const _ShiftTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final shifts = SecurityAuditStore.shifts;
    final active = SecurityAuditStore.activeShift;
    final today = SecurityAuditStore.todayShifts;

    return ListView(padding: const EdgeInsets.all(16), children: [
      if (active != null)
        Card(
          color: _primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child:
                      Icon(_shiftIcon(active.shift), color: _primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${active.shift.name} Shift',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(
                          '${active.staffName} — ${active.openedAt.hour.toString().padLeft(2, '0')}:${active.openedAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.grey500)),
                    ])),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.green100,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Text('Active',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green)),
                ),
              ]),
              if (active.notes != null && active.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(active.notes!,
                    style: TextStyle(fontSize: 12, color: AppColors.grey700)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: RoleGate(
                    requiredPermission: Permission.manageShiftHandover,
                    child: ElevatedButton.icon(
                      onPressed: () => _closeShift(context, active),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Close Shift'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: AppColors.white),
                    )),
              ),
            ]),
          ),
        )
      else
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const Icon(Icons.swap_horiz_rounded,
                  size: 40, color: AppColors.grey500),
              const SizedBox(height: 8),
              const Text('No active shift',
                  style: TextStyle(color: AppColors.grey500)),
              const SizedBox(height: 12),
              RoleGate(
                  requiredPermission: Permission.manageShiftHandover,
                  child: ElevatedButton.icon(
                    onPressed: () => _startShift(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Start Shift'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppColors.white),
                  )),
            ]),
          ),
        ),
      const SizedBox(height: 16),
      Row(children: [
        Text('Today\'s Shifts (${today.length})',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const Spacer(),
        Text('${shifts.length} total',
            style: const TextStyle(fontSize: 11, color: AppColors.grey500)),
      ]),
      const SizedBox(height: 8),
      ...shifts.map((s) {
        final isActiveShift = s.isActive;
        return Card(
          color: isActiveShift ? _primary.withValues(alpha: 0.03) : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isActiveShift ? _primary : AppColors.grey500,
              child:
                  Icon(_shiftIcon(s.shift), color: AppColors.white, size: 16),
            ),
            title: Text('${s.staffName} — ${s.shift.name} Shift',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text(
              '${s.openedAt.day}/${s.openedAt.month} ${s.openedAt.hour.toString().padLeft(2, '0')}:${s.openedAt.minute.toString().padLeft(2, '0')}${s.closedAt != null ? ' → ${s.closedAt!.hour.toString().padLeft(2, '0')}:${s.closedAt!.minute.toString().padLeft(2, '0')}' : ' → Active'}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: RoleGate(
                requiredPermission: Permission.manageShiftHandover,
                child: IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.red300),
                  tooltip: 'Delete',
                  onPressed: () {
                    SecurityAuditStore.removeShift(s.id);
                    onChange();
                  },
                )),
          ),
        );
      }),
    ]);
  }

  IconData _shiftIcon(ShiftType s) {
    switch (s) {
      case ShiftType.morning:
        return Icons.wb_sunny_rounded;
      case ShiftType.afternoon:
        return Icons.wb_cloudy_rounded;
      case ShiftType.night:
        return Icons.nights_stay_rounded;
    }
  }

  void _startShift(BuildContext context) {
    ShiftType shift = ShiftType.morning;
    final nameCtl = TextEditingController();
    final notesCtl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Start Shift',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              DropdownButtonFormField<ShiftType>(
                initialValue: shift,
                decoration: const InputDecoration(
                    labelText: 'Shift', border: OutlineInputBorder()),
                items: ShiftType.values
                    .map((t) => DropdownMenuItem(
                        value: t, child: Text('${t.name} Shift')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSheet(() => shift = v);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(
                      labelText: 'Staff Name', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: notesCtl,
                  decoration: const InputDecoration(
                      labelText: 'Handover Notes',
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
                    SecurityAuditStore.addShift(ShiftHandover(
                      id: 'sa_${DateTime.now().millisecondsSinceEpoch}',
                      shift: shift,
                      staffName: nameCtl.text,
                      notes: notesCtl.text.isEmpty ? null : notesCtl.text,
                    ));
                    Navigator.pop(ctx);
                    onChange();
                  },
                  child: const Text('Start Shift'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _closeShift(BuildContext context, ShiftHandover shift) {
    final notesCtl = TextEditingController(text: shift.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Close Shift',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          Text('Closing ${shift.shift.name} Shift — ${shift.staffName}',
              style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
          const SizedBox(height: 8),
          TextField(
              controller: notesCtl,
              decoration: const InputDecoration(
                  labelText: 'Shift Summary / Notes',
                  border: OutlineInputBorder()),
              maxLines: 3),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {
                SecurityAuditStore.updateShift(
                    shift.id,
                    ShiftHandover(
                      id: shift.id,
                      shift: shift.shift,
                      staffName: shift.staffName,
                      openedAt: shift.openedAt,
                      closedAt: DateTime.now(),
                      notes: notesCtl.text.isEmpty ? null : notesCtl.text,
                      isActive: false,
                    ));
                Navigator.pop(ctx);
                onChange();
              },
              child: const Text('Close Shift'),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════ SHARED ═══════════════════════════

String _fmt(double n) => n.toStringAsFixed(0);
