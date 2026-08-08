import 'package:flutter/material.dart';
import '../../models/food_beverage.dart';
import '../../data/fnb_store.dart';
import '../../data/feed_store.dart';
import '../../data/role_store.dart';
import '../../utils/role_gate.dart';
import '../../models/role.dart';
import '../../widgets/hom_widgets.dart';
import '../../utils/theme.dart';
import '../../main.dart' as app;

final Color _primary = AppColors.primary;

String _feedLocation(Order o) => o.locationLabel;

void _feedOrder(String action, Order o, String verb) {
  FeedStore.log(
    dept: 'restaurants',
    action: action,
    message: '$verb order at ${_feedLocation(o)} (${o.serverName})',
    refId: o.id,
  );
}

enum _FnbTabKind { tables, orders, menu }

/// Sub-tabs are permission-gated (mirrors the web module): Tables needs
/// managePOS; Orders + Menu are shared by the POS and kitchen (KDS) roles.
List<_FnbTabKind> _fnbTabsFor(Session s) {
  final kinds = <_FnbTabKind>[];
  if (s.has(Permission.managePOS)) kinds.add(_FnbTabKind.tables);
  if (s.hasAny([Permission.managePOS, Permission.manageKDS])) {
    kinds.add(_FnbTabKind.orders);
    kinds.add(_FnbTabKind.menu);
  }
  return kinds;
}

class FnbScreen extends StatefulWidget {
  const FnbScreen({super.key});
  @override
  State<FnbScreen> createState() => _FnbScreenState();
}

class _FnbScreenState extends State<FnbScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<_FnbTabKind> _kinds;
  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _kinds = _fnbTabsFor(RoleStore.current);
    _tabController = TabController(length: _kinds.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_kinds.isEmpty) {
      return const Scaffold(
          body: Center(child: Text('No F&B access')));
    }
    return Scaffold(
      body: Column(children: [
        Material(
          color: AppColors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: _primary,
            labelColor: _primary,
            unselectedLabelColor: AppColors.grey500,
            tabs: _kinds
                .map((k) => Tab(
                      text: switch (k) {
                        _FnbTabKind.tables => 'Tables',
                        _FnbTabKind.orders => 'Orders',
                        _FnbTabKind.menu => 'Menu',
                      },
                      icon: Icon(switch (k) {
                        _FnbTabKind.tables => Icons.table_restaurant_rounded,
                        _FnbTabKind.orders => Icons.receipt_long_rounded,
                        _FnbTabKind.menu => Icons.menu_book_rounded,
                      }, size: 16),
                    ))
                .toList(),
          ),
        ),
        Expanded(
            child: TabBarView(controller: _tabController, children: [
          ..._kinds.map((k) => switch (k) {
                _FnbTabKind.tables =>
                  _TablesTab(onOrderTap: () => setState(() {})),
                _FnbTabKind.orders =>
                  _OrdersTab(onChange: () => setState(() {})),
                _FnbTabKind.menu => _MenuTab(onChange: () => setState(() {})),
              }),
        ])),
      ]),
    );
  }
}

// ─────────────────────── TABLES TAB ───────────────────────

class _TablesTab extends StatefulWidget {
  final VoidCallback onOrderTap;
  const _TablesTab({required this.onOrderTap});
  @override
  State<_TablesTab> createState() => _TablesTabState();
}

class _TablesTabState extends State<_TablesTab> {
  Color _tableColor(TableStatus s) {
    switch (s) {
      case TableStatus.free:
        return _primary;
      case TableStatus.occupied:
        return AppColors.red400;
      case TableStatus.reserved:
        return AppColors.orange;
      case TableStatus.cleaning:
        return AppColors.grey500;
    }
  }

  String _tableLabel(TableStatus s) {
    switch (s) {
      case TableStatus.free:
        return 'Free';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.reserved:
        return 'Reserved';
      case TableStatus.cleaning:
        return 'Cleaning';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tables = FnbStore.tables;
    final compact = isCompact(context);
    final crossAxisCount = compact
        ? (isLandscape(context) ? 4 : 3)
        : (isLandscape(context) ? 6 : 4);
    return Scaffold(
      body: tables.isEmpty
          ? const Center(child: Text('No tables configured'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemCount: tables.length,
              itemBuilder: (ctx, i) {
                final t = tables[i];
                final color = _tableColor(t.status);
                final openOrder = FnbStore.orderForTable(t.id);
                return GestureDetector(
                  onTap: () {
                    if (t.status == TableStatus.free) {
                      if (RoleStore.has(Permission.managePOS)) {
                        _showCreateOrder(context, t);
                      }
                    } else if (openOrder != null) {
                      _showOrderDetail(context, openOrder);
                    }
                  },
                  onLongPress: () {
                    if (RoleStore.has(Permission.managePOS)) {
                      _showTableActions(context, t);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: color.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(t.number,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: color)),
                          const SizedBox(height: 4),
                          Text('${t.seats} seats',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.grey600)),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(_tableLabel(t.status),
                                style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ]),
                  ),
                );
              },
            ),
      floatingActionButton: RoleGate(
        requiredPermission: Permission.manageTableManagement,
        child: FloatingActionButton(
          backgroundColor: _primary,
          foregroundColor: AppColors.white,
          child: const Icon(Icons.add),
          onPressed: () => _showTableForm(context),
        ),
      ),
    );
  }

