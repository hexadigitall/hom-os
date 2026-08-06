enum TableStatus { free, occupied, reserved, cleaning }

enum OrderStatus { open, preparing, served, paid, cancelled }

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
  String menuItemId, name;
  int quantity;
  double unitPrice;
  String status; // pending, preparing, ready, served
  String? note;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.status = 'pending',
    this.note,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
    'menuItemId': menuItemId, 'name': name,
    'quantity': quantity, 'unitPrice': unitPrice,
    'status': status, 'note': note,
  };

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    menuItemId: j['menuItemId'], name: j['name'],
    quantity: j['quantity'], unitPrice: (j['unitPrice'] as num).toDouble(),
    status: j['status'] ?? 'pending', note: j['note'],
  );
}

class Order {
  String id, tableId, tableNumber, serverName;
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

  int get preparingCount => items.where((i) => i.status == 'preparing').length;
  int get readyCount => items.where((i) => i.status == 'ready').length;
  int get servedCount => items.where((i) => i.status == 'served').length;
  bool get allServed => items.isNotEmpty && items.every((i) => i.status == 'served');

  Map<String, dynamic> toJson() => {
    'id': id, 'tableId': tableId, 'tableNumber': tableNumber,
    'serverName': serverName, 'createdAt': createdAt.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
    'status': status.name, 'paymentMethod': paymentMethod,
    'roomChargeId': roomChargeId, 'discount': discount,
  };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['id'], tableId: j['tableId'],
    tableNumber: j['tableNumber'], serverName: j['serverName'],
    createdAt: DateTime.parse(j['createdAt']),
    items: (j['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
    status: OrderStatus.values.byName(j['status']),
    paymentMethod: j['paymentMethod'] ?? 'cash',
    roomChargeId: j['roomChargeId'],
    discount: (j['discount'] as num?)?.toDouble(),
  );
}
