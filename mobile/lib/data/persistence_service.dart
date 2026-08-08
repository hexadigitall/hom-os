import 'dart:convert';
import 'package:hive/hive.dart';
import '../utils/hive_security.dart';

class PersistenceService {
  static Box<String>? _store;

  static Future<void> init() async {
    _store = await HiveSecurity.openEncryptedBox('hom_data');
  }

  static Future<void> save<T>(String key, T value) async {
    await _store?.put(key, jsonEncode(value));
  }

  static T? load<T>(String key, T Function(dynamic) fromJson) {
    final raw = _store?.get(key);
    if (raw == null) return null;
    try {
      return fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<void> remove(String key) async {
    await _store?.delete(key);
  }

  static Future<void> saveList<T>(
    String key, List<T> items, Map<String, dynamic> Function(T) toJson,
  ) async {
    await _store?.put(key, jsonEncode(items.map((e) => toJson(e)).toList()));
  }

  static List<T>? loadList<T>(
    String key, T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _store?.get(key);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }
}
