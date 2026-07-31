import 'package:flutter/material.dart';
import '../../models/back_office.dart';
import '../../models/expenditure.dart';
import '../../data/back_office_store.dart';
import '../../data/expenditure_store.dart';
import '../../widgets/hom_widgets.dart';
import '../../models/role.dart';
import '../../data/role_store.dart';
import '../../utils/role_gate.dart';
import '../../utils/theme.dart';

final Color _primary = AppColors.primary;

class BackOfficeScreen extends StatefulWidget {
  const BackOfficeScreen({super.key});
  @override
  State<BackOfficeScreen> createState() => _BackOfficeScreenState();
}

class _BackOfficeScreenState extends State<BackOfficeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() { super.initState(); _tabController = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Back Office & Supply Chain'),
        bottom: TabBar(
          controller: _tabController, isScrollable: true,
          indicatorColor: _primary, labelColor: _primary, unselectedLabelColor: AppColors.grey500,
          tabs: const [
            Tab(text: 'Procurement', icon: Icon(Icons.receipt_long_rounded, size: 15)),
            Tab(text: 'Payroll', icon: Icon(Icons.account_balance_wallet_rounded, size: 15)),
            Tab(text: 'Tax Config', icon: Icon(Icons.tune_rounded, size: 15)),
          ],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [
        _ProcurementTab(onChange: () => setState(() {})),
        _PayrollTab(onChange: () => setState(() {})),
        _TaxConfigTab(onChange: () => setState(() {})),
      ]),
    );
  }
}

// ═══════════════════════════ PROCUREMENT ═══════════════════════════

