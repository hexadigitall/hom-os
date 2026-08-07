'use client';

import { useState } from 'react';
import {
  Plus, Trash2, Edit3, Download, ArrowLeft, Verified, AlertTriangle,
} from 'lucide-react';
import {
  ScumlTransaction, CashTransaction, StateTaxConfig, StateTaxReport,
  FireServiceCert, NaptipAlert, NaptipIncidentType, LgaInspection,
} from '@/lib/types';
import { SCUML_THRESHOLD } from '@/lib/types';
import { seedScuml, seedCash, seedTaxConfigs, seedTaxReports, seedFireCerts, seedNaptip, seedLga } from '@/lib/seed';
import { useSyncedCollection } from '@/lib/synced';
import { useAuth } from '@/lib/auth';
import { hasPermission, PERMISSIONS, tagFor, type Department } from '@/lib/rbac';
import { today, addDays, uid, naira, fmtDate } from '@/lib/format';
import { Card, MetricCard, StatusChip, SectionHeader, Btn, IconBtn, Field, TextInput, NumberInput, DateInput, Select, FormCard, FieldGrid, EmptyState } from '../ui';

type SubTab = 'hub' | 'cash' | 'scuml' | 'naptip' | 'lga' | 'tax' | 'fire';

type TaxConfigItem = StateTaxConfig & { id: string };
const taxConfigSeed = (): TaxConfigItem[] => seedTaxConfigs().map(c => ({ ...c, id: c.stateName }));

const SUB_NAV: { id: SubTab; label: string }[] = [
  { id: 'hub', label: 'Overview' },
  { id: 'cash', label: 'Cash' },
  { id: 'scuml', label: 'SCUML' },
  { id: 'naptip', label: 'NAPTIP' },
  { id: 'lga', label: 'LGA H&S' },
  { id: 'tax', label: 'State Tax' },
  { id: 'fire', label: 'Fire Certs' },
];

export function ComplianceModule() {
  const [tab, setTab] = useState<SubTab>('hub');

  return (
    <div className="space-y-4">
      <div className="flex gap-1.5 overflow-x-auto pb-1">
        {SUB_NAV.map(s => (
          <button key={s.id} onClick={() => setTab(s.id)}
            className={`px-3 py-1.5 rounded-full text-xs font-bold whitespace-nowrap ${tab === s.id ? 'bg-hom-primary text-white' : 'bg-white border text-zinc-600 hover:bg-zinc-50'}`}>{s.label}</button>
        ))}
      </div>
      {tab === 'hub' && <ComplianceHub onOpen={setTab} />}
      {tab === 'cash' && <CashTab />}
      {tab === 'scuml' && <ScumlTab />}
      {tab === 'naptip' && <NaptipTab />}
      {tab === 'lga' && <LgaTab />}
      {tab === 'tax' && <TaxTab />}
      {tab === 'fire' && <FireTab />}
    </div>
  );
}

