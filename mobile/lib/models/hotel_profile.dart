/// Hotel-level identity and branding record, stored per hotel on-device and
/// shown on the branded splash/lock surfaces. The `hotels/{hotelId}` doc on
/// Firestore remains the server-authoritative master; this local copy is the
/// offline cache that keeps the branded surfaces consistent between syncs.
class HotelProfile {
  final String hotelId;
  String hotelName;
  String tagline;
  String currency;
  String address;
  String city;
  String state;
  String phone;
  String email;
  String website;
  String timezone;

  /// Whether the splash/lock screens render this hotel's tagline.
  bool showTaglineOnSplash;

  final DateTime createdAt;
  DateTime updatedAt;

  HotelProfile({
    required this.hotelId,
    this.hotelName = '',
    this.tagline = '',
    this.currency = 'NGN',
    this.address = '',
    this.city = '',
    this.state = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.timezone = 'Africa/Lagos',
    this.showTaglineOnSplash = true,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  Map<String, dynamic> toJson() => {
    'hotelId': hotelId,
    'hotelName': hotelName,
    'tagline': tagline,
    'currency': currency,
    'address': address,
    'city': city,
    'state': state,
    'phone': phone,
    'email': email,
    'website': website,
    'timezone': timezone,
    'showTaglineOnSplash': showTaglineOnSplash,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory HotelProfile.fromJson(Map<String, dynamic> j) => HotelProfile(
    hotelId: j['hotelId'].toString(),
    hotelName: j['hotelName']?.toString() ?? '',
    tagline: j['tagline']?.toString() ?? '',
    currency: j['currency']?.toString() ?? 'NGN',
    address: j['address']?.toString() ?? '',
    city: j['city']?.toString() ?? '',
    state: j['state']?.toString() ?? '',
    phone: j['phone']?.toString() ?? '',
    email: j['email']?.toString() ?? '',
    website: j['website']?.toString() ?? '',
    timezone: j['timezone']?.toString() ?? 'Africa/Lagos',
    showTaglineOnSplash: j['showTaglineOnSplash'] ?? true,
    createdAt: DateTime.parse(j['createdAt']),
    updatedAt: j['updatedAt'] != null ? DateTime.parse(j['updatedAt']) : null,
  );
}
