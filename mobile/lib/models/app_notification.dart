import 'package:flutter/material.dart';

enum NotificationType {
  alarm,
  operational,
  deadline,
  system;

  String get label {
    switch (this) {
      case NotificationType.alarm: return 'Alarm';
      case NotificationType.operational: return 'Operational';
      case NotificationType.deadline: return 'Deadline';
      case NotificationType.system: return 'System';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.alarm: return Icons.warning_rounded;
      case NotificationType.operational: return Icons.sync_rounded;
      case NotificationType.deadline: return Icons.schedule_rounded;
      case NotificationType.system: return Icons.info_rounded;
    }
  }
}

enum Urgency { high, medium, low }

class AppNotification {
  final String id;
  final NotificationType type;
  final Urgency urgency;
  final String title;
  final String body;
  final DateTime timestamp;
  bool read;
  final String? actionRoute;
  final String? actionLabel;

  AppNotification({
    required this.id,
    required this.type,
    this.urgency = Urgency.medium,
    required this.title,
    required this.body,
    DateTime? timestamp,
    this.read = false,
    this.actionRoute,
    this.actionLabel,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type.name, 'urgency': urgency.name,
    'title': title, 'body': body, 'timestamp': timestamp.toIso8601String(),
    'read': read, 'actionRoute': actionRoute, 'actionLabel': actionLabel,
  };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'],
    type: NotificationType.values.byName(j['type']),
    urgency: Urgency.values.byName(j['urgency']),
    title: j['title'], body: j['body'],
    timestamp: DateTime.parse(j['timestamp']),
    read: j['read'] ?? false,
    actionRoute: j['actionRoute'], actionLabel: j['actionLabel'],
  );
}
