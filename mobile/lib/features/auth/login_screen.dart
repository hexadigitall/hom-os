import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../../data/auth_service.dart';
import '../../utils/theme.dart';
import 'google_connect_screen.dart';
import 'auth_shell.dart';
import 'google_button.dart';

bool get _googleSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

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

  void _routeResult(AuthResult result) {
    if (!mounted) return;
    if (result.isOk) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (result.status == AuthStatus.unprovisioned) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GoogleConnectScreen()),
      );
    } else {
      _showError(result.message ?? 'Sign-in failed');
    }
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      _showError('Please enter email and password');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await AuthService.login(_emailCtrl.text.trim(), _passCtrl.text);
      _routeResult(result);
    } catch (e) {
      _showError('Login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final result = await AuthService.signInWithGoogle();
      _routeResult(result);
    } catch (e) {
      _showError('Google sign-in error: $e');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('Enter your email address first');
      return;
    }
    final error = await AuthService.sendPasswordReset(email);
    if (!mounted) return;
    if (error == null) {
      _showSuccess('Password reset email sent (check your inbox).');
    } else {
      _showError(error);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.red));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.green));
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Welcome Back', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 4),
          const Text('Sign in to continue', style: TextStyle(fontSize: 14, color: AppColors.grey500)),
          const SizedBox(height: 24),
          if (_googleSupported) ...[
            GoogleButton(onPressed: _googleSignIn, loading: _googleLoading),
            const SizedBox(height: 20),
            const GoogleOrDivider(),
            const SizedBox(height: 20),
          ],
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded)), keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next),
          const SizedBox(height: 12),
          TextField(controller: _passCtrl, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_rounded), suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: () => setState(() => _obscure = !_obscure))), obscureText: _obscure, textInputAction: TextInputAction.done, onSubmitted: (_) => _login()),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgotPassword,
              child: const Text('Forgot password?', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white)) : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/staff-register'),
            icon: const Icon(Icons.app_registration_rounded, size: 18),
            label: const Text('I have an invite code'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            icon: const Icon(Icons.add_business_rounded, size: 18),
            label: const Text('Set up a new hotel'),
          ),
        ],
      ),
    );
  }
}
