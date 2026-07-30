import 'package:flutter/material.dart';

enum FuelCategory { power, kitchen }

enum FuelType {
  diesel(
    'Diesel (AGO)',
    Icons.local_gas_station_rounded,
    FuelCategory.power,
    'Liters',
    'Gen Hours',
    'L/hr',
  ),
  petrol(
    'Petrol (PMS)',
    Icons.oil_barrel_rounded,
    FuelCategory.power,
    'Liters',
    'Gen Hours',
    'L/hr',
  ),
  grid(
    'Grid Electricity',
    Icons.bolt_rounded,
    FuelCategory.power,
    'kWh',
    'Hours',
    '₦/kWh',
  ),
  lpg(
    'LPG (Gas)',
    Icons.local_fire_department_rounded,
    FuelCategory.kitchen,
    'kg',
    'Cooking Hours',
    'kg/hr',
  ),
  charcoal(
    'Charcoal',
    Icons.whatshot_rounded,
    FuelCategory.kitchen,
    'kg',
    null,
    null,
  );

  final String displayName;
  final IconData icon;
  final FuelCategory category;
  final String unit;
  final String? usageLabel;
  final String? efficiencyUnit;

  const FuelType(
    this.displayName,
    this.icon,
    this.category,
    this.unit,
    this.usageLabel,
    this.efficiencyUnit,
  );

  bool get hasTheftDetection =>
      this == FuelType.diesel || this == FuelType.petrol;

  double? theftThreshold(double usageHours, double quantity) {
    if (!hasTheftDetection || usageHours <= 0) return null;
    final rate = quantity / usageHours;
    // Diesel generators should consume ~8-12 L/hr; anything below 8 is suspicious
    if (rate < 8) return rate;
    return null;
  }
}

class FuelLog {
  final String id;
  final DateTime date;
  final FuelType fuelType;
  double quantity;
  double cost;
  String supplier;
  double? usageHours;
  String note;

  FuelLog({
    required this.id,
    required this.date,
    required this.fuelType,
    required this.quantity,
    required this.cost,
    this.supplier = '',
    this.usageHours,
    this.note = '',
  });

  double? get efficiencyRate =>
      usageHours != null && usageHours! > 0 ? quantity / usageHours! : null;

  double? get theftAlertRate =>
      fuelType.theftThreshold(usageHours ?? 0, quantity);

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String(),
    'fuelType': fuelType.name, 'quantity': quantity,
    'cost': cost, 'supplier': supplier,
    'usageHours': usageHours, 'note': note,
  };

  factory FuelLog.fromJson(Map<String, dynamic> json) => FuelLog(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    fuelType: FuelType.values.byName(json['fuelType'] as String),
    quantity: (json['quantity'] as num).toDouble(),
    cost: (json['cost'] as num).toDouble(),
    supplier: json['supplier'] as String? ?? '',
    usageHours: (json['usageHours'] as num?)?.toDouble(),
    note: json['note'] as String? ?? '',
  );
}
