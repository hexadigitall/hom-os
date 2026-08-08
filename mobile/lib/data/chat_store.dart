import 'persistence_service.dart';
import 'store_sync.dart';
import '../models/chat.dart';
import 'package:flutter/foundation.dart';

/// Internal department chat — offline-first store.
///
/// Collections (flat, under hotels/{hotelId}/):
///   chat_rooms    — channels (#front-desk …), the #hotel-general broadcast
///                   room, and 1:1 DM rooms
///   chat_messages — messages (read receipts via `readBy`)
///
/// Posting rules are enforced at the UI layer:
///   * #hotel-general is write-restricted to `manageChat` (management/heads)
///   * channels are scope-gated by their `departments`
///   * DMs are visible only to the two `members`
///
/// NOTE: production should also enforce these with Firestore security rules;
/// the UI filter keeps conversations out of sight, rules keep them out of reach.
class ChatStore {
  static final List<ChatRoom> _rooms = [];
  static final List<ChatMessage> _messages = [];

  /// Bumped on every cloud merge so chat UIs can rebuild live.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static final StoreSync<ChatRoom> roomSync = _initRoomSync();
  static final StoreSync<ChatMessage> messageSync = _initMessageSync();

  static StoreSync<ChatRoom> _initRoomSync() {
    final s = StoreSync<ChatRoom>(
      collection: 'chat_rooms',
      target: _rooms,
      fromJson: ChatRoom.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'chat_rooms',
      onMerge: () => revision.value++,
    );
    CloudSync.register(s);
    return s;
  }

  static StoreSync<ChatMessage> _initMessageSync() {
    final s = StoreSync<ChatMessage>(
      collection: 'chat_messages',
      target: _messages,
      fromJson: ChatMessage.fromJson,
      toJson: (e) => e.toJson(),
      cacheKey: 'chat_messages',
      onMerge: () => revision.value++,
    );
    CloudSync.register(s);
    return s;
  }

  // ===================== INIT =====================

  static Future<void> load() async {
    final r = PersistenceService.loadList('chat_rooms', ChatRoom.fromJson);
    if (r != null && r.isNotEmpty) { _rooms.addAll(r); } else { _seedRooms(); }
    final m = PersistenceService.loadList('chat_messages', ChatMessage.fromJson);
    if (m != null && m.isNotEmpty) { _messages.addAll(m); } else { _seedMessages(); }
    roomSync.loadMeta();
    messageSync.loadMeta();
  }

  static Future<void> _save() async {
    await PersistenceService.saveList('chat_rooms', _rooms, (e) => e.toJson());
    await PersistenceService.saveList('chat_messages', _messages, (e) => e.toJson());
    await roomSync.push();
    await messageSync.push();
  }

  // ===================== SEEDS =====================

  static void _seedRooms() {
    final now = DateTime.now();
    _rooms.addAll([
      ChatRoom(
        id: 'room_general', name: 'Hotel General', kind: ChatRoomKind.general,
        departments: const [], lastMessageAt: now,
        lastMessage: 'Welcome — this is the hotel-wide announcement channel.',
      ),
      ChatRoom(
        id: 'room_frontdesk', name: 'Front Desk & Concierge',
        kind: ChatRoomKind.channel,
        departments: const ['reception', 'reservations', 'concierge'],
        lastMessage: 'Welcome aboard, Front Desk!', lastMessageAt: now,
      ),
      ChatRoom(
        id: 'room_housekeeping', name: 'Housekeeping & Laundry',
        kind: ChatRoomKind.channel,
        departments: const ['housekeeping', 'laundry'],
        lastMessage: 'Welcome aboard, Housekeeping!', lastMessageAt: now,
      ),
      ChatRoom(
        id: 'room_engineering', name: 'Engineering & Power',
        kind: ChatRoomKind.channel, departments: const ['engineering'],
        lastMessage: 'Welcome aboard, Engineering!', lastMessageAt: now,
      ),
      ChatRoom(
        id: 'room_fnb', name: 'Kitchen, Bar & Banqueting',
        kind: ChatRoomKind.channel,
        departments: const ['kitchen', 'restaurants', 'banqueting'],
        lastMessage: 'Welcome aboard, F&B!', lastMessageAt: now,
      ),
      ChatRoom(
        id: 'room_backoffice', name: 'Accounts, Procurement & HR',
        kind: ChatRoomKind.channel,
        departments: const ['accounts', 'procurement', 'humanResources'],
        lastMessage: 'Welcome aboard, Back Office!', lastMessageAt: now,
      ),
      ChatRoom(
        id: 'room_security', name: 'Security & HSE',
        kind: ChatRoomKind.channel,
        departments: const ['security', 'healthSafety'],
        lastMessage: 'Welcome aboard, Security!', lastMessageAt: now,
      ),
    ]);
  }

