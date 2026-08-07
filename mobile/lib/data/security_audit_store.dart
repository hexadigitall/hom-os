import 'persistence_service.dart';
import 'store_sync.dart';
import '../models/security_audit.dart';

class SecurityAuditStore {
  static final List<NightAuditLog> _nightAudits = [];
  static final List<SecurityIncident> _incidents = [];
  static final List<VisitorPass> _visitorPasses = [];
  static final List<ShiftHandover> _shifts = [];

  // Offline-first cloud sync for each security/audit collection.
  static final StoreSync<NightAuditLog> auditSync = _initAuditSync();
  static final StoreSync<SecurityIncident> incidentSync = _initIncidentSync();
  static final StoreSync<VisitorPass> visitorSync = _initVisitorSync();
  static final StoreSync<ShiftHandover> shiftSync = _initShiftSync();

  static StoreSync<NightAuditLog> _initAuditSync() {
    final s = StoreSync<NightAuditLog>(
      collection: 'sa_nightaudits', target: _nightAudits,
      fromJson: NightAuditLog.fromJson, toJson: (e) => e.toJson(),
      cacheKey: 'sa_night_audits',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<SecurityIncident> _initIncidentSync() {
    final s = StoreSync<SecurityIncident>(
      collection: 'sa_incidents', target: _incidents,
      fromJson: SecurityIncident.fromJson, toJson: (e) => e.toJson(),
      cacheKey: 'sa_incidents',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<VisitorPass> _initVisitorSync() {
    final s = StoreSync<VisitorPass>(
      collection: 'sa_visitors', target: _visitorPasses,
      fromJson: VisitorPass.fromJson, toJson: (e) => e.toJson(),
      cacheKey: 'sa_visitor_passes',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<ShiftHandover> _initShiftSync() {
    final s = StoreSync<ShiftHandover>(
      collection: 'sa_shifts', target: _shifts,
      fromJson: ShiftHandover.fromJson, toJson: (e) => e.toJson(),
      cacheKey: 'sa_shifts',
    );
    CloudSync.register(s);
    return s;
  }

  // ───────────────────── INIT ─────────────────────

  static Future<void> load() async {
    final n = PersistenceService.loadList('sa_night_audits', NightAuditLog.fromJson);
    if (n != null) { _nightAudits.clear(); _nightAudits.addAll(n); }
    final i = PersistenceService.loadList('sa_incidents', SecurityIncident.fromJson);
    if (i != null) { _incidents.clear(); _incidents.addAll(i); }
    final v = PersistenceService.loadList('sa_visitor_passes', VisitorPass.fromJson);
    if (v != null) { _visitorPasses.clear(); _visitorPasses.addAll(v); }
    final s = PersistenceService.loadList('sa_shifts', ShiftHandover.fromJson);
    if (s != null) { _shifts.clear(); _shifts.addAll(s); }
    if (_nightAudits.isEmpty) _seed();
    auditSync.loadMeta();
    incidentSync.loadMeta();
    visitorSync.loadMeta();
    shiftSync.loadMeta();
  }

  static Future<void> _save() async {
    await PersistenceService.saveList('sa_night_audits', _nightAudits, (e) => e.toJson());
    await PersistenceService.saveList('sa_incidents', _incidents, (e) => e.toJson());
    await PersistenceService.saveList('sa_visitor_passes', _visitorPasses, (e) => e.toJson());
    await PersistenceService.saveList('sa_shifts', _shifts, (e) => e.toJson());
    await auditSync.push();
    await incidentSync.push();
    await visitorSync.push();
    await shiftSync.push();
  }

  static int _counter = 0;
  static String _id() => 'sa_${DateTime.now().millisecondsSinceEpoch}_${++_counter}';

  // ───────────────────── NIGHT AUDIT ─────────────────────

  static List<NightAuditLog> get nightAudits => List.unmodifiable(_nightAudits);
  static NightAuditLog? get todayAudit {
    final today = DateTime.now();
    return _nightAudits.cast<NightAuditLog?>().firstWhere(
      (a) => a!.businessDate.year == today.year && a.businessDate.month == today.month && a.businessDate.day == today.day,
      orElse: () => null,
    );
  }
  static bool get isTodayLocked => todayAudit?.locked ?? false;
  static bool isDateLocked(DateTime date) => _nightAudits.any((a) =>
    a.businessDate.year == date.year && a.businessDate.month == date.month && a.businessDate.day == date.day && a.locked);

  static Future<void> addNightAudit(NightAuditLog a) async { _nightAudits.insert(0, a); await _save(); }
  static Future<void> updateNightAudit(String id, NightAuditLog updated) async {
    final i = _nightAudits.indexWhere((a) => a.id == id);
    if (i >= 0) { _nightAudits[i] = updated; await _save(); }
  }
  static Future<void> removeNightAudit(String id) async { _nightAudits.removeWhere((a) => a.id == id); await _save(); }

  // ───────────────────── INCIDENTS ─────────────────────

  static List<SecurityIncident> get incidents => List.unmodifiable(_incidents);
  static List<SecurityIncident> get openIncidents => _incidents.where((i) => i.status != IncidentStatus.resolved).toList();

  static Future<void> addIncident(SecurityIncident i) async { _incidents.insert(0, i); await _save(); }
  static Future<void> updateIncident(String id, SecurityIncident updated) async {
    final i = _incidents.indexWhere((inc) => inc.id == id);
    if (i >= 0) { _incidents[i] = updated; await _save(); }
  }
  static Future<void> removeIncident(String id) async { _incidents.removeWhere((i) => i.id == id); await _save(); }

  // ───────────────────── VISITOR PASSES ─────────────────────

  static List<VisitorPass> get visitorPasses => List.unmodifiable(_visitorPasses);
  static List<VisitorPass> get activeVisitors => _visitorPasses.where((v) => v.active).toList();

  static Future<void> addVisitorPass(VisitorPass v) async { _visitorPasses.insert(0, v); await _save(); }
  static Future<void> updateVisitorPass(String id, VisitorPass updated) async {
    final i = _visitorPasses.indexWhere((v) => v.id == id);
    if (i >= 0) { _visitorPasses[i] = updated; await _save(); }
  }
  static Future<void> removeVisitorPass(String id) async { _visitorPasses.removeWhere((v) => v.id == id); await _save(); }

  // ───────────────────── SHIFT HANDOVER ─────────────────────

  static List<ShiftHandover> get shifts => List.unmodifiable(_shifts);
  static ShiftHandover? get activeShift => _shifts.cast<ShiftHandover?>().firstWhere(
    (s) => s!.isActive, orElse: () => null,
  );
  static List<ShiftHandover> get todayShifts {
    final now = DateTime.now();
    return _shifts.where((s) =>
        s.openedAt.year == now.year && s.openedAt.month == now.month && s.openedAt.day == now.day).toList();
  }

  static Future<void> addShift(ShiftHandover s) async { _shifts.insert(0, s); await _save(); }
  static Future<void> updateShift(String id, ShiftHandover updated) async {
    final i = _shifts.indexWhere((s) => s.id == id);
    if (i >= 0) { _shifts[i] = updated; await _save(); }
  }
  static Future<void> removeShift(String id) async { _shifts.removeWhere((s) => s.id == id); await _save(); }

  // ───────────────────── SEED ─────────────────────

  static void _seed() {
    final now = DateTime.now();
    _nightAudits.addAll([
      NightAuditLog(id: _id(), businessDate: now.subtract(const Duration(days: 1)), totalRevenue: 485000, roomRevenue: 350000, fnbRevenue: 95000, otherRevenue: 40000, cashDropCount: 2, cashDropTotal: 120000, closedBy: 'Lateef', locked: true, closedAt: now.subtract(const Duration(hours: 8))),
      NightAuditLog(id: _id(), businessDate: now.subtract(const Duration(days: 2)), totalRevenue: 412000, roomRevenue: 300000, fnbRevenue: 82000, otherRevenue: 30000, cashDropCount: 1, cashDropTotal: 65000, closedBy: 'Lateef', locked: true, closedAt: now.subtract(const Duration(days: 1, hours: 8))),
    ]);
    _incidents.addAll([
      SecurityIncident(id: _id(), type: IncidentType.theft, location: 'Room 103', description: 'Guest reported missing laptop from room', reportedBy: 'Fatima (HK)', status: IncidentStatus.investigating),
      SecurityIncident(id: _id(), type: IncidentType.propertyDamage, location: 'Pool Area', description: 'Broken sun lounger — guest accident', reportedBy: 'Pool Attendant', status: IncidentStatus.resolved, resolvedBy: 'Maintenance', dateResolved: now.subtract(const Duration(hours: 6)), notes: 'Lounger replaced'),
    ]);
    _visitorPasses.addAll([
      VisitorPass(id: _id(), visitorName: 'Mr. Adebayo Oke', purpose: 'Meeting with GM', hostName: 'Blessing Eze', badgeNumber: 'V-001', checkIn: now.subtract(const Duration(hours: 2))),
      VisitorPass(id: _id(), visitorName: 'Dr. Ngozi Okonkwo', purpose: 'Health Inspection', hostName: 'Management', badgeNumber: 'V-002', checkIn: now.subtract(const Duration(hours: 1))),
    ]);
  }
}
