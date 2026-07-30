class UserPreferences {
  bool notificationsEnabled;
  bool compactMode;
  String language;

  UserPreferences({
    this.notificationsEnabled = true,
    this.compactMode = false,
    this.language = 'en',
  });

  Map<String, dynamic> toJson() => {
    'notificationsEnabled': notificationsEnabled,
    'compactMode': compactMode,
    'language': language,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> j) => UserPreferences(
    notificationsEnabled: j['notificationsEnabled'] ?? true,
    compactMode: j['compactMode'] ?? false,
    language: j['language'] ?? 'en',
  );
}

class UserProfile {
  final String userId;
  String displayName;
  String email;
  String phone;
  String? photoUrl;
  String roleId;
  String roleName;
  String hotelId;
  String hotelName;
  UserPreferences preferences;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? lastLoginAt;

  UserProfile({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.roleId,
    this.roleName = '',
    required this.hotelId,
    this.hotelName = '',
    UserPreferences? preferences,
    required this.createdAt,
    DateTime? updatedAt,
    this.lastLoginAt,
  }) : preferences = preferences ?? UserPreferences(),
       updatedAt = updatedAt ?? createdAt;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
    'roleId': roleId,
    'roleName': roleName,
    'hotelId': hotelId,
    'hotelName': hotelName,
    'preferences': preferences.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    userId: j['userId'],
    displayName: j['displayName'],
    email: j['email'],
    phone: j['phone'] ?? '',
    photoUrl: j['photoUrl'],
    roleId: j['roleId'],
    roleName: j['roleName'] ?? '',
    hotelId: j['hotelId'],
    hotelName: j['hotelName'] ?? '',
    preferences: j['preferences'] != null
        ? UserPreferences.fromJson(j['preferences'])
        : UserPreferences(),
    createdAt: DateTime.parse(j['createdAt']),
    updatedAt: j['updatedAt'] != null ? DateTime.parse(j['updatedAt']) : null,
    lastLoginAt: j['lastLoginAt'] != null ? DateTime.parse(j['lastLoginAt']) : null,
  );
}
