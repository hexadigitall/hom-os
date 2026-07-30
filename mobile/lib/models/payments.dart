class VirtualAccount {
  String id;
  String bookingId;
  String guestName;
  String bankName;
  String accountNumber;
  String accountName;
  int amount;
  String status; // pending | active | matched | expired
  DateTime createdAt;
  DateTime? expiresAt;

  VirtualAccount({
    required this.id,
    required this.bookingId,
    required this.guestName,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isActive => status == 'active';
  bool get isMatched => status == 'matched';

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'guestName': guestName,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'accountName': accountName,
    'amount': amount,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
  };

  factory VirtualAccount.fromJson(Map<String, dynamic> j) => VirtualAccount(
    id: j['id'],
    bookingId: j['bookingId'],
    guestName: j['guestName'],
    bankName: j['bankName'],
    accountNumber: j['accountNumber'],
    accountName: j['accountName'],
    amount: j['amount'],
    status: j['status'],
    createdAt: DateTime.parse(j['createdAt']),
    expiresAt: j['expiresAt'] != null ? DateTime.parse(j['expiresAt']) : null,
  );
}

class PosTerminal {
  String id;
  String terminalId;
  String bankName;
  String merchantCode;
  String status; // active | inactive
  DateTime addedAt;

  PosTerminal({
    required this.id,
    required this.terminalId,
    required this.bankName,
    required this.merchantCode,
    required this.status,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'terminalId': terminalId,
    'bankName': bankName,
    'merchantCode': merchantCode,
    'status': status,
    'addedAt': addedAt.toIso8601String(),
  };

  factory PosTerminal.fromJson(Map<String, dynamic> j) => PosTerminal(
    id: j['id'],
    terminalId: j['terminalId'],
    bankName: j['bankName'],
    merchantCode: j['merchantCode'],
    status: j['status'],
    addedAt: DateTime.parse(j['addedAt']),
  );
}

class PosSettlement {
  String id;
  String terminalId;
  String terminalRef;
  int amount;
  DateTime date;
  String status; // pending | settled | flagged
  String? note;

  PosSettlement({
    required this.id,
    required this.terminalId,
    required this.terminalRef,
    required this.amount,
    required this.date,
    required this.status,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'terminalId': terminalId,
    'terminalRef': terminalRef,
    'amount': amount,
    'date': date.toIso8601String(),
    'status': status,
    'note': note,
  };

  factory PosSettlement.fromJson(Map<String, dynamic> j) => PosSettlement(
    id: j['id'],
    terminalId: j['terminalId'],
    terminalRef: j['terminalRef'],
    amount: j['amount'],
    date: DateTime.parse(j['date']),
    status: j['status'],
    note: j['note'],
  );
}
