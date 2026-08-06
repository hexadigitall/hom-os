import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/compliance.dart';
import '../../data/compliance_store.dart';
import '../../models/role.dart';
import '../../utils/role_gate.dart';
import 'package:hom_mobile/utils/theme.dart';

class ScumlScreen extends StatefulWidget {
  const ScumlScreen({super.key});
  @override
  State<ScumlScreen> createState() => _ScumlScreenState();
}

class _ScumlScreenState extends State<ScumlScreen> {
  void _add() => _showForm(null);

  void _edit(ScumlTransaction t) => _showForm(t);

  void _showForm(ScumlTransaction? existing) {
    final guestCtl = TextEditingController(text: existing?.guestName ?? '');
    final addressCtl = TextEditingController(text: existing?.address ?? '');
    final idNumCtl = TextEditingController(text: existing?.idNumber ?? '');
    final amountCtl = TextEditingController(text: existing != null ? existing.amount.toString() : '');
    final purposeCtl = TextEditingController(text: existing?.purpose ?? '');
    DateTime date = existing?.date ?? DateTime.now();
    String idType = existing?.idType ?? 'National ID';

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
              const Text('New SCUML Transaction', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 16),
              TextField(controller: guestCtl, decoration: const InputDecoration(labelText: 'Guest Name', hintText: 'Full name as on ID')),
              const SizedBox(height: 12),
              TextField(controller: addressCtl, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: idType,
                items: ['National ID', 'International Passport', "Driver's License", 'Voter ID', 'BVN'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setSB(() => idType = v!),
                decoration: const InputDecoration(labelText: 'ID Type'),
              ),
              const SizedBox(height: 12),
              TextField(controller: idNumCtl, decoration: const InputDecoration(labelText: 'ID Number')),
              const SizedBox(height: 12),
              TextField(controller: amountCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₦)')),
              const SizedBox(height: 12),
              TextField(controller: purposeCtl, decoration: const InputDecoration(labelText: 'Purpose of Transaction')),
              const SizedBox(height: 12),
              Text('Date: ${date.toIso8601String().substring(0, 10)}', style: TextStyle(color: AppColors.grey600, fontSize: 13)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: RoleGate(
                  requiredPermission: Permission.captureGuestNIN,
                  child: ElevatedButton(
                    onPressed: () {
                      final amt = double.tryParse(amountCtl.text) ?? 0;
                      if (guestCtl.text.isEmpty || idNumCtl.text.isEmpty || amt <= 0) return;
                      final t = ScumlTransaction(
                        id: existing?.id ?? ComplianceStore.genId(), date: date,
                        guestName: guestCtl.text, address: addressCtl.text,
                        idType: idType, idNumber: idNumCtl.text,
                        amount: amt, purpose: purposeCtl.text,
                      );
                      if (existing != null) {
                        ComplianceStore.updateScuml(existing.id, t);
                      } else {
                        ComplianceStore.addScuml(t);
                      }
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Log Transaction'),
                  ),
                ),
              ),
            ]),
          ),
        ),
      )),
    );
  }

  Future<void> _exportCsv() async {
    final records = ComplianceStore.scumlTransactions;
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No transactions to export')));
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln(ScumlTransaction.csvHeader());
    for (final r in records) {
      buffer.writeln(r.toCsvRow().join(','));
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/scuml_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    await File(path).writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(path)], text: 'SCUML Transaction Report');
  }

  void _delete(String id) {
    ComplianceStore.removeScuml(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final records = ComplianceStore.scumlTransactions;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SCUML', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (records.isNotEmpty)
            IconButton(onPressed: _exportCsv, icon: const Icon(Icons.file_download_rounded), tooltip: 'Export CSV'),
        ],
      ),
      body: records.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.gavel_rounded, size: 64, color: AppColors.grey300),
                const SizedBox(height: 12),
                Text('No SCUML transactions', style: TextStyle(color: AppColors.grey500)),
                const SizedBox(height: 4),
                Text('Transactions above ₦5M must be reported', style: TextStyle(fontSize: 12, color: AppColors.grey400)),
              ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: records.length + 1,
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${records.length} transaction${records.length == 1 ? '' : 's'}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('Total: ${_fmt(ComplianceStore.scumlTotal)}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.green700)),
                    ]),
                  );
                }
                final r = records[i - 1];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Flexible(child: Text(r.guestName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15), overflow: TextOverflow.ellipsis)),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          RoleGate(requiredPermission: Permission.captureGuestNIN, child: IconButton(onPressed: () => _edit(r), icon: const Icon(Icons.edit_rounded, size: 18))),
                          RoleGate(requiredPermission: Permission.captureGuestNIN, child: IconButton(onPressed: () => _delete(r.id), icon: const Icon(Icons.delete_rounded, size: 18, color: AppColors.redAccent))),
                        ]),
                      ]),
                      const SizedBox(height: 4),
                      Text('${r.idType}: ${r.idNumber}', style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                      Text(r.address, style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(r.date.toIso8601String().substring(0, 10), style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                        Text(_fmt(r.amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.indigo)),
                      ]),
                      if (r.purpose.isNotEmpty)
                        Text(r.purpose, style: TextStyle(fontSize: 11, color: AppColors.grey500)),
                    ]),
                  ),
                );
              },
            ),
      floatingActionButton: RoleGate(
        requiredPermission: Permission.captureGuestNIN,
        child: FloatingActionButton(
          onPressed: _add,
          backgroundColor: AppColors.indigo,
          child: const Icon(Icons.add, color: AppColors.white),
        ),
      ),
    );
  }

  String _fmt(double a) => '₦${a.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}
