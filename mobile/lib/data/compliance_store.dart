import 'persistence_service.dart';
import 'store_sync.dart';
import '../models/compliance.dart';

class ComplianceStore {
  // SCUML
  static final List<ScumlTransaction> _scumlTransactions = [];
  static List<ScumlTransaction> get scumlTransactions => List.unmodifiable(_scumlTransactions);
  static double get scumlTotal => _scumlTransactions.fold(0.0, (s, t) => s + t.amount);

  // Cash Transactions
  static final List<CashTransaction> _cashTransactions = [];
  static List<CashTransaction> get cashTransactions => List.unmodifiable(_cashTransactions);
  static double get cashTotal => _cashTransactions.fold(0.0, (s, t) => s + t.amount);
  static List<CashTransaction> get flaggedCashTransactions =>
    _cashTransactions.where((t) => t.flagged || t.exceedsThreshold).toList();
  static int get thresholdAlertCount =>
    _cashTransactions.where((t) => t.exceedsThreshold).length;

  // Fire Service
  static final List<FireServiceCert> _fireServiceCerts = [];
  static List<FireServiceCert> get fireServiceCerts => List.unmodifiable(_fireServiceCerts);
  static FireServiceCert? get latestFireCert =>
    _fireServiceCerts.isNotEmpty ? _fireServiceCerts.first : null;

  // State Tax
  static final List<StateTaxConfig> _stateTaxConfigs = [
    StateTaxConfig(id: 'Lagos', stateName: 'Lagos', rate: 5.0),
    StateTaxConfig(id: 'Rivers', stateName: 'Rivers', rate: 5.0),
    StateTaxConfig(id: 'FCT', stateName: 'Federal Capital Territory', rate: 5.0),
    StateTaxConfig(id: 'Oyo', stateName: 'Oyo', rate: 3.0, appliesToOtherServices: true),
    StateTaxConfig(id: 'Delta', stateName: 'Delta', rate: 2.5),
  ];
  static List<StateTaxConfig> get stateTaxConfigs => List.unmodifiable(_stateTaxConfigs);

  static final List<StateTaxReport> _taxReports = [];
  static List<StateTaxReport> get taxReports => List.unmodifiable(_taxReports);

  // NAPTIP
  static final List<NaptipAlert> _naptipAlerts = [];
  static List<NaptipAlert> get naptipAlerts => List.unmodifiable(_naptipAlerts);


  // LGA H&S
  static final List<LgaInspection> _lgaInspections = [];
  static List<LgaInspection> get lgaInspections => List.unmodifiable(_lgaInspections);

  static LgaInspection? get latestInspection => _lgaInspections.isNotEmpty ? _lgaInspections.first : null;

  static int _counter = 0;
  static String genId() => 'cmp_${DateTime.now().millisecondsSinceEpoch}_${++_counter}';

  // Offline-first cloud sync for each compliance collection.
  static final StoreSync<ScumlTransaction> scumlSync = _initScumlSync();
  static final StoreSync<CashTransaction> cashSync = _initCashSync();
  static final StoreSync<StateTaxConfig> taxConfigSync = _initTaxConfigSync();
  static final StoreSync<StateTaxReport> taxReportSync = _initTaxReportSync();
  static final StoreSync<NaptipAlert> naptipSync = _initNaptipSync();
  static final StoreSync<LgaInspection> lgaSync = _initLgaSync();
  static final StoreSync<FireServiceCert> fireSync = _initFireSync();

