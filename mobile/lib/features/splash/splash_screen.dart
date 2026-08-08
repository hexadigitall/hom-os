import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/hotel_settings_store.dart';
import '../../data/role_store.dart';
import '../../models/hotel_profile.dart';
import '../../utils/theme.dart';
import '../auth/auth_shell.dart' show authShellTagline, authShellWordmark;

/// Branded first screen shown on every app open before the auth gate.
///
/// Full HOM brand background (deep green gradient), the logo on a white tile,
/// the HOM wordmark, the official tagline, and — once a session exists — the
/// hotel's own name and tagline from its local branding profile. Held for a
/// short branded beat while the local session state is already being verified
/// underneath, then swapped for the [AuthGate] decision (login, or home behind
/// the device lock).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final profile = HotelSettingsStore.resolve(
      RoleStore.current.hotelId,
      RoleStore.current.hotelName,
    );
    return Material(
      color: const Color(0xFF064534),
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
                    colors: [Color(0xFF0E9F6E), Color(0xFF0B7A55), Color(0xFF064534)],
                  ),
                ),
              ),
            ),
            Center(
              // Center when the brand block fits; scroll when a long hotel
              // name wraps and pushes the tagline down past the screen.
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    vertical: 28, horizontal: 20),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeOutCubic,
                    )),
                    child: landscape
                        ? _buildLandscape(profile)
                        : _buildPortrait(profile),
                  ),
                ),
              ),
            ),
            // Subtle bottom progress hint so the branded moment never feels
            // like a hang.
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The hotel's own tagline when branding allows it, else the HOM tagline.
  String _tagline(HotelProfile profile) {
    if (profile.showTaglineOnSplash && profile.tagline.isNotEmpty) {
      return profile.tagline;
    }
    return authShellTagline;
  }

  Widget _buildPortrait(HotelProfile profile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Image.asset(
            'assets/logo/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          authShellWordmark,
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
            fontSize: 32,
            letterSpacing: 2,
          ),
        ),
        if (profile.hotelName.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              profile.hotelName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.3,
                height: 1.25,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          _tagline(profile),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.9),
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildLandscape(HotelProfile profile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            'assets/logo/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(width: 22),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              authShellWordmark,
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                fontSize: 30,
                letterSpacing: 2,
              ),
            ),
            if (profile.hotelName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                profile.hotelName,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.3,
                  height: 1.25,
                ),
              ),
            ],
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                _tagline(profile).replaceAll('\n', ' '),
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
