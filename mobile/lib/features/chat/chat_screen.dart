import 'package:flutter/material.dart';
import '../../models/chat.dart';
import '../../data/chat_store.dart';
import '../../data/role_store.dart';
import '../../data/user_store.dart';
import '../../models/role.dart';
import '../../models/hotel_user.dart';
import '../../utils/theme.dart';
import '../../models/safe_enum.dart';
final Color _primary = AppColors.primary;

Department _deptOf(String name) =>
    safeEnum(name, Department.values, Department.management);

bool _canPost(Session s, ChatRoom room) {
  if (!s.has(Permission.sendChatMessage)) return false;
  if (room.isGeneral) return s.has(Permission.manageChat);
  return true;
}

List<ChatRoom> _visibleRooms(Session s) {
  final who = s.userId;
  final whoName = s.userName;
  return ChatStore.rooms.where((r) {
    if (r.isDirect) {
      return r.members.contains(who) || r.members.contains(whoName);
    }
    if (r.isGeneral) return true;
    if (r.departments.isEmpty) return true;
    if (s.isManagement) return true;
    return r.departments.any((d) => s.canAccessDepartment(_deptOf(d)));
  }).toList();
}

String _clock(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
}

String _dayLabel(DateTime d, DateTime now) {
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    return 'Today';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (d.year == yesterday.year &&
      d.month == yesterday.month &&
      d.day == yesterday.day) {
    return 'Yesterday';
  }
  const mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${mon[d.month - 1]} ${d.day}, ${d.year}';
}

Color _avatarColor(String name) {
  const palette = [
    AppColors.primary, AppColors.blue, AppColors.amber, AppColors.orange,
    AppColors.red400, AppColors.purple, AppColors.teal,
  ];
  final code = name.codeUnits.fold<int>(0, (a, c) => a + c);
  return palette[code % palette.length];
}

