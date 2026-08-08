import 'persistence_service.dart';
import 'store_sync.dart';
import '../models/facility.dart';

/// Facility & Amenity Operations Engine — offline-first store.
///
/// Collections (flat, under hotels/{hotelId}/):
///   facilities        — gym / pool / gift shop / event halls
///   facility_bookings — day passes, memberships, event bookings (+ access log)
///   gift_items        — gift-shop retail inventory
///   facility_sales    — gift-shop POS transactions
///   facility_revenue  — daily revenue-by-source for the Night Audit roll-up
///
/// Revenue is posted idempotently (keyed by refId) the moment a booking is
/// recognized (deposit paid / fully paid) or a gift sale is recorded.
class FacilityStore {
  static final List<Facility> _facilities = [];
  static final List<FacilityBooking> _bookings = [];
  static final List<GiftItem> _giftItems = [];
  static final List<FacilitySale> _sales = [];
  static final List<FacilityRevenue> _revenues = [];

  static final StoreSync<Facility> facilitySync = _initFacilitySync();
  static final StoreSync<FacilityBooking> bookingSync = _initBookingSync();
  static final StoreSync<GiftItem> giftItemSync = _initGiftItemSync();
  static final StoreSync<FacilitySale> saleSync = _initSaleSync();
  static final StoreSync<FacilityRevenue> revenueSync = _initRevenueSync();

