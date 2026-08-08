import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/facility.dart';
import '../../data/facility_store.dart';
import '../../data/feed_store.dart';
import '../../data/role_store.dart';
import '../../models/role.dart';
import '../../widgets/hom_widgets.dart';
import '../../utils/theme.dart';

final Color _primary = AppColors.primary;

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

String _fmtDate(DateTime d) =>
    '${_mon[d.month - 1]} ${d.day}, ${d.year}';
const _mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _normPhone(String phone) {
  var p = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (p.isEmpty) return '';
  if (p.startsWith('0')) p = '234${p.substring(1)}';
  return p;
}

String _waBookingMessage(FacilityBooking b) {
  final lines = <String>[
    'HOM — ${b.facilityName}',
    b.kind.label.toUpperCase(),
    'Guest: ${b.guestName}',
    'Date: ${_fmtDate(b.date)}',
    if (b.isEvent && b.eventType.isNotEmpty) 'Event: ${b.eventType}',
    if (b.isEvent) 'Guests: ${b.guestCount}',
    if (b.qty > 1) 'Qty: ${b.qty}',
    'Amount: ${_naira(b.amount)}',
    'Paid: ${_naira(b.paidAmount)}',
    'Status: ${b.status.label}',
    'Reference: ${b.id}',
  ];
  return lines.join('\n');
}

Future<void> _sendWhatsApp(String phone, String message) async {
  final p = _normPhone(phone);
  if (p.isEmpty) return;
  final uri = Uri.parse('https://wa.me/$p?text=${Uri.encodeComponent(message)}');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

IconData _typeIcon(FacilityType t) => switch (t) {
      FacilityType.gym => Icons.fitness_center_rounded,
      FacilityType.pool => Icons.pool_rounded,
      FacilityType.giftShop => Icons.shopping_bag_rounded,
      FacilityType.eventHall => Icons.event_available_rounded,
    };

IconData _kindIcon(BookingKind k) => switch (k) {
      BookingKind.dayPass => Icons.confirmation_number_rounded,
      BookingKind.membership => Icons.badge_rounded,
      BookingKind.event => Icons.event_rounded,
    };

Color _statusColor(BookingStatus s) => switch (s) {
      BookingStatus.requested => AppColors.blue,
      BookingStatus.confirmed => AppColors.orange,
      BookingStatus.depositPaid => AppColors.amber,
      BookingStatus.paid => AppColors.primary,
      BookingStatus.cancelled => AppColors.red,
    };

Color _typeColor(FacilityType t) => switch (t) {
      FacilityType.gym => AppColors.red400,
      FacilityType.pool => AppColors.blue,
      FacilityType.giftShop => AppColors.orange,
      FacilityType.eventHall => AppColors.amber,
    };

void _feed(String action, String message, String refId) {
  FeedStore.log(
    dept: 'banqueting',
    action: action,
    message: message,
    refId: refId,
  );
}

enum _FacTabKind { facilities, bookings, giftShop, revenue }

List<_FacTabKind> _facTabsFor(Session s) {
  final kinds = <_FacTabKind>[];
  final core = s.hasAny(const [
    Permission.viewFacilities, Permission.manageFacilities,
    Permission.manageFacilityAccess, Permission.manageGiftShop,
  ]);
  if (core) {
    kinds.add(_FacTabKind.facilities);
    kinds.add(_FacTabKind.bookings);
  }
  if (s.hasAny(const [Permission.manageGiftShop, Permission.manageFacilities])) {
    kinds.add(_FacTabKind.giftShop);
  }
  if (s.hasAny(const [
    Permission.viewNightAudit, Permission.manageFacilities,
    Permission.manageFacilityAccess, Permission.manageGiftShop,
  ])) {
    kinds.add(_FacTabKind.revenue);
  }
  return kinds;
}

class FacilitiesScreen extends StatefulWidget {
  const FacilitiesScreen({super.key});
  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<_FacTabKind> _kinds;

  @override
  void initState() {
    super.initState();
    _kinds = _facTabsFor(RoleStore.current);
    _tabController = TabController(length: _kinds.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_kinds.isEmpty) {
      return const Scaffold(
          body: Center(child: Text('No facility access')));
    }
    return Scaffold(
      body: Column(children: [
        Material(
          color: AppColors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: _primary,
            labelColor: _primary,
            unselectedLabelColor: AppColors.grey500,
            tabs: _kinds
                .map((k) => Tab(
                      text: switch (k) {
                        _FacTabKind.facilities => 'Facilities',
                        _FacTabKind.bookings => 'Bookings & Events',
                        _FacTabKind.giftShop => 'Gift Shop',
                        _FacTabKind.revenue => 'Revenue',
                      },
                      icon: Icon(switch (k) {
                        _FacTabKind.facilities => Icons.holiday_village_rounded,
                        _FacTabKind.bookings => Icons.event_available_rounded,
                        _FacTabKind.giftShop => Icons.shopping_bag_rounded,
                        _FacTabKind.revenue => Icons.trending_up_rounded,
                      }, size: 16),
                    ))
                .toList(),
          ),
        ),
        Expanded(
            child: TabBarView(controller: _tabController, children: [
          ..._kinds.map((k) => switch (k) {
                _FacTabKind.facilities => const _FacilitiesTab(),
                _FacTabKind.bookings => const _BookingsTab(),
                _FacTabKind.giftShop => const _GiftShopTab(),
                _FacTabKind.revenue => const _RevenueTab(),
              }),
        ])),
      ]),
    );
  }
}

