import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/whatsapp.dart';
import '../../data/whatsapp_store.dart';
import '../../utils/role_gate.dart';
import '../../models/role.dart';
import '../../utils/theme.dart';

const Color _primaryGreen = AppColors.primary;

class WhatsAppScreen extends StatefulWidget {
  final String? initialTemplateId;
  final String? initialPhone;
  final Map<String, String>? initialVars;
  const WhatsAppScreen(
      {super.key, this.initialTemplateId, this.initialPhone, this.initialVars});
  @override
  State<WhatsAppScreen> createState() => _WhatsAppScreenState();
}

class _WhatsAppScreenState extends State<WhatsAppScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contacts = WhatsAppStore.contacts;
    final sentToday = WhatsAppStore.sentTodayCount;

    return Scaffold(
      body: Column(children: [
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(12, 6, 16, 0),
          child: Row(children: [
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.whatsapp.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle,
                    size: 14, color: AppColors.whatsapp),
                const SizedBox(width: 4),
                Text('$sentToday sent',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.whatsapp)),
              ]),
            ),
          ]),
        ),
        _dashboardRow(contacts.length, sentToday),
        TabBar(
          controller: _tabCtrl,
          labelColor: _primaryGreen,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: _primaryGreen,
          tabs: const [
            Tab(text: 'Contacts', icon: Icon(Icons.people_rounded, size: 18)),
            Tab(text: 'Templates', icon: Icon(Icons.message_rounded, size: 18)),
            Tab(text: 'History', icon: Icon(Icons.history_rounded, size: 18)),
          ],
        ),
        Expanded(
            child: TabBarView(controller: _tabCtrl, children: [
          _ContactsTab(
              searchCtrl: _searchCtrl, onChanged: () => setState(() {})),
          _TemplatesTab(
              initialTemplateId: widget.initialTemplateId,
              initialPhone: widget.initialPhone,
              initialVars: widget.initialVars,
              onChanged: () => setState(() {})),
          _HistoryTab(),
        ])),
      ]),
      floatingActionButton: RoleGate(
        requiredPermission: Permission.manageWhatsApp,
        child: FloatingActionButton(
          onPressed: () => _addContact(context),
          backgroundColor: AppColors.whatsapp,
          child: const Icon(Icons.add, color: AppColors.white),
        ),
      ),
    );
  }

  Widget _dashboardRow(int contacts, int sentToday) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: AppColors.white,
      child: Row(children: [
        _stat('$contacts', 'Contacts', Icons.people_rounded),
        const SizedBox(width: 12),
        _stat('$sentToday', 'Sent Today', Icons.done_all_rounded),
        const SizedBox(width: 12),
        _stat('${WhatsAppStore.templates.length}', 'Templates',
            Icons.description_rounded),
      ]),
    );
  }

  Widget _stat(String v, String l, IconData i) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.whatsapp.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(i, size: 14, color: AppColors.whatsapp),
          const SizedBox(width: 4),
          Text(v,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: AppColors.whatsapp)),
        ]),
        Text(l, style: TextStyle(fontSize: 10, color: AppColors.grey600)),
      ]),
    ));
  }

  void _addContact(BuildContext context) {
    final nameCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    final notesCtl = TextEditingController();
    String entityType = 'other';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSB) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                              child: Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                      color: AppColors.grey300,
                                      borderRadius: BorderRadius.circular(2)))),
                          const SizedBox(height: 16),
                          const Text('Add WhatsApp Contact',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 17)),
                          const SizedBox(height: 16),
                          TextField(
                              controller: nameCtl,
                              decoration: const InputDecoration(
                                  labelText: 'Contact Name')),
                          const SizedBox(height: 12),
                          TextField(
                              controller: phoneCtl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: '0803 123 4567')),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: entityType,
                            items: const [
                              DropdownMenuItem(
                                  value: 'booking',
                                  child: Text('Booking Guest')),
                              DropdownMenuItem(
                                  value: 'staff', child: Text('Staff')),
                              DropdownMenuItem(
                                  value: 'vendor', child: Text('Vendor')),
                              DropdownMenuItem(
                                  value: 'subscription',
                                  child: Text('Subscription')),
                              DropdownMenuItem(
                                  value: 'other', child: Text('Other')),
                            ],
                            onChanged: (v) => setSB(() => entityType = v!),
                            decoration:
                                const InputDecoration(labelText: 'Category'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                              controller: notesCtl,
                              maxLines: 2,
                              decoration:
                                  const InputDecoration(labelText: 'Notes')),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (nameCtl.text.isEmpty ||
                                    phoneCtl.text.isEmpty) return;
                                WhatsAppStore.addContact(WhatsAppContact(
                                  id: WhatsAppStore.genId(),
                                  name: nameCtl.text,
                                  phone: phoneCtl.text,
                                  entityType:
                                      WhatsAppStore.parseEntityType(entityType),
                                  notes: notesCtl.text,
                                ));
                                Navigator.pop(ctx);
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.whatsapp,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14)),
                              child: const Text('Add Contact'),
                            ),
                          ),
                        ]),
                  ),
                ),
              )),
    );
  }
}

