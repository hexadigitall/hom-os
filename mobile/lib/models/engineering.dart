enum GeneratorStatus { running, idle, maintenance, fault }
enum EquipmentType { generator, hvac, lift, waterPump, waterTreatment, electrical, plumbing, other }
enum MaintenancePriority { routine, important, urgent, critical }
enum GridBand { a, b, c }

class Generator {
  String id, name;
  String? model, location;
  double capacityKva;
  double currentRunHours;
  double lastOilChangeHours;
  double currentLoadKva;
  GeneratorStatus status;
  DateTime? lastServiceDate;

  Generator({
    required this.id, required this.name, this.model, this.location,
    required this.capacityKva, this.currentRunHours = 0,
    this.lastOilChangeHours = 0, this.currentLoadKva = 0,
    this.status = GeneratorStatus.idle, this.lastServiceDate,
  });

  double get loadPct => capacityKva > 0 ? (currentLoadKva / capacityKva * 100).clamp(0, 100) : 0;
  double get fuelRateLph => capacityKva * 0.055;
  double get efficiencyLph => currentLoadKva > 0 ? fuelRateLph * (currentLoadKva / capacityKva) : 0;
  String get statusLabel => status.name;

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'model': model, 'location': location,
    'capacityKva': capacityKva, 'currentRunHours': currentRunHours,
    'lastOilChangeHours': lastOilChangeHours, 'currentLoadKva': currentLoadKva,
    'status': status.name,
    'lastServiceDate': lastServiceDate?.toIso8601String(),
  };

  factory Generator.fromJson(Map<String, dynamic> j) => Generator(
    id: j['id'], name: j['name'], model: j['model'], location: j['location'],
    capacityKva: (j['capacityKva'] as num).toDouble(),
    currentRunHours: (j['currentRunHours'] as num?)?.toDouble() ?? 0,
    lastOilChangeHours: (j['lastOilChangeHours'] as num?)?.toDouble() ?? 0,
    currentLoadKva: (j['currentLoadKva'] as num?)?.toDouble() ?? 0,
    status: GeneratorStatus.values.byName(j['status'] ?? 'idle'),
    lastServiceDate: j['lastServiceDate'] != null ? DateTime.parse(j['lastServiceDate']) : null,
  );
}

class MaintenanceTask {
  String id, equipmentName, description, assignedTo;
  EquipmentType equipmentType;
  MaintenancePriority priority;
  DateTime scheduledDate;
  DateTime? completedDate;
  bool completed;

  MaintenanceTask({
    required this.id, required this.equipmentName, this.description = '',
    required this.assignedTo, required this.equipmentType,
    this.priority = MaintenancePriority.routine,
    required this.scheduledDate, this.completedDate, this.completed = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'equipmentName': equipmentName, 'description': description,
    'assignedTo': assignedTo, 'equipmentType': equipmentType.name,
    'priority': priority.name, 'scheduledDate': scheduledDate.toIso8601String(),
    'completedDate': completedDate?.toIso8601String(), 'completed': completed,
  };

  factory MaintenanceTask.fromJson(Map<String, dynamic> j) => MaintenanceTask(
    id: j['id'], equipmentName: j['equipmentName'],
    description: j['description'] ?? '', assignedTo: j['assignedTo'],
    equipmentType: EquipmentType.values.byName(j['equipmentType']),
    priority: MaintenancePriority.values.byName(j['priority'] ?? 'routine'),
    scheduledDate: DateTime.parse(j['scheduledDate']),
    completedDate: j['completedDate'] != null ? DateTime.parse(j['completedDate']) : null,
    completed: j['completed'] ?? false,
  );
}

class WaterTreatmentLog {
  String id;
  DateTime date;
  String source;
  double phLevel;
  double? chlorineLevel, tdsLevel;
  String treatmentAction;
  String? notes, performedBy;
  DateTime? nextScheduledDate;
  String? chemicalUsed;
  double? chemicalDosageMl;