// ───────────────────────────── FACILITIES TAB ─────────────────────────────

class _FacilitiesTab extends StatefulWidget {
  const _FacilitiesTab();
  @override
  State<_FacilitiesTab> createState() => _FacilitiesTabState();
}

class _FacilitiesTabState extends State<_FacilitiesTab> {
  bool get canEdit => RoleStore.has(Permission.manageFacilities);

  @override
  Widget build(BuildContext context) {
    final facilities = FacilityStore.facilities;
    final openToday = FacilityStore.bookings
        .where((b) =>
            b.status != BookingStatus.cancelled &&
            b.date.year == DateTime.now().year &&
            b.date.month == DateTime.now().month &&
            b.date.day == DateTime.now().day)
        .length;
    final visits = FacilityStore.todaysCheckIns.length;

    return ListView(padding: const EdgeInsets.all(12), children: [
      HomResponsiveGrid(children: [
        HomMetricCard(
            label: 'Amenities',
            value: '${facilities.length}',
            color: _primary,
            icon: Icons.holiday_village_rounded,
            sub: '${facilities.where((f) => f.isAvailable).length} available'),
        HomMetricCard(
            label: 'Bookings today',
            value: '$openToday',
            color: AppColors.blue,
            icon: Icons.event_available_rounded),
        HomMetricCard(
            label: 'Visits today',
            value: '$visits',
            color: AppColors.amber,
            icon: Icons.login_rounded,
            sub: 'access log'),
      ]),
      const SizedBox(height: 12),
      HomSectionTitle(
        title: 'Facility & Amenity List',
        trailing: canEdit
            ? TextButton.icon(
                onPressed: () => _addFacility(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
              )
            : null,
      ),
      const SizedBox(height: 8),
      for (final type in FacilityType.values) ...[
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 10, bottom: 4),
          child: Text(
            type.label.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _typeColor(type),
                letterSpacing: 0.5),
          ),
        ),
        for (final f in facilities.where((f) => f.type == type))
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: InkWell(
              onTap: canEdit ? () => _editFacility(context, f) : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: _typeColor(type).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(_typeIcon(type), color: _typeColor(type), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(f.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14),
                                    overflow: TextOverflow.ellipsis)),
                            HomStatusChip(
                                label: f.isAvailable ? 'Open' : 'Closed',
                                color: f.isAvailable
                                    ? _primary
                                    : AppColors.red),
                          ]),
                          const SizedBox(height: 2),
                          Text(
                            '${f.hours}  ·  ${f.capacity > 0 ? '${f.capacity} capacity' : ''}',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.grey600),
                          ),
                          Text(
                            f.type == FacilityType.eventHall
                                ? '${_naira(f.rate)}/event  ·  deposit ${f.depositPercent.toStringAsFixed(0)}%'
                                : f.rate > 0
                                    ? '${_naira(f.rate)}/pass'
                                    : 'Retail point of sale',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _typeColor(type)),
                          ),
                          if (f.type == FacilityType.eventHall &&
                              f.equipment.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Wrap(
                                  spacing: 4,
                                  runSpacing: 2,
                                  children: f.equipment
                                      .take(4)
                                      .map((e) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                                color: AppColors.grey100,
                                                borderRadius:
                                                    BorderRadius.circular(4)),
                                            child: Text(
                                              e,
                                              style: const TextStyle(
                                                  fontSize: 9,
                                                  color: AppColors.grey700),
                                            ),
                                          ))
                                      .toList()),
                            ),
                        ]),
                  ),
                ]),
              ),
            ),
          ),
      ],
    ]);
  }

  void _addFacility(BuildContext context) => _facilitySheet(context, null);

  void _editFacility(BuildContext context, Facility f) =>
      _facilitySheet(context, f);
}