// ===================== CONTACTS TAB =====================

class _ContactsTab extends StatelessWidget {
  final TextEditingController searchCtrl;
  final VoidCallback onChanged;
  const _ContactsTab({required this.searchCtrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final contacts = WhatsAppStore.contacts;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: TextField(
          controller: searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search contacts...',
            prefixIcon: const Icon(Icons.search, size: 20),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (_) => onChanged(),
        ),
      ),
      Expanded(
        child: contacts.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_rounded, size: 64, color: AppColors.grey300),
                  const SizedBox(height: 12),
                  Text('No contacts yet',
                      style: TextStyle(color: AppColors.grey500)),
                  const SizedBox(height: 4),
                  Text('Add contacts to send WhatsApp messages',
                      style: TextStyle(fontSize: 12, color: AppColors.grey400)),
                ]),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: contacts.length,
                itemBuilder: (ctx, i) => _contactCard(context, contacts[i]),
              ),
      ),
    ]);
  }

  Widget _contactCard(BuildContext context, WhatsAppContact c) {
    final q = searchCtrl.text.toLowerCase();
    if (q.isNotEmpty &&
        !c.name.toLowerCase().contains(q) &&
        !c.phone.contains(q)) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.whatsapp.withValues(alpha: 0.15),
            child: Text(c.name[0].toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.whatsapp)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              Text(c.phone,
                  style: TextStyle(fontSize: 12, color: AppColors.grey600)),
              if (c.entityType != ContactEntityType.other)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: _entityColor(c.entityType).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(_entityLabel(c.entityType),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _entityColor(c.entityType))),
                ),
            ]),
          ),
          RoleGate(
            requiredPermission: Permission.sendAutomatedWhatsApp,
            child: IconButton(
              icon: const Icon(Icons.message_rounded,
                  size: 20, color: AppColors.whatsapp),
              tooltip: 'Send WhatsApp',
              onPressed: () => _sendToContact(context, c),
            ),
          ),
          RoleGate(
            requiredPermission: Permission.manageWhatsApp,
            child: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _editContact(context, c);
                if (v == 'delete') {
                  WhatsAppStore.removeContact(c.id);
                  onChanged();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'edit',
                    child: SizedBox(
                        width: 80,
                        child: Row(children: [
                          Icon(Icons.edit_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(fontSize: 13))
                        ]))),
                PopupMenuItem(
                    value: 'delete',
                    child: SizedBox(
                        width: 80,
                        child: Row(children: [
                          Icon(Icons.delete_rounded,
                              size: 16, color: AppColors.red),
                          SizedBox(width: 8),
                          Text('Delete',
                              style:
                                  TextStyle(fontSize: 13, color: AppColors.red))
                        ]))),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  void _sendToContact(BuildContext context, WhatsAppContact c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _SendSheet(contact: c, onSent: () => onChanged()),
    );
  }

  void _editContact(BuildContext context, WhatsAppContact c) {
    final nameCtl = TextEditingController(text: c.name);
    final phoneCtl = TextEditingController(text: c.phone);
    final notesCtl = TextEditingController(text: c.notes);
    String entityType = _entityTypeStr(c.entityType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSB) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                              child: Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                      color: AppColors.grey300,
                                      borderRadius: BorderRadius.circular(2)))),
                          const SizedBox(height: 16),
                          Text('Edit ${c.name}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 17)),
                          const SizedBox(height: 16),
                          TextField(
                              controller: nameCtl,
                              decoration: const InputDecoration(
                                  labelText: 'Contact Name')),
                          const SizedBox(height: 12),
                          TextField(
                              controller: phoneCtl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                  labelText: 'Phone Number')),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: entityType,
                            items: const [
                              DropdownMenuItem(
                                  value: 'booking',
                                  child: Text('Booking Guest')),
                              DropdownMenuItem(
                                  value: 'staff', child: Text('Staff')),
                              DropdownMenuItem(
                                  value: 'vendor', child: Text('Vendor')),
                              DropdownMenuItem(
                                  value: 'subscription',
                                  child: Text('Subscription')),
                              DropdownMenuItem(
                                  value: 'other', child: Text('Other')),
                            ],
                            onChanged: (v) => setSB(() => entityType = v!),
                            decoration:
                                const InputDecoration(labelText: 'Category'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                              controller: notesCtl,
                              maxLines: 2,
                              decoration:
                                  const InputDecoration(labelText: 'Notes')),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (nameCtl.text.isEmpty ||
                                    phoneCtl.text.isEmpty) return;
                                c.name = nameCtl.text;
                                c.phone = phoneCtl.text;
                                c.notes = notesCtl.text;
                                c.entityType =
                                    WhatsAppStore.parseEntityType(entityType);
                                WhatsAppStore.updateContact(c);
                                Navigator.pop(ctx);
                                onChanged();
                              },
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ]),
                  ),
                ),
              )),
    );
  }

  Color _entityColor(ContactEntityType t) {
    switch (t) {
      case ContactEntityType.booking:
        return AppColors.blue;
      case ContactEntityType.staff:
        return _primaryGreen;
      case ContactEntityType.vendor:
        return AppColors.orange;
      case ContactEntityType.subscription:
        return AppColors.purple;
      case ContactEntityType.compliance:
        return AppColors.indigo;
      case ContactEntityType.other:
        return AppColors.grey500;
    }
  }

  String _entityLabel(ContactEntityType t) {
    switch (t) {
      case ContactEntityType.booking:
        return 'Guest';
      case ContactEntityType.staff:
        return 'Staff';
      case ContactEntityType.vendor:
        return 'Vendor';
      case ContactEntityType.subscription:
        return 'Subscription';
      case ContactEntityType.compliance:
        return 'Compliance';
      case ContactEntityType.other:
        return 'Other';
    }
  }

  String _entityTypeStr(ContactEntityType t) {
    switch (t) {
      case ContactEntityType.booking:
        return 'booking';
      case ContactEntityType.staff:
        return 'staff';
      case ContactEntityType.vendor:
        return 'vendor';
      case ContactEntityType.subscription:
        return 'subscription';
      case ContactEntityType.compliance:
        return 'compliance';
      case ContactEntityType.other:
        return 'other';
    }
  }
}

