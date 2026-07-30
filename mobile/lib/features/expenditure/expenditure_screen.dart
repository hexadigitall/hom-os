import 'package:flutter/material.dart';
import '../../models/expenditure.dart';
import '../../data/expenditure_store.dart';
import '../../features/reports/report_engine.dart';
import '../../utils/role_gate.dart';
import '../../utils/theme.dart';
import '../../models/role.dart';
import '../../data/role_store.dart';

class ExpenditureScreen extends StatefulWidget {
  const ExpenditureScreen({super.key});
  @override
  State<ExpenditureScreen> createState() => _ExpenditureScreenState();
}

class _ExpenditureScreenState extends State<ExpenditureScreen> {
  ExpenditureCategory? _catFilter;
  Department? _deptFilter;
  String _search = '';

  List<ExpenditureRecord> get _records {
    var list = ExpenditureStore.all;
    final defaultDept = RoleStore.currentRole.department;
    final effectiveDept = _deptFilter ?? defaultDept;
    if (effectiveDept != null) list = list.where((r) => r.department == effectiveDept).toList();
    if (_catFilter != null) list = list.where((r) => r.category == _catFilter).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((r) =>
        r.description.toLowerCase().contains(q) ||
        r.vendor.toLowerCase().contains(q) ||
        r.subcategory.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  void _add() => _showForm(null);

  void _edit(ExpenditureRecord r) => _showForm(r);

  void _showForm(ExpenditureRecord? existing) {
    final descCtl = TextEditingController(text: existing?.description ?? '');
    final subCtl = TextEditingController(text: existing?.subcategory ?? '');
    final amountCtl = TextEditingController(text: existing != null ? existing.amount.toString() : '');
    final vendorCtl = TextEditingController(text: existing?.vendor ?? '');
    final paymentCtl = TextEditingController(text: existing?.paymentMethod ?? '');
    final refCtl = TextEditingController(text: existing?.receiptRef ?? '');
    final notesCtl = TextEditingController(text: existing?.notes ?? '');
    ExpenditureCategory cat = existing?.category ?? ExpenditureCategory.other;
    Department? dept = existing?.department ?? RoleStore.currentRole.department;
    DateTime date = existing?.date ?? DateTime.now();

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
              Text(existing != null ? 'Edit Expenditure' : 'New Expenditure', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 16),
              DropdownButtonFormField<ExpenditureCategory>(
                initialValue: cat,
                items: ExpenditureCategory.values.map((c) => DropdownMenuItem(value: c, child: Row(children: [Icon(c.icon, size: 18), const SizedBox(width: 8), Text(c.displayName)])),
                ).toList(),
                onChanged: (v) => setSB(() => cat = v!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              TextField(controller: descCtl, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              TextField(controller: subCtl, decoration: const InputDecoration(labelText: 'Subcategory')),
              const SizedBox(height: 12),
              TextField(controller: amountCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₦)')),
              const SizedBox(height: 12),
              TextField(controller: vendorCtl, decoration: const InputDecoration(labelText: 'Vendor')),
              const SizedBox(height: 12),
              TextField(controller: paymentCtl, decoration: const InputDecoration(labelText: 'Payment Method')),
              const SizedBox(height: 12),
              TextField(controller: refCtl, decoration: const InputDecoration(labelText: 'Receipt Ref')),
              const SizedBox(height: 12),
              TextField(controller: notesCtl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
              const SizedBox(height: 12),
              DropdownButtonFormField<Department?>(
                initialValue: dept,
                items: [
                  DropdownMenuItem(value: null, child: const Text('All Departments')),
                  ...Department.values.map((d) => DropdownMenuItem(value: d, child: Text(d.name))),
                ],
                onChanged: (v) => setSB(() => dept = v),
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              const SizedBox(height: 12),
              Text('Date: ${date.toIso8601String().substring(0, 10)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: RoleGate(
                  requiredPermission: Permission.createExpenditure,
                  child: ElevatedButton(
                    onPressed: () {
                      final amt = double.tryParse(amountCtl.text) ?? 0;
                      if (descCtl.text.isEmpty || amt <= 0) return;
                      final r = ExpenditureRecord(
                        id: existing?.id ?? ExpenditureStore.generateId(),
                        date: date, category: cat,
                        subcategory: subCtl.text, description: descCtl.text,
                        amount: amt, vendor: vendorCtl.text,
                        paymentMethod: paymentCtl.text, receiptRef: refCtl.text,
                        notes: notesCtl.text, department: dept,
                      );
                      if (existing != null) {
                        ExpenditureStore.update(existing.id, r);
                      } else {
                        ExpenditureStore.add(r);
                      }
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Text(existing != null ? 'Update' : 'Add Record'),
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
    ExpenditureStore.remove(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final records = _records;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenditure'),
        actions: [
          if (records.isNotEmpty)
            RoleGate(
              requiredPermission: Permission.createExpenditure,
              child: TextButton(
                onPressed: () { ExpenditureStore.clear(); setState(() {}); },
                child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
              ),
            ),
        ],
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          color: Colors.white,
          child: Column(children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by description, vendor...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip(null, 'All'),
                  ...ExpenditureCategory.values.map((c) => _filterChip(c, c.displayName)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _deptChip(null, 'My Dept'),
                  ...Department.values.map((d) => _deptChip(d, d.name)),
                ],
              ),
            ),
          ]),
        ),
        Expanded(
          child: records.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No expenditure records', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Tap + to add a record, or import via Upload', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: records.length,
                  itemBuilder: (ctx, i) {
                    final r = records[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showDetail(r),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(r.category.icon, size: 20, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(ReportEngine.formatCurrency(r.amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(r.category.displayName, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                Text('${r.date.toIso8601String().substring(0, 10)}${r.vendor.isNotEmpty ? ' • ${r.vendor}' : ''}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ]),
                            ),
                            RoleGate(
                              requiredPermission: Permission.createExpenditure,
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                onPressed: () => _delete(r.id),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
      floatingActionButton: RoleGate(
        requiredPermission: Permission.createExpenditure,
        child: FloatingActionButton(
          onPressed: _add,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _filterChip(ExpenditureCategory? cat, String label) {
    final active = _catFilter == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
        selected: active,
        onSelected: (_) => setState(() => _catFilter = cat),
        visualDensity: VisualDensity.compact,
        selectedColor: AppColors.primary.withValues(alpha: 0.1),
        backgroundColor: Colors.grey.shade100,
      ),
    );
  }

  Widget _deptChip(Department? d, String label) {
    final active = _deptFilter == d;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
        selected: active,
        onSelected: (_) => setState(() => _deptFilter = d),
        visualDensity: VisualDensity.compact,
        selectedColor: AppColors.primary.withValues(alpha: 0.1),
        backgroundColor: Colors.grey.shade100,
      ),
    );
  }

  void _showDetail(ExpenditureRecord r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(r.category.icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Text(ReportEngine.formatCurrency(r.amount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
              const Spacer(),
              RoleGate(
                requiredPermission: Permission.createExpenditure,
                child: IconButton(onPressed: () { Navigator.pop(context); _edit(r); }, icon: const Icon(Icons.edit_rounded, size: 20)),
              ),
            ]),
            const SizedBox(height: 12),
            _detailRow('Category', r.category.displayName),
            _detailRow('Subcategory', r.subcategory),
            _detailRow('Description', r.description),
            _detailRow('Date', r.date.toIso8601String().substring(0, 10)),
            _detailRow('Vendor', r.vendor),
            _detailRow('Payment Method', r.paymentMethod),
            _detailRow('Receipt Ref', r.receiptRef),
            _detailRow('Notes', r.notes),
          ]),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 96, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
        const SizedBox(width: 4),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
