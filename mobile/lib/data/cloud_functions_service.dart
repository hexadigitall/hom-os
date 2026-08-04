import 'package:cloud_functions/cloud_functions.dart';
import '../models/invite_code.dart';
import '../models/hotel_user.dart';
import '../models/role.dart';

/// A structured error raised by HOM's Cloud Functions callables.
class CloudFunctionsException implements Exception {
  final String message;
  final String? code;

  CloudFunctionsException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Thin, typed wrappers over HOM's server-authoritative Cloud Functions.
///
/// Clients NEVER write `user_roles`, `hotels` or `invites` directly — every
/// identity and privilege change goes through these callables, which validate
/// the request against Firestore (Admin SDK) and fail closed. This is what
/// makes the locked firestore.rules safe.
class CloudFunctionsService {
  static final _functions = FirebaseFunctions.instance;

  static Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic>? data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call(data ?? {});
      final value = result.data;
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      throw CloudFunctionsException(e.message ?? 'Request failed', code: e.code);
    } catch (e) {
      throw CloudFunctionsException('Network error: $e');
    }
  }

  // ──────────────────── onboarding ────────────────────

  /// Owner bootstrap (email/password). Creates the Auth user, hotel and
  /// super_admin role doc server-side.
  static Future<String> signupOwner({
    required String name,
    required String email,
    String phone = '',
    required String password,
    required String hotelName,
  }) async {
    final res = await _call('signupOwner', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'hotelName': hotelName,
    });
    return res['hotelId']?.toString() ?? '';
  }

  /// Owner bootstrap for an already-authenticated account (Google sign-up).
  static Future<String> provisionOwner({
    required String name,
    String phone = '',
    required String hotelName,
  }) async {
    final res = await _call('provisionOwner', {
      'name': name,
      'phone': phone,
      'hotelName': hotelName,
    });
    return res['hotelId']?.toString() ?? '';
  }

  /// Staff sign-up (email/password) from an invite code.
  static Future<String> signupStaff({
    required String inviteCode,
    required String name,
    required String email,
    String phone = '',
    required String password,
  }) async {
    final res = await _call('signupStaff', {
      'inviteCode': inviteCode,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
    return res['hotelId']?.toString() ?? '';
  }

  /// Link an already-authenticated account (Google) to an invite code.
  static Future<String> redeemInvite(String inviteCode) async {
    final res = await _call('redeemInvite', {'inviteCode': inviteCode});
    return res['hotelId']?.toString() ?? '';
  }

  // ──────────────────── invite management ────────────────────

  static Future<InviteCode> createInvite({
    required String roleId,
    required String roleName,
    List<Department> departments = const [],
    bool isHead = false,
  }) async {
    final res = await _call('createInvite', {
      'roleId': roleId,
      'roleName': roleName,
      'departments': departments.map((d) => d.name).toList(),
      'isHead': isHead,
    });
    final invite = res['invite'];
    if (invite is Map) {
      return InviteCode.fromJson(Map<String, dynamic>.from(invite));
    }
    throw CloudFunctionsException('Invite could not be created.');
  }

  static Future<List<InviteCode>> listInvites() async {
    final res = await _call('listInvites', {});
    final list = res['invites'];
    if (list is List) {
      return list
          .whereType<Map>()
          .map((e) => InviteCode.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  static Future<void> deleteInvite(String code) async {
    await _call('deleteInvite', {'code': code});
  }

  // ──────────────────── user (role) management ────────────────────

  static Future<List<HotelUser>> listUsers() async {
    final res = await _call('listUsers', {});
    final list = res['users'];
    if (list is List) {
      return list
          .whereType<Map>()
          .map((e) => HotelUser.fromRoleDoc(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  static Future<void> updateUserRole({
    required String targetUid,
    List<String>? roleIds,
    String? userName,
    List<String>? assignedDepartments,
    List<String>? customPermissions,
    Map<String, bool>? isHeadOfDepartment,
    String? status,
  }) async {
    await _call('updateUserRole', {
      'targetUid': targetUid,
      if (roleIds != null) 'roleIds': roleIds,
      if (userName != null) 'userName': userName,
      if (assignedDepartments != null) 'assignedDepartments': assignedDepartments,
      if (customPermissions != null) 'customPermissions': customPermissions,
      if (isHeadOfDepartment != null) 'isHeadOfDepartment': isHeadOfDepartment,
      if (status != null) 'status': status,
    });
  }

  static Future<void> deleteUserRole(String targetUid) async {
    await _call('deleteUserRole', {'targetUid': targetUid});
  }
}