  static StoreSync<Facility> _initFacilitySync() {
    final s = StoreSync<Facility>(
      collection: 'facilities',
      target: _facilities,
      fromJson: Facility.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'facilities',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<FacilityBooking> _initBookingSync() {
    final s = StoreSync<FacilityBooking>(
      collection: 'facility_bookings',
      target: _bookings,
      fromJson: FacilityBooking.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'facility_bookings',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<GiftItem> _initGiftItemSync() {
    final s = StoreSync<GiftItem>(
      collection: 'gift_items',
      target: _giftItems,
      fromJson: GiftItem.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'gift_items',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<FacilitySale> _initSaleSync() {
    final s = StoreSync<FacilitySale>(
      collection: 'facility_sales',
      target: _sales,
      fromJson: FacilitySale.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'facility_sales',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<FacilityRevenue> _initRevenueSync() {
    final s = StoreSync<FacilityRevenue>(
      collection: 'facility_revenue',
      target: _revenues,
      fromJson: FacilityRevenue.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'facility_revenue',
    );
    CloudSync.register(s);
    return s;
  }

  // ===================== INIT =====================

  static Future<void> load() async {
    final f = PersistenceService.loadList('facilities', Facility.fromJson);
    if (f != null && f.isNotEmpty) { _facilities.addAll(f); } else { _seedFacilities(); }
    final b = PersistenceService.loadList('facility_bookings', FacilityBooking.fromJson);
    if (b != null && b.isNotEmpty) { _bookings.addAll(b); } else { _seedBookings(); }
    final g = PersistenceService.loadList('gift_items', GiftItem.fromJson);
    if (g != null && g.isNotEmpty) { _giftItems.addAll(g); } else { _seedGiftItems(); }
    final s = PersistenceService.loadList('facility_sales', FacilitySale.fromJson);
    if (s != null && s.isNotEmpty) { _sales.addAll(s); }
    final r = PersistenceService.loadList('facility_revenue', FacilityRevenue.fromJson);
    if (r != null && r.isNotEmpty) { _revenues.addAll(r); } else { _seedRevenue(); }
    facilitySync.loadMeta();
    bookingSync.loadMeta();
    giftItemSync.loadMeta();
    saleSync.loadMeta();
    revenueSync.loadMeta();
  }

  static Future<void> _save() async {
    await PersistenceService.saveList('facilities', _facilities, (e) => e.toJson());
    await PersistenceService.saveList('facility_bookings', _bookings, (e) => e.toJson());
    await PersistenceService.saveList('gift_items', _giftItems, (e) => e.toJson());
    await PersistenceService.saveList('facility_sales', _sales, (e) => e.toJson());
    await PersistenceService.saveList('facility_revenue', _revenues, (e) => e.toJson());
    await facilitySync.push();
    await bookingSync.push();
    await giftItemSync.push();
    await saleSync.push();
    await revenueSync.push();
  }

  // ===================== SEEDS =====================

  static void _seedFacilities() {
    _facilities.addAll([
      Facility(
        id: 'fac_gym', name: 'Fitness & Gym Center', type: FacilityType.gym,
        rate: 5000, capacity: 40, hours: '6:00 — 22:00',
        description: 'Cardio + strength suites, PT sessions, daily lockers.',
      ),
      Facility(
        id: 'fac_pool', name: 'Swimming Pool & Sun Deck', type: FacilityType.pool,
        rate: 3000, capacity: 30, hours: '7:00 — 21:00',
        description: 'Outdoor pool, cabanas and towel service for day visitors.',
      ),
      Facility(
        id: 'fac_shop', name: 'Gift Shop & Boutique', type: FacilityType.giftShop,
        rate: 0, capacity: 0, hours: '9:00 — 21:00',
        description: 'Branded merchandise, snacks, toiletries and souvenirs.',
      ),
      Facility(
        id: 'fac_owambe', name: 'Owambe Hall', type: FacilityType.eventHall,
        rate: 250000, capacity: 300, venue: 'Ground floor, east wing',
        depositPercent: 70, hours: 'By arrangement',
        description: 'Full-service banquet hall — weddings, owambe parties, AGMs.',
        equipment: ['Projector', '2 Wireless Mics', 'Dining Tables (30)', 'Chairs (300)'],
      ),
      Facility(
        id: 'fac_ivory', name: 'Ivory Banquet Room', type: FacilityType.eventHall,
        rate: 150000, capacity: 120, venue: 'First floor',
        depositPercent: 50, hours: 'By arrangement',
        description: 'Intimate function room for corporate events and receptions.',
        equipment: ['Projector', 'Screen', 'Dining Tables (12)', 'Chairs (120)'],
      ),
    ]);
  }

  static void _seedGiftItems() {
    _giftItems.addAll([
      GiftItem(id: 'gi_tshirt', name: 'HOM Branded T-Shirt', sku: 'MR-101', category: 'Apparel', price: 15000, stock: 24, low: 5),
      GiftItem(id: 'gi_cap', name: 'HOM Baseball Cap', sku: 'MR-102', category: 'Apparel', price: 9000, stock: 30, low: 5),
      GiftItem(id: 'gi_bottle', name: 'Steel Water Bottle', sku: 'SR-201', category: 'Souvenirs', price: 12000, stock: 40, low: 8),
      GiftItem(id: 'gi_keychain', name: 'Souvenir Keychain', sku: 'SR-202', category: 'Souvenirs', price: 3500, stock: 60, low: 10),
      GiftItem(id: 'gi_nuts', name: 'Spiced Nut Mix (200g)', sku: 'FD-301', category: 'Snacks', price: 4500, stock: 50, low: 10),
      GiftItem(id: 'gi_chips', name: 'Plantain Chips', sku: 'FD-302', category: 'Snacks', price: 2000, stock: 45, low: 10),
      GiftItem(id: 'gi_lotion', name: 'Shea Body Lotion', sku: 'TO-401', category: 'Toiletries', price: 8000, stock: 18, low: 5),
      GiftItem(id: 'gi_shampoo', name: 'Travel Shampoo', sku: 'TO-402', category: 'Toiletries', price: 4000, stock: 12, low: 4),
    ]);
  }

  static void _seedBookings() {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final gym = _facilities.firstWhere((f) => f.type == FacilityType.gym);
    final pool = _facilities.firstWhere((f) => f.type == FacilityType.pool);
    final owambe = _facilities.firstWhere((f) => f.id == 'fac_owambe');

    _bookings.addAll([
      FacilityBooking(
        id: 'bk_gym_pass', facilityId: gym.id, facilityName: gym.name,
        kind: BookingKind.dayPass, status: BookingStatus.paid,
        guestName: 'Dayo Adeyemi', phone: '2348031112233',
        date: day, amount: gym.rate, paidAmount: gym.rate, qty: 2,
        paymentMethod: 'POS', staffName: 'Gift Shop / Wellness',
        checkIns: [DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()],
      ),
      FacilityBooking(
        id: 'bk_pool_pass', facilityId: pool.id, facilityName: pool.name,
        kind: BookingKind.dayPass, status: BookingStatus.confirmed,
        guestName: 'Ngozi Eze', phone: '2348025556677',
        date: day, amount: pool.rate, paidAmount: 0,
        paymentMethod: 'Cash', staffName: 'Wellness',
      ),
      FacilityBooking(
        id: 'bk_gym_member', facilityId: gym.id, facilityName: gym.name,
        kind: BookingKind.membership, status: BookingStatus.paid,
        guestName: 'Musa Ibrahim', phone: '2348057778899',
        date: day, endDate: DateTime(now.year, now.month, now.day).add(const Duration(days: 30)),
        amount: 50000, paidAmount: 50000, paymentMethod: 'Transfer', staffName: 'Wellness',
      ),
      FacilityBooking(
        id: 'bk_owambe', facilityId: owambe.id, facilityName: owambe.name,
        kind: BookingKind.event, status: BookingStatus.depositPaid,
        guestName: 'Adesuwa & Tunde', phone: '2348069990001',
        date: day.add(const Duration(days: 14)),
        endDate: day.add(const Duration(days: 14)),
        amount: 250000, paidAmount: 175000, depositPercent: 70,
        eventType: 'Wedding / Owambe', guestCount: 250,
        avNeeds: 'Projector + 2 mics', buffet: '3-course + small chops', organizer: 'Adesuwa',
        paymentMethod: 'Transfer', staffName: 'Banqueting',
      ),
      FacilityBooking(
        id: 'bk_agm', facilityId: 'fac_ivory', facilityName: 'Ivory Banquet Room',
        kind: BookingKind.event, status: BookingStatus.requested,
        guestName: 'Zenith Manufacturing Ltd', phone: '2348091234567',
        date: day.add(const Duration(days: 21)),
        endDate: day.add(const Duration(days: 21)),
        amount: 150000, paidAmount: 0, depositPercent: 50,
        eventType: 'AGM', guestCount: 100, avNeeds: 'Projector + sound',
        buffet: 'Coffee break + lunch', organizer: 'Mrs. Okonkwo',
        paymentMethod: 'Transfer', staffName: 'Banqueting',
      ),
    ]);
  }

  static void _seedRevenue() {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    _revenues.addAll([
      FacilityRevenue(id: 'frev_gym_pass', date: day, source: 'Gym', amount: 10000, refId: 'bk_gym_pass'),
      FacilityRevenue(id: 'frev_gym_member', date: day, source: 'Gym', amount: 50000, refId: 'bk_gym_member'),
      FacilityRevenue(id: 'frev_owambe', date: day, source: 'Events', amount: 175000, refId: 'bk_owambe'),
    ]);
  }

  // ===================== ID GENS =====================

  static String genFacilityId() => 'fac_${DateTime.now().millisecondsSinceEpoch}';
  static String genBookingId() => 'bk_${DateTime.now().millisecondsSinceEpoch}';
  static String genGiftItemId() => 'gi_${DateTime.now().millisecondsSinceEpoch}';
  static String genSaleId() => 'sale_${DateTime.now().millisecondsSinceEpoch}';
  static String genRevenueId() => 'frev_${DateTime.now().millisecondsSinceEpoch}';

  // ===================== FACILITIES =====================

  static List<Facility> get facilities => List.unmodifiable(_facilities);
  static List<Facility> facilitiesByType(FacilityType type) =>
      _facilities.where((f) => f.type == type).toList();
  static List<Facility> get availableFacilities =>
      _facilities.where((f) => f.isAvailable).toList();
  static Facility? facilityById(String id) {
    try { return _facilities.firstWhere((f) => f.id == id); } catch (_) { return null; }
  }
  static String facilityName(String id) => facilityById(id)?.name ?? 'Facility';

  static Future<void> addFacility(Facility f) async { _facilities.add(f); await _save(); }
  static Future<void> updateFacility(String id, Facility updated) async {
    final i = _facilities.indexWhere((f) => f.id == id);
    if (i >= 0) { _facilities[i] = updated; await _save(); }
  }
  static Future<void> removeFacility(String id) async {
    _facilities.removeWhere((f) => f.id == id); await _save();
  }

  // ===================== BOOKINGS / PASSES / EVENTS =====================

  static List<FacilityBooking> get bookings => List.unmodifiable(_bookings);
  static List<FacilityBooking> bookingsForFacility(String facilityId) =>
      _bookings.where((b) => b.facilityId == facilityId).toList();
  static List<FacilityBooking> bookingsForKind(BookingKind kind) =>
      _bookings.where((b) => b.kind == kind).toList();
  static List<FacilityBooking> activeMemberships() =>
      _bookings.where((b) =>
          b.kind == BookingKind.membership && b.status != BookingStatus.cancelled &&
          b.endDate.isAfter(DateTime.now())).toList();
  static List<FacilityBooking> activeDayPasses() =>
      _bookings.where((b) =>
          b.kind == BookingKind.dayPass && b.status == BookingStatus.paid &&
          b.date.year == DateTime.now().year &&
          b.date.month == DateTime.now().month &&
          b.date.day == DateTime.now().day).toList();

  /// Access log — today's scans across paid passes / memberships.
  static List<String> get todaysCheckIns {
    final now = DateTime.now();
    final out = <String>[];
    for (final b in _bookings) {
      if (b.status == BookingStatus.cancelled) continue;
      for (final ts in b.checkIns) {
        final t = DateTime.tryParse(ts);
        if (t != null && t.year == now.year && t.month == now.month && t.day == now.day) {
          out.add(ts);
        }
      }
    }
    return out;
  }

  static Future<void> addBooking(FacilityBooking b) async {
    _bookings.insert(0, b);
    await syncBookingRevenue(b);
    await _save();
  }

  static Future<void> updateBooking(String id, FacilityBooking updated) async {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i >= 0) { _bookings[i] = updated; await syncBookingRevenue(updated); await _save(); }
  }

  /// Check-in a guest (appends to the booking's access log).
  static Future<void> checkInBooking(String id) async {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i < 0) return;
    final b = _bookings[i];
    final copy = FacilityBooking(
      id: b.id, facilityId: b.facilityId, facilityName: b.facilityName,
      kind: b.kind, status: b.status, guestName: b.guestName, phone: b.phone,
      date: b.date, endDate: b.endDate, qty: b.qty, amount: b.amount,
      paidAmount: b.paidAmount, depositPercent: b.depositPercent,
      eventType: b.eventType, guestCount: b.guestCount, avNeeds: b.avNeeds,
      buffet: b.buffet, organizer: b.organizer, notes: b.notes,
      staffName: b.staffName, paymentMethod: b.paymentMethod,
      checkIns: [...b.checkIns, DateTime.now().toIso8601String()],
    );
    _bookings[i] = copy;
    await _save();
  }

  static Future<void> removeBooking(String id) async {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i >= 0) {
      _revenues.removeWhere((r) => r.refId == _bookings[i].id);
      _bookings.removeAt(i);
    }
    await _save();
  }

  /// Idempotent Night Audit roll-up: a recognized booking (deposit paid or
  /// fully paid) owns exactly one facility_revenue row, keyed by refId.
  static Future<void> syncBookingRevenue(FacilityBooking b) async {
    _revenues.removeWhere((r) => r.refId == b.id);
    if (b.status.recognized && b.amount > 0) {
      final source = facilityById(b.facilityId)?.type.shortLabel ?? b.facilityName;
      final recognized = b.status == BookingStatus.depositPaid
          ? b.paidAmount.clamp(0.0, b.amount)
          : b.amount;
      if (recognized > 0) {
        _revenues.add(FacilityRevenue(
          date: b.date, source: source, amount: recognized, refId: b.id,
        ));
      }
    }
  }

  // ===================== GIFT ITEMS =====================

  static List<GiftItem> get giftItems => List.unmodifiable(_giftItems);
  static List<GiftItem> get lowStockItems =>
      _giftItems.where((g) => g.lowStock).toList();

  static Future<void> addGiftItem(GiftItem g) async { _giftItems.add(g); await _save(); }
  static Future<void> updateGiftItem(String id, GiftItem updated) async {
    final i = _giftItems.indexWhere((g) => g.id == id);
    if (i >= 0) { _giftItems[i] = updated; await _save(); }
  }
  static Future<void> removeGiftItem(String id) async {
    _giftItems.removeWhere((g) => g.id == id); await _save();
  }

  // ===================== GIFT SHOP SALES =====================

  static List<FacilitySale> get sales => List.unmodifiable(_sales);
  static List<FacilitySale> salesForMonth(int year, int month) =>
      _sales.where((s) => s.date.year == year && s.date.month == month).toList();

  static Future<FacilitySale> recordSale(FacilitySale sale) async {
    for (final line in sale.items) {
      final i = _giftItems.indexWhere((g) => g.id == line.itemId);
      if (i >= 0) {
        _giftItems[i] = GiftItem(
          id: _giftItems[i].id, name: _giftItems[i].name, sku: _giftItems[i].sku,
          category: _giftItems[i].category, price: _giftItems[i].price,
          stock: (_giftItems[i].stock - line.qty).clamp(0, 1 << 31),
          low: _giftItems[i].low, available: _giftItems[i].available,
        );
      }
    }
    _sales.insert(0, sale);
    _revenues.removeWhere((r) => r.refId == sale.id);
    if (sale.total > 0) {
      _revenues.add(FacilityRevenue(
        date: sale.date, source: FacilityType.giftShop.shortLabel,
        amount: sale.total, refId: sale.id,
      ));
    }
    await _save();
    return sale;
  }

  static Future<void> removeSale(String id) async {
    _revenues.removeWhere((r) => r.refId == id);
    _sales.removeWhere((s) => s.id == id);
    await _save();
  }

  // ===================== REVENUE ROLL-UP =====================

  static List<FacilityRevenue> get revenues => List.unmodifiable(_revenues);

  static double get monthRevenue {
    final now = DateTime.now();
    return _revenues
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .fold(0.0, (s, r) => s + r.amount);
  }

  static double revenueForDate(DateTime d) => _revenues
      .where((r) => r.date.year == d.year && r.date.month == d.month && r.date.day == d.day)
      .fold(0.0, (s, r) => s + r.amount);

  /// Facility revenue for [month] grouped by source (Gym / Pool / Gift Shop / Events).
  static Map<String, double> revenueBySource(int year, int month) {
    final map = <String, double>{};
    for (final r in _revenues) {
      if (r.date.year == year && r.date.month == month) {
        map[r.source] = (map[r.source] ?? 0) + r.amount;
      }
    }
    return map;
  }
}
