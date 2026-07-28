import 'package:flutter/material.dart';

const Color primaryGreen = Color(0xFF0E9F6E);
const Color darkGreen = Color(0xFF0B7A55);
const Color inkBlack = Color(0xFF0E1A14);

void main() => runApp(const HOMApp());

class HOMApp extends StatelessWidget {
  const HOMApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HOM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: primaryGreen,
        scaffoldBackgroundColor: const Color(0xFFF6F7F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      home: const HomeShell(),
    );
  }
}

// ===================== SHELL =====================

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  static const _labels = ['Overview', 'Bookings', 'Rooms', 'Diesel', 'Inventory', 'Staff', 'Vendors'];
  static const _icons = [
    Icons.dashboard_rounded, Icons.calendar_month_rounded, Icons.bed_rounded,
    Icons.local_gas_station_rounded, Icons.inventory_2_rounded, Icons.people_rounded, Icons.store_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Image.asset('assets/logo/logo.png', height: 26, errorBuilder: (c, e, s) => const SizedBox.shrink()),
          const SizedBox(width: 10),
          Text('HOM — ${_labels[_tab]}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: primaryGreen)),
          ),
        ]),
      ),
      body: _screens[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: List.generate(7, (i) => NavigationDestination(
          icon: Icon(_icons[i], size: 22),
          label: _labels[i],
        )),
      ),
    );
  }

  List<Widget> get _screens => const [
    OverviewScreen(), BookingsScreen(), RoomsScreen(), DieselScreen(),
    InventoryScreen(), StaffScreen(), VendorsScreen(),
  ];
}

// ===================== MODELS =====================

class Room {
  String id, number, type, status;
  int price;
  Room({required this.id, required this.number, required this.type, required this.status, required this.price});
}

class Booking {
  String id, guest, phone, room, checkin, checkout, status;
  int amount;
  Booking({required this.id, required this.guest, required this.phone, required this.room, required this.checkin, required this.checkout, required this.status, required this.amount});
}

class DieselLog {
  String id, date, supplier, note;
  int liters, cost, genHours;
  DieselLog({required this.id, required this.date, required this.liters, required this.cost, required this.supplier, required this.genHours, required this.note});
}

class InventoryItem {
  String id, name;
  int qty, low, cost;
  InventoryItem({required this.id, required this.name, required this.qty, required this.low, required this.cost});
}

class StaffMember {
  String id, name, role;
  int salary;
  StaffMember({required this.id, required this.name, required this.role, required this.salary});
}

class Vendor {
  String id, name, contact, category;
  Vendor({required this.id, required this.name, required this.contact, required this.category});
}

class PurchaseOrder {
  String id, vendorId, items, date, status;
  int amount;
  PurchaseOrder({required this.id, required this.vendorId, required this.items, required this.amount, required this.date, required this.status});
}

String _uid() => DateTime.now().millisecondsSinceEpoch.toRadixString(36);
String _today() => DateTime.now().toIso8601String().substring(0, 10);

// ===================== SHARED DATA =====================