// ===================== SEND SHEET =====================

class _SendSheet extends StatefulWidget {
  final WhatsAppContact contact;
  final VoidCallback onSent;
  const _SendSheet({required this.contact, required this.onSent});

  @override
  State<_SendSheet> createState() => _SendSheetState();
}

class _SendSheetState extends State<_SendSheet> {
  final _msgCtrl = TextEditingController();
  String? _selectedTemplateId;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = WhatsAppStore.templates
        .where((t) =>
            t.entityType == null || t.entityType == widget.contact.entityType)
        .toList();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.grey300,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          AppColors.whatsapp.withValues(alpha: 0.15),
                      child: Text(widget.contact.name[0].toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.whatsapp,
                              fontSize: 14))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(widget.contact.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                        Text(widget.contact.phone,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.grey600)),
                      ])),
                ]),
                const SizedBox(height: 16),
                if (templates.isNotEmpty) ...[
                  const Text('Quick Template',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 28,
                    child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: templates
                            .map((t) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(t.name,
                                        style: const TextStyle(fontSize: 10)),
                                    selected: _selectedTemplateId == t.id,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedTemplateId = t.id;
                                        _msgCtrl.text = t.message;
                                      });
                                    },
                                    selectedColor: AppColors.whatsapp
                                        .withValues(alpha: 0.2),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ))
                            .toList()),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _msgCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: RoleGate(
                    requiredPermission: Permission.sendAutomatedWhatsApp,
                    child: ElevatedButton.icon(
                      onPressed:
                          _msgCtrl.text.isEmpty ? null : () => _send(context),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Send via WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.whatsapp,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  Future<void> _send(BuildContext context) async {
    final phone = widget.contact.formattedPhone;
    final text = Uri.encodeComponent(_msgCtrl.text);
    final uri = Uri.parse('https://wa.me/$phone?text=$text');

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      WhatsAppStore.logMessage(WhatsAppMessage(
        id: WhatsAppStore.genMsgId(),
        contactId: widget.contact.id,
        contactName: widget.contact.name,
        phone: widget.contact.phone,
        message: _msgCtrl.text,
        sentAt: DateTime.now(),
      ));
      widget.onSent();
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Could not open WhatsApp. Please ensure WhatsApp is installed.'),
              backgroundColor: AppColors.red),
        );
      }
    }
  }
}

