class InviteCode {
  final String code;
  final String roleId;
  final String roleName;
  final String hotelId;
  final String hotelName;
  final DateTime createdAt;
  String? usedByUserId;
  DateTime? usedAt;

  InviteCode({
    required this.code,
    required this.roleId,
    required this.roleName,
    required this.hotelId,
    required this.hotelName,
    required this.createdAt,
    this.usedByUserId,
    this.usedAt,
  });

  bool get isExpired => createdAt.add(const Duration(days: 7)).isBefore(DateTime.now());
  bool get isUsed => usedByUserId != null;
  bool get isValid => !isExpired && !isUsed;

  Map<String, dynamic> toJson() => {
    'code': code,
    'roleId': roleId,
    'roleName': roleName,
    'hotelId': hotelId,
    'hotelName': hotelName,
    'createdAt': createdAt.toIso8601String(),
    'usedByUserId': usedByUserId,
    'usedAt': usedAt?.toIso8601String(),
  };

  factory InviteCode.fromJson(Map<String, dynamic> j) => InviteCode(
    code: j['code'],
    roleId: j['roleId'],
    roleName: j['roleName'] ?? '',
    hotelId: j['hotelId'],
    hotelName: j['hotelName'] ?? '',
    createdAt: DateTime.parse(j['createdAt']),
    usedByUserId: j['usedByUserId'],
    usedAt: j['usedAt'] != null ? DateTime.parse(j['usedAt']) : null,
  );
}
