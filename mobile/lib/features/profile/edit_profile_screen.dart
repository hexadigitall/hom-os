import 'package:flutter/material.dart';
import '../../data/profile_store.dart';
import '../../models/hotel_user.dart';
import '../../models/user_profile.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile? profile;
  final HotelUser? user;

  const EditProfileScreen({super.key, this.profile, this.user});

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
    _nameCtrl = TextEditingController(text: widget.profile?.displayName ?? widget.user?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.profile?.phone ?? widget.user?.phone ?? '');
    _photoCtrl = TextEditingController(text: widget.profile?.photoUrl ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _photoCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final profile = widget.profile;
    final user = widget.user;
    if (profile != null) {
      profile.displayName = _nameCtrl.text;
      profile.phone = _phoneCtrl.text;
      profile.photoUrl = _photoCtrl.text.trim().isEmpty ? null : _photoCtrl.text.trim();
      profile.updatedAt = DateTime.now();
      ProfileStore.save(profile);
    }
    if (user != null) {
      user.name = _nameCtrl.text;
      user.phone = _phoneCtrl.text;
    }
    Navigator.pop(context);
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
          if (widget.user != null) ...[
            const SizedBox(height: 16),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_rounded),
                hintText: widget.user!.email,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
