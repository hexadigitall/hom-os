import 'persistence_service.dart';
import 'store_sync.dart';
import '../models/back_office.dart';
import '../models/role.dart';
import 'role_store.dart';

class BackOfficeStore {
  static final List<ProcurementOrder> _procurements = [];
  static final List<PayrollRecord> _payrolls = [];
  static final List<TaxConfiguration> _taxConfigs = [];

  // Offline-first cloud sync for each back-office collection.
  static final StoreSync<ProcurementOrder> procurementSync = _initProcurementSync();
  static final StoreSync<PayrollRecord> payrollSync = _initPayrollSync();
  static final StoreSync<TaxConfiguration> taxConfigSync = _initTaxConfigSync();

  static StoreSync<ProcurementOrder> _initProcurementSync() {
    final s = StoreSync<ProcurementOrder>(
      collection: 'bo_procurements',
      target: _procurements,
      fromJson: ProcurementOrder.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'bo_procurements',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<PayrollRecord> _initPayrollSync() {
    final s = StoreSync<PayrollRecord>(
      collection: 'bo_payrolls',
      target: _payrolls,
      fromJson: PayrollRecord.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'bo_payrolls',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<TaxConfiguration> _initTaxConfigSync() {
    final s = StoreSync<TaxConfiguration>(
      collection: 'bo_tax_config',
      target: _taxConfigs,
      fromJson: TaxConfiguration.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'bo_tax_config',
    );
    CloudSync.register(s);
    return s;
  }

  // ───────────────────── INIT ─────────────────────

  static Future<void> load() async {
    final p = PersistenceService.loadList('bo_procurements', ProcurementOrder.fromJson);
    if (p != null) { _procurements.clear(); _procurements.addAll(p); }
    final pr = PersistenceService.loadList('bo_payrolls', PayrollRecord.fromJson);
    if (pr != null) { _payrolls.clear(); _payrolls.addAll(pr); }
    final t = PersistenceService.loadList('bo_tax_config', TaxConfiguration.fromJson);
    if (t != null && t.isNotEmpty) {
      _taxConfigs.clear(); _taxConfigs.addAll(t);
    } else {
      final legacy = PersistenceService.load('bo_tax_config', (d) => TaxConfiguration.fromJson(d as Map<String, dynamic>));
      if (legacy != null) _taxConfigs.add(legacy);
    }
    if (_procurements.isEmpty) _seed();
    procurementSync.loadMeta();
    payrollSync.loadMeta();
    taxConfigSync.loadMeta();
  }

  static Future<void> _save() async {
    await PersistenceService.saveList('bo_procurements', _procurements, (e) => e.toJson());
    await PersistenceService.saveList('bo_payrolls', _payrolls, (e) => e.toJson());
    await PersistenceService.saveList('bo_tax_config', _taxConfigs, (e) => e.toJson());
    await procurementSync.push();
    await payrollSync.push();
    await taxConfigSync.push();
  }

  static int _counter = 0;
  static String _id() => 'bo_${DateTime.now().millisecondsSinceEpoch}_${++_counter}';

  // ───────────────────── PROCUREMENT ─────────────────────

  static List<ProcurementOrder> get procurements => List.unmodifiable(_procurements);
  static List<ProcurementOrder> get openOrders => _procurements.where((p) => p.status != ProcurementStatus.delivered && p.status != ProcurementStatus.cancelled).toList();
  static double get totalSpend => _procurements.where((p) => p.status == ProcurementStatus.delivered).fold(0.0, (s, p) => s + p.amount);

  static List<ProcurementOrder> get procurementForCurrentDept {
    final scope = RoleStore.departments;
    if (scope.isEmpty) return procurements;
    return _procurements.where((p) => p.department != null && scope.contains(p.department)).toList();
  }

  static Future<void> addProcurement(ProcurementOrder p) async { _procurements.insert(0, p); await _save(); }
  static Future<void> updateProcurement(String id, ProcurementOrder updated) async {
    final i = _procurements.indexWhere((p) => p.id == id);
    if (i >= 0) { _procurements[i] = updated; await _save(); }
  }
  static Future<void> removeProcurement(String id) async { _procurements.removeWhere((p) => p.id == id); await _save(); }

  // ───────────────────── PAYROLL ─────────────────────

  static List<PayrollRecord> get payrolls => List.unmodifiable(_payrolls);
  static List<PayrollRecord> get pendingPayroll => _payrolls.where((p) => p.status == PayrollStatus.pending).toList();
  static double get totalPaid => _payrolls.where((p) => p.status == PayrollStatus.paid).fold(0.0, (s, p) => s + p.netPay);

  static List<PayrollRecord> get payrollForCurrentDept {
    final scope = RoleStore.departments;
    if (scope.isEmpty) return payrolls;
    return _payrolls.where((p) =>
        scope.any((d) => _deptLabelMatches(p.department, d))).toList();
  }

  static bool _deptLabelMatches(String label, Department d) {
    final norm = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return norm == d.name.toLowerCase().replaceAll('_', '') ||
        norm.contains(d.name.toLowerCase());
  }

  static Future<void> addPayroll(PayrollRecord r) async { _payrolls.insert(0, r); await _save(); }
  static Future<void> updatePayroll(String id, PayrollRecord updated) async {
    final i = _payrolls.indexWhere((p) => p.id == id);
    if (i >= 0) { _payrolls[i] = updated; await _save(); }
  }
  static Future<void> removePayroll(String id) async { _payrolls.removeWhere((p) => p.id == id); await _save(); }

  // ───────────────────── TAX CONFIG ─────────────────────

  static TaxConfiguration get taxConfig =>
      _taxConfigs.isNotEmpty ? _taxConfigs.first : TaxConfiguration(id: 'tax_default');
  static Future<void> updateTaxConfig(TaxConfiguration t) async {
    final i = _taxConfigs.indexWhere((c) => c.id == t.id);
    if (i >= 0) { _taxConfigs[i] = t; } else { _taxConfigs.add(t); }
    await _save();
  }
  static Future<void> resetTaxConfig() async { _taxConfigs.clear(); await _save(); }

  // ───────────────────── SEED ─────────────────────

  static void _seed() {
    _taxConfigs.add(TaxConfiguration(id: 'tax_default'));
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    _procurements.addAll([
      ProcurementOrder(id: _id(), vendorName: 'MRS Petroleum', items: 'Diesel 500L, Engine Oil 20L', amount: 620000, status: ProcurementStatus.delivered, deliveryDate: now.subtract(const Duration(days: 5))),
      ProcurementOrder(id: _id(), vendorName: 'Fresh Foods Ltd', items: 'Vegetables, Rice, Cooking Oil', amount: 185000, status: ProcurementStatus.approved, notes: 'Weekly kitchen supply'),
      ProcurementOrder(id: _id(), vendorName: 'CleanPro Supplies', items: 'Detergent 50L, Bleach 20L, Mops x10', amount: 95000, status: ProcurementStatus.draft),
    ]);
    _payrolls.addAll([
      PayrollRecord(id: _id(), staffName: 'Amina Yusuf', department: 'Front Desk', basicSalary: 120000, allowances: 15000, deductions: 2000, payeTax: 8400, pensionContribution: 9600, netPay: 115000, periodStart: monthStart, periodEnd: monthEnd, status: PayrollStatus.paid),
      PayrollRecord(id: _id(), staffName: 'Chidi Okonkwo', department: 'Housekeeping', basicSalary: 70000, allowances: 5000, deductions: 1000, payeTax: 4900, pensionContribution: 5600, netPay: 63500, periodStart: monthStart, periodEnd: monthEnd, status: PayrollStatus.pending),
      PayrollRecord(id: _id(), staffName: 'Blessing Eze', department: 'Management', basicSalary: 200000, allowances: 30000, deductions: 5000, payeTax: 14000, pensionContribution: 16000, netPay: 195000, periodStart: monthStart, periodEnd: monthEnd, status: PayrollStatus.pending),
    ]);
  }
}
