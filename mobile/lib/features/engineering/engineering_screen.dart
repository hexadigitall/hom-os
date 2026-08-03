import 'package:flutter/material.dart';
import '../../models/engineering.dart';
import '../../data/engineering_store.dart';
import '../../main.dart' as app;
import '../../widgets/hom_widgets.dart';
import '../../models/role.dart';
import '../../utils/role_gate.dart';
import '../../utils/theme.dart';

const Color _primary = AppColors.primary;

class EngineeringScreen extends StatefulWidget {
  const EngineeringScreen({super.key});
  @override
  State<EngineeringScreen> createState() => _EngineeringScreenState();
}

class _EngineeringScreenState extends State<EngineeringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Engineering & Power'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: _primary,
          labelColor: _primary,
          unselectedLabelColor: AppColors.grey500,
          tabs: const [
            Tab(
                text: 'Dashboard',
                icon: Icon(Icons.dashboard_rounded, size: 15)),
            Tab(text: 'Generators', icon: Icon(Icons.power, size: 15)),
            Tab(text: 'Maintenance', icon: Icon(Icons.build_rounded, size: 15)),
            Tab(
                text: 'Fuel & Tanks',
                icon: Icon(Icons.local_gas_station_rounded, size: 15)),
            Tab(text: 'Grid & Cost', icon: Icon(Icons.bolt_rounded, size: 15)),
            Tab(
                text: 'Water Treatment',
                icon: Icon(Icons.water_drop_rounded, size: 15)),
          ],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [
        _DashboardTab(onChange: () => setState(() {})),
        _GeneratorsTab(onChange: () => setState(() {})),
        _MaintenanceTab(onChange: () => setState(() {})),
        _FuelTanksTab(onChange: () => setState(() {})),
        _GridCostTab(onChange: () => setState(() {})),
        _WaterTab(onChange: () => setState(() {})),
      ]),
    );
  }
}

// ─────────────────────── DASHBOARD TAB ───────────────────────

class _DashboardTab extends StatelessWidget {
  final VoidCallback onChange;
  const _DashboardTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final fuelCost = app.HOMData.fuelLogs.fold(0.0, (s, f) => s + f.cost);
    final tariff = EngineeringStore.activeTariff;
    final theftCount = EngineeringStore.theftAlerts.length;
    final upcomingWater = EngineeringStore.upcomingWaterTasks;
    final totalGenCost = EngineeringStore.generators
        .fold(0.0, (s, g) => s + g.currentRunHours * g.fuelRateLph * 1.2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        HomSectionTitle(title: 'Power Fleet Overview'),
        const SizedBox(height: 8),
        Wrap(children: [
          HomMetricCard(
              label: 'Running',
              value: '${EngineeringStore.runningCount}',
              color: _primary),
          HomMetricCard(
              label: 'Faults',
              value: '${EngineeringStore.faultCount}',
              color: AppColors.red),
          HomMetricCard(
              label: 'Total kVA',
              value: EngineeringStore.totalCapacity.toStringAsFixed(0),
              color: AppColors.blue),
          HomMetricCard(
              label: 'Avg Load',
              value: '${EngineeringStore.avgLoadPct.toStringAsFixed(0)}%',
              color: AppColors.orange),
        ]),
        const SizedBox(height: 16),
        Wrap(children: [
          HomAnalyticsCard(
              label: 'Run Hours',
              value: '${EngineeringStore.totalRunHours.toStringAsFixed(0)}h',
              icon: Icons.timer,
              color: AppColors.blue),
          HomAnalyticsCard(
              label: 'Energy Cost (₦)',
              value: _fmtShort(fuelCost),
              icon: Icons.monetization_on_rounded,
              color: AppColors.red),
        ]),
        const SizedBox(height: 16),
        HomSectionTitle(title: 'Generator Fleet'),
        const SizedBox(height: 8),
        ...EngineeringStore.generators.map((g) => Card(
                child: ListTile(
              leading: CircleAvatar(
                backgroundColor: g.status == GeneratorStatus.running
                    ? _primary
                    : g.status == GeneratorStatus.fault
                        ? AppColors.red
                        : AppColors.grey500,
                child: Text('${g.capacityKva.toStringAsFixed(0)}k',
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              title: Text(g.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              subtitle: Text(
                  '${g.statusLabel}  •  ${g.currentLoadKva.toStringAsFixed(0)}/${g.capacityKva.toStringAsFixed(0)} kVA (${g.loadPct.toStringAsFixed(0)}%)  •  ${g.currentRunHours.toStringAsFixed(0)}h',
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: g.status == GeneratorStatus.running
                      ? _primary.withValues(alpha: 0.1)
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(g.statusLabel,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: g.status == GeneratorStatus.running
                            ? _primary
                            : AppColors.grey500)),
              ),
            ))),
        const SizedBox(height: 16),
        HomSectionTitle(title: 'Grid vs Diesel Cost'),
        const SizedBox(height: 8),
        Card(
            child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Grid (${tariff?.bandName ?? 'N/A'})',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('₦${_fmtShort(tariff?.monthlyCost ?? 0)}/mo',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Diesel Generation',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text('₦${_fmtShort(totalGenCost)}/mo',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.orange)),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(
                value: tariff != null && totalGenCost > 0
                    ? (tariff.monthlyCost / (tariff.monthlyCost + totalGenCost))
                        .clamp(0.0, 1.0)
                    : 0),
          ]),
        )),
        if (theftCount > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppColors.red50,
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(Icons.warning_rounded, color: AppColors.red, size: 20),
              const SizedBox(width: 10),
              Flexible(
                  child: Text(
                      '$theftCount tank theft alert(s)! Variance detected in dip readings.',
                      style: const TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 13))),
            ]),
          ),
        ],
        if (upcomingWater.isNotEmpty) ...[
          const SizedBox(height: 16),
          HomSectionTitle(title: 'Upcoming Water Treatment'),
          ...upcomingWater.take(3).map((w) => Card(
                  child: ListTile(
                leading:
                    const Icon(Icons.water_drop_rounded, color: AppColors.blue),
                title: Text('${w.source} — ${w.treatmentAction}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(
                    'Due: ${w.nextScheduledDate!.toIso8601String().substring(0, 10)}',
                    style: const TextStyle(fontSize: 11)),
              ))),
        ],
      ]),
    );
  }

  String _fmtShort(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}

