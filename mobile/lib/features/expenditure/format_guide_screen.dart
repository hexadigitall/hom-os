import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class FormatGuideScreen extends StatelessWidget {
  const FormatGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sectionStyle = TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primaryDark);
    final codeStyle = TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.grey800);
    final codePad = const EdgeInsets.all(12);

    return Scaffold(
      appBar: AppBar(title: const Text('File Format Guide', maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.description_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 10),
                Flexible(child: Text('HOM Expenditure Format Guide', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primaryDark), overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 12),
              Text(
                'Upload CSV (.csv) or Excel (.xlsx) files with expenditure data. '
                'Your file must have a header row with the columns below.',
                style: TextStyle(color: AppColors.grey700, height: 1.5),
              ),
            ]),
          ),
        ),

        const SizedBox(height: 16),
        Text('Required Columns', style: sectionStyle),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Table(
              columnWidths: const {0: FlexColumnWidth(1.6), 1: FlexColumnWidth(3), 2: FlexColumnWidth(2.5)},
              border: TableBorder.all(color: AppColors.grey200),
              children: [
                _headerRow('Column', 'Example', 'Notes'),
                _dataRow('Date', '2026-01-15', 'YYYY-MM-DD format'),
                _dataRow('Category', 'Food & Beverage', 'One from the category list'),
                _dataRow('Subcategory', 'Kitchen Supplies', 'Optional sub-category'),
                _dataRow('Description', 'Fresh veg purchase', 'Optional details'),
                _dataRow('Amount', '45000', 'Amount in Naira (numbers only)'),
                _dataRow('Vendor', 'FreshFarm Ltd', 'Optional supplier name'),
                _dataRow('Payment Method', 'Bank Transfer', 'Optional: Cash, Transfer, POS, Card'),
                _dataRow('Receipt Ref', 'REC-001', 'Optional receipt/invoice number'),
                _dataRow('Notes', 'Weekly market order', 'Optional notes'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        Text('Categories', style: sectionStyle),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(spacing: 8, runSpacing: 6, children: [
              _chip('Food & Beverage', Icons.restaurant),
              _chip('Logistics / Transport', Icons.local_shipping),
              _chip('Toiletries & Amenities', Icons.cleaning_services),
              _chip('Laundry & Linen', Icons.local_laundry_service),
              _chip('Utilities (Power/Water)', Icons.bolt),
              _chip('Maintenance & Repairs', Icons.build),
              _chip('Marketing & Advertising', Icons.campaign),
              _chip('Administrative', Icons.description),
              _chip('Other', Icons.more_horiz),
            ]),
          ),
        ),

        const SizedBox(height: 16),
        Text('Sample CSV', style: sectionStyle),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: codePad,
            child: SelectableText(
              'Date,Category,Subcategory,Description,Amount,Vendor,Payment Method,Receipt Ref,Notes\n'
              '2026-01-15,Food & Beverage,Kitchen Supplies,Fresh vegetable purchase,45000,FreshFarm Ltd,Transfer,REC-001,Weekly market\n'
              '2026-01-15,Logistics / Transport,Fuel,Fuel for generator delivery,85000,MRS Petroleum,Transfer,REC-002,\n'
              '2026-01-16,Toiletries & Amenities,Bathroom,Soap and shampoo restock,32000,CleanPro Supplies,Cash,REC-003,\n'
              '2026-01-16,Laundry & Linen,Bedsheets,Premium bedsheet set (20 pcs),120000,LinenHouse Ltd,Transfer,REC-004,\n'
              '2026-01-17,Utilities (Power/Water),Electricity,PHED Bill payment,78000,PHED,Transfer,REC-005,Service period Dec\n'
              '2026-01-18,Food & Beverage,Breakfast,Guest breakfast supplies,67000,CaterPlus Ltd,POS,REC-006,\n'
              '2026-01-19,Administrative,Office,Stationery supplies,15000,OfficeHub,Card,REC-007,\n'
              '2026-01-20,Maintenance & Repairs,Plumbing,Fix leak in Room 204,25000,Kazeem Plumbing,Cash,REC-008,\n'
              '2026-01-21,Marketing & Advertising,Digital,Social media ad campaign,50000,DigitalBoost Ltd,Transfer,REC-009,\n'
              '2026-01-22,Other,Contingency,Miscellaneous expenses,12000,,\n',
              style: codeStyle,
            ),
          ),
        ),

        const SizedBox(height: 16),
        Text('Import Rules', style: sectionStyle),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _rule('The first header row must contain Date as the first column'),
              _rule('Rows with zero or empty amounts are skipped'),
              _rule('Unknown categories default to "Other"'),
              _rule('Date format: YYYY-MM-DD (DD/MM/YYYY also supported)'),
              _rule('Maximum file size: 10MB'),
              _rule('Duplicate records are not automatically detected'),
            ]),
          ),
        ),
      ]),
    );
  }

  TableRow _headerRow(String c1, String c2, String c3) => TableRow(
    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1)),
    children: [c1, c2, c3].map((t) => Padding(
      padding: const EdgeInsets.all(10),
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
    )).toList(),
  );

  TableRow _dataRow(String c1, String c2, String c3) => TableRow(
    children: [c1, c2, c3].map((t) => Padding(
      padding: const EdgeInsets.all(10),
      child: Text(t, style: const TextStyle(fontSize: 12)),
    )).toList(),
  );

  Widget _chip(String label, IconData icon) => Chip(
    avatar: Icon(icon, size: 16, color: AppColors.primary),
    label: Text(label, style: const TextStyle(fontSize: 11)),
    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
    visualDensity: VisualDensity.compact,
  );

  Widget _rule(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
    ]),
  );
}
