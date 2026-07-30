import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_store.dart';
import '../models/role.dart';

class FirestoreRoleService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> writeUserRole({
    required String uid,
    required String userId,
    required String roleId,
    required String userName,
    required String hotelId,
    required String email,
  }) async {
    await _firestore.collection('user_roles').doc(uid).set({
      'userId': userId,
      'roleId': roleId,
      'userName': userName,
      'hotelId': hotelId,
      'email': email,
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

  static AppRole? findRole(String roleId) {
    for (final r in RoleStore.prebuiltRoles) {
      if (r.id == roleId) return r;
    }
    return null;
  }

  static Session buildSession({
    required String userId,
    required String userName,
    required String roleId,
    required String hotelId,
  }) {
    final role = findRole(roleId) ?? RoleStore.prebuiltRoles.first;
    return Session(userId: userId, userName: userName, role: role, hotelId: hotelId);
  }

  static Future<void> clearUserRole(String uid) async {
    try {
      await _firestore.collection('user_roles').doc(uid).delete();
    } catch (_) {}
  }
}
