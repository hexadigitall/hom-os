import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/compliance.dart';
import '../../data/compliance_store.dart';
import '../../models/role.dart';
import '../../utils/role_gate.dart';
import '../../utils/theme.dart';

class LgaScreen extends StatefulWidget {
  const LgaScreen({super.key});
  @override
  State<LgaScreen> createState() => _LgaScreenState();
}

class _LgaScreenState extends State<LgaScreen> {
  void _add() => _showForm(null);

  void _edit(LgaInspection i) => _showForm(i);

  void _showForm(LgaInspection? existing) {
    final inspectorCtl = TextEditingController(text: existing?.inspector ?? '');
    final agencyCtl = TextEditingController(text: existing?.agency ?? '');
    final certNumCtl = TextEditingController(text: existing?.certificateNumber ?? '');
    final scoreCtl = TextEditingController(text: existing != null ? existing.score.toString() : '');
    DateTime inspDate = existing?.inspectionDate ?? DateTime.now();
    DateTime? expiryDate = existing?.expiryDate;

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
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Log Inspection', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 16),
              TextField(controller: inspectorCtl, decoration: const InputDecoration(labelText: 'Inspector Name')),
              const SizedBox(height: 12),
              TextField(controller: agencyCtl, decoration: const InputDecoration(labelText: 'Agency / LGA')),
              const SizedBox(height: 12),
              TextField(controller: certNumCtl, decoration: const InputDecoration(labelText: 'Certificate Number')),
              const SizedBox(height: 12),
              TextField(controller: scoreCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Score (0-100)')),
              const SizedBox(height: 12),
              Text('Inspection Date: ${DateFormat('dd MMM yyyy').format(inspDate)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(context: context, initialDate: inspDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                  if (picked != null) setSB(() => inspDate = picked);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Change Date'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: RoleGate(
                  requiredPermission: Permission.manageLGAHealthPermits,
                  child: ElevatedButton(
                    onPressed: () {
                      final score = (double.tryParse(scoreCtl.text) ?? 0).clamp(0, 100) as double;
                      if (certNumCtl.text.isEmpty) return;
                      final now = DateTime.now();
                      final status = expiryDate != null
                          ? expiryDate.isBefore(now) ? 'expired' : 'valid'
                          : 'pending-renewal';
                      final i = LgaInspection(
                        id: existing?.id ?? ComplianceStore.genId(), inspectionDate: inspDate,
                        inspector: inspectorCtl.text, agency: agencyCtl.text,
                        certificateNumber: certNumCtl.text, expiryDate: expiryDate,
                        score: score, status: status,
                      );
                      if (existing != null) {
                        ComplianceStore.updateLgaInspection(existing.id, i);
                      } else {
                        ComplianceStore.addLgaInspection(i);
                      }
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Save Inspection'),
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
    ComplianceStore.removeLgaInspection(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final inspections = ComplianceStore.lgaInspections;
    final latest = ComplianceStore.latestInspection;

    return Scaffold(
      appBar: AppBar(title: const Text('LGA Health & Safety')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (latest != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.cyan.shade700, Colors.cyan.shade500]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Latest Certificate', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              const SizedBox(height: 4),
              Text(latest.certificateNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text(latest.agency, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                _statusBadge(latest.status),
              ]),
              if (latest.expiryDate != null) ...[
                const SizedBox(height: 4),
                Text('Expires: ${DateFormat('dd MMM yyyy').format(latest.expiryDate!)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ],
              const SizedBox(height: 8),
              Row(children: [
                Text('Score: ${latest.score.toStringAsFixed(0)}/100', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
        ],
        Text('All Inspections (${inspections.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        if (inspections.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                Icon(Icons.healing_rounded, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text('No inspections recorded', style: TextStyle(color: Colors.grey.shade500)),
              ]),
            ),
          )
        else
          ...inspections.map((i) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(i.certificateNumber, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14), overflow: TextOverflow.ellipsis)),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    _statusBadge(i.status),
                    RoleGate(requiredPermission: Permission.manageLGAHealthPermits, child: IconButton(onPressed: () => _edit(i), icon: const Icon(Icons.edit_rounded, size: 18))),
                    RoleGate(requiredPermission: Permission.manageLGAHealthPermits, child: IconButton(onPressed: () => _delete(i.id), icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent))),
                  ]),
                ]),
                const SizedBox(height: 4),
                Text('${i.agency} — ${i.inspector}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Row(children: [
                  Text(DateFormat('dd MMM yyyy').format(i.inspectionDate), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const Spacer(),
                  Text('Score: ${i.score.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.cyan.shade700)),
                ]),
                if (i.expiryDate != null)
                  Text('Exp: ${DateFormat('dd MMM yyyy').format(i.expiryDate!)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ]),
            ),
          )),
      ]),
      floatingActionButton: RoleGate(
        requiredPermission: Permission.manageLGAHealthPermits,
        child: FloatingActionButton(
          onPressed: _add,
          backgroundColor: Colors.cyan.shade700,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color c;
    switch (status) {
      case 'valid': c = AppColors.primary; break;
      case 'expired': c = Colors.red; break;
      default: c = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
      child: Text(status.replaceAll('-', ' ').toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c)),
    );
  }
}
