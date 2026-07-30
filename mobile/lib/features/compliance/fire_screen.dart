import 'package:flutter/material.dart';
import '../../models/compliance.dart';
import '../../data/compliance_store.dart';
import '../../models/role.dart';
import '../../utils/role_gate.dart';
import '../../utils/theme.dart';

class FireScreen extends StatefulWidget {
  const FireScreen({super.key});

  @override
  State<FireScreen> createState() => _FireScreenState();
}

class _FireScreenState extends State<FireScreen> {
  void _add() => _showForm(null);

  void _edit(FireServiceCert c) => _showForm(c);

  void _showForm(FireServiceCert? existing) {
    final certNumCtl = TextEditingController(text: existing?.certificateNumber ?? '');
    final officeCtl = TextEditingController(text: existing?.fireServiceOffice ?? '');
    final scoreCtl = TextEditingController(text: existing?.inspectionScore?.toString() ?? '');
    DateTime issueDate = existing?.issueDate ?? DateTime.now();
    DateTime expiryDate = existing?.expiryDate ?? DateTime.now().add(const Duration(days: 365));

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
              Text(existing != null ? 'Edit Fire Service Certificate' : 'Add Fire Service Certificate', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 16),
              TextField(controller: certNumCtl, decoration: const InputDecoration(labelText: 'Certificate Number')),
              const SizedBox(height: 12),
              TextField(controller: officeCtl, decoration: const InputDecoration(labelText: 'Fire Service Office')),
              const SizedBox(height: 12),
              TextField(controller: scoreCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Inspection Score (0-100)')),
              const SizedBox(height: 12),
              Text('Issue Date: ${issueDate.toIso8601String().substring(0, 10)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(context: context, initialDate: issueDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (picked != null) setSB(() => issueDate = picked);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Change Issue Date'),
              ),
              Text('Expiry Date: ${expiryDate.toIso8601String().substring(0, 10)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(context: context, initialDate: expiryDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
                  if (picked != null) setSB(() => expiryDate = picked);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Change Expiry Date'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: RoleGate(
                  requiredPermission: Permission.manageFireServiceCertificates,
                  child: ElevatedButton(
                    onPressed: () {
                      if (certNumCtl.text.isEmpty) return;
                      final now = DateTime.now();
                      final status = expiryDate.isBefore(now) ? 'expired' : 'valid';
                      final c = FireServiceCert(
                        id: existing?.id ?? ComplianceStore.genId(),
                        certificateNumber: certNumCtl.text,
                        issueDate: issueDate,
                        expiryDate: expiryDate,
                        fireServiceOffice: officeCtl.text,
                        status: status,
                        inspectionScore: double.tryParse(scoreCtl.text),
                      );
                      if (existing != null) {
                        ComplianceStore.updateFireServiceCert(existing.id, c);
                      } else {
                        ComplianceStore.addFireServiceCert(c);
                      }
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Save'),
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
    ComplianceStore.removeFireServiceCert(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final certs = ComplianceStore.fireServiceCerts;
    final latest = ComplianceStore.latestFireCert;

    return Scaffold(
      appBar: AppBar(title: const Text('Fire Service Certificates')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (latest != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.red.shade700, Colors.red.shade500]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Latest Certificate', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              const SizedBox(height: 4),
              Text(latest.certificateNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 8),
              Row(children: [
                Flexible(child: Text(latest.fireServiceOffice, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                _badge(latest.status),
              ]),
              const SizedBox(height: 4),
              Text('Issued: ${latest.issueDate.toIso8601String().substring(0, 10)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              Text('Expires: ${latest.expiryDate.toIso8601String().substring(0, 10)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              if (latest.inspectionScore != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Score: ${latest.inspectionScore!.toStringAsFixed(0)}/100', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
            ]),
          ),
          const SizedBox(height: 16),
        ],
        Text('All Certificates (${certs.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        if (certs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                Icon(Icons.local_fire_department_rounded, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text('No fire service certificates', style: TextStyle(color: Colors.grey.shade500)),
              ]),
            ),
          )
        else
          ...certs.map((c) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.local_fire_department_rounded, size: 18, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text(c.certificateNumber, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14), overflow: TextOverflow.ellipsis)),
                  _badge(c.status),
                  if (c.expiresSoon && !c.isExpired)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Text('SOON', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.orange.shade700)),
                    ),
                  RoleGate(requiredPermission: Permission.manageFireServiceCertificates, child: IconButton(onPressed: () => _edit(c), icon: const Icon(Icons.edit_rounded, size: 18))),
                  RoleGate(requiredPermission: Permission.manageFireServiceCertificates, child: IconButton(onPressed: () => _delete(c.id), icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent))),
                ]),
                const SizedBox(height: 4),
                Text(c.fireServiceOffice, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Row(children: [
                  Text('Issued: ${c.issueDate.toIso8601String().substring(0, 10)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  const SizedBox(width: 12),
                  Text('Expires: ${c.expiryDate.toIso8601String().substring(0, 10)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ]),
              ]),
            ),
          )),
      ]),
      floatingActionButton: RoleGate(
        requiredPermission: Permission.manageFireServiceCertificates,
        child: FloatingActionButton(
          onPressed: _add,
          backgroundColor: Colors.red.shade700,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _badge(String status) {
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
