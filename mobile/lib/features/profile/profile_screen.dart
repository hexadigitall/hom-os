import 'package:flutter/material.dart';
import '../../data/auth_service.dart';
import '../../data/hom_api_service.dart';
import '../../data/profile_store.dart';
import '../../data/role_store.dart';
import '../../models/role.dart';
import 'edit_profile_screen.dart';
import '../../utils/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _languages = [
    (code: 'en', label: 'English'),
    (code: 'fr', label: 'French'),
    (code: 'es', label: 'Spanish'),
    (code: 'ha', label: 'Hausa'),
    (code: 'yo', label: 'Yoruba'),
    (code: 'ig', label: 'Igbo'),
  ];

  @override
  Widget build(BuildContext context) {
    final session = RoleStore.current;
    final profile = ProfileStore.load(session.userId);
    // The session mirrors the live user_roles doc, so name/phone/avatar come
    // from the server first; the local Hive profile is only an offline cache.
    final displayName = session.userName.isNotEmpty
        ? session.userName
        : (profile?.displayName ?? '');
    final phone = session.phone.isNotEmpty ? session.phone : (profile?.phone ?? '');
    final photoUrl = (session.photoUrl?.isNotEmpty ?? false)
        ? session.photoUrl
        : profile?.photoUrl;
    final prefs = session.preferences;

    Future<void> syncPreferences() async {
      if (profile != null) {
        profile.preferences.notificationsEnabled = prefs.notificationsEnabled;
        profile.preferences.compactMode = prefs.compactMode;
        profile.preferences.language = prefs.language;
        profile.updatedAt = DateTime.now();
        await ProfileStore.save(profile);
      }
      try {
        await HomApiService.updateSelfProfile(preferences: {
          'notificationsEnabled': prefs.notificationsEnabled,
          'compactMode': prefs.compactMode,
          'language': prefs.language,
        });
      } catch (_) {
        // Offline — local cache is kept; the next sync will reconcile.
      }
      if (mounted) setState(() {});
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(profile: profile, session: session),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: session.roleAccent.withValues(alpha: 0.12),
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: session.roleAccent),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              displayName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: session.roleAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                session.primaryRole?.name ?? 'Unassigned',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: session.roleAccent),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                _detailRow(Icons.email_rounded, 'Email', session.email),
                const Divider(height: 20),
                _detailRow(Icons.phone_rounded, 'Phone', phone),
                const Divider(height: 20),
                _detailRow(Icons.business_rounded, 'Hotel', session.hotelName.isEmpty ? (session.hotelId ?? '') : session.hotelName),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Role & Permissions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                _detailRow(
                  Icons.badge_rounded,
                  'Roles',
                  session.resolvedRoles.map((r) => r.name).join(', '),
                ),
                const Divider(height: 20),
                _detailRow(
                  Icons.account_balance_rounded,
                  'Departments',
                  session.departmentScope.isEmpty
                      ? 'All (Management)'
                      : session.departmentScope.map((d) => d.name).join(', '),
                ),
                const Divider(height: 20),
                _detailRow(Icons.gpp_maybe_rounded, 'Status', session.status.label),
                if (session.customPermissions.isNotEmpty) ...[
                  const Divider(height: 20),
                  _detailRow(
                    Icons.add_circle_rounded,
                    'Extra Grants',
                    session.customPermissions.map((p) => p.name).join(', '),
                  ),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('App Settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notifications', style: TextStyle(fontSize: 14)),
                  value: prefs.notificationsEnabled,
                  onChanged: (v) {
                    prefs.notificationsEnabled = v;
                    syncPreferences();
                  },
                ),
                const Divider(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Compact Mode', style: TextStyle(fontSize: 14)),
                  value: prefs.compactMode,
                  onChanged: (v) {
                    prefs.compactMode = v;
                    syncPreferences();
                  },
                ),
                const Divider(height: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(children: [
                    const Icon(Icons.language_rounded, size: 18, color: AppColors.grey600),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: prefs.language,
                        items: _languages
                            .map((l) => DropdownMenuItem(value: l.code, child: Text(l.label, style: const TextStyle(fontSize: 14))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            prefs.language = v;
                            syncPreferences();
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Language',
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              icon: const Icon(Icons.logout_rounded, color: AppColors.red),
              label: const Text('Sign Out', style: TextStyle(color: AppColors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.grey600),
      const SizedBox(width: 10),
      Text('$label: ', style: TextStyle(fontSize: 13, color: AppColors.grey600)),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
    ]);
  }
}