class HOMData {
  static final rooms = <Room>[
    Room(id: 'r1', number: '101', type: 'Deluxe', status: 'available', price: 25000),
    Room(id: 'r2', number: '102', type: 'Deluxe', status: 'occupied', price: 25000),
    Room(id: 'r3', number: '103', type: 'Standard', status: 'available', price: 15000),
    Room(id: 'r4', number: '201', type: 'Executive', status: 'maintenance', price: 40000),
    Room(id: 'r5', number: '202', type: 'Executive', status: 'available', price: 40000),
  ];
  static final bookings = <Booking>[
    Booking(id: 'b1', guest: 'John Doe', phone: '08031234567', room: '102', checkin: '2026-07-27', checkout: '2026-07-29', status: 'checked-in', amount: 50000),
  ];
  static final diesel = <DieselLog>[
    DieselLog(id: 'd1', date: '2026-07-26', liters: 200, cost: 240000, supplier: 'MRS PH', genHours: 12, note: 'No theft'),
  ];
  static final inventory = <InventoryItem>[
    InventoryItem(id: 'i1', name: 'Tissue Roll', qty: 50, low: 10, cost: 500),
    InventoryItem(id: 'i2', name: 'Bottled Water', qty: 8, low: 20, cost: 200),
    InventoryItem(id: 'i3', name: 'Towel Set', qty: 30, low: 10, cost: 2500),
  ];
  static final staff = <StaffMember>[
    StaffMember(id: 's1', name: 'Amina Yusuf', role: 'Front Desk', salary: 120000),
    StaffMember(id: 's2', name: 'Chidi Okonkwo', role: 'Cleaner', salary: 70000),
    StaffMember(id: 's3', name: 'Blessing Eze', role: 'Manager', salary: 200000),
  ];
  static final vendors = <Vendor>[
    Vendor(id: 'v1', name: 'MRS Petroleum', contact: '0801-234-5678', category: 'Fuel'),
    Vendor(id: 'v2', name: 'CleanPro Supplies', contact: '0809-876-5432', category: 'Cleaning'),
  ];
  static final purchaseOrders = <PurchaseOrder>[
    PurchaseOrder(id: 'po1', vendorId: 'v1', items: 'Diesel 500L', amount: 600000, date: '2026-07-25', status: 'delivered'),
  ];
  static int paye(int s) => (s * 0.07).round();
  static int pension(int s) => (s * 0.08).round();
  static int netPay(int s) => s - paye(s) - pension(s);
}

// ===================== HELPERS =====================

Widget _sectionTitle(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
);

Widget _statusChip(String s) {
  Color c;
  switch (s) {
    case 'checked-in': case 'available': case 'approved': case 'delivered':
      c = Colors.green; break;
    case 'cancelled': case 'maintenance':
      c = Colors.red; break;
    default:
      c = Colors.blue;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
    child: Text(s, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
  );
}

void _showForm(BuildContext context, String title, List<Widget> fields, VoidCallback onSave) {
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: Text(title),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: fields)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      ElevatedButton(onPressed: () { onSave(); Navigator.pop(ctx); }, child: const Text('Save')),
    ],
  ));
}

// ===================== OVERVIEW =====================

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final avail = HOMData.rooms.where((r) => r.status == 'available').length;
    final active = HOMData.bookings.where((b) => b.status == 'checked-in').length;
    final low = HOMData.inventory.where((i) => i.qty <= i.low).length;
    final theft = HOMData.diesel.where((dg) => dg.genHours > 0 && dg.liters / dg.genHours < 8).length;

    return ListView(padding: const EdgeInsets.all(16), children: [
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6,
        children: [
          _stat('Rooms', '${HOMData.rooms.length}', '$avail available', Icons.bed_rounded, Colors.blue),
          _stat('Bookings', '$active', '${HOMData.bookings.length} total', Icons.calendar_month_rounded, primaryGreen),
          _stat('Diesel', '${HOMData.diesel.fold(0, (a, b) => a + b.liters)}L', '${HOMData.diesel.length} logs', Icons.local_gas_station_rounded, Colors.amber),
          _stat('Low Stock', '$low', '${HOMData.inventory.length} items', Icons.warning_rounded, Colors.red),
        ],
      ),
      const SizedBox(height: 16),
      if (theft > 0)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
            const SizedBox(width: 10),
            Text('$theft theft alert(s)!', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        )
      else
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16)),
          child: const Row(children: [
            Icon(Icons.check_circle, color: primaryGreen, size: 20),
            SizedBox(width: 10),
            Text('No theft alerts', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
      const SizedBox(height: 16),
      _sectionTitle('Recent Bookings'),
      ...HOMData.bookings.take(3).map((b) => Card(
        child: ListTile(
          title: Text('${b.guest} — Room ${b.room}', style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${b.checkin} → ${b.checkout}'),
          trailing: _statusChip(b.status),
        ),
      )),
    ]);
  }

  Widget _stat(String label, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ]),
    );
  }
}