Future<void> _facilitySheet(BuildContext context, Facility? existing) {
  final nameCtl = TextEditingController(text: existing?.name ?? '');
  final rateCtl = TextEditingController(
      text: existing != null && existing.rate > 0
          ? existing.rate.toStringAsFixed(0)
          : '');
  final capCtl = TextEditingController(
      text: existing != null && existing.capacity > 0
          ? existing.capacity.toString()
          : '');
  final hoursCtl = TextEditingController(text: existing?.hours ?? '');
  final venueCtl = TextEditingController(text: existing?.venue ?? '');
  final descCtl = TextEditingController(text: existing?.description ?? '');
  final depositCtl = TextEditingController(
      text: existing != null && existing.depositPercent > 0
          ? existing.depositPercent.toStringAsFixed(0)
          : '');
  final equipmentCtl = TextEditingController(
      text: existing?.equipment.join(', ') ?? '');
  final blockedCtl = TextEditingController(
      text: existing?.blockedDates.join(', ') ?? '');
  var type = existing?.type ?? FacilityType.gym;
  var available = existing?.isAvailable ?? true;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(existing == null ? 'Add Facility' : 'Edit Facility',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(
                      labelText: 'Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<FacilityType>(
                key: ValueKey('fac-type-$type'),
                initialValue: type,
                decoration: const InputDecoration(
                    labelText: 'Type', border: OutlineInputBorder()),
                items: FacilityType.values
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text('${t.label} (${t.shortLabel})')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSheetState(() => type = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: rateCtl,
                  decoration: const InputDecoration(
                      labelText: 'Rate (₦) — pass price / event fee',
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(
                  controller: capCtl,
                  decoration: const InputDecoration(
                      labelText: 'Capacity (members / visitors / hall seats)',
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(
                  controller: hoursCtl,
                  decoration: const InputDecoration(
                      labelText: 'Hours', border: OutlineInputBorder())),
              if (type == FacilityType.eventHall) ...[
                const SizedBox(height: 12),
                TextField(
                    controller: venueCtl,
                    decoration: const InputDecoration(
                        labelText: 'Venue / Location',
                        border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: depositCtl,
                    decoration: const InputDecoration(
                        labelText: 'Deposit schedule (%) — e.g. 70 for 70/30',
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(
                    controller: equipmentCtl,
                    decoration: const InputDecoration(
                        labelText: 'Equipment (comma separated) — AV, tables, chairs',
                        border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: blockedCtl,
                    decoration: const InputDecoration(
                        labelText: 'Blocked dates (yyyy-MM-dd, comma separated)',
                        border: OutlineInputBorder())),
              ],
              const SizedBox(height: 12),
              TextField(
                  controller: descCtl,
                  decoration: const InputDecoration(
                      labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2),
              SwitchListTile(
                  value: available,
                  onChanged: (v) => setSheetState(() => available = v),
                  title: const Text('Available for booking'),
                  contentPadding: EdgeInsets.zero),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    if (nameCtl.text.isEmpty) return;
                    final f = Facility(
                      id: existing?.id ??
                          'fac_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameCtl.text,
                      type: type,
                      rate: double.tryParse(rateCtl.text) ?? 0,
                      capacity: int.tryParse(capCtl.text) ?? 0,
                      isAvailable: available,
                      hours: hoursCtl.text,
                      description: descCtl.text,
                      venue: venueCtl.text,
                      depositPercent: double.tryParse(depositCtl.text) ?? 0,
                      blockedDates: blockedCtl.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList(),
                      equipment: equipmentCtl.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList(),
                    );
                    if (existing != null) {
                      FacilityStore.updateFacility(existing.id, f);
                    } else {
                      FacilityStore.addFacility(f);
                    }
                    _feed('facility.${existing == null ? 'created' : 'updated'}',
                        '${existing == null ? 'Added' : 'Updated'} facility ${f.name}',
                        f.id);
                    Navigator.pop(ctx);
                  },
                  child: Text(existing == null ? 'Add Facility' : 'Update Facility'),
                ),
              ),
            ]),
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────── BOOKINGS & EVENTS TAB ───────────────────────────

class _BookingsTab extends StatefulWidget {
  const _BookingsTab();
  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  var _kindFilter = 0; // 0 = all
  final _searchCtl = TextEditingController();

  bool get canManage => RoleStore.hasAny(const [
        Permission.manageFacilities,
        Permission.manageFacilityAccess,
        Permission.manageCorporateEvents,
        Permission.manageBanquetingHallRentals,
      ]);
  bool get canDelete => RoleStore.hasAny(const [
        Permission.manageFacilities,
        Permission.manageCorporateEvents,
        Permission.manageBanquetingHallRentals,
      ]);

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = FacilityStore.bookings;
    final q = _searchCtl.text.toLowerCase();
    var list = all.where((b) {
      if (_kindFilter != 0 && b.kind.index != _kindFilter - 1) return false;
      if (q.isNotEmpty &&
          !b.guestName.toLowerCase().contains(q) &&
          !b.facilityName.toLowerCase().contains(q) &&
          !b.phone.contains(q)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final counts = <int, int>{0: all.length};
    for (final k in BookingKind.values) {
      counts[k.index + 1] = all.where((b) => b.kind == k).length;
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _searchCtl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search guest, facility or phone…',
                isDense: true,
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search, size: 18),
              ),
            ),
          ),
          if (canManage) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: AppColors.white),
              onPressed: () => _addBooking(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Book'),
            ),
          ],
        ]),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          for (var i = 0; i <= BookingKind.values.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(i == 0
                    ? 'All ($counts[0]!)'
                    : '${BookingKind.values[i - 1].label} ($counts[i]!)'),
                selected: _kindFilter == i,
                onSelected: (_) => setState(() => _kindFilter = i),
              ),
            ),
        ]),
      ),
      Expanded(
        child: list.isEmpty
            ? const Center(child: Text('No bookings yet'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                itemCount: list.length,
                itemBuilder: (context, i) => _bookingCard(context, list[i]),
              ),
      ),
    ]);
  }

  Widget _bookingCard(BuildContext context, FacilityBooking b) {
    final today = DateTime.now();
    final isToday = b.date.year == today.year &&
        b.date.month == today.month &&
        b.date.day == today.day;
    final checkins = b.checkIns.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: _statusColor(b.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(_kindIcon(b.kind),
                  color: _statusColor(b.status), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.guestName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                Text(
                  '${b.facilityName}  ·  ${b.kind.label}  ·  ${_fmtDate(b.date)}${isToday ? ' (today)' : ''}',
                  style: TextStyle(fontSize: 11, color: AppColors.grey600),
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
            HomStatusChip(label: b.status.label, color: _statusColor(b.status)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Text(
                'Amount ${_naira(b.amount)}  ·  Paid ${_naira(b.paidAmount)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
            if (checkins > 0)
              Text('$checkins check-in${checkins == 1 ? '' : 's'}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _primary)),
          ]),
          if (b.isEvent && (b.eventType.isNotEmpty || b.organizer.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${b.eventType}${b.eventType.isNotEmpty && b.organizer.isNotEmpty ? ' · ' : ''}${b.organizer}'
                '${b.guestCount > 0 ? ' · ${b.guestCount} guests' : ''}',
                style: TextStyle(fontSize: 11, color: AppColors.grey600),
              ),
            ),
          if (b.balance > 0 && b.status != BookingStatus.cancelled)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Balance ${_naira(b.balance)}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange),
              ),
            ),
          const SizedBox(height: 8),
          Row(children: [
            if (canManage) ...[
              if (b.status == BookingStatus.requested)
                _actionBtn('Confirm', Icons.check_rounded, _primary, () {
                  _setStatus(b, BookingStatus.confirmed, 'Confirmed booking for ${b.guestName}');
                }),
              if (b.status == BookingStatus.confirmed)
                _actionBtn(
                    b.isEvent ? 'Deposit' : 'Collect',
                    Icons.payments_rounded,
                    AppColors.amber,
                    () => _setStatus(b, BookingStatus.depositPaid,
                        'Deposit collected for ${b.guestName}')),
              if (b.status == BookingStatus.depositPaid)
                _actionBtn('Full Payment', Icons.check_circle_rounded,
                    _primary, () {
                  _setStatus(b, BookingStatus.paid,
                      'Full payment received for ${b.guestName}');
                }),
              if (!b.isEvent && b.status == BookingStatus.paid)
                _actionBtn('Check-in', Icons.login_rounded, AppColors.blue, () {
                  FacilityStore.checkInBooking(b.id);
                  setState(() {});
                  _feed('facility.checkin',
                      '${b.guestName} checked in at ${b.facilityName}', b.id);
                }),
            ],
            if (b.phone.isNotEmpty)
              _actionBtn('WhatsApp', Icons.chat_rounded, AppColors.whatsapp,
                  () => _sendWhatsApp(b.phone, _waBookingMessage(b))),
            const Spacer(),
            if (canDelete)
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: AppColors.red300, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () {
                  FacilityStore.removeBooking(b.id);
                  setState(() {});
                },
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          minimumSize: const Size(0, 30),
          visualDensity: VisualDensity.compact,
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label),
      ),
    );
  }

  void _setStatus(FacilityBooking b, BookingStatus status, String verbMsg) {
    final copy = FacilityBooking(
      id: b.id, facilityId: b.facilityId, facilityName: b.facilityName,
      kind: b.kind, status: status, guestName: b.guestName, phone: b.phone,
      date: b.date, endDate: b.endDate, qty: b.qty, amount: b.amount,
      paidAmount: status == BookingStatus.paid
          ? b.amount
          : status == BookingStatus.depositPaid
              ? b.depositDue
              : b.paidAmount,
      depositPercent: b.depositPercent, eventType: b.eventType,
      guestCount: b.guestCount, avNeeds: b.avNeeds, buffet: b.buffet,
      organizer: b.organizer, notes: b.notes, staffName: b.staffName,
      paymentMethod: b.paymentMethod, checkIns: b.checkIns,
    );
    FacilityStore.updateBooking(b.id, copy);
    setState(() {});
    _feed('facility.status', verbMsg, b.id);
  }

  void _addBooking(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _BookingFormSheet(
        facilities: FacilityStore.availableFacilities,
        onSave: (b) {
          FacilityStore.addBooking(b);
          _feed('facility.booking',
              '${b.kind.label} for ${b.guestName} at ${b.facilityName}', b.id);
          if (mounted) setState(() {});
        },
      ),
    );
  }
}

