import 'package:flutter/material.dart';

// ===================== SCUML =====================

class ScumlTransaction {
  final String id;
  final DateTime date;
  final String guestName;
  final String address;
  final String idType;
  final String idNumber;
  final double amount;
  final String purpose;

  ScumlTransaction({
    required this.id,
    required this.date,
    required this.guestName,
    this.address = '',
    required this.idType,
    required this.idNumber,
    required this.amount,
    this.purpose = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String(), 'guestName': guestName,
    'address': address, 'idType': idType, 'idNumber': idNumber,
    'amount': amount, 'purpose': purpose,
  };

  factory ScumlTransaction.fromJson(Map<String, dynamic> j) => ScumlTransaction(
    id: j['id'], date: DateTime.parse(j['date']),
    guestName: j['guestName'], address: j['address'] ?? '',
    idType: j['idType'], idNumber: j['idNumber'],
    amount: (j['amount'] as num).toDouble(), purpose: j['purpose'] ?? '',
  );

  List<String> toCsvRow() => [
    date.toIso8601String().substring(0, 10),
    guestName, address, idType, idNumber,
    amount.toStringAsFixed(2), purpose,
  ];

  static String csvHeader() => 'Date,Guest Name,Address,ID Type,ID Number,Amount (₦),Purpose';

  ScumlTransaction copyWith({
    String? id, DateTime? date, String? guestName, String? address,
    String? idType, String? idNumber, double? amount, String? purpose,
  }) => ScumlTransaction(
    id: id ?? this.id, date: date ?? this.date,
    guestName: guestName ?? this.guestName, address: address ?? this.address,
    idType: idType ?? this.idType, idNumber: idNumber ?? this.idNumber,
    amount: amount ?? this.amount, purpose: purpose ?? this.purpose,
  );
}

// ===================== STATE CONSUMPTION TAX =====================

class StateTaxConfig {
  String stateName;
  double rate;
  bool appliesToAccommodation;
  bool appliesToFoodAndDrinks;
  bool appliesToOtherServices;

  StateTaxConfig({
    required this.stateName,
    required this.rate,
    this.appliesToAccommodation = true,
    this.appliesToFoodAndDrinks = true,
    this.appliesToOtherServices = false,
  });

  Map<String, dynamic> toJson() => {
    'stateName': stateName, 'rate': rate,
    'appliesToAccommodation': appliesToAccommodation,
    'appliesToFoodAndDrinks': appliesToFoodAndDrinks,
    'appliesToOtherServices': appliesToOtherServices,
  };

  factory StateTaxConfig.fromJson(Map<String, dynamic> j) => StateTaxConfig(
    stateName: j['stateName'], rate: (j['rate'] as num).toDouble(),
    appliesToAccommodation: j['appliesToAccommodation'] ?? true,
    appliesToFoodAndDrinks: j['appliesToFoodAndDrinks'] ?? true,
    appliesToOtherServices: j['appliesToOtherServices'] ?? false,
  );
}

class StateTaxReport {
  final String id;
  final String stateName;
  final double rate;
  final double totalSales;
  final double taxDue;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String status; // pending, filed, paid

  StateTaxReport({
    required this.id,
    required this.stateName,
    required this.rate,
    required this.totalSales,
    required this.taxDue,
    required this.periodStart,
    required this.periodEnd,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'stateName': stateName, 'rate': rate,
    'totalSales': totalSales, 'taxDue': taxDue,
    'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(),
    'status': status,
  };

  factory StateTaxReport.fromJson(Map<String, dynamic> j) => StateTaxReport(
    id: j['id'], stateName: j['stateName'], rate: (j['rate'] as num).toDouble(),
    totalSales: (j['totalSales'] as num).toDouble(),
    taxDue: (j['taxDue'] as num).toDouble(),
    periodStart: DateTime.parse(j['periodStart']),
    periodEnd: DateTime.parse(j['periodEnd']),
    status: j['status'] ?? 'pending',
  );
}

// ===================== NAPTIP =====================

enum NaptipIncidentType {
  trafficking('Suspected Trafficking', Icons.people_outline),
  forcedLabour('Forced Labour', Icons.construction),
  childExploitation('Child Exploitation', Icons.child_care),
  other('Other', Icons.more_horiz);

