import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/reconciliation.dart';
import '../../models/payments.dart';
import '../../data/reconciliation_store.dart';
import '../../data/expenditure_store.dart';
import '../../data/payment_store.dart';
import '../../utils/bank_parser.dart';
import '../../main.dart' as app;
import '../../models/role.dart';
import '../../utils/role_gate.dart';
import '../../widgets/hom_widgets.dart';
import '../../utils/theme.dart';

const Color _primaryGreen = AppColors.primary;

class ReconciliationScreen extends StatefulWidget {
  const ReconciliationScreen({super.key});
  @override
  State<ReconciliationScreen> createState() => _ReconciliationScreenState();
}

class _ReconciliationScreenState extends State<ReconciliationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Material(
          color: AppColors.white,
          child: TabBar(
            controller: _tabCtrl,
            indicatorColor: _primaryGreen,
            labelColor: _primaryGreen,
            unselectedLabelColor: AppColors.grey600,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(text: 'Bank Stmts'),
              Tab(text: 'Virtual Accts'),
              Tab(text: 'POS'),
            ],
          ),
        ),
        Expanded(
            child: TabBarView(
          controller: _tabCtrl,
          children: [
            _BankStatementsTab(parent: this),
            _VirtualAccountsTab(parent: this),
            _PosTab(parent: this),
          ],
        )),
      ]),
    );
  }
}

// ===================== BANK STATEMENTS TAB =====================

class _BankStatementsTab extends StatefulWidget {
  final _ReconciliationScreenState parent;
  const _BankStatementsTab({required this.parent});
  @override
  State<_BankStatementsTab> createState() => _BankStatementsTabState();
}

