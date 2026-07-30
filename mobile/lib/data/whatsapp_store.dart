import 'package:flutter/material.dart';
import 'persistence_service.dart';
import '../models/whatsapp.dart';

class WhatsAppStore extends ChangeNotifier {
  static final List<WhatsAppContact> _contacts = [];
  static final List<WhatsAppMessage> _messages = [];
  static int _msgCounter = 0;

  static const List<WhatsAppTemplate> templates = [
    WhatsAppTemplate(
      id: 't1', name: 'Booking Confirmation',
      entityType: ContactEntityType.booking,
      message: 'Dear [Guest], your booking at HOM Hotel is confirmed!\n'
          'Room: [Room] | Check-in: [Checkin] | Check-out: [Checkout]\n'
          'Amount: ₦[Amount]\n'
          'Thank you for choosing HOM!',
    ),
    WhatsAppTemplate(
      id: 't2', name: 'Guest Welcome',
      entityType: ContactEntityType.booking,
      message: 'Welcome to HOM Hotel, [Guest]!\n'
          'Room [Room] is ready. Enjoy your stay.\n'
          'Front Desk: [HotelPhone]',
    ),
    WhatsAppTemplate(
      id: 't3', name: 'Checkout Reminder',
      entityType: ContactEntityType.booking,
      message: 'Dear [Guest], this is a reminder that your checkout '
          'from Room [Room] is tomorrow ([Checkout]).\n'
          'Thank you for staying with HOM!',
    ),
    WhatsAppTemplate(
      id: 't4', name: 'Staff Payslip',
      entityType: ContactEntityType.staff,
      message: 'HOM PAYROLL — [StaffName]\n'
          'Gross: ₦[Gross]\nPAYE (7%): ₦[Paye]\n'
          'Pension (8%): ₦[Pension]\nNet Pay: ₦[Net]\n'
          'Thank you for your service.',
    ),
    WhatsAppTemplate(
      id: 't5', name: 'Purchase Order Notification',
      entityType: ContactEntityType.vendor,
      message: 'New Purchase Order from HOM Hotel\n'
          'Items: [Items]\nAmount: ₦[Amount]\n'
          'Date: [Date]\nPlease process accordingly.',
    ),
    WhatsAppTemplate(
      id: 't6', name: 'Subscription Renewal Reminder',
      entityType: ContactEntityType.subscription,
      message: 'Renewal Reminder: [SubName] ([Provider])\n'
          'Amount: ₦[Amount]/[Cycle]\n'
          'Due in [Days] day(s)\n'
          'Please process renewal.',
    ),
    WhatsAppTemplate(
      id: 't7', name: 'Fuel Theft Alert',
      entityType: ContactEntityType.other,
      message: '⚠️ FUEL THEFT ALERT — HOM Hotel\n'
          '[FuelType]: [Rate] [Unit] — below efficiency threshold!\n'
          'Supplier: [Supplier] | Date: [Date]',
    ),
    WhatsAppTemplate(
      id: 't8', name: 'General Reminder',
      message: 'Reminder from HOM Hotel:\n[Message]',
    ),
  ];

  static List<WhatsAppContact> get contacts => List.unmodifiable(_contacts);
  static List<WhatsAppMessage> get messages => List.unmodifiable(_messages);

  static int get sentTodayCount {
    final today = DateTime.now();
    return _messages.where((m) =>
        m.sentAt.year == today.year &&
        m.sentAt.month == today.month &&
        m.sentAt.day == today.day).length;
  }

  static Future<void> init() async {
    if (_contacts.isNotEmpty) return;
    final c = PersistenceService.loadList('wa_contacts', WhatsAppContact.fromJson);
    if (c != null && c.isNotEmpty) { _contacts.addAll(c); }
    final m = PersistenceService.loadList('wa_messages', WhatsAppMessage.fromJson);
    if (m != null && m.isNotEmpty) { _messages.addAll(m); }
  }

  static Future<void> _save() async {
    await PersistenceService.saveList('wa_contacts', _contacts, (e) => e.toJson());
    await PersistenceService.saveList('wa_messages', _messages, (e) => e.toJson());
  }

  static String genId() => 'wa_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
  static String genMsgId() {
    _msgCounter++;
    return 'msg_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}_$_msgCounter';
  }

  static Future<void> addContact(WhatsAppContact c) async {
    _contacts.insert(0, c);
    await _save();
  }

  static Future<void> updateContact(WhatsAppContact c) async {
    final i = _contacts.indexWhere((x) => x.id == c.id);
    if (i >= 0) { _contacts[i] = c; await _save(); }
  }

  static Future<void> removeContact(String id) async {
    _contacts.removeWhere((c) => c.id == id);
    await _save();
  }

  static WhatsAppContact? findContact(String entityType, String entityId) {
    final type = parseEntityType(entityType);
    try {
      return _contacts.firstWhere((c) => c.entityType == type && c.entityId == entityId);
    } catch (_) {
      return null;
    }
  }

  static ContactEntityType parseEntityType(String s) {
    switch (s) {
      case 'booking': return ContactEntityType.booking;
      case 'staff': return ContactEntityType.staff;
      case 'vendor': return ContactEntityType.vendor;
      case 'subscription': return ContactEntityType.subscription;
      default: return ContactEntityType.other;
    }
  }

  static Future<void> logMessage(WhatsAppMessage msg) async {
    _messages.insert(0, msg);
    await _save();
  }

  static Future<void> updateMessage(WhatsAppMessage msg) async {
    final i = _messages.indexWhere((m) => m.id == msg.id);
    if (i >= 0) { _messages[i] = msg; await _save(); }
  }

  static Future<void> removeMessage(String id) async {
    _messages.removeWhere((m) => m.id == id);
    await _save();
  }

  static String interpolate(String template, Map<String, String> vars) {
    var result = template;
    vars.forEach((k, v) {
      result = result.replaceAll('[$k]', v);
    });
    return result;
  }
}
