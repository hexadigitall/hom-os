import 'persistence_service.dart';
import 'store_sync.dart';
import '../models/food_beverage.dart';

class FnbStore {
  static final List<MenuItem> _menu = [];
  static final List<RestaurantTable> _tables = [];
  static final List<Order> _orders = [];

  // Offline-first cloud sync. Order serialization is now aligned across
  // platforms (openedAt/servedBy/tableId + item ids), so orders sync too.
  static final StoreSync<MenuItem> menuSync = _initMenuSync();
  static final StoreSync<RestaurantTable> tableSync = _initTableSync();
  static final StoreSync<Order> orderSync = _initOrderSync();

  static StoreSync<MenuItem> _initMenuSync() {
    final s = StoreSync<MenuItem>(
      collection: 'fnb_menu',
      target: _menu,
      fromJson: MenuItem.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'fnb_menu',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<RestaurantTable> _initTableSync() {
    final s = StoreSync<RestaurantTable>(
      collection: 'fnb_tables',
      target: _tables,
      fromJson: RestaurantTable.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'fnb_tables',
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<Order> _initOrderSync() {
    final s = StoreSync<Order>(
      collection: 'fnb_orders',
      target: _orders,
      fromJson: Order.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'fnb_orders',
    );
    CloudSync.register(s);
    return s;
  }

  // ===================== INIT =====================

  static Future<void> load() async {
    final m = PersistenceService.loadList('fnb_menu', MenuItem.fromJson);
    if (m != null) { _menu.clear(); _menu.addAll(m); }
    final t = PersistenceService.loadList('fnb_tables', RestaurantTable.fromJson);
    if (t != null) { _tables.clear(); _tables.addAll(t); }
    final o = PersistenceService.loadList('fnb_orders', Order.fromJson);
    if (o != null) { _orders.clear(); _orders.addAll(o); }
    if (_menu.isEmpty) _seedMenu();
    if (_tables.isEmpty) _seedTables();
    menuSync.loadMeta();
    tableSync.loadMeta();
    orderSync.loadMeta();
  }

  static Future<void> _save() async {
    await PersistenceService.saveList('fnb_menu', _menu, (e) => e.toJson());
    await PersistenceService.saveList('fnb_tables', _tables, (e) => e.toJson());
    await PersistenceService.saveList('fnb_orders', _orders, (e) => e.toJson());
    await menuSync.push();
    await tableSync.push();
    await orderSync.push();
  }

  // ===================== ID GENERATORS =====================

  static int _menuCounter = 0;
  static int _tableCounter = 0;
  static int _orderCounter = 0;

  static String genMenuId() => 'm_${DateTime.now().millisecondsSinceEpoch}_${++_menuCounter}';
  static String genTableId() => 't_${DateTime.now().millisecondsSinceEpoch}_${++_tableCounter}';
  static String genOrderId() => 'ord_${DateTime.now().millisecondsSinceEpoch}_${++_orderCounter}';

  // ===================== MENU =====================

  static List<MenuItem> get menu => List.unmodifiable(_menu);

  static const List<String> _defaultCategories = [
    'food', 'suya', 'drink', 'bar', 'wine', 'pastry', 'special',
  ];

  static List<String> get categories {
    final set = <String>{..._defaultCategories};
    for (final m in _menu) {
      if (m.category.isNotEmpty) set.add(m.category);
    }
    return set.toList();
  }

  static FnbStation stationForCategory(String category) =>
      MenuItem.stationForCategory(category);

  /// Stations present on the live menu, always including General as a fallback.
  static List<FnbStation> get stations {
    final set = <FnbStation>{FnbStation.general};
    for (final m in _menu) {
      set.add(m.station);
    }
    return FnbStation.values.where(set.contains).toList();
  }

  static List<MenuItem> menuByStation(FnbStation station) =>
      _menu.where((m) => m.station == station && m.available).toList();

  static List<MenuItem> menuByCategory(String c) =>
      _menu.where((m) => m.category == c && m.available).toList();

  /// Open orders carrying kitchen work for [station] — drives the station
  /// filter chips so the Suya man never sees a mixed kitchen ticket.
  static List<Order> ordersForStation(FnbStation station) =>
      openOrders.where((o) =>
          o.items.any((i) => i.station == station && i.isKitchenWork)).toList();

  static Future<void> addMenuItem(MenuItem item) async { _menu.add(item); await _save(); }
  static Future<void> updateMenuItem(String id, MenuItem updated) async {
    final i = _menu.indexWhere((m) => m.id == id);
    if (i >= 0) { _menu[i] = updated; await _save(); }
  }
  static Future<void> removeMenuItem(String id) async { _menu.removeWhere((m) => m.id == id); await _save(); }

  // ===================== TABLES =====================

  static List<RestaurantTable> get tables => List.unmodifiable(_tables);

  static Future<void> addTable(RestaurantTable t) async { _tables.add(t); await _save(); }
  static Future<void> updateTable(String id, RestaurantTable updated) async {
    final i = _tables.indexWhere((t) => t.id == id);
    if (i >= 0) { _tables[i] = updated; await _save(); }
  }
  static Future<void> removeTable(String id) async { _tables.removeWhere((t) => t.id == id); await _save(); }

  // ===================== ORDERS =====================

  static List<Order> get orders => List.unmodifiable(_orders);
  static List<Order> get openOrders => _orders.where((o) => o.status == OrderStatus.open || o.status == OrderStatus.preparing).toList();
  static Order? orderForTable(String tableId) => _orders.cast<Order?>().firstWhere(
    (o) => o!.tableId == tableId && (o.status == OrderStatus.open || o.status == OrderStatus.preparing),
    orElse: () => null,
  );

  static Future<void> addOrder(Order o) async { _orders.insert(0, o); await _save(); }
  static Future<void> updateOrder(String id, Order updated) async {
    final i = _orders.indexWhere((o) => o.id == id);
    if (i >= 0) { _orders[i] = updated; await _save(); }
  }
  static Future<void> removeOrder(String id) async { _orders.removeWhere((o) => o.id == id); await _save(); }

  // ===================== SEED DATA =====================

  static void _seedMenu() {
    _menu.addAll([
      MenuItem(id: genMenuId(), name: 'Jollof Rice & Chicken', category: 'food', price: 4500, description: 'Smoked jollof with grilled chicken, plantain & coleslaw'),
      MenuItem(id: genMenuId(), name: 'Egusi Soup & Pounded Yam', category: 'food', price: 5500, description: 'Classic egusi with assorted meat & pounded yam'),
      MenuItem(id: genMenuId(), name: 'Grilled Tilapia', category: 'food', price: 6500, description: 'Whole tilapia with chips & garden salad'),
      MenuItem(id: genMenuId(), name: 'Pepper Soup Goat Meat', category: 'food', price: 5000, description: 'Spiced pepper soup with tender goat meat'),
      MenuItem(id: genMenuId(), name: 'Beef Suya Platter', category: 'suya', price: 8000, description: 'Spiced beef suya with onions, pepper & yaji — serving for 2'),
      MenuItem(id: genMenuId(), name: 'Chicken Suya Skewers', category: 'suya', price: 5000, description: 'Charcoal-grilled chicken skewers dusted in yaji'),
      MenuItem(id: genMenuId(), name: 'Puff Puff', category: 'pastry', price: 1000, description: 'Six golden fried dough bites — best fresh'),
      MenuItem(id: genMenuId(), name: 'Meat Pie', category: 'pastry', price: 1500, description: 'Buttery Nigerian meat pie, oven fresh'),
      MenuItem(id: genMenuId(), name: 'Chin Chin', category: 'pastry', price: 1000, description: 'Crunchy fried dough snacks'),
      MenuItem(id: genMenuId(), name: 'Bottled Water', category: 'drink', price: 500),
      MenuItem(id: genMenuId(), name: 'Maltina', category: 'drink', price: 800),
      MenuItem(id: genMenuId(), name: 'Chapman Mocktail', category: 'drink', price: 2500, description: 'Non-alcoholic fruit mocktail'),
      MenuItem(id: genMenuId(), name: 'Star Lager', category: 'bar', price: 1200),
      MenuItem(id: genMenuId(), name: 'Heineken', category: 'bar', price: 1500),
      MenuItem(id: genMenuId(), name: 'Jameson Whisky (Shot)', category: 'bar', price: 3000),
      MenuItem(id: genMenuId(), name: 'South African Red Wine', category: 'wine', price: 15000, description: 'Cabernet Sauvignon — bottle'),
      MenuItem(id: genMenuId(), name: 'Nigerian Palm Wine', category: 'special', price: 2000, description: 'Fresh tapped palm wine — calabash'),
    ]);
  }

  static void _seedTables() {
    _tables.addAll([
      RestaurantTable(id: genTableId(), number: 'T1', seats: 2),
      RestaurantTable(id: genTableId(), number: 'T2', seats: 2),
      RestaurantTable(id: genTableId(), number: 'T3', seats: 4),
      RestaurantTable(id: genTableId(), number: 'T4', seats: 4),
      RestaurantTable(id: genTableId(), number: 'T5', seats: 6),
      RestaurantTable(id: genTableId(), number: 'VIP-1', seats: 8),
      RestaurantTable(id: genTableId(), number: 'VIP-2', seats: 8),
      RestaurantTable(id: genTableId(), number: 'Bar-1', seats: 1, status: TableStatus.reserved),
    ]);
  }
}
