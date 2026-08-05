import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/auth_service.dart';
import '../../data/hom_api_service.dart';
import '../../data/profile_store.dart';
import '../../data/role_store.dart';
import '../../models/user_profile.dart';
import '../../utils/theme.dart';
import 'auth_shell.dart';

/// Which onboarding path to present after Google sign-in.
enum ConnectMode {
  /// Unknown intent — show both staff and owner options.
  auto,

  /// Staff joining with an invite code.
  staff,

  /// New hotel owner.
  owner,
}

/// Shown when a Google account is signed in but has no role document yet.
/// Staff attach an invite code; owners provision their new hotel. The form
/// collects the extra details Google can't provide (confirm name, phone).
class GoogleConnectScreen extends StatefulWidget {
  const GoogleConnectScreen({
    super.key,
    this.mode = ConnectMode.auto,
    this.initialCode,
  });

  /// The onboarding path the user arrived from (`auto` shows both cards).
  final ConnectMode mode;

  /// Invite code pre-filled when the staff arrived via an invite link.
  final String? initialCode;

  @override
  State<GoogleConnectScreen> createState() => _GoogleConnectScreenState();
}

class _GoogleConnectScreenState extends State<GoogleConnectScreen> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _hotelCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _connecting = false;
  bool _provisioning = false;

  @override
  void initState() {
    super.initState();
    final code = widget.initialCode?.trim() ?? '';
    if (code.isNotEmpty) _codeCtrl.text = code.toUpperCase();
    _nameCtrl.text = FirebaseAuth.instance.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _hotelCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.red));
  }

  Future<void> _connectInvite() async {
    if (_codeCtrl.text.trim().isEmpty) {
      _showError('Please enter your invite code');
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('Please enter your full name');
      return;
    }
    setState(() => _connecting = true);
    try {
      await AuthService.redeemInvite(
        _codeCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
      );
      await _saveLocalProfile();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } on HomApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Could not connect invite: $e');
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _provisionHotel() async {
    if (_nameCtrl.text.trim().isEmpty || _hotelCtrl.text.trim().isEmpty) {
      _showError('Please fill in your name and hotel name');
      return;
    }
    setState(() => _provisioning = true);
    try {
      await AuthService.provisionOwner(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        hotelName: _hotelCtrl.text.trim(),
      );
      await _saveLocalProfile();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } on HomApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Could not create your hotel: $e');
    } finally {
      if (mounted) setState(() => _provisioning = false);
    }
  }

  /// Persist the details captured here (phone + confirmed name) to the local
  /// profile, which is where phone/photo/display name live on the client.
  Future<void> _saveLocalProfile() async {
    final session = RoleStore.current;
    if (session.userId.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    final existing = ProfileStore.load(session.userId);
    await ProfileStore.save(UserProfile(
      userId: session.userId,
      displayName: _nameCtrl.text.trim().isNotEmpty
          ? _nameCtrl.text.trim()
          : (user?.displayName ?? session.userName),
      email: session.email.isNotEmpty ? session.email : (user?.email ?? ''),
      phone: _phoneCtrl.text.trim(),
      photoUrl: user?.photoURL,
      roleId: session.roleIds.isNotEmpty ? session.roleIds.first : '',
      roleIds: session.roleIds,
      assignedDepartments: session.assignedDepartments,
      customPermissions: session.customPermissions,
      isHeadOfDepartment: session.isHeadOfDepartment,
      status: session.status,
      hotelId: session.hotelId ?? '',
      hotelName: session.hotelName,
      createdAt: existing?.createdAt ?? DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final showStaff = widget.mode != ConnectMode.owner;
    final showOwner = widget.mode != ConnectMode.staff;

    return AuthShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Finish Signing In',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 4),
          const Text(
            'You are signed in with Google. Complete a few details to link your account to a hotel.',
            style: TextStyle(fontSize: 14, color: AppColors.grey500),
          ),
          const SizedBox(height: 24),

          if (showStaff) ...[
            _staffCard(),
            if (showOwner) ...[
              const SizedBox(height: 16),
              const Center(
                child: Text('or', style: TextStyle(color: AppColors.grey500)),
              ),
              const SizedBox(height: 16),
            ],
          ],
          if (showOwner) _ownerCard(),
        ],
      ),
    );
  }

  Widget _staffCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Join your hotel',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Enter the invite code from your manager.',
                style: TextStyle(fontSize: 12, color: AppColors.grey500)),
            const SizedBox(height: 12),
            TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_rounded))),
            const SizedBox(height: 12),
            TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone number (optional)',
                    prefixIcon: Icon(Icons.phone_rounded))),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              onChanged: (v) => setState(() {
                _codeCtrl.value = _codeCtrl.value.copyWith(
                  text: v.toUpperCase(),
                  selection: TextSelection.collapsed(offset: v.length),
                );
              }),
              decoration: const InputDecoration(
                  labelText: 'Invite code',
                  prefixIcon: Icon(Icons.vpn_key_rounded)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _connecting ? null : _connectInvite,
                icon: _connecting
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white))
                    : const Icon(Icons.link_rounded, size: 18),
                label: const Text('Connect Invite'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ownerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('I own the hotel',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Set up a new hotel with this Google account.',
                style: TextStyle(fontSize: 12, color: AppColors.grey500)),
            const SizedBox(height: 12),
            TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Your full name',
                    prefixIcon: Icon(Icons.person_rounded))),
            const SizedBox(height: 12),
            TextField(
                controller: _hotelCtrl,
                decoration: const InputDecoration(
                    labelText: 'Hotel / Business name',
                    prefixIcon: Icon(Icons.business_rounded))),
            const SizedBox(height: 12),
            TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone number (optional)',
                    prefixIcon: Icon(Icons.phone_rounded))),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _provisioning ? null : _provisionHotel,
                icon: _provisioning
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white))
                    : const Icon(Icons.hotel_rounded, size: 18),
                label: const Text('Create My Hotel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