// ───────────────────────────── ROOM LIST ─────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    ChatStore.revision.addListener(_onChanged);
    RoleStore.sessionNotifier.addListener(_onChanged);
  }

  @override
  void dispose() {
    ChatStore.revision.removeListener(_onChanged);
    RoleStore.sessionNotifier.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _newMessage() async {
    final s = RoleStore.current;
    if (!s.has(Permission.sendChatMessage)) return;
    final who = s.userId;
    final whoName = s.userName;
    final staff = UserStore.getUsers()
        .where((u) => u.isAccountActive)
        .where((u) =>
            u.firebaseUid != who &&
            u.userId != who &&
            u.name != whoName)
        .toList();
    final memberId = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _StaffPicker(staff: staff),
    );
    if (memberId == null || memberId.isEmpty) return;
    final staffMember = staff.firstWhere(
      (u) => (u.firebaseUid ?? u.userId) == memberId,
      orElse: () => staff.isEmpty
          ? HotelUser(
              userId: memberId,
              name: memberId,
              email: '',
              phone: '',
              passwordHash: '',
              roleId: '',
              hotelId: s.hotelId ?? '',
              hotelName: s.hotelName,
              createdAt: DateTime.now(),
            )
          : staff.first,
    );
    ChatRoom? existing;
    for (final r in ChatStore.rooms) {
      if (r.isDirect &&
          (r.members.contains(who) || r.members.contains(whoName)) &&
          r.members.contains(memberId)) {
        existing = r;
        break;
      }
    }
    ChatRoom room;
    if (existing != null) {
      room = existing;
    } else {
      room = ChatRoom(
        name: staffMember.name,
        kind: ChatRoomKind.dm,
        members: [whoName.isEmpty ? who : whoName, memberId],
      );
      await ChatStore.addRoom(room);
    }
    if (!mounted) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ChatThreadScreen(room: room)));
  }

  @override
  Widget build(BuildContext context) {
    final s = RoleStore.current;
    if (!s.has(Permission.viewDepartmentChat)) {
      return const Scaffold(body: Center(child: Text('No chat access')));
    }
    final rooms = _visibleRooms(s);
    final general = rooms.where((r) => r.isGeneral).toList();
    final channels =
        rooms.where((r) => r.isDirect == false && r.isGeneral == false).toList();
    final dms = rooms.where((r) => r.isDirect).toList();
    final who = s.userId.isNotEmpty ? s.userId : s.userName;

    Widget roomTile(ChatRoom r) {
      final un = ChatStore.unreadIn(r.id, who);
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: _avatarColor(r.name).withValues(alpha: 0.15),
          foregroundColor: _avatarColor(r.name),
          child: Icon(r.isGeneral
              ? Icons.campaign_rounded
              : r.isDirect
                  ? Icons.person_rounded
                  : Icons.forum_rounded, size: 18),
        ),
        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(
          r.lastMessage.isEmpty ? 'No messages yet' : r.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 12,
              color: un > 0 ? AppColors.ink : AppColors.grey500,
              fontWeight: un > 0 ? FontWeight.w600 : FontWeight.w400),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_clock(r.lastMessageAt),
                style: TextStyle(fontSize: 10, color: un > 0 ? _primary : AppColors.grey500)),
            if (un > 0)
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                    color: _primary, borderRadius: BorderRadius.circular(9)),
                child: Text('$un',
                    style: const TextStyle(
                        color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => ChatThreadScreen(room: r)));
        },
      );
    }

    Widget section(String title, List<ChatRoom> list) {
      if (list.isEmpty) return const SizedBox.shrink();
      return Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(title.toUpperCase(),
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    letterSpacing: 0.5, color: _primary)),
          ),
        ),
        for (final r in list) roomTile(r),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Chat'),
        actions: [
          IconButton(
            onPressed: _newMessage,
            tooltip: 'New direct message',
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      floatingActionButton: s.has(Permission.sendChatMessage)
          ? FloatingActionButton(
              onPressed: _newMessage,
              backgroundColor: _primary,
              child: const Icon(Icons.edit_rounded),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          section('Pinned', general),
          section('Channels', channels),
          section('Direct Messages', dms),
          if (rooms.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No rooms available for your scope')),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────── THREAD ─────────────────────────────

class ChatThreadScreen extends StatefulWidget {
  final ChatRoom room;
  const ChatThreadScreen({super.key, required this.room});
  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final TextEditingController _text = TextEditingController();
  final ScrollController _scroll = ScrollController();

  ChatRoom get _room => ChatStore.roomById(widget.room.id) ?? widget.room;

  @override
  void initState() {
    super.initState();
    ChatStore.revision.addListener(_onChanged);
    _markRead();
  }

  @override
  void dispose() {
    ChatStore.revision.removeListener(_onChanged);
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    _markRead();
    _jumpToBottom(animated: false);
  }

  void _markRead() {
    final s = RoleStore.current;
    final who = s.userId.isNotEmpty ? s.userId : s.userName;
    if (who.isNotEmpty) ChatStore.markRead(widget.room.id, who);
  }

  void _jumpToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (animated) {
        _scroll.animateTo(target,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      } else {
        _scroll.jumpTo(target);
      }
    });
  }

  Future<void> _send() async {
    final s = RoleStore.current;
    final text = _text.text;
    if (text.trim().isEmpty) return;
    if (!_canPost(s, _room)) return;
    _text.clear();
    await ChatStore.sendMessage(
      roomId: _room.id,
      sender: s.userName.isEmpty ? 'Staff' : s.userName,
      senderId: s.userId,
      text: text,
    );
    setState(() {});
    _jumpToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final s = RoleStore.current;
    final room = _room;
    final messages = ChatStore.messagesFor(room.id);
    final canPost = _canPost(s, room);
    final generalLocked = room.isGeneral && !s.has(Permission.manageChat);

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(room.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          Text(
            room.isGeneral
                ? 'Hotel-wide · broadcast'
                : room.isDirect
                    ? 'Direct message'
                    : room.departments
                        .map((d) => _deptOf(d).name)
                        .join(' · '),
            style: TextStyle(fontSize: 10, color: AppColors.grey500),
          ),
        ]),
      ),
      body: Column(children: [
        if (generalLocked)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: AppColors.amber.withValues(alpha: 0.12),
            child: const Row(children: [
              Icon(Icons.campaign_rounded, size: 16, color: AppColors.amber),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Broadcast channel — only management & department heads can post.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        Expanded(
          child: messages.isEmpty
              ? const Center(child: Text('No messages yet — say hello!'))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final m = messages[i];
                    final mine = m.senderId.isNotEmpty && m.senderId == s.userId;
                    final showName = !mine &&
                        (i == 0 || messages[i - 1].sender != m.sender);
                    final showDay =
                        i == 0 || _dayLabel(m.createdAt, DateTime.now()) !=
                            _dayLabel(messages[i - 1].createdAt, DateTime.now());
                    final read = mine && m.readBy.length > 1;
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (showDay) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                                color: AppColors.grey200,
                                borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              _dayLabel(m.createdAt, DateTime.now()),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: mine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (showName)
                              Padding(
                                padding: const EdgeInsets.only(left: 4, top: 6, bottom: 2),
                                child: Text(m.sender,
                                    style: TextStyle(
                                        fontSize: 10, fontWeight: FontWeight.w800,
                                        color: _avatarColor(m.sender))),
                              ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 1.5),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              constraints: BoxConstraints(
                                  maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                              decoration: BoxDecoration(
                                color: mine ? _primary : AppColors.grey200,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: mine
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(m.text,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: mine ? AppColors.white : AppColors.ink)),
                                  const SizedBox(height: 2),
                                  Row(mainAxisSize: MainAxisSize.min, children: [
                                    Text(_clock(m.createdAt),
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: mine
                                                ? AppColors.white.withValues(alpha: 0.7)
                                                : AppColors.grey500)),
                                    if (mine) ...[
                                      const SizedBox(width: 3),
                                      Icon(read ? Icons.done_all_rounded : Icons.done_rounded,
                                          size: 12,
                                          color: read
                                              ? AppColors.white
                                              : AppColors.white.withValues(alpha: 0.7)),
                                    ],
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]);
                  },
                ),
        ),
        if (!canPost)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: const Text(
              'You have read-only access.',
              style: TextStyle(fontSize: 12, color: AppColors.grey500),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Message ${room.name}…',
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.grey200,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                onPressed: _send,
                backgroundColor: _primary,
                child: const Icon(Icons.send_rounded, size: 18),
              ),
            ]),
          ),
      ]),
    );
  }
}

