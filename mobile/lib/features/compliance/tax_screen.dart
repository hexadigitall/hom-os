import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/compliance.dart';
import '../../data/compliance_store.dart';
import '../../utils/tax_engine.dart';
import '../../models/role.dart';
import '../../utils/role_gate.dart';
import '../../utils/theme.dart';
import '../../widgets/hom_widgets.dart';

class TaxScreen extends StatefulWidget {
  const TaxScreen({super.key});
  @override
  State<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends State<TaxScreen> {
  void _editConfig(StateTaxConfig config) {
    final nameCtl = TextEditingController(text: config.stateName);
    final rateCtl = TextEditingController(text: config.rate.toString());
    bool acc = config.appliesToAccommodation;
    bool food = config.appliesToFoodAndDrinks;
    bool other = config.appliesToOtherServices;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSB) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                              child: Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                      color: AppColors.grey300,
                                      borderRadius: BorderRadius.circular(2)))),
                          const SizedBox(height: 16),
                          Text(
                              config.stateName.isEmpty
                                  ? 'Add State Tax Config'
                                  : 'Edit ${config.stateName}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 17)),
                          const SizedBox(height: 16),
                          TextField(
                              controller: nameCtl,
                              decoration: const InputDecoration(
                                  labelText: 'State Name')),
                          const SizedBox(height: 12),
                          TextField(
                              controller: rateCtl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Tax Rate (%)',
                                  hintText: 'e.g. 5.0')),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            title: const Text('Applies to Accommodation',
                                style: TextStyle(fontSize: 13)),
                            value: acc,
                            onChanged: (v) => setSB(() => acc = v!),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          CheckboxListTile(
                            title: const Text('Applies to Food & Drinks',
                                style: TextStyle(fontSize: 13)),
                            value: food,
                            onChanged: (v) => setSB(() => food = v!),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          CheckboxListTile(
                            title: const Text('Applies to Other Services',
                                style: TextStyle(fontSize: 13)),
                            value: other,
                            onChanged: (v) => setSB(() => other = v!),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: RoleGate(
                              requiredPermission: Permission.manageTaxConfig,
                              child: ElevatedButton(
                                onPressed: () {
                                  final rate =
                                      double.tryParse(rateCtl.text) ?? 5.0;
                                  if (nameCtl.text.isEmpty) return;
                                  ComplianceStore.upsertTaxConfig(
                                      StateTaxConfig(
                                    stateName: nameCtl.text,
                                    rate: rate,
                                    appliesToAccommodation: acc,
                                    appliesToFoodAndDrinks: food,
                                    appliesToOtherServices: other,
                                  ));
                                  Navigator.pop(ctx);
                                  setState(() {});
                                },
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14)),
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

  @override
  Widget build(BuildContext context) {
    final configs = ComplianceStore.stateTaxConfigs;
    final reports = ComplianceStore.taxReports;

    return Scaffold(
      appBar: AppBar(title: const Text('State Consumption Tax', maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Configured States',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        ...configs.map((c) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(c.stateName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${c.rate}% rate'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.teal50,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('${c.rate}%',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.teal700)),
                  ),
                  const SizedBox(width: 4),
                  RoleGate(
                      requiredPermission: Permission.manageTaxConfig,
                      child: HomTileAction(
                          onPressed: () => _editConfig(c),
                          icon: Icons.edit_rounded)),
                  RoleGate(
                      requiredPermission: Permission.manageTaxConfig,
                      child: HomTileAction(
                          onPressed: () {
                            ComplianceStore.removeTaxConfig(c.stateName);
                            setState(() {});
                          },
                          icon: Icons.delete_rounded,
                          color: AppColors.redAccent)),
                ]),
              ),
            )),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: RoleGate(
            requiredPermission: Permission.manageTaxConfig,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _editConfig(StateTaxConfig(stateName: '', rate: 5.0)),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add State'),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Tax Reports',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        if (reports.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                Icon(Icons.account_balance_rounded,
                    size: 48, color: AppColors.grey300),
                const SizedBox(height: 8),
                Text('No reports filed yet',
                    style: TextStyle(color: AppColors.grey500)),
              ]),
            ),
          )
        else
          ...reports.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(
                              child: Text(
                                  '${r.stateName} — ${DateFormat('MMM yyyy').format(r.periodStart)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          _statusChip(r.status),
                        ]),
                        const SizedBox(height: 6),
                        Text('Sales: ${_fmt(r.totalSales)}',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.grey600)),
                        Text('Tax Due: ${_fmt(r.taxDue)}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal700)),
                        Align(
                            alignment: Alignment.centerRight,
                            child: RoleGate(
                                requiredPermission: Permission.manageTaxConfig,
                                child: IconButton(
                                    onPressed: () {
                                      ComplianceStore.removeTaxReport(r.id);
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.delete_rounded,
                                        size: 18,
                                        color: AppColors.redAccent)))),
                      ]),
                ),
              )),
      ]),
      floatingActionButton: RoleGate(
        requiredPermission: Permission.manageTaxConfig,
        child: FloatingActionButton.extended(
          onPressed: () {
            final periodEnd = DateTime.now();
            final periodStart = DateTime(periodEnd.year, periodEnd.month, 1);
            final salesCtl = TextEditingController(text: '500000');
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Generate Tax Report'),
                content: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.6),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(ctx).viewInsets.bottom),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                          'Period: ${DateFormat('MMM yyyy').format(periodStart)}'),
                      const SizedBox(height: 12),
                      TextField(
                        controller: salesCtl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Total Sales (₦)',
                            hintText: 'e.g. 500000'),
                      ),
                      const SizedBox(height: 8),
                      Text('${configs.length} state(s) configured',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.grey600)),
                      if (configs.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...configs.map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(c.stateName,
                                        style: const TextStyle(fontSize: 12)),
                                    Text(
                                        '${c.rate}% → ₦${((double.tryParse(salesCtl.text) ?? 0) * c.rate / 100).toStringAsFixed(0)}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.teal700)),
                                  ]),
                            )),
                      ],
                    ]),
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () {
                        final totalSales = double.tryParse(salesCtl.text) ?? 0;
                        if (totalSales <= 0) return;
                        for (final c in configs) {
                          final report = TaxEngine.generateReport(
                            stateName: c.stateName,
                            totalSales: totalSales,
                            periodStart: periodStart,
                            periodEnd: periodEnd,
                          );
                          ComplianceStore.addTaxReport(report);
                        }
                        Navigator.pop(ctx);
                        setState(() {});
                      },
                      child: const Text('Generate')),
                ],
              ),
            );
          },
          icon: const Icon(Icons.add_chart_rounded),
          label: const Text('Generate Report'),
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.white,
        ),
      ),
    );
  }

  Widget _statusChip(String s) {
    Color c;
    switch (s) {
      case 'filed':
        c = AppColors.teal;
        break;
      case 'paid':
        c = AppColors.primary;
        break;
      default:
        c = AppColors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(s.toUpperCase(),
          style:
              TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
    );
  }

  String _fmt(double a) =>
      '₦${a.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}
