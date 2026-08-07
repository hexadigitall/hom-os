import 'role.dart';
import 'safe_enum.dart';

enum ProcurementStatus { draft, approved, ordered, delivered, cancelled }
enum PayrollStatus { pending, paid, cancelled }

class ProcurementOrder {
  String id, vendorName, items;
  String? notes;
  double amount;
  ProcurementStatus status;
  DateTime orderDate;
  DateTime? deliveryDate;
  Department? department;

  ProcurementOrder({
    required this.id, required this.vendorName, required this.items,
    this.notes, required this.amount,
    this.status = ProcurementStatus.draft, DateTime? orderDate, this.deliveryDate,
    this.department,
  }) : orderDate = orderDate ?? DateTime.now();

  static Department? _parseDepartment(Map<String, dynamic> j) {
    final deps = j['departments'];
    if (deps is List && deps.isNotEmpty && deps.first is String) {
      return Department.values.byName(deps.first as String);
    }
    final single = j['department'];
    return single is String ? Department.values.byName(single) : null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vendorName': vendorName,
        'items': items,
        'notes': notes,
        'amount': amount,
        'status': status.name,
        'orderDate': orderDate.toIso8601String(),
        'deliveryDate': deliveryDate?.toIso8601String(),
        'department': department?.name,
        'departments': department != null ? [department!.name] : <String>[],
      };

  factory ProcurementOrder.fromJson(Map<String, dynamic> j) => ProcurementOrder(
        id: j['id'],
        vendorName: j['vendorName'],
        items: j['items'],
        notes: j['notes'],
        amount: (j['amount'] as num).toDouble(),
        status: safeEnum(j['status'], ProcurementStatus.values, ProcurementStatus.draft),
        orderDate: DateTime.parse(j['orderDate']),
        deliveryDate: j['deliveryDate'] != null
            ? DateTime.tryParse('${j['deliveryDate']}')
            : null,
        department: _parseDepartment(j),
      );
}

class PayrollRecord {
  String id, staffName, department;
  double basicSalary, allowances, deductions, payeTax, pensionContribution, netPay;
  PayrollStatus status;
  DateTime periodStart, periodEnd;
  DateTime? paidDate;

  PayrollRecord({
    required this.id, required this.staffName, this.department = '',
    this.basicSalary = 0, this.allowances = 0, this.deductions = 0,
    this.payeTax = 0, this.pensionContribution = 0, this.netPay = 0,
    this.status = PayrollStatus.pending,
    required this.periodStart, required this.periodEnd, this.paidDate,
  });

  double get grossPay => basicSalary + allowances;
  double get totalDeductions => deductions + payeTax + pensionContribution;

  Map<String, dynamic> toJson() => {
    'id': id, 'staffName': staffName, 'department': department,
    'basicSalary': basicSalary, 'allowances': allowances, 'deductions': deductions,
    'payeTax': payeTax, 'pensionContribution': pensionContribution, 'netPay': netPay,
    'status': status.name, 'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(), 'paidDate': paidDate?.toIso8601String(),
  };

  factory PayrollRecord.fromJson(Map<String, dynamic> j) => PayrollRecord(
    id: j['id'], staffName: j['staffName'], department: j['department'] ?? '',
    basicSalary: (j['basicSalary'] as num?)?.toDouble() ?? 0,
    allowances: (j['allowances'] as num?)?.toDouble() ?? 0,
    deductions: (j['deductions'] as num?)?.toDouble() ?? 0,
    payeTax: (j['payeTax'] as num?)?.toDouble() ?? 0,
    pensionContribution: (j['pensionContribution'] as num?)?.toDouble() ?? 0,
    netPay: (j['netPay'] as num?)?.toDouble() ?? 0,
    status: safeEnum(j['status'], PayrollStatus.values, PayrollStatus.pending),
    periodStart: DateTime.parse(j['periodStart']),
    periodEnd: DateTime.parse(j['periodEnd']),
    paidDate: j['paidDate'] != null ? DateTime.parse(j['paidDate']) : null,
  );
}

class TaxConfiguration {
  String id, name;
  double vatRate, citRate, lgaDevelopmentLevy, pensionEmployeeRate, pensionEmployerRate;
  String currencyCode, currencySymbol;
  bool active;

  TaxConfiguration({
    required this.id, this.name = 'Default',
    this.vatRate = 7.5, this.citRate = 30.0,
    this.lgaDevelopmentLevy = 1.0,
    this.pensionEmployeeRate = 8.0, this.pensionEmployerRate = 10.0,
    this.currencyCode = 'NGN', this.currencySymbol = '\u20A6',
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'vatRate': vatRate, 'citRate': citRate,
    'lgaDevelopmentLevy': lgaDevelopmentLevy,
    'pensionEmployeeRate': pensionEmployeeRate,
    'pensionEmployerRate': pensionEmployerRate,
    'currencyCode': currencyCode, 'currencySymbol': currencySymbol,
    'active': active,
  };

  factory TaxConfiguration.fromJson(Map<String, dynamic> j) => TaxConfiguration(
    id: j['id'], name: j['name'] ?? 'Default',
    vatRate: (j['vatRate'] as num?)?.toDouble() ?? 7.5,
    citRate: (j['citRate'] as num?)?.toDouble() ?? 30.0,
    lgaDevelopmentLevy: (j['lgaDevelopmentLevy'] as num?)?.toDouble() ?? 1.0,
    pensionEmployeeRate: (j['pensionEmployeeRate'] as num?)?.toDouble() ?? 8.0,
    pensionEmployerRate: (j['pensionEmployerRate'] as num?)?.toDouble() ?? 10.0,
    currencyCode: j['currencyCode'] ?? 'NGN',
    currencySymbol: j['currencySymbol'] ?? '\u20A6',
    active: j['active'] ?? true,
  );
}