// ===================== BOOKINGS =====================

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  void _add() {
    final guest = TextEditingController(), phone = TextEditingController(), checkin = TextEditingController(text: _today()), checkout = TextEditingController(text: _today());
    String room = HOMData.rooms.firstWhere((r) => r.status == 'available', orElse: () => HOMData.rooms.first).number;
    _showForm(context, 'New Booking', [
      TextField(controller: guest, decoration: const InputDecoration(labelText: 'Guest name')),
      TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
      StatefulBuilder(builder: (ctx, setSB) => DropdownButtonFormField<String>(
        initialValue: room,
        items: HOMData.rooms.where((r) => r.status == 'available').map((r) => DropdownMenuItem(value: r.number, child: Text('${r.number} — ₦${r.price}'))).toList(),
        onChanged: (v) => setSB(() => room = v!),
        decoration: const InputDecoration(labelText: 'Room'),
      )),
      TextField(controller: checkin, decoration: const InputDecoration(labelText: 'Check-in')),
      TextField(controller: checkout, decoration: const InputDecoration(labelText: 'Check-out')),
    ], () {
      if (guest.text.isEmpty) return;
      final r = HOMData.rooms.firstWhere((rr) => rr.number == room);
      HOMData.bookings.insert(0, Booking(
        id: _uid(), guest: guest.text, phone: phone.text, room: room,
        checkin: checkin.text, checkout: checkout.text, status: 'confirmed', amount: r.price,
      ));
      r.status = 'occupied';
      setState(() {});
    });
  }

  void _edit(Booking b) {
    final guest = TextEditingController(text: b.guest), phone = TextEditingController(text: b.phone);
    _showForm(context, 'Edit Booking', [
      TextField(controller: guest, decoration: const InputDecoration(labelText: 'Guest')),
      TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
    ], () { b.guest = guest.text; b.phone = phone.text; setState(() {}); });
  }

  void _checkout(Booking b) {
    b.status = 'checked-out';
    final r = HOMData.rooms.where((rr) => rr.number == b.room).toList();
    if (r.isNotEmpty) r.first.status = 'available';
    setState(() {});
  }

  void _cancel(Booking b) {
    b.status = 'cancelled';
    final r = HOMData.rooms.where((rr) => rr.number == b.room).toList();
    if (r.isNotEmpty) r.first.status = 'available';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Bookings (${HOMData.bookings.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add, size: 16), label: const Text('New')),
      ]),
      const SizedBox(height: 8),
      ...HOMData.bookings.map((b) => Card(child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(b.guest, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            _statusChip(b.status),
          ]),
          const SizedBox(height: 4),
          Text('Room ${b.room} • ${b.checkin} → ${b.checkout} • ₦${b.amount}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(b.phone, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Row(children: [
            if (b.status != 'checked-out' && b.status != 'cancelled') ...[
              IconButton(onPressed: () => _edit(b), icon: const Icon(Icons.edit_rounded, size: 18), tooltip: 'Edit'),
              IconButton(onPressed: () => _checkout(b), icon: const Icon(Icons.logout_rounded, size: 18, color: primaryGreen), tooltip: 'Check out'),
              IconButton(onPressed: () => _cancel(b), icon: const Icon(Icons.cancel_rounded, size: 18, color: Colors.red), tooltip: 'Cancel'),
            ],
            IconButton(onPressed: () => setState(() => HOMData.bookings.remove(b)), icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent), tooltip: 'Delete'),
          ]),
        ]),
      ))),
    ]);
  }
}

