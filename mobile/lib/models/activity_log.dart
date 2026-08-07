import 'package:cloud_firestore/cloud_firestore.dart';

/// A single entry in the shared, real-time departmental activity feed.
///
/// Written by the acting staff member's own device (same offline-first path as
/// every other hotel business record) and synced under
/// `hotels/{hotelId}/activity_logs`, so every department sees one live stream
/// of what is happening across the hotel.
class ActivityLog {
  final String id;

  /// Department badge label (e.g. `restaurants`, `housekeeping`,
  /// `engineering`, `security`, `reception`). Free-form so third-party or
  /// future departments keep working without a code change.
  final String dept;

  /// Stable verb id, e.g. `order.created`, `order.paid`, `booking.checkedIn`.
  final String action;

  /// Human-readable summary shown in the feed, e.g.
  /// `Order T3 — 2x Jollof Rice & Chicken sent to kitchen`.
  final String message;

  /// Name of the staff member who performed the action.
  final String actor;

  /// Optional id of the related record (order/booking/task/...).
  final String? refId;

  final DateTime createdAt;

  ActivityLog({
    required this.id,
    required this.dept,
    required this.action,
    required this.message,
    required this.actor,
    this.refId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'dept': dept,
        'action': action,
        'message': message,
        'actor': actor,
        'refId': refId,
        'createdAt': createdAt.toIso8601String(),
      };

  static DateTime _parse(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) {
      final t = DateTime.tryParse(v);
      if (t != null) return t;
    }
    return DateTime.now();
  }

  factory ActivityLog.fromJson(Map<String, dynamic> j) => ActivityLog(
        id: j['id'],
        dept: j['dept'] ?? 'operations',
        action: j['action'] ?? '',
        message: j['message'] ?? '',
        actor: j['actor'] ?? '',
        refId: j['refId'],
        createdAt: _parse(j['createdAt']),
      );
}
