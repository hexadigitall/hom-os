import 'safe_enum.dart';

enum TableStatus { free, occupied, reserved, cleaning }

enum OrderStatus { open, preparing, served, paid, cancelled }

enum OrderType { dineIn, roomService, takeaway, barWalkup, directCall }

/// Production station an F&B item is routed to. Menu items carry a station;
/// order items inherit it at punch time, so the Suya man sees only Suya
/// tickets and the mixologist only bar tickets.
enum FnbStation { mainKitchen, suyaGrill, barMixologist, pastry, general }

String fnbStationLabel(FnbStation s) => switch (s) {
      FnbStation.mainKitchen => 'Main Kitchen',
      FnbStation.suyaGrill => 'Suya & Grill',
      FnbStation.barMixologist => 'Bar / Mixologist',
      FnbStation.pastry => 'Pastry',
      FnbStation.general => 'General',
    };

/// Granular per-item pipeline shared across mobile + web (the exact
/// checkpoints a guest can be told about at any moment).
const List<String> kItemPipeline = [
  'pending', // punched in, not yet acknowledged
  'seen', // station display notified
  'queued', // station master acknowledged / sequenced
  'preparing', // active prep underway
  'ready', // ready for pickup
  'picked_up', // runner collected it
  'served', // delivered to guest
];

int kItemStageIndex(String status) {
  final i = kItemPipeline.indexOf(status);
  if (i >= 0) return i;
  return status == 'cancelled' ? kItemPipeline.length : -1;
}

String kItemStageLabel(String status) => switch (status) {
      'pending' => 'Pending',
      'seen' => 'Seen',
      'queued' => 'Queued',
      'preparing' => 'Preparing',
      'ready' => 'Ready',
      'picked_up' => 'Picked up',
      'served' => 'Served',
      'cancelled' => 'Cancelled',
      _ => status,
    };

class MenuItem {
  String id, name;
  String? description;
  String category;
  double price;
  bool available;
  int sortOrder;
  FnbStation station;

  MenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.price,
    this.available = true,
    this.sortOrder = 0,
    FnbStation? station,
  }) : station = station ?? stationForCategory(category);

  /// Default routing by category; the Menu form can override per item.
  static FnbStation stationForCategory(String category) {
    switch (category) {
      case 'food':
        return FnbStation.mainKitchen;
      case 'suya':
        return FnbStation.suyaGrill;
      case 'drink':
      case 'bar':
      case 'wine':
        return FnbStation.barMixologist;
      case 'pastry':
        return FnbStation.pastry;
      default:
        return FnbStation.general;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'description': description,
    'category': category, 'price': price,
    'available': available, 'sortOrder': sortOrder,
    'station': station.name,
  };

  factory MenuItem.fromJson(Map<String, dynamic> j) {
    final category = (j['category'] as String?) ?? 'food';
    return MenuItem(
      id: j['id'], name: j['name'],
      description: j['description'],
      category: category,
      price: (j['price'] as num).toDouble(),
      available: j['available'] ?? true,
      sortOrder: j['sortOrder'] ?? 0,
      station: safeEnum(
          j['station'], FnbStation.values, MenuItem.stationForCategory(category)),
    );
  }
}

class RestaurantTable {
  String id, number;
  int seats;
  TableStatus status;

  RestaurantTable({
    required this.id,
    required this.number,
    this.seats = 4,
    this.status = TableStatus.free,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'number': number, 'seats': seats, 'status': status.name,
  };

  factory RestaurantTable.fromJson(Map<String, dynamic> j) => RestaurantTable(
    id: j['id'], number: j['number'],
    seats: j['seats'] ?? 4,
    status: TableStatus.values.byName(j['status']),
  );
}

class OrderItem {
  String id, menuItemId, name;
  int quantity;
  double unitPrice;
  String status; // one of kItemPipeline: pending/seen/queued/preparing/ready/picked_up/served
  String? note;
  FnbStation station;

  OrderItem({
    String? id,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.status = 'pending',
    this.note,
    this.station = FnbStation.general,
  }) : id = id ?? 'oi_${DateTime.now().microsecondsSinceEpoch}';

  double get total => quantity * unitPrice;

  /// Next checkpoint in the granular pipeline; stays put on terminal states.
  String get nextStatus {
    final i = kItemStageIndex(status);
    if (i < 0 || i >= kItemPipeline.length - 1) return status;
    return kItemPipeline[i + 1];
  }

  /// Still flowing through the kitchen (not yet served or cancelled).
  bool get isKitchenWork =>
      status != 'served' && status != 'cancelled';

  Map<String, dynamic> toJson() => {
        'id': id,
        'menuItemId': menuItemId,
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'status': status,
        'note': note,
        'station': station.name,
      };

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: j['id'],
        menuItemId: j['menuItemId'],
        name: j['name'],
        quantity: j['quantity'],
        unitPrice: (j['unitPrice'] as num).toDouble(),
        status: j['status'] ?? 'pending',
        note: j['note'],
        station: safeEnum(
            j['station'], FnbStation.values, FnbStation.general),
      );
}

class Order {
  String id, tableId, tableNumber, serverName;
  OrderType orderType;
  String? roomNumber;
  DateTime createdAt;
  List<OrderItem> items;
  OrderStatus status;
  String paymentMethod; // cash, card, transfer, roomCharge, split
  String? roomChargeId; // if posted to room
  double? discount;

  /// Accountability timestamps set as the pipeline crosses each checkpoint
  /// (first station touch, first queue, all-ready, all-served).
  DateTime? seenAt, queuedAt, readyAt, servedAt;

