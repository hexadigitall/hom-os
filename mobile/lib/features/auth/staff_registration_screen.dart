import 'package:flutter/material.dart';
import '../../data/auth_service.dart';
import '../../data/cloud_functions_service.dart';
import 'package:hom_mobile/utils/theme.dart';

class StaffRegistrationScreen extends StatefulWidget {
  const StaffRegistrationScreen({super.key, this.initialCode});

  /// Invite code pre-filled from a WhatsApp invite link, e.g.
  /// `app.hom.com.ng/#/staff-register?code=XXXX`.
  final String? initialCode;

  @override
  State<StaffRegistrationScreen> createState() => _StaffRegistrationScreenState();
}

class _StaffRegistrationScreenState extends State<StaffRegistrationScreen> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final code = widget.initialCode?.trim() ?? '';
    if (code.isNotEmpty) {
      _codeCtrl.text = code.toUpperCase();
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }
    if (_passCtrl.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.registerStaff(
        inviteCode: _codeCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on CloudFunctionsException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Registration failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Join with Invite Code'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Enter the invite code from your hotel manager to create your account.',
                style: TextStyle(fontSize: 14, color: AppColors.grey500)),
            const SizedBox(height: 20),
            TextField(
              controller: _codeCtrl,
              decoration: InputDecoration(
                labelText: 'Invite code',
                prefixIcon: const Icon(Icons.vpn_key_rounded),
                suffixIcon: _codeCtrl.text.isNotEmpty
                    ? Icon(Icons.check_circle_rounded, color: AppColors.green)
                    : null,
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (v) => setState(() {
                _codeCtrl.value = _codeCtrl.value.copyWith(
                  text: v.toUpperCase(),
                  selection: TextSelection.collapsed(offset: v.length),
                );
              }),
            ),
            const SizedBox(height: 24),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_rounded))),
            const SizedBox(height: 12),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_rounded)), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone number (optional)', prefixIcon: Icon(Icons.phone_rounded)), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextField(controller: _passCtrl, decoration: InputDecoration(labelText: 'Create password', prefixIcon: const Icon(Icons.lock_rounded), suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: () => setState(() => _obscure = !_obscure))), obscureText: _obscure),
            const SizedBox(height: 12),
            TextField(controller: _confirmCtrl, decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_rounded)), obscureText: true),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white)) : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
