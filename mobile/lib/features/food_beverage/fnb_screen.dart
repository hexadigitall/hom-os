import 'package:flutter/material.dart';
import '../../models/food_beverage.dart';
import '../../data/fnb_store.dart';
import '../../data/role_store.dart';
import '../../utils/role_gate.dart';
import '../../models/role.dart';
import '../../widgets/hom_widgets.dart';
import '../../utils/theme.dart';

final Color _primary = AppColors.primary;

class FnbScreen extends StatefulWidget {
  const FnbScreen({super.key});
  @override
  State<FnbScreen> createState() => _FnbScreenState();
}

class _FnbScreenState extends State<FnbScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('F&B Operations'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _primary,
          labelColor: _primary,
          unselectedLabelColor: AppColors.grey500,
          tabs: const [
            Tab(text: 'Tables', icon: Icon(Icons.table_restaurant_rounded, size: 16)),
            Tab(text: 'Orders', icon: Icon(Icons.receipt_long_rounded, size: 16)),
            Tab(text: 'Menu', icon: Icon(Icons.menu_book_rounded, size: 16)),
          ],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [
        _TablesTab(onOrderTap: () => setState(() {})),
        _OrdersTab(onChange: () => setState(() {})),
        _MenuTab(onChange: () => setState(() {})),
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
      case TableStatus.free: return _primary;
      case TableStatus.occupied: return AppColors.red400;
      case TableStatus.reserved: return AppColors.orange;
      case TableStatus.cleaning: return AppColors.grey500;
    }
  }

  String _tableLabel(TableStatus s) {
    switch (s) {
      case TableStatus.free: return 'Free';
      case TableStatus.occupied: return 'Occupied';
      case TableStatus.reserved: return 'Reserved';
      case TableStatus.cleaning: return 'Cleaning';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tables = FnbStore.tables;
    final compact = isCompact(context);
    final crossAxisCount = compact ? (isLandscape(context) ? 4 : 3) : (isLandscape(context) ? 6 : 4);
    return Scaffold(
      body: tables.isEmpty
          ? const Center(child: Text('No tables configured'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.85,
              ),
              itemCount: tables.length,
              itemBuilder: (ctx, i) {
                final t = tables[i];
                final color = _tableColor(t.status);
                final openOrder = FnbStore.orderForTable(t.id);
                return GestureDetector(
                  onTap: () {
                    if (t.status == TableStatus.free) {
                      _showCreateOrder(context, t);
                    } else if (openOrder != null) {
                      _showOrderDetail(context, openOrder);
                    }
                  },
                  onLongPress: () => _showTableActions(context, t),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(t.number, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
                      const SizedBox(height: 4),
                      Text('${t.seats} seats', style: TextStyle(fontSize: 10, color: AppColors.grey600)),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                        child: Text(_tableLabel(t.status), style: const TextStyle(color: AppColors.white, fontSize: 9, fontWeight: FontWeight.w700)),
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
      context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Table ${t.number}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
                FnbStore.updateTable(t.id, RestaurantTable(id: t.id, number: t.number, seats: t.seats, status: s));
                Navigator.pop(ctx);
                widget.onOrderTap();
              },
            ),
          if (t.status == TableStatus.occupied)
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.red, size: 20),
              title: const Text('Remove Table', style: TextStyle(color: AppColors.red), overflow: TextOverflow.ellipsis),
              onTap: () { FnbStore.removeTable(t.id); Navigator.pop(ctx); widget.onOrderTap(); },
            ),
        ]),
      )),
    );
  }

  void _showTableForm(BuildContext context, {RestaurantTable? table}) {
    final nameCtl = TextEditingController(text: table?.number ?? '');
    final capacityCtl = TextEditingController(text: table?.seats.toString() ?? '');
    TableStatus status = table?.status ?? TableStatus.free;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(table == null ? 'Add Table' : 'Edit Table', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Table Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: capacityCtl, decoration: const InputDecoration(labelText: 'Capacity (seats)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              if (table != null) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<TableStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  items: TableStatus.values.map((s) => DropdownMenuItem(value: s, child: Row(children: [
                    Icon(Icons.circle, color: _tableColor(s), size: 14),
                    const SizedBox(width: 8),
                    Text(_tableLabel(s)),
                  ]))).toList(),
                  onChanged: (v) { if (v != null) setSheetState(() => status = v); },
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: RoleGate(
                  requiredPermission: Permission.manageTableManagement,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
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
    );
  }

  void _showCreateOrder(BuildContext context, RestaurantTable t) {
    final nameCtl = TextEditingController(text: RoleStore.current.userName);
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('New Order — Table ${t.number}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Server Name', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {
                final order = Order(
                  id: FnbStore.genOrderId(), tableId: t.id, tableNumber: t.number,
                  serverName: nameCtl.text.trim().isEmpty ? 'Staff' : nameCtl.text.trim(),
                );
                FnbStore.addOrder(order);
                FnbStore.updateTable(t.id, RestaurantTable(id: t.id, number: t.number, seats: t.seats, status: TableStatus.occupied));
                Navigator.pop(ctx);
                widget.onOrderTap();
                _showAddItems(context, order);
              },
              child: const Text('Create & Add Items'),
            ),
          ),
        ]),
      ),
      ),
    );
  }

  void _showAddItems(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85, minChildSize: 0.4, maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) => _MenuSelector(
            onAdd: (item, qty, note) {
              order.items.add(OrderItem(
                menuItemId: item.id, name: item.name,
                quantity: qty, unitPrice: item.price, note: note,
              ));
              FnbStore.updateOrder(order.id, order);
              (ctx as Element).markNeedsBuild();
            },
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  void _showOrderDetail(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Order — Table ${order.tableNumber}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text('Server: ${order.serverName}  •  ${order.status.name}', style: TextStyle(color: AppColors.grey600, fontSize: 12)),
            const Divider(),
            if (order.items.isEmpty)
              const Padding(padding: EdgeInsets.all(16), child: Text('No items yet'))
            else
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(child: Text('${item.quantity}x ${item.name}', style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text('₦${item.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  statusBadge(item.status),
                ]),
              )),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text('₦${order.total.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _primary)),
            ]),
            const SizedBox(height: 12),
            if (order.status == OrderStatus.open || order.status == OrderStatus.preparing)
              Row(children: [
                Expanded(child: ElevatedButton(
                  onPressed: () { _showAddItems(context, order); setSheetState(() {}); },
                  child: const Text('Add Items'),
                )),
                const SizedBox(width: 8),
                if (order.items.isNotEmpty)
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: AppColors.white),
                    onPressed: () {
                      for (final item in order.items) {
                        if (item.status == 'pending') item.status = 'preparing';
                      }
                      order.status = OrderStatus.preparing;
                      FnbStore.updateOrder(order.id, order);
                      setSheetState(() {});
                    },
                    child: const Text('Send to Kitchen'),
                  )),
              ]),
            if (order.allServed && order.status != OrderStatus.paid)
              _PaymentSection(order: order, onPaid: () {
                final table = FnbStore.tables.cast<RestaurantTable?>().firstWhere((t) => t!.id == order.tableId, orElse: () => null);
                if (table != null) FnbStore.updateTable(order.tableId, RestaurantTable(id: table.id, number: table.number, seats: table.seats, status: TableStatus.free));
                order.status = OrderStatus.paid;
                FnbStore.updateOrder(order.id, order);
                setSheetState(() {});
                widget.onOrderTap();
              }),
          ]),
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
      const Text('Payment', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      const SizedBox(height: 8),
      Row(children: [
        _PaymentChip(label: 'Cash', icon: Icons.money, selected: order.paymentMethod == 'cash', onTap: () { order.paymentMethod = 'cash'; onPaid(); }),
        const SizedBox(width: 8),
        _PaymentChip(label: 'Card', icon: Icons.credit_card, selected: order.paymentMethod == 'card', onTap: () { order.paymentMethod = 'card'; onPaid(); }),
        const SizedBox(width: 8),
        _PaymentChip(label: 'Transfer', icon: Icons.phone_android, selected: order.paymentMethod == 'transfer', onTap: () { order.paymentMethod = 'transfer'; onPaid(); }),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        _PaymentChip(label: 'Room Charge', icon: Icons.hotel, selected: order.paymentMethod == 'roomCharge', onTap: () { order.paymentMethod = 'roomCharge'; onPaid(); }),
        const SizedBox(width: 8),
        _PaymentChip(label: 'Split', icon: Icons.call_split, selected: order.paymentMethod == 'split', onTap: () { order.paymentMethod = 'split'; onPaid(); }),
      ]),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
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
  const _PaymentChip({required this.label, required this.icon, required this.selected, required this.onTap});

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
          Icon(icon, size: 14, color: selected ? AppColors.white : AppColors.grey700),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? AppColors.white : AppColors.grey700)),
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

