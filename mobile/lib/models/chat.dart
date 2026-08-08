// ──────────────────────────────────────────────────────────────
// INTERNAL DEPARTMENT CHAT
// Channels (department-scoped) · #hotel-general broadcast · 1:1 DMs
// Offline-first, flat collections under hotels/{hotelId}/.
// Read receipts via per-message readBy (staff user ids / names).
// ──────────────────────────────────────────────────────────────

import 'safe_enum.dart';

enum ChatRoomKind { channel, general, dm }

extension ChatRoomKindLabel on ChatRoomKind {
  String get label => switch (this) {
        ChatRoomKind.channel => 'Channel',
        ChatRoomKind.general => 'Hotel General',
        ChatRoomKind.dm => 'Direct Message',
      };
}

/// A chat conversation.
///
/// * `channel` — department-scoped room (visible to staff whose scope
///   intersects [departments]).
/// * `general` — hotel-wide broadcast: read by all staff, write requires the
///   `manageChat` permission (management / department heads).
/// * `dm` — private 1:1, visible only to the staff listed in [members].
class ChatRoom {
  String id;
  String name; // 'Hotel General', 'Front Desk', …
  ChatRoomKind kind;
  List<String> departments; // department scope for channels; empty = everyone
  List<String> members; // staff ids/names for DMs; empty = whole scope
  String lastMessage; // preview text
  DateTime lastMessageAt;
  DateTime createdAt;

  ChatRoom({
    String? id,
    required this.name,
    this.kind = ChatRoomKind.channel,
    List<String>? departments,
    List<String>? members,
    this.lastMessage = '',
    DateTime? lastMessageAt,
    DateTime? createdAt,
  })  : id = id ?? 'room_${DateTime.now().microsecondsSinceEpoch}',
        departments = departments ?? [],
        members = members ?? [],
        lastMessageAt = lastMessageAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  bool get isGeneral => kind == ChatRoomKind.general;
  bool get isDirect => kind == ChatRoomKind.dm;

  /// Whether [who] (a userId or staff name) is part of this room.
  bool includes(String who) =>
      members.isEmpty || members.contains(who);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'departments': departments,
        'members': members,
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChatRoom.fromJson(Map<String, dynamic> j) => ChatRoom(
        id: j['id'],
        name: j['name'] ?? '',
        kind: safeEnum(j['kind'], ChatRoomKind.values, ChatRoomKind.channel),
        departments: (j['departments'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        members: (j['members'] as List?)?.map((e) => e.toString()).toList() ??
            [],
        lastMessage: j['lastMessage'] ?? '',
        lastMessageAt:
            DateTime.tryParse(j['lastMessageAt'] ?? '') ?? DateTime.now(),
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );
}

/// A single chat message. `readBy` holds the staff ids/names that have read it
/// (the sender is always included) — that's the read-receipt model.
class ChatMessage {
  String id;
  String roomId;
  String sender; // display name
  String senderId; // user id (may be empty for offline-created DMs)
  String text;
  DateTime createdAt;
  List<String> readBy;

  ChatMessage({
    String? id,
    required this.roomId,
    required this.sender,
    this.senderId = '',
    required this.text,
    DateTime? createdAt,
    List<String>? readBy,
  })  : id = id ?? 'msg_${DateTime.now().microsecondsSinceEpoch}',
        createdAt = createdAt ?? DateTime.now(),
        readBy = readBy ?? [];

  bool get isMine => senderId.isNotEmpty;

  bool isReadBy(String who) => readBy.contains(who);

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'sender': sender,
        'senderId': senderId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'readBy': readBy,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'],
        roomId: j['roomId'] ?? '',
        sender: j['sender'] ?? '',
        senderId: j['senderId'] ?? '',
        text: j['text'] ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        readBy: (j['readBy'] as List?)?.map((e) => e.toString()).toList() ??
            [],
      );
}
