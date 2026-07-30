import 'package:flutter/material.dart';
import '../utils/theme.dart';

const Color _primary = AppColors.primary;
const double _radius = 12;

const double kMetricMinWidth = 80;
const double kMetricMaxWidth = 200;
const double kMetricMinHeight = 60;
const double kMetricMaxHeight = 100;
const double kFieldSpacing = 12;

// ═══════════════════════════ RESPONSIVE HELPERS ═══════════════════════════

bool isCompact(BuildContext context) => MediaQuery.of(context).size.width < 600;
bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600;
bool isLandscape(BuildContext context) => MediaQuery.of(context).orientation == Orientation.landscape;
int gridColumns(BuildContext context) {
  if (isTablet(context)) return isLandscape(context) ? 4 : 3;
  return isLandscape(context) ? 3 : 2;
}

// ═══════════════════════════ METRIC CARD ═══════════════════════════

class HomMetricCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData? icon;
  final String? sub;
  const HomMetricCard({super.key, required this.label, required this.value, required this.color, this.icon, this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: kMetricMinWidth, maxWidth: kMetricMaxWidth, minHeight: kMetricMinHeight, maxHeight: kMetricMaxHeight),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(_radius)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) Icon(icon, color: color, size: 16),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color), overflow: TextOverflow.ellipsis),
        Text(label, style: TextStyle(fontSize: 10, color: color), overflow: TextOverflow.ellipsis),
        if (sub != null) Text(sub!, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7)), overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ═══════════════════════════ ANALYTICS CARD ═══════════════════════════

class HomAnalyticsCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const HomAnalyticsCard({super.key, required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color), overflow: TextOverflow.ellipsis),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════ STATUS CHIP ═══════════════════════════

class HomStatusChip extends StatelessWidget {
  final String label;
  final Color? color;
  const HomStatusChip({super.key, required this.label, this.color});

  factory HomStatusChip.fromStatus(String status) {
    Color c;
    switch (status) {
      case 'checked-in': case 'available': case 'approved': case 'delivered':
      case 'running': case 'paid': case 'resolved': case 'locked':
        c = _primary; break;
      case 'cancelled': case 'maintenance': case 'fault': case 'overdue':
      case 'pending': case 'open': case 'condemned':
        c = Colors.red; break;
      default:
        c = Colors.blue;
    }
    return HomStatusChip(label: status, color: c);
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.blue;
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c), overflow: TextOverflow.ellipsis),
    );
  }
}

// ═══════════════════════════ SECTION TITLE ═══════════════════════════

class HomSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const HomSectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15), overflow: TextOverflow.ellipsis)),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

// ═══════════════════════════ DETAIL ROW ═══════════════════════════

class HomDetailRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool alignRight;
  const HomDetailRow({super.key, required this.label, required this.value, this.valueColor, this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: alignRight
          ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Flexible(child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
            ])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: valueColor), overflow: TextOverflow.ellipsis)),
            ]),
    );
  }
}

// ═══════════════════════════ FORM FIELD WRAPPER ═══════════════════════════

EdgeInsets sheetPadding(BuildContext context) =>
  EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom);

Widget homField(Widget field, {double bottomSpacing = kFieldSpacing}) {
  return Padding(
    padding: EdgeInsets.only(bottom: bottomSpacing),
    child: field,
  );
}

// ═══════════════════════════ RESPONSIVE GRID ═══════════════════════════

class HomResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  const HomResponsiveGrid({super.key, required this.children, this.spacing = 12});

  @override
  Widget build(BuildContext context) {
    final cols = gridColumns(context);
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final itemWidth = constraints.maxWidth > 0
            ? (constraints.maxWidth - spacing * (cols - 1)) / cols
            : constraints.maxWidth;
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += cols) {
          final rowChildren = <Widget>[];
          for (var j = 0; j < cols && i + j < children.length; j++) {
            rowChildren.add(SizedBox(width: itemWidth, child: children[i + j]));
            if (j < cols - 1 && i + j + 1 < children.length) {
              rowChildren.add(SizedBox(width: spacing));
            }
          }
          rows.add(Row(mainAxisSize: MainAxisSize.min, children: rowChildren));
          if (i + cols < children.length) rows.add(SizedBox(height: spacing));
        }
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: rows);
      },
    );
  }
}