class _BankStatementsTabState extends State<_BankStatementsTab> {
  String _filter = 'all';
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BankTransaction> get _displayList {
    var list = _filter == 'unmatched'
        ? ReconciliationStore.unmatched
        : _filter == 'matched'
            ? ReconciliationStore.matchedTransactions
            : ReconciliationStore.transactions;
    if (_search.isNotEmpty) {
      list = list
          .where((t) =>
              t.description.toLowerCase().contains(_search.toLowerCase()) ||
              (t.reference?.toLowerCase().contains(_search.toLowerCase()) ??
                  false))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final txns = ReconciliationStore.transactions;
    final matched = ReconciliationStore.matchedTransactions.length;
    final unmatched = ReconciliationStore.unmatched.length;

    return Stack(children: [
      Column(children: [
        _dashboardRow(txns.length, matched, unmatched),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        SizedBox(
          height: 32,
          child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _filterChip('all', 'All (${txns.length})'),
                _filterChip('matched', 'Matched ($matched)'),
                _filterChip('unmatched', 'Unmatched ($unmatched)'),
              ]),
        ),
        Expanded(
          child: _displayList.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.account_balance_rounded,
                      size: 64, color: AppColors.grey300),
                  const SizedBox(height: 12),
                  Text('No transactions',
                      style: TextStyle(color: AppColors.grey500)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                  itemCount: _displayList.length,
                  itemBuilder: (ctx, i) =>
                      _transactionCard(context, _displayList[i]),
                ),
        ),
      ]),
      Positioned(
        right: 16,
        bottom: 16,
        child: RoleGate(
            requiredPermission: Permission.manageReconciliation,
            child: FloatingActionButton(
              onPressed: () => _uploadStatement(context),
              backgroundColor: _primaryGreen,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.upload_file_rounded),
            )),
      ),
    ]);
  }

  Widget _dashboardRow(int total, int matched, int unmatched) {
    final pct = total > 0 ? matched / total * 100 : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: Column(children: [
        HomResponsiveGrid(children: [
          HomMetricCard(
              label: 'Transactions',
              value: '$total',
              color: AppColors.blue,
              icon: Icons.receipt_long_rounded),
          HomMetricCard(
              label: 'Matched',
              value: '$matched',
              color: _primaryGreen,
              icon: Icons.check_circle_rounded),
          HomMetricCard(
              label: 'Unmatched',
              value: '$unmatched',
              color: unmatched > 0 ? AppColors.red : AppColors.grey500,
              icon: Icons.error_outline_rounded),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: AppColors.grey200,
            valueColor: AlwaysStoppedAnimation(pct > 80
                ? _primaryGreen
                : pct > 50
                    ? AppColors.amber
                    : AppColors.red),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text('${pct.toStringAsFixed(0)}% reconciled',
            style: TextStyle(fontSize: 11, color: AppColors.grey600)),
      ]),
    );
  }

  Widget _filterChip(String val, String label) {
    final active = _filter == val;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
        selected: active,
        onSelected: (_) => setState(() => _filter = val),
        visualDensity: VisualDensity.compact,
        selectedColor: _primaryGreen.withValues(alpha: 0.15),
      ),
    );
  }

  Widget _transactionCard(BuildContext context, BankTransaction t) {
    final txnMatches = ReconciliationStore.matchesForTransaction(t.id);
    final isMatched = txnMatches.isNotEmpty;
    return Card(
      color: isMatched ? null : AppColors.orange50,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetail(context, t),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (t.isCredit ? _primaryGreen : AppColors.red)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                  t.isCredit
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 18,
                  color: t.isCredit ? _primaryGreen : AppColors.red),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                          child: Text(t.description,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 2),
                    Text(
                        '${t.date.day}/${t.date.month}/${t.date.year} — ${t.source}',
                        style:
                            TextStyle(fontSize: 10, color: AppColors.grey500),
                        overflow: TextOverflow.ellipsis),
                    if (txnMatches.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                            '${txnMatches.length} match(es): ${txnMatches.map((m) => m.entityLabel).join(', ')}',
                            style: TextStyle(
                                fontSize: 10,
                                color: _primaryGreen,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                  ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${t.isCredit ? '+' : '-'}₦${t.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: t.isCredit ? _primaryGreen : AppColors.red)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isMatched
                      ? _primaryGreen.withValues(alpha: 0.1)
                      : AppColors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(isMatched ? 'Matched' : 'Unmatched',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isMatched ? _primaryGreen : AppColors.orange)),
              ),
            ]),
            const SizedBox(width: 4),
            Column(mainAxisSize: MainAxisSize.min, children: [
              RoleGate(
                  requiredPermission: Permission.manageReconciliation,
                  child: InkWell(
                    onTap: () => _editTransaction(context, t),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          size: 14, color: _primaryGreen),
                    ),
                  )),
              const SizedBox(height: 4),
              RoleGate(
                  requiredPermission: Permission.manageReconciliation,
                  child: InkWell(
                    onTap: () => _deleteTransaction(context, t),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          size: 14, color: AppColors.redAccent),
                    ),
                  )),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, BankTransaction t) {
    final suggestions = ReconciliationStore.findPotentialMatches(t);
    final txnMatches = ReconciliationStore.matchesForTransaction(t.id);

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
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: (t.isCredit
                                          ? _primaryGreen
                                          : AppColors.red)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(
                                  t.isCredit
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  size: 24,
                                  color: t.isCredit
                                      ? _primaryGreen
                                      : AppColors.red),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(
                                      '${t.isCredit ? 'Credit' : 'Debit'} — ₦${t.amount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18)),
                                  Text(
                                      '${t.date.day}/${t.date.month}/${t.date.year} • ${t.source}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey600)),
                                ])),
                          ]),
                          const SizedBox(height: 16),
                          _detailRow('Description', t.description),
                          if (t.reference != null)
                            _detailRow('Reference', t.reference!),
                          if (t.balance != null)
                            _detailRow(
                                'Balance', '₦${t.balance!.toStringAsFixed(0)}'),
                          if (txnMatches.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text('Current Matches',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: _primaryGreen)),
                            const SizedBox(height: 8),
                            ...txnMatches.map((m) => Card(
                                  color: _primaryGreen.withValues(alpha: 0.05),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(children: [
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(m.entityLabel,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13)),
                                            Text(
                                                '${m.entityType == MatchEntityType.booking ? 'Booking' : 'Expense'} • ₦${m.matchedAmount.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.grey600),
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ])),
                                      RoleGate(
                                          requiredPermission:
                                              Permission.manageReconciliation,
                                          child: IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                size: 18,
                                                color: AppColors.redAccent),
                                            onPressed: () {
                                              ReconciliationStore.removeMatch(
                                                  m.id);
                                              widget.parent.setState(() {});
                                              Navigator.pop(ctx);
                                            },
                                          )),
                                    ]),
                                  ),
                                )),
                          ],
                          if (suggestions.isNotEmpty && txnMatches.isEmpty) ...[
                            const SizedBox(height: 16),
                            Text('Suggested Matches',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.grey800)),
                            const SizedBox(height: 8),
                            ...suggestions
                                .map((s) => _suggestionTile(ctx, setSB, t, s)),
                          ],
                          if (txnMatches.isEmpty && suggestions.isEmpty) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: RoleGate(
                                  requiredPermission:
                                      Permission.manageReconciliation,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _manualMatch(ctx, setSB, t),
                                    icon: const Icon(Icons.search_rounded,
                                        size: 16),
                                    label: const Text('Manual Match'),
                                  )),
                            ),
                          ],
                        ]),
                  ),
                ),
              )),
    );
  }

  Widget _suggestionTile(BuildContext ctx, void Function(VoidCallback) setSB,
      BankTransaction t, PotentialMatch s) {
    final confidencePct = (s.confidence * 100).toStringAsFixed(0);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (s.confidence > 0.8 ? _primaryGreen : AppColors.amber)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.compare_arrows_rounded,
                size: 16,
                color: s.confidence > 0.8 ? _primaryGreen : AppColors.amber),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(s.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                Text(
                    '${s.entityType == MatchEntityType.booking ? 'Booking' : 'Expense'} • ₦${s.amount.toStringAsFixed(0)} • ${s.reason}',
                    style: TextStyle(fontSize: 10, color: AppColors.grey600)),
              ])),
          Text('$confidencePct%',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: s.confidence > 0.8 ? _primaryGreen : AppColors.amber)),
          const SizedBox(width: 8),
          RoleGate(
              requiredPermission: Permission.manageReconciliation,
              child: IconButton(
                icon: const Icon(Icons.check_circle,
                    size: 20, color: _primaryGreen),
                onPressed: () {
                  ReconciliationStore.addMatch(ReconciliationMatch(
                    id: ReconciliationStore.genMatchId(),
                    bankTransactionId: t.id,
                    entityType: s.entityType,
                    entityId: s.entityId,
                    entityLabel: s.label,
                    entityAmount: s.amount,
                    matchedAmount: min(t.amount, s.amount),
                    confidence: s.confidence,
                  ));
                  widget.parent.setState(() {});
                  Navigator.pop(ctx);
                },
              )),
        ]),
      ),
    );
  }

  void _manualMatch(BuildContext context, void Function(VoidCallback) setSB,
      BankTransaction t) {
    final searchCtl = TextEditingController();
    List<_SearchResult> results = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
          builder: (ctx2, setSB2) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx2).viewInsets.bottom),
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
                          const Text('Manual Match',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 17)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: searchCtl,
                            decoration: InputDecoration(
                              hintText: 'Search bookings & expenses...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (v) {
                              if (v.isEmpty) {
                                setSB2(() => results = []);
                                return;
                              }
                              final q = v.toLowerCase();
                              final List<_SearchResult> res = [];
                              for (final b in app.HOMData.bookings) {
                                if (b.guest.toLowerCase().contains(q) ||
                                    b.room.contains(q)) {
                                  res.add(_SearchResult(
                                      MatchEntityType.booking,
                                      b.id,
                                      '${b.guest} — Room ${b.room}',
                                      b.amount.toDouble()));
                                }
                              }
                              for (final e in ExpenditureStore.all) {
                                if (e.description.toLowerCase().contains(q) ||
                                    e.vendor.toLowerCase().contains(q)) {
                                  res.add(_SearchResult(
                                      MatchEntityType.expenditure,
                                      e.id,
                                      e.description.isNotEmpty
                                          ? e.description
                                          : e.category.displayName,
                                      e.amount));
                                }
                              }
                              setSB2(() => results = res);
                            },
                          ),
                          const SizedBox(height: 12),
                          if (results.isEmpty && searchCtl.text.isNotEmpty)
                            const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No results',
                                    style: TextStyle(color: AppColors.grey500)))
                          else
                            ListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              children: results.take(50).map((r) => ListTile(
                                  dense: true,
                                  leading: Icon(
                                      r.type == MatchEntityType.booking
                                          ? Icons.person_rounded
                                          : Icons.receipt_rounded,
                                      size: 18,
                                      color: _primaryGreen),
                                  title: Text(r.label,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                      '${r.type == MatchEntityType.booking ? 'Booking' : 'Expense'} • ₦${r.amount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.grey600),
                                      overflow: TextOverflow.ellipsis),
                                  trailing: RoleGate(
                                      requiredPermission:
                                          Permission.manageReconciliation,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          ReconciliationStore.addMatch(
                                              ReconciliationMatch(
                                            id: ReconciliationStore
                                                .genMatchId(),
                                            bankTransactionId: t.id,
                                            entityType: r.type,
                                            entityId: r.id,
                                            entityLabel: r.label,
                                            entityAmount: r.amount,
                                            matchedAmount:
                                                min(t.amount, r.amount),
                                            isManual: true,
                                            confidence: 1.0,
                                          ));
                                          widget.parent.setState(() {});
                                          Navigator.pop(ctx);
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6)),
                                        child: const Text('Match',
                                            style: TextStyle(fontSize: 11)),
                                      ),
                                    ),
                                  ),
                                ).toList(),
                              ),
                          if (t.amount > 0) ...[
                            const Divider(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: RoleGate(
                                  requiredPermission:
                                      Permission.manageSplitPayments,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _splitPayment(ctx2, setSB, t),
                                    icon: const Icon(Icons.call_split_rounded,
                                        size: 16),
                                    label: const Text('Split Payment'),
                                  )),
                            ),
                          ],
                        ]),
                  ),
                ),
              )),
    );
  }

  void _splitPayment(BuildContext context, void Function(VoidCallback) setSB,
      BankTransaction t) {
    final allocations = <_SplitRow>[];
    double remaining = t.amount;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => StatefulBuilder(
            builder: (ctx2, setSB2) => Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx2).viewInsets.bottom),
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
                                        borderRadius:
                                            BorderRadius.circular(2)))),
                            const SizedBox(height: 16),
                            const Text('Split Payment',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 17)),
                            const SizedBox(height: 4),
                            Text(
                                'Total: ₦${t.amount.toStringAsFixed(0)} • Remaining: ₦${remaining.toStringAsFixed(0)}',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.grey600)),
                            const SizedBox(height: 12),
                            ...allocations.asMap().entries.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(children: [
                                    Expanded(
                                        child: Text(e.value.label,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600))),
                                    Text(
                                        '₦${e.value.amount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800)),
                                    RoleGate(
                                        requiredPermission:
                                            Permission.manageSplitPayments,
                                        child: IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: AppColors.redAccent),
                                          onPressed: () {
                                            remaining +=
                                                allocations[e.key].amount;
                                            allocations.removeAt(e.key);
                                            setSB2(() {});
                                          },
                                        )),
                                  ]),
                                )),
                            if (remaining > 0)
                              RoleGate(
                                  requiredPermission:
                                      Permission.manageSplitPayments,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      showDialog(
                                          context: ctx2,
                                          builder: (dCtx) {
                                            final amtCtl =
                                                TextEditingController();
                                            String type = 'booking';
                                            return AlertDialog(
                                              scrollable: true,
                                              title:
                                                  const Text('Add Allocation'),
                                              content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    DropdownButtonFormField<
                                                        String>(
                                                      initialValue: type,
                                                      items: const [
                                                        DropdownMenuItem(
                                                            value: 'booking',
                                                            child: Text(
                                                                'Booking')),
                                                        DropdownMenuItem(
                                                            value: 'expense',
                                                            child: Text(
                                                                'Expense')),
                                                      ],
                                                      onChanged: (v) =>
                                                          type = v!,
                                                      decoration:
                                                          const InputDecoration(
                                                              labelText:
                                                                  'Type'),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    TextField(
                                                      controller: amtCtl,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      decoration: InputDecoration(
                                                          labelText:
                                                              'Amount (max ₦${remaining.toStringAsFixed(0)})'),
                                                    ),
                                                  ]),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(dCtx),
                                                    child:
                                                        const Text('Cancel')),
                                                ElevatedButton(
                                                    onPressed: () {
                                                      final amt =
                                                          double.tryParse(amtCtl
                                                                  .text) ??
                                                              0;
                                                      if (amt <= 0 ||
                                                          amt > remaining)
                                                        return;
                                                      allocations.add(_SplitRow(
                                                        type: type == 'booking'
                                                            ? MatchEntityType
                                                                .booking
                                                            : MatchEntityType
                                                                .expenditure,
                                                        id: '',
                                                        label: type == 'booking'
                                                            ? 'Booking split'
                                                            : 'Expense split',
                                                        amount: amt,
                                                      ));
                                                      remaining -= amt;
                                                      Navigator.pop(dCtx);
                                                      setSB2(() {});
                                                    },
                                                    child: const Text('Add')),
                                              ],
                                            );
                                          });
                                    },
                                    icon:
                                        const Icon(Icons.add_rounded, size: 16),
                                    label: Text(
                                        'Add Split (₦${remaining.toStringAsFixed(0)} remaining)'),
                                  )),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: RoleGate(
                                  requiredPermission:
                                      Permission.manageSplitPayments,
                                  child: ElevatedButton(
                                    onPressed: allocations.isEmpty ||
                                            remaining > 0
                                        ? null
                                        : () {
                                            final splitAllocs =
                                                <SplitAllocation>[];
                                            for (final a in allocations) {
                                              ReconciliationStore.addMatch(
                                                  ReconciliationMatch(
                                                id: ReconciliationStore
                                                    .genMatchId(),
                                                bankTransactionId: t.id,
                                                entityType: a.type,
                                                entityId: a.id,
                                                entityLabel: a.label,
                                                entityAmount: a.amount,
                                                matchedAmount: a.amount,
                                                isManual: true,
                                                confidence: 1.0,
                                              ));
                                              splitAllocs.add(SplitAllocation(
                                                entityType: a.type,
                                                entityId: a.id,
                                                entityLabel: a.label,
                                                amount: a.amount,
                                              ));
                                            }
                                            PaymentStore.createSplitPayment(
                                              bankTransactionId: t.id,
                                              allocations: splitAllocs,
                                            );
                                            widget.parent.setState(() {});
                                            Navigator.pop(ctx);
                                            Navigator.pop(context);
                                          },
                                    style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14)),
                                    child: Text(remaining > 0
                                        ? 'Allocate ₦${remaining.toStringAsFixed(0)} remaining'
                                        : 'Save Allocations (₦${t.amount.toStringAsFixed(0)})'),
                                  )),
                            ),
                          ]),
                    ),
                  ),
                )));
  }

  void _editTransaction(BuildContext context, BankTransaction t) {
    final descCtl = TextEditingController(text: t.description);
    final amtCtl = TextEditingController(text: t.amount.toStringAsFixed(0));
    final refCtl = TextEditingController(text: t.reference ?? '');
    final srcCtl = TextEditingController(text: t.source);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                  const Text('Edit Transaction',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 16),
                  TextField(
                      controller: descCtl,
                      decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: amtCtl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Amount (₦)',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: refCtl,
                      decoration: const InputDecoration(
                          labelText: 'Reference',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: srcCtl,
                      decoration: const InputDecoration(
                          labelText: 'Source', border: OutlineInputBorder())),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final amt = double.tryParse(amtCtl.text) ?? t.amount;
                        ReconciliationStore.updateTransaction(
                          t.id,
                          BankTransaction(
                            id: t.id,
                            date: t.date,
                            description: descCtl.text.trim(),
                            amount: amt,
                            reference: refCtl.text.trim().isEmpty
                                ? null
                                : refCtl.text.trim(),
                            balance: t.balance,
                            source: srcCtl.text.trim(),
                            type: t.type,
                          ),
                        );
                        widget.parent.setState(() {});
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  void _deleteTransaction(BuildContext context, BankTransaction t) {
    ReconciliationStore.removeTransaction(t.id);
    setState(() {});
    widget.parent.setState(() {});
  }

  // ===================== UPLOAD STATEMENT =====================

  Future<void> _uploadStatement(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) return;
      final raw = String.fromCharCodes(file.bytes!);
      final parsed = BankStatementParser.parseCsv(raw, source: file.name);
      if (parsed.transactions.isNotEmpty) {
        ReconciliationStore.addTransactions(parsed.transactions);
        setState(() {});
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${parsed.parsedCount} transactions parsed (${parsed.skippedCount} skipped)'),
          backgroundColor: _primaryGreen,
          action: parsed.errors.isNotEmpty
              ? SnackBarAction(
                  label: 'Errors',
                  onPressed: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                            title: const Text('Parse Errors'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView(
                                shrinkWrap: true,
                                children: parsed.errors
                                    .map((e) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 4),
                                          child: Text(e,
                                              style: TextStyle(fontSize: 12)),
                                        ))
                                    .toList(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('OK'))
                            ],
                          )),
                )
              : null,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppColors.red));
      }
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(color: AppColors.grey600, fontSize: 12))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

