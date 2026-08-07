import 'safe_enum.dart';

enum TableStatus { free, occupied, reserved, cleaning }

enum OrderStatus { open, preparing, served, paid, cancelled }

enum OrderType { dineIn, roomService, takeaway }

class MenuItem {
  String id, name;
  String? description;
  String category;
  double price;
  bool available;
  int sortOrder;

  MenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.price,
    this.available = true,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'description': description,
    'category': category, 'price': price,
    'available': available, 'sortOrder': sortOrder,
  };

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
    id: j['id'], name: j['name'],
    description: j['description'],
    category: (j['category'] as String?) ?? 'food',
    price: (j['price'] as num).toDouble(),
    available: j['available'] ?? true,
    sortOrder: j['sortOrder'] ?? 0,
  );
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
  String status; // pending, preparing, ready, served
  String? note;

  OrderItem({
    String? id,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.status = 'pending',
    this.note,
  }) : id = id ?? 'oi_${DateTime.now().microsecondsSinceEpoch}';

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'id': id,
        'menuItemId': menuItemId,
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'status': status,
        'note': note,
      };

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: j['id'],
        menuItemId: j['menuItemId'],
        name: j['name'],
        quantity: j['quantity'],
        unitPrice: (j['unitPrice'] as num).toDouble(),
        status: j['status'] ?? 'pending',
        note: j['note'],
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
  }) : createdAt = createdAt ?? DateTime.now(),
       items = items ?? [];

  double get subtotal => items.fold(0.0, (s, i) => s + i.total);
  double get total => subtotal - (discount ?? 0);

  /// Human-readable serving location: room number for room service, table
  /// number for dine-in, otherwise a takeaway placeholder.
  String get locationLabel {
    if (orderType == OrderType.roomService) {
      final room = (roomNumber ?? '').trim();
      return room.isEmpty ? 'Room Service' : 'Room $room';
    }
    if (orderType == OrderType.takeaway) return 'Takeaway';
    final t = tableNumber.trim();
    return t.isEmpty ? 'Dine-in' : 'Table $t';
  }

  int get preparingCount => items.where((i) => i.status == 'preparing').length;
  int get readyCount => items.where((i) => i.status == 'ready').length;
  int get servedCount => items.where((i) => i.status == 'served').length;
  bool get allServed => items.isNotEmpty && items.every((i) => i.status == 'served');

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
      };

  static DateTime _parseOpenedAt(Map<String, dynamic> j) {
    final v = j['openedAt'] ?? j['createdAt'];
    if (v is String) {
      final t = DateTime.tryParse(v);
      if (t != null) return t;
    }
    return DateTime.now();
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
      );
}