  static StoreSync<ScumlTransaction> _initScumlSync() {
    final s = StoreSync<ScumlTransaction>(
      collection: 'cmp_scuml', target: _scumlTransactions,
      fromJson: ScumlTransaction.fromJson, toJson: (e) => e.toJson(),
      cacheKey: 'cmp_scuml',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<CashTransaction> _initCashSync() {
    final s = StoreSync<CashTransaction>(
      collection: 'cmp_cash', target: _cashTransactions,
      fromJson: CashTransaction.fromJson, toJson: (e) => e.toJson(),
      cacheKey: 'cmp_cash',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<StateTaxConfig> _initTaxConfigSync() {
    final s = StoreSync<StateTaxConfig>(
      collection: 'cmp_tax_config', target: _stateTaxConfigs,
      fromJson: StateTaxConfig.fromJson, toJson: (e) => e.toJson(),
      cacheKey: 'cmp_tax_config',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<StateTaxReport> _initTaxReportSync() {
    final s = StoreSync<StateTaxReport>(
      collection: 'cmp_tax_reports', target: _taxReports,
      fromJson: StateTaxReport.fromJson, toJson: (e) => e.toJson(),
      cacheKey: 'cmp_tax_reports',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<NaptipAlert> _initNaptipSync() {
    final s = StoreSync<NaptipAlert>(
      collection: 'cmp_naptip', target: _naptipAlerts,
      fromJson: NaptipAlert.fromJson, toJson: (e) => e.toJson(),
      cacheKey: 'cmp_naptip',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<LgaInspection> _initLgaSync() {
    final s = StoreSync<LgaInspection>(
      collection: 'cmp_lga', target: _lgaInspections,
      fromJson: LgaInspection.fromJson, toJson: (e) => e.toJson(),
      cacheKey: 'cmp_lga',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<FireServiceCert> _initFireSync() {
    final s = StoreSync<FireServiceCert>(
      collection: 'cmp_fire_certs', target: _fireServiceCerts,
      fromJson: FireServiceCert.fromJson, toJson: (e) => e.toJson(),
      cacheKey: 'cmp_fire_certs',
    );
    CloudSync.register(s);
    return s;
  }

  // ===================== PERSISTENCE =====================

  static Future<void> load() async {
    final s = PersistenceService.loadList('cmp_scuml', ScumlTransaction.fromJson);
    if (s != null) { _scumlTransactions.clear(); _scumlTransactions.addAll(s); }
    final c = PersistenceService.loadList('cmp_tax_config', StateTaxConfig.fromJson);
    if (c != null) { _stateTaxConfigs.clear(); _stateTaxConfigs.addAll(c); }
    final r = PersistenceService.loadList('cmp_tax_reports', StateTaxReport.fromJson);
    if (r != null) { _taxReports.clear(); _taxReports.addAll(r); }
    final n = PersistenceService.loadList('cmp_naptip', NaptipAlert.fromJson);
    if (n != null) { _naptipAlerts.clear(); _naptipAlerts.addAll(n); }
    final l = PersistenceService.loadList('cmp_lga', LgaInspection.fromJson);
    if (l != null) { _lgaInspections.clear(); _lgaInspections.addAll(l); }
    final cash = PersistenceService.loadList('cmp_cash', CashTransaction.fromJson);
    if (cash != null) { _cashTransactions.clear(); _cashTransactions.addAll(cash); }
    final fire = PersistenceService.loadList('cmp_fire_certs', FireServiceCert.fromJson);
    if (fire != null) { _fireServiceCerts.clear(); _fireServiceCerts.addAll(fire); }
    scumlSync.loadMeta();
    cashSync.loadMeta();
    taxConfigSync.loadMeta();
    taxReportSync.loadMeta();
    naptipSync.loadMeta();
    lgaSync.loadMeta();
    fireSync.loadMeta();
  }

  static Future<void> _save() async {
    await PersistenceService.saveList('cmp_scuml', _scumlTransactions, (e) => e.toJson());
    await PersistenceService.saveList('cmp_tax_config', _stateTaxConfigs, (e) => e.toJson());
    await PersistenceService.saveList('cmp_tax_reports', _taxReports, (e) => e.toJson());
    await PersistenceService.saveList('cmp_naptip', _naptipAlerts, (e) => e.toJson());
    await PersistenceService.saveList('cmp_lga', _lgaInspections, (e) => e.toJson());
    await PersistenceService.saveList('cmp_cash', _cashTransactions, (e) => e.toJson());
    await PersistenceService.saveList('cmp_fire_certs', _fireServiceCerts, (e) => e.toJson());
    await scumlSync.push();
    await cashSync.push();
    await taxConfigSync.push();
    await taxReportSync.push();
    await naptipSync.push();
    await lgaSync.push();
    await fireSync.push();
  }

  static Future<void> addScuml(ScumlTransaction t) async { _scumlTransactions.insert(0, t); await _save(); }
  static Future<void> updateScuml(String id, ScumlTransaction updated) async {
    final i = _scumlTransactions.indexWhere((t) => t.id == id);
    if (i >= 0) { _scumlTransactions[i] = updated; await _save(); }
  }
  static Future<void> removeScuml(String id) async { _scumlTransactions.removeWhere((t) => t.id == id); await _save(); }

  static Future<void> upsertTaxConfig(StateTaxConfig c) async {
    if (c.id == null) {
      c = StateTaxConfig(
        id: c.stateName, stateName: c.stateName, rate: c.rate,
        appliesToAccommodation: c.appliesToAccommodation,
        appliesToFoodAndDrinks: c.appliesToFoodAndDrinks,
        appliesToOtherServices: c.appliesToOtherServices,
      );
    }
    final i = _stateTaxConfigs.indexWhere((x) => x.id == c.id);
    if (i >= 0) { _stateTaxConfigs[i] = c; } else { _stateTaxConfigs.add(c); }
    await _save();
  }
  static Future<void> removeTaxConfig(String stateName) async { _stateTaxConfigs.removeWhere((c) => c.stateName == stateName); await _save(); }

  static Future<void> addTaxReport(StateTaxReport r) async { _taxReports.insert(0, r); await _save(); }
  static Future<void> updateTaxReport(String id, StateTaxReport updated) async {
    final i = _taxReports.indexWhere((x) => x.id == id);
    if (i >= 0) { _taxReports[i] = updated; await _save(); }
  }
  static Future<void> removeTaxReport(String id) async { _taxReports.removeWhere((r) => r.id == id); await _save(); }

  static Future<void> addNaptipAlert(NaptipAlert a) async { _naptipAlerts.insert(0, a); await _save(); }
  static Future<void> updateNaptipAlert(String id, NaptipAlert updated) async {
    final i = _naptipAlerts.indexWhere((a) => a.id == id);
    if (i >= 0) { _naptipAlerts[i] = updated; await _save(); }
  }
  static Future<void> removeNaptipAlert(String id) async { _naptipAlerts.removeWhere((a) => a.id == id); await _save(); }

  static Future<void> addLgaInspection(LgaInspection insp) async { _lgaInspections.insert(0, insp); await _save(); }
  static Future<void> updateLgaInspection(String id, LgaInspection updated) async {
    final idx = _lgaInspections.indexWhere((x) => x.id == id);
    if (idx >= 0) { _lgaInspections[idx] = updated; await _save(); }
  }
  static Future<void> removeLgaInspection(String id) async { _lgaInspections.removeWhere((x) => x.id == id); await _save(); }

  // ===================== CASH TRANSACTIONS =====================

  static Future<void> addCashTransaction(CashTransaction t) async { _cashTransactions.insert(0, t); await _save(); }
  static Future<void> updateCashTransaction(String id, CashTransaction updated) async {
    final idx = _cashTransactions.indexWhere((x) => x.id == id);
    if (idx >= 0) { _cashTransactions[idx] = updated; await _save(); }
  }
  static Future<void> removeCashTransaction(String id) async { _cashTransactions.removeWhere((x) => x.id == id); await _save(); }

  // ===================== FIRE SERVICE CERTS =====================

  static Future<void> addFireServiceCert(FireServiceCert c) async { _fireServiceCerts.insert(0, c); await _save(); }
  static Future<void> updateFireServiceCert(String id, FireServiceCert updated) async {
    final idx = _fireServiceCerts.indexWhere((x) => x.id == id);
    if (idx >= 0) { _fireServiceCerts[idx] = updated; await _save(); }
  }
  static Future<void> removeFireServiceCert(String id) async { _fireServiceCerts.removeWhere((x) => x.id == id); await _save(); }
}
