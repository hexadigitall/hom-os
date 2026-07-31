import 'dart:convert';
import 'role.dart';

class HotelUser {
  final String userId;
  String name;
  String email;
  String phone;
  String passwordHash;

  /// Lead/primary role id (display + legacy).
  String roleId;

  /// Additive role set.
  List<String> roleIds;

  List<Department> assignedDepartments;
  Set<Permission> customPermissions;
  Map<Department, bool> isHeadOfDepartment;
  AccountStatus status;

  String hotelId;
  String hotelName;

  /// Firebase Auth UID backing this account (set after first cloud sync) —
  /// used so admin edits can reach the Firestore role doc for real-time sync.
  String? firebaseUid;

  final DateTime createdAt;

  HotelUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.roleId,
    List<String>? roleIds,
    this.assignedDepartments = const [],
    this.customPermissions = const {},
    this.isHeadOfDepartment = const {},
    this.status = AccountStatus.active,
    required this.hotelId,
    required this.hotelName,
    this.firebaseUid,
    required this.createdAt,
  }) : roleIds = roleIds ?? [roleId];

  bool get isAccountActive => status == AccountStatus.active;
  bool get isSuspended => status == AccountStatus.suspended;
  bool get isPending => status == AccountStatus.pending;

  bool canAccessDepartment(Department dept) {
    if (roleIds.contains('super_admin') || roleIds.contains('hotel_manager')) {
      return true;
    }
    return assignedDepartments.contains(dept) ||
        (isHeadOfDepartment[dept] ?? false);
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'email': email,
    'phone': phone,
    'passwordHash': passwordHash,
    'roleId': roleId,
    'roleIds': roleIds,
    'assignedDepartments': assignedDepartments.map((d) => d.name).toList(),
    'customPermissions': customPermissions.map((p) => p.name).toList(),
    'isHeadOfDepartment': isHeadOfDepartment.map((k, v) => MapEntry(k.name, v)),
    'status': status.name,
    'hotelId': hotelId,
    'hotelName': hotelName,
    'firebaseUid': firebaseUid,
    'createdAt': createdAt.toIso8601String(),
  };

  factory HotelUser.fromJson(Map<String, dynamic> j) => HotelUser(
    userId: j['userId'],
    name: j['name'],
    email: j['email'],
    phone: j['phone'] ?? '',
    passwordHash: j['passwordHash'],
    roleId: j['roleId'] ?? j['roleIds']?[0] ?? '',
    roleIds: (j['roleIds'] as List<dynamic>? ?? [j['roleId']])
        .whereType<String>()
        .toList(),
    assignedDepartments: (j['assignedDepartments'] as List<dynamic>? ?? [])
        .map((e) => Department.values.asNameMap()[e.toString()] ?? Department.management)
        .toList(),
    customPermissions: (j['customPermissions'] as List<dynamic>? ?? [])
        .map((e) => Permission.values.asNameMap()[e.toString()])
        .whereType<Permission>()
        .toSet(),
    isHeadOfDepartment: (j['isHeadOfDepartment'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(
          Department.values.asNameMap()[k] ?? Department.management,
          v == true,
        )),
    status: AccountStatus.values.asNameMap()[j['status']] ?? AccountStatus.active,
    hotelId: j['hotelId'],
    hotelName: j['hotelName'],
    firebaseUid: j['firebaseUid']?.toString(),
    createdAt: DateTime.parse(j['createdAt']),
  );
}

String _hashPassword(String password) => base64Encode(utf8.encode(password));
bool verifyPassword(String password, String hash) => _hashPassword(password) == hash;
