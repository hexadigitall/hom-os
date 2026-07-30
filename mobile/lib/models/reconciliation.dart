class BankTransaction {
  String id;
  DateTime date;
  String description;
  double amount;
  String? reference;
  double? balance;
  String source;
  String type; // 'CR' or 'DR'

  BankTransaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    this.reference,
    this.balance,
    this.source = 'Bank Statement',
    this.type = 'DR',
  });

  bool get isCredit => type == 'CR';
  bool get isDebit => type == 'DR';
  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String(), 'description': description,
    'amount': amount, 'reference': reference, 'balance': balance,
    'source': source, 'type': type,
  };
  factory BankTransaction.fromJson(Map<String, dynamic> j) => BankTransaction(
    id: j['id'], date: DateTime.parse(j['date']),
    description: j['description'], amount: (j['amount'] as num).toDouble(),
    reference: j['reference'], balance: (j['balance'] as num?)?.toDouble(),
    source: j['source'] ?? 'Bank Statement', type: j['type'] ?? 'DR',
  );
}

enum MatchEntityType { booking, expenditure }

class ReconciliationMatch {
  String id;
  String bankTransactionId;
  MatchEntityType entityType;
  String entityId;
  String entityLabel;
  double entityAmount;
  double matchedAmount;
  double confidence;
  bool isManual;
  DateTime matchedAt;

  ReconciliationMatch({
    required this.id,
    required this.bankTransactionId,
    required this.entityType,
    required this.entityId,
    required this.entityLabel,
    required this.entityAmount,
    required this.matchedAmount,
    this.confidence = 0.0,
    this.isManual = false,
    DateTime? matchedAt,
  }) : matchedAt = matchedAt ?? DateTime.now();
  Map<String, dynamic> toJson() => {
    'id': id, 'bankTransactionId': bankTransactionId,
    'entityType': entityType.name, 'entityId': entityId,
    'entityLabel': entityLabel, 'entityAmount': entityAmount,
    'matchedAmount': matchedAmount, 'confidence': confidence,
    'isManual': isManual, 'matchedAt': matchedAt.toIso8601String(),
  };
  factory ReconciliationMatch.fromJson(Map<String, dynamic> j) => ReconciliationMatch(
    id: j['id'], bankTransactionId: j['bankTransactionId'],
    entityType: MatchEntityType.values.byName(j['entityType']),
    entityId: j['entityId'], entityLabel: j['entityLabel'],
    entityAmount: (j['entityAmount'] as num).toDouble(),
    matchedAmount: (j['matchedAmount'] as num).toDouble(),
    confidence: (j['confidence'] as num?)?.toDouble() ?? 0.0,
    isManual: j['isManual'] ?? false,
    matchedAt: j['matchedAt'] != null ? DateTime.parse(j['matchedAt']) : null,
  );
}

class SplitPayment {
  String id;
  String bankTransactionId;
  List<SplitAllocation> allocations;

  SplitPayment({
    required this.id,
    required this.bankTransactionId,
    required this.allocations,
  });
  Map<String, dynamic> toJson() => {
    'id': id, 'bankTransactionId': bankTransactionId,
    'allocations': allocations.map((a) => a.toJson()).toList(),
  };
  factory SplitPayment.fromJson(Map<String, dynamic> j) => SplitPayment(
    id: j['id'], bankTransactionId: j['bankTransactionId'],
    allocations: (j['allocations'] as List).map((a) => SplitAllocation.fromJson(a)).toList(),
  );
}

class SplitAllocation {
  MatchEntityType entityType;
  String entityId;
  String entityLabel;
  double amount;

  SplitAllocation({
    required this.entityType,
    required this.entityId,
    required this.entityLabel,
    required this.amount,
  });
  Map<String, dynamic> toJson() => {
    'entityType': entityType.name, 'entityId': entityId,
    'entityLabel': entityLabel, 'amount': amount,
  };
  factory SplitAllocation.fromJson(Map<String, dynamic> j) => SplitAllocation(
    entityType: MatchEntityType.values.byName(j['entityType']),
    entityId: j['entityId'], entityLabel: j['entityLabel'],
    amount: (j['amount'] as num).toDouble(),
  );
}
