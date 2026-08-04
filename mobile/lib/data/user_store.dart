import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/hotel_user.dart';
import '../models/invite_code.dart';
import '../models/role.dart';
import 'hom_api_service.dart';

/// Offline cache of the hotel's users and invites.
///
/// This is NOT a source of truth — the authoritative store is Firestore,
/// written only by Cloud Functions. Reads come from the `listUsers` /
/// `listInvites` callables and every mutation proxies to `updateUserRole` /
/// `deleteUserRole` / `createInvite` / `deleteInvite`. The Hive box just keeps
/// the data readable offline and drives the admin accounts UI.
class UserStore {
  static Box<String>? _box;

  /// Bumped after every successful refresh so the admin UI can rebuild.
  static final ValueNotifier<int> usersVersion = ValueNotifier<int>(0);
  static final ValueNotifier<int> invitesVersion = ValueNotifier<int>(0);

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

  // ──────────────────── server-backed refresh ────────────────────

  /// Pull the hotel's users from the `listUsers` callable into the cache.
  /// Best-effort: on failure the last cached snapshot stays readable.
  static Future<void> refreshUsers() async {
    try {
      final users = await HomApiService.listUsers();
      await _saveUsers(users);
      usersVersion.value++;
    } catch (_) {}
  }

  /// Pull the hotel's invites from the `listInvites` callable into the cache.
  static Future<void> refreshInvites() async {
    try {
      final invites = await HomApiService.listInvites();
      await _saveInvites(invites);
      invitesVersion.value++;
    } catch (_) {}
  }

  // ──────────────────── cache reads ────────────────────

  static bool get isOwnerRegistered {
    final users = _loadUsers();
    return users.any((u) => u.roleId == 'super_admin');
  }

  static String? get ownerHotelId {
    for (final u in _loadUsers()) {
      if (u.roleId == 'super_admin') return u.hotelId;
    }
    return null;
  }

  static String? get ownerHotelName {
    for (final u in _loadUsers()) {
      if (u.roleId == 'super_admin') return u.hotelName;
    }
    return null;
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

  static List<InviteCode> getInviteCodes() => _loadInvites();

  static List<HotelUser> getUsers() => _loadUsers();

  // ──────────────────── mutations (via callables) ────────────────────

  /// Create a single-use invite through the `createInvite` callable.
  static Future<String> createInvite({
    required String roleId,
    required String roleName,
    List<Department> departments = const [],
    bool isHead = false,
  }) async {
    final invite = await HomApiService.createInvite(
      roleId: roleId,
      roleName: roleName,
      departments: departments,
      isHead: isHead,
    );
    final invites = _loadInvites()
      ..removeWhere((i) => i.code == invite.code)
      ..insert(0, invite);
    await _saveInvites(invites);
    invitesVersion.value++;
    return invite.code;
  }

  static Future<void> deleteInvite(String code) async {
    try {
      await HomApiService.deleteInvite(code);
    } finally {
      final invites = _loadInvites()
        ..removeWhere((i) => i.code == code);
      await _saveInvites(invites);
      invitesVersion.value++;
    }
  }

  /// Push the edited assignment to `updateUserRole`, then refresh the cache.
  static Future<void> updateUser(HotelUser updated) async {
    final uid = updated.firebaseUid ?? updated.userId;
    try {
      await HomApiService.updateUserRole(
        targetUid: uid,
        roleIds: updated.roleIds,
        userName: updated.name,
        assignedDepartments: updated.assignedDepartments.map((d) => d.name).toList(),
        customPermissions: updated.customPermissions.map((p) => p.name).toList(),
        isHeadOfDepartment: {
          for (final e in updated.isHeadOfDepartment.entries) e.key.name: e.value,
        },
        status: updated.status.name,
      );
    } finally {
      await refreshUsers();
    }
  }

  /// Remove a staff account via the `deleteUserRole` callable, then refresh.
  static Future<void> deleteUser(String userId) async {
    try {
      await HomApiService.deleteUserRole(userId);
    } finally {
      final users = _loadUsers()
        ..removeWhere((u) => u.userId == userId);
      await _saveUsers(users);
      usersVersion.value++;
      await refreshUsers();
    }
  }
}