// ===================== ROOMS =====================

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});
  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  void _add() {
    final num = TextEditingController(), price = TextEditingController();
    String type = 'Deluxe';
    _showForm(context, 'Add Room', [
      TextField(controller: num, decoration: const InputDecoration(labelText: 'Room number')),
      StatefulBuilder(builder: (ctx, setSB) => DropdownButtonFormField<String>(
        initialValue: type,
        items: ['Standard', 'Deluxe', 'Executive', 'Suite'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: (v) => setSB(() => type = v!),
        decoration: const InputDecoration(labelText: 'Type'),
      )),
      TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price per night')),
    ], () {
      if (num.text.isEmpty) return;
      HOMData.rooms.insert(0, Room(id: _uid(), number: num.text, type: type, status: 'available', price: int.tryParse(price.text) ?? 0));
      setState(() {});
    });
  }

  void _edit(Room r) {
    final price = TextEditingController(text: r.price.toString());
    String type = r.type;
    _showForm(context, 'Edit Room ${r.number}', [
      StatefulBuilder(builder: (ctx, setSB) => DropdownButtonFormField<String>(
        initialValue: type,
        items: ['Standard', 'Deluxe', 'Executive', 'Suite'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: (v) => setSB(() => type = v!),
      )),
      TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')),
    ], () { r.type = type; r.price = int.tryParse(price.text) ?? r.price; setState(() {}); });
  }

  void _toggleStatus(Room r) {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(16), child: Text('Set Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
      ...['available', 'occupied', 'maintenance'].map((s) => ListTile(
        title: Text(s.toUpperCase()),
        leading: Icon(s == 'available' ? Icons.check_circle_rounded : s == 'occupied' ? Icons.person_rounded : Icons.build_rounded, color: s == r.status ? primaryGreen : Colors.grey),
        onTap: () { r.status = s; Navigator.pop(ctx); setState(() {}); },
      )),
    ])));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Rooms (${HOMData.rooms.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add, size: 16), label: const Text('Add')),
      ]),
      const SizedBox(height: 8),
      ...HOMData.rooms.map((r) => Card(child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Room ${r.number}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            _statusChip(r.status),
          ]),
          Text('${r.type} — ₦${r.price}/night', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Row(children: [
            TextButton.icon(onPressed: () => _toggleStatus(r), icon: const Icon(Icons.swap_horiz_rounded, size: 14), label: const Text('Status')),
            IconButton(onPressed: () => _edit(r), icon: const Icon(Icons.edit_rounded, size: 18)),
            IconButton(onPressed: () => setState(() => HOMData.rooms.remove(r)), icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent)),
          ]),
        ]),
      ))),
    ]);
  }
}

// ===================== DIESEL =====================

class DieselScreen extends StatefulWidget {
  const DieselScreen({super.key});
  @override
  State<DieselScreen> createState() => _DieselScreenState();
}

class _DieselScreenState extends State<DieselScreen> {
  void _add() {
    final lit = TextEditingController(), cost = TextEditingController(), sup = TextEditingController(), hrs = TextEditingController(), note = TextEditingController();
    _showForm(context, 'Log Diesel', [
      TextField(controller: lit, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Liters')),
      TextField(controller: cost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost (₦)')),
      TextField(controller: sup, decoration: const InputDecoration(labelText: 'Supplier')),
      TextField(controller: hrs, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Generator hours')),
      TextField(controller: note, decoration: const InputDecoration(labelText: 'Note')),
    ], () {
      final l = int.tryParse(lit.text) ?? 0, h = int.tryParse(hrs.text) ?? 0;
      if (h > 0 && l / h < 8) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('THEFT ALERT: ${(l / h).toStringAsFixed(1)} L/hr!'),
          backgroundColor: Colors.red,
        ));
      }
      HOMData.diesel.insert(0, DieselLog(id: _uid(), date: _today(), liters: l, cost: int.tryParse(cost.text) ?? 0, supplier: sup.text, genHours: h, note: note.text));
      setState(() {});
    });
  }

  void _edit(DieselLog d) {
    final lit = TextEditingController(text: d.liters.toString());
    final cost = TextEditingController(text: d.cost.toString());
    final sup = TextEditingController(text: d.supplier);
    final hrs = TextEditingController(text: d.genHours.toString());
    final note = TextEditingController(text: d.note);
    _showForm(context, 'Edit Diesel Log', [
      TextField(controller: lit, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Liters')),
      TextField(controller: cost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost')),
      TextField(controller: sup, decoration: const InputDecoration(labelText: 'Supplier')),
      TextField(controller: hrs, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Gen hours')),
      TextField(controller: note, decoration: const InputDecoration(labelText: 'Note')),
    ], () {
      d.liters = int.tryParse(lit.text) ?? d.liters;
      d.cost = int.tryParse(cost.text) ?? d.cost;
      d.supplier = sup.text;
      d.genHours = int.tryParse(hrs.text) ?? d.genHours;
      d.note = note.text;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Diesel Logs (${HOMData.diesel.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add, size: 16), label: const Text('Log')),
      ]),
      const SizedBox(height: 8),
      ...HOMData.diesel.map((d) {
        final rate = d.genHours > 0 ? d.liters / d.genHours : 0.0;
        final theft = d.genHours > 0 && rate < 8;
        return Card(
          color: theft ? Colors.red.shade50 : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${d.liters}L — ${d.supplier}', style: const TextStyle(fontWeight: FontWeight.w800)),
                if (theft) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                  child: Text('${rate.toStringAsFixed(1)} L/hr', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ]),
              Text('${d.date} • ${d.genHours}hrs • ₦${d.cost} ${d.note.isNotEmpty ? '• ${d.note}' : ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 6),
              Row(children: [
                IconButton(onPressed: () => _edit(d), icon: const Icon(Icons.edit_rounded, size: 18)),
                IconButton(onPressed: () => setState(() => HOMData.diesel.remove(d)), icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent)),
              ]),
            ]),
          ),
        );
      }),
    ]);
  }
}