/// Full booking / pass / membership form (events expand to hall fields).
class _BookingFormSheet extends StatefulWidget {
  final List<Facility> facilities;
  final void Function(FacilityBooking) onSave;
  const _BookingFormSheet({required this.facilities, required this.onSave});

  @override
  State<_BookingFormSheet> createState() => _BookingFormSheetState();
}

class _BookingFormSheetState extends State<_BookingFormSheet> {
  late Facility _facility;
  var _kind = BookingKind.dayPass;
  final _guestCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _qtyCtl = TextEditingController(text: '1');
  final _amountCtl = TextEditingController();
  final _paidCtl = TextEditingController();
  final _eventTypeCtl = TextEditingController();
  final _organizerCtl = TextEditingController();
  final _avCtl = TextEditingController();
  final _buffetCtl = TextEditingController();
  final _notesCtl = TextEditingController();
  final _guestCountCtl = TextEditingController();
  var _paymentMethod = 'Cash';
  var _status = BookingStatus.requested;
  DateTime _date = DateTime.now();
  DateTime _endDate = DateTime.now();
  double _depositPct = 0;

  @override
  void initState() {
    super.initState();
    _facility = widget.facilities.isNotEmpty ? widget.facilities.first : _dummyFacility();
    _date = DateTime.now();
    _endDate = DateTime.now();
  }

