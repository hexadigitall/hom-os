import 'persistence_service.dart';
import '../models/back_office.dart';
import 'role_store.dart';

class BackOfficeStore {
  static final List<ProcurementOrder> _procurements = [];
  static final List<PayrollRecord> _payrolls = [];
  static TaxConfiguration? _taxConfig;

  // ───────────────────── INIT ─────────────────────

  static Future<void> load() async {
    final p = PersistenceService.loadList('bo_procurements', ProcurementOrder.fromJson);
    if (p != null) { _procurements.clear(); _procurements.addAll(p); }
    final pr = PersistenceService.loadList('bo_payrolls', PayrollRecord.fromJson);
    if (pr != null) { _payrolls.clear(); _payrolls.addAll(pr); }
    final t = PersistenceService.load('bo_tax_config', (d) => TaxConfiguration.fromJson(d as Map<String, dynamic>));
    if (t != null) { _taxConfig = t; }
    if (_procurements.isEmpty) _seed();
  }

  static Future<void> _save() async {
    await PersistenceService.saveList('bo_procurements', _procurements, (e) => e.toJson());
    await PersistenceService.saveList('bo_payrolls', _payrolls, (e) => e.toJson());
    if (_taxConfig != null) await PersistenceService.save('bo_tax_config', _taxConfig!.toJson());
  }

  static int _counter = 0;
  static String _id() => 'bo_${DateTime.now().millisecondsSinceEpoch}_${++_counter}';

  // ───────────────────── PROCUREMENT ─────────────────────

  static List<ProcurementOrder> get procurements => List.unmodifiable(_procurements);
  static List<ProcurementOrder> get openOrders => _procurements.where((p) => p.status != ProcurementStatus.delivered && p.status != ProcurementStatus.cancelled).toList();
  static double get totalSpend => _procurements.where((p) => p.status == ProcurementStatus.delivered).fold(0.0, (s, p) => s + p.amount);

  static List<ProcurementOrder> get procurementForCurrentDept {
    final dept = RoleStore.currentRole.department;
    if (dept == null) return procurements;
    return _procurements.where((p) => p.department == dept).toList();
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
    final dept = RoleStore.currentRole.department;
    if (dept == null) return payrolls;
    return _payrolls.where((p) => p.department == dept.name).toList();
  }

  static Future<void> addPayroll(PayrollRecord r) async { _payrolls.insert(0, r); await _save(); }
  static Future<void> updatePayroll(String id, PayrollRecord updated) async {
    final i = _payrolls.indexWhere((p) => p.id == id);
    if (i >= 0) { _payrolls[i] = updated; await _save(); }
  }
  static Future<void> removePayroll(String id) async { _payrolls.removeWhere((p) => p.id == id); await _save(); }

  // ───────────────────── TAX CONFIG ─────────────────────

  static TaxConfiguration get taxConfig => _taxConfig ?? TaxConfiguration(id: 'tax_default');
  static Future<void> updateTaxConfig(TaxConfiguration t) async { _taxConfig = t; await _save(); }
  static Future<void> resetTaxConfig() async { _taxConfig = TaxConfiguration(id: 'tax_default'); await _save(); }

  // ───────────────────── SEED ─────────────────────

  static void _seed() {
    _taxConfig = TaxConfiguration(id: 'tax_default');
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