// ===================== INVENTORY =====================

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  void _add() {
    final name = TextEditingController(), qty = TextEditingController(), low = TextEditingController(), cost = TextEditingController();
    _showForm(context, 'Add Item', [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
      TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
      TextField(controller: low, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Low stock threshold')),
      TextField(controller: cost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit cost')),
    ], () {
      if (name.text.isEmpty) return;
      HOMData.inventory.insert(0, InventoryItem(id: _uid(), name: name.text, qty: int.tryParse(qty.text) ?? 0, low: int.tryParse(low.text) ?? 5, cost: int.tryParse(cost.text) ?? 0));
      setState(() {});
    });
  }

  void _edit(InventoryItem it) {
    final name = TextEditingController(text: it.name);
    final qty = TextEditingController(text: it.qty.toString());
    final low = TextEditingController(text: it.low.toString());
    final cost = TextEditingController(text: it.cost.toString());
    _showForm(context, 'Edit Item', [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
      TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
      TextField(controller: low, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Low threshold')),
      TextField(controller: cost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit cost')),
    ], () {
      it.name = name.text;
      it.qty = int.tryParse(qty.text) ?? it.qty;
      it.low = int.tryParse(low.text) ?? it.low;
      it.cost = int.tryParse(cost.text) ?? it.cost;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Inventory (${HOMData.inventory.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add, size: 16), label: const Text('Add')),
      ]),
      const SizedBox(height: 8),
      ...HOMData.inventory.map((it) => Card(child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(it.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            if (it.qty <= it.low) Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
              child: const Text('LOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.red)),
            ),
          ]),
          Text('Qty: ${it.qty} • Min: ${it.low} • ₦${it.cost}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Row(children: [
            IconButton(onPressed: () => setState(() => it.qty = (it.qty - 1).clamp(0, 99999)), icon: const Icon(Icons.remove_circle_outline, size: 28)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${it.qty}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            IconButton(onPressed: () => setState(() => it.qty += 10), icon: const Icon(Icons.add_circle, size: 28, color: primaryGreen)),
            const Spacer(),
            IconButton(onPressed: () => _edit(it), icon: const Icon(Icons.edit_rounded, size: 18)),
            IconButton(onPressed: () => setState(() => HOMData.inventory.remove(it)), icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent)),
          ]),
        ]),
      ))),
    ]);
  }
}

// ===================== STAFF / HR PAYROLL =====================

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  void _add() {
    final name = TextEditingController(), role = TextEditingController(), sal = TextEditingController();
    _showForm(context, 'Add Staff', [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
      TextField(controller: role, decoration: const InputDecoration(labelText: 'Role')),
      TextField(controller: sal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly salary (₦)')),
    ], () {
      if (name.text.isEmpty) return;
      HOMData.staff.insert(0, StaffMember(id: _uid(), name: name.text, role: role.text, salary: int.tryParse(sal.text) ?? 0));
      setState(() {});
    });
  }

  void _edit(StaffMember s) {
    final name = TextEditingController(text: s.name);
    final role = TextEditingController(text: s.role);
    final sal = TextEditingController(text: s.salary.toString());
    _showForm(context, 'Edit Staff', [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
      TextField(controller: role, decoration: const InputDecoration(labelText: 'Role')),
      TextField(controller: sal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Salary')),
    ], () {
      s.name = name.text;
      s.role = role.text;
      s.salary = int.tryParse(sal.text) ?? s.salary;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Staff & Payroll (${HOMData.staff.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add, size: 16), label: const Text('Add')),
      ]),
      const SizedBox(height: 8),
      ...HOMData.staff.map((s) {
        final p = HOMData.paye(s.salary), pe = HOMData.pension(s.salary), net = HOMData.netPay(s.salary);
        return Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Row(children: [
                IconButton(onPressed: () => _edit(s), icon: const Icon(Icons.edit_rounded, size: 18)),
                IconButton(onPressed: () => setState(() => HOMData.staff.remove(s)), icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent)),
              ]),
            ]),
            Text(s.role, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Gross: ₦${s.salary}', style: const TextStyle(fontSize: 12)),
                Text('PAYE 7%: ₦$p', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text('Pension 8%: ₦$pe', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text('Net: ₦$net', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: primaryGreen)),
              ]),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payslip: ${s.name} — Net ₦$net (PAYE 7% + Pension 8%)'))),
                icon: const Icon(Icons.send_rounded, size: 14),
                label: const Text('Send WhatsApp Payslip'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
              ),
            ),
          ]),
        ));
      }),
    ]);
  }
}

