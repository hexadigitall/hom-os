import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/role.dart';
import '../../data/user_store.dart';
import '../../data/role_store.dart';
import '../../utils/theme.dart';

class InviteStaffSheet extends StatefulWidget {
  const InviteStaffSheet({super.key});
  @override
  State<InviteStaffSheet> createState() => _InviteStaffSheetState();
}

class _InviteStaffSheetState extends State<InviteStaffSheet> {
  String? _selectedRoleId;
  String? _generatedCode;

  final _availableRoles = RoleStore.prebuiltRoles
      .where((r) => r.id != 'super_admin' && r.id != 'auditor')
      .toList();

  void _generate() {
    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role'), backgroundColor: AppColors.red),
      );
      return;
    }
    final role = RoleStore.prebuiltRoles.cast<AppRole?>().firstWhere(
      (r) => r!.id == _selectedRoleId,
      orElse: () => null,
    );
    if (role == null) return;
    final hotelId = RoleStore.current.hotelId ?? 'hotel_001';
    final hotelName = UserStore.ownerHotelName ?? 'My Hotel';
    final code = UserStore.generateInviteCode(role.id, role.name, hotelId, hotelName);
    setState(() => _generatedCode = code);
  }

  void _copy() {
    if (_generatedCode == null) return;
    Clipboard.setData(ClipboardData(text: _generatedCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied!')),
    );
  }

  void _shareWhatsApp() {
    if (_generatedCode == null) return;
    Clipboard.setData(ClipboardData(text: _generatedCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied! Paste it into your WhatsApp message.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Invite Staff', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 4),
          const Text('Generate a one-time invite code to share via WhatsApp',
              style: TextStyle(fontSize: 13, color: AppColors.grey500)),
          const SizedBox(height: 20),
          const Text('Select role', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedRoleId,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_rounded)),
            hint: const Text('Choose a role'),
            items: _availableRoles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
            onChanged: (v) => setState(() {
              _selectedRoleId = v;
              _generatedCode = null;
            }),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.generating_tokens_rounded, size: 18),
              label: const Text('Generate Invite Code'),
            ),
          ),
          if (_generatedCode != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(children: [
                const Text('Invite Code', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                const SizedBox(height: 6),
                SelectableText(_generatedCode!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 2, color: AppColors.primary)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  TextButton.icon(onPressed: _copy, icon: const Icon(Icons.copy_rounded, size: 16), label: const Text('Copy')),
                  const SizedBox(width: 12),
                  TextButton.icon(onPressed: _shareWhatsApp, icon: const Icon(Icons.chat_rounded, size: 16, color: AppColors.whatsapp), label: const Text('Share', style: TextStyle(color: AppColors.whatsapp))),
                ]),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
