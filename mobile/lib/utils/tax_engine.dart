import '../models/compliance.dart';
import '../data/compliance_store.dart';

class TaxBreakdown {
  final double subtotal;
  final double vatRate;
  final double vatAmount;
  final double stateTaxRate;
  final double stateTaxAmount;
  final double serviceChargeRate;
  final double serviceChargeAmount;
  final double total;

  TaxBreakdown({
    required this.subtotal,
    required this.vatRate,
    required this.vatAmount,
    required this.stateTaxRate,
    required this.stateTaxAmount,
    required this.serviceChargeRate,
    required this.serviceChargeAmount,
    required this.total,
  });
}

class TaxEngine {
  static const double vatRate = 7.5;
  static const double serviceChargeRate = 10.0;

  static TaxBreakdown compute({
    required double subtotal,
    String? stateName,
    bool applyVat = true,
    bool applyServiceCharge = false,
  }) {
    // Find state tax config if state specified
    double stateTaxRate = 0;
    if (stateName != null) {
      final configs = ComplianceStore.stateTaxConfigs;
      for (final c in configs) {
        if (c.stateName.toLowerCase() == stateName.toLowerCase()) {
          stateTaxRate = c.rate;
          break;
        }
      }
    }

    final vatAmount = applyVat ? subtotal * (vatRate / 100) : 0.0;
    final stateTaxAmount = subtotal * (stateTaxRate / 100);
    final serviceChargeAmount = applyServiceCharge ? subtotal * (serviceChargeRate / 100) : 0.0;
    final total = subtotal + vatAmount + stateTaxAmount + serviceChargeAmount;

    return TaxBreakdown(
      subtotal: subtotal,
      vatRate: vatRate,
      vatAmount: vatAmount,
      stateTaxRate: stateTaxRate,
      stateTaxAmount: stateTaxAmount,
      serviceChargeRate: serviceChargeRate,
      serviceChargeAmount: serviceChargeAmount,
      total: total,
    );
  }

  static TaxBreakdown computeFromTotal({
    required double totalInclusive,
    String? stateName,
    bool applyVat = true,
    bool applyServiceCharge = false,
  }) {
    double stateTaxRate = 0;
    if (stateName != null) {
      final configs = ComplianceStore.stateTaxConfigs;
      for (final c in configs) {
        if (c.stateName.toLowerCase() == stateName.toLowerCase()) {
          stateTaxRate = c.rate;
          break;
        }
      }
    }

    final divisor = 1 +
        (applyVat ? vatRate / 100 : 0.0) +
        (stateTaxRate / 100) +
        (applyServiceCharge ? serviceChargeRate / 100 : 0.0);

    final subtotal = totalInclusive / divisor;
    final vatAmount = applyVat ? subtotal * (vatRate / 100) : 0.0;
    final stateTaxAmount = subtotal * (stateTaxRate / 100);
    final serviceChargeAmount = applyServiceCharge ? subtotal * (serviceChargeRate / 100) : 0.0;

    return TaxBreakdown(
      subtotal: subtotal,
      vatRate: vatRate,
      vatAmount: vatAmount,
      stateTaxRate: stateTaxRate,
      stateTaxAmount: stateTaxAmount,
      serviceChargeRate: serviceChargeRate,
      serviceChargeAmount: serviceChargeAmount,
      total: totalInclusive,
    );
  }

  static StateTaxReport generateReport({
    required String stateName,
    required double totalSales,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final configs = ComplianceStore.stateTaxConfigs;
    double rate = 0;
    for (final c in configs) {
      if (c.stateName.toLowerCase() == stateName.toLowerCase()) {
        rate = c.rate;
        break;
      }
    }
    final taxDue = totalSales * (rate / 100);
    return StateTaxReport(
      id: ComplianceStore.genId(),
      stateName: stateName,
      rate: rate,
      totalSales: totalSales,
      taxDue: taxDue,
      periodStart: periodStart,
      periodEnd: periodEnd,
      status: 'pending',
    );
  }
}
