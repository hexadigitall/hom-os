import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
        appBarTheme:
            const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0.5),
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  static const _labels = ['Overview', 'Bookings', 'Rooms', 'Diesel', 'Inventory', 'Staff', 'Vendors'];
  static const _icons = [
    Icons.dashboard_rounded,
    Icons.calendar_month_rounded,
    Icons.bed_rounded,
    Icons.local_gas_station_rounded,
    Icons.inventory_2_rounded,
    Icons.people_rounded,
    Icons.store_rounded
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
          Container(margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: const Text('Local'))
        ]),
      ),
      body: Center(child: Text('Screen: ${_labels[_tab]}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: List.generate(7, (i) => NavigationDestination(icon: Icon(_icons[i], size: 22), label: Text(_labels[i], style: const TextStyle(fontSize: 10)))),
      ),
    );
  }
}