  final String label;
  final IconData icon;
  const NaptipIncidentType(this.label, this.icon);
}

class NaptipAlert {
  final String id;
  final DateTime date;
  final NaptipIncidentType type;
  final String description;
  final String actionTaken;
  final String reportedTo;
  final String status; // pending, investigated, resolved

  NaptipAlert({
    required this.id,
    required this.date,
    required this.type,
    this.description = '',
    this.actionTaken = '',
    this.reportedTo = '',
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String(), 'type': type.name,
    'description': description, 'actionTaken': actionTaken,
    'reportedTo': reportedTo, 'status': status,
  };

  factory NaptipAlert.fromJson(Map<String, dynamic> j) => NaptipAlert(
    id: j['id'], date: DateTime.parse(j['date']),
    type: NaptipIncidentType.values.byName(j['type']),
    description: j['description'] ?? '', actionTaken: j['actionTaken'] ?? '',
    reportedTo: j['reportedTo'] ?? '', status: j['status'] ?? 'pending',
  );

  NaptipAlert copyWith({
    String? id, DateTime? date, NaptipIncidentType? type,
    String? description, String? actionTaken,
    String? reportedTo, String? status,
  }) => NaptipAlert(
    id: id ?? this.id, date: date ?? this.date, type: type ?? this.type,
    description: description ?? this.description,
    actionTaken: actionTaken ?? this.actionTaken,
    reportedTo: reportedTo ?? this.reportedTo,
    status: status ?? this.status,
  );
}

// ===================== CASH TRANSACTION MONITORING =====================

class CashTransaction {
  final String id;
  final DateTime date;
  final String guestName;
  final String receiptNumber;
  final String paymentMethod; // cash, pos, transfer
  final double amount;
  final String purpose;
  final bool flagged;

  CashTransaction({
    required this.id,
    required this.date,
    required this.guestName,
    this.receiptNumber = '',
    required this.paymentMethod,
    required this.amount,
    this.purpose = '',
    this.flagged = false,
  });

  bool get exceedsThreshold => amount >= 5000000; // ₦5M SCUML threshold
  double get thresholdPercent => (amount / 5000000 * 100).clamp(0, 100);

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String(), 'guestName': guestName,
    'receiptNumber': receiptNumber, 'paymentMethod': paymentMethod,
    'amount': amount, 'purpose': purpose, 'flagged': flagged,
  };

  factory CashTransaction.fromJson(Map<String, dynamic> j) => CashTransaction(
    id: j['id'], date: DateTime.parse(j['date']),
    guestName: j['guestName'], receiptNumber: j['receiptNumber'] ?? '',
    paymentMethod: j['paymentMethod'], amount: (j['amount'] as num).toDouble(),
    purpose: j['purpose'] ?? '', flagged: j['flagged'] ?? false,
  );

  CashTransaction copyWith({
    String? id, DateTime? date, String? guestName, String? receiptNumber,
    String? paymentMethod, double? amount, String? purpose, bool? flagged,
  }) => CashTransaction(
    id: id ?? this.id, date: date ?? this.date,
    guestName: guestName ?? this.guestName,
    receiptNumber: receiptNumber ?? this.receiptNumber,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    amount: amount ?? this.amount, purpose: purpose ?? this.purpose,
    flagged: flagged ?? this.flagged,
  );
}

// ===================== FIRE SERVICE CERTIFICATE =====================

class FireServiceCert {
  final String id;
  final String certificateNumber;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String fireServiceOffice;
  final String status; // valid, expired, pending-renewal
  final double? inspectionScore;

