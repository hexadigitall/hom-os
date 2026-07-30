import 'persistence_service.dart';
import '../models/engineering.dart';

class EngineeringStore {
  static final List<Generator> _generators = [];
  static final List<MaintenanceTask> _maintenanceTasks = [];
  static final List<WaterTreatmentLog> _waterLogs = [];
  static final List<TankDipLog> _tankDipLogs = [];
  static final List<GridTariffConfig> _gridTariffs = [];

  static Future<void> load() async {
    final g = PersistenceService.loadList('eng_generators', Generator.fromJson);
    if (g != null) { _generators.clear(); _generators.addAll(g); }
    final m = PersistenceService.loadList('eng_maintenance', MaintenanceTask.fromJson);
    if (m != null) { _maintenanceTasks.clear(); _maintenanceTasks.addAll(m); }
    final w = PersistenceService.loadList('eng_water', WaterTreatmentLog.fromJson);
    if (w != null) { _waterLogs.clear(); _waterLogs.addAll(w); }
    final t = PersistenceService.loadList('eng_tank_dips', TankDipLog.fromJson);
    if (t != null) { _tankDipLogs.clear(); _tankDipLogs.addAll(t); }
    final r = PersistenceService.loadList('eng_grid_tariffs', GridTariffConfig.fromJson);
    if (r != null) { _gridTariffs.clear(); _gridTariffs.addAll(r); }
    if (_generators.isEmpty) _seed();
  }

  static Future<void> _save() async {
    await PersistenceService.saveList('eng_generators', _generators, (e) => e.toJson());
    await PersistenceService.saveList('eng_maintenance', _maintenanceTasks, (e) => e.toJson());
    await PersistenceService.saveList('eng_water', _waterLogs, (e) => e.toJson());
    await PersistenceService.saveList('eng_tank_dips', _tankDipLogs, (e) => e.toJson());
    await PersistenceService.saveList('eng_grid_tariffs', _gridTariffs, (e) => e.toJson());
  }

  static int _counter = 0;
  static String _id() => 'eng_${DateTime.now().millisecondsSinceEpoch}_${++_counter}';

  // ===================== GENERATORS =====================

  static List<Generator> get generators => List.unmodifiable(_generators);
  static int get runningCount => _generators.where((g) => g.status == GeneratorStatus.running).length;
  static int get faultCount => _generators.where((g) => g.status == GeneratorStatus.fault).length;
  static double get totalCapacity => _generators.fold(0.0, (s, g) => s + g.capacityKva);
  static double get totalRunHours => _generators.fold(0.0, (s, g) => s + g.currentRunHours);
  static double get avgLoadPct {
    final active = _generators.where((g) => g.capacityKva > 0).toList();
    if (active.isEmpty) return 0;
    return active.fold(0.0, (s, g) => s + g.loadPct) / active.length;
  }

  static Future<void> addGenerator(Generator g) async { _generators.add(g); await _save(); }
  static Future<void> updateGenerator(String id, Generator updated) async {
    final i = _generators.indexWhere((g) => g.id == id);
    if (i >= 0) { _generators[i] = updated; await _save(); }
  }
  static Future<void> removeGenerator(String id) async { _generators.removeWhere((g) => g.id == id); await _save(); }

  // ===================== MAINTENANCE =====================

  static List<MaintenanceTask> get tasks => List.unmodifiable(_maintenanceTasks);
  static List<MaintenanceTask> get pendingTasks => _maintenanceTasks.where((t) => !t.completed).toList();
  static List<MaintenanceTask> get overdueTasks => _maintenanceTasks.where((t) => !t.completed && t.scheduledDate.isBefore(DateTime.now())).toList();

  static Future<void> addTask(MaintenanceTask t) async { _maintenanceTasks.add(t); await _save(); }
  static Future<void> updateTask(String id, MaintenanceTask updated) async {
    final i = _maintenanceTasks.indexWhere((t) => t.id == id);
    if (i >= 0) { _maintenanceTasks[i] = updated; await _save(); }
  }
  static Future<void> removeTask(String id) async { _maintenanceTasks.removeWhere((t) => t.id == id); await _save(); }

  // ===================== WATER TREATMENT =====================

  static List<WaterTreatmentLog> get waterLogs => List.unmodifiable(_waterLogs);
  static List<WaterTreatmentLog> get upcomingWaterTasks => _waterLogs.where((w) => w.nextScheduledDate != null && w.nextScheduledDate!.isAfter(DateTime.now())).toList();

  static Future<void> addWaterLog(WaterTreatmentLog w) async { _waterLogs.insert(0, w); await _save(); }
  static Future<void> updateWaterLog(String id, WaterTreatmentLog updated) async {
    final i = _waterLogs.indexWhere((w) => w.id == id);
    if (i >= 0) { _waterLogs[i] = updated; await _save(); }
  }
  static Future<void> removeWaterLog(String id) async { _waterLogs.removeWhere((w) => w.id == id); await _save(); }

  // ===================== TANK DIP LOGS =====================

  static List<TankDipLog> get tankDipLogs => List.unmodifiable(_tankDipLogs);
  static TankDipLog? get latestDip => _tankDipLogs.isNotEmpty ? _tankDipLogs.first : null;
  static List<TankDipLog> get theftAlerts => _tankDipLogs.where((d) => d.isTheftAlert).toList();

  static Future<void> addTankDipLog(TankDipLog d) async { _tankDipLogs.insert(0, d); await _save(); }
  static Future<void> updateTankDipLog(String id, TankDipLog updated) async {
    final i = _tankDipLogs.indexWhere((d) => d.id == id);
    if (i >= 0) { _tankDipLogs[i] = updated; await _save(); }
  }
  static Future<void> removeTankDipLog(String id) async { _tankDipLogs.removeWhere((d) => d.id == id); await _save(); }

