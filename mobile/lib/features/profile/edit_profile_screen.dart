import 'package:flutter/material.dart';
import '../../data/profile_store.dart';
import '../../data/cloud_functions_service.dart';
import '../../data/role_store.dart';
import '../../models/user_profile.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile? profile;
  final Session? session;

  const EditProfileScreen({super.key, this.profile, this.session});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _photoCtrl;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameCtrl = TextEditingController(
        text: profile?.displayName ?? widget.session?.userName ?? '');
    _phoneCtrl = TextEditingController(text: profile?.phone ?? '');
    _photoCtrl = TextEditingController(text: profile?.photoUrl ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _photoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final session = widget.session;
    final profile = widget.profile ??
        UserProfile(
          userId: session?.userId ?? '',
          displayName: session?.userName ?? '',
          email: session?.email ?? '',
          phone: '',
          roleId: session?.roleIds.isNotEmpty == true ? session!.roleIds.first : '',
          roleIds: session?.roleIds ?? const [],
          hotelId: session?.hotelId ?? '',
          hotelName: session?.hotelName ?? '',
          createdAt: DateTime.now(),
        );
    profile.displayName = _nameCtrl.text;
    profile.phone = _phoneCtrl.text;
    profile.photoUrl = _photoCtrl.text.trim().isEmpty ? null : _photoCtrl.text.trim();
    profile.updatedAt = DateTime.now();
    await ProfileStore.save(profile);

    // Best-effort server name sync (only works for management-level accounts;
    // the callable requires admin. Staff keep their name locally.)
    if (session != null && _nameCtrl.text.trim().isNotEmpty &&
        _nameCtrl.text.trim() != session.userName) {
      CloudFunctionsService.updateUserRole(
        targetUid: session.userId,
        userName: _nameCtrl.text.trim(),
      ).catchError((_) {});
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_rounded)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_rounded)),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _photoCtrl,
            decoration: const InputDecoration(
              labelText: 'Profile Photo URL (optional)',
              prefixIcon: Icon(Icons.image_rounded),
              hintText: 'https://...',
            ),
          ),
          if (widget.session != null) ...[
            const SizedBox(height: 16),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_rounded),
                hintText: widget.session!.email,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
