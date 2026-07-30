import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xl;
import '../models/expenditure.dart';
import '../data/expenditure_store.dart';

class FileParseResult {
  final List<ExpenditureRecord> records;
  final List<String> errors;
  final int totalRows;

  const FileParseResult({
    required this.records,
    required this.errors,
    required this.totalRows,
  });
}

class FileParser {
  static Future<FileParseResult> parseFile(String filePath, String fileName) async {
    final ext = fileName.split('.').last.toLowerCase();
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return ext == 'csv' ? _parseCsv(bytes) : _parseXlsx(bytes);
  }

  static FileParseResult _parseCsv(List<int> bytes) {
    final text = utf8.decode(bytes);
    final rows = const CsvToListConverter(eol: '\n').convert(text);
    return _processRows(rows);
  }

  static FileParseResult _parseXlsx(List<int> bytes) {
    final excel = xl.Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;
    final rows = sheet.rows.map((r) => r.map((c) => c?.value?.toString() ?? '').toList()).toList();
    return _processRows(rows);
  }

  static FileParseResult _processRows(List<List<dynamic>> rows) {
    if (rows.isEmpty) return const FileParseResult(records: [], errors: [], totalRows: 0);

    final errors = <String>[];
    final records = <ExpenditureRecord>[];

    int headerRow = 0;
    for (int i = 0; i < rows.length; i++) {
      final first = rows[i].isNotEmpty ? rows[i][0].toString().toLowerCase().trim() : '';
      if (first == 'date' || first == 'date (yyyy-mm-dd)') {
        headerRow = i;
        break;
      }
    }

    final dataRows = rows.sublist(headerRow + 1);

    for (int i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) continue;

      try {
        final record = _parseRow(row, i + headerRow + 2, errors);
        if (record != null) records.add(record);
      } catch (e) {
        errors.add('Row ${i + headerRow + 2}: $e');
      }
    }

    return FileParseResult(records: records, errors: errors, totalRows: dataRows.length);
  }

  static ExpenditureRecord? _parseRow(List<dynamic> row, int rowNum, List<String> errors) {
    String get(int idx) => idx < row.length ? row[idx].toString().trim() : '';

    final dateStr = get(0);
    final catStr = get(1);
    final subcat = get(2);
    final desc = get(3);
    final amtStr = get(4);
    final vendor = get(5);
    final payment = get(6);
    final receipt = get(7);
    final notes = get(8);

    if (dateStr.isEmpty) {
      errors.add('Row $rowNum: missing date, skipped');
      return null;
    }

    DateTime? date;
    try { date = DateTime.parse(dateStr); } catch (_) {
      final parts = dateStr.split(RegExp(r'[/\-.]'));
      if (parts.length == 3) {
        try { date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])); } catch (_) {}
      }
    }
    if (date == null) {
      errors.add('Row $rowNum: invalid date "$dateStr", skipped');
      return null;
    }

    final amount = double.tryParse(amtStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    if (amount <= 0) {
      errors.add('Row $rowNum: invalid or zero amount "$amtStr", skipped');
      return null;
    }

    final category = ExpenditureCategory.fromString(catStr);
    final id = ExpenditureStore.generateId();

    return ExpenditureRecord(
      id: id,
      date: date,
      category: category,
      subcategory: subcat,
      description: desc,
      amount: amount,
      vendor: vendor,
      paymentMethod: payment,
      receiptRef: receipt,
      notes: notes,
    );
  }
}
