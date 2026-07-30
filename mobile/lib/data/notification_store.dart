import 'persistence_service.dart';
import '../models/app_notification.dart';

class NotificationStore {
  static final List<AppNotification> _notifications = [];
  static int _counter = 0;

  static String genId() => 'notif_${DateTime.now().millisecondsSinceEpoch}_${++_counter}';

  static List<AppNotification> get all => List.unmodifiable(_notifications);
  static List<AppNotification> get unread => _notifications.where((n) => !n.read).toList();
  static int get unreadCount => _notifications.where((n) => !n.read).length;

  static Future<void> load() async {
    final r = PersistenceService.loadList('app_notifications', AppNotification.fromJson);
    if (r != null) { _notifications.clear(); _notifications.addAll(r); }
  }

  static Future<void> _save() => PersistenceService.saveList('app_notifications', _notifications, (n) => n.toJson());

  static Future<void> add(AppNotification n) async { _notifications.insert(0, n); await _save(); }

  static Future<void> markRead(String id) async {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i >= 0) { _notifications[i].read = true; await _save(); }
  }

  static Future<void> markAllRead() async {
    for (final n in _notifications) { n.read = true; }
    await _save();
  }

  static Future<void> remove(String id) async { _notifications.removeWhere((n) => n.id == id); await _save(); }
  static Future<void> clear() async { _notifications.clear(); await _save(); }

  static List<AppNotification> filterByType(NotificationType? type) {
    if (type == null) return all;
    return _notifications.where((n) => n.type == type).toList();
  }

  // ===================== AUTO-TRIGGERED NOTIFICATIONS =====================

  static void notifyFuelTheft(double rate, String fuelType, String supplier) {
    add(AppNotification(
      id: genId(), type: NotificationType.alarm, urgency: Urgency.high,
      title: 'Fuel Theft Detected',
      body: '${rate.toStringAsFixed(1)} $fuelType — abnormal consumption from $supplier. Investigate immediately.',
      actionRoute: 'fuel',
      actionLabel: 'View Fuel Logs',
    ));
  }

  static void notifyGeneratorFault(String fault, String generatorName) {
    add(AppNotification(
      id: genId(), type: NotificationType.alarm, urgency: Urgency.high,
      title: 'Generator Fault — $generatorName',
      body: fault,
    ));
  }

  static void notifyLowInventory(String itemName, int qty, int low) {
    add(AppNotification(
      id: genId(), type: NotificationType.deadline, urgency: Urgency.high,
      title: 'Low Stock Alert',
      body: '$itemName is at $qty (threshold: $low). Reorder now.',
      actionRoute: 'inventory',
      actionLabel: 'View Inventory',
    ));
  }

  static void notifyGuestRequestUnresolved(String guestName, String request, int minutes) {
    add(AppNotification(
      id: genId(), type: NotificationType.alarm, urgency: Urgency.high,
      title: 'Unresolved Guest Request',
      body: '$guestName requested "$request" $minutes min ago. Escalate to Duty Manager.',
      actionRoute: 'bookings',
      actionLabel: 'View Bookings',
    ));
  }

  static void notifyCheckoutReminder(String guestName, String room) {
    add(AppNotification(
      id: genId(), type: NotificationType.deadline, urgency: Urgency.medium,
      title: 'Check-out Reminder',
      body: '$guestName in Room $room checks out in 30 min. Prepare for turnover.',
      actionRoute: 'bookings',
      actionLabel: 'View Booking',
    ));
  }

  static void notifyRoomReady(String room) {
    add(AppNotification(
      id: genId(), type: NotificationType.operational, urgency: Urgency.medium,
      title: 'Room Ready — $room',
      body: 'Room $room is now clean, inspected and ready for check-in.',
      actionRoute: 'rooms',
      actionLabel: 'View Rooms',
    ));
  }

  static void notifyKitchenOrderReady(String tableOrRoom, String items) {
    add(AppNotification(
      id: genId(), type: NotificationType.operational, urgency: Urgency.medium,
      title: 'Order Ready',
      body: 'Order for $tableOrRoom is ready: $items.',
    ));
  }

  static void notifyComplianceDeadline(String certName, int daysLeft) {
    final urgency = daysLeft <= 7 ? Urgency.high : (daysLeft <= 15 ? Urgency.medium : Urgency.low);
    add(AppNotification(
      id: genId(), type: NotificationType.deadline, urgency: urgency,
      title: 'Compliance Deadline — $daysLeft days',
      body: '$certName expires in $daysLeft days. Renew to avoid penalties.',
      actionRoute: 'compliance',
      actionLabel: 'View Compliance',
    ));
  }

  static void notifyPaymentReceived(String guestName, double amount, String method) {
    add(AppNotification(
      id: genId(), type: NotificationType.operational, urgency: Urgency.medium,
      title: 'Payment Received',
      body: '$guestName paid ₦${amount.toStringAsFixed(0)} via $method. Invoice cleared.',
      actionRoute: 'bookings',
      actionLabel: 'View Booking',
    ));
  }

  static void notifyStaffShiftChange(String staffName, String newShift, String date) {
    add(AppNotification(
      id: genId(), type: NotificationType.operational, urgency: Urgency.low,
      title: 'Shift Change — $staffName',
      body: '$staffName moved to $newShift on $date.',
    ));
  }

  static void notifySyncConflict(String entity, String field) {
    add(AppNotification(
      id: genId(), type: NotificationType.system, urgency: Urgency.medium,
      title: 'Sync Conflict',
      body: 'Conflict in $entity ($field). Local change kept.',
    ));
  }

  static void notifyOfflineSyncComplete(int recordsCount) {
    add(AppNotification(
      id: genId(), type: NotificationType.system, urgency: Urgency.low,
      title: 'Offline Sync Complete',
      body: '$recordsCount local changes synced to server.',
    ));
  }

  // ===================== SAMPLE SEED DATA =====================

  static void seedSampleData() {
    final now = DateTime.now();
    final templates = <AppNotification>[
      AppNotification(id: genId(), type: NotificationType.alarm, urgency: Urgency.high, title: 'Generator Overheat', body: 'Main DG coolant temp at 105°C. Auto-shutdown imminent.', timestamp: now.subtract(const Duration(minutes: 5))),
      AppNotification(id: genId(), type: NotificationType.deadline, urgency: Urgency.high, title: 'Fire Safety Cert Expiring', body: 'Fire safety certificate expires in 3 days. Renew immediately.', timestamp: now.subtract(const Duration(hours: 1))),
      AppNotification(id: genId(), type: NotificationType.operational, urgency: Urgency.medium, title: 'Room 204 Ready', body: 'Room 204 is now clean and inspected. Ready for check-in.', timestamp: now.subtract(const Duration(hours: 2))),
      AppNotification(id: genId(), type: NotificationType.alarm, urgency: Urgency.medium, title: 'Guest Request Unresolved', body: 'Room 310 requested extra towels 15 min ago. No staff assigned.', timestamp: now.subtract(const Duration(hours: 3))),
      AppNotification(id: genId(), type: NotificationType.deadline, urgency: Urgency.low, title: 'Waste Management Renewal', body: 'Waste management contract expires in 30 days.', timestamp: now.subtract(const Duration(hours: 5))),
      AppNotification(id: genId(), type: NotificationType.system, urgency: Urgency.low, title: 'Offline Sync Complete', body: '12 local changes synced to server.', timestamp: now.subtract(const Duration(days: 1))),
      AppNotification(id: genId(), type: NotificationType.operational, urgency: Urgency.medium, title: 'Payment Received', body: 'Chioma Okafor paid ₦45,000 via bank transfer. Room 105 cleared.', timestamp: now.subtract(const Duration(days: 1))),
      AppNotification(id: genId(), type: NotificationType.deadline, urgency: Urgency.high, title: 'Diesel Reorder Alert', body: 'Diesel stock at 200L. Reorder threshold: 500L. Order now.', timestamp: now.subtract(const Duration(days: 2))),
    ];
    for (final t in templates) { add(t); }
  }
}
