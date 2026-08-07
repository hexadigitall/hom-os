import 'package:flutter/foundation.dart';
import 'persistence_service.dart';
import 'role_store.dart';
import 'store_sync.dart';
import '../models/activity_log.dart';

/// Live, hotel-wide activity feed store.
///
/// Every department appends entries here (offline-first, exactly like other
/// business records); [sync] keeps them real-time against
/// `hotels/{hotelId}/activity_logs`. The store is a [ChangeNotifier] so feed
/// screens rebuild the moment a cloud snapshot lands via [StoreSync.onMerge].
class FeedStore extends ChangeNotifier {
  static final List<ActivityLog> _logs = [];

  static final StoreSync<ActivityLog> sync = _initSync();

  static StoreSync<ActivityLog> _initSync() {
    final s = StoreSync<ActivityLog>(
      collection: 'activity_logs',
      target: _logs,
      fromJson: ActivityLog.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'activity_logs',
      onMerge: () => _instance.notifyListeners(),
    );
    CloudSync.register(s);
    return s;
  }

  FeedStore._();
  static final FeedStore _instance = FeedStore._();
  static FeedStore get instance => _instance;

  // ===================== INIT =====================

  static Future<void> load() async {
    final persisted = PersistenceService.loadList('activity_logs', ActivityLog.fromJson);
    if (persisted != null) {
      _logs.clear();
      _logs.addAll(persisted);
    }
    if (_logs.isEmpty) _seed();
    sync.loadMeta();
  }

  static Future<void> _save() async {
    await PersistenceService.saveList('activity_logs', _logs, (e) => e.toJson());
    await sync.push();
    _instance.notifyListeners();
  }

  // ===================== ACCESS =====================

  /// Newest first.
  static List<ActivityLog> get logs {
    final out = List<ActivityLog>.of(_logs)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(out);
  }

  // ===================== WRITE =====================

  static int _counter = 0;
  static String _genId() =>
      'act_${DateTime.now().millisecondsSinceEpoch}_${++_counter}';

  /// Append one activity entry, tagged with the acting user's name.
  static Future<void> log({
    required String dept,
    required String action,
    required String message,
    String? refId,
  }) async {
    _logs.insert(
      0,
      ActivityLog(
        id: _genId(),
        dept: dept,
        action: action,
        message: message,
        actor: RoleStore.current.userName.isEmpty
            ? 'Staff'
            : RoleStore.current.userName,
        refId: refId,
      ),
    );
    await _save();
  }

  // ===================== SEED =====================

  static void _seed() {
    _logs.addAll([
      ActivityLog(
        id: _genId(),
        dept: 'restaurants',
        action: 'order.created',
        message: 'Order T1 opened — table 2-seater assigned',
        actor: 'HOM Setup',
      ),
      ActivityLog(
        id: _genId(),
        dept: 'housekeeping',
        action: 'task.completed',
        message: 'Room 101 turn-down marked complete',
        actor: 'HOM Setup',
      ),
    ]);
  }
}
