import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../../data/auth_service.dart';
import '../../utils/theme.dart';

const Color _primaryGreen = AppColors.primary;

bool get _googleSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      _showError('Please enter email and password');
      return;
    }
    setState(() => _loading = true);
    try {
      final ok = await AuthService.login(_emailCtrl.text.trim(), _passCtrl.text);
      if (ok) {
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showError('Invalid email or password');
      }
    } catch (e) {
      _showError('Login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final ok = await AuthService.signInWithGoogle();
      if (ok) {
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showError('Google sign-in failed. Ensure your account has been invited.');
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: _primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.hotel_rounded, color: _primaryGreen, size: 32),
              ),
              const SizedBox(height: 20),
              const Text('Welcome Back', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
              const SizedBox(height: 4),
              const Text('Sign in to continue', style: TextStyle(fontSize: 14, color: AppColors.grey500)),
              const SizedBox(height: 28),
              TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded)), keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next),
              const SizedBox(height: 12),
              TextField(controller: _passCtrl, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_rounded), suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: () => setState(() => _obscure = !_obscure))), obscureText: _obscure, textInputAction: TextInputAction.done, onSubmitted: (_) => _login()),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white)) : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
              if (_googleSupported)
                SizedBox(
                  width: double.infinity, height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _googleLoading ? null : _googleSignIn,
                    icon: _googleLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.g_mobiledata_rounded, size: 26),
                    label: Text('Sign in with Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.grey700)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.grey300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/staff-register'),
                icon: const Icon(Icons.app_registration_rounded, size: 18),
                label: const Text('I have an invite code'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