  static void _seedMessages() {
    final now = DateTime.now();
    DateTime mins(int m) => now.subtract(Duration(minutes: m));
    _messages.addAll([
      ChatMessage(
        id: 'msg_seed1', roomId: 'room_general', sender: 'HOM System',
        text: 'Welcome to HOM Chat. Department heads and management can post '
            'announcements here — everyone reads.', createdAt: mins(5),
        readBy: const ['HOM System'],
      ),
      ChatMessage(
        id: 'msg_seed2', roomId: 'room_frontdesk', sender: 'HOM System',
        text: 'This channel is for Front Desk & Concierge only.',
        createdAt: mins(4), readBy: const ['HOM System'],
      ),
      ChatMessage(
        id: 'msg_seed3', roomId: 'room_housekeeping', sender: 'HOM System',
        text: 'This channel is for Housekeeping & Laundry only.',
        createdAt: mins(3), readBy: const ['HOM System'],
      ),
      ChatMessage(
        id: 'msg_seed4', roomId: 'room_engineering', sender: 'HOM System',
        text: 'This channel is for Engineering & Power only.',
        createdAt: mins(2), readBy: const ['HOM System'],
      ),
      ChatMessage(
        id: 'msg_seed5', roomId: 'room_fnb', sender: 'HOM System',
        text: 'This channel is for Kitchen, Bar & Banqueting only.',
        createdAt: mins(1), readBy: const ['HOM System'],
      ),
      ChatMessage(
        id: 'msg_seed6', roomId: 'room_backoffice', sender: 'HOM System',
        text: 'This channel is for Accounts, Procurement & HR only.',
        createdAt: mins(1), readBy: const ['HOM System'],
      ),
      ChatMessage(
        id: 'msg_seed7', roomId: 'room_security', sender: 'HOM System',
        text: 'This channel is for Security & HSE only.',
        createdAt: mins(1), readBy: const ['HOM System'],
      ),
    ]);
  }

  // ===================== ID GENS =====================

  static String genRoomId() => 'room_${DateTime.now().millisecondsSinceEpoch}';
  static String genMessageId() => 'msg_${DateTime.now().millisecondsSinceEpoch}';

  // ===================== ROOMS =====================

  static List<ChatRoom> get rooms => List.unmodifiable(_rooms);
  static ChatRoom? roomById(String id) {
    try { return _rooms.firstWhere((r) => r.id == id); } catch (_) { return null; }
  }

  static Future<void> addRoom(ChatRoom room) async {
    _rooms.insert(0, room);
    await _save();
  }

  static Future<void> updateRoom(String id, ChatRoom updated) async {
    final i = _rooms.indexWhere((r) => r.id == id);
    if (i >= 0) { _rooms[i] = updated; await _save(); }
  }

  static Future<void> removeRoom(String id) async {
    _rooms.removeWhere((r) => r.id == id);
    _messages.removeWhere((m) => m.roomId == id);
    await _save();
  }

  // ===================== MESSAGES =====================

  static List<ChatMessage> get messages => List.unmodifiable(_messages);

  static List<ChatMessage> messagesFor(String roomId) {
    final out = _messages.where((m) => m.roomId == roomId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return out;
  }

  /// Send a message. The sender auto-marks their own message as read.
  static Future<void> sendMessage({
    required String roomId,
    required String sender,
    String senderId = '',
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    final m = ChatMessage(
      roomId: roomId, sender: sender, senderId: senderId, text: text.trim(),
      readBy: [senderId.isEmpty ? sender : senderId],
    );
    _messages.add(m);
    final i = _rooms.indexWhere((r) => r.id == roomId);
    if (i >= 0) {
      final r = _rooms[i];
      _rooms[i] = ChatRoom(
        id: r.id, name: r.name, kind: r.kind,
        departments: r.departments, members: r.members,
        lastMessage: m.text, lastMessageAt: m.createdAt, createdAt: r.createdAt,
      );
    }
    await _save();
  }

  /// Mark every message in [roomId] as read by [who] (userId or staff name).
  static Future<void> markRead(String roomId, String who) async {
    var touched = false;
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      if (m.roomId == roomId && !m.isReadBy(who)) {
        _messages[i] = ChatMessage(
          id: m.id, roomId: m.roomId, sender: m.sender, senderId: m.senderId,
          text: m.text, createdAt: m.createdAt, readBy: [...m.readBy, who],
        );
        touched = true;
      }
    }
    if (touched) await _save();
  }

  /// Unread messages in [roomId] for [who].
  static int unreadIn(String roomId, String who) => _messages
      .where((m) => m.roomId == roomId && !m.isReadBy(who))
      .length;

  /// Total unread across every room the staff member [who] can see.
  static int totalUnread(String who) => _messages
      .where((m) => !m.isReadBy(who))
      .length;
}