  Facility _dummyFacility() => Facility(
      id: 'fac_0', name: 'Facility', type: FacilityType.gym, rate: 0);

  void _onFacility(Facility f) {
    setState(() {
      _facility = f;
      _depositPct = f.depositPercent;
      if (_kind == BookingKind.event && _amountCtl.text.isEmpty && f.rate > 0) {
        _amountCtl.text = f.rate.toStringAsFixed(0);
      }
      if (_amountCtl.text.isEmpty && f.rate > 0 && _kind != BookingKind.event) {
        _amountCtl.text = f.rate.toStringAsFixed(0);
      }
    });
  }

  void _onKind(BookingKind k) {
    setState(() {
      _kind = k;
      if (_kind == BookingKind.membership) {
        _endDate = _date.add(const Duration(days: 30));
      } else {
        _endDate = _date;
      }
      if (_amountCtl.text.isEmpty && _facility.rate > 0) {
        _amountCtl.text = _facility.rate.toStringAsFixed(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEvent = _kind == BookingKind.event;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('New Booking / Pass / Event',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            DropdownButtonFormField<Facility>(
              key: ValueKey('bk-facility-${_facility.id}'),
              initialValue: _facility,
              decoration: const InputDecoration(
                  labelText: 'Facility', border: OutlineInputBorder()),
              items: widget.facilities
                  .map((f) => DropdownMenuItem(
                      value: f,
                      child: Text('${f.name} (${f.type.shortLabel})',
                          overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) {
                if (v != null) _onFacility(v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BookingKind>(
              key: ValueKey('bk-kind-$_kind'),
              initialValue: _kind,
              decoration: const InputDecoration(
                  labelText: 'Booking Type', border: OutlineInputBorder()),
              items: BookingKind.values
                  .map((k) =>
                      DropdownMenuItem(value: k, child: Text(k.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) _onKind(v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _guestCtl,
                decoration: const InputDecoration(
                    labelText: 'Guest / Client Name',
                    border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _phoneCtl,
                decoration: const InputDecoration(
                    labelText: 'WhatsApp Phone (for pass/receipt)',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                    controller: _qtyCtl,
                    decoration: const InputDecoration(
                        labelText: 'Qty', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                    controller: _amountCtl,
                    decoration: const InputDecoration(
                        labelText: 'Amount (₦)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(context, true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Date', border: OutlineInputBorder()),
                    child: Text(_fmtDate(_date)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: isEvent || _kind == BookingKind.membership
                      ? () => _pickDate(context, false)
                      : null,
                  child: InputDecorator(
                    decoration: InputDecoration(
                        labelText: isEvent
                            ? 'End date'
                            : _kind == BookingKind.membership
                                ? 'Expiry'
                                : 'Date',
                        border: const OutlineInputBorder()),
                    child: Text(_fmtDate(_endDate)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('bk-pay-$_paymentMethod'),
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(
                      labelText: 'Payment', border: OutlineInputBorder()),
                  items: ['Cash', 'Transfer', 'POS', 'Card']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _paymentMethod = v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                    controller: _paidCtl,
                    decoration: const InputDecoration(
                        labelText: 'Paid (₦)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number),
              ),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<BookingStatus>(
              key: ValueKey('bk-status-$_status'),
              initialValue: _status,
              decoration: const InputDecoration(
                  labelText: 'Status', border: OutlineInputBorder()),
              items: BookingStatus.values
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
            if (isEvent) ...[
              const SizedBox(height: 12),
              TextField(
                  controller: _eventTypeCtl,
                  decoration: const InputDecoration(
                      labelText: 'Event type (Wedding / Owambe / AGM / Party)',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: _organizerCtl,
                  decoration: const InputDecoration(
                      labelText: 'Organizer / Contact',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: _guestCountCtl,
                  decoration: const InputDecoration(
                      labelText: 'Expected guests',
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(
                  controller: _avCtl,
                  decoration: const InputDecoration(
                      labelText: 'AV / equipment needs',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: _buffetCtl,
                  decoration: const InputDecoration(
                      labelText: 'Buffet / catering',
                      border: OutlineInputBorder())),
              if (_depositPct > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Deposit schedule: ${_depositPct.toStringAsFixed(0)}% / ${(100 - _depositPct).toStringAsFixed(0)}% '
                    '(${_naira(_amount * _depositPct / 100)} due up-front)',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            TextField(
                controller: _notesCtl,
                decoration: const InputDecoration(
                    labelText: 'Notes', border: OutlineInputBorder()),
                maxLines: 2),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  if (_guestCtl.text.isEmpty) return;
                  final amount = double.tryParse(_amountCtl.text) ?? 0;
                  final paid = double.tryParse(_paidCtl.text) ?? 0;
                  widget.onSave(FacilityBooking(
                    id: 'bk_${DateTime.now().millisecondsSinceEpoch}',
                    facilityId: _facility.id,
                    facilityName: _facility.name,
                    kind: _kind,
                    status: _status,
                    guestName: _guestCtl.text,
                    phone: _phoneCtl.text.trim(),
                    date: _date,
                    endDate: _endDate,
                    qty: int.tryParse(_qtyCtl.text) ?? 1,
                    amount: amount,
                    paidAmount: paid,
                    depositPercent: isEvent ? _depositPct : 0,
                    eventType: _eventTypeCtl.text,
                    guestCount: int.tryParse(_guestCountCtl.text) ?? 0,
                    avNeeds: _avCtl.text,
                    buffet: _buffetCtl.text,
                    organizer: _organizerCtl.text,
                    notes: _notesCtl.text,
                    staffName: RoleStore.current.userName.isEmpty
                        ? 'Staff'
                        : RoleStore.current.userName,
                    paymentMethod: _paymentMethod,
                  ));
                  Navigator.pop(context);
                },
                child: const Text('Save Booking'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  double get _amount => double.tryParse(_amountCtl.text) ?? 0;

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final initial = isStart ? _date : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(nowYear - 1),
      lastDate: DateTime(nowYear + 3),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _date = picked;
          if (_endDate.isBefore(picked)) _endDate = picked;
          if (_kind == BookingKind.membership) {
            _endDate = picked.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  int get nowYear => DateTime.now().year;
}

// ───────────────────────────── GIFT SHOP TAB ─────────────────────────────

class _GiftShopTab extends StatefulWidget {
  const _GiftShopTab();
  @override
  State<_GiftShopTab> createState() => _GiftShopTabState();
}

class _GiftShopTabState extends State<_GiftShopTab> {
  final Map<String, int> _cart = {};
  bool get canPOS => RoleStore.hasAny(const [
        Permission.manageGiftShop,
        Permission.manageFacilities,
      ]);

  @override
  Widget build(BuildContext context) {
    final items = FacilityStore.giftItems;
    final cartTotal = items
        .where((g) => (_cart[g.id] ?? 0) > 0)
        .fold(0.0, (s, g) => s + (_cart[g.id] ?? 0) * g.price);
    final cartCount =
        _cart.values.fold(0, (s, v) => s + v);
    final lowStock = FacilityStore.lowStockItems.length;

    return ListView(padding: const EdgeInsets.all(12), children: [
      HomResponsiveGrid(children: [
        HomMetricCard(
            label: 'Items',
            value: '${items.length}',
            color: _primary,
            icon: Icons.inventory_2_rounded),
        HomMetricCard(
            label: 'Low stock',
            value: '$lowStock',
            color: AppColors.red,
            icon: Icons.warning_amber_rounded),
        HomMetricCard(
            label: 'Cart',
            value: _naira(cartTotal),
            color: AppColors.orange,
            icon: Icons.shopping_cart_rounded,
            sub: '$cartCount items'),
      ]),
      const SizedBox(height: 12),
      HomSectionTitle(
        title: 'Gift Shop POS',
        trailing: canPOS
            ? TextButton.icon(
                onPressed: () => _addGiftItem(context, null),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Item'))
            : null,
      ),
      const SizedBox(height: 8),
      ...items.map((g) {
        final qty = _cart[g.id] ?? 0;
        final disabled = !g.available || g.stock == 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(g.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 13),
                                overflow: TextOverflow.ellipsis)),
                        if (g.lowStock)
                          const Text('  LOW',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.red)),
                      ]),
                      Text(
                        '₦${g.price.toStringAsFixed(0)}  ·  stock ${g.stock}',
                        style: TextStyle(
                            fontSize: 11,
                            color: disabled ? AppColors.grey500 : AppColors.grey700),
                      ),
                    ]),
              ),
              if (canPOS)
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    onPressed: qty <= 0
                        ? null
                        : () => setState(() {
                              _cart[g.id] = qty - 1;
                              if (_cart[g.id] == 0) _cart.remove(g.id);
                            }),
                  ),
                  Text('$qty',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    onPressed: disabled || qty >= g.stock
                        ? null
                        : () => setState(() => _cart[g.id] = qty + 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    color: AppColors.grey600,
                    onPressed: () => _addGiftItem(context, g),
                  ),
                ])
              else
                Text('stock ${g.stock}',
                    style: TextStyle(fontSize: 11, color: AppColors.grey600)),
            ]),
          ),
        );
      }),
      const SizedBox(height: 8),
      if (canPOS && cartCount > 0)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () => _checkout(context, items, cartTotal, cartCount),
            icon: const Icon(Icons.point_of_sale_rounded),
            label: Text('Checkout — ${_naira(cartTotal)}'),
          ),
        ),
    ]);
  }

  void _checkout(BuildContext context, List<GiftItem> items, double total, int count) {
    final cashierCtl = TextEditingController(
        text: RoleStore.current.userName.isEmpty
            ? 'Staff'
            : RoleStore.current.userName);
    final customerCtl = TextEditingController();
    final noteCtl = TextEditingController();
    var method = 'Cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Checkout',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                for (final g in items.where((g) => (_cart[g.id] ?? 0) > 0))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      Expanded(
                          child: Text('${g.name} × ${_cart[g.id]}',
                              style: const TextStyle(fontSize: 12))),
                      Text(_naira((_cart[g.id] ?? 0) * g.price),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                    ]),
                  ),
                const Divider(height: 16),
                Row(children: [
                  Expanded(
                      child: Text('Total',
                          style: const TextStyle(fontWeight: FontWeight.w800))),
                  Text(_naira(total),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16)),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('chk-method-$method'),
                  initialValue: method,
                  decoration: const InputDecoration(
                      labelText: 'Payment', border: OutlineInputBorder()),
                  items: ['Cash', 'Transfer', 'POS', 'Card']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheetState(() => method = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: customerCtl,
                    decoration: const InputDecoration(
                        labelText: 'Customer (optional)',
                        border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: cashierCtl,
                    decoration: const InputDecoration(
                        labelText: 'Cashier', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: noteCtl,
                    decoration: const InputDecoration(
                        labelText: 'Note', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      final sale = FacilitySale(
                        id: 'sale_${DateTime.now().millisecondsSinceEpoch}',
                        date: DateTime.now(),
                        items: items
                            .where((g) => (_cart[g.id] ?? 0) > 0)
                            .map((g) => SaleLine(
                                  itemId: g.id,
                                  name: g.name,
                                  qty: _cart[g.id] ?? 0,
                                  unitPrice: g.price,
                                ))
                            .toList(),
                        cashier: cashierCtl.text,
                        customerName: customerCtl.text,
                        paymentMethod: method,
                        note: noteCtl.text,
                      );
                      FacilityStore.recordSale(sale);
                      _feed('facility.sale',
                          'Gift shop sale ${_naira(sale.total)} (${sale.unitCount} items) by ${sale.cashier}',
                          sale.id);
                      Navigator.pop(ctx);
                      if (mounted) {
                        _cart.clear();
                        setState(() {});
                      }
                    },
                    child: Text('Complete Sale — ${_naira(total)}'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _addGiftItem(BuildContext context, GiftItem? existing) {
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final skuCtl = TextEditingController(text: existing?.sku ?? '');
    final catCtl = TextEditingController(text: existing?.category ?? 'General');
    final priceCtl = TextEditingController(
        text: existing != null ? existing.price.toStringAsFixed(0) : '');
    final stockCtl = TextEditingController(
        text: existing != null ? existing.stock.toString() : '');
    final lowCtl = TextEditingController(
        text: existing != null ? existing.low.toString() : '');
    var available = existing?.available ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(existing == null ? 'Add Gift Item' : 'Edit Gift Item',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(
                        labelText: 'Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                        controller: skuCtl,
                        decoration: const InputDecoration(
                            labelText: 'SKU / barcode',
                            border: OutlineInputBorder())),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                        controller: catCtl,
                        decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder())),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                        controller: priceCtl,
                        decoration: const InputDecoration(
                            labelText: 'Price (₦)',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                        controller: stockCtl,
                        decoration: const InputDecoration(
                            labelText: 'Stock', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number),
                  ),
                ]),
                const SizedBox(height: 12),
                TextField(
                    controller: lowCtl,
                    decoration: const InputDecoration(
                        labelText: 'Low-stock alert at',
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number),
                SwitchListTile(
                    value: available,
                    onChanged: (v) => setSheetState(() => available = v),
                    title: const Text('Available for sale'),
                    contentPadding: EdgeInsets.zero),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      if (nameCtl.text.isEmpty) return;
                      final g = GiftItem(
                        id: existing?.id ??
                            'gi_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtl.text,
                        sku: skuCtl.text,
                        category: catCtl.text,
                        price: double.tryParse(priceCtl.text) ?? 0,
                        stock: int.tryParse(stockCtl.text) ?? 0,
                        low: int.tryParse(lowCtl.text) ?? 0,
                        available: available,
                      );
                      if (existing != null) {
                        FacilityStore.updateGiftItem(existing.id, g);
                      } else {
                        FacilityStore.addGiftItem(g);
                      }
                      Navigator.pop(ctx);
                      if (mounted) setState(() {});
                    },
                    child: Text(existing == null ? 'Add Item' : 'Update Item'),
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

// ───────────────────────────── REVENUE TAB ─────────────────────────────

class _RevenueTab extends StatelessWidget {
  const _RevenueTab();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = FacilityStore.monthRevenue;
    final today = FacilityStore.revenueForDate(now);
    final bySource = FacilityStore.revenueBySource(now.year, now.month);
    final sourceOrder = ['Gym', 'Pool', 'Gift Shop', 'Events'];
    final rows = FacilityStore.revenues.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView(padding: const EdgeInsets.all(12), children: [
      HomResponsiveGrid(children: [
        HomMetricCard(
            label: 'This month',
            value: _naira(month),
            color: _primary,
            icon: Icons.trending_up_rounded),
        HomMetricCard(
            label: 'Today',
            value: _naira(today),
            color: AppColors.amber,
            icon: Icons.today_rounded),
        HomMetricCard(
            label: 'Roll-up target',
            value: 'Night Audit',
            color: AppColors.blue,
            icon: Icons.nightlight_round,
            sub: 'auto-posted by source'),
      ]),
      const SizedBox(height: 12),
      const HomSectionTitle(title: 'Revenue by Source'),
      const SizedBox(height: 8),
      for (final source in sourceOrder)
        if ((bySource[source] ?? 0) > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(source,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12)),
                const Spacer(),
                Text(_naira(bySource[source] ?? 0),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: month > 0 ? (bySource[source] ?? 0) / month : 0,
                  minHeight: 8,
                  backgroundColor: AppColors.grey200,
                  valueColor:
                      AlwaysStoppedAnimation(_sourceColor(source)),
                ),
              ),
            ]),
          ),
      const SizedBox(height: 8),
      const HomSectionTitle(title: 'Recent Postings'),
      const SizedBox(height: 8),
      if (rows.isEmpty)
        const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
              child: Text('No facility revenue yet — postings appear when '
                  'bookings are paid or gift sales are recorded.')),
        ),
      for (final r in rows.take(20))
        Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            dense: true,
            leading: Icon(Icons.payments_rounded,
                color: _sourceColor(r.source), size: 20),
            title: Text('${r.source} — ${_naira(r.amount)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: Text('${_fmtDate(r.date)}  ·  ${r.refId}',
                style: const TextStyle(fontSize: 10)),
          ),
        ),
    ]);
  }

  Color _sourceColor(String source) => switch (source) {
        'Gym' => AppColors.red400,
        'Pool' => AppColors.blue,
        'Gift Shop' => AppColors.orange,
        _ => AppColors.amber,
      };
}
