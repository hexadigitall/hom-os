// ──────────────────────────────────────────────────────────────
// FACILITY & AMENITY OPERATIONS ENGINE
// Gym · Pool · Gift Shop · Event Halls & Banqueting
// Offline-first, flat collections under hotels/{hotelId}/.
// Revenue rolls up into Night Audit / RevPAR via facility_revenue.
// ──────────────────────────────────────────────────────────────

import 'safe_enum.dart';

enum FacilityType { gym, pool, giftShop, eventHall }

extension FacilityTypeLabel on FacilityType {
  String get label => switch (this) {
        FacilityType.gym => 'Gymnasium',
        FacilityType.pool => 'Swimming Pool',
        FacilityType.giftShop => 'Gift Shop',
        FacilityType.eventHall => 'Event Hall / Banquet',
      };

  String get shortLabel => switch (this) {
        FacilityType.gym => 'Gym',
        FacilityType.pool => 'Pool',
        FacilityType.giftShop => 'Gift Shop',
        FacilityType.eventHall => 'Events',
      };

  /// Source label used by the Night Audit revenue roll-up.
  String get revenueSource => shortLabel;

  /// Department used to tag new records so they stay in the creator's scope.
  String get dept => switch (this) {
        FacilityType.gym => 'healthSafety',
        FacilityType.pool => 'healthSafety',
        FacilityType.giftShop => 'concierge',
        FacilityType.eventHall => 'banqueting',
      };

  String get icon => switch (this) {
        FacilityType.gym => 'fitness',
        FacilityType.pool => 'pool',
        FacilityType.giftShop => 'shop',
        FacilityType.eventHall => 'event',
      };
}

/// A bookable/sellable amenity (gym, pool, gift shop, event hall/banquet).
class Facility {
  String id;
  String name;
  FacilityType type;
  double rate; // pass price / hourly rate / base rate
  int capacity; // members / visitors / hall capacity
  bool isAvailable;
  String hours;
  String description;
  // Event-hall specifics
  String venue;
  double depositPercent;
  List<String> blockedDates; // yyyy-MM-dd — halls unavailable on these
  List<String> equipment; // AV / chairs / tables etc.

