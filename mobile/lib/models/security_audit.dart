enum IncidentStatus { open, investigating, resolved }
enum IncidentType { theft, fire, medical, intruder, propertyDamage, noiseComplaint, other }
enum ShiftType { morning, afternoon, night }

class NightAuditLog {
  String id;
  String? closedBy, notes;
  DateTime businessDate;
  double totalRevenue, roomRevenue, fnbRevenue, otherRevenue;
  int cashDropCount;
  double cashDropTotal;
  DateTime? closedAt;
  bool locked;

  NightAuditLog({
    required this.id, this.closedBy, this.notes,
    required this.businessDate,
    this.totalRevenue = 0, this.roomRevenue = 0,
    this.fnbRevenue = 0, this.otherRevenue = 0,
    this.cashDropCount = 0, this.cashDropTotal = 0,
    this.closedAt, this.locked = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'closedBy': closedBy, 'notes': notes,
    'businessDate': businessDate.toIso8601String(),
    'totalRevenue': totalRevenue, 'roomRevenue': roomRevenue,
    'fnbRevenue': fnbRevenue, 'otherRevenue': otherRevenue,
    'cashDropCount': cashDropCount, 'cashDropTotal': cashDropTotal,
    'closedAt': closedAt?.toIso8601String(), 'locked': locked,
  };

  factory NightAuditLog.fromJson(Map<String, dynamic> j) => NightAuditLog(
    id: j['id'], closedBy: j['closedBy'], notes: j['notes'],
    businessDate: DateTime.parse(j['businessDate']),
    totalRevenue: (j['totalRevenue'] as num?)?.toDouble() ?? 0,
    roomRevenue: (j['roomRevenue'] as num?)?.toDouble() ?? 0,
    fnbRevenue: (j['fnbRevenue'] as num?)?.toDouble() ?? 0,
    otherRevenue: (j['otherRevenue'] as num?)?.toDouble() ?? 0,
    cashDropCount: (j['cashDropCount'] as num?)?.toInt() ?? 0,
    cashDropTotal: (j['cashDropTotal'] as num?)?.toDouble() ?? 0,
    closedAt: j['closedAt'] != null ? DateTime.parse(j['closedAt']) : null,
    locked: j['locked'] ?? false,
  );
}

class SecurityIncident {
  String id;
  String? location, description, reportedBy, resolvedBy, notes;
  IncidentType type;
  IncidentStatus status;
  DateTime dateReported;
  DateTime? dateResolved;

  SecurityIncident({
    required this.id, this.location, this.description, this.reportedBy,
    this.resolvedBy, this.notes,
    required this.type, this.status = IncidentStatus.open,
    DateTime? dateReported, this.dateResolved,
  }) : dateReported = dateReported ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id, 'location': location, 'description': description,
    'reportedBy': reportedBy, 'resolvedBy': resolvedBy, 'notes': notes,
    'type': type.name, 'status': status.name,
    'dateReported': dateReported.toIso8601String(),
    'dateResolved': dateResolved?.toIso8601String(),
  };

  factory SecurityIncident.fromJson(Map<String, dynamic> j) => SecurityIncident(
    id: j['id'], location: j['location'], description: j['description'],
    reportedBy: j['reportedBy'], resolvedBy: j['resolvedBy'], notes: j['notes'],
    type: IncidentType.values.byName(j['type'] ?? 'other'),
    status: IncidentStatus.values.byName(j['status'] ?? 'open'),
    dateReported: DateTime.parse(j['dateReported']),
    dateResolved: j['dateResolved'] != null ? DateTime.parse(j['dateResolved']) : null,
  );
}

class VisitorPass {
  String id, visitorName, purpose, hostName;
  String? badgeNumber, notes;
  DateTime checkIn;
  DateTime? checkOut;
  bool active;

  VisitorPass({
    required this.id, required this.visitorName, required this.purpose,
    required this.hostName, this.badgeNumber, this.notes,
    DateTime? checkIn, this.checkOut, this.active = true,
  }) : checkIn = checkIn ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id, 'visitorName': visitorName, 'purpose': purpose,
    'hostName': hostName, 'badgeNumber': badgeNumber, 'notes': notes,
    'checkIn': checkIn.toIso8601String(), 'checkOut': checkOut?.toIso8601String(),
    'active': active,
  };

  factory VisitorPass.fromJson(Map<String, dynamic> j) => VisitorPass(
    id: j['id'], visitorName: j['visitorName'], purpose: j['purpose'],
    hostName: j['hostName'], badgeNumber: j['badgeNumber'], notes: j['notes'],
    checkIn: DateTime.parse(j['checkIn']),
    checkOut: j['checkOut'] != null ? DateTime.parse(j['checkOut']) : null,
    active: j['active'] ?? true,
  );
}

class ShiftHandover {
  String id;
  ShiftType shift;
  String staffName;
  DateTime openedAt;
  DateTime? closedAt;
  String? notes;
  bool isActive;

  ShiftHandover({
    required this.id,
    required this.shift,
    required this.staffName,
    DateTime? openedAt,
    this.closedAt,
    this.notes,
    this.isActive = true,
  }) : openedAt = openedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id, 'shift': shift.name, 'staffName': staffName,
    'openedAt': openedAt.toIso8601String(),
    'closedAt': closedAt?.toIso8601String(),
    'notes': notes, 'isActive': isActive,
  };

  factory ShiftHandover.fromJson(Map<String, dynamic> j) => ShiftHandover(
    id: j['id'],
    shift: ShiftType.values.byName(j['shift'] ?? 'morning'),
    staffName: j['staffName'] ?? '',
    openedAt: DateTime.parse(j['openedAt']),
    closedAt: j['closedAt'] != null ? DateTime.parse(j['closedAt']) : null,
    notes: j['notes'],
    isActive: j['isActive'] ?? true,
  );
}
