import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/expenditure.dart';
import 'report_engine.dart';
import '../../utils/theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportGranularity _granularity = ReportGranularity.monthly;
  ExpenditureCategory? _catFilter;
  List<Report> _reports = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    setState(() {
      _loading = true;
      _reports = ReportEngine.generate(granularity: _granularity, categoryFilter: _catFilter);
      _loading = false;
    });
  }

  void _exportPdf(Report report) async {
    final pdf = await _buildPdf(report);
    final dir = await getTemporaryDirectory();
    final periodStr = report.period.label.replaceAll(RegExp(r'[^\w\d]'), '_');
    final file = File('${dir.path}/HOM_Report_$periodStr.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'HOM Expenditure Report - ${report.period.label}');
  }

  void _previewPdf(Report report) async {
    final pdf = await _buildPdf(report);
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  Future<pw.Document> _buildPdf(Report report) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('HOM - Hospitality Operations Manager', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('Expenditure Report', style: pw.TextStyle(fontSize: 14)),
            ]),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: PdfColors.green50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Period: ${report.period.label}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text('Records: ${report.recordCount}', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Grand Total: ${ReportEngine.formatCurrency(report.grandTotal)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ]),
          ),
          pw.SizedBox(height: 16),
          pw.Header(level: 1, text: 'Category Breakdown'),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headers: ['Category', 'Total (₦)', '% of Total', 'Records'],
            data: report.categories.map((c) => [
              c.category.displayName,
              c.total.toStringAsFixed(0),
              c.percentage.toStringAsFixed(1),
              '${c.records.length}',
            ]).toList(),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1),
            },
          ),
          pw.SizedBox(height: 8),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Text('Total: ${ReportEngine.formatCurrency(report.grandTotal)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          ]),
          if (report.allRecords.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Header(level: 1, text: 'Transaction Details'),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headers: ['Date', 'Category', 'Amount', 'Vendor', 'Description'],
              data: report.allRecords.map((r) => [
                DateFormat('dd/MM/yy').format(r.date),
                r.category.code,
                r.amount.toStringAsFixed(0),
                r.vendor,
                r.description,
              ]).toList(),
            ),
          ],
          pw.SizedBox(height: 20),
          pw.Text('Generated by HOM - ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}', style: pw.TextStyle(color: PdfColors.grey500, fontSize: 8)),
        ],
      ),
    );
    return pdf;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.white,
          child: Column(children: [
            Row(children: [
              Expanded(
                child: _segmentedBtn([
                  ('Weekly', ReportGranularity.weekly),
                  ('Monthly', ReportGranularity.monthly),
                  ('Quarterly', ReportGranularity.quarterly),
                  ('Yearly', ReportGranularity.yearly),
                ]),
              ),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _catChip(null, 'All Categories'),
                  ...ExpenditureCategory.values.map((c) => _catChip(c, c.displayName)),
                ],
              ),
            ),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _reports.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.bar_chart_rounded, size: 64, color: AppColors.grey300),
                        const SizedBox(height: 12),
                        Text('No data for selected period', style: TextStyle(color: AppColors.grey500)),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _reports.length,
                      itemBuilder: (ctx, i) => _buildReportCard(_reports[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _segmentedBtn(List<(String, ReportGranularity)> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: items.map((item) {
          final (label, value) = item;
          final active = _granularity == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _granularity = value; _generate(); }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? AppColors.white : AppColors.grey700,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _catChip(ExpenditureCategory? cat, String label) {
    final active = _catFilter == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
        selected: active,
        onSelected: (_) => setState(() { _catFilter = cat; _generate(); }),
        visualDensity: VisualDensity.compact,
        selectedColor: AppColors.primary.withValues(alpha: 0.1),
        backgroundColor: AppColors.grey100,
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Text(report.period.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'pdf') _exportPdf(report);
                if (v == 'preview') _previewPdf(report);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'preview', child: Row(children: [Icon(Icons.download_rounded, size: 18), SizedBox(width: 8), Flexible(child: Text('Preview / Print', style: TextStyle(fontSize: 13)))])),
                PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.share_rounded, size: 18), SizedBox(width: 8), Flexible(child: Text('Share PDF', style: TextStyle(fontSize: 13)))])),
              ],
            ),
          ]),
          const SizedBox(height: 4),
          Text('${report.recordCount} transactions', style: TextStyle(color: AppColors.grey600, fontSize: 12)),
          const SizedBox(height: 8),
          Text(ReportEngine.formatCurrency(report.grandTotal), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.primary)),
          const SizedBox(height: 12),
          ...report.categories.take(5).map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              SizedBox(width: 24, child: Icon(c.category.icon, size: 16, color: AppColors.primary)),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: Text(c.category.displayName, style: const TextStyle(fontSize: 12))),
              Expanded(flex: 2, child: Text(ReportEngine.formatCurrency(c.total), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              SizedBox(width: 36, child: Text('${c.percentage.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, color: AppColors.grey500), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
            ]),
          )),
          if (report.categories.length > 5)
            Text('...and ${report.categories.length - 5} more categories', style: TextStyle(color: AppColors.grey500, fontSize: 11)),
        ]),
      ),
    );
  }
}