  Facility({
    String? id,
    required this.name,
    required this.type,
    this.rate = 0,
    this.capacity = 0,
    this.isAvailable = true,
    this.hours = '',
    this.description = '',
    this.venue = '',
    this.depositPercent = 0,
    List<String>? blockedDates,
    List<String>? equipment,
  })  : id = id ?? 'fac_${DateTime.now().microsecondsSinceEpoch}',
        blockedDates = blockedDates ?? [],
        equipment = equipment ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'rate': rate,
        'capacity': capacity,
        'isAvailable': isAvailable,
        'hours': hours,
        'description': description,
        'venue': venue,
        'depositPercent': depositPercent,
        'blockedDates': blockedDates,
        'equipment': equipment,
      };

  factory Facility.fromJson(Map<String, dynamic> j) => Facility(
        id: j['id'],
        name: j['name'] ?? '',
        type: safeEnum(j['type'], FacilityType.values, FacilityType.gym),
        rate: (j['rate'] as num?)?.toDouble() ?? 0,
        capacity: j['capacity'] ?? 0,
        isAvailable: j['isAvailable'] ?? true,
        hours: j['hours'] ?? '',
        description: j['description'] ?? '',
        venue: j['venue'] ?? '',
        depositPercent: (j['depositPercent'] as num?)?.toDouble() ?? 0,
        blockedDates: (j['blockedDates'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        equipment: (j['equipment'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

enum BookingKind { dayPass, membership, event }

extension BookingKindLabel on BookingKind {
  String get label => switch (this) {
        BookingKind.dayPass => 'Day Pass',
        BookingKind.membership => 'Membership',
        BookingKind.event => 'Event Booking',
      };
}

enum BookingStatus { requested, confirmed, depositPaid, paid, cancelled }

extension BookingStatusLabel on BookingStatus {
  String get label => switch (this) {
        BookingStatus.requested => 'Requested',
        BookingStatus.confirmed => 'Confirmed',
        BookingStatus.depositPaid => 'Deposit Paid',
        BookingStatus.paid => 'Paid',
        BookingStatus.cancelled => 'Cancelled',
      };

  /// Whether this booking has recorded revenue for the Night Audit roll-up.
  bool get recognized => this == BookingStatus.paid || this == BookingStatus.depositPaid;
}

/// Unified booking / pass / membership / event record.
/// `checkIns` doubles as the access log (gym member scan, pool pass scan).
class FacilityBooking {
  String id;
  String facilityId;
  String facilityName;
  BookingKind kind;
  BookingStatus status;
  String guestName;
  String phone;
  DateTime date; // visit date / membership start / event start
  DateTime endDate; // membership expiry / event end
  int qty;
  double amount;
  double paidAmount;
  double depositPercent;
  double depositDue;
  String eventType; // wedding / AGM / retreat / party / conference …
  int guestCount;
  String avNeeds; // 'Projector + 2 mics' etc.
  String buffet; // buffet/catering notes
  String organizer;
  String notes;
  String staffName;
  String paymentMethod;
  List<String> checkIns; // ISO timestamps — access log

  FacilityBooking({
    String? id,
    required this.facilityId,
    required this.facilityName,
    this.kind = BookingKind.dayPass,
    this.status = BookingStatus.requested,
    required this.guestName,
    this.phone = '',
    required this.date,
    DateTime? endDate,
    this.qty = 1,
    this.amount = 0,
    this.paidAmount = 0,
    this.depositPercent = 0,
    this.eventType = '',
    this.guestCount = 0,
    this.avNeeds = '',
    this.buffet = '',
    this.organizer = '',
    this.notes = '',
    this.staffName = '',
    this.paymentMethod = 'Cash',
    List<String>? checkIns,
  })  : id = id ?? 'bk_${DateTime.now().microsecondsSinceEpoch}',
        endDate = endDate ?? date,
        depositDue =
            amount * (depositPercent / 100),
        checkIns = checkIns ?? [];

  bool get isEvent => kind == BookingKind.event;
  bool get isActivePass =>
      (kind == BookingKind.dayPass || kind == BookingKind.membership) &&
      status != BookingStatus.cancelled;
  double get balance => amount - paidAmount;

  /// Deposit due for events (e.g. 70% of the agreed amount).
  double get depositRemaining => (depositDue - paidAmount).clamp(0, double.infinity);

  Map<String, dynamic> toJson() => {
        'id': id,
        'facilityId': facilityId,
        'facilityName': facilityName,
        'kind': kind.name,
        'status': status.name,
        'guestName': guestName,
        'phone': phone,
        'date': date.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'qty': qty,
        'amount': amount,
        'paidAmount': paidAmount,
        'depositPercent': depositPercent,
        'depositDue': depositDue,
        'eventType': eventType,
        'guestCount': guestCount,
        'avNeeds': avNeeds,
        'buffet': buffet,
        'organizer': organizer,
        'notes': notes,
        'staffName': staffName,
        'paymentMethod': paymentMethod,
        'checkIns': checkIns,
      };

  factory FacilityBooking.fromJson(Map<String, dynamic> j) => FacilityBooking(
        id: j['id'],
        facilityId: j['facilityId'] ?? '',
        facilityName: j['facilityName'] ?? '',
        kind: safeEnum(j['kind'], BookingKind.values, BookingKind.dayPass),
        status:
            safeEnum(j['status'], BookingStatus.values, BookingStatus.requested),
        guestName: j['guestName'] ?? '',
        phone: j['phone'] ?? '',
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
        endDate: DateTime.tryParse(j['endDate'] ?? '') ??
            DateTime.tryParse(j['date'] ?? '') ??
            DateTime.now(),
        qty: j['qty'] ?? 1,
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        paidAmount: (j['paidAmount'] as num?)?.toDouble() ?? 0,
        depositPercent: (j['depositPercent'] as num?)?.toDouble() ?? 0,
        eventType: j['eventType'] ?? '',
        guestCount: j['guestCount'] ?? 0,
        avNeeds: j['avNeeds'] ?? '',
        buffet: j['buffet'] ?? '',
        organizer: j['organizer'] ?? '',
        notes: j['notes'] ?? '',
        staffName: j['staffName'] ?? '',
        paymentMethod: j['paymentMethod'] ?? 'Cash',
        checkIns: (j['checkIns'] as List?)?.map((e) => e.toString()).toList() ??
            [],
      );
}

/// Gift-shop retail inventory item (barcode-friendly via `sku`).
class GiftItem {
  String id;
  String name;
  String sku;
  String category;
  double price;
  int stock;
  int low;
  bool available;

  GiftItem({
    String? id,
    required this.name,
    this.sku = '',
    this.category = 'General',
    this.price = 0,
    this.stock = 0,
    this.low = 0,
    this.available = true,
  }) : id = id ?? 'gi_${DateTime.now().microsecondsSinceEpoch}';

  bool get lowStock => available && stock <= low;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sku': sku,
        'category': category,
        'price': price,
        'stock': stock,
        'low': low,
        'available': available,
      };

  factory GiftItem.fromJson(Map<String, dynamic> j) => GiftItem(
        id: j['id'],
        name: j['name'] ?? '',
        sku: j['sku'] ?? '',
        category: j['category'] ?? 'General',
        price: (j['price'] as num?)?.toDouble() ?? 0,
        stock: j['stock'] ?? 0,
        low: j['low'] ?? 0,
        available: j['available'] ?? true,
      );
}

class SaleLine {
  String itemId;
  String name;
  int qty;
  double unitPrice;

  SaleLine({
    required this.itemId,
    required this.name,
    this.qty = 1,
    this.unitPrice = 0,
  });

  double get lineTotal => qty * unitPrice;

  Map<String, dynamic> toJson() =>
      {'itemId': itemId, 'name': name, 'qty': qty, 'unitPrice': unitPrice};

  factory SaleLine.fromJson(Map<String, dynamic> j) => SaleLine(
        itemId: j['itemId'] ?? '',
        name: j['name'] ?? '',
        qty: j['qty'] ?? 1,
        unitPrice: (j['unitPrice'] as num?)?.toDouble() ?? 0,
      );
}

/// Gift-shop retail POS transaction. Posting one decrements item stock and
/// records a facility_revenue row for the Night Audit roll-up.
class FacilitySale {
  String id;
  DateTime date;
  List<SaleLine> items;
  String cashier;
  String customerName;
  String paymentMethod;
  String note;

  FacilitySale({
    String? id,
    required this.date,
    List<SaleLine>? items,
    this.cashier = '',
    this.customerName = '',
    this.paymentMethod = 'Cash',
    this.note = '',
  })  : id = id ?? 'sale_${DateTime.now().microsecondsSinceEpoch}',
        items = items ?? [];

  double get total => items.fold(0.0, (s, l) => s + l.lineTotal);
  int get unitCount => items.fold(0, (s, l) => s + l.qty);

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'cashier': cashier,
        'customerName': customerName,
        'paymentMethod': paymentMethod,
        'note': note,
      };

  factory FacilitySale.fromJson(Map<String, dynamic> j) => FacilitySale(
        id: j['id'],
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
        items: (j['items'] as List?)
                ?.map((e) => SaleLine.fromJson((e as Map).cast<String, dynamic>()))
                .toList() ??
            [],
        cashier: j['cashier'] ?? '',
        customerName: j['customerName'] ?? '',
        paymentMethod: j['paymentMethod'] ?? 'Cash',
        note: j['note'] ?? '',
      );
}

/// Daily revenue-by-source record for Night Audit / RevPAR roll-up.
/// One row per (date, source, ref) so edits stay idempotent.
class FacilityRevenue {
  String id;
  DateTime date;
  String source; // Gym / Pool / Gift Shop / Events
  double amount;
  String refId; // facility_booking id or facility_sale id

  FacilityRevenue({
    String? id,
    required this.date,
    required this.source,
    required this.amount,
    required this.refId,
  }) : id = id ?? 'frev_${DateTime.now().microsecondsSinceEpoch}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'source': source,
        'amount': amount,
        'refId': refId,
      };

  factory FacilityRevenue.fromJson(Map<String, dynamic> j) => FacilityRevenue(
        id: j['id'],
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
        source: j['source'] ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        refId: j['refId'] ?? '',
      );
}
