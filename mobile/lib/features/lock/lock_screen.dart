import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_lock_service.dart';
import '../../data/auth_service.dart';
import '../../data/hotel_settings_store.dart';
import '../../data/role_store.dart';
import '../../utils/theme.dart';
import '../auth/auth_shell.dart' show authShellTagline, authShellWordmark;

/// Full-screen overlay shown whenever [AppLockService.isLocked] is true and an
/// active session exists. Sits on top of the whole navigator via the
/// MaterialApp builder, so no route is reachable without the local credential.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocus = FocusNode();
  bool _obscured = true;
  bool _error = false;
  bool _busy = false;
  String? _hint;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tryBiometricSoon();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricSoon() async {
    if (!AppLockService.biometricWanted) return;
    if (!await AppLockService.deviceSupportsBiometrics()) return;
    // Small delay so the frame (and the OS prompt) shows cleanly.
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      final ok = await AppLockService.authenticateBiometric();
      if (ok && mounted) AppLockService.unlock();
    });
  }

  Future<void> _unlockWithBiometric() async {
    setState(() => _busy = true);
    final ok = await AppLockService.authenticateBiometric();
    final supported = await AppLockService.deviceSupportsBiometrics();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      AppLockService.unlock();
    } else if (!supported && !_error) {
      setState(() => _hint = 'Biometrics unavailable — enter your PIN instead.');
    }
  }

  Future<void> _submitPin(String value) async {
    if (value.length != AppLockService.pinLength || _busy) return;
    setState(() => _busy = true);
    final ok = await AppLockService.verifyPin(value);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _error = false;
        AppLockService.unlock();
      } else {
        _error = true;
        _hint = 'Incorrect PIN. Try again.';
        _pinController.clear();
      }
    });
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    await AuthService.logout();
    AppLockService.unlock();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    return Material(
      color: const Color(0xFF064534),
      child: SafeArea(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0B7A55), Color(0xFF064534)],
                    ),
                  ),
                ),
              ),
              if (landscape)
                _buildLandscape(width)
              else
                _buildPortrait(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortrait() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _LockBrand(),
              const SizedBox(height: 28),
              const Text(
                'Enter your PIN',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _hint ?? 'Unlock HOM to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _error ? const Color(0xFFFFB4AB) : AppColors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              _PinDots(
                length: AppLockService.pinLength,
                filled: _pinController.text.length,
                error: _error,
              ),
              const SizedBox(height: 12),
              _obscured
                  ? const SizedBox.shrink()
                  : _buildPinField(),
              const SizedBox(height: 16),
              _Keypad(
                onDigit: (d) {
                  if (_pinController.text.length >= AppLockService.pinLength) {
                    return;
                  }
                  _error = false;
                  _hint = null;
                  setState(() => _pinController.text += d);
                  _submitPin(_pinController.text);
                },
                onBackspace: () {
                  if (_pinController.text.isEmpty) return;
                  setState(() => _pinController.text =
                      _pinController.text.substring(0, _pinController.text.length - 1));
                },
                onShowEntry: () =>
                    setState(() => _obscured = !_obscured),
              ),
              const SizedBox(height: 12),
              _buildBiometricRow(),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _busy ? null : _signOut,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign out'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandscape(double width) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width > 900 ? 820 : 700),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Expanded(child: _LockBrand()),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Enter your PIN',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hint ?? 'Unlock HOM to continue',
                      style: TextStyle(
                        color:
                            _error ? const Color(0xFFFFB4AB) : AppColors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PinDots(
                      length: AppLockService.pinLength,
                      filled: _pinController.text.length,
                      error: _error,
                    ),
                    const SizedBox(height: 12),
                    _Keypad(
                      onDigit: (d) {
                        if (_pinController.text.length >=
                            AppLockService.pinLength) {
                          return;
                        }
                        _error = false;
                        _hint = null;
                        setState(() => _pinController.text += d);
                        _submitPin(_pinController.text);
                      },
                      onBackspace: () {
                        if (_pinController.text.isEmpty) return;
                        setState(() => _pinController.text = _pinController.text
                            .substring(0, _pinController.text.length - 1));
                      },
                      onShowEntry: () =>
                          setState(() => _obscured = !_obscured),
                    ),
                    const SizedBox(height: 12),
                    _buildBiometricRow(),
                    TextButton.icon(
                      onPressed: _busy ? null : _signOut,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign out'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinField() {
    return TextField(
      controller: _pinController,
      focusNode: _pinFocus,
      autofocus: true,
      obscureText: true,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(AppLockService.pinLength),
      ],
      maxLength: AppLockService.pinLength,
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: AppColors.white.withValues(alpha: 0.06),
        hintText: 'PIN',
        hintStyle: const TextStyle(color: AppColors.white38),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.2)),
        ),
      ),
      style: const TextStyle(color: AppColors.white, letterSpacing: 8),
      onChanged: (v) {
        setState(() {});
        if (v.length == AppLockService.pinLength) _submitPin(v);
      },
    );
  }

  Widget _buildBiometricRow() {
    return FutureBuilder<bool>(
      future: AppLockService.deviceSupportsBiometrics(),
      builder: (context, snap) {
        final supported = snap.data ?? false;
        if (!supported || !AppLockService.biometricWanted) {
          return const SizedBox.shrink();
        }
        return TextButton.icon(
          onPressed: _busy ? null : _unlockWithBiometric,
          icon: const Icon(Icons.fingerprint_rounded, size: 20),
          label: const Text('Use fingerprint or face'),
          style: TextButton.styleFrom(foregroundColor: AppColors.white),
        );
      },
    );
  }
}

class _LockBrand extends StatelessWidget {
  const _LockBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'assets/logo/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          authShellWordmark,
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: 1,
          ),
        ),
        if (_hotelName().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            _hotelName(),
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.3,
              height: 1.25,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          _tagline(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.white70, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  String _hotelName() {
    final session = RoleStore.current;
    return HotelSettingsStore.displayName(session.hotelId, session.hotelName);
  }

  String _tagline() {
    final session = RoleStore.current;
    final profile =
        HotelSettingsStore.resolve(session.hotelId, session.hotelName);
    if (profile.showTaglineOnSplash && profile.tagline.isNotEmpty) {
      return profile.tagline;
    }
    return authShellTagline;
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({
    required this.length,
    required this.filled,
    required this.error,
  });

  final int length;
  final int filled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < length; i++)
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: error
                  ? const Color(0xFFFFB4AB)
                  : (i < filled
                      ? AppColors.white
                      : AppColors.white.withValues(alpha: 0.25)),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onShowEntry,
  });

  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onShowEntry;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '<'],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final key in row)
                _Key(value: key, onTap: () {
                  if (key == '<') {
                    onBackspace();
                  } else if (key.isNotEmpty) {
                    onDigit(key);
                  }
                }),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Key(value: '', onTap: onShowEntry, hint: 'show'),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.value, required this.onTap, this.hint});

  final String value;
  final VoidCallback onTap;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 66,
          height: 54,
          child: Center(
            child: value == ''
                ? Text(
                    hint ?? '',
                    style: const TextStyle(color: AppColors.white38, fontSize: 12),
                  )
                : value == '<'
                    ? const Icon(Icons.backspace_outlined,
                        color: AppColors.white, size: 22)
                    : Text(
                        value,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