  void _showTableActions(BuildContext context, RestaurantTable t) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Table ${t.number}',
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          ListTile(
            leading: Icon(Icons.edit_rounded, color: _primary, size: 20),
            title: const Text('Edit Table', overflow: TextOverflow.ellipsis),
            onTap: () {
              Navigator.pop(ctx);
              _showTableForm(context, table: t);
            },
          ),
          const Divider(),
          for (final s in TableStatus.values)
            ListTile(
              leading: Icon(Icons.circle, color: _tableColor(s), size: 14),
              title: Text(_tableLabel(s), overflow: TextOverflow.ellipsis),
              selected: t.status == s,
              onTap: () {
                FnbStore.updateTable(
                    t.id,
                    RestaurantTable(
                        id: t.id, number: t.number, seats: t.seats, status: s));
                Navigator.pop(ctx);
                widget.onOrderTap();
              },
            ),
          if (t.status != TableStatus.occupied &&
              FnbStore.orderForTable(t.id) == null)
            ListTile(
              leading: const Icon(Icons.delete_rounded,
                  color: AppColors.red, size: 20),
              title: const Text('Remove Table',
                  style: TextStyle(color: AppColors.red),
                  overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.pop(ctx);
                showDialog<bool>(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    title: const Text('Remove Table?'),
                    content: Text(
                        'Delete ${t.number}? This cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dctx, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(dctx, true),
                          child: const Text('Remove',
                              style: TextStyle(color: AppColors.red))),
                    ],
                  ),
                ).then((confirmed) {
                  if (confirmed == true) {
                    FnbStore.removeTable(t.id);
                    widget.onOrderTap();
                  }
                });
              },
            ),
        ]),
      )),
    );
  }

  void _showTableForm(BuildContext context, {RestaurantTable? table}) {
    final nameCtl = TextEditingController(text: table?.number ?? '');
    final capacityCtl =
        TextEditingController(text: table?.seats.toString() ?? '');
    TableStatus status = table?.status ?? TableStatus.free;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(table == null ? 'Add Table' : 'Edit Table',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(
                        labelText: 'Table Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: capacityCtl,
                    decoration: const InputDecoration(
                        labelText: 'Capacity (seats)',
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number),
                if (table != null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TableStatus>(
                    initialValue: status,
                    decoration: const InputDecoration(
                        labelText: 'Status', border: OutlineInputBorder()),
                    items: TableStatus.values
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Row(children: [
                              Icon(Icons.circle,
                                  color: _tableColor(s), size: 14),
                              const SizedBox(width: 8),
                              Text(_tableLabel(s)),
                            ])))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheetState(() => status = v);
                    },
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: RoleGate(
                    requiredPermission: Permission.manageTableManagement,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () {
                        final name = nameCtl.text.trim();
                        final capacity = int.tryParse(capacityCtl.text) ?? 4;
                        if (name.isEmpty) return;
                        final t = RestaurantTable(
                          id: table?.id ?? FnbStore.genTableId(),
                          number: name,
                          seats: capacity,
                          status: status,
                        );
                        if (table != null) {
                          FnbStore.updateTable(table.id, t);
                        } else {
                          FnbStore.addTable(t);
                        }
                        Navigator.pop(ctx);
                        widget.onOrderTap();
                      },
                      child: Text(table == null ? 'Add Table' : 'Update Table'),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateOrder(BuildContext context, RestaurantTable t) {
    final nameCtl = TextEditingController(text: RoleStore.current.userName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Order — Table ${t.number}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                      controller: nameCtl,
                      decoration: const InputDecoration(
                          labelText: 'Server Name',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: RoleGate(
                      requiredPermission: Permission.managePOS,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () {
                          final order = Order(
                            id: FnbStore.genOrderId(),
                            tableId: t.id,
                            tableNumber: t.number,
                            serverName: nameCtl.text.trim().isEmpty
                                ? 'Staff'
                                : nameCtl.text.trim(),
                          );
                          FnbStore.addOrder(order);
                          _feedOrder('order.created', order, 'New');
                          FnbStore.updateTable(
                              t.id,
                              RestaurantTable(
                                  id: t.id,
                                  number: t.number,
                                  seats: t.seats,
                                  status: TableStatus.occupied));
                          Navigator.pop(ctx);
                          widget.onOrderTap();
                          _showAddItems(context, order);
                        },
                        child: const Text('Create & Add Items'),
                      ),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  void _showAddItems(BuildContext context, Order order) {
    _showAddItemsForOrder(context, order, onChange: widget.onOrderTap);
  }

  void _showOrderDetail(BuildContext context, Order order) {
    var sentToKitchen = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order — ${order.locationLabel}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('Server: ${order.serverName}  •  ${order.sourceLabel}',
                        style:
                            TextStyle(color: AppColors.grey600, fontSize: 12)),
                    if (order.hasKitchenWork)
                      Text(order.kitchenSummary,
                          style: TextStyle(
                              color: AppColors.grey600, fontSize: 12)),
                    if (order.seenAt != null)
                      Text('First seen ${_fmtTs(order.seenAt!)}',
                          style:
                              TextStyle(color: AppColors.grey600, fontSize: 11)),
                    if (order.readyAt != null)
                      Text('Ready ${_fmtTs(order.readyAt!)}',
                          style:
                              TextStyle(color: AppColors.grey600, fontSize: 11)),
                    if (order.servedAt != null)
                      Text('Served ${_fmtTs(order.servedAt!)}',
                          style:
                              TextStyle(color: AppColors.grey600, fontSize: 11)),
                    const Divider(),
                    if (order.items.isEmpty)
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No items yet'))
                    else
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(children: [
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('${item.quantity}x ${item.name}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        Text(fnbStationLabel(item.station),
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.grey500)),
                                      ])),
                              Text('₦${item.total.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              statusBadge(kItemStageLabel(item.status),
                                  color: _itemStatusColor(item.status)),
                            ]),
                          )),
                    const Divider(),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('₦${order.total.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: _primary)),
                        ]),
                    const SizedBox(height: 12),
                    if (order.status == OrderStatus.open ||
                        order.status == OrderStatus.preparing)
                      Row(children: [
                        if (RoleStore.has(Permission.managePOS))
                          Expanded(
                              child: ElevatedButton(
                            onPressed: () {
                              _showAddItems(context, order);
                              setSheetState(() {});
                            },
                            child: const Text('Add Items'),
                          )),
                        if (RoleStore.has(Permission.managePOS))
                          const SizedBox(width: 8),
                        if (order.items.isNotEmpty &&
                            RoleStore.has(Permission.managePOS))
                          Expanded(
                              child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orange,
                                foregroundColor: AppColors.white),
                            onPressed: sentToKitchen
                                ? null
                                : () {
                                    if (order.status == OrderStatus.open) {
                                      order.status = OrderStatus.preparing;
                                      FnbStore.updateOrder(order.id, order);
                                    }
                                    _feedOrder('order.kitchen', order,
                                        'Sent to kitchen');
                                    setSheetState(
                                        () => sentToKitchen = true);
                                    widget.onOrderTap();
                                  },
                            child: Text(sentToKitchen
                                ? 'In Kitchen'
                                : 'Send to Kitchen'),
                          )),
                      ]),
                    if (order.allServed && order.status != OrderStatus.paid)
                      RoleGate(
                        requiredPermission: Permission.managePOS,
                        child: _PaymentSection(
                            order: order,
                            onPaid: () {
                              final table = FnbStore.tables
                                  .cast<RestaurantTable?>()
                                  .firstWhere((t) => t!.id == order.tableId,
                                      orElse: () => null);
                              if (table != null)
                                FnbStore.updateTable(
                                    order.tableId,
                                    RestaurantTable(
                                        id: table.id,
                                        number: table.number,
                                        seats: table.seats,
                                        status: TableStatus.free));
                              order.status = OrderStatus.paid;
                              FnbStore.updateOrder(order.id, order);
                              _feedOrder('order.paid', order, 'Paid');
                              setSheetState(() {});
                              widget.onOrderTap();
                            }),
                      ),
                    const SizedBox(height: 12),
                    if (order.status == OrderStatus.open ||
                        order.status == OrderStatus.preparing)
                      RoleGate(
                        requiredPermission: Permission.voidFnbOrders,
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.red),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _confirmDeleteOrder(
                                  context, order, widget.onOrderTap);
                            },
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            label: const Text('Delete Order'),
                          ),
                        ),
                      ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── PAYMENT SECTION ───────────────────────

