import 'package:flutter/material.dart';
import 'package:hom_mobile/utils/theme.dart';

enum BillingCycle {
  monthly('Monthly', 1),
  quarterly('Quarterly', 3),
  annual('Annual', 12);

  final String label;
  final int months;
  const BillingCycle(this.label, this.months);
  String get jsonName => name;
  static BillingCycle fromJson(String s) => BillingCycle.values.byName(s);
}

enum SubscriptionStatus {
  active('Active', AppColors.green),
  expiring('Expiring Soon', AppColors.orange),
  expired('Expired', AppColors.red),
  cancelled('Cancelled', AppColors.grey500);

  final String label;
  final Color color;
  const SubscriptionStatus(this.label, this.color);
  String get jsonName => name;
  static SubscriptionStatus fromJson(String s) => SubscriptionStatus.values.byName(s);
}

class Subscription {
  final String id;
  String name;
  String provider;
  String category;
  double amount;
  BillingCycle billingCycle;
  DateTime startDate;
  SubscriptionStatus status;
  String contactInfo;
  String notes;
  bool autoLogExpenditure;

  Subscription({
    required this.id,
    required this.name,
    required this.provider,
    this.category = '',
    required this.amount,
    required this.billingCycle,
    required this.startDate,
    this.status = SubscriptionStatus.active,
    this.contactInfo = '',
    this.notes = '',
    this.autoLogExpenditure = true,
  });

  DateTime get renewalDate {
    final monthsSince = DateTime.now().difference(startDate).inDays ~/ 30;
    final cyclesSince = (monthsSince / billingCycle.months).ceil();
    return DateTime(
      startDate.year,
      startDate.month + cyclesSince * billingCycle.months,
      startDate.day,
    );
  }

  int get daysUntilRenewal => DateTime.now().difference(renewalDate).inDays.abs();

  double get monthlyCost => billingCycle == BillingCycle.monthly
      ? amount
      : billingCycle == BillingCycle.quarterly
          ? amount / 3
          : amount / 12;
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'provider': provider, 'category': category,
    'amount': amount, 'billingCycle': billingCycle.name,
    'startDate': startDate.toIso8601String(), 'status': status.name,
    'contactInfo': contactInfo, 'notes': notes,
    'autoLogExpenditure': autoLogExpenditure,
  };
  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
    id: j['id'], name: j['name'], provider: j['provider'],
    category: j['category'] ?? '', amount: (j['amount'] as num).toDouble(),
    billingCycle: BillingCycle.values.byName(j['billingCycle']),
    startDate: DateTime.parse(j['startDate']),
    status: SubscriptionStatus.values.byName(j['status'] ?? 'active'),
    contactInfo: j['contactInfo'] ?? '', notes: j['notes'] ?? '',
    autoLogExpenditure: j['autoLogExpenditure'] ?? true,
  );
}
