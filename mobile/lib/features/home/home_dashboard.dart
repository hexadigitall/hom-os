import 'package:flutter/material.dart';
import '../../data/back_office_store.dart';
import '../../data/compliance_store.dart';
import '../../data/expenditure_store.dart';
import '../../data/facility_store.dart';
import '../../data/fnb_store.dart';
import '../../data/hotel_settings_store.dart';
import '../../data/housekeeping_store.dart';
import '../../data/notification_store.dart';
import '../../data/operations_store.dart';
import '../../data/payment_store.dart';
import '../../data/reconciliation_store.dart';
import '../../data/role_store.dart';
import '../../data/security_audit_store.dart';
import '../../data/subscription_store.dart';
import '../../data/user_store.dart';
import '../../main.dart' as app;
import '../../models/facility.dart';
import '../../models/food_beverage.dart';
import '../../utils/theme.dart';
import '../../widgets/hom_widgets.dart';

/// Role-aware Home tab. Every role lands here, but the dashboard content is
/// chosen from the account's role so the "Home" they see matches the work
/// they do: management sees revenue/occupancy, front desk sees rooms and
/// in-house guests, housekeeping sees tasks, kitchen sees orders, etc.
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  @override
  Widget build(BuildContext context) {
    final session = RoleStore.current;

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _header(session),
          const SizedBox(height: 16),
          ..._roleSections(session),
        ],
      ),
    );
  }

  // ────────────────────────────── shared bits ──────────────────────────────

  Widget _header(Session session) {
    final firstName = session.userName.trim().split(' ').first;
    final hotelName = HotelSettingsStore.displayName(
      session.hotelId,
      session.hotelName,
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        '$greeting(), $firstName',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
      ),
      const SizedBox(height: 4),
      Row(children: [
        const Icon(Icons.apartment_rounded,
            size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            hotelName.isEmpty ? 'Welcome to HOM' : hotelName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.grey700,
              height: 1.25,
            ),
          ),
        ),
      ]),
    ]);
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _naira(num value) {
    final whole = value.round();
    final sign = whole < 0 ? '-' : '';
    final s = whole.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '$sign₦$buf';
  }

  String _pct(double value) => '${value.toStringAsFixed(0)}%';

  List<Widget> _sections({
    List<HomMetricCard> kpis = const [],
    List<Widget> alerts = const [],
    List<Widget> recents = const [],
  }) {
    final children = <Widget>[
      if (kpis.isNotEmpty) ...[
        const HomSectionTitle(title: 'At a glance'),
        const SizedBox(height: 8),
        HomResponsiveGrid(children: kpis),
      ],
    ];
    final unread = NotificationStore.unreadCount;
    if (unread > 0) {
      children.addAll(const [SizedBox(height: 16)]);
      children.add(_alertRow(
        Icons.notifications_rounded,
        '$unread unread notification${unread == 1 ? '' : 's'}',
        AppColors.blue,
      ));
    }
    if (alerts.isNotEmpty) {
      children.addAll(const [SizedBox(height: 16), HomSectionTitle(title: 'Needs attention')]);
      children.add(const SizedBox(height: 4));
      children.addAll(alerts);
    }
    if (recents.isNotEmpty) {
      children.addAll(const [SizedBox(height: 16), HomSectionTitle(title: 'Recent activity')]);
      children.add(const SizedBox(height: 4));
      children.addAll(recents);
    }
    return children;
  }

  Widget _alertRow(IconData icon, String text, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ),
      ]),
    );
  }

  Widget _tile(String title, String subtitle, {Widget? trailing}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis),
        trailing: trailing,
      ),
    );
  }

  // ────────────────────────────── role dispatch ──────────────────────────────

  List<Widget> _roleSections(Session session) {
    final ids = session.roleIds;
    if (ids.contains('super_admin') || ids.contains('hotel_manager')) {
      return [..._managementSections(), ..._facilitySections()];
    }
    switch (session.primaryRole?.id) {
      case 'auditor':
        return _auditorSections();
      case 'front_desk':
        return _frontDeskSections();
      case 'accountant':
        return _accountantSections();
      case 'housekeeping':
        return _housekeepingSections();
      case 'kitchen':
        return _kitchenSections();
      case 'dept_head':
        return [..._deptHeadSections(), ..._facilitySections()];
      case 'events_coordinator':
      case 'wellness_attendant':
      case 'gift_shop_cashier':
        return _facilitySections();
      default:
        return _managementSections();
    }
  }

  // ────────────────────────────── facilities ──────────────────────────────

  List<Widget> _facilitySections() {
    final bookings = FacilityStore.bookings
        .where((b) => b.status != BookingStatus.cancelled)
        .take(4)
        .toList();
    final recents = bookings.map((b) {
      return _tile(
        '${b.guestName} — ${b.facilityName}',
        '${b.kind.label}  ·  ${b.status.label}',
        trailing: Text(_naira(b.amount),
            style:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      );
    }).toList();

    return _sections(
      kpis: [
        HomMetricCard(
            label: 'Amenity revenue',
            value: _naira(FacilityStore.monthRevenue),
            color: AppColors.amber,
            icon: Icons.holiday_village_rounded,
            sub: 'this month'),
        HomMetricCard(
            label: 'Bookings',
            value: '${FacilityStore.bookings.length}',
            color: AppColors.primary,
            icon: Icons.event_available_rounded),
        HomMetricCard(
            label: 'Visits today',
            value: '${FacilityStore.todaysCheckIns.length}',
            color: AppColors.blue,
            icon: Icons.login_rounded),
        HomMetricCard(
            label: 'Low-stock retail',
            value: '${FacilityStore.lowStockItems.length}',
            color: AppColors.red,
            icon: Icons.shopping_bag_rounded),
      ],
      alerts: [
        for (final s in FacilityStore.revenueBySource(
            DateTime.now().year, DateTime.now().month)
            .entries
            .take(3))
          _alertRow(
            Icons.trending_up_rounded,
            '${s.key}: ${_naira(s.value)} facility revenue this month',
            AppColors.amber,
          ),
      ],
      recents: recents,
    );
  }

  List<Widget> _bookingRecents() {
    return app.HOMData.bookings.take(4).map((b) {
      return _tile(
        '${b.guest} — Room ${b.room}',
        '${b.checkin} → ${b.checkout}',
        trailing: HomStatusChip.fromStatus(b.status),
      );
    }).toList();
  }

  // ────────────────────────────── management ──────────────────────────────

  List<Widget> _managementSections() {
    final alerts = <Widget>[
      if (ExpenditureStore.count > 0)
        _alertRow(
          Icons.receipt_long_rounded,
          '${_naira(ExpenditureStore.totalAll)} total expenditure '
          '(${ExpenditureStore.count} records)',
          AppColors.amber,
        ),
      if (ReconciliationStore.totalUnmatchedAmount > 0)
        _alertRow(
          Icons.compare_arrows_rounded,
          '${_naira(ReconciliationStore.totalUnmatchedAmount)} in bank '
          'transactions not yet matched',
          AppColors.blue,
        ),
      if (ComplianceStore.thresholdAlertCount > 0)
        _alertRow(
          Icons.gpp_bad_rounded,
          '${ComplianceStore.thresholdAlertCount} cash transaction(s) exceed '
          'the ₦5M compliance threshold',
          AppColors.red,
        ),
      if (SubscriptionStore.totalMonthlyCost > 0)
        _alertRow(
          Icons.subscriptions_rounded,
          '${_naira(SubscriptionStore.totalMonthlyCost)}/mo in active '
          'subscriptions',
          AppColors.green,
        ),
    ];

    return _sections(
      kpis: [
        HomMetricCard(
            label: 'Occupancy',
            value: _pct(OperationsStore.monthAvgOccupancy),
            color: AppColors.blue,
            icon: Icons.bed_rounded,
            sub: 'this month'),
        HomMetricCard(
            label: 'Revenue',
            value: _naira(OperationsStore.monthRevenue),
            color: AppColors.primary,
            icon: Icons.payments_rounded,
            sub: 'this month'),
        HomMetricCard(
            label: 'Avg rate',
            value: _naira(OperationsStore.monthAvgAdr),
            color: AppColors.amber,
            icon: Icons.room_service_rounded),
        HomMetricCard(
            label: 'RevPAR',
            value: _naira(OperationsStore.monthAvgRevpar),
            color: AppColors.red,
            icon: Icons.trending_up_rounded),
      ],
      alerts: alerts,
      recents: _bookingRecents(),
    );
  }

  // ────────────────────────────── auditor ──────────────────────────────

  List<Widget> _auditorSections() {
    final alerts = <Widget>[
      if (OperationsStore.totalDiscrepancy != 0)
        _alertRow(
          Icons.money_off_rounded,
          'Cash drop discrepancy of '
          '${_naira(OperationsStore.totalDiscrepancy)}',
          AppColors.red,
        ),
      if (ComplianceStore.thresholdAlertCount > 0)
        _alertRow(
          Icons.gpp_bad_rounded,
          '${ComplianceStore.thresholdAlertCount} cash transaction(s) exceed '
          'the ₦5M compliance threshold',
          AppColors.red,
        ),
    ];

    return _sections(
      kpis: [
        HomMetricCard(
            label: 'Revenue',
            value: _naira(OperationsStore.monthRevenue),
            color: AppColors.primary,
            icon: Icons.payments_rounded,
            sub: 'this month'),
        HomMetricCard(
            label: 'Expenses',
            value: _naira(ExpenditureStore.totalAll),
            color: AppColors.amber,
            icon: Icons.receipt_long_rounded),
        HomMetricCard(
            label: 'Matched',
            value: _naira(ReconciliationStore.totalMatchedAmount),
            color: AppColors.green,
            icon: Icons.verified_rounded),
        HomMetricCard(
            label: 'Unmatched',
            value: _naira(ReconciliationStore.totalUnmatchedAmount),
            color: AppColors.red,
            icon: Icons.compare_arrows_rounded),
      ],
      alerts: alerts,
      recents: _expenditureRecents(),
    );
  }

  // ────────────────────────────── front desk ──────────────────────────────

  List<Widget> _frontDeskSections() {
    final today = OperationsStore.todayRevenue;
    final available = today == null
        ? OperationsStore.totalRooms
        : today.roomsAvailable - today.roomsSold;
    final sold = today?.roomsSold ?? 0;

    final alerts = <Widget>[
      if (SecurityAuditStore.activeShift != null)
        _alertRow(
          Icons.logout_rounded,
          'Shift active — ${SecurityAuditStore.activeShift!.staffName} '
          '(${SecurityAuditStore.activeShift!.shift})',
          AppColors.green,
        ),
      if (SecurityAuditStore.activeVisitors.isNotEmpty)
        _alertRow(
          Icons.badge_rounded,
          '${SecurityAuditStore.activeVisitors.length} active '
          'visitor${SecurityAuditStore.activeVisitors.length == 1 ? '' : 's'} '
          'on site',
          AppColors.blue,
        ),
      if (SecurityAuditStore.openIncidents.isNotEmpty)
        _alertRow(
          Icons.warning_rounded,
          '${SecurityAuditStore.openIncidents.length} open security '
          'incident${SecurityAuditStore.openIncidents.length == 1 ? '' : 's'}',
          AppColors.red,
        ),
    ];

    return _sections(
      kpis: [
        HomMetricCard(
            label: 'Rooms free',
            value: '$available',
            color: AppColors.blue,
            icon: Icons.meeting_room_rounded,
            sub: 'of ${today?.roomsAvailable ?? OperationsStore.totalRooms}'),
        HomMetricCard(
            label: 'In-house',
            value: '$sold',
            color: AppColors.primary,
            icon: Icons.bed_rounded,
            sub: 'guests checked in'),
        HomMetricCard(
            label: 'Cash drops',
            value: '${OperationsStore.todayCashDrops.length}',
            color: AppColors.amber,
            icon: Icons.payments_rounded,
            sub: 'today'),
        HomMetricCard(
            label: 'POS pending',
            value: '${PaymentStore.pendingSettlements.length}',
            color: AppColors.red,
            icon: Icons.point_of_sale_rounded),
      ],
      alerts: alerts,
      recents: _bookingRecents(),
    );
  }

  // ────────────────────────────── accountant ──────────────────────────────

  List<Widget> _accountantSections() {
    final alerts = <Widget>[
      if (OperationsStore.totalDiscrepancy != 0)
        _alertRow(
          Icons.money_off_rounded,
          'Cash drop discrepancy of '
          '${_naira(OperationsStore.totalDiscrepancy)}',
          AppColors.red,
        ),
      if (ComplianceStore.thresholdAlertCount > 0)
        _alertRow(
          Icons.gpp_bad_rounded,
          '${ComplianceStore.thresholdAlertCount} cash transaction(s) exceed '
          'the ₦5M compliance threshold',
          AppColors.red,
        ),
    ];

    return _sections(
      kpis: [
        HomMetricCard(
            label: 'Expenses',
            value: _naira(ExpenditureStore.totalAll),
            color: AppColors.amber,
            icon: Icons.receipt_long_rounded,
            sub: '${ExpenditureStore.count} records'),
        HomMetricCard(
            label: 'Matched',
            value: _naira(ReconciliationStore.totalMatchedAmount),
            color: AppColors.green,
            icon: Icons.verified_rounded),
        HomMetricCard(
            label: 'Unmatched',
            value: _naira(ReconciliationStore.totalUnmatchedAmount),
            color: AppColors.red,
            icon: Icons.compare_arrows_rounded),
        HomMetricCard(
            label: 'Payroll paid',
            value: _naira(BackOfficeStore.totalPaid),
            color: AppColors.primary,
            icon: Icons.payments_rounded),
      ],
      alerts: alerts,
      recents: _expenditureRecents(),
    );
  }

  List<Widget> _expenditureRecents() {
    final sorted = [...ExpenditureStore.all]..sort(
        (a, b) => b.date.compareTo(a.date));
    return sorted.take(4).map((e) {
      return _tile(
        e.vendor.isEmpty ? e.description : e.vendor,
        '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-'
            '${e.date.day.toString().padLeft(2, '0')}  •  ${e.category.name}',
        trailing: Text(_naira(e.amount),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      );
    }).toList();
  }

  // ────────────────────────────── housekeeping ──────────────────────────────

  List<Widget> _housekeepingSections() {
    final unclaimed = HousekeepingStore.unclaimed.length;
    final alerts = <Widget>[
      if (HousekeepingStore.condemnedCount > 0)
        _alertRow(
          Icons.dry_cleaning_rounded,
          '${HousekeepingStore.condemnedCount} item(s) condemned — '
          '${_naira(HousekeepingStore.totalReplacementCost)} to replace',
          AppColors.red,
        ),
      if (unclaimed > 0)
        _alertRow(
          Icons.search_rounded,
          '$unclaimed unclaimed lost & found item${
              unclaimed == 1 ? '' : 's'}',
          AppColors.blue,
        ),
    ];

    final pending = HousekeepingStore.pendingTasks.take(4).map((t) {
      final date = t.scheduledDate;
      return _tile(
        'Room ${t.roomNumber} — ${t.assignedTo}',
        '${t.priorityLabel}  •  '
            '${date.day}/${date.month}/${date.year}',
      );
    }).toList();

    return _sections(
      kpis: [
        HomMetricCard(
            label: 'Pending',
            value: '${HousekeepingStore.pendingTasks.length}',
            color: AppColors.blue,
            icon: Icons.cleaning_services_rounded,
            sub: 'tasks'),
        HomMetricCard(
            label: 'Overdue',
            value: '${HousekeepingStore.overdueTasks.length}',
            color: AppColors.red,
            icon: Icons.schedule_rounded),
        HomMetricCard(
            label: 'Laundry',
            value: '${HousekeepingStore.pendingLaundry.length}',
            color: AppColors.amber,
            icon: Icons.local_laundry_service_rounded,
            sub: 'pending'),
        HomMetricCard(
            label: 'Condemned',
            value: '${HousekeepingStore.condemnedCount}',
            color: AppColors.red,
            icon: Icons.report_rounded),
      ],
      alerts: alerts,
      recents: pending,
    );
  }

  // ────────────────────────────── kitchen ──────────────────────────────

  List<Widget> _kitchenSections() {
    final occupied = FnbStore.tables.where(
      (t) => t.status == TableStatus.occupied || t.status == TableStatus.reserved,
    ).length;
    final lowStock =
        app.HOMData.inventory.where((i) => i.qty <= i.low).length;
    final preparing = FnbStore.openOrders.where((o) => o.status == OrderStatus.preparing).length;

    final recents = FnbStore.openOrders.take(4).map((o) {
      return _tile(
        'Table ${o.tableNumber} — ${o.serverName}',
        '${_naira(o.subtotal)}  •  ${o.status.name}',
      );
    }).toList();

    return _sections(
      kpis: [
        HomMetricCard(
            label: 'Open orders',
            value: '${FnbStore.openOrders.length}',
            color: AppColors.primary,
            icon: Icons.receipt_long_rounded),
        HomMetricCard(
            label: 'Tables',
            value: '$occupied',
            color: AppColors.amber,
            icon: Icons.table_restaurant_rounded,
            sub: 'occupied'),
        HomMetricCard(
            label: 'Preparing',
            value: '$preparing',
            color: AppColors.blue,
            icon: Icons.soup_kitchen_rounded),
        HomMetricCard(
            label: 'Low stock',
            value: '$lowStock',
            color: AppColors.red,
            icon: Icons.inventory_2_rounded),
      ],
      alerts: const [],
      recents: recents,
    );
  }

  // ────────────────────────────── dept head ──────────────────────────────

  List<Widget> _deptHeadSections() {
    final deptExpenses =
        ExpenditureStore.forCurrentDepartment.fold(0.0, (s, r) => s + r.amount);
    final lowStock =
        app.HOMData.inventory.where((i) => i.qty <= i.low).length;

    final recents = BackOfficeStore.openOrders.take(4).map((p) {
      return _tile(
        p.vendorName,
        '${p.items}  •  ${p.status.name}',
        trailing: Text(_naira(p.amount),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      );
    }).toList();

    return _sections(
      kpis: [
        HomMetricCard(
            label: 'Dept spend',
            value: _naira(deptExpenses),
            color: AppColors.amber,
            icon: Icons.receipt_long_rounded),
        HomMetricCard(
            label: 'Staff',
            value: '${UserStore.getUsers().length}',
            color: AppColors.primary,
            icon: Icons.people_rounded),
        HomMetricCard(
            label: 'Open PO',
            value: '${BackOfficeStore.openOrders.length}',
            color: AppColors.blue,
            icon: Icons.shopping_cart_rounded),
        HomMetricCard(
            label: 'Low stock',
            value: '$lowStock',
            color: AppColors.red,
            icon: Icons.inventory_2_rounded),
      ],
      alerts: const [],
      recents: recents,
    );
  }
}