class _PaymentSection extends StatelessWidget {
  final Order order;
  final VoidCallback onPaid;
  const _PaymentSection({required this.order, required this.onPaid});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(),
      const Text('Payment',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      const SizedBox(height: 8),
      Row(children: [
        _PaymentChip(
            label: 'Cash',
            icon: Icons.money,
            selected: order.paymentMethod == 'cash',
            onTap: () {
              order.paymentMethod = 'cash';
              onPaid();
            }),
        const SizedBox(width: 8),
        _PaymentChip(
            label: 'Card',
            icon: Icons.credit_card,
            selected: order.paymentMethod == 'card',
            onTap: () {
              order.paymentMethod = 'card';
              onPaid();
            }),
        const SizedBox(width: 8),
        _PaymentChip(
            label: 'Transfer',
            icon: Icons.phone_android,
            selected: order.paymentMethod == 'transfer',
            onTap: () {
              order.paymentMethod = 'transfer';
              onPaid();
            }),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        _PaymentChip(
            label: 'Room Charge',
            icon: Icons.hotel,
            selected: order.paymentMethod == 'roomCharge',
            onTap: () {
              order.paymentMethod = 'roomCharge';
              onPaid();
            }),
        const SizedBox(width: 8),
        _PaymentChip(
            label: 'Split',
            icon: Icons.call_split,
            selected: order.paymentMethod == 'split',
            onTap: () {
              order.paymentMethod = 'split';
              onPaid();
            }),
      ]),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: onPaid,
          child: Text('Mark Paid — ₦${order.total.toStringAsFixed(0)}'),
        ),
      ),
    ]);
  }
}

class _PaymentChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _primary : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _primary : AppColors.grey300),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 14, color: selected ? AppColors.white : AppColors.grey700),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.white : AppColors.grey700)),
        ]),
      ),
    );
  }
}

// ─────────────────────── ORDERS TAB ───────────────────────

class _OrdersTab extends StatefulWidget {
  final VoidCallback onChange;
  const _OrdersTab({required this.onChange});
  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: RoleGate(
        requiredPermission: Permission.managePOS,
        child: FloatingActionButton(
          backgroundColor: _primary,
          foregroundColor: AppColors.white,
          tooltip: 'New Order',
          child: const Icon(Icons.add),
          onPressed: () => _openNewOrderSheet(context, onChange: widget.onChange),
        ),
      ),
      body: Column(children: [
        TabBar(
          controller: _subTabController,
          indicatorColor: _primary,
          labelColor: _primary,
          unselectedLabelColor: AppColors.grey500,
          tabs: const [
            Tab(text: 'Active Orders', icon: Icon(Icons.receipt, size: 14)),
            Tab(
                text: 'Kitchen View (KDS)',
                icon: Icon(Icons.restaurant, size: 14)),
          ],
        ),
        Expanded(
            child: TabBarView(controller: _subTabController, children: [
          _ActiveOrders(onChange: widget.onChange),
          _KdsView(onChange: widget.onChange),
        ])),
      ]),
    );
  }
}

