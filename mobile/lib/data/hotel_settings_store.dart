import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/hotel_profile.dart';
import '../utils/hive_security.dart';

/// Per-hotel identity & branding cache, encrypted at rest like every other
/// on-device box. Keyed by hotelId so switching hotels never leaks settings.
class HotelSettingsStore {
  static Box<String>? _box;

  static Future<void> init() async {
    _box = await HiveSecurity.openEncryptedBox('hom_hotel_settings');
  }

  static HotelProfile? load(String hotelId) {
    if (hotelId.isEmpty) return null;
    final raw = _box?.get(hotelId);
    if (raw == null) return null;
    try {
      return HotelProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(HotelProfile profile) async {
    await _box?.put(profile.hotelId, jsonEncode(profile.toJson()));
  }

  static Future<void> delete(String hotelId) async {
    await _box?.delete(hotelId);
  }

  /// Seed a profile from the server-known identity (session hotelId/name)
  /// when none exists yet, so the branded surfaces always have a baseline.
  static HotelProfile ensure(String hotelId, String hotelName) {
    final existing = load(hotelId);
    if (existing != null) return existing;
    final seeded = HotelProfile(
      hotelId: hotelId,
      hotelName: hotelName,
      createdAt: DateTime.now(),
    );
    save(seeded);
    return seeded;
  }

  /// Branding profile with a session fallback — never writes to the box.
  /// Use for read-only surfaces (splash, lock, headers) so a removed or
  /// never-created profile falls back to the server-mirrored identity.
  static HotelProfile resolve(String? hotelId, String sessionHotelName) {
    final loaded = load(hotelId ?? '');
    if (loaded != null) return loaded;
    return HotelProfile(
      hotelId: hotelId ?? '',
      hotelName: sessionHotelName,
      createdAt: DateTime.now(),
    );
  }

  /// Best available hotel display name for a surface: local branding first,
  /// then the server-mirrored session name.
  static String displayName(String? hotelId, String sessionHotelName) {
    final profile = load(hotelId ?? '');
    if (profile != null && profile.hotelName.isNotEmpty) {
      return profile.hotelName;
    }
    return sessionHotelName;
  }
}
