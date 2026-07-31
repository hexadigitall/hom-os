import 'role.dart';

class InviteCode {
  final String code;
  final String roleId;
  final String roleName;

  /// Department scope baked into the invite (multi-department heads, etc.).
  List<Department> departments;

  /// Whether the invitee is intended to head their assigned department(s).
  bool isHead;

  final String hotelId;
  final String hotelName;
  final DateTime createdAt;
  String? usedByUserId;
  DateTime? usedAt;

  InviteCode({
    required this.code,
    required this.roleId,
    required this.roleName,
    this.departments = const [],
    this.isHead = false,
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
    'departments': departments.map((d) => d.name).toList(),
    'isHead': isHead,
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
    departments: (j['departments'] as List<dynamic>? ?? [])
        .map((e) => Department.values.asNameMap()[e.toString()] ?? Department.management)
        .toList(),
    isHead: j['isHead'] == true,
    hotelId: j['hotelId'],
    hotelName: j['hotelName'] ?? '',
    createdAt: DateTime.parse(j['createdAt']),
    usedByUserId: j['usedByUserId'],
    usedAt: j['usedAt'] != null ? DateTime.parse(j['usedAt']) : null,
  );
}
