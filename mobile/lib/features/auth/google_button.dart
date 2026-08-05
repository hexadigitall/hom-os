import 'package:flutter/material.dart';
import '../../utils/theme.dart';

/// Full-width "Continue with Google" outlined button with loading state.
class GoogleButton extends StatelessWidget {
  const GoogleButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.label = 'Continue with Google',
  });

  final VoidCallback onPressed;
  final bool loading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.g_mobiledata_rounded, size: 26),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.grey700),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.grey300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/// Divider used to separate the Google button from the email/password form.
class GoogleOrDivider extends StatelessWidget {
  const GoogleOrDivider({super.key, this.label = 'or with email'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.grey500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}