// ─────────────────────── GENERATORS TAB ───────────────────────

class _GeneratorsTab extends StatelessWidget {
  final VoidCallback onChange;
  const _GeneratorsTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final gens = EngineeringStore.generators;
    return Scaffold(
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.grey50,
          child: Wrap(children: [
            HomMetricCard(
                label: 'Running',
                value: '${EngineeringStore.runningCount}',
                color: _primary),
            HomMetricCard(
                label: 'Faults',
                value: '${EngineeringStore.faultCount}',
                color: AppColors.red),
            HomMetricCard(
                label: 'Total kVA',
                value: EngineeringStore.totalCapacity.toStringAsFixed(0),
                color: AppColors.blue),
            HomMetricCard(
                label: 'Avg Load',
                value: '${EngineeringStore.avgLoadPct.toStringAsFixed(0)}%',
                color: AppColors.orange),
          ]),
        ),
        Expanded(
          child: gens.isEmpty
              ? const Center(child: Text('No generators configured'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: gens.length,
                  itemBuilder: (ctx, i) {
                    final g = gens[i];
                    return Card(
                        child: Column(children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: g.status == GeneratorStatus.running
                              ? _primary
                              : g.status == GeneratorStatus.fault
                                  ? AppColors.red
                                  : AppColors.grey500,
                          child: Text(g.capacityKva.toStringAsFixed(0),
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                        title: Text(g.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            '${g.model ?? ''}  •  ${g.statusLabel}  •  ${g.currentRunHours.toStringAsFixed(0)}h',
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                        trailing: RoleGate(
                            requiredPermission:
                                Permission.trackGeneratorRunHours,
                            child: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') _showForm(context, gen: g);
                                if (v == 'toggle') {
                                  final next =
                                      g.status == GeneratorStatus.running
                                          ? GeneratorStatus.idle
                                          : GeneratorStatus.running;
                                  EngineeringStore.updateGenerator(
                                      g.id,
                                      Generator(
                                          id: g.id,
                                          name: g.name,
                                          model: g.model,
                                          location: g.location,
                                          capacityKva: g.capacityKva,
                                          currentRunHours: g.currentRunHours,
                                          lastOilChangeHours:
                                              g.lastOilChangeHours,
                                          currentLoadKva: g.currentLoadKva,
                                          status: next,
                                          lastServiceDate: g.lastServiceDate));
                                  onChange();
                                }
                                if (v == 'delete') {
                                  EngineeringStore.removeGenerator(g.id);
                                  onChange();
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: 'edit', child: Text('Edit')),
                                PopupMenuItem(
                                    value: 'toggle',
                                    child: Text(
                                        g.status == GeneratorStatus.running
                                            ? 'Stop'
                                            : 'Start')),
                                const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete',
                                        style:
                                            TextStyle(color: AppColors.red))),
                              ],
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(children: [
                          Expanded(
                              child:
                                  _loadBar('Load', g.loadPct, AppColors.amber)),
                          const SizedBox(width: 8),
                          Text(
                              '${g.currentLoadKva.toStringAsFixed(0)}/${g.capacityKva.toStringAsFixed(0)} kVA',
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ]));
                  },
                ),
        ),
      ]),
      floatingActionButton: RoleGate(
          requiredPermission: Permission.trackGeneratorRunHours,
          child: FloatingActionButton(
            backgroundColor: _primary,
            foregroundColor: AppColors.white,
            child: const Icon(Icons.add),
            onPressed: () => _showForm(context),
          )),
    );
  }

  Widget _loadBar(String label, double pct, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('${pct.toStringAsFixed(0)}%',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 2),
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: AppColors.grey200,
            color: color,
            minHeight: 8),
      ),
    ]);
  }

  void _showForm(BuildContext context, {Generator? gen}) {
    final nameCtl = TextEditingController(text: gen?.name ?? '');
    final modelCtl = TextEditingController(text: gen?.model ?? '');
    final locCtl = TextEditingController(text: gen?.location ?? '');
    final kvaCtl =
        TextEditingController(text: gen?.capacityKva.toStringAsFixed(0) ?? '');
    final loadCtl = TextEditingController(
        text: gen?.currentLoadKva.toStringAsFixed(0) ?? '0');
    final hoursCtl = TextEditingController(
        text: gen?.currentRunHours.toStringAsFixed(0) ?? '');
    final oilCtl = TextEditingController(
        text: gen?.lastOilChangeHours.toStringAsFixed(0) ?? '0');
    GeneratorStatus status = gen?.status ?? GeneratorStatus.idle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.grey300,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Text(gen == null ? 'Add Generator' : 'Edit Generator',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(
                        labelText: 'Generator Name',
                        border: OutlineInputBorder())),
                homField(Row(children: [
                  Expanded(
                      child: TextField(
                          controller: modelCtl,
                          decoration: const InputDecoration(
                              labelText: 'Model',
                              border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: kvaCtl,
                          decoration: const InputDecoration(
                              labelText: 'Capacity (kVA)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                ])),
                TextField(
                    controller: locCtl,
                    decoration: const InputDecoration(
                        labelText: 'Location', border: OutlineInputBorder())),
                homField(Row(children: [
                  Expanded(
                      child: TextField(
                          controller: loadCtl,
                          decoration: const InputDecoration(
                              labelText: 'Current Load (kVA)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: hoursCtl,
                          decoration: const InputDecoration(
                              labelText: 'Run Hours',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                ])),
                homField(Row(children: [
                  Expanded(
                      child: TextField(
                          controller: oilCtl,
                          decoration: const InputDecoration(
                              labelText: 'Oil Change (hrs)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: DropdownButtonFormField<GeneratorStatus>(
                    initialValue: status,
                    decoration: const InputDecoration(
                        labelText: 'Status', border: OutlineInputBorder()),
                    items: GeneratorStatus.values
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s.name)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheet(() => status = v);
                    },
                  )),
                ])),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      final kva = double.tryParse(kvaCtl.text) ?? 0;
                      if (nameCtl.text.isEmpty || kva <= 0) return;
                      final g = Generator(
                        id: gen?.id ??
                            'g_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtl.text,
                        model: modelCtl.text.isEmpty ? null : modelCtl.text,
                        location: locCtl.text.isEmpty ? null : locCtl.text,
                        capacityKva: kva,
                        currentRunHours: double.tryParse(hoursCtl.text) ?? 0,
                        lastOilChangeHours: double.tryParse(oilCtl.text) ?? 0,
                        currentLoadKva: double.tryParse(loadCtl.text) ?? 0,
                        status: status,
                      );
                      if (gen != null) {
                        EngineeringStore.updateGenerator(gen.id, g);
                      } else {
                        EngineeringStore.addGenerator(g);
                      }
                      Navigator.pop(ctx);
                      onChange();
                    },
                    child: Text(gen == null ? 'Add Generator' : 'Update'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── FUEL & TANKS TAB ───────────────────────

class _FuelTanksTab extends StatelessWidget {
  final VoidCallback onChange;
  const _FuelTanksTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final dips = EngineeringStore.tankDipLogs;
    final thefts = EngineeringStore.theftAlerts;
    final logs = app.HOMData.fuelLogs;
    final dieselCost = logs
        .where((f) => f.fuelType.name == 'diesel')
        .fold(0.0, (s, f) => s + f.cost);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        HomSectionTitle(title: 'Tank Dip Logging'),
        const SizedBox(height: 8),
        if (thefts.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                color: AppColors.red50,
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.warning_rounded, color: AppColors.red, size: 18),
              const SizedBox(width: 8),
              Flexible(
                  child: Text('${thefts.length} theft alert(s) detected!',
                      style: const TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 13))),
            ]),
          ),
        Wrap(children: [
          HomMetricCard(
              label: 'Total Dips',
              value: '${dips.length}',
              color: AppColors.blue),
          HomMetricCard(
              label: 'Theft Alerts',
              value: '${thefts.length}',
              color: AppColors.red),
          HomMetricCard(
              label: 'Diesel Cost',
              value: '₦${dieselCost.toStringAsFixed(0)}',
              color: AppColors.orange),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: RoleGate(
              requiredPermission: Permission.trackFuelDeliveryCycles,
              child: ElevatedButton.icon(
                onPressed: () => _showDipForm(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Record Dip Reading'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: AppColors.white),
              )),
        ),
        const SizedBox(height: 16),
        HomSectionTitle(title: 'Dip History'),
        ...dips.take(10).map((d) => Card(
              color: d.isTheftAlert ? AppColors.red50 : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      d.isTheftAlert ? AppColors.red : AppColors.green,
                  child: Icon(
                      d.isTheftAlert ? Icons.warning_rounded : Icons.check,
                      color: AppColors.white,
                      size: 18),
                ),
                title: Text(
                    '${d.tankName} — ${d.calculatedVolumeL.toStringAsFixed(0)}L',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(
                    'Dip: ${d.dipReadingCm.toStringAsFixed(0)}cm  •  ${d.date.toIso8601String().substring(0, 10)}${d.variancePct != null ? '  •  Var: ${d.variancePct!.toStringAsFixed(1)}%' : ''}',
                    style: TextStyle(
                        fontSize: 11,
                        color:
                            d.isTheftAlert ? AppColors.red : AppColors.grey600),
                    overflow: TextOverflow.ellipsis),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  RoleGate(
                      requiredPermission: Permission.trackFuelDeliveryCycles,
                      child: IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        onPressed: () => _showDipForm(context, dip: d),
                      )),
                  RoleGate(
                      requiredPermission: Permission.trackFuelDeliveryCycles,
                      child: IconButton(
                        icon: const Icon(Icons.delete_rounded,
                            size: 18, color: AppColors.redAccent),
                        onPressed: () {
                          EngineeringStore.removeTankDipLog(d.id);
                          onChange();
                        },
                      )),
                ]),
                onTap: () => _showDipDetail(context, d),
              ),
            )),
        const SizedBox(height: 16),
        HomSectionTitle(title: 'Fuel Consumption (30d)'),
        const SizedBox(height: 8),
        ...logs
            .where((f) =>
                f.fuelType.name == 'diesel' || f.fuelType.name == 'petrol')
            .take(5)
            .map((f) => Card(
                    child: ListTile(
                  leading: Icon(f.fuelType.icon, color: AppColors.amber700),
                  title: Text(
                      '${f.quantity.toStringAsFixed(0)}${f.fuelType.unit} — ${f.supplier}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${f.date.toIso8601String().substring(0, 10)}  •  ₦${f.cost.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 11)),
                  trailing: f.theftAlertRate != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.red,
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(
                              '${f.theftAlertRate!.toStringAsFixed(1)} L/hr',
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        )
                      : null,
                ))),
      ]),
    );
  }

  void _showDipDetail(BuildContext context, TankDipLog d) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              scrollable: true,
              title: Text('${d.tankName} — Dip Reading'),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _det('Date', d.date.toIso8601String().substring(0, 10)),
                    _det('Dip Reading',
                        '${d.dipReadingCm.toStringAsFixed(0)} cm'),
                    _det('Tank Capacity',
                        '${d.tankCapacityL.toStringAsFixed(0)} L'),
                    _det('Calculated Volume',
                        '${d.calculatedVolumeL.toStringAsFixed(0)} L'),
                    _det('Expected Volume',
                        d.expectedVolumeL?.toStringAsFixed(0) ?? 'N/A'),
                    if (d.varianceL != null)
                      _det(
                          'Variance',
                          '${d.varianceL!.toStringAsFixed(0)} L (${d.variancePct!.toStringAsFixed(1)}%)',
                          d.isTheftAlert ? AppColors.red : null),
                    if (d.isTheftAlert)
                      _det(
                          '⚠ ALERT', 'Possible theft detected!', AppColors.red),
                    _det('Performed By', d.performedBy ?? 'N/A'),
                    if (d.notes != null) _det('Notes', d.notes!),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'))
              ],
            ));
  }

  Widget _det(String label, String value, [Color? color]) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Text('$label: ',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Flexible(
              child: Text(value, style: TextStyle(fontSize: 13, color: color))),
        ]),
      );

  void _showDipForm(BuildContext context, {TankDipLog? dip}) {
    final readingCtl =
        TextEditingController(text: dip?.dipReadingCm.toStringAsFixed(0) ?? '');
    final capacityCtl = TextEditingController(
        text: dip?.tankCapacityL.toStringAsFixed(0) ?? '5000');
    final performedCtl = TextEditingController(text: dip?.performedBy ?? '');
    final notesCtl = TextEditingController(text: dip?.notes ?? '');
    String tankName = dip?.tankName ?? 'Main Diesel Tank';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.grey300,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Text(dip == null ? 'Record Tank Dip' : 'Edit Dip Reading',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: tankName,
                  decoration: const InputDecoration(
                      labelText: 'Tank', border: OutlineInputBorder()),
                  items: [
                    'Main Diesel Tank',
                    'Generator Day Tank',
                    'Petrol Storage',
                    'LPG Cylinder'
                  ]
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null)
                      setSheet(() {
                        tankName = v;
                        if (v == 'Generator Day Tank') {
                          capacityCtl.text = '500';
                        } else if (v == 'Petrol Storage') {
                          capacityCtl.text = '1000';
                        } else {
                          capacityCtl.text = '5000';
                        }
                      });
                  },
                ),
                const SizedBox(height: 12),
                homField(Row(children: [
                  Expanded(
                      child: TextField(
                          controller: readingCtl,
                          decoration: const InputDecoration(
                              labelText: 'Dip Reading (cm)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: capacityCtl,
                          decoration: const InputDecoration(
                              labelText: 'Tank Capacity (L)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                ])),
                TextField(
                    controller: performedCtl,
                    decoration: const InputDecoration(
                        labelText: 'Performed By',
                        border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: notesCtl,
                    decoration: const InputDecoration(
                        labelText: 'Notes', border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      final reading = double.tryParse(readingCtl.text) ?? 0;
                      final cap = double.tryParse(capacityCtl.text) ?? 5000;
                      if (reading <= 0) return;
                      final vol = (reading / 100) * cap;
                      final lastDip = EngineeringStore.latestDip;
                      double? expected;
                      if (lastDip != null && lastDip.tankName == tankName) {
                        final prevVol = lastDip.calculatedVolumeL;
                        final daysSince = DateTime.now()
                            .difference(lastDip.date)
                            .inDays
                            .toDouble();
                        expected = prevVol -
                            (EngineeringStore.totalRunHours *
                                12 *
                                daysSince /
                                30);
                      }
                      final entry = TankDipLog(
                        id: dip?.id ??
                            'dip_${DateTime.now().millisecondsSinceEpoch}',
                        date: dip?.date ?? DateTime.now(),
                        tankName: tankName,
                        dipReadingCm: reading,
                        tankCapacityL: cap,
                        calculatedVolumeL: vol,
                        expectedVolumeL: expected,
                        performedBy: performedCtl.text.isEmpty
                            ? null
                            : performedCtl.text,
                        notes: notesCtl.text.isEmpty ? null : notesCtl.text,
                      );
                      if (dip != null) {
                        EngineeringStore.updateTankDipLog(dip.id, entry);
                      } else {
                        EngineeringStore.addTankDipLog(entry);
                      }
                      Navigator.pop(ctx);
                      onChange();
                    },
                    child: Text(dip == null ? 'Record' : 'Update'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── GRID & COST TAB ───────────────────────

class _GridCostTab extends StatelessWidget {
  final VoidCallback onChange;
  const _GridCostTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final tariffs = EngineeringStore.gridTariffs;
    final active = EngineeringStore.activeTariff;
    final dieselLogs =
        app.HOMData.fuelLogs.where((f) => f.fuelType.name == 'diesel').toList();
    final totalDieselL = dieselLogs.fold(0.0, (s, f) => s + f.quantity);
    final dieselCost = dieselLogs.fold(0.0, (s, f) => s + f.cost);
    final dieselLph = EngineeringStore.totalRunHours > 0
        ? totalDieselL / EngineeringStore.totalRunHours
        : 0;
    final dieselPerKwh = dieselLph > 0 && EngineeringStore.totalCapacity > 0
        ? (dieselCost / totalDieselL * dieselLph) /
            EngineeringStore.totalCapacity
        : 0;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HomSectionTitle(title: 'Grid Tariff Configuration'),
          const SizedBox(height: 8),
          ...tariffs.map((t) => Card(
                color: t.band == active?.band
                    ? _primary.withValues(alpha: 0.05)
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        t.band == active?.band ? _primary : AppColors.grey500,
                    child: Text(t.band.name.toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                  title: Text(t.label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${t.hoursPerDay.toStringAsFixed(0)}h/day  •  ₦${t.costPerKwh.toStringAsFixed(0)}/kWh  •  ₦${_fmtShort(t.monthlyCost)}/mo'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (t.band == active?.band)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Text('ACTIVE',
                            style: TextStyle(
                                color: AppColors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      )
                    else
                      RoleGate(
                          requiredPermission: Permission.trackGridTariffUsage,
                          child: TextButton(
                            onPressed: () {
                              EngineeringStore.upsertTariff(t);
                              onChange();
                            },
                            child: const Text('Activate'),
                          )),
                    RoleGate(
                        requiredPermission: Permission.trackGridTariffUsage,
                        child: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit')
                              _showTariffForm(context, tariff: t);
                            if (v == 'delete') {
                              EngineeringStore.removeTariff(t.id);
                              onChange();
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete',
                                    style: TextStyle(color: AppColors.red))),
                          ],
                        )),
                  ]),
                ),
              )),
          const SizedBox(height: 20),
          HomSectionTitle(title: 'Cost Optimisation'),
          const SizedBox(height: 8),
          Card(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Grid Electricity',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text(
                  'Active: ${active?.bandName ?? 'None'}  •  ₦${active?.costPerKwh.toStringAsFixed(0) ?? 'N/A'}/kWh  •  ${active?.hoursPerDay.toStringAsFixed(0) ?? 'N/A'}h/day',
                  style: const TextStyle(fontSize: 12)),
              const Divider(),
              const Text('Diesel Generation',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text(
                  'Avg consumption: ${dieselLph.toStringAsFixed(1)} L/hr  •  Est. cost: ₦${dieselPerKwh.toStringAsFixed(0)}/kWh',
                  style: const TextStyle(fontSize: 12)),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Grid Monthly: ₦${_fmtShort(active?.monthlyCost ?? 0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Diesel Monthly: ₦${_fmtShort(dieselCost)}',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.orange)),
              ]),
              const SizedBox(height: 8),
              if (active != null && dieselPerKwh > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: active.costPerKwh < dieselPerKwh
                        ? AppColors.green50
                        : AppColors.orange50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(
                        active.costPerKwh < dieselPerKwh
                            ? Icons.check_circle
                            : Icons.info_rounded,
                        color: active.costPerKwh < dieselPerKwh
                            ? AppColors.green
                            : AppColors.orange,
                        size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                        child: Text(
                      active.costPerKwh < dieselPerKwh
                          ? 'Grid is cheaper than diesel. Use grid during supply hours.'
                          : 'Diesel is cheaper than grid. Consider running gen-sets during peak hours.',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active.costPerKwh < dieselPerKwh
                              ? AppColors.green
                              : AppColors.orange),
                    )),
                  ]),
                ),
            ]),
          )),
        ]),
      ),
      floatingActionButton: RoleGate(
          requiredPermission: Permission.trackGridTariffUsage,
          child: FloatingActionButton(
            backgroundColor: _primary,
            foregroundColor: AppColors.white,
            child: const Icon(Icons.add),
            onPressed: () => _showTariffForm(context),
          )),
    );
  }

  void _showTariffForm(BuildContext context, {GridTariffConfig? tariff}) {
    final labelCtl = TextEditingController(text: tariff?.label ?? '');
    final descCtl = TextEditingController(text: tariff?.description ?? '');
    final hoursCtl = TextEditingController(
        text: (tariff?.hoursPerDay ?? 16).toStringAsFixed(0));
    final costCtl = TextEditingController(
        text: (tariff?.costPerKwh ?? 100).toStringAsFixed(0));
    GridBand band = tariff?.band ?? GridBand.b;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.grey300,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Text(tariff == null ? 'Add Tariff' : 'Edit Tariff',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                    controller: labelCtl,
                    decoration: const InputDecoration(
                        labelText: 'Label', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: descCtl,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: hoursCtl,
                          decoration: const InputDecoration(
                              labelText: 'Hours/Day',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextField(
                          controller: costCtl,
                          decoration: const InputDecoration(
                              labelText: 'Cost (₦/kWh)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<GridBand>(
                  initialValue: band,
                  decoration: const InputDecoration(
                      labelText: 'Band', border: OutlineInputBorder()),
                  items: GridBand.values
                      .map((b) => DropdownMenuItem(
                          value: b,
                          child: Text('Band ${b.name.toUpperCase()}')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheet(() => band = v);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      final hours = double.tryParse(hoursCtl.text) ?? 0;
                      final cost = double.tryParse(costCtl.text) ?? 0;
                      if (labelCtl.text.isEmpty || hours <= 0 || cost <= 0)
                        return;
                      final entry = GridTariffConfig(
                        id: tariff?.id ??
                            't_${DateTime.now().millisecondsSinceEpoch}',
                        band: band,
                        hoursPerDay: hours,
                        costPerKwh: cost,
                        label: labelCtl.text,
                        description: descCtl.text,
                      );
                      EngineeringStore.upsertTariff(entry);
                      Navigator.pop(ctx);
                      onChange();
                    },
                    child: Text(tariff == null ? 'Add Tariff' : 'Update'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  String _fmtShort(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}

// ─────────────────────── MAINTENANCE TAB ───────────────────────

class _MaintenanceTab extends StatelessWidget {
  final VoidCallback onChange;
  const _MaintenanceTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final tasks = EngineeringStore.pendingTasks;
    final overdue = EngineeringStore.overdueTasks;
    return Scaffold(
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.grey50,
          child: Wrap(children: [
            HomMetricCard(
                label: 'Pending',
                value: '${tasks.length}',
                color: AppColors.blue),
            HomMetricCard(
                label: 'Overdue',
                value: '${overdue.length}',
                color: AppColors.red),
            HomMetricCard(
                label: 'Urgent',
                value:
                    '${tasks.where((t) => t.priority == MaintenancePriority.urgent || t.priority == MaintenancePriority.critical).length}',
                color: AppColors.orange),
          ]),
        ),
        Expanded(
          child: tasks.isEmpty
              ? const Center(child: Text('No pending maintenance tasks'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: tasks.length,
                  itemBuilder: (ctx, i) {
                    final t = tasks[i];
                    final isOverdue = overdue.contains(t);
                    return Card(
                      color: isOverdue ? AppColors.red50 : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isOverdue ? AppColors.red : _primary,
                          child: Icon(
                              isOverdue
                                  ? Icons.warning_rounded
                                  : Icons.check_circle_outline,
                              color: AppColors.white,
                              size: 20),
                        ),
                        title: Text(t.equipmentName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            '${t.description}  •  Due: ${t.scheduledDate.toIso8601String().substring(0, 10)}  •  ${t.assignedTo}  •  ${t.priority.name}',
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          if (!t.completed)
                            RoleGate(
                                requiredPermission:
                                    Permission.managePreventativeMaintenance,
                                child: IconButton(
                                  icon:
                                      Icon(Icons.check_circle, color: _primary),
                                  onPressed: () {
                                    EngineeringStore.updateTask(
                                        t.id,
                                        MaintenanceTask(
                                            id: t.id,
                                            equipmentName: t.equipmentName,
                                            description: t.description,
                                            assignedTo: t.assignedTo,
                                            equipmentType: t.equipmentType,
                                            priority: t.priority,
                                            scheduledDate: t.scheduledDate,
                                            completedDate: DateTime.now(),
                                            completed: true));
                                    onChange();
                                  },
                                )),
                          RoleGate(
                              requiredPermission:
                                  Permission.managePreventativeMaintenance,
                              child: IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                onPressed: () => _showForm(context, task: t),
                              )),
                          RoleGate(
                              requiredPermission:
                                  Permission.managePreventativeMaintenance,
                              child: IconButton(
                                icon: const Icon(Icons.delete_rounded,
                                    color: AppColors.redAccent, size: 18),
                                onPressed: () {
                                  EngineeringStore.removeTask(t.id);
                                  onChange();
                                },
                              )),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ]),
      floatingActionButton: RoleGate(
          requiredPermission: Permission.managePreventativeMaintenance,
          child: FloatingActionButton(
            backgroundColor: _primary,
            foregroundColor: AppColors.white,
            child: const Icon(Icons.add),
            onPressed: () => _showForm(context),
          )),
    );
  }

  void _showForm(BuildContext context, {MaintenanceTask? task}) {
    final equipCtl = TextEditingController(text: task?.equipmentName ?? '');
    final descCtl = TextEditingController(text: task?.description ?? '');
    final assignCtl = TextEditingController(text: task?.assignedTo ?? '');
    DateTime dueDate =
        task?.scheduledDate ?? DateTime.now().add(const Duration(days: 7));
    EquipmentType equipType = task?.equipmentType ?? EquipmentType.generator;
    MaintenancePriority priority =
        task?.priority ?? MaintenancePriority.routine;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.grey300,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Text(task == null ? 'Schedule Maintenance' : 'Edit Maintenance',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                    controller: equipCtl,
                    decoration: const InputDecoration(
                        labelText: 'Equipment Name',
                        border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: descCtl,
                    decoration: const InputDecoration(
                        labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 12),
                TextField(
                    controller: assignCtl,
                    decoration: const InputDecoration(
                        labelText: 'Assigned To',
                        border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: DropdownButtonFormField<EquipmentType>(
                    initialValue: equipType,
                    decoration: const InputDecoration(
                        labelText: 'Type', border: OutlineInputBorder()),
                    items: EquipmentType.values
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e.name)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheet(() => equipType = v);
                    },
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: DropdownButtonFormField<MaintenancePriority>(
                    initialValue: priority,
                    decoration: const InputDecoration(
                        labelText: 'Priority', border: OutlineInputBorder()),
                    items: MaintenancePriority.values
                        .map((p) =>
                            DropdownMenuItem(value: p, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheet(() => priority = v);
                    },
                  )),
                ]),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(
                      'Due Date: ${dueDate.toIso8601String().substring(0, 10)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) setSheet(() => dueDate = picked);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      if (equipCtl.text.isEmpty || assignCtl.text.isEmpty)
                        return;
                      final updated = MaintenanceTask(
                        id: task?.id ??
                            'm_${DateTime.now().millisecondsSinceEpoch}',
                        equipmentName: equipCtl.text,
                        description: descCtl.text,
                        assignedTo: assignCtl.text,
                        equipmentType: equipType,
                        priority: priority,
                        scheduledDate: dueDate,
                        completed: task?.completed ?? false,
                      );
                      if (task != null) {
                        EngineeringStore.updateTask(task.id, updated);
                      } else {
                        EngineeringStore.addTask(updated);
                      }
                      Navigator.pop(ctx);
                      onChange();
                    },
                    child: Text(task == null ? 'Schedule Task' : 'Update'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── WATER TREATMENT TAB ───────────────────────

class _WaterTab extends StatelessWidget {
  final VoidCallback onChange;
  const _WaterTab({required this.onChange});

  @override
  Widget build(BuildContext context) {
    final logs = EngineeringStore.waterLogs;
    final upcoming = EngineeringStore.upcomingWaterTasks;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (upcoming.isNotEmpty) ...[
            HomSectionTitle(title: 'Upcoming Tasks'),
            ...upcoming.take(5).map((w) => Card(
                  color: w.nextScheduledDate!
                          .isBefore(DateTime.now().add(const Duration(days: 2)))
                      ? AppColors.orange50
                      : null,
                  child: ListTile(
                    leading: const Icon(Icons.schedule_rounded,
                        color: AppColors.blue),
                    title: Text('${w.source} — ${w.treatmentAction}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                        'Due: ${w.nextScheduledDate!.toIso8601String().substring(0, 10)}  •  ${w.chemicalUsed ?? ''} ${w.chemicalDosageMl != null ? '(${w.chemicalDosageMl!.toStringAsFixed(0)}ml)' : ''}',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                  ),
                )),
            const SizedBox(height: 16),
          ],
          HomSectionTitle(title: 'Treatment Log'),
          ...logs.map((w) => Card(
                  child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: w.source == 'RO Plant'
                      ? AppColors.blue
                      : w.source == 'Swimming Pool'
                          ? AppColors.teal
                          : AppColors.grey500,
                  child: Text(w.source[0],
                      style: const TextStyle(
                          color: AppColors.white, fontWeight: FontWeight.w700)),
                ),
                title: Text('${w.source} — ${w.treatmentAction}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(
                    'pH: ${w.phLevel}  •  Cl: ${w.chlorineLevel?.toStringAsFixed(1) ?? 'N/A'}  •  TDS: ${w.tdsLevel?.toStringAsFixed(0) ?? 'N/A'}  •  ${w.date.toIso8601String().substring(0, 10)}',
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  RoleGate(
                      requiredPermission: Permission.manageWaterTreatment,
                      child: IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        onPressed: () => _showForm(context, log: w),
                      )),
                  RoleGate(
                      requiredPermission: Permission.manageWaterTreatment,
                      child: IconButton(
                        icon: const Icon(Icons.delete_rounded,
                            size: 18, color: AppColors.redAccent),
                        onPressed: () {
                          EngineeringStore.removeWaterLog(w.id);
                          onChange();
                        },
                      )),
                ]),
                onTap: () => _showDetail(context, w),
              ))),
        ]),
      ),
      floatingActionButton: RoleGate(
          requiredPermission: Permission.manageWaterTreatment,
          child: FloatingActionButton(
            backgroundColor: _primary,
            foregroundColor: AppColors.white,
            child: const Icon(Icons.add),
            onPressed: () => _showForm(context),
          )),
    );
  }

  void _showDetail(BuildContext context, WaterTreatmentLog w) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              scrollable: true,
              title: Text('${w.source} — ${w.treatmentAction}'),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(
                        'Date', w.date.toIso8601String().substring(0, 10)),
                    _detailRow('pH Level', '${w.phLevel}'),
                    _detailRow('Chlorine',
                        w.chlorineLevel?.toStringAsFixed(1) ?? 'N/A'),
                    _detailRow('TDS',
                        '${w.tdsLevel?.toStringAsFixed(0) ?? 'N/A'} ppm'),
                    _detailRow('Chemical', w.chemicalUsed ?? 'N/A'),
                    _detailRow(
                        'Dosage',
                        w.chemicalDosageMl != null
                            ? '${w.chemicalDosageMl!.toStringAsFixed(0)} ml'
                            : 'N/A'),
                    _detailRow(
                        'Next Due',
                        w.nextScheduledDate
                                ?.toIso8601String()
                                .substring(0, 10) ??
                            'N/A'),
                    _detailRow('Performed By', w.performedBy ?? 'N/A'),
                    if (w.notes != null) _detailRow('Notes', w.notes!),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'))
              ],
            ));
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Text('$label: ',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 13)))
        ]),
      );

  void _showForm(BuildContext context, {WaterTreatmentLog? log}) {
    final performedCtl = TextEditingController(text: log?.performedBy ?? '');
    final notesCtl = TextEditingController(text: log?.notes ?? '');
    final chemCtl = TextEditingController(text: log?.chemicalUsed ?? '');
    final dosageCtl = TextEditingController(
        text: log?.chemicalDosageMl?.toStringAsFixed(0) ?? '');
    final phCtl =
        TextEditingController(text: log?.phLevel.toStringAsFixed(1) ?? '7.0');
    final chlorineCtl = TextEditingController(
        text: log?.chlorineLevel?.toStringAsFixed(1) ?? '');
    final tdsCtl =
        TextEditingController(text: log?.tdsLevel?.toStringAsFixed(0) ?? '');
    String source = log?.source ?? 'RO Plant';
    String action = log?.treatmentAction ?? 'backwash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.grey300,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Text(log == null ? 'Log Water Treatment' : 'Edit Water Log',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: source,
                  decoration: const InputDecoration(
                      labelText: 'Source', border: OutlineInputBorder()),
                  items: ['Borehole', 'RO Plant', 'STP', 'Swimming Pool']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheet(() => source = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: action,
                  decoration: const InputDecoration(
                      labelText: 'Action', border: OutlineInputBorder()),
                  items: [
                    'backwash',
                    'chemicalDosing',
                    'filterClean',
                    'sampleTest'
                  ]
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheet(() => action = v);
                  },
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: TextField(
                          decoration: const InputDecoration(
                              labelText: 'pH Level',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          controller: phCtl)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextField(
                          decoration: const InputDecoration(
                              labelText: 'Chlorine (mg/L)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          controller: chlorineCtl)),
                ]),
                const SizedBox(height: 12),
                homField(Row(children: [
                  Expanded(
                      child: TextField(
                          controller: chemCtl,
                          decoration: const InputDecoration(
                              labelText: 'Chemical Used',
                              border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextField(
                          controller: dosageCtl,
                          decoration: const InputDecoration(
                              labelText: 'Dosage (ml)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                ])),
                homField(Row(children: [
                  Expanded(
                      child: TextField(
                          decoration: const InputDecoration(
                              labelText: 'TDS (ppm)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          controller: tdsCtl)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextField(
                          controller: performedCtl,
                          decoration: const InputDecoration(
                              labelText: 'Performed By',
                              border: OutlineInputBorder()))),
                ])),
                const SizedBox(height: 12),
                TextField(
                    controller: notesCtl,
                    decoration: const InputDecoration(
                        labelText: 'Notes', border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      final entry = WaterTreatmentLog(
                        id: log?.id ??
                            'w_${DateTime.now().millisecondsSinceEpoch}',
                        date: log?.date ?? DateTime.now(),
                        source: source,
                        phLevel: double.tryParse(phCtl.text) ?? 7.0,
                        chlorineLevel: double.tryParse(chlorineCtl.text),
                        tdsLevel: double.tryParse(tdsCtl.text),
                        treatmentAction: action,
                        performedBy: performedCtl.text.isEmpty
                            ? null
                            : performedCtl.text,
                        notes: notesCtl.text.isEmpty ? null : notesCtl.text,
                        chemicalUsed:
                            chemCtl.text.isEmpty ? null : chemCtl.text,
                        chemicalDosageMl: double.tryParse(dosageCtl.text),
                        nextScheduledDate: log?.nextScheduledDate ??
                            DateTime.now().add(const Duration(days: 7)),
                      );
                      if (log != null) {
                        EngineeringStore.updateWaterLog(log.id, entry);
                      } else {
                        EngineeringStore.addWaterLog(entry);
                      }
                      Navigator.pop(ctx);
                      onChange();
                    },
                    child: Text(log == null ? 'Log Entry' : 'Update'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