class _OrdersTabState extends State<_OrdersTab> with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() { super.initState(); _subTabController = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _subTabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TabBar(
        controller: _subTabController, indicatorColor: _primary, labelColor: _primary, unselectedLabelColor: AppColors.grey500,
        tabs: const [
          Tab(text: 'Active Orders', icon: Icon(Icons.receipt, size: 14)),
          Tab(text: 'Kitchen View (KDS)', icon: Icon(Icons.restaurant, size: 14)),
        ],
      ),
      Expanded(child: TabBarView(controller: _subTabController, children: [
        _ActiveOrders(onChange: widget.onChange),
        _KdsView(onChange: widget.onChange),
      ])),
    ]);
  }
}

class _ActiveOrders extends StatelessWidget {
  final VoidCallback onChange;
  const _ActiveOrders({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final orders = FnbStore.orders.where((o) => o.status != OrderStatus.paid && o.status != OrderStatus.cancelled).toList();
    if (orders.isEmpty) return const Center(child: Text('No active orders'));
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: orders.length,
      itemBuilder: (ctx, i) {
        final o = orders[i];
        return Card(child: ListTile(
          leading: CircleAvatar(
            backgroundColor: o.status == OrderStatus.preparing ? AppColors.orange : _primary,
            child: Text(o.tableNumber, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          title: Text('Table ${o.tableNumber} — ₦${o.total.toStringAsFixed(0)}', overflow: TextOverflow.ellipsis),
          subtitle: Text('${o.serverName}  •  ${o.items.length} items  •  ${o.status.name}', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (o.preparingCount > 0) statusBadge('${o.preparingCount} prep'),
            if (o.readyCount > 0) const SizedBox(width: 4),
            if (o.readyCount > 0) statusBadge('${o.readyCount} ready', color: AppColors.orange),
          ]),
          onTap: () => _showOrderDetail(context, o),
        ));
      },
    );
  }

  void _showOrderDetail(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Order — Table ${order.tableNumber}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text('Server: ${order.serverName}  •  ${order.status.name}', style: TextStyle(color: AppColors.grey600, fontSize: 12)),
            const Divider(),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text('${item.quantity}x ${item.name}', style: const TextStyle(fontWeight: FontWeight.w600))),
                Text('₦${item.total.toStringAsFixed(0)}'),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final next = item.status == 'pending' ? 'preparing' : item.status == 'preparing' ? 'ready' : item.status == 'ready' ? 'served' : 'served';
                    item.status = next;
                    if (order.allServed) order.status = OrderStatus.served;
                    FnbStore.updateOrder(order.id, order);
                    setSheetState(() {});
                    onChange();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.status == 'pending' ? AppColors.blue50 : item.status == 'preparing' ? AppColors.orange50 : item.status == 'ready' ? AppColors.green50 : AppColors.grey100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(item.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: item.status == 'pending' ? AppColors.blue : item.status == 'preparing' ? AppColors.orange : item.status == 'ready' ? AppColors.green : AppColors.grey500)),
                  ),
                ),
              ]),
            )),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text('₦${order.total.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _primary)),
            ]),
            const SizedBox(height: 12),
            if (order.status != OrderStatus.paid && order.status != OrderStatus.cancelled)
              Row(children: [
                if (!order.allServed)
                  Expanded(child: ElevatedButton(
                    onPressed: () {
                      for (final item in order.items) { if (item.status == 'pending') item.status = 'preparing'; }
                      order.status = OrderStatus.preparing;
                      FnbStore.updateOrder(order.id, order);
                      setSheetState(() {});
                      onChange();
                    },
                    child: const Text('Send All to Kitchen'),
                  )),
                if (order.allServed && order.status != OrderStatus.paid) ...[
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: AppColors.white),
                    onPressed: () {
                      order.status = OrderStatus.paid;
                      final table = FnbStore.tables.where((t) => t.id == order.tableId).firstOrNull;
                      if (table != null) FnbStore.updateTable(order.tableId, RestaurantTable(id: table.id, number: table.number, seats: table.seats, status: TableStatus.free));
                      FnbStore.updateOrder(order.id, order);
                      Navigator.pop(ctx);
                      onChange();
                    },
                    child: const Text('Mark Paid'),
                  )),
                ],
                const SizedBox(width: 8),
                Expanded(child: TextButton(
                  onPressed: () { order.status = OrderStatus.cancelled; FnbStore.updateOrder(order.id, order); Navigator.pop(ctx); onChange(); },
                  child: const Text('Cancel', style: TextStyle(color: AppColors.red)),
                )),
              ]),
          ]),
        ),
      ),
      ),
    );
  }
}

