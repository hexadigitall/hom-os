import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Encryption-at-rest for HOM's local Hive boxes.
///
/// A single AES-256 key is generated once and kept in the platform secure
/// store (Android Keystore-backed EncryptedSharedPreferences, iOS Keychain,
/// Windows DPAPI, WebCrypto on web). Every box is opened with [openEncryptedBox]
/// so business data is never written to disk as plaintext.
///
/// Legacy devices that already have plaintext boxes are migrated in place on
/// first boot: Hive stores per-frame CRCs seeded by the cipher key, so opening
/// a plaintext box with a cipher silently yields an empty box (no exception).
/// We therefore probe with an unencrypted read, and when real data is found,
/// re-write it into a freshly created encrypted box before deleting the old one.
class HiveSecurity {
  HiveSecurity._();

  static const _storage = FlutterSecureStorage();
  static const _keyId = 'hom_hive_enc_key_v1';

  static HiveAesCipher? _cipher;

  /// The shared AES-256 cipher, or `null` when secure storage is unavailable
  /// (availability over security: the box then stays plaintext and a warning
  /// is logged rather than risking a data lockout).
  static Future<HiveAesCipher?> keyCipher() async {
    if (_cipher != null) return _cipher;
    try {
      var b64 = await _storage.read(key: _keyId);
      if (b64 == null || b64.isEmpty) {
        final key = _randomBytes(32);
        b64 = base64Encode(key);
        await _storage.write(key: _keyId, value: b64);
      }
      final raw = base64Decode(b64);
      if (raw.length != 32) {
        throw StateError('Stored Hive key is not 256-bit.');
      }
      _cipher = HiveAesCipher(raw);
      return _cipher;
    } catch (e) {
      debugPrint('[HiveSecurity] secure storage unavailable — '
          'Hive boxes will stay plaintext. $e');
      return null;
    }
  }

  static List<int> _randomBytes(int n) {
    final rnd = Random.secure();
    return List<int>.generate(n, (_) => rnd.nextInt(256));
  }

  /// Opens [name] with AES-256, transparently migrating a legacy plaintext
  /// box. Falls back to plaintext when secure storage is unavailable.
  static Future<Box<String>> openEncryptedBox(String name) async {
    final cipher = await keyCipher();
    if (cipher == null) return Hive.openBox<String>(name);

    // Probe for legacy plaintext data with an unencrypted read. An encrypted
    // box read without a cipher has mismatching CRCs and reads as empty, which
    // is exactly what we rely on here to distinguish the two cases.
    final probe = await Hive.openBox<String>(name);
    final hadData = probe.isNotEmpty;
    final copy = Map<String, String>.from(probe.toMap());
    await probe.close();

    if (!hadData) {
      // Fresh box (or already encrypted) — just open with the cipher.
      return Hive.openBox<String>(name, encryptionCipher: cipher);
    }

    try {
      await Hive.deleteBoxFromDisk(name);
      final enc = await Hive.openBox<String>(name, encryptionCipher: cipher);
      await enc.putAll(copy);
      debugPrint('[HiveSecurity] migrated box "$name" to encrypted storage '
          '(${copy.length} entries).');
      return enc;
    } catch (e) {
      // Migration failed — keep availability, restore the plaintext copy.
      debugPrint('[HiveSecurity] migration of "$name" failed: $e');
      final plain = await Hive.openBox<String>(name);
      await plain.putAll(copy);
      return plain;
    }
  }
}