function ComplianceHub({ onOpen }: { onOpen: (t: SubTab) => void }) {
  const { session } = useAuth();
  const scuml = useSyncedCollection<ScumlTransaction>('cmp_scuml', 'cmp_scuml', seedScuml, session);
  const cash = useSyncedCollection<CashTransaction>('cmp_cash', 'cmp_cash', seedCash, session);
  const tax = useSyncedCollection<TaxConfigItem>('cmp_tax_config', 'cmp_tax_config', taxConfigSeed, session);
  const naptip = useSyncedCollection<NaptipAlert>('cmp_naptip', 'cmp_naptip', seedNaptip, session);
  const lga = useSyncedCollection<LgaInspection>('cmp_lga', 'cmp_lga', seedLga, session);
  const fire = useSyncedCollection<FireServiceCert>('cmp_fire_certs', 'cmp_fire_certs', seedFireCerts, session);

  const thresholdAlerts = cash.items.filter(c => c.amount >= SCUML_THRESHOLD).length;
  const latestInspection = lga.items[0];
  const latestFire = fire.items[0];

  const tiles: { label: string; value: React.ReactNode; sub: string; color: string; onOpen: SubTab }[] = [
    { label: 'SCUML Records', value: scuml.items.length, sub: 'NSITF reporting', color: 'bg-blue-50 text-blue-700', onOpen: 'scuml' },
    { label: 'State Tax Configs', value: tax.items.length, sub: 'States configured', color: 'bg-green-50 text-green-700', onOpen: 'tax' },
    { label: 'NAPTIP Open Alerts', value: naptip.items.filter(n => n.status !== 'resolved').length, sub: 'Under investigation', color: 'bg-amber-50 text-amber-700', onOpen: 'naptip' },
    { label: 'LGA H&S Status', value: latestInspection?.status ?? 'missing', sub: latestInspection ? `Score ${latestInspection.score}/100` : 'No inspection yet', color: latestInspection?.status === 'passed' ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700', onOpen: 'lga' },
    { label: 'Cash Threshold Alerts', value: thresholdAlerts, sub: `≥ ${naira(SCUML_THRESHOLD)}`, color: thresholdAlerts > 0 ? 'bg-red-50 text-red-700' : 'bg-green-50 text-green-700', onOpen: 'cash' },
    { label: 'Fire Certificate', value: latestFire?.status ?? 'missing', sub: latestFire ? `${latestFire.certificateNumber} • ${fmtDate(latestFire.expiryDate)}` : 'No certificate', color: latestFire?.status === 'valid' ? 'bg-green-50 text-green-700' : latestFire?.status === 'expired' ? 'bg-red-50 text-red-700' : 'bg-amber-50 text-amber-700', onOpen: 'fire' },
  ];

  return (
    <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
      {tiles.map((t, i) => (
        <button key={i} onClick={() => onOpen(t.onOpen)} className="text-left">
          <MetricCard label={t.label} value={String(t.value)} sub={t.sub} color={t.color} />
        </button>
      ))}
    </div>
  );
}

// ─── Cash Transactions ───────────────────────────────────────────────────────

function CashTab() {
  const { session } = useAuth();
  const cash = useSyncedCollection<CashTransaction>('cmp_cash', 'cmp_cash', seedCash, session);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<CashTransaction | null>(null);
  const depts = tagFor(session, 'accounts');

  return (
    <div className="space-y-4">
      <SectionHeader title={`Cash Transactions (${cash.items.length})`} sub={`Flagged threshold: ${naira(SCUML_THRESHOLD)}`}>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Record Cash</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Total Cash Volume" value={naira(cash.items.reduce((a, c) => a + c.amount, 0))} sub={`${cash.items.length} transactions`} color="bg-blue-50 text-blue-700" />
        <MetricCard label="Above Threshold" value={cash.items.filter(c => c.amount >= SCUML_THRESHOLD).length} sub="Require SCUML reporting" color="bg-red-50 text-red-700" />
        <MetricCard label="Flagged" value={cash.items.filter(c => c.flagged).length} sub="Manually flagged" color="bg-amber-50 text-amber-700" />
      </div>
      {showForm && (
        <CashForm initial={editItem} depts={depts} onSave={(c) => {
          if (editItem) cash.replace(c.id, c); else cash.add(c);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {cash.items.map(c => {
            const over = c.amount >= SCUML_THRESHOLD;
            return (
              <div key={c.id} className={`p-4 flex flex-col md:flex-row md:items-center justify-between gap-3 ${over || c.flagged ? 'bg-red-50/50' : ''}`}>
                <div className="flex-1 min-w-0">
                  <div className="font-bold flex items-center gap-2 flex-wrap">{c.guestName} <span className="text-zinc-400 font-normal text-sm">{naira(c.amount)}</span>
                    {(over || c.flagged) && <span className="text-[10px] bg-red-500 text-white px-2 py-0.5 rounded-full flex items-center gap-1"><AlertTriangle size={10} /> THRESHOLD</span>}
                  </div>
                  <div className="text-xs text-zinc-500 mt-0.5">{fmtDate(c.date)} • {c.paymentMethod.toUpperCase()} • Receipt {c.receiptNumber} • {c.purpose}</div>
                  {over && (
                    <div className="mt-2 flex items-center gap-2 text-[10px]">
                      <div className="h-1.5 flex-1 max-w-xs bg-zinc-100 rounded-full overflow-hidden">
                        <div className="h-full bg-red-500 rounded-full" style={{ width: `${Math.min(100, (c.amount / SCUML_THRESHOLD) * 100)}%` }} />
                      </div>
                      <span className="text-zinc-400">{((c.amount / SCUML_THRESHOLD) * 100).toFixed(0)}% of threshold</span>
                    </div>
                  )}
                </div>
                <div className="flex items-center gap-2">
                  <StatusChip status={c.paymentMethod} />
                  <IconBtn onClick={() => { setEditItem(c); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                  <IconBtn tone="red" onClick={() => cash.remove(c.id)}><Trash2 size={14} /></IconBtn>
                </div>
              </div>
            );
          })}
          {cash.items.length === 0 && <EmptyState text="No cash transactions" />}
        </div>
      </Card>
    </div>
  );
}

function CashForm({ initial, depts, onSave, onCancel }: { initial: CashTransaction | null; depts: Department[]; onSave: (c: CashTransaction) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { date: initial.date, guestName: initial.guestName, receiptNumber: initial.receiptNumber, paymentMethod: initial.paymentMethod, amount: String(initial.amount), purpose: initial.purpose, flagged: initial.flagged }
    : { date: today(), guestName: '', receiptNumber: '', paymentMethod: 'cash', amount: '', purpose: '', flagged: false });
  return (
    <FormCard title={initial ? 'Edit Cash Transaction' : 'Record Cash Transaction'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Guest / Payer"><TextInput value={f.guestName} onChange={e => setF({ ...f, guestName: e.target.value })} placeholder="Guest / Payer name" /></Field>
        <Field label="Receipt Number"><TextInput value={f.receiptNumber} onChange={e => setF({ ...f, receiptNumber: e.target.value })} placeholder="Receipt number" /></Field>
        <Field label="Payment Method">
          <Select value={f.paymentMethod} onChange={e => setF({ ...f, paymentMethod: e.target.value as any })}>
            <option value="cash">CASH</option><option value="pos">POS</option><option value="transfer">TRANSFER</option>
          </Select>
        </Field>
        <Field label="Amount (₦)"><NumberInput value={f.amount} onChange={e => setF({ ...f, amount: e.target.value })} placeholder="Amount" /></Field>
        <Field label="Purpose"><TextInput value={f.purpose} onChange={e => setF({ ...f, purpose: e.target.value })} placeholder="Purpose" /></Field>
        <Field label="Date"><DateInput value={f.date} onChange={e => setF({ ...f, date: e.target.value })} /></Field>
      </FieldGrid>
      <label className="flex items-center gap-2 mt-3 text-sm cursor-pointer">
        <input type="checkbox" checked={f.flagged} onChange={e => setF({ ...f, flagged: e.target.checked })} className="accent-hom-primary w-4 h-4" />
        Flag for SCUML reporting
      </label>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.guestName || !f.amount) return alert('Guest name and amount required'); onSave({ id: initial?.id || uid('cmp'), createdAt: initial ? initial.createdAt : new Date().toISOString(), ...f, amount: Number(f.amount), paymentMethod: f.paymentMethod as CashTransaction['paymentMethod'], departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Record'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── SCUML ───────────────────────────────────────────────────────────────────

function ScumlTab() {
  const { session } = useAuth();
  const scuml = useSyncedCollection<ScumlTransaction>('cmp_scuml', 'cmp_scuml', seedScuml, session);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<ScumlTransaction | null>(null);
  const depts = tagFor(session, 'accounts');

  const exportCsv = () => {
    const rows = [
      ['Date', 'Guest Name', 'Address', 'ID Type', 'ID Number', 'Amount (₦)', 'Purpose'],
      ...scuml.items.map(s => [s.date, s.guestName, s.address, s.idType, s.idNumber, String(s.amount), s.purpose]),
    ];
    const blob = new Blob([rows.map(r => r.join(',')).join('\n')], { type: 'text/csv' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = 'hom_scuml_report.csv';
    a.click();
  };

  return (
    <div className="space-y-4">
      <SectionHeader title={`SCUML Transactions (${scuml.items.length})`} sub="Large cash transactions for SCUML/NSITF filing">
        <Btn color="outline" onClick={exportCsv}><Download size={14} /> Export CSV</Btn>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Add Transaction</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Total Value" value={naira(scuml.items.reduce((a, s) => a + s.amount, 0))} sub="All records" color="bg-blue-50 text-blue-700" />
        <MetricCard label="Submitted" value={scuml.items.filter(s => s.submittedToScuml).length} sub="Filed to SCUML" color="bg-green-50 text-green-700" />
        <MetricCard label="Pending Filing" value={scuml.items.filter(s => !s.submittedToScuml).length} sub="Not yet submitted" color="bg-amber-50 text-amber-700" />
      </div>
      {showForm && (
        <ScumlForm initial={editItem} depts={depts} onSave={(s) => {
          if (editItem) scuml.replace(s.id, s); else scuml.add(s);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {scuml.items.map(s => (
            <div key={s.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
              <div className="flex-1 min-w-0">
                <div className="font-bold flex items-center gap-2 flex-wrap">{s.guestName} <span className="text-zinc-400 font-normal text-sm">{naira(s.amount)}</span></div>
                <div className="text-xs text-zinc-500 mt-0.5">{fmtDate(s.date)} • {s.idType} {s.idNumber} • {s.address}</div>
                <div className="text-xs text-zinc-400 mt-0.5">{s.purpose}</div>
              </div>
              <div className="flex items-center gap-2">
                <button onClick={() => scuml.update(s.id, { submittedToScuml: !s.submittedToScuml, submittedDate: !s.submittedToScuml ? today() : undefined })} className={`text-[10px] px-2 py-1 rounded-full font-medium ${s.submittedToScuml ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-700'}`}>{s.submittedToScuml ? 'Submitted' : 'Mark Submitted'}</button>
                <IconBtn onClick={() => { setEditItem(s); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                <IconBtn tone="red" onClick={() => scuml.remove(s.id)}><Trash2 size={14} /></IconBtn>
              </div>
            </div>
          ))}
          {scuml.items.length === 0 && <EmptyState text="No SCUML transactions yet" />}
        </div>
      </Card>
    </div>
  );
}

function ScumlForm({ initial, depts, onSave, onCancel }: { initial: ScumlTransaction | null; depts: Department[]; onSave: (s: ScumlTransaction) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { date: initial.date, guestName: initial.guestName, address: initial.address, idType: initial.idType, idNumber: initial.idNumber, amount: String(initial.amount), purpose: initial.purpose }
    : { date: today(), guestName: '', address: '', idType: 'National ID', idNumber: '', amount: '', purpose: '' });
  return (
    <FormCard title={initial ? 'Edit SCUML Transaction' : 'Add SCUML Transaction'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Guest Name"><TextInput value={f.guestName} onChange={e => setF({ ...f, guestName: e.target.value })} placeholder="Guest name" /></Field>
        <Field label="Address"><TextInput value={f.address} onChange={e => setF({ ...f, address: e.target.value })} placeholder="Address" /></Field>
        <Field label="ID Type">
          <Select value={f.idType} onChange={e => setF({ ...f, idType: e.target.value })}>
            <option>National ID</option><option>Passport</option><option>Driver's License</option><option>Voter's Card</option>
          </Select>
        </Field>
        <Field label="ID Number"><TextInput value={f.idNumber} onChange={e => setF({ ...f, idNumber: e.target.value })} placeholder="ID number" /></Field>
        <Field label="Amount (₦)"><NumberInput value={f.amount} onChange={e => setF({ ...f, amount: e.target.value })} placeholder="Amount" /></Field>
        <Field label="Purpose"><TextInput value={f.purpose} onChange={e => setF({ ...f, purpose: e.target.value })} placeholder="Purpose" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.guestName || !f.amount) return alert('Guest name and amount required'); onSave({ id: initial?.id || uid('cmp'), createdAt: initial ? initial.createdAt : new Date().toISOString(), submittedToScuml: initial?.submittedToScuml || false, ...f, amount: Number(f.amount), departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Add'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── NAPTIP ──────────────────────────────────────────────────────────────────

const NAPTIP_TYPES: { id: NaptipIncidentType; label: string }[] = [
  { id: 'humanTrafficking', label: 'Human Trafficking' },
  { id: 'forcedLabour', label: 'Forced Labour' },
  { id: 'childLabour', label: 'Child Labour' },
  { id: 'exploitation', label: 'Exploitation' },
  { id: 'other', label: 'Other' },
];

function NaptipTab() {
  const { session } = useAuth();
  const naptip = useSyncedCollection<NaptipAlert>('cmp_naptip', 'cmp_naptip', seedNaptip, session);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<NaptipAlert | null>(null);
  const depts = tagFor(session, 'humanResources');

  return (
    <div className="space-y-4">
      <SectionHeader title={`NAPTIP Alerts (${naptip.items.length})`} sub="Human trafficking & exploitation reporting">
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> New Alert</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Open" value={naptip.items.filter(n => n.status === 'pending').length} sub="Pending review" color="bg-red-50 text-red-700" />
        <MetricCard label="Investigating" value={naptip.items.filter(n => n.status === 'investigated').length} sub="Under investigation" color="bg-amber-50 text-amber-700" />
        <MetricCard label="Resolved" value={naptip.items.filter(n => n.status === 'resolved').length} sub="Closed out" color="bg-green-50 text-green-700" />
      </div>
      {showForm && (
        <NaptipForm initial={editItem} depts={depts} onSave={(n) => {
          if (editItem) naptip.replace(n.id, n); else naptip.add(n);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {naptip.items.map(n => (
            <div key={n.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
              <div className="flex-1 min-w-0">
                <div className="font-bold">{NAPTIP_TYPES.find(t => t.id === n.type)?.label || n.type}</div>
                <div className="text-xs text-zinc-500 mt-0.5">{fmtDate(n.date)} • {n.description}</div>
                <div className="text-xs text-zinc-400 mt-0.5">Action: {n.actionTaken || '—'} • Reported to: {n.reportedTo}</div>
              </div>
              <div className="flex items-center gap-2">
                <StatusChip status={n.status === 'investigated' ? 'investigating' : n.status} />
                {n.status !== 'resolved' && (
                  <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => naptip.update(n.id, { status: n.status === 'pending' ? 'investigated' : 'resolved' })}>
                    {n.status === 'pending' ? 'Mark Investigating' : 'Resolve'}
                  </Btn>
                )}
                <IconBtn onClick={() => { setEditItem(n); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                <IconBtn tone="red" onClick={() => naptip.remove(n.id)}><Trash2 size={14} /></IconBtn>
              </div>
            </div>
          ))}
          {naptip.items.length === 0 && <EmptyState text="No NAPTIP alerts" />}
        </div>
      </Card>
    </div>
  );
}

function NaptipForm({ initial, depts, onSave, onCancel }: { initial: NaptipAlert | null; depts: Department[]; onSave: (n: NaptipAlert) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { date: initial.date, type: initial.type, description: initial.description, actionTaken: initial.actionTaken, reportedTo: initial.reportedTo }
    : { date: today(), type: 'other' as NaptipIncidentType, description: '', actionTaken: '', reportedTo: '' });
  return (
    <FormCard title={initial ? 'Edit NAPTIP Alert' : 'New NAPTIP Alert'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Date"><DateInput value={f.date} onChange={e => setF({ ...f, date: e.target.value })} /></Field>
        <Field label="Incident Type">
          <Select value={f.type} onChange={e => setF({ ...f, type: e.target.value as NaptipIncidentType })}>
            {NAPTIP_TYPES.map(t => <option key={t.id} value={t.id}>{t.label}</option>)}
          </Select>
        </Field>
        <Field label="Description"><TextInput value={f.description} onChange={e => setF({ ...f, description: e.target.value })} placeholder="Incident description" /></Field>
        <Field label="Reported To"><TextInput value={f.reportedTo} onChange={e => setF({ ...f, reportedTo: e.target.value })} placeholder="NAPTIP office" /></Field>
        <Field label="Action Taken" className="md:col-span-2"><TextInput value={f.actionTaken} onChange={e => setF({ ...f, actionTaken: e.target.value })} placeholder="Action taken" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.description) return alert('Description required'); onSave({ id: initial?.id || uid('cmp'), status: initial?.status || 'pending', ...f, departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Add'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── LGA H&S ─────────────────────────────────────────────────────────────────

function LgaTab() {
  const { session } = useAuth();
  const lga = useSyncedCollection<LgaInspection>('cmp_lga', 'cmp_lga', seedLga, session);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<LgaInspection | null>(null);
  const depts = tagFor(session, 'healthSafety');

  return (
    <div className="space-y-4">
      <SectionHeader title={`LGA H&S Inspections (${lga.items.length})`} sub="Local government health & safety permits">
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Add Inspection</Btn>
      </SectionHeader>
      {showForm && (
        <LgaForm initial={editItem} depts={depts} onSave={(i) => {
          if (editItem) lga.replace(i.id, i); else lga.add(i);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <div className="grid md:grid-cols-2 gap-4">
        {lga.items.map(i => (
          <Card key={i.id} className="p-5">
            <div className="flex justify-between items-start gap-2">
              <div>
                <div className="font-bold">{i.agency}</div>
                <div className="text-xs text-zinc-500 mt-0.5">Cert {i.certificateNumber} • Inspected {fmtDate(i.inspectionDate)} by {i.inspector}</div>
              </div>
              <div className="flex items-center gap-2">
                <StatusChip status={i.status} />
                <span className={`text-[10px] px-2 py-0.5 rounded-full font-medium ${i.score >= 80 ? 'bg-green-100 text-green-700' : i.score >= 60 ? 'bg-amber-100 text-amber-700' : 'bg-red-100 text-red-700'}`}>Score {i.score}</span>
              </div>
            </div>
            {i.expiryDate && <div className="text-xs text-zinc-500 mt-2">Expires {fmtDate(i.expiryDate)}</div>}
            {i.failedItems.length > 0 && (
              <div className="mt-3 text-xs text-red-600 bg-red-50 rounded-xl p-3">Failed: {i.failedItems.join(', ')}</div>
            )}
            <div className="mt-3 flex gap-1.5">
              <IconBtn onClick={() => { setEditItem(i); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
              <IconBtn tone="red" onClick={() => lga.remove(i.id)}><Trash2 size={14} /></IconBtn>
            </div>
          </Card>
        ))}
        {lga.items.length === 0 && <EmptyState text="No inspections recorded" />}
      </div>
    </div>
  );
}

function LgaForm({ initial, depts, onSave, onCancel }: { initial: LgaInspection | null; depts: Department[]; onSave: (i: LgaInspection) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { inspectionDate: initial.inspectionDate, inspector: initial.inspector, agency: initial.agency, certificateNumber: initial.certificateNumber, expiryDate: initial.expiryDate || '', score: String(initial.score), status: initial.status, passedItems: initial.passedItems.join(', '), failedItems: initial.failedItems.join(', ') }
    : { inspectionDate: today(), inspector: '', agency: '', certificateNumber: '', expiryDate: '', score: '0', status: 'passed', passedItems: '', failedItems: '' });
  return (
    <FormCard title={initial ? 'Edit Inspection' : 'Add Inspection'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Inspection Date"><DateInput value={f.inspectionDate} onChange={e => setF({ ...f, inspectionDate: e.target.value })} /></Field>
        <Field label="Inspector"><TextInput value={f.inspector} onChange={e => setF({ ...f, inspector: e.target.value })} placeholder="Inspector" /></Field>
        <Field label="Agency"><TextInput value={f.agency} onChange={e => setF({ ...f, agency: e.target.value })} placeholder="Health & safety agency" /></Field>
        <Field label="Certificate Number"><TextInput value={f.certificateNumber} onChange={e => setF({ ...f, certificateNumber: e.target.value })} placeholder="Cert number" /></Field>
        <Field label="Expiry Date"><DateInput value={f.expiryDate} onChange={e => setF({ ...f, expiryDate: e.target.value })} /></Field>
        <Field label="Score (0-100)"><NumberInput value={f.score} onChange={e => setF({ ...f, score: e.target.value })} placeholder="Score" /></Field>
        <Field label="Status">
          <Select value={f.status} onChange={e => setF({ ...f, status: e.target.value })}>
            <option value="passed">Passed</option><option value="pending">Pending</option><option value="failed">Failed</option>
          </Select>
        </Field>
        <Field label="Passed Items"><TextInput value={f.passedItems} onChange={e => setF({ ...f, passedItems: e.target.value })} placeholder="Comma-separated" /></Field>
        <Field label="Failed Items" className="md:col-span-2"><TextInput value={f.failedItems} onChange={e => setF({ ...f, failedItems: e.target.value })} placeholder="Comma-separated" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.agency) return alert('Agency required'); onSave({ id: initial?.id || uid('cmp'), ...f, score: Number(f.score) || 0, passedItems: f.passedItems ? f.passedItems.split(',').map(s => s.trim()).filter(Boolean) : [], failedItems: f.failedItems ? f.failedItems.split(',').map(s => s.trim()).filter(Boolean) : [], departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Add'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── State Tax ───────────────────────────────────────────────────────────────

function TaxTab() {
  const { session } = useAuth();
  const canManage = hasPermission(session, PERMISSIONS.manageTaxConfig);
  const tax = useSyncedCollection<TaxConfigItem>('cmp_tax_config', 'cmp_tax_config', taxConfigSeed, session);
  const reports = useSyncedCollection<StateTaxReport>('cmp_tax_reports', 'cmp_tax_reports', seedTaxReports, session);
  const [editState, setEditState] = useState<string | null>(null);
  const [creating, setCreating] = useState(false);
  const [showReport, setShowReport] = useState<string | null>(null);
  const depts = tagFor(session, 'accounts');

  const generateReport = (stateName: string) => {
    const cfg = tax.items.find(t => t.stateName === stateName);
    if (!cfg) return;
    const totalSales = 5000000 + Math.round(Math.random() * 4000000);
    const taxDue = totalSales * (cfg.rate / 100);
    const start = new Date(); start.setDate(1);
    const end = new Date(start.getFullYear(), start.getMonth() + 1, 0);
    reports.add({ id: uid('cmp'), stateName, rate: cfg.rate, totalSales, taxDue, periodStart: start.toISOString().slice(0, 10), periodEnd: end.toISOString().slice(0, 10), status: 'pending', departments: depts });
    setShowReport(null);
  };

  return (
    <div className="space-y-4">
      <SectionHeader title="State Consumption Tax" sub="Configure state sales tax rates">
        {canManage && <Btn color="outline" onClick={() => reports.set([])}>Clear Reports</Btn>}
        {canManage && <Btn onClick={() => setCreating(true)}><Plus size={14} /> Add State</Btn>}
      </SectionHeader>
      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
        {tax.items.map(cfg => (
          <Card key={cfg.id} className="p-5">
            <div className="flex justify-between items-start gap-2">
              <div>
                <div className="font-bold">{cfg.stateName}</div>
                <div className="text-3xl font-black text-hom-primary mt-1">{cfg.rate}%</div>
                <div className="text-xs text-zinc-500 mt-1">{cfg.appliesToOtherServices ? 'Applies to other services' : 'Standard goods'}</div>
              </div>
              <div className="flex gap-1">
                {canManage && <IconBtn onClick={() => setEditState(cfg.stateName)}><Edit3 size={14} /></IconBtn>}
                {canManage && <IconBtn tone="red" title="Delete config" onClick={() => tax.remove(cfg.id)}><Trash2 size={14} /></IconBtn>}
              </div>
            </div>
            <div className="mt-3 flex gap-2">
              <Btn color="amber" className="!px-3 !py-1.5 !text-[11px]" onClick={() => setShowReport(cfg.stateName)}>Generate Report</Btn>
            </div>
          </Card>
        ))}
      </div>

      {editState && (
        <TaxConfigForm initial={tax.items.find(t => t.stateName === editState)!} depts={depts} onSave={(c) => {
          tax.replace(c.id, c);
          setEditState(null);
        }} onCancel={() => setEditState(null)} />
      )}

      {creating && canManage && (
        <TaxConfigForm initial={null} depts={depts} onSave={(c) => {
          if (tax.items.some(t => t.stateName === c.stateName)) return alert(`${c.stateName} already configured`);
          tax.add(c);
          setCreating(false);
        }} onCancel={() => setCreating(false)} />
      )}

      {showReport && (
        <Card className="p-6">
          <h3 className="font-bold mb-3">Generate {showReport} tax report?</h3>
          <div className="flex gap-2">
            <Btn color="amber" onClick={() => generateReport(showReport)}>Generate</Btn>
            <Btn color="outline" onClick={() => setShowReport(null)}>Cancel</Btn>
          </div>
        </Card>
      )}

      {reports.items.length > 0 && (
        <Card className="overflow-hidden">
          <div className="p-4 border-b font-bold text-sm">Tax Reports</div>
          <div className="divide-y">
            {reports.items.map(r => {
              const next = r.status === 'pending' ? 'filed' : r.status === 'filed' ? 'paid' : null;
              return (
                <div key={r.id} className="p-3 flex flex-col md:flex-row md:items-center justify-between gap-2 text-sm">
                  <div className="min-w-0"><span className="font-medium">{r.stateName}</span> <span className="text-zinc-400 text-xs">• {r.periodStart} → {r.periodEnd} • {r.rate}%</span></div>
                  <div className="flex items-center gap-2">
                    <span className="font-bold">{naira(r.taxDue)}</span>
                    <StatusChip status={r.status} />
                    {canManage && next && (
                      <Btn color="outline" className="!px-2.5 !py-1 !text-[10px]" onClick={() => reports.update(r.id, { status: next })}>Mark {next[0].toUpperCase() + next.slice(1)}</Btn>
                    )}
                    {canManage && <IconBtn tone="red" title="Delete report" onClick={() => reports.remove(r.id)}><Trash2 size={13} /></IconBtn>}
                  </div>
                </div>
              );
            })}
          </div>
        </Card>
      )}
    </div>
  );
}

function TaxConfigForm({ initial, depts, onSave, onCancel }: { initial: TaxConfigItem | null; depts: Department[]; onSave: (c: TaxConfigItem) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { stateName: initial.stateName, rate: String(initial.rate), appliesToOtherServices: initial.appliesToOtherServices }
    : { stateName: '', rate: '7.5', appliesToOtherServices: false });
  return (
    <FormCard title={initial ? `Edit ${initial.stateName} Tax Config` : 'Add State Tax Config'} onCancel={onCancel}>
      <div className="grid md:grid-cols-3 gap-3">
        <Field label="State Name">{initial ? <div className="px-3 py-2 bg-zinc-50 rounded-xl text-sm font-medium">{initial.stateName}</div> : <TextInput value={f.stateName} onChange={e => setF({ ...f, stateName: e.target.value })} placeholder="e.g. Lagos" />}</Field>
        <Field label="Rate (%)"><NumberInput value={f.rate} onChange={e => setF({ ...f, rate: e.target.value })} placeholder="Rate" step="0.5" /></Field>
        <label className="flex items-center gap-2 text-sm cursor-pointer pt-6">
          <input type="checkbox" checked={f.appliesToOtherServices} onChange={e => setF({ ...f, appliesToOtherServices: e.target.checked })} className="accent-hom-primary w-4 h-4" />
          Applies to other services
        </label>
      </div>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => {
          if (!f.stateName.trim()) return alert('State name required');
          onSave(initial
            ? { ...initial, rate: Number(f.rate) || 0, appliesToOtherServices: f.appliesToOtherServices }
            : { id: f.stateName.trim(), stateName: f.stateName.trim(), rate: Number(f.rate) || 0, appliesToOtherServices: f.appliesToOtherServices, departments: depts });
        }}>{initial ? 'Save' : 'Add State'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Fire Certificates ───────────────────────────────────────────────────────

function FireTab() {
  const { session } = useAuth();
  const fire = useSyncedCollection<FireServiceCert>('cmp_fire_certs', 'cmp_fire_certs', seedFireCerts, session);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<FireServiceCert | null>(null);
  const depts = tagFor(session, 'healthSafety');

  const statusOf = (c: FireServiceCert) => {
    if (c.expiryDate < today()) return 'expired';
    if (addDays(c.expiryDate, -30) <= today()) return 'pending-renewal';
    return c.status;
  };

  return (
    <div className="space-y-4">
      <SectionHeader title={`Fire Service Certificates (${fire.items.length})`} sub="Fire safety certification & renewals">
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Add Certificate</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Valid" value={fire.items.filter(c => statusOf(c) === 'valid').length} sub="In good standing" color="bg-green-50 text-green-700" />
        <MetricCard label="Renewal Due" value={fire.items.filter(c => statusOf(c) === 'pending-renewal').length} sub="Within 30 days" color="bg-amber-50 text-amber-700" />
        <MetricCard label="Expired" value={fire.items.filter(c => statusOf(c) === 'expired').length} sub="Needs immediate action" color="bg-red-50 text-red-700" />
      </div>
      {showForm && (
        <FireForm initial={editItem} depts={depts} onSave={(c) => {
          if (editItem) fire.replace(c.id, c); else fire.add(c);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {fire.items.map(c => {
            const st = statusOf(c);
            return (
              <div key={c.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
                <div className="flex-1 min-w-0">
                  <div className="font-bold flex items-center gap-2 flex-wrap"><Verified size={16} className="text-hom-primary" /> {c.certificateNumber} <span className="text-zinc-400 font-normal text-sm">{c.fireServiceOffice}</span></div>
                  <div className="text-xs text-zinc-500 mt-0.5">Issued {fmtDate(c.issueDate)} • Expires {fmtDate(c.expiryDate)}{c.inspectionScore != null && ` • Score ${c.inspectionScore}/100`}</div>
                </div>
                <div className="flex items-center gap-2">
                  <StatusChip status={st} />
                  <IconBtn onClick={() => { setEditItem(c); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                  <IconBtn tone="red" onClick={() => fire.remove(c.id)}><Trash2 size={14} /></IconBtn>
                </div>
              </div>
            );
          })}
          {fire.items.length === 0 && <EmptyState text="No fire certificates" />}
        </div>
      </Card>
    </div>
  );
}

function FireForm({ initial, depts, onSave, onCancel }: { initial: FireServiceCert | null; depts: Department[]; onSave: (c: FireServiceCert) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { certificateNumber: initial.certificateNumber, issueDate: initial.issueDate, expiryDate: initial.expiryDate, fireServiceOffice: initial.fireServiceOffice, status: initial.status, inspectionScore: initial.inspectionScore != null ? String(initial.inspectionScore) : '' }
    : { certificateNumber: '', issueDate: today(), expiryDate: addDays(today(), 365), fireServiceOffice: '', status: 'pending-renewal', inspectionScore: '' });
  return (
    <FormCard title={initial ? 'Edit Certificate' : 'Add Certificate'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Certificate Number"><TextInput value={f.certificateNumber} onChange={e => setF({ ...f, certificateNumber: e.target.value })} placeholder="Certificate number" /></Field>
        <Field label="Fire Service Office"><TextInput value={f.fireServiceOffice} onChange={e => setF({ ...f, fireServiceOffice: e.target.value })} placeholder="Fire service office" /></Field>
        <Field label="Issue Date"><DateInput value={f.issueDate} onChange={e => setF({ ...f, issueDate: e.target.value })} /></Field>
        <Field label="Expiry Date"><DateInput value={f.expiryDate} onChange={e => setF({ ...f, expiryDate: e.target.value })} /></Field>
        <Field label="Status">
          <Select value={f.status} onChange={e => setF({ ...f, status: e.target.value as any })}>
            <option value="valid">Valid</option><option value="pending-renewal">Pending Renewal</option><option value="expired">Expired</option>
          </Select>
        </Field>
        <Field label="Inspection Score"><NumberInput value={f.inspectionScore} onChange={e => setF({ ...f, inspectionScore: e.target.value })} placeholder="Score (optional)" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.certificateNumber) return alert('Certificate number required'); onSave({ id: initial?.id || uid('cmp'), ...f, inspectionScore: f.inspectionScore ? Number(f.inspectionScore) : undefined, departments: initial?.departments || depts } as FireServiceCert); }}>{initial ? 'Update' : 'Add'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}