// ─────────────────────── KITCHEN DISPLAY (KDS) ───────────────────────

class _KdsView extends StatelessWidget {
  final VoidCallback onChange;
  const _KdsView({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final preparing = FnbStore.orders.where((o) => o.status == OrderStatus.preparing || o.preparingCount > 0).toList();
    if (preparing.isEmpty) return const Center(child: Text('No orders in the kitchen'));
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: preparing.length,
      itemBuilder: (ctx, i) {
        final o = preparing[i];
        return Card(
          color: AppColors.orange50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.restaurant, size: 18, color: AppColors.orange),
                const SizedBox(width: 8),
                Text('Table ${o.tableNumber}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const Spacer(),
                Text(o.createdAt.toIso8601String().substring(11, 19), style: TextStyle(color: AppColors.grey600, fontSize: 11)),
              ]),
              const Divider(),
              ...o.items.where((item) => item.status == 'preparing' || item.status == 'pending').map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(child: Text('${item.quantity}x ${item.name}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                  if (item.note != null && item.note!.isNotEmpty)
                    Text('(${item.note})', style: TextStyle(color: AppColors.grey600, fontSize: 11)),
                  const SizedBox(width: 8),
                  RoleGate(
                    requiredPermission: Permission.manageKDS,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                      onPressed: () {
                        item.status = 'ready';
                        FnbStore.updateOrder(o.id, o);
                        onChange();
                      },
                      child: const Text('Ready', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ]),
              )),
            ]),
          ),
        );
      },
    );
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
        : FnbStore.menu.where((m) => m.name.toLowerCase().contains(_search.toLowerCase())).toList();
    return Scaffold(
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: const InputDecoration(hintText: 'Search menu...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
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
                        backgroundColor: _categoryColor(item.category).withValues(alpha: 0.2),
                        child: Text(item.category.name[0].toUpperCase(), style: TextStyle(color: _categoryColor(item.category), fontWeight: FontWeight.w700)),
                      ),
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                      subtitle: Text('${item.category.name}  •  ${item.available ? 'Available' : 'Unavailable'}', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('₦${item.price.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w800, color: _primary)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          onPressed: () => _showItemForm(context, item: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, size: 18, color: AppColors.redAccent),
                          onPressed: () { FnbStore.removeMenuItem(item.id); setState(() {}); widget.onChange(); },
                        ),
                      ]),
                    );
                  },
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add),
        onPressed: () => _showItemForm(context),
      ),
    );
  }

  Color _categoryColor(MenuCategory c) {
    switch (c) {
      case MenuCategory.food: return AppColors.orange;
      case MenuCategory.drink: return AppColors.blue;
      case MenuCategory.bar: return AppColors.purple;
      case MenuCategory.wine: return AppColors.red;
      case MenuCategory.special: return AppColors.teal;
    }
  }

  void _showItemForm(BuildContext context, {MenuItem? item}) {
    final nameCtl = TextEditingController(text: item?.name ?? '');
    final descCtl = TextEditingController(text: item?.description ?? '');
    final priceCtl = TextEditingController(text: item?.price.toStringAsFixed(0) ?? '');
    MenuCategory cat = item?.category ?? MenuCategory.food;
    bool available = item?.available ?? true;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(item == null ? 'Add Menu Item' : 'Edit Menu Item', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descCtl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 12),
            TextField(controller: priceCtl, decoration: const InputDecoration(labelText: 'Price (₦)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            DropdownButtonFormField<MenuCategory>(
              initialValue: cat, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: MenuCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (v) { if (v != null) setSheetState(() => cat = v); },
            ),
            SwitchListTile(value: available, onChanged: (v) => setSheetState(() => available = v), title: const Text('Available'), contentPadding: EdgeInsets.zero),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  final price = double.tryParse(priceCtl.text) ?? 0;
                  if (nameCtl.text.isEmpty || price <= 0) return;
                  final m = MenuItem(
                    id: item?.id ?? 'm_${DateTime.now().millisecondsSinceEpoch}', name: nameCtl.text,
                    description: descCtl.text.isEmpty ? null : descCtl.text,
                    category: cat, price: price, available: available,
                  );
                  if (item != null) { FnbStore.updateMenuItem(item.id, m); } else { FnbStore.addMenuItem(m); }
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
    );
  }
}