// ===================== VIRTUAL ACCOUNTS TAB =====================

class _VirtualAccountsTab extends StatefulWidget {
  final _ReconciliationScreenState parent;
  const _VirtualAccountsTab({required this.parent});
  @override
  State<_VirtualAccountsTab> createState() => _VirtualAccountsTabState();
}

class _VirtualAccountsTabState extends State<_VirtualAccountsTab> {
  String _vaFilter = 'all';

  List<VirtualAccount> get _vaList {
    final list = PaymentStore.virtualAccounts;
    if (_vaFilter == 'active')
      return list.where((v) => v.status == 'active').toList();
    if (_vaFilter == 'matched')
      return list.where((v) => v.status == 'matched').toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final all = PaymentStore.virtualAccounts;
    final active = PaymentStore.activeVirtualAccounts.length;
    final matched = PaymentStore.matchedVirtualAccounts.length;

    return Stack(children: [
      Column(children: [
        _vaDashboard(all.length, active, matched),
        SizedBox(
          height: 32,
          child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _vaFilterChip('all', 'All (${all.length})'),
                _vaFilterChip('active', 'Active ($active)'),
                _vaFilterChip('matched', 'Matched ($matched)'),
              ]),
        ),
        Expanded(
          child: _vaList.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.account_balance_rounded,
                      size: 64, color: AppColors.grey300),
                  const SizedBox(height: 12),
                  Text('No virtual accounts',
                      style: TextStyle(color: AppColors.grey500)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                  itemCount: _vaList.length,
                  itemBuilder: (ctx, i) => _vaCard(context, _vaList[i]),
                ),
        ),
      ]),
      Positioned(
        right: 16,
        bottom: 16,
        child: RoleGate(
            requiredPermission: Permission.manageVirtualAccounts,
            child: FloatingActionButton(
              onPressed: () => _generateVA(context),
              backgroundColor: _primaryGreen,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.add_rounded),
            )),
      ),
    ]);
  }

  Widget _vaDashboard(int total, int active, int matched) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: Row(children: [
        Expanded(
            child: _vaStat('$total', 'Total', Icons.account_balance_rounded,
                AppColors.blue)),
        const SizedBox(width: 8),
        Expanded(
            child: _vaStat('$active', 'Active', Icons.check_circle_rounded,
                _primaryGreen)),
        const SizedBox(width: 8),
        Expanded(
            child: _vaStat(
                '$matched', 'Matched', Icons.link_rounded, AppColors.purple)),
      ]),
    );
  }

  Widget _vaStat(String v, String l, IconData i, Color c) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(i, size: 14, color: c),
          const SizedBox(width: 4),
          Text(v,
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 18, color: c)),
        ]),
        Text(l, style: TextStyle(fontSize: 10, color: AppColors.grey600)),
      ]),
    );
  }

  Widget _vaFilterChip(String val, String label) {
    final active = _vaFilter == val;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
        selected: active,
        onSelected: (_) => setState(() => _vaFilter = val),
        visualDensity: VisualDensity.compact,
        selectedColor: _primaryGreen.withValues(alpha: 0.15),
      ),
    );
  }

  Widget _vaCard(BuildContext context, VirtualAccount va) {
    final statusColor = va.status == 'active'
        ? _primaryGreen
        : va.status == 'matched'
            ? AppColors.purple
            : AppColors.grey500;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.account_balance_rounded,
                size: 18, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(va.guestName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text('${va.bankName} • ${va.accountNumber}',
                    style: TextStyle(fontSize: 11, color: AppColors.grey600)),
                Text('Booking: ${va.bookingId}',
                    style: TextStyle(fontSize: 10, color: AppColors.grey500),
                    overflow: TextOverflow.ellipsis),
              ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₦${va.amount.toStringAsFixed(0)}',
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(va.status.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor)),
            ),
          ]),
          const SizedBox(width: 4),
          Column(mainAxisSize: MainAxisSize.min, children: [
            RoleGate(
                requiredPermission: Permission.manageVirtualAccounts,
                child: InkWell(
                  onTap: () => _editVirtualAccount(context, va),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        size: 14, color: _primaryGreen),
                  ),
                )),
            const SizedBox(height: 4),
            RoleGate(
                requiredPermission: Permission.manageVirtualAccounts,
                child: InkWell(
                  onTap: () => _deleteVirtualAccount(context, va),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 14, color: AppColors.redAccent),
                  ),
                )),
          ]),
        ]),
      ),
    );
  }

  void _generateVA(BuildContext context) {
    final guestCtl = TextEditingController();
    final amtCtl = TextEditingController();
    String? bookingId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                  const Text('Generate Virtual Account',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: guestCtl,
                    decoration: const InputDecoration(
                        labelText: 'Guest Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amtCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Amount (₦)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: 'Booking (optional)',
                        border: OutlineInputBorder()),
                    items: app.HOMData.bookings
                        .map((b) => DropdownMenuItem(
                            value: b.id,
                            child: Text('${b.guest} — Room ${b.room}')))
                        .toList(),
                    onChanged: (v) => bookingId = v,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = guestCtl.text.trim();
                        final amt = int.tryParse(amtCtl.text) ?? 0;
                        if (name.isEmpty || amt <= 0) return;
                        PaymentStore.generateVirtualAccount(
                          bookingId: bookingId ??
                              'manual_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
                          guestName: name,
                          amount: amt,
                        );
                        setState(() {});
                        widget.parent.setState(() {});
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Generate'),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  void _editVirtualAccount(BuildContext context, VirtualAccount va) {
    final guestCtl = TextEditingController(text: va.guestName);
    final amtCtl = TextEditingController(text: va.amount.toString());
    String status = va.status;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                  const Text('Edit Virtual Account',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 16),
                  TextField(
                      controller: guestCtl,
                      decoration: const InputDecoration(
                          labelText: 'Guest Name',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: amtCtl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Amount (₦)',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(
                        labelText: 'Status', border: OutlineInputBorder()),
                    items: ['active', 'matched', 'expired']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => status = v!,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final amt = int.tryParse(amtCtl.text) ?? va.amount;
                        PaymentStore.updateVirtualAccount(
                          va.id,
                          VirtualAccount(
                            id: va.id,
                            bookingId: va.bookingId,
                            guestName: guestCtl.text.trim(),
                            bankName: va.bankName,
                            accountNumber: va.accountNumber,
                            accountName: va.accountName,
                            amount: amt,
                            status: status,
                            createdAt: va.createdAt,
                            expiresAt: va.expiresAt,
                          ),
                        );
                        setState(() {});
                        widget.parent.setState(() {});
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  void _deleteVirtualAccount(BuildContext context, VirtualAccount va) {
    PaymentStore.removeVirtualAccount(va.id);
    setState(() {});
    widget.parent.setState(() {});
  }
}

// ===================== POS TAB =====================

class _PosTab extends StatefulWidget {
  final _ReconciliationScreenState parent;
  const _PosTab({required this.parent});
  @override
  State<_PosTab> createState() => _PosTabState();
}

class _PosTabState extends State<_PosTab> with SingleTickerProviderStateMixin {
  late TabController _posTabCtrl;

  @override
  void initState() {
    super.initState();
    _posTabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _posTabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: AppColors.white,
        child: TabBar(
          controller: _posTabCtrl,
          indicatorColor: _primaryGreen,
          labelColor: _primaryGreen,
          unselectedLabelColor: AppColors.grey600,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(text: 'Terminals'),
            Tab(text: 'Settlements'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _posTabCtrl,
          children: [
            _PosTerminalsTab(parent: widget.parent),
            _PosSettlementsTab(parent: widget.parent),
          ],
        ),
      ),
    ]);
  }
}

