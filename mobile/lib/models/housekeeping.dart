enum LaundryStatus { received, washing, drying, ironing, ready, delivered }
enum LaundryType { selfService, guestCharge, dryCleanOnly }
enum LostFoundCategory { electronics, clothing, jewelry, documents, luggage, keys, other }
enum LinenCategory { bedsheet, towel, pillowcase, duvet, mattressProtector, bathrobe }
enum LinenCondition { new_, good, stained, torn, condemned }
enum HousekeepingPriority { routine, deepClean, turndown, vipSetup, maintenanceRequest }

class LaundryItem {
  String id, guestName, roomNumber, itemDescription;
  LaundryStatus status;
  LaundryType type;
  DateTime receivedDate;
  DateTime? readyDate;
  double? chargeAmount;

  LaundryItem({
    required this.id, required this.guestName, required this.roomNumber,
    required this.itemDescription, this.status = LaundryStatus.received,
    this.type = LaundryType.guestCharge, DateTime? receivedDate,
    this.readyDate, this.chargeAmount,
  }) : receivedDate = receivedDate ?? DateTime.now();

  String get statusLabel => status.name;

  Map<String, dynamic> toJson() => {
    'id': id, 'guestName': guestName, 'roomNumber': roomNumber,
    'itemDescription': itemDescription, 'status': status.name,
    'type': type.name, 'receivedDate': receivedDate.toIso8601String(),
    'readyDate': readyDate?.toIso8601String(), 'chargeAmount': chargeAmount,
  };

  factory LaundryItem.fromJson(Map<String, dynamic> j) => LaundryItem(
    id: j['id'], guestName: j['guestName'], roomNumber: j['roomNumber'],
    itemDescription: j['itemDescription'],
    status: LaundryStatus.values.byName(j['status'] ?? 'received'),
    type: LaundryType.values.byName(j['type'] ?? 'guestCharge'),
    receivedDate: DateTime.parse(j['receivedDate']),
    readyDate: j['readyDate'] != null ? DateTime.parse(j['readyDate']) : null,
    chargeAmount: (j['chargeAmount'] as num?)?.toDouble(),
  );
}

class LostFoundItem {
  String id, itemName, foundBy, locationFound;
  String? guestName, claimedBy, notes;
  LostFoundCategory category;
  DateTime foundDate;
  DateTime? claimedDate;
  bool returned;

  LostFoundItem({
    required this.id, required this.itemName, required this.foundBy,
    required this.locationFound, this.guestName, this.claimedBy, this.notes,
    required this.category, DateTime? foundDate, this.claimedDate,
    this.returned = false,
  }) : foundDate = foundDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id, 'itemName': itemName, 'foundBy': foundBy,
    'locationFound': locationFound, 'guestName': guestName,
    'claimedBy': claimedBy, 'notes': notes, 'category': category.name,
    'foundDate': foundDate.toIso8601String(), 'claimedDate': claimedDate?.toIso8601String(),
    'returned': returned,
  };

  factory LostFoundItem.fromJson(Map<String, dynamic> j) => LostFoundItem(
    id: j['id'], itemName: j['itemName'], foundBy: j['foundBy'],
    locationFound: j['locationFound'], guestName: j['guestName'],
    claimedBy: j['claimedBy'], notes: j['notes'],
    category: LostFoundCategory.values.byName(j['category'] ?? 'other'),
    foundDate: DateTime.parse(j['foundDate']),
    claimedDate: j['claimedDate'] != null ? DateTime.parse(j['claimedDate']) : null,
    returned: j['returned'] ?? false,
  );
}

class LinenDamage {
  String id, itemName;
  String? roomNumber, notes;
  LinenCategory category;
  LinenCondition condition;
  DateTime dateRecorded;
  int quantity;
  double? replacementCost;

  LinenDamage({
    required this.id, required this.itemName, this.roomNumber, this.notes,
    required this.category, this.condition = LinenCondition.good,
    DateTime? dateRecorded, this.quantity = 1, this.replacementCost,
  }) : dateRecorded = dateRecorded ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id, 'itemName': itemName, 'roomNumber': roomNumber, 'notes': notes,
    'category': category.name, 'condition': condition.name,
    'dateRecorded': dateRecorded.toIso8601String(), 'quantity': quantity,
    'replacementCost': replacementCost,
  };

  factory LinenDamage.fromJson(Map<String, dynamic> j) => LinenDamage(
    id: j['id'], itemName: j['itemName'], roomNumber: j['roomNumber'],
    notes: j['notes'], category: LinenCategory.values.byName(j['category'] ?? 'bedsheet'),
    condition: LinenCondition.values.byName(j['condition'] ?? 'good'),
    dateRecorded: DateTime.parse(j['dateRecorded']),
    quantity: (j['quantity'] as num?)?.toInt() ?? 1,
    replacementCost: (j['replacementCost'] as num?)?.toDouble(),
  );
}

class HousekeepingTask {
  String id, roomNumber, assignedTo;
  String? notes;
  HousekeepingPriority priority;
  DateTime scheduledDate;
  DateTime? completedDate;
  bool completed;

  HousekeepingTask({
    required this.id, required this.roomNumber, required this.assignedTo,
    this.notes, this.priority = HousekeepingPriority.routine,
    DateTime? scheduledDate, this.completedDate, this.completed = false,
  }) : scheduledDate = scheduledDate ?? DateTime.now();

  String get priorityLabel => priority.name;

  Map<String, dynamic> toJson() => {
    'id': id, 'roomNumber': roomNumber, 'assignedTo': assignedTo,
    'notes': notes, 'priority': priority.name,
    'scheduledDate': scheduledDate.toIso8601String(),
    'completedDate': completedDate?.toIso8601String(),
    'completed': completed,
  };

  factory HousekeepingTask.fromJson(Map<String, dynamic> j) => HousekeepingTask(
    id: j['id'], roomNumber: j['roomNumber'], assignedTo: j['assignedTo'],
    notes: j['notes'], priority: HousekeepingPriority.values.byName(j['priority'] ?? 'routine'),
    scheduledDate: DateTime.parse(j['scheduledDate']),
    completedDate: j['completedDate'] != null ? DateTime.parse(j['completedDate']) : null,
    completed: j['completed'] ?? false,
  );
}
