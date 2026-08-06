import 'package:flutter/material.dart';
import '../../utils/theme.dart';

/// Responsive auth scaffold used by every sign-in / sign-up screen.
///
/// Narrow screens get a single centered column (max 440). Wide screens get a
/// two-pane layout: a brand panel on the left and the form card on the right,
/// so desktop / landscape web views never stretch forms edge to edge.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.child,
    this.showAppBar = false,
    this.appBarTitle,
  });

  final Widget child;
  final bool showAppBar;
  final String? appBarTitle;

  static const double _formMaxWidth = 440;
  static const double _wideBreakpoint = 760;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: showAppBar
          ? AppBar(
              title: Text(appBarTitle ?? 'HOM'),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
            )
          : null,
      body: SafeArea(child: wide ? _buildWide(context) : _buildNarrow(context)),
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _formMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _BrandHeader(),
              const SizedBox(height: 28),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(flex: 5, child: _BrandPanel()),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _formMaxWidth),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact brand header shown above the form on narrow layouts.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset('assets/logo/logo.png',
                fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'HOM',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1),
        ),
      ],
    );
  }
}

/// Deep-green marketing panel shown on the left of wide layouts.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  static const _features = [
    (Icons.apartment_rounded, 'All departments, one workspace'),
    (Icons.cloud_off_rounded, 'Offline-first — keeps working without internet'),
    (Icons.shield_rounded, 'Server-authoritative roles & access'),
    (Icons.mobile_friendly_rounded, 'Web, Android, iOS, Windows & macOS'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B7A55), Color(0xFF064534), Color(0xFF0E1A14)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset('assets/logo/logo.png',
                      fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'HOM',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'HOSPITALITY',
                style: TextStyle(
                  color: AppColors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            'The Hotel Operating System\nPowering Nigeria.',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 30,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Run your hotel from any device — front desk, housekeeping, F&B,\nengineering, reports and more, all in one place.',
            style: TextStyle(color: AppColors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 36),
          for (final (icon, label) in _features)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(label, style: const TextStyle(color: AppColors.white, fontSize: 14)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
