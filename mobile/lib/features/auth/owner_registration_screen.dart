import 'package:flutter/material.dart';
import '../../data/auth_service.dart';
import '../../data/hom_api_service.dart';
import '../../utils/theme.dart';
import 'auth_shell.dart';
import 'google_button.dart';
import 'google_connect_screen.dart';

class OwnerRegistrationScreen extends StatefulWidget {
  const OwnerRegistrationScreen({super.key});
  @override
  State<OwnerRegistrationScreen> createState() => _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState extends State<OwnerRegistrationScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _hotelCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _hotelCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _hotelCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }
    if (!_emailCtrl.text.contains('@')) {
      _showError('Please enter a valid email address');
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
      await AuthService.registerOwner(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passCtrl.text,
        hotelName: _hotelCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } on HomApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Registration failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final result = await AuthService.signInWithGoogle();
      if (!mounted) return;
      if (result.isOk) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      } else if (result.status == AuthStatus.unprovisioned) {
        // Owner flow: straight to the hotel-provisioning form.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const GoogleConnectScreen(mode: ConnectMode.owner),
          ),
        );
      } else {
        _showError(result.message ?? 'Google sign-in failed');
      }
    } catch (e) {
      _showError('Google sign-in error: $e');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.red));
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Welcome to HOM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 4),
          const Text('Set up your hotel to get started', style: TextStyle(fontSize: 14, color: AppColors.grey500)),
          const SizedBox(height: 24),
          GoogleButton(onPressed: _googleSignIn, loading: _googleLoading),
          const SizedBox(height: 20),
          const GoogleOrDivider(),
          const SizedBox(height: 20),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Your full name', prefixIcon: Icon(Icons.person_rounded))),
          const SizedBox(height: 12),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_rounded)), keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone number (optional)', prefixIcon: Icon(Icons.phone_rounded)), keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          TextField(controller: _hotelCtrl, decoration: const InputDecoration(labelText: 'Hotel / Business name', prefixIcon: Icon(Icons.business_rounded))),
          const SizedBox(height: 12),
          TextField(controller: _passCtrl, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_rounded), suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: () => setState(() => _obscure = !_obscure))), obscureText: _obscure),
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
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text('Already have an account? Sign in', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
