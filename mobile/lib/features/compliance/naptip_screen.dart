import 'package:flutter/material.dart';
import '../../models/compliance.dart';
import '../../data/compliance_store.dart';
import '../../models/role.dart';
import '../../utils/role_gate.dart';
import 'package:hom_mobile/utils/theme.dart';

class NaptipScreen extends StatefulWidget {
  const NaptipScreen({super.key});
  @override
  State<NaptipScreen> createState() => _NaptipScreenState();
}

class _NaptipScreenState extends State<NaptipScreen> {
  void _add() => _showForm(null);

  void _edit(NaptipAlert a) => _showForm(a);

  void _cycleStatus(NaptipAlert a) {
    const statuses = ['pending', 'investigated', 'resolved'];
    final i = statuses.indexOf(a.status);
    final next = statuses[(i + 1) % statuses.length];
    ComplianceStore.updateNaptipAlert(a.id, a.copyWith(status: next));
    setState(() {});
  }

  void _showForm(NaptipAlert? existing) {
    final descCtl = TextEditingController(text: existing?.description ?? '');
    final actionCtl = TextEditingController(text: existing?.actionTaken ?? '');
    final reportedCtl = TextEditingController(text: existing?.reportedTo ?? '');
    NaptipIncidentType type = existing?.type ?? NaptipIncidentType.other;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSB) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Report NAPTIP Incident', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 16),
              DropdownButtonFormField<NaptipIncidentType>(
                initialValue: type,
                items: NaptipIncidentType.values.map((t) => DropdownMenuItem(value: t, child: Row(children: [Icon(t.icon, size: 18), const SizedBox(width: 8), Text(t.label)]))).toList(),
                onChanged: (v) => setSB(() => type = v!),
                decoration: const InputDecoration(labelText: 'Incident Type'),
              ),
              const SizedBox(height: 12),
              TextField(controller: descCtl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', hintText: 'Describe the incident')),
              const SizedBox(height: 12),
              TextField(controller: actionCtl, maxLines: 2, decoration: const InputDecoration(labelText: 'Action Taken')),
              const SizedBox(height: 12),
              TextField(controller: reportedCtl, decoration: const InputDecoration(labelText: 'Reported To', hintText: 'e.g. NAPTIP office, Police')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: RoleGate(
                  requiredPermission: Permission.manageCompliance,
                  child: ElevatedButton(
                    onPressed: () {
                      if (descCtl.text.isEmpty) return;
                      final a = NaptipAlert(
                        id: existing?.id ?? ComplianceStore.genId(), date: existing?.date ?? DateTime.now(),
                        type: type, description: descCtl.text,
                        actionTaken: actionCtl.text, reportedTo: reportedCtl.text,
                        status: existing?.status ?? 'pending',
                      );
                      if (existing != null) {
                        ComplianceStore.updateNaptipAlert(existing.id, a);
                      } else {
                        ComplianceStore.addNaptipAlert(a);
                      }
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Submit Report'),
                  ),
                ),
              ),
            ]),
          ),
        ),
      )),
    );
  }

  void _delete(String id) {
    ComplianceStore.removeNaptipAlert(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final alerts = ComplianceStore.naptipAlerts;
    return Scaffold(
      appBar: AppBar(title: const Text('NAPTIP Alerts', maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: alerts.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.warning_rounded, size: 64, color: AppColors.grey300),
                const SizedBox(height: 12),
                Text('No incidents reported', style: TextStyle(color: AppColors.grey500)),
                const SizedBox(height: 4),
                Text('Report suspected trafficking or exploitation', style: TextStyle(fontSize: 12, color: AppColors.grey400)),
              ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: alerts.length,
              itemBuilder: (ctx, i) {
                final a = alerts[i];
                Color statusColor;
                switch (a.status) {
                  case 'investigated': statusColor = AppColors.blue; break;
                  case 'resolved': statusColor = AppColors.green; break;
                  default: statusColor = AppColors.orange;
                }
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                          child: Row(children: [
                            Icon(a.type.icon, size: 18, color: AppColors.orange800),
                            const SizedBox(width: 8),
                            Flexible(child: Text(a.type.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14), overflow: TextOverflow.ellipsis)),
                          ]),
                        ),
                        GestureDetector(
                          onTap: () => _cycleStatus(a),
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text(a.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                          ),
                        ),
                        RoleGate(requiredPermission: Permission.manageCompliance, child: IconButton(onPressed: () => _edit(a), icon: const Icon(Icons.edit_rounded, size: 18))),
                        RoleGate(requiredPermission: Permission.manageCompliance, child: IconButton(onPressed: () => _delete(a.id), icon: const Icon(Icons.delete_rounded, size: 18, color: AppColors.redAccent))),
                      ]),
                      const SizedBox(height: 6),
                      Text(a.description, style: TextStyle(fontSize: 13, color: AppColors.grey700)),
                      if (a.actionTaken.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Action: ${a.actionTaken}', style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                        ),
                      if (a.reportedTo.isNotEmpty)
                        Text('Reported to: ${a.reportedTo}', style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_fmtDate(a.date), style: TextStyle(fontSize: 11, color: AppColors.grey400)),
                      ),
                    ]),
                  ),
                );
              },
            ),
      floatingActionButton: RoleGate(
        requiredPermission: Permission.manageCompliance,
        child: FloatingActionButton(
          onPressed: _add,
          backgroundColor: AppColors.orange800,
          child: const Icon(Icons.add, color: AppColors.white),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
