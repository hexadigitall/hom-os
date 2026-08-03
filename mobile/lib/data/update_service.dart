import 'dart:convert';

import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;
import 'package:http/http.dart' as http;

/// App version injected at build time via `--dart-define=HOM_APP_VERSION=...`.
/// Falls back to the pubspec version for local/dev builds.
const String kAppVersion = String.fromEnvironment('HOM_APP_VERSION',
    defaultValue: '2.0.1');

class UpdateInfo {
  final String latestTag;
  final String downloadUrl;
  const UpdateInfo({required this.latestTag, required this.downloadUrl});
}

/// Polls the release API once and exposes a new-version signal.
///
/// The web build is always the latest deploy, so updates only matter for
/// installed apps (Android APK/AAB, Windows MSIX, Linux DEB).
class UpdateService {
  UpdateService._();

  static final ValueNotifier<UpdateInfo?> status = ValueNotifier<UpdateInfo?>(null);

  static const String _apiUrl = 'https://hom.com.ng/api/latest-release';
  static const String _downloadUrl = 'https://hom.com.ng/download';

  /// Version scheme is 2.<github-run-number>.0, so the middle segment is a
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
      if (latestBuild > _currentBuild()) {
        status.value = UpdateInfo(
          latestTag: data['tag_name'] as String? ?? 'v$latestBuild',
          downloadUrl: _downloadUrl,
        );
      }
    } catch (_) {
      // Offline or unreachable must never block the app.
    }
  }
}