class _ActiveOrders extends StatelessWidget {
  final VoidCallback onChange;
  const _ActiveOrders({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final orders = FnbStore.orders
        .where((o) =>
            o.status != OrderStatus.paid && o.status != OrderStatus.cancelled)
        .toList();
    if (orders.isEmpty) return const Center(child: Text('No active orders'));
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: orders.length,
      itemBuilder: (ctx, i) {
        final o = orders[i];
        return Card(
            child: ListTile(
          leading: CircleAvatar(
            backgroundColor:
                o.status == OrderStatus.preparing ? AppColors.orange : _primary,
            child: Text(_shortLocation(o),
                style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
          title: Text('${o.locationLabel} — ₦${o.total.toStringAsFixed(0)}',
              overflow: TextOverflow.ellipsis),
          subtitle: Text(
              '${o.serverName}  •  ${o.items.length} items  •  ${o.status.name}',
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (o.queuedCount > 0)
              statusBadge('${o.queuedCount} queued', color: AppColors.teal),
            if (o.preparingCount > 0) ...[
              const SizedBox(width: 4),
              statusBadge('${o.preparingCount} prep'),
            ],
            if (o.readyCount > 0) ...[
              const SizedBox(width: 4),
              statusBadge('${o.readyCount} ready', color: AppColors.orange),
            ],
          ]),
          onTap: () => _showOrderDetail(context, o),
        ));
      },
    );
  }

  void _showOrderDetail(BuildContext context, Order order) {
    var sentToKitchen = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order — ${order.locationLabel}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('Server: ${order.serverName}  •  ${order.sourceLabel}',
                        style:
                            TextStyle(color: AppColors.grey600, fontSize: 12)),
                    if (order.hasKitchenWork)
                      Text(order.kitchenSummary,
                          style: TextStyle(
                              color: AppColors.grey600, fontSize: 12)),
                    if (order.seenAt != null)
                      Text('First seen ${_fmtTs(order.seenAt!)}',
                          style:
                              TextStyle(color: AppColors.grey600, fontSize: 11)),
                    if (order.readyAt != null)
                      Text('Ready ${_fmtTs(order.readyAt!)}',
                          style:
                              TextStyle(color: AppColors.grey600, fontSize: 11)),
                    if (order.servedAt != null)
                      Text('Served ${_fmtTs(order.servedAt!)}',
                          style:
                              TextStyle(color: AppColors.grey600, fontSize: 11)),
                    const Divider(),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('${item.quantity}x ${item.name}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      Text(fnbStationLabel(item.station),
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.grey500)),
                                    ])),
                            Text('₦${item.total.toStringAsFixed(0)}'),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                order.advanceItem(item);
                                if (order.allServed) {
                                  order.status = OrderStatus.served;
                                }
                                FnbStore.updateOrder(order.id, order);
                                setSheetState(() {});
                                onChange();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _itemStatusColor(item.status)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(kItemStageLabel(item.status),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: _itemStatusColor(item.status))),
                              ),
                            ),
                          ]),
                        )),
                    const Divider(),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('₦${order.total.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: _primary)),
                        ]),
                    const SizedBox(height: 12),
                    if (order.status != OrderStatus.paid &&
                        order.status != OrderStatus.cancelled)
                      Row(children: [
                        if (!order.allServed &&
                            RoleStore.has(Permission.managePOS))
                          Expanded(
                              child: ElevatedButton(
                            onPressed: sentToKitchen
                                ? null
                                : () {
                                    if (order.status == OrderStatus.open) {
                                      order.status = OrderStatus.preparing;
                                      FnbStore.updateOrder(order.id, order);
                                    }
                                    _feedOrder('order.kitchen', order,
                                        'Sent to kitchen');
                                    setSheetState(
                                        () => sentToKitchen = true);
                                    onChange();
                                  },
                            child: Text(sentToKitchen
                                ? 'In Kitchen'
                                : 'Send All to Kitchen'),
                          )),
                        if (order.allServed &&
                            order.status != OrderStatus.paid) ...[
                          Expanded(
                              child: RoleGate(
                            requiredPermission: Permission.managePOS,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  foregroundColor: AppColors.white),
                              onPressed: () {
                                order.status = OrderStatus.paid;
                                final table = FnbStore.tables
                                    .where((t) => t.id == order.tableId)
                                    .firstOrNull;
                                if (table != null)
                                  FnbStore.updateTable(
                                      order.tableId,
                                      RestaurantTable(
                                          id: table.id,
                                          number: table.number,
                                          seats: table.seats,
                                          status: TableStatus.free));
                                FnbStore.updateOrder(order.id, order);
                                _feedOrder('order.paid', order, 'Paid');
                                Navigator.pop(ctx);
                                onChange();
                              },
                              child: const Text('Mark Paid'),
                            ),
                          )),
                        ],
                        const SizedBox(width: 8),
                        if (RoleStore.has(Permission.voidFnbOrders))
                          Expanded(
                              child: TextButton(
                            onPressed: () {
                              order.status = OrderStatus.cancelled;
                              final table = FnbStore.tables
                                  .where((t) => t.id == order.tableId)
                                  .firstOrNull;
                              if (table != null) {
                                FnbStore.updateTable(
                                    table.id,
                                    RestaurantTable(
                                        id: table.id,
                                        number: table.number,
                                        seats: table.seats,
                                        status: TableStatus.free));
                              }
                              FnbStore.updateOrder(order.id, order);
                              Navigator.pop(ctx);
                              onChange();
                            },
                            child: const Text('Cancel',
                                style: TextStyle(color: AppColors.red)),
                          )),
                        const SizedBox(width: 8),
                        if (RoleStore.has(Permission.voidFnbOrders))
                          Expanded(
                              child: RoleGate(
                            requiredPermission: Permission.voidFnbOrders,
                            child: TextButton(
                              onPressed: () => _confirmDeleteOrder(ctx, order,
                                  () {
                                Navigator.pop(ctx);
                                onChange();
                              }),
                              child: const Text('Delete',
                                  style: TextStyle(color: AppColors.red)),
                            ),
                          )),
                      ]),
                  ]),
            ),
          ),
        ),
      ),
    );
  }

}