class _ProcurementTab extends StatelessWidget {
  final VoidCallback onChange;
  const _ProcurementTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final orders = BackOfficeStore.procurementForCurrentDept;
    final openOrders = orders.where((p) => p.status != ProcurementStatus.delivered && p.status != ProcurementStatus.cancelled).toList();
    final totalSpend = orders.where((p) => p.status == ProcurementStatus.delivered).fold(0.0, (s, p) => s + p.amount);
    return Scaffold(
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(12), color: AppColors.grey50,
          child: Wrap(children: [
            HomMetricCard(label: 'Open Orders', value: '${openOrders.length}', color: AppColors.orange),
            HomMetricCard(label: 'Total Spend', value: '₦${_fmt(totalSpend)}', color: _primary),
            HomMetricCard(label: 'Total Orders', value: '${orders.length}', color: AppColors.blue),
          ]),
        ),
        Expanded(
          child: orders.isEmpty
              ? const Center(child: Text('No purchase orders'))
              : ListView.builder(padding: const EdgeInsets.all(8), itemCount: orders.length, itemBuilder: (ctx, i) {
                  final po = orders[i];
                  return Card(child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: po.status == ProcurementStatus.delivered ? _primary
                          : po.status == ProcurementStatus.cancelled ? AppColors.red
                          : po.status == ProcurementStatus.approved ? AppColors.blue
                          : AppColors.grey500,
                      child: Text(po.status.name[0].toUpperCase(), style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
                    ),
                    title: Text(po.vendorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${po.items}  •  ₦${_fmt(po.amount)}  •  ${po.orderDate.toIso8601String().substring(0, 10)}', style: const TextStyle(fontSize: 11)),
                    trailing: RoleGate(requiredPermission: Permission.managePurchaseOrders, child: PopupMenuButton<String>(
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        if (po.status == ProcurementStatus.draft)
                          const PopupMenuItem(value: 'approve', child: Text('Approve')),
                        if (po.status == ProcurementStatus.approved)
                          const PopupMenuItem(value: 'deliver', child: Text('Mark Delivered')),
                        if (po.status != ProcurementStatus.delivered && po.status != ProcurementStatus.cancelled)
                          const PopupMenuItem(value: 'cancel', child: Text('Cancel', style: TextStyle(color: AppColors.red))),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.red))),
                      ],
                      onSelected: (v) {
                        if (v == 'edit') {
                          _editForm(context, po);
                        } else                         if (v == 'approve') {
                          BackOfficeStore.updateProcurement(po.id, ProcurementOrder(id: po.id, vendorName: po.vendorName, items: po.items, notes: po.notes, amount: po.amount, status: ProcurementStatus.approved, orderDate: po.orderDate, department: po.department));
                          onChange();
                        } else if (v == 'deliver') {
                          BackOfficeStore.updateProcurement(po.id, ProcurementOrder(id: po.id, vendorName: po.vendorName, items: po.items, notes: po.notes, amount: po.amount, status: ProcurementStatus.delivered, orderDate: po.orderDate, deliveryDate: DateTime.now(), department: po.department));
                          ExpenditureStore.add(ExpenditureRecord(
                            id: 'po_${po.id}', date: DateTime.now(), category: ExpenditureCategory.procurement,
                            subcategory: 'Stock', description: 'PO: ${po.items} from ${po.vendorName}', amount: po.amount, vendor: po.vendorName,
                          ));
                          onChange();
                        } else if (v == 'cancel') {
                          BackOfficeStore.updateProcurement(po.id, ProcurementOrder(id: po.id, vendorName: po.vendorName, items: po.items, notes: po.notes, amount: po.amount, status: ProcurementStatus.cancelled, orderDate: po.orderDate, department: po.department));
                          onChange();
                        } else if (v == 'delete') { BackOfficeStore.removeProcurement(po.id); onChange(); }
                      },
                    )),
                  ));
                }),
        ),
      ]),
      floatingActionButton: RoleGate(requiredPermission: Permission.managePurchaseOrders, child: FloatingActionButton(
        backgroundColor: _primary, foregroundColor: AppColors.white,
        child: const Icon(Icons.add),
        onPressed: () => _showForm(context),
      )),
    );
  }

  void _showForm(BuildContext context) {
    final vendorCtl = TextEditingController();
    final itemsCtl = TextEditingController();
    final amtCtl = TextEditingController();
    final notesCtl = TextEditingController();
    Department? dept = RoleStore.currentRole.department;

    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSB) => Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('New Purchase Order', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(controller: vendorCtl, decoration: const InputDecoration(labelText: 'Vendor Name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: itemsCtl, decoration: const InputDecoration(labelText: 'Items', border: OutlineInputBorder()), maxLines: 2),
          const SizedBox(height: 12),
          TextField(controller: amtCtl, decoration: const InputDecoration(labelText: 'Amount (₦)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          TextField(controller: notesCtl, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()), maxLines: 2),
          const SizedBox(height: 12),
          DropdownButtonFormField<Department?>(
            initialValue: dept,
            items: [
              DropdownMenuItem(value: null, child: const Text('All Departments')),
              ...Department.values.map((d) => DropdownMenuItem(value: d, child: Text(d.name))),
            ],
            onChanged: (v) => setSB(() => dept = v),
            decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {
                if (vendorCtl.text.isEmpty || itemsCtl.text.isEmpty) return;
                final po = ProcurementOrder(
                  id: 'bo_${DateTime.now().millisecondsSinceEpoch}',
                  vendorName: vendorCtl.text, items: itemsCtl.text,
                  notes: notesCtl.text.isEmpty ? null : notesCtl.text,
                  amount: double.tryParse(amtCtl.text) ?? 0,
                  department: dept,
                );
                BackOfficeStore.addProcurement(po);
                Navigator.pop(ctx);
                onChange();
              },
              child: const Text('Create Order'),
            ),
          ),
          ]),
        ),
      )),
    );
  }

  void _editForm(BuildContext context, ProcurementOrder po) {
    final vendorCtl = TextEditingController(text: po.vendorName);
    final itemsCtl = TextEditingController(text: po.items);
    final amtCtl = TextEditingController(text: po.amount.toStringAsFixed(0));
    final notesCtl = TextEditingController(text: po.notes ?? '');
    Department? dept = po.department ?? RoleStore.currentRole.department;

    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSB) => Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(height: 4, width: 40, margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2))),
            const Text('Edit Purchase Order', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(controller: vendorCtl, decoration: const InputDecoration(labelText: 'Vendor Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: itemsCtl, decoration: const InputDecoration(labelText: 'Items', border: OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 12),
            TextField(controller: amtCtl, decoration: const InputDecoration(labelText: 'Amount (₦)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: notesCtl, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 12),
            DropdownButtonFormField<Department?>(
              initialValue: dept,
              items: [
                DropdownMenuItem(value: null, child: const Text('All Departments')),
                ...Department.values.map((d) => DropdownMenuItem(value: d, child: Text(d.name))),
              ],
              onChanged: (v) => setSB(() => dept = v),
              decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  if (vendorCtl.text.isEmpty || itemsCtl.text.isEmpty) return;
                  final updated = ProcurementOrder(
                    id: po.id,
                    vendorName: vendorCtl.text, items: itemsCtl.text,
                    notes: notesCtl.text.isEmpty ? null : notesCtl.text,
                    amount: double.tryParse(amtCtl.text) ?? po.amount,
                    status: po.status, orderDate: po.orderDate, deliveryDate: po.deliveryDate,
                    department: dept,
                  );
                  BackOfficeStore.updateProcurement(po.id, updated);
                  Navigator.pop(ctx);
                  onChange();
                },
                child: const Text('Save Changes'),
              ),
            ),
          ]),
        ),
      )),
    );
  }
}

