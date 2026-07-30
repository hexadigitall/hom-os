import 'persistence_service.dart';
import '../models/expenditure.dart';
import '../models/role.dart';
import 'role_store.dart';

class ExpenditureStore {
  static final List<ExpenditureRecord> _records = [];
  static int _counter = 0;

  static List<ExpenditureRecord> get all => List.unmodifiable(_records);

  static String generateId() => 'exp_${DateTime.now().millisecondsSinceEpoch}_${++_counter}';

  static Future<void> load() async {
    final r = PersistenceService.loadList('expenditure_records', ExpenditureRecord.fromJson);
    if (r != null) { _records.clear(); _records.addAll(r); }
  }

  static Future<void> _save() => PersistenceService.saveList('expenditure_records', _records, (r) => r.toJson());

  static Future<void> add(ExpenditureRecord r) async { _records.insert(0, r); await _save(); }

  static Future<void> addAll(List<ExpenditureRecord> records) async {
    _records.insertAll(0, records);
    await _save();
  }

  static List<ExpenditureRecord> filterByCategory(ExpenditureCategory? cat) {
    if (cat == null) return all;
    return _records.where((r) => r.category == cat).toList();
  }

  static List<ExpenditureRecord> get forCurrentDepartment {
    final dept = RoleStore.currentRole.department;
    if (dept == null) return all;
    return _records.where((r) => r.department == dept).toList();
  }

  static List<ExpenditureRecord> filterByDepartment(Department? dept) {
    if (dept == null) return all;
    return _records.where((r) => r.department == dept).toList();
  }

  static List<ExpenditureRecord> filterByDateRange(DateTime start, DateTime end) {
    final endEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _records.where((r) => r.date.isAfter(start.subtract(const Duration(days: 1))) && r.date.isBefore(endEnd)).toList();
  }

  static List<ExpenditureRecord> filterByPeriod(DateTime start, DateTime end) {
    return _records.where((r) =>
        !r.date.isBefore(start) && !r.date.isAfter(end)).toList();
  }

  static Future<void> update(String id, ExpenditureRecord updated) async {
    final i = _records.indexWhere((r) => r.id == id);
    if (i >= 0) { _records[i] = updated; await _save(); }
  }

  static Future<void> remove(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _save();
  }

  static Future<void> clear() async { _records.clear(); await _save(); }

  static int get count => _records.length;

  static double get totalAll => _records.fold(0.0, (sum, r) => sum + r.amount);

  static Map<ExpenditureCategory, double> totalsByCategory(List<ExpenditureRecord>? records) {
    final list = records ?? _records;
    final map = <ExpenditureCategory, double>{};
    for (final c in ExpenditureCategory.values) {
      map[c] = 0.0;
    }
    for (final r in list) {
      map[r.category] = (map[r.category] ?? 0) + r.amount;
    }
    return map;
  }
}