void _confirmDeleteOrder(BuildContext ctx, Order order, VoidCallback onDone) {
  showDialog<bool>(
    context: ctx,
    builder: (dctx) => AlertDialog(
      title: const Text('Delete Order?'),
      content: Text(
          'Delete the order for ${order.locationLabel}? This cannot be undone.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.red))),
      ],
    ),
  ).then((confirmed) {
    if (confirmed != true) return;
    FnbStore.removeOrder(order.id);
    _feedOrder('order.deleted', order, 'Deleted');
    if (!FnbStore.orders.any((o) => o.tableId == order.tableId)) {
      final table =
          FnbStore.tables.where((t) => t.id == order.tableId).firstOrNull;
      if (table != null)
        FnbStore.updateTable(
            order.tableId,
            RestaurantTable(
                id: table.id,
                number: table.number,
                seats: table.seats,
                status: TableStatus.free));
    }
    onDone();
  });
}



// ─────────────────────── KITCHEN DISPLAY (KDS) ───────────────────────

/// Kitchen Display System: station-filtered granular pipeline. Each station
/// (Main Kitchen / Suya & Grill / Bar / Pastry) only ever sees its own
/// tickets, and items are advanced through pending → seen → queued →
/// preparing → ready → picked_up → served with first-crossing timestamps.
class _KdsView extends StatefulWidget {
  final VoidCallback onChange;
  const _KdsView({required this.onChange});
  @override
  State<_KdsView> createState() => _KdsViewState();
}

class _KdsViewState extends State<_KdsView> {
  FnbStation _station = FnbStation.general;

  @override
  Widget build(BuildContext context) {
    final stations = FnbStore.stations;
    final station = stations.contains(_station) ? _station : stations.first;
    final orders = FnbStore.orders
        .where((o) =>
            o.status == OrderStatus.open || o.status == OrderStatus.preparing)
        .where((o) => o.items.any((i) => i.station == station && i.isKitchenWork))
        .toList();
    return Column(children: [
      SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          children: [
            for (final s in stations)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  selected: s == station,
                  label: Text(fnbStationLabel(s)),
                  onSelected: (_) => setState(() => _station = s),
                ),
              ),
          ],
        ),
      ),
      Expanded(
        child: orders.isEmpty
            ? Center(
                child: Text(
                    'No orders for ${fnbStationLabel(station)} right now'))
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: orders.length,
                itemBuilder: (ctx, i) {
                  final o = orders[i];
                  final work = o.items
                      .where((item) =>
                          item.station == station && item.isKitchenWork)
                      .toList();
                  return Card(
                    color: AppColors.orange50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.restaurant,
                                  size: 18, color: AppColors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(o.locationLabel,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16))),
                              Text(_elapsedSince(o.createdAt),
                                  style: TextStyle(
                                      color: AppColors.grey600, fontSize: 11)),
                            ]),
                            const SizedBox(height: 2),
                            Row(children: [
                              Text(o.sourceLabel,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.grey600,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              if (o.seenAt == null)
                                statusBadge('Fresh', color: AppColors.blue)
                              else if (o.queuedAt == null)
                                statusBadge('Seen', color: AppColors.blue)
                              else if (o.readyAt == null)
                                statusBadge('In prep',
                                    color: AppColors.orange)
                              else if (!o.allServed)
                                statusBadge('Ready', color: AppColors.green)
                              else
                                statusBadge('Served', color: _primary),
                              const Spacer(),
                              Text(o.serverName,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.grey600)),
                            ]),
                            const Divider(),
                            ...work.map((item) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(children: [
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('${item.quantity}x ${item.name}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 15)),
                                              if (item.note != null &&
                                                  item.note!.isNotEmpty)
                                                Text('• ${item.note}',
                                                    style: TextStyle(
                                                        color: AppColors.grey600,
                                                        fontSize: 11)),
                                            ])),
                                    const SizedBox(width: 8),
                                    statusBadge(kItemStageLabel(item.status),
                                        color: _itemStatusColor(item.status)),
                                    const SizedBox(width: 8),
                                    RoleGate(
                                      requiredPermission: Permission.manageKDS,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: _primary,
                                            foregroundColor: AppColors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4)),
                                        onPressed: () {
                                          o.advanceItem(item);
                                          if (o.allServed) {
                                            o.status = OrderStatus.served;
                                          }
                                          FnbStore.updateOrder(o.id, o);
                                          widget.onChange();
                                        },
                                        child: Text(
                                            _kdsAdvanceLabel(item.status),
                                            style:
                                                const TextStyle(fontSize: 11)),
                                      ),
                                    ),
                                  ]),
                                )),
                          ]),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}

