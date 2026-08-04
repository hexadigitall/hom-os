import 'package:flutter/material.dart';
import '../../data/auth_service.dart';
import '../../data/cloud_functions_service.dart';
import '../../utils/theme.dart';

/// Shown when a Google account is signed in but has no role document yet.
/// Staff attach an invite code; owners provision their new hotel.
class GoogleConnectScreen extends StatefulWidget {
  const GoogleConnectScreen({super.key});

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
    setState(() => _connecting = true);
    try {
      await AuthService.redeemInvite(_codeCtrl.text.trim());
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on CloudFunctionsException catch (e) {
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
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on CloudFunctionsException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Could not create your hotel: $e');
    } finally {
      if (mounted) setState(() => _provisioning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Finish Signing In'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'You are signed in with Google, but your account is not linked to a hotel yet.',
            style: TextStyle(fontSize: 14, color: AppColors.grey600),
          ),
          const SizedBox(height: 24),

          // Join with an invite code
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Join your hotel',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Have an invite code from your manager? Enter it below.',
                      style: TextStyle(fontSize: 12, color: AppColors.grey500)),
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                          : const Icon(Icons.link_rounded, size: 18),
                      label: const Text('Connect Invite'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Text('or', style: TextStyle(color: AppColors.grey500)),
          ),
          const SizedBox(height: 16),

          // Provision a new hotel
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('I own the hotel',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Set up a new hotel with this Google account.',
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                          : const Icon(Icons.hotel_rounded, size: 18),
                      label: const Text('Create My Hotel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