  Order({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    required this.serverName,
    this.orderType = OrderType.dineIn,
    this.roomNumber,
    DateTime? createdAt,
    List<OrderItem>? items,
    this.status = OrderStatus.open,
    this.paymentMethod = 'cash',
    this.roomChargeId,
    this.discount,
    this.seenAt,
    this.queuedAt,
    this.readyAt,
    this.servedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       items = items ?? [];

  double get subtotal => items.fold(0.0, (s, i) => s + i.total);
  double get total => subtotal - (discount ?? 0);

  /// Where the order lives in the guest's world.
  String get locationLabel {
    switch (orderType) {
      case OrderType.roomService:
        final room = (roomNumber ?? '').trim();
        return room.isEmpty ? 'Room Service' : 'Room $room';
      case OrderType.takeaway:
        return 'Takeaway';
      case OrderType.barWalkup:
        return 'Bar Walk-up';
      case OrderType.directCall:
        return 'Direct Call';
      case OrderType.dineIn:
        final t = tableNumber.trim();
        return t.isEmpty ? 'Dine-in' : 'Table $t';
    }
  }

  /// Who/what punched the order in — surfaced to the kitchen so a room-service
  /// call is never mistaken for a walk-in.
  String get sourceLabel => switch (orderType) {
        OrderType.dineIn => 'Restaurant Floor',
        OrderType.roomService => 'Room Service Call',
        OrderType.takeaway => 'Takeaway / Pickup',
        OrderType.barWalkup => 'Direct Bar Walk-up',
        OrderType.directCall => 'Kitchen (Direct Call)',
      };

  bool get hasKitchenWork => items.any((i) => i.isKitchenWork);

  int get queuedCount => items.where((i) => i.status == 'queued').length;
  int get preparingCount => items.where((i) => i.status == 'preparing').length;
  int get readyCount =>
      items.where((i) => i.status == 'ready' || i.status == 'picked_up').length;
  int get servedCount => items.where((i) => i.status == 'served').length;
  bool get allServed =>
      items.isNotEmpty && items.every((i) => i.status == 'served');

  /// One-line kitchen status, e.g. `2 queued · 1 preparing · 3 ready`.
  String get kitchenSummary {
    final parts = <String>[
      if (queuedCount > 0) '$queuedCount queued',
      if (preparingCount > 0) '$preparingCount preparing',
      if (readyCount > 0) '$readyCount ready',
    ];
    return parts.isEmpty ? 'Awaiting kitchen' : parts.join(' · ');
  }

  /// Advance one item to its next checkpoint and refresh order timestamps.
  void advanceItem(OrderItem item) {
    final next = item.nextStatus;
    if (next == item.status) return;
    item.status = next;
    refreshTimestamps();
  }

  /// First-crossing timestamps so staff and guests always know where things
  /// stand (e.g. "your suya is on the grill" instead of a guessing game).
  void refreshTimestamps() {
    final now = DateTime.now();
    final anySeen = items.any((i) => kItemStageIndex(i.status) >= 1);
    if (anySeen && seenAt == null) seenAt = now;
    final anyQueued = items.any((i) => kItemStageIndex(i.status) >= 2);
    if (anyQueued && queuedAt == null) queuedAt = now;
    final allDone = items.isNotEmpty &&
        items.every((i) =>
            kItemStageIndex(i.status) >= kItemStageIndex('ready'));
    if (allDone && readyAt == null) readyAt = now;
    final allServed =
        items.isNotEmpty && items.every((i) => i.status == 'served');
    if (allServed && servedAt == null) servedAt = now;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tableId': tableId,
        'tableNumber': tableNumber,
        'serverName': serverName,
        'servedBy': serverName,
        'orderType': orderType.name,
        'roomNumber': roomNumber,
        'openedAt': createdAt.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
        'status': status.name,
        'paymentMethod': paymentMethod,
        'roomChargeId': roomChargeId,
        'discount': discount,
        'seenAt': seenAt?.toIso8601String(),
        'queuedAt': queuedAt?.toIso8601String(),
        'readyAt': readyAt?.toIso8601String(),
        'servedAt': servedAt?.toIso8601String(),
      };

  static DateTime _parseOpenedAt(Map<String, dynamic> j) {
    final v = j['openedAt'] ?? j['createdAt'];
    if (v is String) {
      final t = DateTime.tryParse(v);
      if (t != null) return t;
    }
    return DateTime.now();
  }

  static DateTime? _parseTs(dynamic v) {
    if (v is String) {
      final t = DateTime.tryParse(v);
      if (t != null) return t;
    }
    return null;
  }

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'],
        tableId: j['tableId'] ?? '',
        tableNumber: j['tableNumber'] ?? '',
        serverName: j['servedBy'] ?? j['serverName'] ?? '',
        orderType: safeEnum(
            j['orderType'] ?? j['order_source'], OrderType.values, OrderType.dineIn),
        roomNumber: j['roomNumber'],
        createdAt: _parseOpenedAt(j),
        items: (j['items'] as List)
            .map((e) => OrderItem.fromJson(e))
            .toList(),
        status: safeEnum(j['status'], OrderStatus.values, OrderStatus.open),
        paymentMethod: j['paymentMethod'] ?? 'cash',
        roomChargeId: j['roomChargeId'],
        discount: (j['discount'] as num?)?.toDouble(),
        seenAt: _parseTs(j['seenAt']),
        queuedAt: _parseTs(j['queuedAt']),
        readyAt: _parseTs(j['readyAt']),
        servedAt: _parseTs(j['servedAt']),
      );
}
