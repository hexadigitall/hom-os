import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invite_code.dart';

/// Cloud (Firestore) invite store.
///
/// Lets invite codes generated on the owner's device be redeemed on ANY other
/// device (web, phone, desktop). HOM stays offline-first: every cloud call is
/// best-effort and falls back to the local Hive store silently, so a hotel
/// with no internet still works exactly as before.
class FirestoreInviteService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> writeInvite(InviteCode invite) async {
    try {
      await _firestore.collection('invites').doc(invite.code).set(invite.toJson());
    } catch (_) {}
  }

  static Future<InviteCode?> readInvite(String code) async {
    try {
      final doc = await _firestore.collection('invites').doc(code).get();
      if (!doc.exists) return null;
      return InviteCode.fromJson(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  static Future<void> markUsed(String code, String userId) async {
    try {
      await _firestore.collection('invites').doc(code).update({
        'usedByUserId': userId,
        'usedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  static Future<void> deleteInvite(String code) async {
    try {
      await _firestore.collection('invites').doc(code).delete();
    } catch (_) {}
  }
}
