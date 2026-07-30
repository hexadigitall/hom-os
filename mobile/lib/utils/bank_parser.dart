import '../models/reconciliation.dart';

class BankParseResult {
  final List<BankTransaction> transactions;
  final List<String> errors;
  final int parsedCount;
  final int skippedCount;

  BankParseResult({
    required this.transactions,
    required this.errors,
    required this.parsedCount,
    required this.skippedCount,
  });
}

class BankStatementParser {
  static BankParseResult parseCsv(String raw, {String source = 'Bank Statement'}) {
    final lines = raw.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    final transactions = <BankTransaction>[];
    final errors = <String>[];
    int skipped = 0;

    if (lines.isEmpty) {
      return BankParseResult(transactions: [], errors: ['File is empty'], parsedCount: 0, skippedCount: 0);
    }

    final header = lines[0].toLowerCase();
    final dataLines = lines.skip(1).toList();

    _ColumnMap? cols;
    if (header.contains('date') || header.contains('transaction')) {
      cols = _detectColumns(header);

      if (cols != null && cols.date != null) {
        for (var i = 0; i < dataLines.length; i++) {
          final result = _parseRow(dataLines[i], cols, source, i + 2);
          if (result != null) {
            transactions.add(result);
          } else {
            skipped++;
          }
        }
        return BankParseResult(
          transactions: transactions,
          errors: errors,
          parsedCount: transactions.length,
          skippedCount: skipped,
        );
      }
    }

    errors.add('Could not detect CSV format. Ensure header row contains Date, Description/ Narration, and Amount columns.');
    return BankParseResult(transactions: [], errors: errors, parsedCount: 0, skippedCount: dataLines.length);
  }

  static _ColumnMap? _detectColumns(String header) {
    final cols = _ColumnMap();
    final parts = header.split(',').map((p) => p.trim().toLowerCase().replaceAll('"', '')).toList();
    for (var i = 0; i < parts.length; i++) {
      final p = parts[i];
      if (p.contains('date')) {
        cols.date = i;
      } else if (p.contains('narration') || p.contains('description') || p.contains('details') || p.contains('transaction remark')) {
        cols.description = i;
      } else if (p.contains('amount')) {
        cols.amount = i;
      } else if (p.contains('debit')) {
        cols.debit = i;
      } else if (p.contains('credit')) {
        cols.credit = i;
      } else if (p.contains('balance')) {
        cols.balance = i;
      } else if (p.contains('reference') || p.contains('ref') && !p.contains('trans ref')) {
        cols.reference = i;
      } else if (p.contains('trans ref') || p.contains('transaction ref') || p.contains('tran id')) {
        cols.reference = i;
      }
    }
    if (cols.date == null || (cols.amount == null && cols.debit == null && cols.credit == null)) {
      return null;
    }
    return cols;
  }

  static BankTransaction? _parseRow(String line, _ColumnMap cols, String source, int lineNum) {
    try {
      final parts = _splitCsvLine(line);
      if (parts.length <= cols.date!) return null;

      final dateStr = parts[cols.date!].trim().replaceAll('"', '');
      final date = _parseDate(dateStr);
      if (date == null) return null;

      final desc = cols.description != null && parts.length > cols.description!
          ? parts[cols.description!].trim().replaceAll('"', '') : '';

      double amount;
      String type;
      if (cols.amount != null && parts.length > cols.amount!) {
        final raw = parts[cols.amount!].trim().replaceAll('"', '').replaceAll(',', '');
        final val = double.tryParse(raw);
        if (val == null) return null;
        amount = val.abs();
        type = val >= 0 ? 'CR' : 'DR';
      } else {
        final debit = cols.debit != null && parts.length > cols.debit!
            ? double.tryParse(parts[cols.debit!].trim().replaceAll('"', '').replaceAll(',', '')) : null;
        final credit = cols.credit != null && parts.length > cols.credit!
            ? double.tryParse(parts[cols.credit!].trim().replaceAll('"', '').replaceAll(',', '')) : null;
        if (debit == null && credit == null) return null;
        amount = (credit ?? debit)!;
        type = debit != null && debit > 0 ? 'DR' : 'CR';
      }

      final ref = cols.reference != null && parts.length > cols.reference!
          ? parts[cols.reference!].trim().replaceAll('"', '') : null;

      double? balance;
      if (cols.balance != null && parts.length > cols.balance!) {
        balance = double.tryParse(parts[cols.balance!].trim().replaceAll('"', '').replaceAll(',', ''));
      }

      return BankTransaction(
        id: _genId(),
        date: date,
        description: desc,
        amount: amount,
        reference: ref,
        balance: balance,
        source: source,
        type: type,
      );
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseDate(String s) {
    s = s.trim();
    try {
      final parts = s.split(RegExp(r'[/\-]'));
      if (parts.length != 3) return null;
      final y = int.tryParse(parts[2]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[0]);
      if (y == null || m == null || d == null) return null;
      final year = y < 100 ? y + 2000 : y;
      return DateTime(year, m, d);
    } catch (_) {
      return null;
    }
  }

  static List<String> _splitCsvLine(String line) {
    final result = <String>[];
    var current = '';
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(current);
        current = '';
      } else {
        current += c;
      }
    }
    result.add(current);
    return result;
  }

  static int _idCounter = 0;
  static String _genId() => 'bt_${DateTime.now().millisecondsSinceEpoch}_${++_idCounter}';
}

class _ColumnMap {
  int? date;
  int? description;
  int? amount;
  int? debit;
  int? credit;
  int? balance;
  int? reference;
}