String _elapsedSince(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  return '${d.inHours}h ${d.inMinutes % 60}m';
}

String _kdsAdvanceLabel(String status) => switch (status) {
      'pending' => 'Accept',
      'seen' => 'Queue',
      'queued' => 'Start',
      'preparing' => 'Ready',
      'ready' => 'Pickup',
      'picked_up' => 'Served',
      _ => 'Done',
    };

Color _itemStatusColor(String status) {
  switch (status) {
    case 'pending':
      return AppColors.blue;
    case 'seen':
    case 'queued':
      return AppColors.teal;
    case 'preparing':
      return AppColors.orange;
    case 'ready':
    case 'picked_up':
      return AppColors.green;
    case 'served':
      return _primary;
    case 'cancelled':
      return AppColors.red;
    default:
      return AppColors.grey500;
  }
}

// ─────────────────────── MENU TAB ───────────────────────

class _MenuTab extends StatefulWidget {
  final VoidCallback onChange;
  const _MenuTab({required this.onChange});
  @override
  State<_MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<_MenuTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final items = _search.isEmpty
        ? FnbStore.menu
        : FnbStore.menu
            .where((m) => m.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();
    return Scaffold(
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: const InputDecoration(
                hintText: 'Search menu...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder()),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No menu items'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _categoryColor(item.category)
                            .withValues(alpha: 0.2),
                        child: Text(item.category[0].toUpperCase(),
                            style: TextStyle(
                                color: _categoryColor(item.category),
                                fontWeight: FontWeight.w700)),
                      ),
                      title: Text(item.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '${item.category}  •  ${fnbStationLabel(item.station)}  •  ${item.available ? 'Available' : 'Unavailable'}',
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('₦${item.price.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, color: _primary)),
                        const SizedBox(width: 8),
                        RoleGate(
                          requiredPermission: Permission.managePOS,
                          child: HomTileAction(
                            icon: Icons.edit_rounded,
                            onPressed: () => _showItemForm(context, item: item),
                          ),
                        ),
                        RoleGate(
                          requiredPermission: Permission.managePOS,
                          child: HomTileAction(
                            icon: Icons.delete_rounded,
                            color: AppColors.redAccent,
                            onPressed: () {
                              FnbStore.removeMenuItem(item.id);
                              setState(() {});
                              widget.onChange();
                            },
                          ),
                        ),
                      ]),
                    );
                  },
                ),
        ),
      ]),
      floatingActionButton: RoleGate(
        requiredPermission: Permission.managePOS,
        child: FloatingActionButton(
          backgroundColor: _primary,
          foregroundColor: AppColors.white,
          child: const Icon(Icons.add),
          onPressed: () => _showItemForm(context),
        ),
      ),
    );
  }

  Color _categoryColor(String c) {
    switch (c) {
      case 'food':
        return AppColors.orange;
      case 'drink':
        return AppColors.blue;
      case 'bar':
        return AppColors.purple;
      case 'wine':
        return AppColors.red;
      case 'special':
        return AppColors.teal;
      default:
        return AppColors.grey600;
    }
  }

  void _showItemForm(BuildContext context, {MenuItem? item}) {
    final nameCtl = TextEditingController(text: item?.name ?? '');
    final descCtl = TextEditingController(text: item?.description ?? '');
    final priceCtl =
        TextEditingController(text: item?.price.toStringAsFixed(0) ?? '');
    String cat = item?.category.isNotEmpty == true
        ? item!.category
        : FnbStore.categories.first;
    bool available = item?.available ?? true;
    FnbStation station = item?.station ?? MenuItem.stationForCategory(cat);
    bool stationTouched = item != null;

    void pickNewCategory(StateSetter setSheetState) {
      final ctl = TextEditingController();
      showDialog<String>(
        context: context,
        builder: (dctx) => AlertDialog(
          title: const Text('New category'),
          content: TextField(
              controller: ctl,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'Category name', border: OutlineInputBorder())),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dctx),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.pop(
                    dctx, ctl.text.trim().toLowerCase().replaceAll(' ', '_'));
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ).then((value) {
        if (value != null && value.isNotEmpty) {
          setSheetState(() => cat = value);
        }
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(item == null ? 'Add Menu Item' : 'Edit Menu Item',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(
                        labelText: 'Item Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: descCtl,
                    decoration: const InputDecoration(
                        labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 12),
                TextField(
                    controller: priceCtl,
                    decoration: const InputDecoration(
                        labelText: 'Price (₦)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('menu-cat-$cat'),
                  initialValue: cat,
                  decoration: const InputDecoration(
                      labelText: 'Category', border: OutlineInputBorder()),
                  items: [
                    ...FnbStore.categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c))),
                    const DropdownMenuItem(
                        value: '__new__', child: Text('+ New category…')),
                  ],
                  onChanged: (v) {
                    if (v == '__new__') {
                      pickNewCategory(setSheetState);
                    } else if (v != null) {
                      setSheetState(() {
                        cat = v;
                        if (!stationTouched) {
                          station = MenuItem.stationForCategory(v);
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FnbStation>(
                  key: ValueKey('menu-station-$station'),
                  initialValue: station,
                  decoration: const InputDecoration(
                      labelText: 'Station', border: OutlineInputBorder()),
                  items: FnbStation.values
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text(fnbStationLabel(s))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setSheetState(() {
                        station = v;
                        stationTouched = true;
                      });
                    }
                  },
                ),
                SwitchListTile(
                    value: available,
                    onChanged: (v) => setSheetState(() => available = v),
                    title: const Text('Available'),
                    contentPadding: EdgeInsets.zero),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      final price = double.tryParse(priceCtl.text) ?? 0;
                      if (nameCtl.text.isEmpty || price <= 0) return;
                      final m = MenuItem(
                        id: item?.id ??
                            'm_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtl.text,
                        description: descCtl.text.isEmpty ? null : descCtl.text,
                        category: cat,
                        price: price,
                        available: available,
                        station: station,
                      );
                      if (item != null) {
                        FnbStore.updateMenuItem(item.id, m);
                      } else {
                        FnbStore.addMenuItem(m);
                      }
                      Navigator.pop(ctx);
                      setState(() {});
                      widget.onChange();
                    },
                    child: Text(item == null ? 'Add Item' : 'Update Item'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── MENU SELECTOR (for order creation) ───────────────────────

class _MenuSelector extends StatefulWidget {
  final Order order;
  final VoidCallback? onChange;
  const _MenuSelector({required this.order, this.onChange});
  @override
  State<_MenuSelector> createState() => _MenuSelectorState();
}

class _MenuSelectorState extends State<_MenuSelector> {
  void _add(MenuItem item, int qty, String? note) {
    setState(() {
      widget.order.items.add(OrderItem(
        menuItemId: item.id,
        name: item.name,
        quantity: qty,
        unitPrice: item.price,
        note: note,
        station: item.station,
      ));
    });
    FnbStore.updateOrder(widget.order.id, widget.order);
    widget.onChange?.call();
  }

  void _remove(OrderItem it) {
    setState(() => widget.order.items.remove(it));
    FnbStore.updateOrder(widget.order.id, widget.order);
    widget.onChange?.call();
  }

  @override
  Widget build(BuildContext context) {
    final cats = FnbStore.categories;
    final items = widget.order.items;
    final count = items.fold<int>(0, (a, i) => a + i.quantity);
    final total = items.fold<double>(0, (a, i) => a + i.quantity * i.unitPrice);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Add Items',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(
              count == 0
                  ? 'Nothing added yet'
                  : '$count item${count == 1 ? '' : 's'} in this order',
              style: const TextStyle(fontSize: 11, color: AppColors.grey600),
            ),
          ],
        ),
      ),
      if (items.isNotEmpty)
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 132),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final it in items)
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 16),
                    color: AppColors.grey500,
                    onPressed: () => _remove(it),
                  ),
                  title: Text('${it.quantity}x ${it.name}',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    '₦${(it.quantity * it.unitPrice).toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      if (cats.isEmpty)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
              child:
                  Text('Menu is empty — add items in the Menu tab first.')),
        )
      else
        DefaultTabController(
          length: cats.length,
          child: Column(children: [
            TabBar(
              isScrollable: true,
              indicatorColor: _primary,
              labelColor: _primary,
              unselectedLabelColor: AppColors.grey500,
              tabs: cats.map((c) => Tab(text: c.toUpperCase())).toList(),
            ),
            SizedBox(
              height: 260,
              child: TabBarView(
                  children: cats
                      .map((c) => _CategoryMenu(category: c, onAdd: _add))
                      .toList()),
            ),
          ]),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total',
                    style: TextStyle(fontSize: 11, color: AppColors.grey600)),
                Text('₦${total.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _primary)),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12)),
              onPressed: () => Navigator.pop(context),
              child: Text(count == 0
                  ? 'Close'
                  : 'Confirm Order — ₦${total.toStringAsFixed(0)}'),
            ),
          ],
        ),
      ),
    ]);
  }
}

