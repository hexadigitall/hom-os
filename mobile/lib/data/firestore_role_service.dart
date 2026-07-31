import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_store.dart';
import '../models/role.dart';

/// Cloud (Firestore) role document — the real-time source of truth for
/// assignments. Zero-trust: an unknown/missing role NEVER falls back to an
/// admin role; it resolves to a pending (unassigned) account instead.
class FirestoreRoleService {
  static final _firestore = FirebaseFirestore.instance;

  static String _permissionName(Permission p) => p.name;
  static String _departmentName(Department d) => d.name;

  static Future<void> writeUserRole({
    required String uid,
    required String userId,
    List<String> roleIds = const [],
    required String userName,
    required String hotelId,
    required String email,
    List<Department> assignedDepartments = const [],
    Set<Permission> customPermissions = const {},
    Map<Department, bool> isHeadOfDepartment = const {},
    AccountStatus status = AccountStatus.active,
  }) async {
    await _firestore.collection('user_roles').doc(uid).set({
      'userId': userId,
      'roleIds': roleIds,
      'userName': userName,
      'hotelId': hotelId,
      'email': email,
      'assignedDepartments': assignedDepartments.map(_departmentName).toList(),
      'customPermissions': customPermissions.map(_permissionName).toList(),
      'isHeadOfDepartment':
          isHeadOfDepartment.map((k, v) => MapEntry(_departmentName(k), v)),
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>?> readUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('user_roles').doc(uid).get();
      if (doc.exists) return doc.data();
    } catch (_) {}
    return null;
  }

  /// Subscribe to live changes for [uid]. Emits the updated role doc map,
  /// or `null` when the document no longer exists (account removed/cleared).
  static Stream<Map<String, dynamic>?> listen(String uid) {
    return _firestore
        .collection('user_roles')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }

  static List<String> _stringList(dynamic v) =>
      (v as List<dynamic>? ?? []).map((e) => e.toString()).toList();

  static List<Department> _departments(dynamic v) => _stringList(v)
      .map((e) => Department.values.asNameMap()[e])
      .whereType<Department>()
      .toList();

  static Set<Permission> _permissions(dynamic v) => _stringList(v)
      .map((e) => Permission.values.asNameMap()[e])
      .whereType<Permission>()
      .toSet();

  static Map<Department, bool> _heads(dynamic v) {
    final raw = v as Map<String, dynamic>? ?? {};
    return raw.map((k, val) => MapEntry(
      Department.values.asNameMap()[k] ?? Department.management,
      val == true,
    ));
  }

  /// Zero-Trust session builder. Unknown roles resolve to nothing; an account
  /// with no resolvable roles is `pending`, never an admin.
  static Session buildSessionFromMap(Map<String, dynamic> data) {
    final roleIds = _stringList(data['roleIds']);
    final statusName = data['status']?.toString();
    final status = statusName != null
        ? (AccountStatus.values.asNameMap()[statusName] ?? AccountStatus.active)
        : (roleIds.isEmpty ? AccountStatus.pending : AccountStatus.active);

    return Session(
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      roleIds: roleIds,
      assignedDepartments: _departments(data['assignedDepartments']),
      customPermissions: _permissions(data['customPermissions']),
      isHeadOfDepartment: _heads(data['isHeadOfDepartment']),
      status: status,
      hotelId: data['hotelId']?.toString(),
    );
  }

  /// Backward-compatible single-role builder (kept for legacy call sites).
  static Session buildSession({
    required String userId,
    required String userName,
    required String roleId,
    required String hotelId,
    String email = '',
  }) {
    return Session(
      userId: userId,
      userName: userName,
      email: email,
      roleIds: roleId.isEmpty ? const [] : [roleId],
      status: roleId.isEmpty ? AccountStatus.pending : AccountStatus.active,
      hotelId: hotelId,
    );
  }

  static Future<void> clearUserRole(String uid) async {
    try {
      await _firestore.collection('user_roles').doc(uid).delete();
    } catch (_) {}
  }
}
