import 'persistence_service.dart';
import 'store_sync.dart';
import '../models/operations.dart';

class OperationsStore {
  static const int totalRooms = 12;
  static final List<DailyRevenue> _revenues = [];
  static final List<CashDrop> _cashDrops = [];
  static final List<HousekeepingLoss> _losses = [];
  static int _lossCounter = 0;

  // Offline-first cloud sync for each operations collection.
  static final StoreSync<DailyRevenue> revenueSync = _initRevenueSync();
  static final StoreSync<CashDrop> cashDropSync = _initCashDropSync();
  static final StoreSync<HousekeepingLoss> lossSync = _initLossSync();

  static StoreSync<DailyRevenue> _initRevenueSync() {
    final s = StoreSync<DailyRevenue>(
      collection: 'ops_revenues',
      target: _revenues,
      fromJson: DailyRevenue.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'ops_revenues',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<CashDrop> _initCashDropSync() {
    final s = StoreSync<CashDrop>(
      collection: 'ops_cash_drops',
      target: _cashDrops,
      fromJson: CashDrop.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'ops_cash_drops',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<HousekeepingLoss> _initLossSync() {
    final s = StoreSync<HousekeepingLoss>(
      collection: 'ops_losses',
      target: _losses,
      fromJson: HousekeepingLoss.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'ops_losses',
    );
    CloudSync.register(s);
    return s;
  }

  static Future<void> init() async {
    if (_revenues.isNotEmpty) return;
    final r = PersistenceService.loadList('ops_revenues', DailyRevenue.fromJson);
    if (r != null && r.isNotEmpty) { _revenues.addAll(r); } else { _seedRevenues(); }
    final c = PersistenceService.loadList('ops_cash_drops', CashDrop.fromJson);
    if (c != null && c.isNotEmpty) { _cashDrops.addAll(c); } else { _seedCashDrops(); }
    final l = PersistenceService.loadList('ops_losses', HousekeepingLoss.fromJson);
    if (l != null && l.isNotEmpty) { _losses.addAll(l); } else { _seedLosses(); }
    revenueSync.loadMeta();
    cashDropSync.loadMeta();
    lossSync.loadMeta();
  }

  static void _seedRevenues() {
    final now = DateTime.now();
    final rng = _SeededRandom(42);
    for (var i = 29; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final weekend = d.weekday == 6 || d.weekday == 7;
      final baseSold = weekend ? rng.nextInt(5) + 8 : rng.nextInt(4) + 5;
      final sold = baseSold.clamp(0, 12);
      final walkIns = weekend ? rng.nextInt(3) : (rng.nextDouble() > 0.7 ? rng.nextInt(2) : 0);
      final rev = sold * (weekend ? (rng.nextInt(5000) + 25000) : (rng.nextInt(4000) + 18000));
      _revenues.add(DailyRevenue(
        id: 'rev_${d.toIso8601String().substring(0, 10)}',
        date: d, roomsSold: sold, walkIns: walkIns,
        totalRevenue: rev.toDouble(),
      ));
    }
  }

  static void _seedCashDrops() {
    final now = DateTime.now();
    final rng = _SeededRandom(42);
    for (var i = 13; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final exp = (rng.nextInt(20000) + 60000).toDouble();
      final act = rng.nextDouble() > 0.2 ? exp : exp + rng.nextInt(5000) - 2500;
      _cashDrops.add(CashDrop(
        id: 'cd_$i', date: d,
        shift: i % 3 == 0 ? 'Morning' : i % 3 == 1 ? 'Evening' : 'Night',
        expectedAmount: exp, actualAmount: act,
        status: act == exp ? CashDropStatus.matched : CashDropStatus.mismatched,
        notes: act != exp ? 'Variance of ₦${(act - exp).abs().toStringAsFixed(0)}' : '',
      ));
    }
  }

  static void _seedLosses() {
    final now = DateTime.now();
    final rng = _SeededRandom(42);
    final items = [
      ('Bath Towel', 'Linen', 3500), ('Face Towel', 'Linen', 1800),
      ('Bedsheet (King)', 'Linen', 8500), ('Pillowcase', 'Linen', 1200),
      ('Bathrobe', 'Linen', 12000), ('Slippers (pair)', 'Amenity', 800),
      ('Soap (bar)', 'Amenity', 350), ('Shampoo (bottle)', 'Amenity', 600),
      ('Lotion (bottle)', 'Amenity', 750), ('Tea/Coffee sachet', 'Amenity', 200),
      ('Water bottle', 'Amenity', 300), ('Wine glass', 'Furniture', 1500),
      ('Remote control', 'Furniture', 2500), ('Light bulb', 'Maintenance', 800),
    ];
    for (var i = 19; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: rng.nextInt(30)));
      final (item, cat, cost) = items[rng.nextInt(items.length)];
      final qty = rng.nextInt(4) + 1;
      _lossCounter++;
      _losses.add(HousekeepingLoss(
        id: 'loss_$_lossCounter', date: d, item: item, category: cat,
        quantity: qty, unitCost: cost.toDouble(),
        roomNumber: '${101 + rng.nextInt(12)}',
      ));
    }
  }

  static Future<void> _save() async {
    await PersistenceService.saveList('ops_revenues', _revenues, (e) => e.toJson());
    await PersistenceService.saveList('ops_cash_drops', _cashDrops, (e) => e.toJson());
    await PersistenceService.saveList('ops_losses', _losses, (e) => e.toJson());
    await revenueSync.push();
    await cashDropSync.push();
    await lossSync.push();
  }

  static String genId() => 'ops_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';

  static List<DailyRevenue> get revenues => List.unmodifiable(_revenues);
  static List<CashDrop> get cashDrops => List.unmodifiable(_cashDrops);
  static List<HousekeepingLoss> get losses => List.unmodifiable(_losses);

  // ===================== DAILY REVENUE CRUD =====================

  static Future<void> addRevenue(DailyRevenue r) async { _revenues.add(r); await _save(); }

  static Future<void> updateRevenue(int index, DailyRevenue updated) async {
    if (index >= 0 && index < _revenues.length) { _revenues[index] = updated; await _save(); }
  }

  static Future<void> removeRevenue(int index) async {
    if (index >= 0 && index < _revenues.length) { _revenues.removeAt(index); await _save(); }
  }

  // ===================== CASH DROP CRUD =====================

  static Future<void> addCashDrop(CashDrop c) async { _cashDrops.insert(0, c); await _save(); }

  static Future<void> updateCashDrop(String id, CashDrop updated) async {
    final i = _cashDrops.indexWhere((c) => c.id == id);
    if (i >= 0) { _cashDrops[i] = updated; await _save(); }
  }

  static Future<void> removeCashDrop(String id) async { _cashDrops.removeWhere((c) => c.id == id); await _save(); }

  // ===================== HOUSEKEEPING LOSS CRUD =====================

  static Future<void> addLoss(HousekeepingLoss l) async { _losses.insert(0, l); _lossCounter++; await _save(); }

  static Future<void> updateLoss(String id, HousekeepingLoss updated) async {
    final i = _losses.indexWhere((l) => l.id == id);
    if (i >= 0) { _losses[i] = updated; await _save(); }
  }

  static Future<void> removeLoss(String id) async { _losses.removeWhere((l) => l.id == id); await _save(); }

  static List<DailyRevenue> revenuesForMonth(int year, int month) =>
      _revenues.where((r) => r.date.year == year && r.date.month == month).toList();

  static DailyRevenue? get todayRevenue {
    final now = DateTime.now();
    try { return _revenues.firstWhere((r) =>
        r.date.year == now.year && r.date.month == now.month && r.date.day == now.day);
    } catch (_) { return null; }
  }

  static List<CashDrop> get todayCashDrops {
    final now = DateTime.now();
    return _cashDrops.where((c) =>
        c.date.year == now.year && c.date.month == now.month && c.date.day == now.day).toList();
  }

  static List<CashDrop> cashDropsForPeriod(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _cashDrops.where((c) => c.date.isAfter(cutoff)).toList();
  }

  static double get totalDiscrepancy =>
      _cashDrops.fold(0.0, (s, c) => s + c.difference);

  static List<HousekeepingLoss> get lossesThisMonth {
    final now = DateTime.now();
    return _losses.where((l) =>
        l.date.year == now.year && l.date.month == now.month).toList();
  }

  static Map<String, double> lossesByCategory() {
    final map = <String, double>{};
    for (final l in _losses) {
      map[l.category] = (map[l.category] ?? 0) + l.totalCost;
    }
    return map;
  }

  static Map<String, int> topLostItems({int limit = 5}) {
    final map = <String, int>{};
    for (final l in _losses) {
      map[l.item] = (map[l.item] ?? 0) + l.quantity;
    }
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted.take(limit)) e.key: e.value};
  }