class _CategoryMenu extends StatelessWidget {
  final String category;
  final void Function(MenuItem item, int qty, String? note) onAdd;
  const _CategoryMenu({required this.category, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final items = FnbStore.menuByCategory(category);
    if (items.isEmpty) return const Center(child: Text('No items'));
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        int qty = 1;
        return ListTile(
          title: Text(item.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
          subtitle: item.description != null
              ? Text(item.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11))
              : null,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('₦${item.price.toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.w800, color: _primary)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_shopping_cart, size: 20),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (dCtx) => StatefulBuilder(
                          builder: (dCtx, setDState) => AlertDialog(
                            scrollable: true,
                            title: Text(item.name),
                            content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(children: [
                                    IconButton(
                                        onPressed: () {
                                          if (qty > 1) setDState(() => qty--);
                                        },
                                        icon: const Icon(Icons.remove)),
                                    Text('$qty',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800)),
                                    IconButton(
                                        onPressed: () => setDState(() => qty++),
                                        icon: const Icon(Icons.add)),
                                  ]),
                                ]),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(dCtx),
                                  child: const Text('Cancel')),
                              ElevatedButton(
                                  onPressed: () {
                                    onAdd(item, qty, null);
                                    Navigator.pop(dCtx);
                                  },
                                  child: const Text('Add to Order')),
                            ],
                          ),
                        ));
              },
            ),
          ]),
        );
      },
    );
  }
}

