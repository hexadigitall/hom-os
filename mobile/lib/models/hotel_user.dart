import 'dart:convert';

class HotelUser {
  final String userId;
  String name;
  String email;
  String phone;
  String passwordHash;
  String roleId;
  String hotelId;
  String hotelName;
  final DateTime createdAt;

  HotelUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.roleId,
    required this.hotelId,
    required this.hotelName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'email': email,
    'phone': phone,
    'passwordHash': passwordHash,
    'roleId': roleId,
    'hotelId': hotelId,
    'hotelName': hotelName,
    'createdAt': createdAt.toIso8601String(),
  };

  factory HotelUser.fromJson(Map<String, dynamic> j) => HotelUser(
    userId: j['userId'],
    name: j['name'],
    email: j['email'],
    phone: j['phone'] ?? '',
    passwordHash: j['passwordHash'],
    roleId: j['roleId'],
    hotelId: j['hotelId'],
    hotelName: j['hotelName'],
    createdAt: DateTime.parse(j['createdAt']),
  );
}

String _hashPassword(String password) => base64Encode(utf8.encode(password));
bool verifyPassword(String password, String hash) => _hashPassword(password) == hash;