class _PosTerminalsTab extends StatefulWidget {
  final _ReconciliationScreenState parent;
  const _PosTerminalsTab({required this.parent});
  @override
  State<_PosTerminalsTab> createState() => _PosTerminalsTabState();
}

class _PosTerminalsTabState extends State<_PosTerminalsTab> {
  @override
  Widget build(BuildContext context) {
    final terminals = PaymentStore.posTerminals;
    final active = PaymentStore.activePosTerminals.length;

    return Stack(children: [
      Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.white,
          child: Row(children: [
            Expanded(
                child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.devices_rounded,
                          size: 14, color: AppColors.blue),
                      const SizedBox(width: 4),
                      Text('${terminals.length}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: AppColors.blue)),
                    ]),
                    Text('Terminals',
                        style:
                            TextStyle(fontSize: 10, color: AppColors.grey600)),
                  ]),
            )),
            const SizedBox(width: 8),
            Expanded(
                child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: _primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 14, color: _primaryGreen),
                      const SizedBox(width: 4),
                      Text('$active',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: _primaryGreen)),
                    ]),
                    Text('Active',
                        style:
                            TextStyle(fontSize: 10, color: AppColors.grey600)),
                  ]),
            )),
          ]),
        ),
        Expanded(
          child: terminals.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.devices_rounded,
                      size: 64, color: AppColors.grey300),
                  const SizedBox(height: 12),
                  Text('No POS terminals',
                      style: TextStyle(color: AppColors.grey500)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                  itemCount: terminals.length,
                  itemBuilder: (ctx, i) => _terminalCard(context, terminals[i]),
                ),
        ),
      ]),
      Positioned(
        right: 16,
        bottom: 16,
        child: RoleGate(
            requiredPermission: Permission.trackPOSTerminals,
            child: FloatingActionButton(
              onPressed: () => _addTerminal(context),
              backgroundColor: _primaryGreen,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.add_rounded),
            )),
      ),
    ]);
  }

  Widget _terminalCard(BuildContext context, PosTerminal t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (t.status == 'active' ? _primaryGreen : AppColors.grey500)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.devices_rounded,
                size: 18,
                color:
                    t.status == 'active' ? _primaryGreen : AppColors.grey500),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(t.terminalId,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                Text('${t.bankName} • ${t.merchantCode}',
                    style: TextStyle(fontSize: 11, color: AppColors.grey600)),
              ])),
          RoleGate(
              requiredPermission: Permission.trackPOSTerminals,
              child: Switch(
                value: t.status == 'active',
                activeTrackColor: _primaryGreen,
                onChanged: (_) {
                  PaymentStore.togglePosTerminalStatus(t.id);
                  setState(() {});
                  widget.parent.setState(() {});
                },
              )),
          const SizedBox(width: 4),
          Column(mainAxisSize: MainAxisSize.min, children: [
            RoleGate(
                requiredPermission: Permission.trackPOSTerminals,
                child: InkWell(
                  onTap: () => _editPosTerminal(context, t),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        size: 14, color: _primaryGreen),
                  ),
                )),
            const SizedBox(height: 4),
            RoleGate(
                requiredPermission: Permission.trackPOSTerminals,
                child: InkWell(
                  onTap: () => _deletePosTerminal(context, t),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 14, color: AppColors.redAccent),
                  ),
                )),
          ]),
        ]),
      ),
    );
  }

  void _addTerminal(BuildContext context) {
    final tidCtl = TextEditingController();
    final bankCtl = TextEditingController();
    final merchantCtl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                  const Text('Add POS Terminal',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 16),
                  TextField(
                      controller: tidCtl,
                      decoration: const InputDecoration(
                          labelText: 'Terminal ID',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: bankCtl,
                      decoration: const InputDecoration(
                          labelText: 'Bank Name',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: merchantCtl,
                      decoration: const InputDecoration(
                          labelText: 'Merchant Code',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final tid = tidCtl.text.trim();
                        final bank = bankCtl.text.trim();
                        final mc = merchantCtl.text.trim();
                        if (tid.isEmpty || bank.isEmpty || mc.isEmpty) return;
                        PaymentStore.addPosTerminal(PosTerminal(
                          id: 'pos_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
                          terminalId: tid,
                          bankName: bank,
                          merchantCode: mc,
                          status: 'active',
                          addedAt: DateTime.now(),
                        ));
                        setState(() {});
                        widget.parent.setState(() {});
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Add Terminal'),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  void _editPosTerminal(BuildContext context, PosTerminal t) {
    final tidCtl = TextEditingController(text: t.terminalId);
    final bankCtl = TextEditingController(text: t.bankName);
    final merchantCtl = TextEditingController(text: t.merchantCode);
    String status = t.status;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                  const Text('Edit POS Terminal',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 16),
                  TextField(
                      controller: tidCtl,
                      decoration: const InputDecoration(
                          labelText: 'Terminal ID',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: bankCtl,
                      decoration: const InputDecoration(
                          labelText: 'Bank Name',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: merchantCtl,
                      decoration: const InputDecoration(
                          labelText: 'Merchant Code',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(
                        labelText: 'Status', border: OutlineInputBorder()),
                    items: ['active', 'inactive']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => status = v!,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        PaymentStore.updatePosTerminal(
                          t.id,
                          PosTerminal(
                            id: t.id,
                            terminalId: tidCtl.text.trim(),
                            bankName: bankCtl.text.trim(),
                            merchantCode: merchantCtl.text.trim(),
                            status: status,
                            addedAt: t.addedAt,
                          ),
                        );
                        setState(() {});
                        widget.parent.setState(() {});
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  void _deletePosTerminal(BuildContext context, PosTerminal t) {
    PaymentStore.removePosTerminal(t.id);
    setState(() {});
    widget.parent.setState(() {});
  }
}

class _PosSettlementsTab extends StatefulWidget {
  final _ReconciliationScreenState parent;
  const _PosSettlementsTab({required this.parent});
  @override
  State<_PosSettlementsTab> createState() => _PosSettlementsTabState();
}

class _PosSettlementsTabState extends State<_PosSettlementsTab> {
  String _settleFilter = 'pending';

  List<PosSettlement> get _settleList {
    final list = PaymentStore.posSettlements;
    if (_settleFilter == 'pending')
      return list.where((s) => s.status == 'pending').toList();
    if (_settleFilter == 'settled')
      return list.where((s) => s.status == 'settled').toList();
    if (_settleFilter == 'flagged')
      return list.where((s) => s.status == 'flagged').toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final all = PaymentStore.posSettlements;
    final pending = PaymentStore.pendingSettlements.length;
    final settled = all.where((s) => s.status == 'settled').length;

    return Stack(children: [
      Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.white,
          child: Row(children: [
            Expanded(
                child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.receipt_long_rounded,
                          size: 14, color: AppColors.blue),
                      const SizedBox(width: 4),
                      Text('${all.length}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: AppColors.blue)),
                    ]),
                    Text('Total',
                        style:
                            TextStyle(fontSize: 10, color: AppColors.grey600)),
                  ]),
            )),
            const SizedBox(width: 8),
            Expanded(
                child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.pending_rounded,
                          size: 14, color: AppColors.orange),
                      const SizedBox(width: 4),
                      Text('$pending',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: AppColors.orange)),
                    ]),
                    Text('Pending',
                        style:
                            TextStyle(fontSize: 10, color: AppColors.grey600)),
                  ]),
            )),
            const SizedBox(width: 8),
            Expanded(
                child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: _primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 14, color: _primaryGreen),
                      const SizedBox(width: 4),
                      Text('$settled',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: _primaryGreen)),
                    ]),
                    Text('Settled',
                        style:
                            TextStyle(fontSize: 10, color: AppColors.grey600)),
                  ]),
            )),
          ]),
        ),
        SizedBox(
          height: 32,
          child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _settleChip('pending', 'Pending ($pending)'),
                _settleChip('settled', 'Settled ($settled)'),
                _settleChip('flagged', 'Flagged'),
                _settleChip('all', 'All (${all.length})'),
              ]),
        ),
        Expanded(
          child: _settleList.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.receipt_long_rounded,
                      size: 64, color: AppColors.grey300),
                  const SizedBox(height: 12),
                  Text('No settlements',
                      style: TextStyle(color: AppColors.grey500)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                  itemCount: _settleList.length,
                  itemBuilder: (ctx, i) => _settleCard(context, _settleList[i]),
                ),
        ),
      ]),
      Positioned(
        right: 16,
        bottom: 16,
        child: RoleGate(
            requiredPermission: Permission.trackPOSTerminals,
            child: FloatingActionButton(
              onPressed: () => _recordSettlement(context),
              backgroundColor: _primaryGreen,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.add_rounded),
            )),
      ),
    ]);
  }

  Widget _settleChip(String val, String label) {
    final active = _settleFilter == val;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
        selected: active,
        onSelected: (_) => setState(() => _settleFilter = val),
        visualDensity: VisualDensity.compact,
        selectedColor: _primaryGreen.withValues(alpha: 0.15),
      ),
    );
  }

  Widget _settleCard(BuildContext context, PosSettlement s) {
    final statusColor = s.status == 'settled'
        ? _primaryGreen
        : s.status == 'pending'
            ? AppColors.orange
            : AppColors.red;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _settleDetail(context, s),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.receipt_long_rounded,
                  size: 18, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(s.terminalRef,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(
                      '${s.date.day}/${s.date.month}/${s.date.year} • Terminal: ${s.terminalId}',
                      style: TextStyle(fontSize: 10, color: AppColors.grey600),
                      overflow: TextOverflow.ellipsis),
                ])),
            Flexible(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                  Text('₦${s.amount.toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(s.status.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor)),
                  ),
                ])),
          ]),
        ),
      ),
    );
  }

  void _settleDetail(BuildContext context, PosSettlement s) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
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
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: _primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.receipt_long_rounded,
                        size: 24, color: _primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(s.terminalRef,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 18)),
                        Text('${s.date.day}/${s.date.month}/${s.date.year}',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.grey600)),
                      ])),
                ]),
                const SizedBox(height: 16),
                _detailRow('Amount', '₦${s.amount.toStringAsFixed(0)}'),
                _detailRow('Terminal', s.terminalId),
                _detailRow('Status', s.status.toUpperCase()),
                if (s.note != null) _detailRow('Note', s.note!),
                if (s.status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: RoleGate(
                          requiredPermission: Permission.trackPOSTerminals,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              PaymentStore.updateSettlementStatus(
                                  s.id, 'settled');
                              setState(() {});
                              widget.parent.setState(() {});
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.check_circle_rounded,
                                size: 16),
                            label: const Text('Mark Settled'),
                            style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12)),
                          )),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RoleGate(
                          requiredPermission: Permission.trackPOSTerminals,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              PaymentStore.updateSettlementStatus(
                                  s.id, 'flagged');
                              setState(() {});
                              widget.parent.setState(() {});
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.flag_rounded, size: 16),
                            label: const Text('Flag'),
                            style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12)),
                          )),
                    ),
                  ]),
                ],
              ]),
        ),
      ),
    );
  }

  void _recordSettlement(BuildContext context) {
    final refCtl = TextEditingController();
    final amtCtl = TextEditingController();
    String? terminalId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                  const Text('Record POS Settlement',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: 'Terminal', border: OutlineInputBorder()),
                    items: PaymentStore.activePosTerminals
                        .map((t) => DropdownMenuItem(
                            value: t.id, child: Text(t.terminalId)))
                        .toList(),
                    onChanged: (v) => terminalId = v,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: refCtl,
                      decoration: const InputDecoration(
                          labelText: 'Settlement Reference',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: amtCtl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Amount (₦)',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final ref = refCtl.text.trim();
                        final amt = int.tryParse(amtCtl.text) ?? 0;
                        if (terminalId == null || ref.isEmpty || amt <= 0)
                          return;
                        PaymentStore.addPosSettlement(PosSettlement(
                          id: 'ps_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
                          terminalId: terminalId!,
                          terminalRef: ref,
                          amount: amt,
                          date: DateTime.now(),
                          status: 'pending',
                        ));
                        setState(() {});
                        widget.parent.setState(() {});
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Record Settlement'),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(color: AppColors.grey600, fontSize: 12))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

// ===================== SHARED HELPERS =====================

class _SearchResult {
  final MatchEntityType type;
  final String id;
  final String label;
  final double amount;
  _SearchResult(this.type, this.id, this.label, this.amount);
}

class _SplitRow {
  final MatchEntityType type;
  final String id;
  final String label;
  final double amount;
  _SplitRow(
      {required this.type,
      required this.id,
      required this.label,
      required this.amount});
}
