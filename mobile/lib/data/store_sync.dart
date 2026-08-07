import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'persistence_service.dart';
import 'role_store.dart';
import 'sync_service.dart';

/// Base for session-aware syncables so [CloudSync] can manage them generically.
abstract class CloudSyncable {
  /// (Re)start syncing for the current session; no-op when signed out.
  void start();

  /// Cancel subscriptions when signed out.
  void stop();
}

/// Offline-first Firestore sync for a feature store's collection.
///
/// Mirrors the HOMData pattern: Firestore is the master once a session is
/// active, the store's in-memory list is live UI state, and the Hive list
/// (under [cacheKey]) is the offline mirror. Firestore's local persistence
/// queues writes issued while offline, so they sync on reconnection — no queue
/// code needed here.
class StoreSync<T> implements CloudSyncable {
  /// Firestore subcollection name under `hotels/{hotelId}`.
  final String collection;

  /// The store's live list (mutated in place by cloud merges).
  final List<T> target;

  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  /// Hive/localStorage key used as the offline mirror.
  final String cacheKey;

  StoreSync({
    required this.collection,
    required this.target,
    required this.fromJson,
    required this.toJson,
    required this.cacheKey,
  });

  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  String? _hotelId;
  Map<String, dynamic> _meta = const {};

  /// Load the persisted diff index. Call from the store's `load()`.
  void loadMeta() {
    _meta = PersistenceService.load<Map<String, dynamic>>(
            'hom_sync_meta_$collection',
            (v) => Map<String, dynamic>.from(v as Map)) ??
        const {};
  }

  @override
  void start() {
    final hotel = SyncService.hotelId;
    if (hotel == null) {
      stop();
      return;
    }
    if (_hotelId == hotel) return;
    _hotelId = hotel;
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      // One-time backfill: when the cloud collection is empty, push local data
      // so Firestore becomes the master copy for this hotel.
      final pushed =
          await SyncService.backfill(collection, target.map(toJson).toList());
      _meta = pushed;
      PersistenceService.save('hom_sync_meta_$collection', pushed);
    } catch (_) {
      // No network / not provisioned — stay local-only this run.
    }
    _sub?.cancel();
    _sub = SyncService.watch(collection).listen(_merge);
  }

  /// Push local changes to the cloud. Call from the store's save path.
  Future<void> push() async {
    if (!SyncService.enabled) return;
    try {
      final next =
          await SyncService.pushDiff(collection, target.map(toJson).toList(), _meta);
      _meta = next;
      PersistenceService.save('hom_sync_meta_$collection', next);
    } catch (_) {
      // Offline — the write is queued by Firestore.
    }
  }

  void _merge(List<Map<String, dynamic>> docs) {
    final sorted = List<Map<String, dynamic>>.of(docs)
      ..sort((a, b) => _docTime(b).compareTo(_docTime(a)));
    final cloudItems = <T>[];
    for (final d in sorted) {
      try {
        cloudItems.add(fromJson(d));
      } catch (_) {/* skip malformed docs */}
    }
    final cloudIds = cloudItems.map((e) => (e as dynamic).id as String).toSet();
    // Cloud is authoritative; keep local-only items (pending offline writes)
    // visible until they reach the cloud.
    final localOnly =
        target.where((e) => !cloudIds.contains((e as dynamic).id)).toList();
    target
      ..clear()
      ..addAll([...cloudItems, ...localOnly]);
    PersistenceService.saveList(cacheKey, target, toJson);
  }

  @override
  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  static DateTime _docTime(Map<String, dynamic> d) {
    final t = d['createdAt'];
    if (t is Timestamp) return t.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

/// Central coordinator: starts/stops every registered [StoreSync] when the
/// session's hotel changes. Identity (`user_roles`/`hotels`/`invites`) stays
/// server-authoritative and is never synced here.
class CloudSync {
  static final List<CloudSyncable> _all = [];
  static bool _attached = false;

  static void register(CloudSyncable sync) => _all.add(sync);

  /// Wire the session notifier once; safe to call repeatedly.
  static void attach() {
    if (_attached) return;
    _attached = true;
    RoleStore.sessionNotifier.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  static void _onSessionChanged() {
    for (final s in _all) {
      s.start();
    }
  }
}
