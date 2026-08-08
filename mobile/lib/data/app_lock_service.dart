import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Device-level lock for HOM.
///
/// This is a local screen-obscuring layer on top of the zero-trust session
/// gate: once a user signs in, the app stays authenticated by design, so a
/// lost or stolen device could otherwise be used to browse the hotel's
/// financial data. This service adds:
///   - a 4-digit PIN (salted SHA-256, key held in the secure store)
///   - biometric unlock (fingerprint / face) via `local_auth`
///   - device passkey / passcode as a second fallback
///   - an inactivity auto-lock (5 minutes) plus lock-on-resume and cold-start
///
/// None of this touches Firebase auth — it only hides the UI until the local
/// credential is presented, so staff workflows are never interrupted more than
/// necessary while the device is protected.
class AppLockService {
  AppLockService._();

  static const _storage = FlutterSecureStorage();
  static const _pinHashKey = 'hom_lock_pin_v1';
  static const _enabledKey = 'hom_lock_enabled_v1';
  static const _biometricKey = 'hom_lock_biometric_v1';
  static const _pinLength = 4;

  /// Auto-lock after this much time without any pointer interaction while the
  /// app is foregrounded, or after being backgrounded for this long.
  static const Duration inactivityTimeout = Duration(minutes: 5);

  static final ValueNotifier<bool> isLocked = ValueNotifier<bool>(false);

  static final LocalAuthentication _localAuth = LocalAuthentication();

  static bool _initialized = false;
  static bool _enabled = false;
  static bool _biometricWanted = false;
  static DateTime _lastInteraction = DateTime.now();
  static DateTime? _backgroundedAt;

  static bool get isEnabled => _enabled;
  static bool get biometricWanted => _biometricWanted;
  static int get pinLength => _pinLength;

  /// Boot-time init. Runs before `runApp` so the cold-start lock state is
  /// already decided when the first frame renders. Does not throw.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _enabled = await _storage.read(key: _enabledKey) == 'true';
      _biometricWanted = await _storage.read(key: _biometricKey) == 'true';
    } catch (e) {
      debugPrint('[AppLock] init failed: $e');
      _enabled = false;
    }
    // Every launch after the first requires the local credential again.
    if (_enabled) isLocked.value = true;
    Timer.periodic(const Duration(seconds: 30), (_) => _checkIdle());
  }

  /// A PIN is stored when this returns true.
  static Future<bool> hasPin() async {
    try {
      final raw = await _storage.read(key: _pinHashKey);
      return raw != null && raw.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Store a new PIN (salted, double SHA-256). 4+ digits recommended.
  static Future<void> setPin(String pin) async {
    final salt = _randomBytes(16);
    final hash = _hashPin(pin, salt);
    await _storage.write(
      key: _pinHashKey,
      value: '${base64Encode(salt)}:$hash',
    );
  }

  static Future<bool> verifyPin(String pin) async {
    try {
      final raw = await _storage.read(key: _pinHashKey);
      if (raw == null || !raw.contains(':')) return false;
      final parts = raw.split(':');
      if (parts.length != 2) return false;
      final salt = base64Decode(parts[0]);
      return _constantEq(_hashPin(pin, salt), parts[1]);
    } catch (_) {
      return false;
    }
  }

  static String _hashPin(String pin, List<int> salt) {
    final first = sha256.convert([...salt, ...utf8.encode(pin)]);
    return sha256.convert([...first.bytes, ...utf8.encode(pin)]).toString();
  }

  /// Constant-time string comparison to avoid timing side-channels.
  static bool _constantEq(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  static List<int> _randomBytes(int n) {
    final rnd = Random.secure();
    return List<int>.generate(n, (_) => rnd.nextInt(256));
  }

  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _storage.write(key: _enabledKey, value: '$value');
    if (value) isLocked.value = true;
  }

  static Future<void> setBiometricEnabled(bool value) async {
    _biometricWanted = value;
    await _storage.write(key: _biometricKey, value: '$value');
  }

  // ──────────────────── biometrics & device passcode ────────────────────

  static Future<bool> deviceSupportsBiometrics() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.isDeviceSupported() &&
          await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Prompt the OS biometric (fingerprint / face). Returns true on success.
  static Future<bool> authenticateBiometric() async {
    if (kIsWeb) return false;
    try {
      final supported = await _localAuth.canCheckBiometrics;
      if (!supported) return false;
      return await _localAuth.authenticate(
        localizedReason: 'Unlock HOM to continue.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: false,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('[AppLock] biometric failed: ${e.code} ${e.message}');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Prompt biometrics first, falling back to the device passcode/passkey.
  /// This is the "PIN, biometric or passkey" path from the lock screen.
  static Future<bool> authenticateBiometricOrPasscode() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Unlock HOM to continue.',
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: false,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('[AppLock] passcode auth failed: ${e.code} ${e.message}');
      return false;
    } catch (_) {
      return false;
    }
  }

  // ──────────────────── lock / unlock / inactivity ────────────────────

  static void touch() => _lastInteraction = DateTime.now();

  static void lock() {
    if (!_enabled) return;
    _lastInteraction = DateTime.now();
    isLocked.value = true;
  }

  static void unlock() {
    _lastInteraction = DateTime.now();
    isLocked.value = false;
  }

  static void _checkIdle() {
    if (!_enabled || isLocked.value) return;
    if (DateTime.now().difference(_lastInteraction) >= inactivityTimeout) {
      isLocked.value = true;
    }
  }

  /// Lifecycle hook: called when the app is backgrounded.
  static void onAppPaused() {
    _backgroundedAt = DateTime.now();
  }

  /// Lifecycle hook: called when the app returns to the foreground. Locks
  /// when it has been away long enough that the user "opened the app again".
  static void onAppResumed() {
    final away = _backgroundedAt;
    _backgroundedAt = null;
    if (!_enabled || isLocked.value) return;
    if (away != null &&
        DateTime.now().difference(away) >= inactivityTimeout) {
      isLocked.value = true;
    }
  }
}
