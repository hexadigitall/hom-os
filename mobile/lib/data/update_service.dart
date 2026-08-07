import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// App version injected at build time via `--dart-define=HOM_APP_VERSION=...`.
/// Falls back to the pubspec version for local/dev builds.
const String kAppVersion = String.fromEnvironment('HOM_APP_VERSION',
    defaultValue: '2.0.1');

/// The APK asset name published on every GitHub release by the build pipeline.
const String _apkAssetName = 'HOM-APK.apk';
const String _checksumsAssetName = 'SHA256SUMS.txt';

enum UpdatePhase {
  idle,
  downloading,
  verifying,
  installing,
  done,
  error,
}

class UpdateInfo {
  final String latestTag;
  final String apkUrl;
  final String checksumsUrl;
  const UpdateInfo({
    required this.latestTag,
    required this.apkUrl,
    required this.checksumsUrl,
  });
}

class UpdateProgress {
  final UpdatePhase phase;
  final double? fraction;
  final String message;
  const UpdateProgress(this.phase, {this.fraction, this.message = ''});
}

/// Polls the release API and can fully auto-update the installed app:
/// download the new APK in the background, verify its SHA-256 against the
/// release checksums, then hand the package to the Android installer.
///
/// The APK is signed with the same keystore on every build, so the install is
/// an in-place upgrade — no uninstall, app data is preserved. The web build is
/// always the latest deploy, so updates only run on installed apps.
class UpdateService {
  UpdateService._();

  /// Set when a newer build exists on GitHub.
  static final ValueNotifier<UpdateInfo?> status = ValueNotifier<UpdateInfo?>(null);

  /// Download / verify / install progress for the active update.
  static final ValueNotifier<UpdateProgress> progress =
      ValueNotifier(const UpdateProgress(UpdatePhase.idle));

  static const MethodChannel _channel = MethodChannel('hom_updater');

  static const String _apiUrl = 'https://hom.com.ng/api/latest-release';

  /// Version scheme is `2.<github-run-number>.0`, so the middle segment is a
  /// strictly increasing build counter that maps 1:1 to release tags (v65…).
  static int _currentBuild() {
    final parts = kAppVersion.split('.');
    if (parts.length >= 2) return int.tryParse(parts[1]) ?? 0;
    return 0;
  }

  static Future<void> check() async {
    if (kIsWeb) return;
    try {
      final res = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final tag = (data['tag_name'] as String? ?? '').replaceAll('v', '').trim();
      final latestBuild = int.tryParse(tag) ?? 0;
      if (latestBuild <= _currentBuild()) {
        status.value = null;
        return;
      }
      final assets = (data['assets'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      String? apkUrl;
      String? sumsUrl;
      for (final a in assets) {
        final name = a['name'] as String? ?? '';
        final url = a['browser_download_url'] as String? ?? '';
        if (name == _apkAssetName) apkUrl = url;
        if (name == _checksumsAssetName) sumsUrl = url;
      }
      // No installable APK on this release — nothing to auto-update.
      if (apkUrl == null) return;
      status.value = UpdateInfo(
        latestTag: data['tag_name'] as String? ?? 'v$latestBuild',
        apkUrl: apkUrl,
        checksumsUrl: sumsUrl ?? '',
      );
    } catch (_) {
      // Offline or unreachable must never block the app.
    }
  }

  /// Download → verify → install, one tap end to end.
  static Future<void> downloadAndInstall(UpdateInfo info) async {
    progress.value = const UpdateProgress(
      UpdatePhase.downloading,
      message: 'Downloading update…',
    );
    try {
      final dir = await getApplicationCacheDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$_apkAssetName');
      if (file.existsSync()) await file.delete();

      progress.value = const UpdateProgress(
        UpdatePhase.downloading,
        fraction: 0,
        message: 'Downloading update…',
      );
      await _streamToFile(info.apkUrl, file, (f) {
        progress.value = UpdateProgress(
          UpdatePhase.downloading,
          fraction: f,
          message: 'Downloading update…',
        );
      });

      progress.value = const UpdateProgress(
        UpdatePhase.verifying,
        message: 'Verifying update…',
      );
      final digest =
          (await crypto.sha256.bind(file.openRead()).first).toString();
      if (info.checksumsUrl.isNotEmpty) {
        final expected = await _expectedChecksum(info.checksumsUrl);
        if (expected != null && !expected.equalsIgnoreCase(digest)) {
          progress.value = const UpdateProgress(
            UpdatePhase.error,
            message: 'Checksum mismatch — update aborted',
          );
          return;
        }
      }

      progress.value = const UpdateProgress(
        UpdatePhase.installing,
        message: 'Installing update…',
      );
      await _channel.invokeMethod('installApk', file.path);
      progress.value = const UpdateProgress(
        UpdatePhase.done,
        message: 'Update installed',
      );
    } on MissingPluginException {
      progress.value = const UpdateProgress(
        UpdatePhase.error,
        message: 'Installer unavailable on this device',
      );
    } on PlatformException catch (e) {
      progress.value = UpdateProgress(
        UpdatePhase.error,
        message: e.message ?? 'Could not launch the installer',
      );
    } catch (e) {
      progress.value = UpdateProgress(
        UpdatePhase.error,
        message: 'Update failed — $e',
      );
    }
  }

  /// Re-arm the banner after returning from the installer screen (e.g. the
  /// user cancelled the install, so the app is still on the old build).
  static void onResumed() {
    if (progress.value.phase == UpdatePhase.installing ||
        progress.value.phase == UpdatePhase.done) {
      progress.value = const UpdateProgress(UpdatePhase.idle);
      check();
    }
  }

  static Future<void> _streamToFile(
    String url,
    File out,
    void Function(double fraction) onProgress,
  ) async {
    final req = http.Request('GET', Uri.parse(url));
    final res = await http.Client().send(req);
    if (res.statusCode != 200) {
      throw HttpException('HTTP ${res.statusCode} downloading APK');
    }
    final total = res.contentLength ?? 0;
    var received = 0;
    final sink = out.openWrite();
    await for (final chunk in res.stream) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0) onProgress(received / total);
    }
    await sink.flush();
    await sink.close();
    if (total > 0 && received < total) {
      throw const HttpException('Download incomplete');
    }
  }

  /// Parse `SHA256SUMS.txt` for the line matching the APK asset.
  static Future<String?> _expectedChecksum(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      for (final line in LineSplitter.split(res.body)) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 2 && parts[1].contains(_apkAssetName)) {
          return parts[0];
        }
      }
    } catch (_) {
      // Missing checksum file must not block an install — best effort only.
    }
    return null;
  }
}

extension on String {
  bool equalsIgnoreCase(String other) =>
      toLowerCase() == other.toLowerCase();
}