  // ===================== GRID TARIFFS =====================

  static List<GridTariffConfig> get gridTariffs => List.unmodifiable(_gridTariffs);
  static GridTariffConfig? get activeTariff => _gridTariffs.isNotEmpty ? _gridTariffs.first : null;

  static Future<void> upsertTariff(GridTariffConfig t) async {
    final i = _gridTariffs.indexWhere((x) => x.band == t.band);
    if (i >= 0) { _gridTariffs[i] = t; } else { _gridTariffs.add(t); }
    await _save();
  }
  static Future<void> removeTariff(String id) async { _gridTariffs.removeWhere((t) => t.id == id); await _save(); }

  // ===================== SEED =====================

  static void _seed() {
    _generators.addAll([
      Generator(id: _id(), name: 'Main DG — Cat C18', model: 'C18', capacityKva: 500, currentRunHours: 12450, currentLoadKva: 320, status: GeneratorStatus.running),
      Generator(id: _id(), name: 'Standby — Perkins', model: '1106A', capacityKva: 250, currentRunHours: 3200, currentLoadKva: 0, status: GeneratorStatus.idle),
      Generator(id: _id(), name: 'Pool House Gen', model: 'FG Wilson', capacityKva: 100, currentRunHours: 890, currentLoadKva: 0, status: GeneratorStatus.maintenance, lastServiceDate: DateTime.now().subtract(const Duration(days: 45))),
      Generator(id: _id(), name: 'Kitchen Backup', model: 'Mikano', capacityKva: 75, currentRunHours: 2100, currentLoadKva: 45, status: GeneratorStatus.fault),
    ]);
    final now = DateTime.now();
    _maintenanceTasks.addAll([
      MaintenanceTask(id: _id(), equipmentName: 'Main DG', description: 'Oil change + filter replace', assignedTo: 'Segun', equipmentType: EquipmentType.generator, priority: MaintenancePriority.urgent, scheduledDate: now.add(const Duration(days: 3))),
      MaintenanceTask(id: _id(), equipmentName: 'AC Chiller 1', description: 'Condenser coil cleaning', assignedTo: 'Emeka', equipmentType: EquipmentType.hvac, priority: MaintenancePriority.important, scheduledDate: now.add(const Duration(days: 7))),
      MaintenanceTask(id: _id(), equipmentName: 'Water Pump — Borehole', description: 'Impeller inspection', assignedTo: 'Segun', equipmentType: EquipmentType.waterPump, scheduledDate: now.subtract(const Duration(days: 2))),
      MaintenanceTask(id: _id(), equipmentName: 'Elevator — Building A', description: 'Annual safety certification', assignedTo: 'LiftCo Ltd', equipmentType: EquipmentType.lift, priority: MaintenancePriority.critical, scheduledDate: now.add(const Duration(days: 14))),
    ]);
    _waterLogs.addAll([
      WaterTreatmentLog(id: _id(), date: now, source: 'RO Plant', phLevel: 7.2, chlorineLevel: 0.5, tdsLevel: 45, treatmentAction: 'backwash', performedBy: 'Segun', notes: 'Routine backwash completed', nextScheduledDate: now.add(const Duration(days: 7)), chemicalUsed: 'Antiscalant', chemicalDosageMl: 50),
      WaterTreatmentLog(id: _id(), date: now.subtract(const Duration(days: 2)), source: 'Swimming Pool', phLevel: 7.8, chlorineLevel: 1.2, treatmentAction: 'chemicalDosing', performedBy: 'Emeka', notes: 'pH high — added acid dose', nextScheduledDate: now.add(const Duration(days: 3)), chemicalUsed: 'Muriatic Acid', chemicalDosageMl: 200),
      WaterTreatmentLog(id: _id(), date: now.subtract(const Duration(days: 7)), source: 'STP', phLevel: 6.9, tdsLevel: 320, treatmentAction: 'sampleTest', performedBy: 'Segun', notes: 'Effluent within NESREA limits', nextScheduledDate: now.add(const Duration(days: 21))),
    ]);
    _tankDipLogs.addAll([
      TankDipLog(id: _id(), date: now, tankName: 'Main Diesel Tank', dipReadingCm: 85, tankCapacityL: 5000, calculatedVolumeL: 4250, expectedVolumeL: 4300, performedBy: 'Segun', notes: 'After 4hr run — expected ~800L used'),
      TankDipLog(id: _id(), date: now.subtract(const Duration(days: 7)), tankName: 'Main Diesel Tank', dipReadingCm: 120, tankCapacityL: 5000, calculatedVolumeL: 6000, performedBy: 'Segun'),
      TankDipLog(id: _id(), date: now.subtract(const Duration(days: 3)), tankName: 'Generator Day Tank', dipReadingCm: 48, tankCapacityL: 500, calculatedVolumeL: 240, expectedVolumeL: 250, performedBy: 'Segun'),
    ]);
    _gridTariffs.addAll([
      GridTariffConfig(id: _id(), band: GridBand.a, hoursPerDay: 20, costPerKwh: 125, label: 'Band A — Premium', description: '20hr+ daily supply — N125/kWh'),
      GridTariffConfig(id: _id(), band: GridBand.b, hoursPerDay: 16, costPerKwh: 95, label: 'Band B — Standard', description: '16hr daily supply — N95/kWh'),
      GridTariffConfig(id: _id(), band: GridBand.c, hoursPerDay: 8, costPerKwh: 60, label: 'Band C — Basic', description: '8hr daily supply — N60/kWh'),
    ]);
  }
}
