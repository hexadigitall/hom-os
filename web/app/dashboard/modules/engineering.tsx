'use client';

import { useState } from 'react';
import { Plus, Trash2, Edit3, Power, Wrench, Fuel, Zap, Droplets, Gauge, AlertTriangle, Timer } from 'lucide-react';
import {
  Generator, MaintenanceTask, TankDipLog, GridTariffConfig, WaterTreatmentLog,
  GeneratorStatus, MaintenancePriority, EquipmentType, GridBand,
} from '@/lib/types';
import {
  seedGenerators, seedMaintenance, seedTankDips, seedTariffs, seedWater,
} from '@/lib/seed';
import { useScopedCollection } from '@/lib/scoped';
import { useAuth } from '@/lib/auth';
import { hasPermission, PERMISSIONS, tagFor, type Department } from '@/lib/rbac';
import { today, nowISO, uid, naira, fmtDate, addDays } from '@/lib/format';
import { Card, MetricCard, StatusChip, SectionHeader, Btn, IconBtn, Field, TextInput, NumberInput, DateInput, Select, FormCard, FieldGrid, EmptyState } from '../ui';

type SubTab = 'dashboard' | 'generators' | 'maintenance' | 'fuel' | 'grid' | 'water';

const SUB_NAV: { id: SubTab; label: string; icon: any }[] = [
  { id: 'dashboard', label: 'Dashboard', icon: Gauge },
  { id: 'generators', label: 'Generators', icon: Power },
  { id: 'maintenance', label: 'Maintenance', icon: Wrench },
  { id: 'fuel', label: 'Fuel & Tanks', icon: Fuel },
  { id: 'grid', label: 'Grid & Cost', icon: Zap },
  { id: 'water', label: 'Water Treatment', icon: Droplets },
];

export function EngineeringModule() {
  const [tab, setTab] = useState<SubTab>('dashboard');
  return (
    <div className="space-y-4">
      <div className="flex gap-1.5 overflow-x-auto pb-1">
        {SUB_NAV.map(s => {
          const Icon = s.icon;
          return (
            <button key={s.id} onClick={() => setTab(s.id)}
              className={`px-3 py-1.5 rounded-full text-xs font-bold whitespace-nowrap flex items-center gap-1.5 ${tab === s.id ? 'bg-hom-primary text-white' : 'bg-white border text-zinc-600 hover:bg-zinc-50'}`}>
              <Icon size={13} />{s.label}
            </button>
          );
        })}
      </div>
      {tab === 'dashboard' && <EngDashboard />}
      {tab === 'generators' && <GeneratorsTab />}
      {tab === 'maintenance' && <MaintenanceTab />}
      {tab === 'fuel' && <FuelTanksTab />}
      {tab === 'grid' && <GridCostTab />}
      {tab === 'water' && <WaterTab />}
    </div>
  );
}

const DIESEL_PRICE = 1200;

