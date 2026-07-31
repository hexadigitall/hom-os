import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/hotel_user.dart';
import '../models/invite_code.dart';
import '../models/role.dart';

class UserStore {
  static Box<String>? _box;

  static Future<void> init() async {
    _box = await Hive.openBox<String>('hom_users');
  }

  static List<HotelUser> _loadUsers() {
    final raw = _box?.get('users');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => HotelUser.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) { return []; }
  }

  static Future<void> _saveUsers(List<HotelUser> users) async {
    await _box?.put('users', jsonEncode(users.map((e) => e.toJson()).toList()));
  }

  static List<InviteCode> _loadInvites() {
    final raw = _box?.get('invites');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => InviteCode.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) { return []; }
  }

  static Future<void> _saveInvites(List<InviteCode> invites) async {
    await _box?.put('invites', jsonEncode(invites.map((e) => e.toJson()).toList()));
  }

  static bool get isOwnerRegistered {
    final users = _loadUsers();
    return users.any((u) => u.roleId == 'super_admin');
  }

  static String? get ownerHotelId {
    final users = _loadUsers();
    final owner = users.cast<HotelUser?>().firstWhere(
      (u) => u!.roleId == 'super_admin',
      orElse: () => null,
    );
    return owner?.hotelId;
  }

  static String? get ownerHotelName {
    final users = _loadUsers();
    final owner = users.cast<HotelUser?>().firstWhere(
      (u) => u!.roleId == 'super_admin',
      orElse: () => null,
    );
    return owner?.hotelName;
  }

  static HotelUser? findByEmail(String email) {
    final users = _loadUsers();
    for (final u in users) {
      if (u.email.toLowerCase() == email.toLowerCase()) return u;
    }
    return null;
  }

  static HotelUser? findById(String userId) {
    final users = _loadUsers();
    for (final u in users) {
      if (u.userId == userId) return u;
    }
    return null;
  }

  static Future<HotelUser> registerOwner({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String hotelName,
  }) async {
    final users = _loadUsers();
    final userId = 'usr_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    final hash = base64Encode(utf8.encode(password));
    final user = HotelUser(
      userId: userId,
      name: name,
      email: email,
      phone: phone,
      passwordHash: hash,
      roleId: 'super_admin',
      roleIds: ['super_admin'],
      status: AccountStatus.active,
      hotelId: 'hotel_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
      hotelName: hotelName,
      createdAt: DateTime.now(),
    );
    users.add(user);
    await _saveUsers(users);
    return user;
  }

  static Future<HotelUser?> registerStaff({
    required String inviteCode,
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final invites = _loadInvites();
    InviteCode? invite;
    for (final i in invites) {
      if (i.code == inviteCode && i.isValid) {
        invite = i;
        break;
      }
    }
    if (invite == null) return null;

    final users = _loadUsers();
    final userId = 'usr_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    final hash = base64Encode(utf8.encode(password));
    final user = HotelUser(
      userId: userId,
      name: name,
      email: email,
      phone: phone,
      passwordHash: hash,
      roleId: invite.roleId,
      roleIds: [invite.roleId],
      assignedDepartments: invite.departments,
      isHeadOfDepartment: invite.isHead
          ? {for (final d in invite.departments) d: true}
          : const {},
      status: AccountStatus.active,
      hotelId: invite.hotelId,
      hotelName: invite.hotelName,
      createdAt: DateTime.now(),
    );
    users.add(user);
    await _saveUsers(users);

    invite.usedByUserId = userId;
    invite.usedAt = DateTime.now();
    await _saveInvites(invites);

    return user;
  }

  static bool verifyPassword(String password, String hash) {
    return base64Encode(utf8.encode(password)) == hash;
  }

  static String generateInviteCode(
    String roleId,
    String roleName,
    String hotelId,
    String hotelName, {
    List<Department> departments = const [],
    bool isHead = false,
  }) {
    final invites = _loadInvites();
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    final seq = (1000 + invites.length).toRadixString(36).toUpperCase();
    final code = '$ts$seq';
    final invite = InviteCode(
      code: code,
      roleId: roleId,
      roleName: roleName,
      departments: departments,
      isHead: isHead,
      hotelId: hotelId,
      hotelName: hotelName,
      createdAt: DateTime.now(),
    );
    invites.add(invite);
    _saveInvites(invites);
    return code;
  }

  static List<InviteCode> getInviteCodes() => _loadInvites();

  static List<HotelUser> getUsers() => _loadUsers();

  // ===================== USER UPDATE/DELETE =====================

  static Future<void> updateUser(HotelUser updated) async {
    final users = _loadUsers();
    final i = users.indexWhere((u) => u.userId == updated.userId);
    if (i >= 0) { users[i] = updated; await _saveUsers(users); }
  }

  static Future<void> deleteUser(String userId) async {
    final users = _loadUsers();
    users.removeWhere((u) => u.userId == userId);
    await _saveUsers(users);
  }

  // ===================== INVITE CODE UPDATE/DELETE =====================

  static Future<void> updateInvite(InviteCode updated) async {
    final invites = _loadInvites();
    final i = invites.indexWhere((inv) => inv.code == updated.code);
    if (i >= 0) { invites[i] = updated; await _saveInvites(invites); }
  }

  static Future<void> deleteInvite(String code) async {
    final invites = _loadInvites();
    invites.removeWhere((inv) => inv.code == code);
    await _saveInvites(invites);
  }
}