// ===================== VENDORS & PURCHASE ORDERS =====================

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key});
  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  void _addVendor() {
    final name = TextEditingController(), contact = TextEditingController(), cat = TextEditingController();
    _showForm(context, 'Add Vendor', [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
      TextField(controller: contact, decoration: const InputDecoration(labelText: 'Contact')),
      TextField(controller: cat, decoration: const InputDecoration(labelText: 'Category')),
    ], () {
      if (name.text.isEmpty) return;
      HOMData.vendors.insert(0, Vendor(id: _uid(), name: name.text, contact: contact.text, category: cat.text));
      setState(() {});
    });
  }

  void _addPO() {
    final items = TextEditingController(), amt = TextEditingController();
    String vendorId = HOMData.vendors.isNotEmpty ? HOMData.vendors.first.id : '';
    _showForm(context, 'New Purchase Order', [
      StatefulBuilder(builder: (ctx, setSB) => DropdownButtonFormField<String>(
        initialValue: vendorId,
        items: HOMData.vendors.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))).toList(),
        onChanged: (v) => setSB(() => vendorId = v!),
        decoration: const InputDecoration(labelText: 'Vendor'),
      )),
      TextField(controller: items, decoration: const InputDecoration(labelText: 'Items')),
      TextField(controller: amt, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₦)')),
    ], () {
      if (items.text.isEmpty) return;
      HOMData.purchaseOrders.insert(0, PurchaseOrder(
        id: _uid(), vendorId: vendorId, items: items.text,
        amount: int.tryParse(amt.text) ?? 0, date: _today(), status: 'pending',
      ));
      setState(() {});
    });
  }

  void _cycleStatus(PurchaseOrder po) {
    final statuses = ['pending', 'approved', 'delivered'];
    final i = statuses.indexOf(po.status);
    po.status = statuses[(i + 1) % statuses.length];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Vendors & POs', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        Row(children: [
          TextButton.icon(onPressed: _addVendor, icon: const Icon(Icons.add, size: 14), label: const Text('Vendor')),
          ElevatedButton.icon(onPressed: _addPO, icon: const Icon(Icons.add, size: 14), label: const Text('PO')),
        ]),
      ]),
      const SizedBox(height: 12),
      _sectionTitle('Vendors (${HOMData.vendors.length})'),
      ...HOMData.vendors.map((v) => Card(child: ListTile(
        title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${v.contact} • ${v.category}'),
        trailing: IconButton(onPressed: () => setState(() {
          HOMData.vendors.remove(v);
          HOMData.purchaseOrders.removeWhere((po) => po.vendorId == v.id);
        }), icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent)),
      ))),
      const SizedBox(height: 16),
      _sectionTitle('Purchase Orders (${HOMData.purchaseOrders.length})'),
      ...HOMData.purchaseOrders.map((po) {
        final vName = HOMData.vendors.where((v) => v.id == po.vendorId).map((v) => v.name).firstOrNull ?? 'Unknown';
        return Card(child: ListTile(
          title: Text(po.items, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('$vName • ₦${po.amount} • ${po.date}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(onTap: () => _cycleStatus(po), child: _statusChip(po.status)),
            IconButton(onPressed: () => setState(() => HOMData.purchaseOrders.remove(po)), icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent)),
          ]),
        ));
      }),
    ]);
  }
}
