import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/user_profile.dart';
import '../utils/hive_security.dart';

class ProfileStore {
  static Box<String>? _box;

  static Future<void> init() async {
    _box = await HiveSecurity.openEncryptedBox('hom_profiles');
  }

  static UserProfile? load(String userId) {
    final raw = _box?.get(userId);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(UserProfile profile) async {
    await _box?.put(profile.userId, jsonEncode(profile.toJson()));
  }

  static Future<void> delete(String userId) async {
    await _box?.delete(userId);
  }

  static Future<void> updateLastLogin(String userId) async {
    final profile = load(userId);
    if (profile != null) {
      profile.lastLoginAt = DateTime.now();
      profile.updatedAt = DateTime.now();
      await save(profile);
    }
  }
}
