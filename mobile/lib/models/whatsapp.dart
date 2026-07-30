enum ContactEntityType { booking, staff, vendor, subscription, compliance, other }

class WhatsAppContact {
  String id;
  String name;
  String phone;
  ContactEntityType entityType;
  String entityId;
  String notes;

  WhatsAppContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.entityType,
    this.entityId = '',
    this.notes = '',
  });

  String get formattedPhone {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('0')) return '+234${cleaned.substring(1)}';
    if (cleaned.startsWith('+')) return cleaned;
    return '+234$cleaned';
  }
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'phone': phone, 'entityType': entityType.name,
    'entityId': entityId, 'notes': notes,
  };
  factory WhatsAppContact.fromJson(Map<String, dynamic> j) => WhatsAppContact(
    id: j['id'], name: j['name'], phone: j['phone'],
    entityType: ContactEntityType.values.byName(j['entityType']),
    entityId: j['entityId'] ?? '', notes: j['notes'] ?? '',
  );
}

class WhatsAppTemplate {
  final String id;
  final String name;
  final String message;
  final ContactEntityType? entityType;

  const WhatsAppTemplate({
    required this.id,
    required this.name,
    required this.message,
    this.entityType,
  });
}

class WhatsAppMessage {
  final String id;
  final String contactId;
  final String contactName;
  final String phone;
  final String message;
  final DateTime sentAt;
  MessageStatus status;

  WhatsAppMessage({
    required this.id,
    required this.contactId,
    required this.contactName,
    required this.phone,
    required this.message,
    required this.sentAt,
    this.status = MessageStatus.sent,
  });
  Map<String, dynamic> toJson() => {
    'id': id, 'contactId': contactId, 'contactName': contactName,
    'phone': phone, 'message': message, 'sentAt': sentAt.toIso8601String(),
    'status': status.name,
  };
  factory WhatsAppMessage.fromJson(Map<String, dynamic> j) => WhatsAppMessage(
    id: j['id'], contactId: j['contactId'], contactName: j['contactName'],
    phone: j['phone'], message: j['message'],
    sentAt: DateTime.parse(j['sentAt']),
    status: MessageStatus.values.byName(j['status'] ?? 'sent'),
  );
}

enum MessageStatus { sent, delivered, failed }