// ─────────────────────────── STAFF DIRECTORY PICKER ───────────────────────────

/// Bottom sheet that lists the hotel's active staff (from `UserStore`) so a
/// user can start a direct chat by picking a colleague instead of typing a
/// free-text name. Falls back to a manual entry field when the directory has
/// not been synced yet.
class _StaffPicker extends StatefulWidget {
  final List<HotelUser> staff;
  const _StaffPicker({required this.staff});

  @override
  State<_StaffPicker> createState() => _StaffPickerState();
}

class _StaffPickerState extends State<_StaffPicker> {
  final TextEditingController _nameCtrl = TextEditingController();
  String _query = '';

  List<HotelUser> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.staff;
    return widget.staff
        .where((u) =>
            u.name.toLowerCase().contains(q) ||
            (u.roleId.isNotEmpty && u.roleId.toLowerCase().contains(q)))
        .toList();
  }

  void _pick(HotelUser u) {
    Navigator.pop(context, u.firebaseUid ?? u.userId);
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final canManual = _nameCtrl.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New direct message',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              labelText: 'Search staff',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.staff.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Directory not synced yet. Type a staff name below.',
                style: TextStyle(fontSize: 12, color: AppColors.grey500),
              ),
            )
          else
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final u in list)
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor:
                              _avatarColor(u.name).withValues(alpha: 0.15),
                          foregroundColor: _avatarColor(u.name),
                          child: const Icon(Icons.person_rounded, size: 18),
                        ),
                        title: Text(u.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        subtitle: Text(
                          [if (u.roleId.isNotEmpty) u.roleId,
                           ...u.assignedDepartments.map((d) => d.name)]
                              .join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 11, color: AppColors.grey500),
                        ),
                        onTap: () => _pick(u),
                      ),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No staff match "$_query".',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.grey500),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _primary),
              onPressed: canManual
                  ? () => Navigator.pop(context, _nameCtrl.text.trim())
                  : null,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Start chat'),
            ),
          ),
        ],
      ),
    );
  }
}