function EngDashboard() {
  const { session } = useAuth();
  const gens = useScopedCollection<Generator>('eng_generators', seedGenerators, session);

  const running = gens.items.filter(g => g.status === 'running');
  const faults = gens.items.filter(g => g.status === 'fault');
  const totalCap = gens.items.reduce((a, g) => a + g.capacityKva, 0);
  const avgLoadPct = gens.items.length ? gens.items.reduce((a, g) => a + (g.capacityKva ? (g.currentLoadKva / g.capacityKva) * 100 : 0), 0) / gens.items.length : 0;
  const totalRunHours = gens.items.reduce((a, g) => a + g.currentRunHours, 0);
  const dailyFuelCost = running.reduce((a, g) => a + g.currentLoadKva * 0.8 * 24 * 0.25 * DIESEL_PRICE, 0);

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Running" value={running.length} sub="Active generators" color="bg-green-50 text-green-700" />
        <MetricCard label="Faults" value={faults.length} sub="Needs attention" color="bg-red-50 text-red-700" />
        <MetricCard label="Total Capacity" value={`${totalCap} kVA`} sub="All units" color="bg-blue-50 text-blue-700" />
        <MetricCard label="Avg Load" value={`${avgLoadPct.toFixed(0)}%`} sub="Across capacity" color="bg-amber-50 text-amber-700" />
      </div>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Run Hours" value={`${Math.round(totalRunHours)}h`} sub="Cumulative" color="bg-blue-50 text-blue-700" />
        <MetricCard label="Energy Cost / Day" value={naira(dailyFuelCost)} sub="Running units @ est. fuel" color="bg-red-50 text-red-700" />
        <MetricCard label="Load vs Capacity" value={`${avgLoadPct.toFixed(0)}%`} sub="of total kVA" color="bg-green-50 text-green-700" />
      </div>
      <Card className="overflow-hidden">
        <div className="p-4 border-b font-bold text-sm flex items-center gap-2"><Timer size={14} /> Generator Status</div>
        <div className="divide-y">
          {gens.items.map(g => (
            <div key={g.id} className="p-4 flex items-center justify-between gap-3">
              <div className="flex-1 min-w-0">
                <div className="font-bold flex items-center gap-2">{g.name} <StatusChip status={g.status} /></div>
                <div className="text-xs text-zinc-500 mt-0.5">{g.model} • {g.capacityKva} kVA • {g.currentLoadKva} kVA load • {Math.round(g.currentRunHours)}h</div>
              </div>
              <div className="h-2 w-32 bg-zinc-100 rounded-full overflow-hidden hidden md:block">
                <div className={`h-full rounded-full ${g.currentLoadKva / g.capacityKva > 0.8 ? 'bg-red-500' : 'bg-hom-primary'}`} style={{ width: `${Math.min(100, (g.currentLoadKva / g.capacityKva) * 100)}%` }} />
              </div>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}

// ─── Generators ──────────────────────────────────────────────────────────────

function GeneratorsTab() {
  const { session } = useAuth();
  const gens = useScopedCollection<Generator>('eng_generators', seedGenerators, session);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<Generator | null>(null);
  const depts = tagFor(session, 'engineering');

  return (
    <div className="space-y-4">
      <SectionHeader title={`Generators (${gens.items.length})`}>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Add Generator</Btn>
      </SectionHeader>
      <div className="grid md:grid-cols-2 gap-4">
        {gens.items.map(g => (
          <Card key={g.id} className="p-5">
            <div className="flex justify-between items-start gap-2">
              <div>
                <div className="font-black text-lg flex items-center gap-2"><Power size={16} className="text-hom-primary" /> {g.name}</div>
                <div className="text-xs text-zinc-500 mt-0.5">{g.model} • {g.capacityKva} kVA</div>
              </div>
              <StatusChip status={g.status} />
            </div>
            <div className="mt-4 grid grid-cols-3 gap-2 text-center">
              <div className="bg-zinc-50 rounded-xl p-3"><div className="font-black">{Math.round(g.currentRunHours)}h</div><div className="text-[10px] text-zinc-500">Run Hours</div></div>
              <div className="bg-zinc-50 rounded-xl p-3"><div className="font-black">{g.currentLoadKva} kVA</div><div className="text-[10px] text-zinc-500">Current Load</div></div>
              <div className="bg-zinc-50 rounded-xl p-3"><div className="font-black">{g.capacityKva ? ((g.currentLoadKva / g.capacityKva) * 100).toFixed(0) : 0}%</div><div className="text-[10px] text-zinc-500">Load %</div></div>
            </div>
            {g.lastServiceDate && <div className="text-xs text-zinc-400 mt-3">Last service: {fmtDate(g.lastServiceDate)}</div>}
            <div className="mt-4 flex gap-1.5 flex-wrap">
              {(['running', 'idle', 'maintenance', 'fault'] as GeneratorStatus[]).map(s => (
                <button key={s} onClick={() => gens.update(g.id, { status: s })}
                  className={`text-[10px] px-2 py-1 rounded-full border font-medium ${g.status === s ? 'bg-hom-primary text-white border-hom-primary' : 'hover:bg-zinc-50'}`}>{s}</button>
              ))}
              <IconBtn onClick={() => { setEditItem(g); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
              <IconBtn tone="red" onClick={() => gens.remove(g.id)}><Trash2 size={14} /></IconBtn>
            </div>
          </Card>
        ))}
        {gens.items.length === 0 && <div className="md:col-span-2"><EmptyState text="No generators" /></div>}
      </div>
      {showForm && (
        <GeneratorForm initial={editItem} depts={depts} onSave={(g) => {
          if (editItem) gens.replace(g.id, g); else gens.add(g);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
    </div>
  );
}

function GeneratorForm({ initial, depts, onSave, onCancel }: { initial: Generator | null; depts: Department[]; onSave: (g: Generator) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { name: initial.name, model: initial.model, capacityKva: String(initial.capacityKva), currentRunHours: String(initial.currentRunHours), currentLoadKva: String(initial.currentLoadKva), status: initial.status, lastServiceDate: initial.lastServiceDate || '' }
    : { name: '', model: '', capacityKva: '', currentRunHours: '0', currentLoadKva: '0', status: 'idle' as GeneratorStatus, lastServiceDate: '' });
  return (
    <FormCard title={initial ? 'Edit Generator' : 'Add Generator'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Name"><TextInput value={f.name} onChange={e => setF({ ...f, name: e.target.value })} placeholder="e.g. Main DG" /></Field>
        <Field label="Model"><TextInput value={f.model} onChange={e => setF({ ...f, model: e.target.value })} placeholder="e.g. Cat C18" /></Field>
        <Field label="Capacity (kVA)"><NumberInput value={f.capacityKva} onChange={e => setF({ ...f, capacityKva: e.target.value })} placeholder="Capacity" /></Field>
        <Field label="Current Run Hours"><NumberInput value={f.currentRunHours} onChange={e => setF({ ...f, currentRunHours: e.target.value })} placeholder="Run hours" /></Field>
        <Field label="Current Load (kVA)"><NumberInput value={f.currentLoadKva} onChange={e => setF({ ...f, currentLoadKva: e.target.value })} placeholder="Load" /></Field>
        <Field label="Last Service Date"><DateInput value={f.lastServiceDate} onChange={e => setF({ ...f, lastServiceDate: e.target.value })} /></Field>
        <Field label="Status">
          <Select value={f.status} onChange={e => setF({ ...f, status: e.target.value as GeneratorStatus })}>
            <option value="running">Running</option><option value="idle">Idle</option><option value="maintenance">Maintenance</option><option value="fault">Fault</option>
          </Select>
        </Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.name || !f.capacityKva) return alert('Name and capacity required'); onSave({ id: initial?.id || uid('eng'), ...f, capacityKva: Number(f.capacityKva), currentRunHours: Number(f.currentRunHours) || 0, currentLoadKva: Number(f.currentLoadKva) || 0, lastServiceDate: f.lastServiceDate || undefined, departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Add Generator'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Maintenance ─────────────────────────────────────────────────────────────

const PRIORITY_COLOR: Record<MaintenancePriority, string> = {
  routine: 'bg-zinc-100 text-zinc-600', important: 'bg-blue-100 text-blue-700',
  urgent: 'bg-amber-100 text-amber-700', critical: 'bg-red-100 text-red-700',
};

function MaintenanceTab() {
  const { session } = useAuth();
  const tasks = useScopedCollection<MaintenanceTask>('eng_maintenance', seedMaintenance, session);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<MaintenanceTask | null>(null);
  const [showDone, setShowDone] = useState(false);
  const depts = tagFor(session, 'engineering');

  const t = today();
  const pending = tasks.items.filter(x => !x.completed);
  const overdue = pending.filter(x => x.scheduledDate < t);
  const urgent = pending.filter(x => x.priority === 'urgent' || x.priority === 'critical');

  const visible = tasks.items.filter(x => showDone || !x.completed);

  return (
    <div className="space-y-4">
      <SectionHeader title={`Maintenance Tasks (${pending.length} pending)`}>
        <label className="flex items-center gap-1.5 text-xs font-medium text-zinc-500 cursor-pointer">
          <input type="checkbox" checked={showDone} onChange={e => setShowDone(e.target.checked)} className="accent-hom-primary" /> Show completed
        </label>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> New Task</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
        <MetricCard label="Pending" value={pending.length} sub="Not completed" color="bg-blue-50 text-blue-700" />
        <MetricCard label="Overdue" value={overdue.length} sub="Past scheduled date" color="bg-red-50 text-red-700" />
        <MetricCard label="Urgent / Critical" value={urgent.length} sub="High priority" color="bg-amber-50 text-amber-700" />
      </div>
      {showForm && (
        <TaskForm initial={editItem} depts={depts} onSave={(task) => {
          if (editItem) tasks.replace(task.id, task); else tasks.add(task);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {visible.map(task => (
            <div key={task.id} className={`p-4 flex flex-col md:flex-row md:items-center justify-between gap-3 ${task.completed ? 'opacity-50' : task.scheduledDate < today() ? 'bg-red-50/40' : ''}`}>
              <div className="flex-1 min-w-0">
                <div className="font-bold flex items-center gap-2 flex-wrap">
                  {task.equipmentName}
                  <span className={`text-[10px] px-2 py-0.5 rounded-full font-medium ${PRIORITY_COLOR[task.priority]}`}>{task.priority}</span>
                  {task.scheduledDate < today() && !task.completed && <span className="text-[10px] bg-red-500 text-white px-2 py-0.5 rounded-full flex items-center gap-1"><AlertTriangle size={10} /> OVERDUE</span>}
                </div>
                <div className="text-xs text-zinc-500 mt-0.5">{task.description || '—'} • {task.equipmentType} • {task.assignedTo} • Due {fmtDate(task.scheduledDate)}</div>
                {task.notes && <div className="text-xs text-zinc-400 mt-0.5">{task.notes}</div>}
              </div>
              <div className="flex items-center gap-2">
                <StatusChip status={task.completed ? 'completed' : 'pending'} label={task.completed ? 'Done' : 'Open'} />
                {!task.completed && (
                  <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => tasks.update(task.id, { completed: true, completedAt: nowISO() })}>Complete</Btn>
                )}
                {task.completed && (
                  <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => tasks.update(task.id, { completed: false, completedAt: undefined })}>Reopen</Btn>
                )}
                <IconBtn onClick={() => { setEditItem(task); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                <IconBtn tone="red" onClick={() => tasks.remove(task.id)}><Trash2 size={14} /></IconBtn>
              </div>
            </div>
          ))}
          {visible.length === 0 && <EmptyState text="No maintenance tasks" />}
        </div>
      </Card>
    </div>
  );
}

function TaskForm({ initial, depts, onSave, onCancel }: { initial: MaintenanceTask | null; depts: Department[]; onSave: (t: MaintenanceTask) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { equipmentName: initial.equipmentName, description: initial.description || '', assignedTo: initial.assignedTo, equipmentType: initial.equipmentType, priority: initial.priority, scheduledDate: initial.scheduledDate, notes: initial.notes || '' }
    : { equipmentName: '', description: '', assignedTo: '', equipmentType: 'generator' as EquipmentType, priority: 'routine' as MaintenancePriority, scheduledDate: today(), notes: '' });
  return (
    <FormCard title={initial ? 'Edit Task' : 'New Maintenance Task'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Equipment Name"><TextInput value={f.equipmentName} onChange={e => setF({ ...f, equipmentName: e.target.value })} placeholder="Equipment" /></Field>
        <Field label="Assigned To"><TextInput value={f.assignedTo} onChange={e => setF({ ...f, assignedTo: e.target.value })} placeholder="Assignee" /></Field>
        <Field label="Equipment Type">
          <Select value={f.equipmentType} onChange={e => setF({ ...f, equipmentType: e.target.value as EquipmentType })}>
            <option value="generator">Generator</option><option value="hvac">HVAC</option><option value="lift">Lift</option><option value="waterPump">Water Pump</option><option value="waterTreatment">Water Treatment</option><option value="electrical">Electrical</option><option value="plumbing">Plumbing</option><option value="other">Other</option>
          </Select>
        </Field>
        <Field label="Priority">
          <Select value={f.priority} onChange={e => setF({ ...f, priority: e.target.value as MaintenancePriority })}>
            <option value="routine">Routine</option><option value="important">Important</option><option value="urgent">Urgent</option><option value="critical">Critical</option>
          </Select>
        </Field>
        <Field label="Scheduled Date"><DateInput value={f.scheduledDate} onChange={e => setF({ ...f, scheduledDate: e.target.value })} /></Field>
        <Field label="Description"><TextInput value={f.description} onChange={e => setF({ ...f, description: e.target.value })} placeholder="Description" /></Field>
        <Field label="Notes" className="md:col-span-2"><TextInput value={f.notes} onChange={e => setF({ ...f, notes: e.target.value })} placeholder="Notes" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.equipmentName || !f.assignedTo) return alert('Equipment and assignee required'); onSave({ id: initial?.id || uid('eng'), ...f, completed: initial?.completed || false, scheduledDate: f.scheduledDate || today(), departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Create Task'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Fuel & Tanks ────────────────────────────────────────────────────────────

function FuelTanksTab() {
  const { session } = useAuth();
  const dips = useScopedCollection<TankDipLog>('eng_tank_dips', seedTankDips, session);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<TankDipLog | null>(null);
  const depts = tagFor(session, 'engineering');

  const thefts = dips.items.filter(d => d.expectedVolumeL != null && Math.abs(d.calculatedVolumeL - d.expectedVolumeL) > d.tankCapacityL * 0.05);
  const dieselCost = dips.items[dips.items.length - 1] ? Math.round((dips.items[dips.items.length - 1].calculatedVolumeL * DIESEL_PRICE) / 1000) * 1000 : 0;

  return (
    <div className="space-y-4">
      <SectionHeader title="Fuel & Tank Dip Readings" sub="Diesel stock reconciliation">
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Record Dip Reading</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Total Dips" value={dips.items.length} sub="Readings logged" color="bg-blue-50 text-blue-700" />
        <MetricCard label="Theft Alerts" value={thefts.length} sub=">5% variance" color="bg-red-50 text-red-700" />
        <MetricCard label="Last Volume" value={dips.items.length ? `${dips.items[0].calculatedVolumeL}L` : '—'} sub="Latest reading" color="bg-amber-50 text-amber-700" />
        <MetricCard label="Est. Diesel Cost" value={naira(dieselCost)} sub="Latest volume" color="bg-green-50 text-green-700" />
      </div>
      {thefts.length > 0 && (
        <div className="p-3 bg-red-50 border border-red-200 rounded-xl text-sm text-red-700 font-bold flex items-center gap-2">
          <AlertTriangle size={16} /> {thefts.length} tank reading(s) exceed tolerance — possible theft or gauge error
        </div>
      )}
      {showForm && (
        <DipForm initial={editItem} depts={depts} onSave={(d) => {
          if (editItem) dips.replace(d.id, d); else dips.add(d);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {dips.items.map(d => {
            const variance = d.expectedVolumeL != null ? Math.abs(d.calculatedVolumeL - d.expectedVolumeL) : 0;
            const theft = d.expectedVolumeL != null && variance > d.tankCapacityL * 0.05;
            return (
              <div key={d.id} className={`p-4 flex flex-col md:flex-row md:items-center justify-between gap-3 ${theft ? 'bg-red-50/60' : ''}`}>
                <div className="flex-1 min-w-0">
                  <div className="font-bold flex items-center gap-2">{d.tankName} <span className="text-zinc-400 font-normal text-sm">{fmtDate(d.date)}</span>
                    {theft && <span className="text-[10px] bg-red-500 text-white px-2 py-0.5 rounded-full flex items-center gap-1"><AlertTriangle size={10} /> VARIANCE</span>}
                  </div>
                  <div className="text-xs text-zinc-500 mt-0.5">Dip {d.dipReadingCm}cm • Volume {d.calculatedVolumeL}L / {d.tankCapacityL}L {d.expectedVolumeL != null && `• Expected ${d.expectedVolumeL}L`} • by {d.performedBy}</div>
                  {d.notes && <div className="text-xs text-zinc-400 mt-0.5">{d.notes}</div>}
                </div>
                <div className="flex items-center gap-2">
                  {d.expectedVolumeL != null && <span className={`text-xs font-bold ${theft ? 'text-red-600' : 'text-zinc-500'}`}>{variance}L off</span>}
                  <IconBtn onClick={() => { setEditItem(d); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                  <IconBtn tone="red" onClick={() => dips.remove(d.id)}><Trash2 size={14} /></IconBtn>
                </div>
              </div>
            );
          })}
          {dips.items.length === 0 && <EmptyState text="No dip readings recorded" />}
        </div>
      </Card>
    </div>
  );
}

function DipForm({ initial, depts, onSave, onCancel }: { initial: TankDipLog | null; depts: Department[]; onSave: (d: TankDipLog) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { date: initial.date, tankName: initial.tankName, dipReadingCm: String(initial.dipReadingCm), tankCapacityL: String(initial.tankCapacityL), calculatedVolumeL: String(initial.calculatedVolumeL), expectedVolumeL: initial.expectedVolumeL != null ? String(initial.expectedVolumeL) : '', performedBy: initial.performedBy, notes: initial.notes || '' }
    : { date: today(), tankName: 'Main Diesel Tank', dipReadingCm: '', tankCapacityL: '5000', calculatedVolumeL: '', expectedVolumeL: '', performedBy: '', notes: '' });
  const autoCalc = () => {
    const reading = Number(f.dipReadingCm) || 0;
    const capacity = Number(f.tankCapacityL) || 0;
    return Math.round((reading / 100) * capacity);
  };
  return (
    <FormCard title={initial ? 'Edit Dip Reading' : 'Record Dip Reading'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Date"><DateInput value={f.date} onChange={e => setF({ ...f, date: e.target.value })} /></Field>
        <Field label="Tank Name"><TextInput value={f.tankName} onChange={e => setF({ ...f, tankName: e.target.value })} placeholder="Tank name" /></Field>
        <Field label="Dip Reading (cm)"><NumberInput value={f.dipReadingCm} onChange={e => setF({ ...f, dipReadingCm: e.target.value, calculatedVolumeL: f.calculatedVolumeL ? f.calculatedVolumeL : String(autoCalc()) })} placeholder="cm" /></Field>
        <Field label="Tank Capacity (L)"><NumberInput value={f.tankCapacityL} onChange={e => setF({ ...f, tankCapacityL: e.target.value })} placeholder="Capacity in litres" /></Field>
        <Field label="Calculated Volume (L)"><NumberInput value={f.calculatedVolumeL} onChange={e => setF({ ...f, calculatedVolumeL: e.target.value })} placeholder="Calculated volume" /></Field>
        <Field label="Expected Volume (L)"><NumberInput value={f.expectedVolumeL} onChange={e => setF({ ...f, expectedVolumeL: e.target.value })} placeholder="Optional — for variance" /></Field>
        <Field label="Performed By"><TextInput value={f.performedBy} onChange={e => setF({ ...f, performedBy: e.target.value })} placeholder="Staff name" /></Field>
        <Field label="Notes"><TextInput value={f.notes} onChange={e => setF({ ...f, notes: e.target.value })} placeholder="Notes" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.tankName || !f.dipReadingCm) return alert('Tank name and reading required'); onSave({ id: initial?.id || uid('eng'), ...f, dipReadingCm: Number(f.dipReadingCm), tankCapacityL: Number(f.tankCapacityL) || 0, calculatedVolumeL: Number(f.calculatedVolumeL) || autoCalc(), expectedVolumeL: f.expectedVolumeL ? Number(f.expectedVolumeL) : undefined, departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Record'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Grid & Cost ─────────────────────────────────────────────────────────────

function GridCostTab() {
  const { session } = useAuth();
  const canManage = hasPermission(session, PERMISSIONS.trackGridTariffUsage);
  const tariffs = useScopedCollection<GridTariffConfig>('eng_tariffs', seedTariffs, session);
  const [editId, setEditId] = useState<string | null>(null);
  const depts = tagFor(session, 'engineering');

  return (
    <div className="space-y-4">
      <SectionHeader title="Grid Tariff Configuration" sub="PHED / utility band pricing">
        {canManage && <Btn onClick={() => setEditId('new')}><Plus size={14} /> Add Band</Btn>}
      </SectionHeader>
      <div className="grid md:grid-cols-3 gap-4">
        {tariffs.items.map(t => {
          const dailyCost = t.costPerKwh * t.hoursPerDay * 50;
          return (
            <Card key={t.id} className="p-5">
              <div className="flex justify-between items-start">
                <div>
                  <div className="font-black uppercase text-lg">Band {t.band}</div>
                  <div className="text-xs text-zinc-500">{t.label} — {t.description}</div>
                </div>
                <div className="flex gap-1">
                  {canManage && <IconBtn onClick={() => setEditId(t.id)}><Edit3 size={14} /></IconBtn>}
                  {canManage && <IconBtn tone="red" title="Delete band" onClick={() => tariffs.remove(t.id)}><Trash2 size={14} /></IconBtn>}
                </div>
              </div>
              <div className="mt-4 grid grid-cols-2 gap-2 text-center">
                <div className="bg-zinc-50 rounded-xl p-3"><div className="font-black">{t.hoursPerDay}h</div><div className="text-[10px] text-zinc-500">Supply / Day</div></div>
                <div className="bg-zinc-50 rounded-xl p-3"><div className="font-black">{naira(t.costPerKwh)}</div><div className="text-[10px] text-zinc-500">Per kWh</div></div>
              </div>
              <div className="mt-3 text-xs text-zinc-500">Est. daily cost (50 kWh usage): <span className="font-bold text-hom-primary">{naira(dailyCost)}</span></div>
            </Card>
          );
        })}
        {tariffs.items.length === 0 && <div className="md:col-span-3"><EmptyState text="No tariff bands configured" /></div>}
      </div>
      {editId && (
        <TariffForm initial={tariffs.items.find(t => t.id === editId) || null} depts={depts} onSave={(t) => {
          if (editId === 'new') tariffs.add(t); else tariffs.replace(t.id, t);
          setEditId(null);
        }} onCancel={() => setEditId(null)} />
      )}
    </div>
  );
}

function TariffForm({ initial, depts, onSave, onCancel }: { initial: GridTariffConfig | null; depts: Department[]; onSave: (t: GridTariffConfig) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { band: initial.band, hoursPerDay: String(initial.hoursPerDay), costPerKwh: String(initial.costPerKwh), label: initial.label, description: initial.description }
    : { band: 'a' as GridBand, hoursPerDay: '20', costPerKwh: '', label: '', description: '' });
  return (
    <FormCard title={initial ? `Edit Band ${initial.band}` : 'Add Tariff Band'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Band">
          <Select value={f.band} onChange={e => setF({ ...f, band: e.target.value as GridBand })}>
            <option value="a">A</option><option value="b">B</option><option value="c">C</option>
          </Select>
        </Field>
        <Field label="Hours Per Day"><NumberInput value={f.hoursPerDay} onChange={e => setF({ ...f, hoursPerDay: e.target.value })} placeholder="Hours" /></Field>
        <Field label="Cost Per kWh (₦)"><NumberInput value={f.costPerKwh} onChange={e => setF({ ...f, costPerKwh: e.target.value })} placeholder="Cost" /></Field>
        <Field label="Label"><TextInput value={f.label} onChange={e => setF({ ...f, label: e.target.value })} placeholder="e.g. Premium" /></Field>
        <Field label="Description" className="md:col-span-2"><TextInput value={f.description} onChange={e => setF({ ...f, description: e.target.value })} placeholder="e.g. Band A — 20h supply" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.costPerKwh) return alert('Cost required'); onSave({ id: initial?.id || uid('eng'), band: f.band, hoursPerDay: Number(f.hoursPerDay) || 0, costPerKwh: Number(f.costPerKwh), label: f.label, description: f.description, departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Add Band'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Water Treatment ─────────────────────────────────────────────────────────

function WaterTab() {
  const { session } = useAuth();
  const logs = useScopedCollection<WaterTreatmentLog>('eng_water', seedWater, session);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<WaterTreatmentLog | null>(null);
  const depts = tagFor(session, 'engineering');

  const outOfRange = logs.items.filter(l => l.phLevel < 6.5 || l.phLevel > 8.5);

  return (
    <div className="space-y-4">
      <SectionHeader title="Water Treatment Logs" sub="pH, chlorine & TDS monitoring">
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Add Log</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Logs" value={logs.items.length} sub="Recorded" color="bg-blue-50 text-blue-700" />
        <MetricCard label="pH Out of Range" value={outOfRange.length} sub="Outside 6.5–8.5" color="bg-red-50 text-red-700" />
        <MetricCard label="Latest pH" value={logs.items[0]?.phLevel ?? '—'} sub="Most recent reading" color="bg-green-50 text-green-700" />
        <MetricCard label="Due Next" value={logs.items.filter(l => l.nextScheduledDate && l.nextScheduledDate <= addDays(today(), 3)).length} sub="Within 3 days" color="bg-amber-50 text-amber-700" />
      </div>
      {showForm && (
        <WaterForm initial={editItem} depts={depts} onSave={(l) => {
          if (editItem) logs.replace(l.id, l); else logs.add(l);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {logs.items.map(l => {
            const badPh = l.phLevel < 6.5 || l.phLevel > 8.5;
            return (
              <div key={l.id} className={`p-4 flex flex-col md:flex-row md:items-center justify-between gap-3 ${badPh ? 'bg-red-50/50' : ''}`}>
                <div className="flex-1 min-w-0">
                  <div className="font-bold flex items-center gap-2 flex-wrap">{l.source} <span className="text-zinc-400 font-normal text-sm">{fmtDate(l.date)}</span>
                    {badPh && <span className="text-[10px] bg-red-500 text-white px-2 py-0.5 rounded-full flex items-center gap-1"><AlertTriangle size={10} /> pH OUT OF RANGE</span>}
                  </div>
                  <div className="text-xs text-zinc-500 mt-0.5">{l.treatmentAction} {l.chemicalUsed && `• ${l.chemicalUsed}${l.chemicalDosageMl != null ? ` ${l.chemicalDosageMl}ml` : ''}`} {l.performedBy && `• by ${l.performedBy}`}</div>
                  {l.nextScheduledDate && <div className="text-xs text-zinc-400 mt-0.5">Next due {fmtDate(l.nextScheduledDate)}</div>}
                </div>
                <div className="flex items-center gap-3 flex-wrap">
                  <div className="flex gap-2 text-center">
                    <div className="bg-zinc-50 rounded-lg px-3 py-1.5"><div className="font-black text-sm">pH {l.phLevel}</div></div>
                    {l.chlorineLevel != null && <div className="bg-zinc-50 rounded-lg px-3 py-1.5"><div className="font-black text-sm">Cl {l.chlorineLevel}</div></div>}
                    {l.tdsLevel != null && <div className="bg-zinc-50 rounded-lg px-3 py-1.5"><div className="font-black text-sm">TDS {l.tdsLevel}</div></div>}
                  </div>
                  <IconBtn onClick={() => { setEditItem(l); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                  <IconBtn tone="red" onClick={() => logs.remove(l.id)}><Trash2 size={14} /></IconBtn>
                </div>
              </div>
            );
          })}
          {logs.items.length === 0 && <EmptyState text="No water treatment logs" />}
        </div>
      </Card>
    </div>
  );
}

function WaterForm({ initial, depts, onSave, onCancel }: { initial: WaterTreatmentLog | null; depts: Department[]; onSave: (l: WaterTreatmentLog) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { date: initial.date, source: initial.source, treatmentAction: initial.treatmentAction, phLevel: String(initial.phLevel), chlorineLevel: initial.chlorineLevel != null ? String(initial.chlorineLevel) : '', tdsLevel: initial.tdsLevel != null ? String(initial.tdsLevel) : '', chemicalUsed: initial.chemicalUsed || '', chemicalDosageMl: initial.chemicalDosageMl != null ? String(initial.chemicalDosageMl) : '', nextScheduledDate: initial.nextScheduledDate || '', performedBy: initial.performedBy || '', notes: initial.notes || '' }
    : { date: today(), source: 'RO Plant', treatmentAction: '', phLevel: '7.0', chlorineLevel: '', tdsLevel: '', chemicalUsed: '', chemicalDosageMl: '', nextScheduledDate: '', performedBy: '', notes: '' });
  return (
    <FormCard title={initial ? 'Edit Water Log' : 'Add Water Treatment Log'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Date"><DateInput value={f.date} onChange={e => setF({ ...f, date: e.target.value })} /></Field>
        <Field label="Source"><TextInput value={f.source} onChange={e => setF({ ...f, source: e.target.value })} placeholder="e.g. RO Plant, Pool" /></Field>
        <Field label="Treatment Action"><TextInput value={f.treatmentAction} onChange={e => setF({ ...f, treatmentAction: e.target.value })} placeholder="e.g. Backwash, Chemical dosing" /></Field>
        <Field label="pH Level"><NumberInput value={f.phLevel} onChange={e => setF({ ...f, phLevel: e.target.value })} placeholder="pH" step="0.1" /></Field>
        <Field label="Chlorine Level"><NumberInput value={f.chlorineLevel} onChange={e => setF({ ...f, chlorineLevel: e.target.value })} placeholder="Chlorine (optional)" step="0.1" /></Field>
        <Field label="TDS Level"><NumberInput value={f.tdsLevel} onChange={e => setF({ ...f, tdsLevel: e.target.value })} placeholder="TDS (optional)" /></Field>
        <Field label="Chemical Used"><TextInput value={f.chemicalUsed} onChange={e => setF({ ...f, chemicalUsed: e.target.value })} placeholder="Chemical" /></Field>
        <Field label="Dosage (ml)"><NumberInput value={f.chemicalDosageMl} onChange={e => setF({ ...f, chemicalDosageMl: e.target.value })} placeholder="Dosage ml" /></Field>
        <Field label="Next Scheduled"><DateInput value={f.nextScheduledDate} onChange={e => setF({ ...f, nextScheduledDate: e.target.value })} /></Field>
        <Field label="Performed By"><TextInput value={f.performedBy} onChange={e => setF({ ...f, performedBy: e.target.value })} placeholder="Staff name" /></Field>
        <Field label="Notes" className="md:col-span-2"><TextInput value={f.notes} onChange={e => setF({ ...f, notes: e.target.value })} placeholder="Notes" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.source) return alert('Source required'); onSave({ id: initial?.id || uid('eng'), ...f, phLevel: Number(f.phLevel) || 0, chlorineLevel: f.chlorineLevel ? Number(f.chlorineLevel) : undefined, tdsLevel: f.tdsLevel ? Number(f.tdsLevel) : undefined, chemicalDosageMl: f.chemicalDosageMl ? Number(f.chemicalDosageMl) : undefined, nextScheduledDate: f.nextScheduledDate || undefined, departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Add Log'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}