  FireServiceCert({
    required this.id,
    required this.certificateNumber,
    required this.issueDate,
    required this.expiryDate,
    this.fireServiceOffice = '',
    this.status = 'pending-renewal',
    this.inspectionScore,
  });

  bool get isExpired => expiryDate.isBefore(DateTime.now());
  bool get expiresSoon => !isExpired && expiryDate.difference(DateTime.now()).inDays <= 30;

  Map<String, dynamic> toJson() => {
    'id': id, 'certificateNumber': certificateNumber,
    'issueDate': issueDate.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(),
    'fireServiceOffice': fireServiceOffice, 'status': status,
    'inspectionScore': inspectionScore,
  };

  factory FireServiceCert.fromJson(Map<String, dynamic> j) => FireServiceCert(
    id: j['id'], certificateNumber: j['certificateNumber'],
    issueDate: DateTime.parse(j['issueDate']),
    expiryDate: DateTime.parse(j['expiryDate']),
    fireServiceOffice: j['fireServiceOffice'] ?? '',
    status: j['status'] ?? 'pending-renewal',
    inspectionScore: (j['inspectionScore'] as num?)?.toDouble(),
  );

  FireServiceCert copyWith({
    String? id, String? certificateNumber, DateTime? issueDate,
    DateTime? expiryDate, String? fireServiceOffice, String? status,
    double? inspectionScore,
  }) => FireServiceCert(
    id: id ?? this.id,
    certificateNumber: certificateNumber ?? this.certificateNumber,
    issueDate: issueDate ?? this.issueDate,
    expiryDate: expiryDate ?? this.expiryDate,
    fireServiceOffice: fireServiceOffice ?? this.fireServiceOffice,
    status: status ?? this.status,
    inspectionScore: inspectionScore ?? this.inspectionScore,
  );
}

// ===================== LGA HEALTH & SAFETY =====================

class LgaInspection {
  final String id;
  final DateTime inspectionDate;
  final String inspector;
  final String agency;
  final String certificateNumber;
  final DateTime? expiryDate;
  final double score; // 0-100
  final String status; // valid, expired, pending-renewal
  final List<String> passedItems;
  final List<String> failedItems;

  LgaInspection({
    required this.id,
    required this.inspectionDate,
    this.inspector = '',
    this.agency = '',
    required this.certificateNumber,
    this.expiryDate,
    this.score = 0,
    this.status = 'pending-renewal',
    this.passedItems = const [],
    this.failedItems = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'inspectionDate': inspectionDate.toIso8601String(),
    'inspector': inspector, 'agency': agency,
    'certificateNumber': certificateNumber,
    'expiryDate': expiryDate?.toIso8601String(),
    'score': score, 'status': status,
  };

  factory LgaInspection.fromJson(Map<String, dynamic> j) => LgaInspection(
    id: j['id'], inspectionDate: DateTime.parse(j['inspectionDate']),
    inspector: j['inspector'] ?? '', agency: j['agency'] ?? '',
    certificateNumber: j['certificateNumber'],
    expiryDate: j['expiryDate'] != null ? DateTime.parse(j['expiryDate']) : null,
    score: (j['score'] as num?)?.toDouble() ?? 0,
    status: j['status'] ?? 'pending-renewal',
  );

  LgaInspection copyWith({
    String? id, DateTime? inspectionDate, String? inspector,
    String? agency, String? certificateNumber, DateTime? expiryDate,
    double? score, String? status, List<String>? passedItems, List<String>? failedItems,
  }) => LgaInspection(
    id: id ?? this.id, inspectionDate: inspectionDate ?? this.inspectionDate,
    inspector: inspector ?? this.inspector, agency: agency ?? this.agency,
    certificateNumber: certificateNumber ?? this.certificateNumber,
    expiryDate: expiryDate ?? this.expiryDate, score: score ?? this.score,
    status: status ?? this.status,
    passedItems: passedItems ?? this.passedItems,
    failedItems: failedItems ?? this.failedItems,
  );
}
