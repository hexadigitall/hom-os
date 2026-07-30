import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/file_parser.dart';
import '../../data/expenditure_store.dart';
import 'format_guide_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _loading = false;
  String? _status;
  Color _statusColor = Colors.grey;

  Future<void> _pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _loading = true;
      _status = 'Parsing ${result.files.single.name}...';
      _statusColor = Colors.blue;
    });

    try {
      final file = result.files.single;
      final path = file.path;
      if (path == null) throw Exception('Could not access file');

      final parsed = await FileParser.parseFile(path, file.name);

      if (parsed.records.isEmpty) {
        setState(() {
          _loading = false;
          _status = 'No valid records found in the file.\n${parsed.errors.join('\n')}';
          _statusColor = Colors.red;
        });
        return;
      }

      ExpenditureStore.addAll(parsed.records);

      setState(() {
        _loading = false;
        _status = '✓ Imported ${parsed.records.length} records from ${parsed.totalRows} rows.'
            '${parsed.errors.isNotEmpty ? '\n${parsed.errors.length} warnings:\n${parsed.errors.take(5).join('\n')}${parsed.errors.length > 5 ? '\n...and ${parsed.errors.length - 5} more' : ''}' : ''}';
        _statusColor = Colors.green;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _status = 'Error: $e';
        _statusColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Expenditure')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Icon(Icons.cloud_upload_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('Upload Expenditure Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Accepted formats: CSV, XLSX', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 8),
              Text('See Format Guide for the required column structure', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _pickAndParse,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.file_upload_rounded),
                  label: Text(_loading ? 'Parsing...' : 'Select CSV / XLSX File'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormatGuideScreen())),
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('View Format Guide'),
              ),
            ]),
          ),
        ),
        if (_status != null)
          Card(
            color: _statusColor.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(_statusColor == Colors.green ? Icons.check_circle : _statusColor == Colors.red ? Icons.error : Icons.info,
                    color: _statusColor, size: 20),
                const SizedBox(width: 12),
                Expanded(child: SelectableText(_status!, style: TextStyle(color: _statusColor, fontSize: 13, height: 1.4))),
              ]),
            ),
          ),
        const SizedBox(height: 16),
        Text('Current Records: ${ExpenditureStore.count}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        if (ExpenditureStore.count > 0)
          Text('Total: ${_fmt(ExpenditureStore.totalAll)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ]),
    );
  }

  String _fmt(double a) {
    return '₦${a.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }
}