  WaterTreatmentLog({
    required this.id, required this.date, required this.source,
    this.phLevel = 7.0, this.chlorineLevel, this.tdsLevel,
    required this.treatmentAction, this.notes, this.performedBy,
    this.nextScheduledDate, this.chemicalUsed, this.chemicalDosageMl,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String(), 'source': source,
    'phLevel': phLevel, 'chlorineLevel': chlorineLevel, 'tdsLevel': tdsLevel,
    'treatmentAction': treatmentAction, 'notes': notes, 'performedBy': performedBy,
    'nextScheduledDate': nextScheduledDate?.toIso8601String(),
    'chemicalUsed': chemicalUsed, 'chemicalDosageMl': chemicalDosageMl,
  };

  factory WaterTreatmentLog.fromJson(Map<String, dynamic> j) => WaterTreatmentLog(
    id: j['id'], date: DateTime.parse(j['date']), source: j['source'],
    phLevel: (j['phLevel'] as num?)?.toDouble() ?? 7.0,
    chlorineLevel: (j['chlorineLevel'] as num?)?.toDouble(),
    tdsLevel: (j['tdsLevel'] as num?)?.toDouble(),
    treatmentAction: j['treatmentAction'], notes: j['notes'],
    performedBy: j['performedBy'],
    nextScheduledDate: j['nextScheduledDate'] != null ? DateTime.parse(j['nextScheduledDate']) : null,
    chemicalUsed: j['chemicalUsed'],
    chemicalDosageMl: (j['chemicalDosageMl'] as num?)?.toDouble(),
  );
}

class TankDipLog {
  String id;
  DateTime date;
  String tankName;
  double dipReadingCm;
  double tankCapacityL;
  double calculatedVolumeL;
  double? expectedVolumeL;
  String? notes, performedBy;

  TankDipLog({
    required this.id, required this.date, required this.tankName,
    required this.dipReadingCm, required this.tankCapacityL,
    required this.calculatedVolumeL, this.expectedVolumeL,
    this.notes, this.performedBy,
  });

  double? get varianceL => expectedVolumeL != null ? calculatedVolumeL - expectedVolumeL! : null;
  double? get variancePct => expectedVolumeL != null && expectedVolumeL! > 0 ? (varianceL! / expectedVolumeL! * 100) : null;
  bool get isTheftAlert => variancePct != null && variancePct! < -10;

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String(), 'tankName': tankName,
    'dipReadingCm': dipReadingCm, 'tankCapacityL': tankCapacityL,
    'calculatedVolumeL': calculatedVolumeL, 'expectedVolumeL': expectedVolumeL,
    'notes': notes, 'performedBy': performedBy,
  };

  factory TankDipLog.fromJson(Map<String, dynamic> j) => TankDipLog(
    id: j['id'], date: DateTime.parse(j['date']), tankName: j['tankName'],
    dipReadingCm: (j['dipReadingCm'] as num).toDouble(),
    tankCapacityL: (j['tankCapacityL'] as num).toDouble(),
    calculatedVolumeL: (j['calculatedVolumeL'] as num).toDouble(),
    expectedVolumeL: (j['expectedVolumeL'] as num?)?.toDouble(),
    notes: j['notes'], performedBy: j['performedBy'],
  );
}

class GridTariffConfig {
  String id;
  GridBand band;
  double hoursPerDay;
  double costPerKwh;
  String label;
  String description;

  GridTariffConfig({
    required this.id, required this.band, required this.hoursPerDay,
    required this.costPerKwh, required this.label, this.description = '',
  });

  double get dailyCost => hoursPerDay * costPerKwh;
  double get monthlyCost => dailyCost * 30;
  String get bandName => 'Band ${band.name.toUpperCase()}';

  Map<String, dynamic> toJson() => {
    'id': id, 'band': band.name, 'hoursPerDay': hoursPerDay,
    'costPerKwh': costPerKwh, 'label': label, 'description': description,
  };

  factory GridTariffConfig.fromJson(Map<String, dynamic> j) => GridTariffConfig(
    id: j['id'], band: GridBand.values.byName(j['band']),
    hoursPerDay: (j['hoursPerDay'] as num).toDouble(),
    costPerKwh: (j['costPerKwh'] as num).toDouble(),
    label: j['label'], description: j['description'] ?? '',
  );
}
