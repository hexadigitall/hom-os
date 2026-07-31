import 'package:flutter/material.dart';
import '../../models/compliance.dart';
import '../../data/compliance_store.dart';
import '../../models/role.dart';
import '../../utils/role_gate.dart';
import 'package:hom_mobile/utils/theme.dart';

class CashScreen extends StatefulWidget {
  const CashScreen({super.key});

  @override
  State<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends State<CashScreen> {
  void _add() => _showForm(null);

  void _edit(CashTransaction t) => _showForm(t);

  void _showForm(CashTransaction? existing) {
    final guestCtl = TextEditingController(text: existing?.guestName ?? '');
    final receiptCtl = TextEditingController(text: existing?.receiptNumber ?? '');
    final amountCtl = TextEditingController(text: existing != null ? existing.amount.toString() : '');
    final purposeCtl = TextEditingController(text: existing?.purpose ?? '');
    String method = existing?.paymentMethod ?? 'cash';

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
              Text(existing != null ? 'Edit Transaction' : 'Record Cash Transaction', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 16),
              TextField(controller: guestCtl, decoration: const InputDecoration(labelText: 'Guest / Payer Name')),
              const SizedBox(height: 12),
              TextField(controller: receiptCtl, decoration: const InputDecoration(labelText: 'Receipt Number')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: method,
                items: ['cash', 'pos', 'transfer'].map((m) => DropdownMenuItem(
                  value: m,
                  child: Row(children: [
                    Icon(m == 'cash' ? Icons.money_rounded : m == 'pos' ? Icons.credit_card_rounded : Icons.account_balance_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(m.toUpperCase()),
                  ]),
                )).toList(),
                onChanged: (v) => setSB(() => method = v!),
                decoration: const InputDecoration(labelText: 'Payment Method'),
              ),
              const SizedBox(height: 12),
              TextField(controller: amountCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₦)')),
              const SizedBox(height: 12),
              TextField(controller: purposeCtl, decoration: const InputDecoration(labelText: 'Purpose')),
              if (double.tryParse(amountCtl.text) != null && double.parse(amountCtl.text) >= 5000000)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.warning_rounded, color: AppColors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Amount exceeds ₦5M SCUML reporting threshold', style: TextStyle(fontSize: 12, color: AppColors.red800, fontWeight: FontWeight.w600))),
                  ]),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: RoleGate(
                  requiredPermission: Permission.logCashTransactions,
                  child: ElevatedButton(
                    onPressed: () {
                      final amt = double.tryParse(amountCtl.text) ?? 0;
                      if (guestCtl.text.isEmpty || amt <= 0) return;
                      final t = CashTransaction(
                        id: existing?.id ?? ComplianceStore.genId(),
                        date: existing?.date ?? DateTime.now(),
                        guestName: guestCtl.text,
                        receiptNumber: receiptCtl.text,
                        paymentMethod: method,
                        amount: amt,
                        purpose: purposeCtl.text,
                        flagged: amt >= 5000000,
                      );
                      if (existing != null) {
                        ComplianceStore.updateCashTransaction(existing.id, t);
                      } else {
                        ComplianceStore.addCashTransaction(t);
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
    ComplianceStore.removeCashTransaction(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ComplianceStore.cashTransactions;
    final flagged = ComplianceStore.flaggedCashTransactions;
    final thresholdCount = ComplianceStore.thresholdAlertCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Transactions'),
        actions: [
          if (thresholdCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.warning_rounded, size: 14, color: AppColors.red),
                const SizedBox(width: 4),
                Text('$thresholdCount threshold', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.red700)),
              ]),
            ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (flagged.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.red200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.warning_rounded, color: AppColors.red, size: 20),
                const SizedBox(width: 8),
                Text('${flagged.length} transaction(s) near/reporting threshold', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.red800)),
              ]),
              const SizedBox(height: 8),
              Text('SCUML requires reporting cash transactions above ₦5M', style: TextStyle(fontSize: 11, color: AppColors.red600)),
            ]),
          ),
          const SizedBox(height: 16),
        ],
        if (transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.grey300),
                const SizedBox(height: 8),
                Text('No cash transactions recorded', style: TextStyle(color: AppColors.grey500)),
                const SizedBox(height: 4),
                Text('Record cash payments to monitor SCUML thresholds', style: TextStyle(fontSize: 12, color: AppColors.grey400)),
              ]),
            ),
          )
        else
          ...transactions.map((t) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: t.paymentMethod == 'cash' ? AppColors.green50 : t.paymentMethod == 'pos' ? AppColors.blue50 : AppColors.purple50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      t.paymentMethod == 'cash' ? Icons.money_rounded : t.paymentMethod == 'pos' ? Icons.credit_card_rounded : Icons.account_balance_rounded,
                      size: 16, color: t.paymentMethod == 'cash' ? AppColors.green700 : t.paymentMethod == 'pos' ? AppColors.blue700 : AppColors.purple700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t.guestName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), overflow: TextOverflow.ellipsis)),
                  if (t.exceedsThreshold)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(20)),
                      child: Text('THRESHOLD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.red700)),
                    ),
                  RoleGate(requiredPermission: Permission.logCashTransactions, child: IconButton(onPressed: () => _edit(t), icon: const Icon(Icons.edit_rounded, size: 18))),
                  RoleGate(requiredPermission: Permission.logCashTransactions, child: IconButton(onPressed: () => _delete(t.id), icon: const Icon(Icons.delete_rounded, size: 18, color: AppColors.redAccent))),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Text(_fmt(t.amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.indigo)),
                  const Spacer(),
                  if (t.exceedsThreshold)
                    Text('₦${(t.amount - 5000000).toStringAsFixed(0)} above limit', style: TextStyle(fontSize: 11, color: AppColors.red600)),
                ]),
                if (t.purpose.isNotEmpty)
                  Text(t.purpose, style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(children: [
                    Text(t.date.toIso8601String().substring(0, 10), style: TextStyle(fontSize: 11, color: AppColors.grey400)),
                    if (t.receiptNumber.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text('Receipt: ${t.receiptNumber}', style: TextStyle(fontSize: 11, color: AppColors.grey400)),
                    ],
                  ]),
                ),
                if (!t.exceedsThreshold && t.amount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (t.amount / 5000000).clamp(0.0, 1.0),
                        backgroundColor: AppColors.grey200,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
                        minHeight: 4,
                      ),
                    ),
                  ),
              ]),
            ),
          )),
      ]),
      floatingActionButton: RoleGate(
        requiredPermission: Permission.logCashTransactions,
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