// ─────────────────────── HELPERS ───────────────────────

Widget statusBadge(String text, {Color? color}) {
  final c = color ?? _primary;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8)),
    child: Text(text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
  );
}

/// Short avatar label for an order: room number, `TA` for takeaway, `BW` for a
/// bar walk-up, `DC` for a direct kitchen call, otherwise the table number.
String _shortLocation(Order o) {
  if (o.orderType == OrderType.roomService) {
    final room = (o.roomNumber ?? '').trim();
    return room.isEmpty ? 'RS' : room;
  }
  if (o.orderType == OrderType.takeaway) return 'TA';
  if (o.orderType == OrderType.barWalkup) return 'BW';
  if (o.orderType == OrderType.directCall) return 'DC';
  return o.tableNumber.trim().isEmpty ? 'DI' : o.tableNumber;
}

String _orderTypeLabel(OrderType t) {
  switch (t) {
    case OrderType.dineIn:
      return 'Dine-in';
    case OrderType.roomService:
      return 'Room Service';
    case OrderType.takeaway:
      return 'Takeaway';
    case OrderType.barWalkup:
      return 'Bar Walk-up';
    case OrderType.directCall:
      return 'Direct Call';
  }
}

String _fmtTs(DateTime t) =>
    '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')} '
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

class _OrderTypeChip extends StatelessWidget {
  final OrderType type;
  final bool selected;
  final VoidCallback onTap;
  const _OrderTypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? _primary : AppColors.grey300, width: 1.2),
        ),
        child: Text(_orderTypeLabel(type),
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.white : AppColors.grey700)),
      ),
    );
  }
}

/// Bottom-sheet that lets staff punch in a brand-new order: pick the order
/// type (dine-in table, room-service room, or takeaway), tag the server and
/// jump straight into the menu selector.
void _openNewOrderSheet(BuildContext context, {VoidCallback? onChange}) {
  final nameCtl = TextEditingController(text: RoleStore.current.userName);
  final roomCtl = TextEditingController();
  OrderType type = OrderType.dineIn;
  final freeTables =
      FnbStore.tables.where((t) => t.status == TableStatus.free).toList();
  RestaurantTable? table = freeTables.isNotEmpty ? freeTables.first : null;

  final activeRooms = <String>{
    for (final b in app.HOMData.bookings)
      if (b.status == 'checked-in' && b.room.trim().isNotEmpty) b.room.trim(),
  }.toList()
    ..sort();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New Order',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: OrderType.values
                        .map((t) => _OrderTypeChip(
                              type: t,
                              selected: type == t,
                              onTap: () => setSheetState(() => type = t),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  if (type == OrderType.dineIn) ...[
                    if (freeTables.isEmpty)
                      const Text('No free tables right now.',
                          style: TextStyle(color: AppColors.grey600))
                    else
                      DropdownButtonFormField<RestaurantTable>(
                        initialValue: table,
                        decoration: const InputDecoration(
                            labelText: 'Table',
                            border: OutlineInputBorder()),
                        items: freeTables
                            .map((t) => DropdownMenuItem(
                                value: t,
                                child:
                                    Text('${t.number} (${t.seats} seats)')))
                            .toList(),
                        onChanged: (v) =>
                            setSheetState(() => table = v ?? table),
                      ),
                  ],
                  if (type == OrderType.roomService) ...[
                    TextField(
                        controller: roomCtl,
                        decoration: const InputDecoration(
                            labelText: 'Room Number',
                            hintText: 'e.g. 102',
                            border: OutlineInputBorder())),
                    if (activeRooms.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('In-house:',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.grey600)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        children: activeRooms
                            .map((r) => ActionChip(
                                  label: Text(r,
                                      style: const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () =>
                                      setSheetState(() => roomCtl.text = r),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  TextField(
                      controller: nameCtl,
                      decoration: const InputDecoration(
                          labelText: 'Server Name',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: RoleGate(
                      requiredPermission: Permission.managePOS,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () {
                          if (type == OrderType.dineIn && table == null) return;
                          final order = Order(
                            id: FnbStore.genOrderId(),
                            tableId: type == OrderType.dineIn
                                ? (table?.id ?? '')
                                : '',
                            tableNumber: type == OrderType.dineIn
                                ? (table?.number ?? '')
                                : '',
                            serverName: nameCtl.text.trim().isEmpty
                                ? 'Staff'
                                : nameCtl.text.trim(),
                            orderType: type,
                            roomNumber: type == OrderType.roomService
                                ? roomCtl.text.trim()
                                : null,
                          );
                          FnbStore.addOrder(order);
                          _feedOrder('order.created', order, 'New');
                          if (type == OrderType.dineIn && table != null) {
                            final t = table!;
                            FnbStore.updateTable(
                                t.id,
                                RestaurantTable(
                                    id: t.id,
                                    number: t.number,
                                    seats: t.seats,
                                    status: TableStatus.occupied));
                          }
                          Navigator.pop(ctx);
                          onChange?.call();
                          _showAddItemsForOrder(context, order,
                              onChange: onChange);
                        },
                        child: const Text('Create & Add Items'),
                      ),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    ),
  );
}

/// Menu selector used while punching items into a freshly created order.
void _showAddItemsForOrder(BuildContext context, Order order,
    {VoidCallback? onChange}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.98,
          expand: false,
          builder: (ctx, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: _MenuSelector(order: order, onChange: onChange),
          ),
        ),
      ),
    ),
  );
}
