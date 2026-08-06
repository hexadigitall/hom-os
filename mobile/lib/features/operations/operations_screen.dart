import 'package:flutter/material.dart';
import '../../models/operations.dart';
import '../../data/operations_store.dart';
import '../../data/expenditure_store.dart';
import '../../widgets/hom_widgets.dart';
import '../../models/role.dart';
import '../../utils/role_gate.dart';
import '../../data/security_audit_store.dart';
import '../../utils/theme.dart';

const Color _primaryGreen = AppColors.primary;

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});
  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operations')),
      body: Column(children: [
        TabBar(
          controller: _tabCtrl,
          labelColor: _primaryGreen,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: _primaryGreen,
          tabs: const [
            Tab(
                text: 'RevPAR',
                icon: Icon(Icons.trending_up_rounded, size: 18)),
            Tab(
                text: 'Night Audit',
                icon: Icon(Icons.nights_stay_rounded, size: 18)),
            Tab(
                text: 'Housekeeping',
                icon: Icon(Icons.cleaning_services_rounded, size: 18)),
          ],
        ),
        Expanded(
            child: TabBarView(controller: _tabCtrl, children: [
          _RevparTab(onChange: _onChange),
          _NightAuditTab(onChange: _onChange),
          _HousekeepingTab(),
        ])),
      ]),
      floatingActionButton: _tabCtrl.index == 0
          ? RoleGate(
              requiredPermission: Permission.createExpenditure,
              child: FloatingActionButton(
                backgroundColor: _primaryGreen,
                foregroundColor: AppColors.white,
                child: const Icon(Icons.add),
                onPressed: () => _addDailyRevenue(context),
              ))
          : _tabCtrl.index == 1
              ? RoleGate(
                  requiredPermission: Permission.logCashDrop,
                  child: FloatingActionButton(
                    backgroundColor: _primaryGreen,
                    foregroundColor: AppColors.white,
                    child: const Icon(Icons.add),
                    onPressed: () => _addCashDrop(context),
                  ))
              : null,
    );
  }

  void _addDailyRevenue(BuildContext context) {
    final roomsAvailCtl = TextEditingController(text: '12');
    final roomsSoldCtl = TextEditingController();
    final walkInsCtl = TextEditingController(text: '0');
    final revenueCtl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Add Daily Revenue',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                    controller: revenueCtl,
                    decoration: const InputDecoration(
                        labelText: 'Total Revenue (₦)',
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextField(
                    controller: roomsSoldCtl,
                    decoration: const InputDecoration(
                        labelText: 'Rooms Sold', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: roomsAvailCtl,
                          decoration: const InputDecoration(
                              labelText: 'Rooms Available',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextField(
                          controller: walkInsCtl,
                          decoration: const InputDecoration(
                              labelText: 'Walk-ins',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today_rounded, size: 18)),
                  controller: TextEditingController(
                      text:
                          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now().add(const Duration(days: 1)));
                    if (picked != null) setSheet(() => selectedDate = picked);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      final rev = double.tryParse(revenueCtl.text) ?? 0;
                      final sold = int.tryParse(roomsSoldCtl.text) ?? 0;
                      if (rev <= 0 || sold <= 0) return;
                      OperationsStore.addRevenue(DailyRevenue(
                        date: selectedDate,
                        roomsAvailable: int.tryParse(roomsAvailCtl.text) ?? 12,
                        roomsSold: sold,
                        walkIns: int.tryParse(walkInsCtl.text) ?? 0,
                        totalRevenue: rev,
                      ));
                      Navigator.pop(ctx);
                      _onChange();
                    },
                    child: const Text('Add Revenue'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _addCashDrop(BuildContext context) {
    if (SecurityAuditStore.isTodayLocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Today is locked — cannot add cash drops')));
      return;
    }
    final expectedCtl = TextEditingController();
    final actualCtl = TextEditingController();
    final notesCtl = TextEditingController();
    String shift = 'Morning';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Log Cash Drop',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: shift,
                  decoration: const InputDecoration(
                      labelText: 'Shift', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                    DropdownMenuItem(value: 'Evening', child: Text('Evening')),
                    DropdownMenuItem(value: 'Night', child: Text('Night')),
                  ],
                  onChanged: (v) {
                    if (v != null) setSheet(() => shift = v);
                  },
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: expectedCtl,
                          decoration: const InputDecoration(
                              labelText: 'Expected (₦)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextField(
                          controller: actualCtl,
                          decoration: const InputDecoration(
                              labelText: 'Actual (₦)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 8),
                TextField(
                    controller: notesCtl,
                    decoration: const InputDecoration(
                        labelText: 'Notes', border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      final exp = double.tryParse(expectedCtl.text) ?? 0;
                      final act = double.tryParse(actualCtl.text) ?? 0;
                      if (exp <= 0) return;
                      final status = act == exp
                          ? CashDropStatus.matched
                          : act < exp
                              ? CashDropStatus.mismatched
                              : CashDropStatus.mismatched;
                      OperationsStore.addCashDrop(CashDrop(
                        id: OperationsStore.genId(),
                        date: DateTime.now(),
                        shift: shift,
                        expectedAmount: exp,
                        actualAmount: act,
                        notes: notesCtl.text,
                        status: status,
                      ));
                      Navigator.pop(ctx);
                      _onChange();
                    },
                    child: const Text('Log Cash Drop'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== HELPER =====================

String _fmt(double n, {bool naira = true}) {
  if (naira) return '₦${_numStr(n)}';
  return _numStr(n);
}

String _numStr(double n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toStringAsFixed(0);
}

// ===================== REVPAR / ADR TAB =====================

class _RevparTab extends StatelessWidget {
  final VoidCallback onChange;
  const _RevparTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final revs = OperationsStore.revenuesForMonth(
        DateTime.now().year, DateTime.now().month);
    final occ = OperationsStore.monthAvgOccupancy;
    final adr = OperationsStore.monthAvgAdr;
    final revpar = OperationsStore.monthAvgRevpar;
    final totalRev = OperationsStore.monthRevenue;
    final totalExp = ExpenditureStore.totalAll;
    final revDays = revs.length;

    return ListView(padding: const EdgeInsets.all(12), children: [
      HomResponsiveGrid(children: [
        HomMetricCard(
            label: 'Occupancy',
            value: '${occ.toStringAsFixed(0)}%',
            color: AppColors.blue,
            icon: Icons.bed_rounded,
            sub: '$revDays days'),
        HomMetricCard(
            label: 'ADR',
            value: _fmt(adr),
            color: _primaryGreen,
            icon: Icons.attach_money_rounded),
        HomMetricCard(
            label: 'RevPAR',
            value: _fmt(revpar),
            color: AppColors.amber,
            icon: Icons.trending_up_rounded),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MONTHLY REVENUE',
                  style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(_fmt(totalRev),
                  style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 28)),
              const SizedBox(height: 4),
              Text('$revDays days of data',
                  style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.7),
                      fontSize: 12)),
            ]),
          ),
          if (totalExp > 0)
            Column(children: [
              Text('${(totalRev / totalExp * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 24)),
              Text('of expenses',
                  style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.7),
                      fontSize: 10)),
            ]),
        ]),
      ),
      const SizedBox(height: 12),
      Text('Daily Revenue Trend',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.grey800)),
      const SizedBox(height: 8),
      SizedBox(
        height: 160,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          ...revs.map((r) {
            final maxRev = revs.fold<double>(
                0, (m, r) => r.totalRevenue > m ? r.totalRevenue : m);
            final h = maxRev > 0 ? (r.totalRevenue / maxRev * 130) : 0.0;
            final isToday = r.date.day == DateTime.now().day;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child:
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (r.totalRevenue > 0)
                    Text(_fmt(r.totalRevenue, naira: false),
                        style: const TextStyle(
                            fontSize: 7, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Container(
                      height: h.clamp(4, 130),
                      decoration: BoxDecoration(
                        color: isToday ? _primaryGreen : AppColors.amber400,
                        borderRadius: BorderRadius.circular(2),
                      )),
                  const SizedBox(height: 2),
                  Text('${r.date.day}',
                      style: TextStyle(
                          fontSize: 7,
                          color: isToday ? _primaryGreen : AppColors.grey500)),
                ]),
              ),
            );
          }),
        ]),
      ),
      const SizedBox(height: 16),
      Text('Room Performance',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.grey800)),
      const SizedBox(height: 8),
      ...revs.takeLast(14).toList().reversed.map((r) {
        final pct = r.occupancyPct;
        final idx = OperationsStore.revenues.indexWhere(
            (x) => x.date.day == r.date.day && x.date.month == r.date.month);
        return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              onTap: () => _editRevenue(context, r, idx >= 0 ? idx : null),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          Text('${r.date.day}/${r.date.month}',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Text(_fmt(r.totalRevenue),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _primaryGreen)),
                        ]),
                        const SizedBox(height: 2),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              minHeight: 6,
                              backgroundColor: AppColors.grey200,
                              valueColor: AlwaysStoppedAnimation(pct > 70
                                  ? _primaryGreen
                                  : pct > 40
                                      ? AppColors.amber
                                      : AppColors.red400),
                            )),
                        const SizedBox(height: 2),
                        Text(
                            '${r.roomsSold} sold · ${pct.toStringAsFixed(0)}% occ · ${r.walkIns} walk-ins',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.grey500)),
                      ])),
                  RoleGate(
                      requiredPermission: Permission.createExpenditure,
                      child: IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: AppColors.red300, size: 18),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: () {
                          if (idx >= 0) {
                            OperationsStore.removeRevenue(idx);
                            onChange();
                          }
                        },
                      )),
                ]),
              ),
            ));
      }),
    ]);
  }

  void _editRevenue(BuildContext context, DailyRevenue r, int? idx) {
    final revCtl =
        TextEditingController(text: r.totalRevenue.toStringAsFixed(0));
    final roomsSoldCtl = TextEditingController(text: r.roomsSold.toString());
    final roomsAvailCtl =
        TextEditingController(text: r.roomsAvailable.toString());
    final walkInsCtl = TextEditingController(text: r.walkIns.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Edit Daily Revenue',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                    controller: revCtl,
                    decoration: const InputDecoration(
                        labelText: 'Total Revenue (₦)',
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: roomsSoldCtl,
                          decoration: const InputDecoration(
                              labelText: 'Rooms Sold',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextField(
                          controller: roomsAvailCtl,
                          decoration: const InputDecoration(
                              labelText: 'Rooms Available',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 8),
                TextField(
                    controller: walkInsCtl,
                    decoration: const InputDecoration(
                        labelText: 'Walk-ins', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      final rev = double.tryParse(revCtl.text) ?? 0;
                      final sold = int.tryParse(roomsSoldCtl.text) ?? 0;
                      if (rev <= 0 || sold <= 0 || idx == null) return;
                      OperationsStore.updateRevenue(
                          idx,
                          DailyRevenue(
                            date: r.date,
                            roomsAvailable: int.tryParse(roomsAvailCtl.text) ??
                                r.roomsAvailable,
                            roomsSold: sold,
                            walkIns: int.tryParse(walkInsCtl.text) ?? r.walkIns,
                            totalRevenue: rev,
                          ));
                      Navigator.pop(ctx);
                      onChange();
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

extension _TakeLast<T> on List<T> {
  List<T> takeLast(int n) => sublist(length < n ? 0 : length - n);
}

// ===================== NIGHT AUDIT TAB =====================

class _NightAuditTab extends StatelessWidget {
  final VoidCallback onChange;
  const _NightAuditTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final drops = OperationsStore.cashDrops;
    final todayDrops = OperationsStore.todayCashDrops;
    final weekDrops = OperationsStore.cashDropsForPeriod(7);
    final matched =
        weekDrops.where((c) => c.status == CashDropStatus.matched).length;
    final mismatched =
        weekDrops.where((c) => c.status == CashDropStatus.mismatched).length;
    final totalDiscrepancy =
        weekDrops.fold(0.0, (s, c) => s + c.difference.abs());

    return ListView(padding: const EdgeInsets.all(12), children: [
      HomResponsiveGrid(children: [
        HomMetricCard(
            label: 'Today',
            value:
                '${todayDrops.length} drop${todayDrops.length == 1 ? '' : 's'}',
            color: AppColors.blue,
            icon: Icons.today_rounded),
        HomMetricCard(
            label: 'Matched',
            value: '$matched',
            color: _primaryGreen,
            icon: Icons.check_circle_rounded),
        HomMetricCard(
            label: 'Mismatched',
            value: '$mismatched',
            color: AppColors.red,
            icon: Icons.warning_rounded),
      ]),
      const SizedBox(height: 6),
      if (totalDiscrepancy > 0)
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              color: AppColors.red50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.red200)),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.red, size: 20),
            const SizedBox(width: 10),
            Text('Week discrepancy: ${_fmt(totalDiscrepancy)}',
                style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ]),
        ),
      const SizedBox(height: 4),
      Text('Last 14 Drops',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.grey800)),
      const SizedBox(height: 8),
      ...drops.take(14).map((c) {
        final isMatch = c.status == CashDropStatus.matched;
        final isLocked = SecurityAuditStore.isDateLocked(c.date);
        return Card(
          color: isMatch ? null : AppColors.red50,
          margin: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            onTap: isLocked ? null : () => _editCashDrop(context, c),
            borderRadius: BorderRadius.circular(12),
            child: Opacity(
              opacity: isLocked ? 0.6 : 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: (isMatch ? _primaryGreen : AppColors.red)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(
                        isMatch ? Icons.check_rounded : Icons.close_rounded,
                        size: 18,
                        color: isMatch ? _primaryGreen : AppColors.red),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('${c.shift} — ${c.date.day}/${c.date.month}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(
                            'Expected: ${_fmt(c.expectedAmount)} • Actual: ${_fmt(c.actualAmount)}',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.grey600)),
                        if (c.notes.isNotEmpty)
                          Text(c.notes,
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.grey500)),
                        if (isLocked)
                          Text('Locked',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.grey500,
                                  fontWeight: FontWeight.w600)),
                      ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(_fmt(c.difference),
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: isMatch ? _primaryGreen : AppColors.red)),
                    RoleGate(
                        requiredPermission: Permission.logCashDrop,
                        child: IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: AppColors.red300, size: 18),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: isLocked
                              ? null
                              : () {
                                  OperationsStore.removeCashDrop(c.id);
                                  onChange();
                                },
                        )),
                  ]),
                ]),
              ),
            ),
          ),
        );
      }),
    ]);
  }

  void _editCashDrop(BuildContext context, CashDrop c) {
    if (SecurityAuditStore.isDateLocked(c.date)) return;
    final expectedCtl =
        TextEditingController(text: c.expectedAmount.toStringAsFixed(0));
    final actualCtl =
        TextEditingController(text: c.actualAmount.toStringAsFixed(0));
    final notesCtl = TextEditingController(text: c.notes);
    String shift = c.shift;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Edit Cash Drop',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: shift,
                  decoration: const InputDecoration(
                      labelText: 'Shift', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                    DropdownMenuItem(value: 'Evening', child: Text('Evening')),
                    DropdownMenuItem(value: 'Night', child: Text('Night')),
                  ],
                  onChanged: (v) {
                    if (v != null) setSheet(() => shift = v);
                  },
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: expectedCtl,
                          decoration: const InputDecoration(
                              labelText: 'Expected (₦)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextField(
                          controller: actualCtl,
                          decoration: const InputDecoration(
                              labelText: 'Actual (₦)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 8),
                TextField(
                    controller: notesCtl,
                    decoration: const InputDecoration(
                        labelText: 'Notes', border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      final exp = double.tryParse(expectedCtl.text) ?? 0;
                      final act = double.tryParse(actualCtl.text) ?? 0;
                      if (exp <= 0) return;
                      final status = act == exp
                          ? CashDropStatus.matched
                          : CashDropStatus.mismatched;
                      OperationsStore.updateCashDrop(
                          c.id,
                          CashDrop(
                            id: c.id,
                            date: c.date,
                            shift: shift,
                            expectedAmount: exp,
                            actualAmount: act,
                            notes: notesCtl.text,
                            status: status,
                          ));
                      Navigator.pop(ctx);
                      onChange();
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== HOUSEKEEPING TAB =====================

class _HousekeepingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final monthLoss = OperationsStore.totalLossCostThisMonth;
    final totalLoss = OperationsStore.totalLossCost;
    final byCat = OperationsStore.lossesByCategory();
    final topItems = OperationsStore.topLostItems();
    final losses = OperationsStore.lossesThisMonth;

    return ListView(padding: const EdgeInsets.all(12), children: [
      HomResponsiveGrid(children: [
        HomMetricCard(
            label: 'This Month',
            value: _fmt(monthLoss),
            color: AppColors.red,
            icon: Icons.monetization_on_rounded),
        HomMetricCard(
            label: 'All Time',
            value: _fmt(totalLoss),
            color: AppColors.orange,
            icon: Icons.history_rounded),
        HomMetricCard(
            label: 'Items Lost',
            value: '${OperationsStore.losses.length}',
            color: AppColors.blue,
            icon: Icons.inventory_rounded),
      ]),
      const SizedBox(height: 16),
      if (byCat.isNotEmpty) ...[
        Text('Loss by Category',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.grey800)),
        const SizedBox(height: 8),
        ...byCat.entries.map((e) {
          final pct = totalLoss > 0 ? e.value / totalLoss * 100 : 0.0;
          Color c;
          switch (e.key) {
            case 'Linen':
              c = AppColors.blue;
              break;
            case 'Amenity':
              c = AppColors.amber;
              break;
            case 'Furniture':
              c = AppColors.purple;
              break;
            default:
              c = AppColors.grey500;
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Flexible(
                  flex: 2,
                  child: Text(e.key,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: c),
                      overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: AppColors.grey200,
                    minHeight: 16,
                    valueColor: AlwaysStoppedAnimation(c),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                  width: 44,
                  child: Text('${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey700),
                      textAlign: TextAlign.right)),
              SizedBox(
                  width: 52,
                  child: Text(_fmt(e.value),
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right)),
            ]),
          );
        }),
      ],
      const SizedBox(height: 16),
      if (topItems.isNotEmpty) ...[
        Text('Top Lost Items',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.grey800)),
        const SizedBox(height: 8),
        ...topItems.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.red50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('${e.value}x',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.red700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(e.key,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis)),
              ]),
            )),
      ],
      const SizedBox(height: 16),
      Text('Recent Records',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.grey800)),
      const SizedBox(height: 8),
      ...losses.take(10).map((l) => Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: AppColors.red50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('${l.quantity}x',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.red700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(l.item,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                          '${l.date.day}/${l.date.month} — Room ${l.roomNumber} — ${l.category}',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.grey500)),
                    ])),
                Text(_fmt(l.totalCost),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.red700)),
              ]),
            ),
          )),
    ]);
  }
}
