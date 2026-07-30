class DailyRevenue {
  final DateTime date;
  final int roomsAvailable;
  final int roomsSold;
  final int walkIns;
  final double totalRevenue;

  DailyRevenue({
    required this.date,
    this.roomsAvailable = 12,
    required this.roomsSold,
    this.walkIns = 0,
    required this.totalRevenue,
  });

  double get occupancyPct => roomsAvailable > 0
      ? (roomsSold / roomsAvailable * 100).clamp(0, 100)
      : 0;
  double get adr => roomsSold > 0 ? totalRevenue / roomsSold : 0;
  double get revpar => roomsAvailable > 0 ? totalRevenue / roomsAvailable : 0;
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(), 'roomsAvailable': roomsAvailable,
    'roomsSold': roomsSold, 'walkIns': walkIns, 'totalRevenue': totalRevenue,
  };
  factory DailyRevenue.fromJson(Map<String, dynamic> j) => DailyRevenue(
    date: DateTime.parse(j['date']), roomsAvailable: j['roomsAvailable'] ?? 12,
    roomsSold: j['roomsSold'], walkIns: j['walkIns'] ?? 0,
    totalRevenue: (j['totalRevenue'] as num).toDouble(),
  );
}

class CashDrop {
  String id;
  DateTime date;
  String shift;
  double expectedAmount;
  double actualAmount;
  String notes;
  CashDropStatus status;

  CashDrop({
    required this.id,
    required this.date,
    required this.shift,
    required this.expectedAmount,
    required this.actualAmount,
    this.notes = '',
    this.status = CashDropStatus.matched,
  });

  double get difference => actualAmount - expectedAmount;
  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String(), 'shift': shift,
    'expectedAmount': expectedAmount, 'actualAmount': actualAmount,
    'notes': notes, 'status': status.name,
  };
  factory CashDrop.fromJson(Map<String, dynamic> j) => CashDrop(
    id: j['id'], date: DateTime.parse(j['date']), shift: j['shift'],
    expectedAmount: (j['expectedAmount'] as num).toDouble(),
    actualAmount: (j['actualAmount'] as num).toDouble(),
    notes: j['notes'] ?? '', status: CashDropStatus.values.byName(j['status'] ?? 'matched'),
  );
}

enum CashDropStatus { matched, mismatched, pending }

class HousekeepingLoss {
  String id;
  DateTime date;
  String item;
  String category;
  int quantity;
  double unitCost;
  String roomNumber;
  String notes;

  HousekeepingLoss({
    required this.id,
    required this.date,
    required this.item,
    required this.category,
    required this.quantity,
    required this.unitCost,
    this.roomNumber = '',
    this.notes = '',
  });

  double get totalCost => quantity * unitCost;
  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String(), 'item': item,
    'category': category, 'quantity': quantity, 'unitCost': unitCost,
    'roomNumber': roomNumber, 'notes': notes,
  };
  factory HousekeepingLoss.fromJson(Map<String, dynamic> j) => HousekeepingLoss(
    id: j['id'], date: DateTime.parse(j['date']), item: j['item'],
    category: j['category'], quantity: j['quantity'],
    unitCost: (j['unitCost'] as num).toDouble(),
    roomNumber: j['roomNumber'] ?? '', notes: j['notes'] ?? '',
  );
}
