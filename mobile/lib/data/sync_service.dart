import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_store.dart';

/// Offline-first sync layer for hotel-scoped business data.
///
/// Every business collection lives under `hotels/{hotelId}/{collection}`.
/// Firestore's local persistence (enabled by default on Android/iOS) means a
/// write issued here while the device is offline is queued on-device and
/// synced the moment the network returns — no queue code needed. This service
/// only reads the session's hotel id (identity stays server-authoritative)
/// and never touches `user_roles`/`hotels`/`invites`.
class SyncService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// The active hotel from the signed-in session, or null when signed out.
  static String? get hotelId {
    final h = RoleStore.current.hotelId;
    return (h == null || h.isEmpty) ? null : h;
  }

  static bool get enabled => hotelId != null;

  static CollectionReference<Map<String, dynamic>> _col(String collection) =>
      _db.collection('hotels').doc(hotelId!).collection(collection);

  /// Live stream of a hotel collection. Firestore's offline cache keeps this
  /// working (and fresh) while the device has no connectivity. Emits docs with
  /// their Firestore id injected as `id`.
  static Stream<List<Map<String, dynamic>>> watch(String collection) {
    if (!enabled) return const Stream.empty();
    return _col(collection).snapshots().map((snap) => [
          for (final d in snap.docs)
            if (d.id.isNotEmpty) {'id': d.id, ...d.data()},
        ]);
  }

  /// Snapshot a collection once (used for backfill decisions).
  static Future<List<Map<String, dynamic>>> fetchOnce(String collection) async {
    if (!enabled) return const [];
    final snap = await _col(collection).get();
    return [
      for (final d in snap.docs)
        if (d.id.isNotEmpty) {'id': d.id, ...d.data()},
    ];
  }

  /// One-time migration: when the cloud collection is empty and local data
  /// exists, push it so Firestore becomes the master copy. Returns the index
  /// ("last pushed" state) the caller should persist for future diffs.
  static Future<Map<String, dynamic>> backfill(
    String collection,
    List<Map<String, dynamic>> items,
  ) async {
    if (!enabled) return const {};
    final existing = await fetchOnce(collection);
    if (existing.isNotEmpty) return _index(existing);
    return pushDiff(collection, items, const {});
  }

  /// Diff [items] against [lastPushed] and sync adds/updates/deletes to the
  /// cloud in one batch. Returns the new "last pushed" state. Writing only
  /// changed docs keeps write churn (and the free-tier quota) minimal.
  static Future<Map<String, dynamic>> pushDiff(
    String collection,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> lastPushed,
  ) async {
    if (!enabled) return lastPushed;
    final db = _db;
    final hotel = db.collection('hotels').doc(hotelId!);
    final batch = db.batch();
    final next = <String, dynamic>{};
    final seen = <String>{};
    var dirty = false;
    final now = FieldValue.serverTimestamp();

    for (final item in items) {
      final id = item['id'];
      if (id is! String || id.isEmpty) continue;
      seen.add(id);
      final prev = lastPushed[id];
      if (prev != null && _same(prev, item)) {
        next[id] = prev;
        continue;
      }
      batch.set(hotel.collection(collection).doc(id), {
        ...item,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));
      next[id] = Map<String, dynamic>.from(item);
      dirty = true;
    }

    for (final id in lastPushed.keys) {
      if (seen.contains(id)) continue;
      batch.delete(hotel.collection(collection).doc(id));
      dirty = true;
    }

    if (dirty) {
      try {
        await batch.commit();
      } catch (_) {
        // Offline — Firestore queues the write anyway; keep lastPushed so the
        // next save() can retry the diff.
        return lastPushed;
      }
    }
    return next;
  }

  /// Index cloud docs into "last pushed" form (business fields only, without
  /// the server timestamps) so later diffs are stable.
  static Map<String, dynamic> _index(List<Map<String, dynamic>> docs) {
    final out = <String, dynamic>{};
    for (final d in docs) {
      final id = d['id'];
      if (id is! String || id.isEmpty) continue;
      final copy = Map<String, dynamic>.from(d)..remove('createdAt')
        ..remove('updatedAt');
      out[id] = copy;
    }
    return out;
  }

  static bool _same(Map<String, dynamic> a, Map<String, dynamic> b) {
    final ca = Map<String, dynamic>.from(a)..remove('id');
    final cb = Map<String, dynamic>.from(b)..remove('id');
    return jsonEncode(ca) == jsonEncode(cb);
  }
}
