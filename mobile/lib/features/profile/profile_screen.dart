import 'package:flutter/material.dart';
import '../../data/auth_service.dart';
import '../../data/profile_store.dart';
import '../../data/role_store.dart';
import '../../data/user_store.dart';
import 'edit_profile_screen.dart';
import '../../utils/theme.dart';

const Color _primaryGreen = AppColors.primary;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final session = RoleStore.current;
    final user = UserStore.findById(session.userId);
    final profile = ProfileStore.load(session.userId);

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
                  builder: (_) => EditProfileScreen(profile: profile, user: user),
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
              backgroundColor: _primaryGreen.withValues(alpha: 0.1),
              child: Text(
                (profile?.displayName ?? session.userName)[0].toUpperCase(),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: _primaryGreen),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              profile?.displayName ?? session.userName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          Center(
            child: Text(
              session.role.name,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                _detailRow(Icons.email_rounded, 'Email', user?.email ?? ''),
                const Divider(height: 20),
                _detailRow(Icons.phone_rounded, 'Phone', user?.phone ?? ''),
                const Divider(height: 20),
                _detailRow(Icons.business_rounded, 'Hotel', user?.hotelName ?? ''),
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
                _detailRow(Icons.badge_rounded, 'Role', session.role.name),
                const Divider(height: 20),
                _detailRow(Icons.fingerprint_rounded, 'Role ID', session.role.id),
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
                  value: profile?.preferences.notificationsEnabled ?? true,
                  onChanged: (v) {
                    if (profile != null) {
                      profile.preferences.notificationsEnabled = v;
                      ProfileStore.save(profile);
                      setState(() {});
                    }
                  },
                ),
                const Divider(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Compact Mode', style: TextStyle(fontSize: 14)),
                  value: profile?.preferences.compactMode ?? false,
                  onChanged: (v) {
                    if (profile != null) {
                      profile.preferences.compactMode = v;
                      ProfileStore.save(profile);
                      setState(() {});
                    }
                  },
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
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
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
      Icon(icon, size: 18, color: Colors.grey.shade600),
      const SizedBox(width: 10),
      Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
    ]);
  }
}