// ===================== TEMPLATES TAB =====================

class _TemplatesTab extends StatelessWidget {
  final String? initialTemplateId;
  final String? initialPhone;
  final Map<String, String>? initialVars;
  final VoidCallback onChanged;
  const _TemplatesTab(
      {this.initialTemplateId,
      this.initialPhone,
      this.initialVars,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final templates = WhatsAppStore.templates;
    return ListView(padding: const EdgeInsets.all(12), children: [
      SizedBox(
        width: double.infinity,
        child: RoleGate(
          requiredPermission: Permission.manageWhatsApp,
          child: OutlinedButton.icon(
            onPressed: () => _addOrEditTemplate(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Template'),
          ),
        ),
      ),
      if (initialTemplateId != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              color: AppColors.amber50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.amber200)),
          child: Row(children: [
            const Icon(Icons.info_rounded, size: 16, color: AppColors.amber),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Template pre-loaded. Send to $initialPhone',
                    style: TextStyle(fontSize: 12, color: AppColors.amber900))),
          ]),
        ),
      ],
      if (templates.isEmpty)
        Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(children: [
              Icon(Icons.message_rounded,
                  size: 48, color: AppColors.grey300),
              const SizedBox(height: 8),
              Text('No templates yet. Create your first one.',
                  style: TextStyle(color: AppColors.grey500)),
            ]),
          ),
        ),
      ...templates.map((t) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _previewAndSend(context, t),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppColors.whatsapp.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.message_rounded,
                        size: 20, color: AppColors.whatsapp),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(t.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                            t.message.replaceAll(RegExp(r'\[.*?\]'), '...'),
                            style: TextStyle(
                                fontSize: 11, color: AppColors.grey500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ])),
                  RoleGate(
                      requiredPermission: Permission.manageWhatsApp,
                      child: IconButton(
                          onPressed: () => _addOrEditTemplate(context,
                              existing: t),
                          icon: const Icon(Icons.edit_rounded,
                              size: 18, color: AppColors.grey600))),
                  RoleGate(
                      requiredPermission: Permission.manageWhatsApp,
                      child: IconButton(
                          onPressed: () {
                            WhatsAppStore.removeTemplate(t.id);
                            onChanged();
                          },
                          icon: const Icon(Icons.delete_rounded,
                              size: 18, color: AppColors.redAccent))),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.grey500),
                ]),
              ),
            ),
          )),
    ]);
  }

  void _addOrEditTemplate(BuildContext context,
      {WhatsAppTemplate? existing}) {
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final msgCtl = TextEditingController(text: existing?.message ?? '');
    var entityType = existing?.entityType ?? ContactEntityType.other;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSB) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                                color: AppColors.grey300,
                                borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    Text(existing == null
                        ? 'New Template'
                        : 'Edit ${existing.name}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 16),
                    TextField(
                        controller: nameCtl,
                        decoration: const InputDecoration(
                            labelText: 'Template Name')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ContactEntityType>(
                      initialValue: entityType,
                      items: ContactEntityType.values
                          .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(_entityLabel(e))))
                          .toList(),
                      onChanged: (v) => setSB(() => entityType = v!),
                      decoration: const InputDecoration(
                          labelText: 'Entity Type'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: msgCtl,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          hintText: 'Use [Placeholders] like [Guest], [Room]',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(12))),
                        )),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameCtl.text.trim().isEmpty ||
                              msgCtl.text.trim().isEmpty) {
                            return;
                          }
                          if (existing == null) {
                            WhatsAppStore.addTemplate(WhatsAppTemplate(
                              id: WhatsAppStore.genTemplateId(),
                              name: nameCtl.text.trim(),
                              message: msgCtl.text,
                              entityType: entityType,
                            ));
                          } else {
                            WhatsAppStore.updateTemplate(WhatsAppTemplate(
                              id: existing.id,
                              name: nameCtl.text.trim(),
                              message: msgCtl.text,
                              entityType: entityType,
                            ));
                          }
                          Navigator.pop(ctx);
                          onChanged();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.whatsapp,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text('Save'),
                      ),
                    ),
                  ]),
            ),
          ),
        );
      }),
    );
  }

  String _entityLabel(ContactEntityType e) {
    switch (e) {
      case ContactEntityType.booking:
        return 'Booking';
      case ContactEntityType.staff:
        return 'Staff';
      case ContactEntityType.vendor:
        return 'Vendor';
      case ContactEntityType.subscription:
        return 'Subscription';
      case ContactEntityType.compliance:
        return 'Compliance';
      case ContactEntityType.other:
        return 'General / Other';
    }
  }

  void _previewAndSend(BuildContext context, WhatsAppTemplate t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSB) {
        final phoneCtl = TextEditingController(text: initialPhone ?? '');
        final msgCtl = TextEditingController(
            text: initialVars != null
                ? WhatsAppStore.interpolate(t.message, initialVars!)
                : t.message);

        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                                color: AppColors.grey300,
                                borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    Text(t.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 12),
                    TextField(
                        controller: phoneCtl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: '0803 123 4567')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: msgCtl,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: RoleGate(
                        requiredPermission: Permission.sendAutomatedWhatsApp,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (phoneCtl.text.isEmpty) return;
                            final raw =
                                phoneCtl.text.replaceAll(RegExp(r'[^\d+]'), '');
                            final phone = raw.startsWith('0')
                                ? '+234${raw.substring(1)}'
                                : raw.startsWith('+')
                                    ? raw
                                    : '+234$raw';
                            final text = Uri.encodeComponent(msgCtl.text);
                            final uri =
                                Uri.parse('https://wa.me/$phone?text=$text');
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Send via WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.whatsapp,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ]),
            ),
          ),
        );
      }),
    );
  }
}

