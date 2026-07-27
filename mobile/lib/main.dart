import 'package:flutter/material.dart';
void main() => runApp(const HOMApp());
class HOMApp extends StatelessWidget {
  const HOMApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'hom.com.ng',
      theme: ThemeData(primarySwatch: Colors.green, primaryColor: Color(0xFF0E9F6E)),
      home: const Dashboard(),
    );
  }
}
class Dashboard extends StatelessWidget {
  const Dashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(children: [Image.asset('assets/logo/logo.png', height: 28), SizedBox(width: 8), Text('hom.com.ng Corinthian')])),
      body: ListView(padding: EdgeInsets.all(16), children: [
        Image.asset('assets/logo/logo.png', height: 120),
        SizedBox(height: 16),
        Text('The Hotel OS Powering Nigeria', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text('Built by Hexadigitall - Corinthian Edition'),
        SizedBox(height: 24),
        Card(child: ListTile(title: Text('Bookings'), subtitle: Text('127 this week'))),
        Card(child: ListTile(title: Text('Diesel'), subtitle: Text('840L tracked'))),
        Card(child: ListTile(title: Text('Paystack'), subtitle: Text('pk_test_7547...'))),
      ]),
    );
  }
}
