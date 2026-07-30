import 'package:intl/intl.dart';
import '../../models/expenditure.dart';
import '../../data/expenditure_store.dart';

class ReportEngine {
  static List<Report> generate({
    required ReportGranularity granularity,
    DateTime? customStart,
    DateTime? customEnd,
    ExpenditureCategory? categoryFilter,
  }) {
    final now = DateTime.now();
    final periods = _buildPeriods(granularity, now, customStart, customEnd);
    return periods.map((p) => _buildReport(p, categoryFilter)).toList();
  }

  static Report generateSingle({
    required ReportPeriod period,
    ExpenditureCategory? categoryFilter,
  }) {
    return _buildReport(period, categoryFilter);
  }

  static List<ReportPeriod> _buildPeriods(ReportGranularity g, DateTime now, DateTime? cs, DateTime? ce) {
    if (cs != null && ce != null) {
      return [ReportPeriod(label: '${_fmt(cs)} - ${_fmt(ce)}', start: cs, end: ce, granularity: g)];
    }

    switch (g) {
      case ReportGranularity.weekly:
        return _recentWeeks(now, 12);
      case ReportGranularity.monthly:
        return _recentMonths(now, 6);
      case ReportGranularity.quarterly:
        return _recentQuarters(now, 4);
      case ReportGranularity.yearly:
        return _recentYears(now, 3);
    }
  }

  static List<ReportPeriod> _recentWeeks(DateTime now, int count) {
    final result = <ReportPeriod>[];
    final sunday = now.subtract(Duration(days: now.weekday % 7));
    for (int i = 0; i < count; i++) {
      final end = sunday.subtract(Duration(days: i * 7));
      final start = end.subtract(const Duration(days: 6));
      final weekNum = DateFormat('w').format(start);
      result.add(ReportPeriod(
        label: 'Week $weekNum (${_fmt(start)} - ${_fmt(end)})',
        start: DateTime(start.year, start.month, start.day),
        end: DateTime(end.year, end.month, end.day, 23, 59, 59),
        granularity: ReportGranularity.weekly,
      ));
    }
    return result;
  }

  static List<ReportPeriod> _recentMonths(DateTime now, int count) {
    final result = <ReportPeriod>[];
    for (int i = 0; i < count; i++) {
      final m = DateTime(now.year, now.month - i, 1);
      final end = DateTime(m.year, m.month + 1, 0, 23, 59, 59);
      result.add(ReportPeriod(
        label: DateFormat('MMMM yyyy').format(m),
        start: m,
        end: end,
        granularity: ReportGranularity.monthly,
      ));
    }
    return result;
  }

  static List<ReportPeriod> _recentQuarters(DateTime now, int count) {
    final result = <ReportPeriod>[];
    for (int i = 0; i < count; i++) {
      final qStart = DateTime(now.year, ((now.month - 1 - i * 3) ~/ 3) * 3 + 1, 1);
      if (qStart.month < 1) continue;
      final qEnd = DateTime(qStart.year, qStart.month + 3, 0, 23, 59, 59);
      final qNum = (qStart.month ~/ 3) + 1;
      result.add(ReportPeriod(
        label: 'Q$qNum ${qStart.year}',
        start: qStart,
        end: qEnd,
        granularity: ReportGranularity.quarterly,
      ));
    }
    return result;
  }

  static List<ReportPeriod> _recentYears(DateTime now, int count) {
    final result = <ReportPeriod>[];
    for (int i = 0; i < count; i++) {
      final y = now.year - i;
      result.add(ReportPeriod(
        label: '$y',
        start: DateTime(y, 1, 1),
        end: DateTime(y, 12, 31, 23, 59, 59),
        granularity: ReportGranularity.yearly,
      ));
    }
    return result;
  }

  static Report _buildReport(ReportPeriod period, ExpenditureCategory? catFilter) {
    final records = ExpenditureStore.filterByDateRange(period.start, period.end);
    final filtered = catFilter != null ? records.where((r) => r.category == catFilter).toList() : records;

    final totals = ExpenditureStore.totalsByCategory(filtered);
    final grandTotal = totals.values.fold(0.0, (a, b) => a + b);

    final subcats = <String, double>{};
    for (final r in filtered) {
      if (r.subcategory.isNotEmpty) {
        subcats[r.subcategory] = (subcats[r.subcategory] ?? 0) + r.amount;
      }
    }

    final categories = ExpenditureCategory.values
        .where((c) => (totals[c] ?? 0) > 0)
        .map((c) => CategoryReport(
              category: c,
              total: totals[c] ?? 0,
              percentage: grandTotal > 0 ? ((totals[c] ?? 0) / grandTotal * 100) : 0,
              records: filtered.where((r) => r.category == c).toList(),
            ))
        .toList();

    return Report(
      period: period,
      grandTotal: grandTotal,
      categories: categories,
      allRecords: filtered,
      subcategoryTotals: subcats,
      recordCount: filtered.length,
    );
  }

  static String _fmt(DateTime d) => DateFormat('dd/MM').format(d);

  static String formatCurrency(double amount) {
    final f = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    return f.format(amount);
  }
}