  static double get totalLossCost => _losses.fold(0.0, (s, l) => s + l.totalCost);
  static double get totalLossCostThisMonth =>
      lossesThisMonth.fold(0.0, (s, l) => s + l.totalCost);

  static double get monthRevenue {
    final now = DateTime.now();
    return _revenues
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .fold(0.0, (s, r) => s + r.totalRevenue);
  }

  static double get monthAvgOccupancy {
    final now = DateTime.now();
    final days = _revenues.where((r) => r.date.year == now.year && r.date.month == now.month).toList();
    if (days.isEmpty) return 0;
    return days.fold(0.0, (s, r) => s + r.occupancyPct) / days.length;
  }

  static double get monthAvgAdr {
    final now = DateTime.now();
    final days = _revenues.where((r) => r.date.year == now.year && r.date.month == now.month).toList();
    if (days.isEmpty) return 0;
    final totalSold = days.fold(0, (s, r) => s + r.roomsSold);
    final totalRev = days.fold(0.0, (s, r) => s + r.totalRevenue);
    return totalSold > 0 ? totalRev / totalSold : 0;
  }

  static double get monthAvgRevpar {
    final now = DateTime.now();
    final days = _revenues.where((r) => r.date.year == now.year && r.date.month == now.month).toList();
    if (days.isEmpty) return 0;
    final totalRev = days.fold(0.0, (s, r) => s + r.totalRevenue);
    return totalRev / (days.length * 12);
  }
}

class _SeededRandom {
  int _seed;
  _SeededRandom(this._seed);

  double nextDouble() {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed / 0x7fffffff;
  }

  int nextInt(int max) => (nextDouble() * max).floor();
}
