import 'persistence_service.dart';
import 'store_sync.dart';
import '../models/housekeeping.dart';

class HousekeepingStore {
  static final List<HousekeepingTask> _tasks = [];
  static final List<LaundryItem> _laundry = [];
  static final List<LostFoundItem> _lostFound = [];
  static final List<LinenDamage> _linenDamages = [];

  // Offline-first cloud sync. Laundry and linen enums are now unified across
  // platforms (LaundryType washIron; LinenCategory mattressProtector/bathrobe/
  // other; LinenCondition new/good/damaged) with tolerant `safeEnum` parsing,
  // so every housekeeping collection syncs.
  static final StoreSync<HousekeepingTask> taskSync = _initTaskSync();
  static final StoreSync<LaundryItem> laundrySync = _initLaundrySync();
  static final StoreSync<LostFoundItem> lostFoundSync = _initLostFoundSync();
  static final StoreSync<LinenDamage> linenSync = _initLinenSync();

  static StoreSync<HousekeepingTask> _initTaskSync() {
    final s = StoreSync<HousekeepingTask>(
      collection: 'hk_tasks',
      target: _tasks,
      fromJson: HousekeepingTask.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'hk_tasks',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<LaundryItem> _initLaundrySync() {
    final s = StoreSync<LaundryItem>(
      collection: 'hk_laundry',
      target: _laundry,
      fromJson: LaundryItem.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'hk_laundry',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<LostFoundItem> _initLostFoundSync() {
    final s = StoreSync<LostFoundItem>(
      collection: 'hk_lost_found',
      target: _lostFound,
      fromJson: LostFoundItem.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'hk_lost_found',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<LinenDamage> _initLinenSync() {
    final s = StoreSync<LinenDamage>(
      collection: 'hk_linen',
      target: _linenDamages,
      fromJson: LinenDamage.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'hk_linen',
    );
    CloudSync.register(s);
    return s;
  }

  // ───────────────────── INIT ─────────────────────

  static Future<void> load() async {
    final t = PersistenceService.loadList('hk_tasks', HousekeepingTask.fromJson);
    if (t != null) { _tasks.clear(); _tasks.addAll(t); }
    final l = PersistenceService.loadList('hk_laundry', LaundryItem.fromJson);
    if (l != null) { _laundry.clear(); _laundry.addAll(l); }
    final lf = PersistenceService.loadList('hk_lost_found', LostFoundItem.fromJson);
    if (lf != null) { _lostFound.clear(); _lostFound.addAll(lf); }
    final ln = PersistenceService.loadList('hk_linen', LinenDamage.fromJson);
    if (ln != null) { _linenDamages.clear(); _linenDamages.addAll(ln); }
    if (_tasks.isEmpty) _seed();
    taskSync.loadMeta();
    laundrySync.loadMeta();
    lostFoundSync.loadMeta();
    linenSync.loadMeta();
  }

  static Future<void> _save() async {
    await PersistenceService.saveList('hk_tasks', _tasks, (e) => e.toJson());
    await PersistenceService.saveList('hk_laundry', _laundry, (e) => e.toJson());
    await PersistenceService.saveList('hk_lost_found', _lostFound, (e) => e.toJson());
    await PersistenceService.saveList('hk_linen', _linenDamages, (e) => e.toJson());
    await taskSync.push();
    await laundrySync.push();
    await lostFoundSync.push();
    await linenSync.push();
  }

  static int _counter = 0;
  static String _id() => 'hk_${DateTime.now().millisecondsSinceEpoch}_${++_counter}';

  // ───────────────────── TASKS ─────────────────────

  static List<HousekeepingTask> get tasks => List.unmodifiable(_tasks);
  static List<HousekeepingTask> get pendingTasks => _tasks.where((t) => !t.completed).toList();
  static List<HousekeepingTask> get overdueTasks => _tasks.where((t) => !t.completed && t.scheduledDate.isBefore(DateTime.now())).toList();

  static Future<void> addTask(HousekeepingTask t) async { _tasks.add(t); await _save(); }
  static Future<void> updateTask(String id, HousekeepingTask updated) async {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i >= 0) { _tasks[i] = updated; await _save(); }
  }
  static Future<void> removeTask(String id) async { _tasks.removeWhere((t) => t.id == id); await _save(); }

  // ───────────────────── LAUNDRY ─────────────────────

  static List<LaundryItem> get laundry => List.unmodifiable(_laundry);
  static List<LaundryItem> get pendingLaundry => _laundry.where((l) => l.status != LaundryStatus.delivered).toList();

  static Future<void> addLaundry(LaundryItem l) async { _laundry.insert(0, l); await _save(); }
  static Future<void> updateLaundry(String id, LaundryItem updated) async {
    final i = _laundry.indexWhere((l) => l.id == id);
    if (i >= 0) { _laundry[i] = updated; await _save(); }
  }
  static Future<void> removeLaundry(String id) async { _laundry.removeWhere((l) => l.id == id); await _save(); }

  // ───────────────────── LOST & FOUND ─────────────────────

  static List<LostFoundItem> get lostFound => List.unmodifiable(_lostFound);
  static List<LostFoundItem> get unclaimed => _lostFound.where((l) => !l.returned).toList();

  static Future<void> addLostFound(LostFoundItem l) async { _lostFound.insert(0, l); await _save(); }
  static Future<void> updateLostFound(String id, LostFoundItem updated) async {
    final i = _lostFound.indexWhere((l) => l.id == id);
    if (i >= 0) { _lostFound[i] = updated; await _save(); }
  }
  static Future<void> removeLostFound(String id) async { _lostFound.removeWhere((l) => l.id == id); await _save(); }

  // ───────────────────── LINEN ─────────────────────

  static List<LinenDamage> get linenDamages => List.unmodifiable(_linenDamages);
  static int get condemnedCount => _linenDamages.where((l) => l.condition == LinenCondition.condemned).fold(0, (s, l) => s + l.quantity);
  static double get totalReplacementCost => _linenDamages.fold(0.0, (s, l) => s + (l.replacementCost ?? 0) * l.quantity);

  static Future<void> addLinenDamage(LinenDamage l) async { _linenDamages.insert(0, l); await _save(); }
  static Future<void> updateLinenDamage(String id, LinenDamage updated) async {
    final i = _linenDamages.indexWhere((x) => x.id == id);
    if (i >= 0) { _linenDamages[i] = updated; await _save(); }
  }
  static Future<void> removeLinenDamage(String id) async { _linenDamages.removeWhere((l) => l.id == id); await _save(); }

  // ───────────────────── SEED ─────────────────────

  static void _seed() {
    final now = DateTime.now();
    _tasks.addAll([
      HousekeepingTask(id: _id(), roomNumber: '101', assignedTo: 'Fatima', priority: HousekeepingPriority.routine, scheduledDate: now),
      HousekeepingTask(id: _id(), roomNumber: '102', assignedTo: 'Fatima', priority: HousekeepingPriority.routine, scheduledDate: now),
      HousekeepingTask(id: _id(), roomNumber: '103', assignedTo: 'Blessing', priority: HousekeepingPriority.deepClean, scheduledDate: now.add(const Duration(days: 1))),
      HousekeepingTask(id: _id(), roomNumber: '201', assignedTo: 'Blessing', priority: HousekeepingPriority.vipSetup, scheduledDate: now.add(const Duration(hours: 4))),
      HousekeepingTask(id: _id(), roomNumber: '202', assignedTo: 'Chidi', priority: HousekeepingPriority.turndown, scheduledDate: now),
    ]);
    _laundry.addAll([
      LaundryItem(id: _id(), guestName: 'John Doe', roomNumber: '102', itemDescription: '2x Suit — Dry Clean', type: LaundryType.dryCleanOnly, chargeAmount: 8000),
      LaundryItem(id: _id(), guestName: 'Maryam Bello', roomNumber: '201', itemDescription: '3x Shirts, 2x Trousers', status: LaundryStatus.washing, chargeAmount: 6500),
      LaundryItem(id: _id(), guestName: 'Mr. Adekunle', roomNumber: '105', itemDescription: '1x bedsheet (stained) — Self', type: LaundryType.selfService),
    ]);
    _lostFound.addAll([
      LostFoundItem(id: _id(), itemName: 'iPhone 15 Pro', foundBy: 'Fatima', locationFound: 'Room 101 — bedside drawer', category: LostFoundCategory.electronics, notes: 'Passcode locked, awaiting guest call'),
      LostFoundItem(id: _id(), itemName: 'Gold Wedding Ring', foundBy: 'Blessing', locationFound: 'Room 201 — bathroom', category: LostFoundCategory.jewelry, notes: 'Guest contacted, will collect at checkout'),
      LostFoundItem(id: _id(), itemName: 'Navy Blue Passport', foundBy: 'Chidi', locationFound: 'Lobby — reception area', category: LostFoundCategory.documents, guestName: 'Oluwaseun Ojo', notes: 'Left on check-in counter'),
    ]);
    _linenDamages.addAll([
      LinenDamage(id: _id(), itemName: 'King Bedsheet — White', roomNumber: '101', category: LinenCategory.bedsheet, condition: LinenCondition.stained, quantity: 2, replacementCost: 8500, notes: 'Red wine stain, cannot remove'),
      LinenDamage(id: _id(), itemName: 'Bath Towel XL', roomNumber: '103', category: LinenCategory.towel, condition: LinenCondition.torn, quantity: 1, replacementCost: 3500, notes: 'Torn during laundry'),
      LinenDamage(id: _id(), itemName: 'Pillowcase — Standard', roomNumber: '202', category: LinenCategory.pillowcase, condition: LinenCondition.condemned, quantity: 4, replacementCost: 2200, notes: 'Yellowed beyond recovery'),
    ]);
  }
}