// ===================== HISTORY TAB =====================

class _HistoryTab extends StatefulWidget {
  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  @override
  Widget build(BuildContext context) {
    final messages = WhatsAppStore.messages;
    return messages.isEmpty
        ? Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.history_rounded, size: 64, color: AppColors.grey300),
              const SizedBox(height: 12),
              Text('No messages sent yet',
                  style: TextStyle(color: AppColors.grey500)),
            ]),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (ctx, i) {
              final m = messages[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.whatsapp.withValues(alpha: 0.15),
                    child: Text(m.contactName[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.whatsapp)),
                  ),
                  title: Text(m.contactName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text(m.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: AppColors.grey600)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                              '${m.sentAt.hour.toString().padLeft(2, '0')}:${m.sentAt.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.grey500)),
                          const SizedBox(height: 2),
                          Icon(Icons.check_circle,
                              size: 14,
                              color: m.status == MessageStatus.sent
                                  ? AppColors.whatsapp
                                  : m.status == MessageStatus.delivered
                                      ? AppColors.blue
                                      : AppColors.red),
                        ]),
                    RoleGate(
                      requiredPermission: Permission.manageWhatsApp,
                      child: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _editMessage(context, m);
                          if (v == 'delete') {
                            WhatsAppStore.removeMessage(m.id);
                            setState(() {});
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                              value: 'edit',
                              child: SizedBox(
                                  width: 80,
                                  child: Row(children: [
                                    Icon(Icons.edit_rounded, size: 16),
                                    SizedBox(width: 8),
                                    Text('Edit', style: TextStyle(fontSize: 13))
                                  ]))),
                          PopupMenuItem(
                              value: 'delete',
                              child: SizedBox(
                                  width: 80,
                                  child: Row(children: [
                                    Icon(Icons.delete_rounded,
                                        size: 16, color: AppColors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(
                                            fontSize: 13, color: AppColors.red))
                                  ]))),
                        ],
                      ),
                    ),
                  ]),
                ),
              );
            },
          );
  }

  void _editMessage(BuildContext context, WhatsAppMessage m) {
    final phoneCtl = TextEditingController(text: m.phone);
    final msgCtl = TextEditingController(text: m.message);
    MessageStatus selectedStatus = m.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSB) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                              child: Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                      color: AppColors.grey300,
                                      borderRadius: BorderRadius.circular(2)))),
                          const SizedBox(height: 16),
                          Text('Edit Message',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 17)),
                          const SizedBox(height: 16),
                          TextField(
                              controller: phoneCtl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                  labelText: 'Recipient Phone')),
                          const SizedBox(height: 12),
                          TextField(
                              controller: msgCtl,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                  labelText: 'Message Body',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(12))))),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<MessageStatus>(
                            initialValue: selectedStatus,
                            items: const [
                              DropdownMenuItem(
                                  value: MessageStatus.sent,
                                  child: Text('Sent')),
                              DropdownMenuItem(
                                  value: MessageStatus.delivered,
                                  child: Text('Delivered')),
                              DropdownMenuItem(
                                  value: MessageStatus.failed,
                                  child: Text('Failed')),
                            ],
                            onChanged: (v) => setSB(() => selectedStatus = v!),
                            decoration:
                                const InputDecoration(labelText: 'Status'),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: RoleGate(
                              requiredPermission: Permission.manageWhatsApp,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (phoneCtl.text.isEmpty ||
                                      msgCtl.text.isEmpty) return;
                                  WhatsAppStore.updateMessage(WhatsAppMessage(
                                    id: m.id,
                                    contactId: m.contactId,
                                    contactName: m.contactName,
                                    phone: phoneCtl.text,
                                    message: msgCtl.text,
                                    sentAt: m.sentAt,
                                    status: selectedStatus,
                                  ));
                                  Navigator.pop(ctx);
                                  setState(() {});
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.whatsapp,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14)),
                                child: const Text('Save Changes'),
                              ),
                            ),
                          ),
                        ]),
                  ),
                ),
              )),
    );
  }
}
