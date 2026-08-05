import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/hotel_user.dart';
import '../models/invite_code.dart';
import '../models/role.dart';

/// A structured error raised by HOM's server API (Vercel routes / Firebase
/// Functions). `statusCode` mirrors the HTTP status when available.
class HomApiException implements Exception {
  final String message;
  final int? statusCode;

  HomApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Override the server base URL at build time, e.g.
/// `flutter run --dart-define=HOM_API_URL=http://localhost:3000`
const String _apiBaseOverride = String.fromEnvironment('HOM_API_URL');

/// Thin, typed wrappers over HOM's server-authoritative API.
///
/// Clients NEVER write `user_roles`, `hotels` or `invites` directly — every
/// identity and privilege change goes through the server, which validates the
/// request against Firestore (Admin SDK) and fails closed. This is what makes
/// the locked firestore.rules safe.
class HomApiService {
  static String get apiBase {
    if (_apiBaseOverride.isNotEmpty) return _apiBaseOverride;
    // The Flutter web build is served from the same origin as the API.
    if (kIsWeb) return '';
    return 'https://app.hom.com.ng';
  }

  static Future<Map<String, dynamic>> _call(
    String method,
    String path, [
    Map<String, dynamic>? data,
  ]) async {
    final uri = Uri.parse('$apiBase$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    try {
      final request = http.Request(method, uri);
      request.headers.addAll(headers);
      if (data != null) request.body = jsonEncode(data);
      final response = await http.Response.fromStream(await request.send());
      final body = _decode(response.body);
      if (response.statusCode >= 400) {
        final message = _serverMessage(body) ?? 'Request failed.';
        throw HomApiException(message, statusCode: response.statusCode);
      }
      return body is Map<String, dynamic> ? body : <String, dynamic>{};
    } on HomApiException {
      rethrow;
    } catch (e) {
      throw HomApiException('Network error: $e');
    }
  }

  static dynamic _decode(String raw) {
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static String? _serverMessage(dynamic body) {
    if (body is Map) {
      final error = body['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
      if (body['message'] is String) return body['message'] as String;
    }
    return null;
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
    final res = await _call('POST', '/api/auth/signup-owner', {
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
    final res = await _call('POST', '/api/auth/provision-owner', {
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
    final res = await _call('POST', '/api/auth/signup-staff', {
      'inviteCode': inviteCode,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
    return res['hotelId']?.toString() ?? '';
  }

  /// Link an already-authenticated account (Google) to an invite code.
  /// [name] is the confirmed display name (Google's by default).
  static Future<String> redeemInvite(String inviteCode, {String? name}) async {
    final res = await _call(
      'POST',
      '/api/auth/redeem-invite',
      {
        'inviteCode': inviteCode,
        if (name != null && name.isNotEmpty) 'name': name,
      },
    );
    return res['hotelId']?.toString() ?? '';
  }

  // ──────────────────── invite management ────────────────────

  static Future<InviteCode> createInvite({
    required String roleId,
    required String roleName,
    List<Department> departments = const [],
    bool isHead = false,
  }) async {
    final res = await _call('POST', '/api/invites', {
      'roleId': roleId,
      'roleName': roleName,
      'departments': departments.map((d) => d.name).toList(),
      'isHead': isHead,
    });
    final invite = res['invite'];
    if (invite is Map) {
      return InviteCode.fromJson(Map<String, dynamic>.from(invite));
    }
    throw HomApiException('Invite could not be created.');
  }

  static Future<List<InviteCode>> listInvites() async {
    final res = await _call('GET', '/api/invites');
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
    await _call('DELETE', '/api/invites/${Uri.encodeComponent(code)}');
  }

  // ──────────────────── user (role) management ────────────────────

  static Future<List<HotelUser>> listUsers() async {
    final res = await _call('GET', '/api/users');
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
    await _call('PATCH', '/api/users/${Uri.encodeComponent(targetUid)}', {
      if (roleIds != null) 'roleIds': roleIds,
      if (userName != null) 'userName': userName,
      if (assignedDepartments != null) 'assignedDepartments': assignedDepartments,
      if (customPermissions != null) 'customPermissions': customPermissions,
      if (isHeadOfDepartment != null) 'isHeadOfDepartment': isHeadOfDepartment,
      if (status != null) 'status': status,
    });
  }

  static Future<void> deleteUserRole(String targetUid) async {
    await _call('DELETE', '/api/users/${Uri.encodeComponent(targetUid)}');
  }
}
