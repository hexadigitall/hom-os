import 'package:flutter/material.dart';
import 'role.dart';

enum ExpenditureCategory {
  foodBeverage('Food & Beverage', Icons.restaurant, 'F&B'),
  logistics('Logistics / Transport', Icons.local_shipping, 'LOG'),
  toiletries('Toiletries & Amenities', Icons.cleaning_services, 'TOL'),
  laundry('Laundry & Linen', Icons.local_laundry_service, 'LND'),
  utilities('Utilities (Power/Water)', Icons.bolt, 'UTL'),
  maintenance('Maintenance & Repairs', Icons.build, 'MNT'),
  procurement('Procurement & Stock', Icons.receipt_long, 'PRC'),
  marketing('Marketing & Advertising', Icons.campaign, 'MKT'),
  administrative('Administrative', Icons.description, 'ADM'),
  other('Other', Icons.more_horiz, 'OTH');

  final String displayName;
  final IconData icon;
  final String code;

  const ExpenditureCategory(this.displayName, this.icon, this.code);

  static ExpenditureCategory fromString(String s) {
    final lower = s.toLowerCase().replaceAll(RegExp(r'[\s/&-]'), '');
    for (final c in ExpenditureCategory.values) {
      if (c.code.toLowerCase() == lower) return c;
      // Legacy Hive records store the Dart enum name (e.g. `procurement`);
      // the web app stores display labels (e.g. `Procurement`, `F&B`).
      if (c.name.toLowerCase() == lower) return c;
      if (c.displayName.toLowerCase().replaceAll(RegExp(r'[\s/&-]'), '') == lower) return c;
    }
    return ExpenditureCategory.other;
  }

  /// Stable label shared with the web app (`EXPENSE_CATEGORIES`).
  static String toWebLabel(ExpenditureCategory c) {
    switch (c) {
      case ExpenditureCategory.foodBeverage:
        return 'F&B';
      case ExpenditureCategory.logistics:
        return 'Logistics / Transport';
      case ExpenditureCategory.toiletries:
        return 'Toiletries & Amenities';
      case ExpenditureCategory.laundry:
        return 'Laundry & Linen';
      case ExpenditureCategory.utilities:
        return 'Utilities (Power/Water)';
      case ExpenditureCategory.maintenance:
        return 'Maintenance & Repairs';
      case ExpenditureCategory.procurement:
        return 'Procurement';
      case ExpenditureCategory.marketing:
        return 'Marketing & Advertising';
      case ExpenditureCategory.administrative:
        return 'Administrative';
      case ExpenditureCategory.other:
        return 'Other';
    }
  }

  static List<ExpenditureCategory> get all => values;
}

class ExpenditureRecord {
  final String id;
  final DateTime date;
  final ExpenditureCategory category;
  final String subcategory;
  final String description;
  final double amount;
  final String vendor;
  final String paymentMethod;
  final String receiptRef;
  final String notes;
  final Department? department;
  final DateTime createdAt;

  ExpenditureRecord({
    required this.id,
    required this.date,
    required this.category,
    this.subcategory = '',
    this.description = '',
    required this.amount,
    this.vendor = '',
    this.paymentMethod = '',
    this.receiptRef = '',
    this.notes = '',
    this.department,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ExpenditureRecord copyWith({
    String? id, DateTime? date, ExpenditureCategory? category,
    String? subcategory, String? description, double? amount,
    String? vendor, String? paymentMethod, String? receiptRef, String? notes,
  }) => ExpenditureRecord(
    id: id ?? this.id, date: date ?? this.date, category: category ?? this.category,
    subcategory: subcategory ?? this.subcategory, description: description ?? this.description,
    amount: amount ?? this.amount, vendor: vendor ?? this.vendor,
    paymentMethod: paymentMethod ?? this.paymentMethod, receiptRef: receiptRef ?? this.receiptRef,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'category': ExpenditureCategory.toWebLabel(category),
        'subcategory': subcategory,
        'description': description,
        'amount': amount,
        'vendor': vendor,
        'paymentMethod': paymentMethod,
        'receiptRef': receiptRef,
        'notes': notes,
        'department': department?.name,
        'departments': department != null ? [department!.name] : <String>[],
      };

  static Department? _parseDepartment(Map<String, dynamic> j) {
    final deps = j['departments'];
    if (deps is List && deps.isNotEmpty && deps.first is String) {
      return Department.values.byName(deps.first as String);
    }
    final single = j['department'];
    return single is String ? Department.values.byName(single) : null;
  }

  factory ExpenditureRecord.fromJson(Map<String, dynamic> j) =>
      ExpenditureRecord(
        id: j['id'],
        date: DateTime.parse(j['date']),
        category: ExpenditureCategory.fromString(j['category'] ?? ''),
        subcategory: j['subcategory'] ?? '',
        description: j['description'] ?? '',
        amount: (j['amount'] as num).toDouble(),
        vendor: j['vendor'] ?? '',
        paymentMethod: j['paymentMethod'] ?? '',
        receiptRef: j['receiptRef'] ?? '',
        notes: j['notes'] ?? '',
        department: _parseDepartment(j),
      );
}

class ReportPeriod {
  final String label;
  final DateTime start;
  final DateTime end;
  final ReportGranularity granularity;

  const ReportPeriod({
    required this.label,
    required this.start,
    required this.end,
    required this.granularity,
  });
}

enum ReportGranularity { weekly, monthly, quarterly, yearly }

class CategoryReport {
  final ExpenditureCategory category;
  final double total;
  final double percentage;
  final List<ExpenditureRecord> records;

  const CategoryReport({
    required this.category,
    required this.total,
    required this.percentage,
    required this.records,
  });
}

class Report {
  final ReportPeriod period;
  final double grandTotal;
  final List<CategoryReport> categories;
  final List<ExpenditureRecord> allRecords;
  final Map<String, double> subcategoryTotals;
  final int recordCount;

  const Report({
    required this.period,
    required this.grandTotal,
    required this.categories,
    required this.allRecords,
    required this.subcategoryTotals,
    required this.recordCount,
  });
}
