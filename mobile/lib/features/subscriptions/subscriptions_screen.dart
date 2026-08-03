import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/subscription.dart';
import '../../data/subscription_store.dart';
import '../../data/expenditure_store.dart';
import '../../models/expenditure.dart';
import '../../utils/role_gate.dart';
import '../../models/role.dart';
import '../../utils/theme.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});
  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  void _add({Subscription? existing}) {
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final provCtl = TextEditingController(text: existing?.provider ?? '');
    final catCtl = TextEditingController(text: existing?.category ?? '');
    final amtCtl =
        TextEditingController(text: existing?.amount.toString() ?? '');
    final contactCtl = TextEditingController(text: existing?.contactInfo ?? '');
    final notesCtl = TextEditingController(text: existing?.notes ?? '');
    BillingCycle cycle = existing?.billingCycle ?? BillingCycle.monthly;
    DateTime start = existing?.startDate ?? DateTime.now();
    bool autoLog = existing?.autoLogExpenditure ?? true;

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
                              existing != null
                                  ? 'Edit Subscription'
                                  : 'New Subscription',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 17)),
                          const SizedBox(height: 16),
                          TextField(
                              controller: nameCtl,
                              decoration: const InputDecoration(
                                  labelText: 'Subscription Name',
                                  hintText: 'e.g. DSTV Premium Business')),
                          const SizedBox(height: 12),
                          TextField(
                              controller: provCtl,
                              decoration: const InputDecoration(
                                  labelText: 'Provider',
                                  hintText: 'e.g. Multichoice Nigeria')),
                          const SizedBox(height: 12),
                          TextField(
                              controller: catCtl,
                              decoration: const InputDecoration(
                                  labelText: 'Category',
                                  hintText: 'e.g. TV, Internet, License')),
                          const SizedBox(height: 12),
                          TextField(
                              controller: amtCtl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Amount (₦)')),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<BillingCycle>(
                            initialValue: cycle,
                            items: BillingCycle.values
                                .map((c) => DropdownMenuItem(
                                    value: c, child: Text(c.label)))
                                .toList(),
                            onChanged: (v) => setSB(() => cycle = v!),
                            decoration: const InputDecoration(
                                labelText: 'Billing Cycle'),
                          ),
                          const SizedBox(height: 12),
                          Text(
                              'Start Date: ${DateFormat('dd MMM yyyy').format(start)}',
                              style: TextStyle(
                                  color: AppColors.grey600, fontSize: 13)),
                          TextButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                  context: context,
                                  initialDate: start,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030));
                              if (picked != null) setSB(() => start = picked);
                            },
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: const Text('Change Start Date'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                              controller: contactCtl,
                              decoration: const InputDecoration(
                                  labelText: 'Contact Info',
                                  hintText: 'Phone / Email')),
                          const SizedBox(height: 12),
                          TextField(
                              controller: notesCtl,
                              maxLines: 2,
                              decoration:
                                  const InputDecoration(labelText: 'Notes')),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            title: const Text('Auto-log to Expenditure',
                                style: TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                            value: autoLog,
                            onChanged: (v) => setSB(() => autoLog = v!),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: RoleGate(
                              requiredPermission:
                                  Permission.manageSubscriptions,
                              child: ElevatedButton(
                                onPressed: () {
                                  final amt = double.tryParse(amtCtl.text) ?? 0;
                                  if (nameCtl.text.isEmpty || amt <= 0) return;
                                  if (existing != null) {
                                    existing.name = nameCtl.text;
                                    existing.provider = provCtl.text;
                                    existing.category = catCtl.text;
                                    existing.amount = amt;
                                    existing.billingCycle = cycle;
                                    existing.startDate = start;
                                    existing.contactInfo = contactCtl.text;
                                    existing.notes = notesCtl.text;
                                    existing.autoLogExpenditure = autoLog;
                                  } else {
                                    final sub = Subscription(
                                      id: SubscriptionStore.genId(),
                                      name: nameCtl.text,
                                      provider: provCtl.text,
                                      category: catCtl.text,
                                      amount: amt,
                                      billingCycle: cycle,
                                      startDate: start,
                                      contactInfo: contactCtl.text,
                                      notes: notesCtl.text,
                                      autoLogExpenditure: autoLog,
                                    );
                                    SubscriptionStore.add(sub);
                                    if (autoLog) {
                                      ExpenditureStore.add(ExpenditureRecord(
                                        id: 'sub_${SubscriptionStore.genId()}',
                                        date: DateTime.now(),
                                        category:
                                            ExpenditureCategory.administrative,
                                        subcategory:
                                            'Subscription — ${sub.category}',
                                        description:
                                            '${sub.name} (${sub.provider}) — ${sub.billingCycle.label}',
                                        amount: sub.amount,
                                        vendor: sub.provider,
                                      ));
                                    }
                                  }
                                  Navigator.pop(ctx);
                                  setState(() {});
                                },
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14)),
                                child: Text(existing != null
                                    ? 'Save Changes'
                                    : 'Add Subscription'),
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
    final subscriptions = SubscriptionStore.all;
    final monthlyTotal = SubscriptionStore.totalMonthlyCost;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text('₦${_fmtShort(monthlyTotal)}/mo',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.primary)),
            ),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Summary cards
        Row(children: [
          _summaryCard(
              'Active', '${SubscriptionStore.active.length}', AppColors.green),
          const SizedBox(width: 8),
          _summaryCard('Expiring', '${SubscriptionStore.expiringSoon.length}',
              AppColors.orange),
          const SizedBox(width: 8),
          _summaryCard(
              'Monthly Total', '₦${_fmtShort(monthlyTotal)}', AppColors.blue),
        ]),
        const SizedBox(height: 16),
        // List
        ...subscriptions.map((s) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14)),
                                    Text(s.provider,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.grey600)),
                                  ]),
                            ),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              _statusChip(s.status),
                              RoleGate(
                                requiredPermission:
                                    Permission.manageSubscriptions,
                                child: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _add(existing: s);
                                    if (v == 'delete') {
                                      SubscriptionStore.remove(s.id);
                                      setState(() {});
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                        value: 'edit',
                                        child: SizedBox(
                                            width: 80,
                                            child: Row(children: [
                                              Icon(Icons.edit_rounded,
                                                  size: 16),
                                              SizedBox(width: 8),
                                              Text('Edit',
                                                  style:
                                                      TextStyle(fontSize: 13))
                                            ]))),
                                    PopupMenuItem(
                                        value: 'delete',
                                        child: SizedBox(
                                            width: 80,
                                            child: Row(children: [
                                              Icon(Icons.delete_rounded,
                                                  size: 16,
                                                  color: AppColors.red),
                                              SizedBox(width: 8),
                                              Text('Delete',
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: AppColors.red))
                                            ]))),
                                  ],
                                ),
                              ),
                            ]),
                          ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Text('₦${s.amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppColors.primary)),
                        const SizedBox(width: 8),
                        Text('/${s.billingCycle.label.toLowerCase()}',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.grey600)),
                        const Spacer(),
                        Text(
                            '${s.billingCycle == BillingCycle.monthly ? s.daysUntilRenewal : (s.renewalDate.difference(DateTime.now()).inDays)}d to renewal',
                            style: TextStyle(
                                fontSize: 11,
                                color: s.status == SubscriptionStatus.expiring
                                    ? AppColors.orange
                                    : AppColors.grey500)),
                      ]),
                      if (s.category.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: AppColors.grey100,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(s.category,
                                style: TextStyle(
                                    fontSize: 10, color: AppColors.grey600)),
                          ),
                        ),
                      if (s.notes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(s.notes,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.grey500,
                                  fontStyle: FontStyle.italic)),
                        ),
                    ]),
              ),
            )),
      ]),
      floatingActionButton: RoleGate(
        requiredPermission: Permission.manageSubscriptions,
        child: FloatingActionButton(
          onPressed: () => _add(),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: AppColors.white),
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 20, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.grey700)),
        ]),
      ),
    );
  }

  Widget _statusChip(SubscriptionStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: status.color)),
    );
  }

  String _fmtShort(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}
