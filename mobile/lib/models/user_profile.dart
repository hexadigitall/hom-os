import 'role.dart';

class UserPreferences {
  bool notificationsEnabled;
  bool compactMode;
  String language;

  UserPreferences({
    this.notificationsEnabled = true,
    this.compactMode = false,
    this.language = 'en',
  });

  Map<String, dynamic> toJson() => {
    'notificationsEnabled': notificationsEnabled,
    'compactMode': compactMode,
    'language': language,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> j) => UserPreferences(
    notificationsEnabled: j['notificationsEnabled'] ?? true,
    compactMode: j['compactMode'] ?? false,
    language: j['language'] ?? 'en',
  );
}

/// Zero-Trust, Additive user profile.
///
/// Effective permissions = union(permissions of every roleIds) ∪ customPermissions,
/// granted ONLY while [status] == active.
class UserProfile {
  final String userId;
  String displayName;
  String email;
  String phone;
  String? photoUrl;

  /// Lead/primary role id (kept for display & legacy compatibility).
  String roleId;
  String roleName;

  /// Additive role set (e.g. ['front_desk', 'dept_head']).
  List<String> roleIds;

  /// Departments this user is scoped to.
  List<Department> assignedDepartments;

  /// Ad-hoc extra grants on top of the role union.
  Set<Permission> customPermissions;

  /// Heads-of-department flags.
  Map<Department, bool> isHeadOfDepartment;

  AccountStatus status;

  String hotelId;
  String hotelName;
  UserPreferences preferences;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? lastLoginAt;

  UserProfile({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.roleId,
    this.roleName = '',
    List<String>? roleIds,
    this.assignedDepartments = const [],
    this.customPermissions = const {},
    this.isHeadOfDepartment = const {},
    this.status = AccountStatus.active,
    required this.hotelId,
    this.hotelName = '',
    UserPreferences? preferences,
    required this.createdAt,
    DateTime? updatedAt,
    this.lastLoginAt,
  }) : roleIds = roleIds ?? [roleId],
       preferences = preferences ?? UserPreferences(),
       updatedAt = updatedAt ?? createdAt;

  bool get isAccountActive => status == AccountStatus.active;
  bool get isSuspended => status == AccountStatus.suspended;
  bool get isPending => status == AccountStatus.pending;

  /// Zero-trust union permission check across the additive role set.
  bool hasPermission(Permission permission, List<AppRole> availableRoles) {
    if (!isAccountActive) return false;
    if (customPermissions.contains(permission)) return true;
    for (final id in roleIds) {
      final role = availableRoles.firstWhere(
        (r) => r.id == id,
        orElse: () => AppRole(id: '', name: '', permissions: const {}),
      );
      if (role.has(permission)) return true;
    }
    return false;
  }

  /// Department scoping. Management bypasses the scope.
  bool canAccessDepartment(Department dept) {
    if (roleIds.contains('super_admin') || roleIds.contains('hotel_manager')) {
      return true;
    }
    return assignedDepartments.contains(dept) ||
        (isHeadOfDepartment[dept] ?? false);
  }

  bool get isManagement =>
      roleIds.contains('super_admin') || roleIds.contains('hotel_manager');

  List<Department> get departmentScope {
    final scope = <Department>{...assignedDepartments, ...isHeadOfDepartment.keys};
    return scope.toList();
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
    'roleId': roleId,
    'roleName': roleName,
    'roleIds': roleIds,
    'assignedDepartments': assignedDepartments.map((d) => d.name).toList(),
    'customPermissions': customPermissions.map((p) => p.name).toList(),
    'isHeadOfDepartment': isHeadOfDepartment.map((k, v) => MapEntry(k.name, v)),
    'status': status.name,
    'hotelId': hotelId,
    'hotelName': hotelName,
    'preferences': preferences.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    userId: j['userId'],
    displayName: j['displayName'],
    email: j['email'],
    phone: j['phone'] ?? '',
    photoUrl: j['photoUrl'],
    roleId: j['roleId'] ?? j['roleIds']?[0] ?? '',
    roleName: j['roleName'] ?? '',
    roleIds: (j['roleIds'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
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
    hotelName: j['hotelName'] ?? '',
    preferences: j['preferences'] != null
        ? UserPreferences.fromJson(j['preferences'])
        : UserPreferences(),
    createdAt: DateTime.parse(j['createdAt']),
    updatedAt: j['updatedAt'] != null ? DateTime.parse(j['updatedAt']) : null,
    lastLoginAt: j['lastLoginAt'] != null ? DateTime.parse(j['lastLoginAt']) : null,
  );
}
