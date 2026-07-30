import 'package:flutter/material.dart';
import '../../data/compliance_store.dart';
import 'scuml_screen.dart';
import 'tax_screen.dart';
import 'naptip_screen.dart';
import 'lga_screen.dart';
import 'cash_screen.dart';
import 'fire_screen.dart';

class ComplianceScreen extends StatelessWidget {
  const ComplianceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scumlCount = ComplianceStore.scumlTransactions.length;
    final taxCount = ComplianceStore.stateTaxConfigs.length;
    final naptipCount = ComplianceStore.naptipAlerts.length;
    final lgaStatus = ComplianceStore.latestInspection?.status ?? 'missing';
    final thresholdAlerts = ComplianceStore.thresholdAlertCount;
    final fireLatest = ComplianceStore.latestFireCert;

    return Scaffold(
      appBar: AppBar(title: const Text('Compliance')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Regulatory & Compliance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0B7A55))),
        const SizedBox(height: 4),
        Text('Stay compliant with Nigerian regulations', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 20),
        if (thresholdAlerts > 0) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade200)),
            child: Row(children: [
              const Icon(Icons.warning_rounded, color: Colors.red, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text('$thresholdAlerts transaction(s) exceed ₦5M SCUML reporting threshold', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.red.shade800))),
            ]),
          ),
          const SizedBox(height: 16),
        ],
        _card(
          context,
          icon: Icons.gavel_rounded,
          title: 'SCUML',
          subtitle: 'Money Laundering Compliance',
          body: '$scumlCount transaction${scumlCount == 1 ? '' : 's'} logged',
          color: Colors.indigo,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScumlScreen())),
        ),
        const SizedBox(height: 12),
        _card(
          context,
          icon: Icons.money_rounded,
          title: 'Cash Transactions',
          subtitle: 'Threshold monitoring',
          body: '$thresholdAlerts threshold alert${thresholdAlerts == 1 ? '' : 's'}',
          color: Colors.deepOrange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashScreen())),
        ),
        const SizedBox(height: 12),
        _card(
          context,
          icon: Icons.account_balance_rounded,
          title: 'State Consumption Tax',
          subtitle: 'Track & file state taxes',
          body: '$taxCount state${taxCount == 1 ? '' : 's'} configured',
          color: Colors.teal,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaxScreen())),
        ),
        const SizedBox(height: 12),
        _card(
          context,
          icon: Icons.warning_rounded,
          title: 'NAPTIP',
          subtitle: 'Human Trafficking Alerts',
          body: '$naptipCount alert${naptipCount == 1 ? '' : 's'}',
          color: Colors.orange.shade800,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NaptipScreen())),
        ),
        const SizedBox(height: 12),
        _card(
          context,
          icon: Icons.healing_rounded,
          title: 'LGA Health & Safety',
          subtitle: 'Inspection & certification',
          body: _lgaStatusText(lgaStatus),
          color: Colors.cyan.shade700,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LgaScreen())),
        ),
        const SizedBox(height: 12),
        _card(
          context,
          icon: Icons.local_fire_department_rounded,
          title: 'Fire Service',
          subtitle: 'Fire safety certificates',
          body: fireLatest != null ? fireLatest.certificateNumber : 'No certificate',
          color: Colors.red.shade700,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FireScreen())),
        ),
      ]),
    );
  }

  String _lgaStatusText(String s) {
    switch (s) {
      case 'valid': return 'Certificate valid';
      case 'expired': return 'Certificate expired!';
      case 'pending-renewal': return 'Renewal pending';
      default: return 'No inspection recorded';
    }
  }

  Widget _card(BuildContext context, {required IconData icon, required String title, required String subtitle, required String body, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color), overflow: TextOverflow.ellipsis),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(body, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800), overflow: TextOverflow.ellipsis),
            ])),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ]),
        ),
      ),
    );
  }
}