// ═══════════════════════════ PAYROLL ═══════════════════════════

class _PayrollTab extends StatelessWidget {
  final VoidCallback onChange;
  const _PayrollTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final records = BackOfficeStore.payrollForCurrentDept;
    final pending = records.where((p) => p.status == PayrollStatus.pending).toList();
    return Scaffold(
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(12), color: AppColors.grey50,
          child: Wrap(children: [
            HomMetricCard(label: 'Pending', value: '${pending.length}', color: AppColors.orange),
            HomMetricCard(label: 'Paid', value: '${records.length - pending.length}', color: _primary),
            HomMetricCard(label: 'Total Paid', value: '₦${_fmt(BackOfficeStore.totalPaid)}', color: AppColors.blue),
          ]),
        ),
        Expanded(
          child: records.isEmpty
              ? const Center(child: Text('No payroll records'))
              : ListView.builder(padding: const EdgeInsets.all(8), itemCount: records.length, itemBuilder: (ctx, i) {
                  final r = records[i];
                  return Card(child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: r.status == PayrollStatus.paid ? _primary : AppColors.orange,
                      child: Text(r.staffName[0], style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
                    ),
                    title: Text(r.staffName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${r.department}  •  Gross: ₦${_fmt(r.grossPay)}  •  Net: ₦${_fmt(r.netPay)}  •  Period: ${r.periodStart.toIso8601String().substring(0, 10)}', style: const TextStyle(fontSize: 11)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('₦${_fmt(r.netPay)}', style: TextStyle(fontWeight: FontWeight.w700, color: r.status == PayrollStatus.paid ? _primary : AppColors.orange, fontSize: 12)),
                      if (r.status == PayrollStatus.pending)
                        RoleGate(requiredPermission: Permission.runPayroll, child: IconButton(
                          icon: Icon(Icons.check_circle, color: _primary),
                          tooltip: 'Mark Paid',
                          onPressed: () {
                            BackOfficeStore.updatePayroll(r.id, PayrollRecord(id: r.id, staffName: r.staffName, department: r.department, basicSalary: r.basicSalary, allowances: r.allowances, deductions: r.deductions, payeTax: r.payeTax, pensionContribution: r.pensionContribution, netPay: r.netPay, status: PayrollStatus.paid, periodStart: r.periodStart, periodEnd: r.periodEnd, paidDate: DateTime.now()));
                            onChange();
                          },
                        )),
                      RoleGate(requiredPermission: Permission.runPayroll, child: PopupMenuButton<String>(
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'detail', child: Text('View Breakdown')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.red))),
                        ],
                        onSelected: (v) {
                          if (v == 'edit') {
                            _editForm(context, r);
                          } else if (v == 'detail') {
                            showDialog(context: context, builder: (ctx) => AlertDialog(
                              title: Text('${r.staffName} — Pay Breakdown'),
                              content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                _row('Basic Salary', '₦${_fmt(r.basicSalary)}'),
                                _row('Allowances', '₦${_fmt(r.allowances)}'),
                                _row('Gross Pay', '₦${_fmt(r.grossPay)}'),
                                const Divider(),
                                _row('PAYE Tax', '-₦${_fmt(r.payeTax)}', AppColors.red),
                                _row('Pension (8%)', '-₦${_fmt(r.pensionContribution)}', AppColors.red),
                                _row('Other Deductions', '-₦${_fmt(r.deductions)}', AppColors.red),
                                const Divider(),
                                _row('Net Pay', '₦${_fmt(r.netPay)}', _primary),
                              ]),
                              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                            ));
                          }
                          if (v == 'delete') { BackOfficeStore.removePayroll(r.id); onChange(); }
                        },
                      )),
                    ]),
                  ));
                }),
        ),
      ]),
      floatingActionButton: RoleGate(requiredPermission: Permission.runPayroll, child: FloatingActionButton(
        backgroundColor: _primary, foregroundColor: AppColors.white,
        child: const Icon(Icons.add),
        onPressed: () => _showForm(context),
      )),
    );
  }

  Widget _row(String label, String value, [Color? color]) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color))]),
  );

  void _showForm(BuildContext context) {
    final nameCtl = TextEditingController();
    final deptCtl = TextEditingController();
    final basicCtl = TextEditingController();
    final allowCtl = TextEditingController();
    final deductCtl = TextEditingController();

    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Add Payroll Record', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Staff Name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: deptCtl, decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: basicCtl, decoration: const InputDecoration(labelText: 'Basic Salary (₦)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: allowCtl, decoration: const InputDecoration(labelText: 'Allowances (₦)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          TextField(controller: deductCtl, decoration: const InputDecoration(labelText: 'Other Deductions (₦)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {
                if (nameCtl.text.isEmpty) return;
                final basic = double.tryParse(basicCtl.text) ?? 0;
                final allow = double.tryParse(allowCtl.text) ?? 0;
                final deduct = double.tryParse(deductCtl.text) ?? 0;
                final gross = basic + allow;
                final taxConfig = BackOfficeStore.taxConfig;
                final payeTax = gross * 0.07;
                final pensEmp = basic * taxConfig.pensionEmployeeRate / 100;
                final netPay = gross - deduct - payeTax - pensEmp;
                final now = DateTime.now();
                final monthStart = DateTime(now.year, now.month, 1);
                final monthEnd = DateTime(now.year, now.month + 1, 0);

                final rec = PayrollRecord(
                  id: 'bo_${DateTime.now().millisecondsSinceEpoch}',
                  staffName: nameCtl.text, department: deptCtl.text,
                  basicSalary: basic, allowances: allow, deductions: deduct,
                  payeTax: payeTax, pensionContribution: pensEmp, netPay: netPay,
                  periodStart: monthStart, periodEnd: monthEnd,
                );
                BackOfficeStore.addPayroll(rec);
                Navigator.pop(ctx);
                onChange();
              },
              child: const Text('Add Record'),
            ),
          ),
          ]),
        ),
      ),
    );
  }

  void _editForm(BuildContext context, PayrollRecord r) {
    final nameCtl = TextEditingController(text: r.staffName);
    final deptCtl = TextEditingController(text: r.department);
    final basicCtl = TextEditingController(text: r.basicSalary.toStringAsFixed(0));
    final allowCtl = TextEditingController(text: r.allowances.toStringAsFixed(0));
    final deductCtl = TextEditingController(text: r.deductions.toStringAsFixed(0));

    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(height: 4, width: 40, margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2))),
            const Text('Edit Payroll Record', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Staff Name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: deptCtl, decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: basicCtl, decoration: const InputDecoration(labelText: 'Basic Salary (₦)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: allowCtl, decoration: const InputDecoration(labelText: 'Allowances (₦)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          TextField(controller: deductCtl, decoration: const InputDecoration(labelText: 'Other Deductions (₦)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {
                if (nameCtl.text.isEmpty) return;
                final basic = double.tryParse(basicCtl.text) ?? r.basicSalary;
                final allow = double.tryParse(allowCtl.text) ?? r.allowances;
                final deduct = double.tryParse(deductCtl.text) ?? r.deductions;
                final gross = basic + allow;
                final taxConfig = BackOfficeStore.taxConfig;
                final payeTax = gross * 0.07;
                final pensEmp = basic * taxConfig.pensionEmployeeRate / 100;
                final netPay = gross - deduct - payeTax - pensEmp;

                final updated = PayrollRecord(
                  id: r.id,
                  staffName: nameCtl.text, department: deptCtl.text,
                  basicSalary: basic, allowances: allow, deductions: deduct,
                  payeTax: payeTax, pensionContribution: pensEmp, netPay: netPay,
                  periodStart: r.periodStart, periodEnd: r.periodEnd,
                  status: r.status, paidDate: r.paidDate,
                );
                BackOfficeStore.updatePayroll(r.id, updated);
                Navigator.pop(ctx);
                onChange();
              },
              child: const Text('Save Changes'),
            ),
          ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════ TAX CONFIG ═══════════════════════════

class _TaxConfigTab extends StatelessWidget {
  final VoidCallback onChange;
  const _TaxConfigTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final t = BackOfficeStore.taxConfig;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.tune_rounded, color: _primary),
            const SizedBox(width: 8),
            Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: t.active ? _primary.withValues(alpha: 0.1) : AppColors.grey100, borderRadius: BorderRadius.circular(12)),
              child: Text(t.active ? 'Active' : 'Inactive', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t.active ? _primary : AppColors.grey500)),
            ),
          ]),
          const SizedBox(height: 16),
          _configRow('Currency', '${t.currencyCode} (${t.currencySymbol})'),
          const Divider(),
          _configRow('VAT Rate', '${t.vatRate.toStringAsFixed(1)}%'),
          _configRow('CIT Rate', '${t.citRate.toStringAsFixed(1)}%'),
          _configRow('LGA Dev. Levy', '${t.lgaDevelopmentLevy.toStringAsFixed(1)}%'),
          const Divider(),
          _configRow('Pension (Employee)', '${t.pensionEmployeeRate.toStringAsFixed(1)}%'),
          _configRow('Pension (Employer)', '${t.pensionEmployerRate.toStringAsFixed(1)}%'),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: RoleGate(requiredPermission: Permission.manageTaxConfig, child: OutlinedButton.icon(
              onPressed: () => _editForm(context, t),
              icon: Icon(Icons.edit_rounded, size: 16),
              label: const Text('Edit Configuration'),
              style: OutlinedButton.styleFrom(foregroundColor: _primary, side: BorderSide(color: _primary)),
            ))),
            const SizedBox(width: 8),
            RoleGate(requiredPermission: Permission.manageTaxConfig, child: OutlinedButton.icon(
              onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                title: const Text('Reset Tax Config?'),
                content: const Text('This will reset all tax settings to defaults.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  TextButton(onPressed: () { BackOfficeStore.resetTaxConfig(); Navigator.pop(ctx); onChange(); }, child: const Text('Reset', style: TextStyle(color: AppColors.red))),
                ],
              )),
              icon: Icon(Icons.restart_alt_rounded, size: 16, color: AppColors.red400),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.red400, side: BorderSide(color: AppColors.red400)),
            )),
          ]),
        ]),
      )),
      const SizedBox(height: 16),
      const Text('Nigeria Tax Notes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      const SizedBox(height: 8),
      Card(child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _note('PAYE: 7% of gross for ≤₦300k, progressive bands above'),
          _note('CIT: 30% for large companies, 20% for SMEs'),
          _note('VAT: 7.5% standard rate (2026)'),
          _note('LGA Dev. Levy: 1% of assessable profit'),
          _note('Pension: 8% employee + 10% employer'),
        ]),
      )),
    ]);
  }

  Widget _configRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.grey500))),
      const SizedBox(width: 8),
      Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), textAlign: TextAlign.right)),
    ]),
  );

  Widget _note(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('• ', style: TextStyle(fontSize: 12)),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.grey500))),
    ]),
  );

  void _editForm(BuildContext context, TaxConfiguration t) {
    final vatCtl = TextEditingController(text: t.vatRate.toStringAsFixed(1));
    final citCtl = TextEditingController(text: t.citRate.toStringAsFixed(1));
    final lgaCtl = TextEditingController(text: t.lgaDevelopmentLevy.toStringAsFixed(1));
    final pensEmpCtl = TextEditingController(text: t.pensionEmployeeRate.toStringAsFixed(1));
    final pensEmprCtl = TextEditingController(text: t.pensionEmployerRate.toStringAsFixed(1));
    String currency = t.currencyCode;

    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Tax Configuration', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: vatCtl, decoration: const InputDecoration(labelText: 'VAT Rate (%)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: citCtl, decoration: const InputDecoration(labelText: 'CIT Rate (%)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: lgaCtl, decoration: const InputDecoration(labelText: 'LGA Levy (%)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(child: DropdownButtonFormField<String>(
                initialValue: currency,
                decoration: const InputDecoration(labelText: 'Currency', border: OutlineInputBorder()),
                items: ['NGN', 'USD', 'EUR', 'GBP'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) { if (v != null) setSheet(() => currency = v); },
              )),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: pensEmpCtl, decoration: const InputDecoration(labelText: 'Pension (Emp %)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: pensEmprCtl, decoration: const InputDecoration(labelText: 'Pension (Empr %)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  BackOfficeStore.updateTaxConfig(TaxConfiguration(
                    id: t.id, name: t.name,
                    vatRate: double.tryParse(vatCtl.text) ?? t.vatRate,
                    citRate: double.tryParse(citCtl.text) ?? t.citRate,
                    lgaDevelopmentLevy: double.tryParse(lgaCtl.text) ?? t.lgaDevelopmentLevy,
                    pensionEmployeeRate: double.tryParse(pensEmpCtl.text) ?? t.pensionEmployeeRate,
                    pensionEmployerRate: double.tryParse(pensEmprCtl.text) ?? t.pensionEmployerRate,
                    currencyCode: currency,
                    currencySymbol: currency == 'NGN' ? '\u20A6' : currency == 'USD' ? '\$' : currency == 'EUR' ? '\u20AC' : '\u00A3',
                  ));
                  Navigator.pop(ctx);
                  onChange();
                },
                child: const Text('Save Configuration'),
              ),
            ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════ SHARED ═══════════════════════════

String _fmt(double n) => n.toStringAsFixed(0);
