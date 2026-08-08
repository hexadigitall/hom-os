import 'package:flutter/material.dart';
import '../../data/hotel_settings_store.dart';
import '../../data/role_store.dart';
import '../../models/hotel_profile.dart';
import '../../utils/theme.dart';

/// Hotel identity & branding settings. Owned by management (owner/manager);
/// every other role sees a read-only view. Writes land in the encrypted
/// local cache — the Firestore `hotels/{hotelId}` doc remains the
/// server-authoritative master for cross-device sync.
class HotelSettingsScreen extends StatefulWidget {
  const HotelSettingsScreen({super.key});

  @override
  State<HotelSettingsScreen> createState() => _HotelSettingsScreenState();
}

class _HotelSettingsScreenState extends State<HotelSettingsScreen> {
  static const _currencies = ['NGN', 'USD', 'EUR', 'GBP'];
  static const _timezones = [
    'Africa/Lagos',
    'Africa/Accra',
    'Africa/Nairobi',
    'Europe/London',
    'America/New_York',
    'UTC',
  ];

  late HotelProfile _profile;
  late bool _canEdit;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _tagline;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _website;
  late String _currency;
  late String _timezone;
  late bool _showTagline;

  @override
  void initState() {
    super.initState();
    final session = RoleStore.current;
    _canEdit = session.isManagement && session.isAccountActive;
    _profile = HotelSettingsStore.ensure(
      session.hotelId ?? '',
      session.hotelName,
    );
    _name = TextEditingController(text: _profile.hotelName);
    _tagline = TextEditingController(text: _profile.tagline);
    _address = TextEditingController(text: _profile.address);
    _city = TextEditingController(text: _profile.city);
    _state = TextEditingController(text: _profile.state);
    _phone = TextEditingController(text: _profile.phone);
    _email = TextEditingController(text: _profile.email);
    _website = TextEditingController(text: _profile.website);
    _currency = _currencies.contains(_profile.currency)
        ? _profile.currency
        : 'NGN';
    _timezone = _timezones.contains(_profile.timezone)
        ? _profile.timezone
        : 'Africa/Lagos';
    _showTagline = _profile.showTaglineOnSplash;
  }

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _phone.dispose();
    _email.dispose();
    _website.dispose();
    super.dispose();
  }

  void _applyForm() {
    _profile
      ..hotelName = _name.text.trim()
      ..tagline = _tagline.text.trim()
      ..address = _address.text.trim()
      ..city = _city.text.trim()
      ..state = _state.text.trim()
      ..phone = _phone.text.trim()
      ..email = _email.text.trim()
      ..website = _website.text.trim()
      ..currency = _currency
      ..timezone = _timezone
      ..showTaglineOnSplash = _showTagline
      ..updatedAt = DateTime.now();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    _applyForm();
    await HotelSettingsStore.save(_profile);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hotel settings saved')),
    );
  }

  Future<void> _reset() async {
    final confirmed = await _confirm(
      'Revert hotel settings?',
      'This clears the saved branding and restores the defaults for this '
          'hotel.',
    );
    if (confirmed != true || !mounted) return;
    final session = RoleStore.current;
    await HotelSettingsStore.delete(session.hotelId ?? '');
    if (!mounted) return;
    setState(() {
      _profile = HotelSettingsStore.ensure(
        session.hotelId ?? '',
        session.hotelName,
      );
      _fillFrom(_profile);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reverted to defaults')),
    );
  }

  /// Full CRUD delete: removes the branding record entirely (no re-seed), so
  /// every surface falls back to the server-mirrored session identity.
  Future<void> _removeBranding() async {
    final confirmed = await _confirm(
      'Remove hotel branding?',
      'The saved name, tagline and contact details will be removed. HOM '
          'defaults will be used on the splash, lock and headers.',
    );
    if (confirmed != true || !mounted) return;
    final session = RoleStore.current;
    await HotelSettingsStore.delete(session.hotelId ?? '');
    if (!mounted) return;
    setState(() {
      _profile = HotelSettingsStore.resolve(
        session.hotelId,
        session.hotelName,
      );
      _fillFrom(_profile);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Branding removed')),
    );
  }

  Future<bool> _confirm(String title, String body) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(title, style: const TextStyle(fontSize: 16)),
        content: Text(body, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _fillFrom(HotelProfile p) {
    _name.text = p.hotelName;
    _tagline.text = p.tagline;
    _address.text = p.address;
    _city.text = p.city;
    _state.text = p.state;
    _phone.text = p.phone;
    _email.text = p.email;
    _website.text = p.website;
    _currency = _currencies.contains(p.currency) ? p.currency : 'NGN';
    _timezone = _timezones.contains(p.timezone) ? p.timezone : 'Africa/Lagos';
    _showTagline = p.showTaglineOnSplash;
  }

  /// Live preview of the branded splash — hotel name and tagline update as
  /// they are typed, so the hotel owner sees exactly what guests/manager will
  /// see on the splash and lock screens.
  Widget _brandPreview() {
    final name = _name.text.trim();
    final tagline = (_showTagline && _tagline.text.trim().isNotEmpty)
        ? _tagline.text.trim()
        : 'The Hotel Operating System\nPowering Nigeria.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E9F6E), Color(0xFF0B7A55), Color(0xFF064534)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(7),
          child: Image.asset(
            'assets/logo/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 10),
        const Text('HOM',
            style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 2)),
        if (name.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.3,
                  height: 1.25)),
        ],
        const SizedBox(height: 4),
        Text(tagline,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.white70, fontSize: 11, height: 1.4)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Settings',
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _brandPreview(),
          const SizedBox(height: 16),
          if (!_canEdit)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(children: [
                Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Only the hotel owner or manager can change these settings.',
                    style: TextStyle(fontSize: 13, color: AppColors.blue),
                  ),
                ),
              ]),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: AbsorbPointer(
                  absorbing: !_canEdit,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Identity & Branding',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Hotel name *',
                          prefixIcon: Icon(Icons.business_rounded),
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tagline,
                        decoration: const InputDecoration(
                          labelText: 'Tagline',
                          hintText: 'e.g. Luxury. Restored.',
                          prefixIcon: Icon(Icons.format_quote_rounded),
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        maxLength: 120,
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _currency,
                            items: _currencies
                                .map((c) => DropdownMenuItem(
                                    value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _currency = v);
                            },
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                              prefixIcon: Icon(Icons.attach_money_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _timezone,
                            items: _timezones
                                .map((t) => DropdownMenuItem(
                                    value: t, child: Text(t)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _timezone = v);
                            },
                            decoration: const InputDecoration(
                              labelText: 'Timezone',
                              prefixIcon: Icon(Icons.schedule_rounded),
                            ),
                          ),
                        ),
                      ]),
                      const Divider(height: 32),
                      const Text('Contact & Location',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _address,
                        decoration: const InputDecoration(
                          labelText: 'Street address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: _city,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              prefixIcon: Icon(Icons.location_city_rounded),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _state,
                            decoration: const InputDecoration(
                              labelText: 'State',
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: Icon(Icons.phone_rounded),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_rounded),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final email = v.trim();
                          final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email);
                          return valid ? null : 'Enter a valid email';
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _website,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Website',
                          prefixIcon: Icon(Icons.public_rounded),
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                      const Divider(height: 32),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Show tagline on splash',
                            style: TextStyle(fontSize: 14)),
                        subtitle: const Text(
                          'Display this hotel\'s tagline on the branded splash and lock screens.',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _showTagline,
                        onChanged: (v) => setState(() => _showTagline = v),
                      ),
                      if (_canEdit) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(_saving ? 'Saving…' : 'Save Changes'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: _reset,
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: const Text('Revert to defaults'),
                          ),
                        ),
                        const Divider(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _removeBranding,
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.red),
                            label: const Text('Remove branding',
                                style: TextStyle(color: AppColors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.red),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