// ─────────────────────── MENU SELECTOR (for order creation) ───────────────────────

class _MenuSelector extends StatefulWidget {
  final void Function(MenuItem item, int qty, String? note) onAdd;
  final ScrollController scrollController;
  const _MenuSelector({required this.onAdd, required this.scrollController});
  @override
  State<_MenuSelector> createState() => _MenuSelectorState();
}

class _MenuSelectorState extends State<_MenuSelector> with SingleTickerProviderStateMixin {
  late TabController _catTab;

  @override
  void initState() { super.initState(); _catTab = TabController(length: MenuCategory.values.length, vsync: this); }
  @override
  void dispose() { _catTab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TabBar(
        controller: _catTab, isScrollable: true, indicatorColor: _primary, labelColor: _primary, unselectedLabelColor: AppColors.grey500,
        tabs: MenuCategory.values.map((c) => Tab(text: c.name.toUpperCase())).toList(),
      ),
      Expanded(child: TabBarView(controller: _catTab, children: MenuCategory.values.map((c) => _CategoryMenu(category: c, onAdd: widget.onAdd)).toList())),
    ]);
  }
}

class _CategoryMenu extends StatelessWidget {
  final MenuCategory category;
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
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          subtitle: item.description != null ? Text(item.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)) : null,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('₦${item.price.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w800, color: _primary)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_shopping_cart, size: 20),
              onPressed: () {
                showDialog(context: context, builder: (dCtx) => StatefulBuilder(
                  builder: (dCtx, setDState) => AlertDialog(
                    title: Text(item.name),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        IconButton(onPressed: () { if (qty > 1) setDState(() => qty--); }, icon: const Icon(Icons.remove)),
                        Text('$qty', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        IconButton(onPressed: () => setDState(() => qty++), icon: const Icon(Icons.add)),
                      ]),
                    ]),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                      ElevatedButton(onPressed: () { onAdd(item, qty, null); Navigator.pop(dCtx); }, child: const Text('Add to Order')),
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
    decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
  );
}


