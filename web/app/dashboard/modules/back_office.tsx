'use client';

import { useState } from 'react';
import { Plus, Trash2, Edit3, Check, FileText, Wallet, Percent } from 'lucide-react';
import {
  ProcurementOrder, PayrollRecord, TaxConfiguration,
  ProcurementStatus,
} from '@/lib/types';
import { seedProcurements, seedPayrolls, seedTaxConfig } from '@/lib/seed';
import { useCollection, useKeyValue } from '@/lib/storage';
import { today, nowISO, uid, naira, fmtDate, monthStart, monthEnd } from '@/lib/format';
import { Card, MetricCard, StatusChip, SectionHeader, Btn, IconBtn, Field, TextInput, NumberInput, DateInput, Select, FormCard, FieldGrid, EmptyState, paye, pension, netPay } from '../ui';

type SubTab = 'procurement' | 'payroll' | 'taxconfig';

const SUB_NAV: { id: SubTab; label: string; icon: any }[] = [
  { id: 'procurement', label: 'Procurement', icon: FileText },
  { id: 'payroll', label: 'Payroll', icon: Wallet },
  { id: 'taxconfig', label: 'Tax Config', icon: Percent },
];

export function BackOfficeModule() {
  const [tab, setTab] = useState<SubTab>('procurement');
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
      {tab === 'procurement' && <ProcurementTab />}
      {tab === 'payroll' && <PayrollTab />}
      {tab === 'taxconfig' && <TaxConfigTab />}
    </div>
  );
}

// ─── Procurement ─────────────────────────────────────────────────────────────

const PROC_NEXT: Record<ProcurementStatus, ProcurementStatus | null> = {
  draft: 'approved', approved: 'ordered', ordered: 'delivered', delivered: null, cancelled: null,
};
const PROC_ORDER: ProcurementStatus[] = ['draft', 'approved', 'ordered', 'delivered'];

function ProcurementTab() {
  const orders = useCollection<ProcurementOrder>('bo_procurement', seedProcurements);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<ProcurementOrder | null>(null);

  const totalValue = orders.items.reduce((a, o) => a + o.amount, 0);
  const inFlight = orders.items.filter(o => o.status !== 'delivered' && o.status !== 'cancelled').length;
  const deliveredValue = orders.items.filter(o => o.status === 'delivered').reduce((a, o) => a + o.amount, 0);

  return (
    <div className="space-y-4">
      <SectionHeader title={`Procurement (${orders.items.length} orders)`}>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> New Order</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Total Value" value={naira(totalValue)} sub="All orders" color="bg-blue-50 text-blue-700" />
        <MetricCard label="In Flight" value={inFlight} sub="Not yet delivered" color="bg-amber-50 text-amber-700" />
        <MetricCard label="Delivered" value={naira(deliveredValue)} sub="Received value" color="bg-green-50 text-green-700" />
        <MetricCard label="Cancelled" value={orders.items.filter(o => o.status === 'cancelled').length} sub="Orders" color="bg-red-50 text-red-700" />
      </div>
      {showForm && (
        <OrderForm initial={editItem} onSave={(o) => {
          if (editItem) orders.replace(o.id, o); else orders.add(o);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {orders.items.map(o => {
            const next = PROC_NEXT[o.status];
            return (
              <div key={o.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
                <div className="flex-1 min-w-0">
                  <div className="font-bold flex items-center gap-2 flex-wrap">{o.items} <span className="text-zinc-400 font-normal text-sm">{o.vendorName}</span></div>
                  <div className="text-xs text-zinc-500 mt-0.5">Ordered {fmtDate(o.orderDate)} {o.deliveryDate && `• Delivered ${fmtDate(o.deliveryDate)}`} {o.notes && `• ${o.notes}`}</div>
                  <div className="flex items-center gap-1 mt-1.5">
                    {PROC_ORDER.map((s, i) => {
                      const reached = PROC_ORDER.indexOf(o.status) >= i;
                      return (
                        <div key={s} className="flex items-center gap-1">
                          {i > 0 && <div className={`h-0.5 w-4 ${reached ? 'bg-hom-primary' : 'bg-zinc-200'}`} />}
                          <span className={`text-[10px] px-1.5 py-0.5 rounded-full font-bold ${reached ? 'bg-hom-primary text-white' : 'bg-zinc-100 text-zinc-400'}`}>{s.toUpperCase()}</span>
                        </div>
                      );
                    })}
                  </div>
                </div>
                <div className="flex items-center gap-3 flex-wrap">
                  <span className="font-bold">{naira(o.amount)}</span>
                  <StatusChip status={o.status} />
                  {next && <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => orders.update(o.id, { status: next, deliveryDate: next === 'delivered' ? today() : o.deliveryDate })}>Mark {next}</Btn>}
                  {o.status !== 'delivered' && o.status !== 'cancelled' && (
                    <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => orders.update(o.id, { status: 'cancelled' })}>Cancel</Btn>
                  )}
                  <IconBtn onClick={() => { setEditItem(o); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                  <IconBtn tone="red" onClick={() => orders.remove(o.id)}><Trash2 size={14} /></IconBtn>
                </div>
              </div>
            );
          })}
          {orders.items.length === 0 && <EmptyState text="No procurement orders" />}
        </div>
      </Card>
    </div>
  );
}

function OrderForm({ initial, onSave, onCancel }: { initial: ProcurementOrder | null; onSave: (o: ProcurementOrder) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { vendorName: initial.vendorName, items: initial.items, amount: String(initial.amount), orderDate: initial.orderDate, deliveryDate: initial.deliveryDate || '', notes: initial.notes || '' }
    : { vendorName: '', items: '', amount: '', orderDate: today(), deliveryDate: '', notes: '' });
  return (
    <FormCard title={initial ? 'Edit Order' : 'New Procurement Order'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Vendor"><TextInput value={f.vendorName} onChange={e => setF({ ...f, vendorName: e.target.value })} placeholder="Vendor name" /></Field>
        <Field label="Items"><TextInput value={f.items} onChange={e => setF({ ...f, items: e.target.value })} placeholder="Items to procure" /></Field>
        <Field label="Amount (₦)"><NumberInput value={f.amount} onChange={e => setF({ ...f, amount: e.target.value })} placeholder="Amount" /></Field>
        <Field label="Order Date"><DateInput value={f.orderDate} onChange={e => setF({ ...f, orderDate: e.target.value })} /></Field>
        <Field label="Expected Delivery"><DateInput value={f.deliveryDate} onChange={e => setF({ ...f, deliveryDate: e.target.value })} /></Field>
        <Field label="Notes" className="md:col-span-2"><TextInput value={f.notes} onChange={e => setF({ ...f, notes: e.target.value })} placeholder="Notes" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.vendorName || !f.items) return alert('Vendor and items required'); onSave({ id: initial?.id || uid('bo'), ...f, amount: Number(f.amount) || 0, status: initial?.status || 'draft' }); }}>{initial ? 'Update' : 'Create Order'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Payroll ─────────────────────────────────────────────────────────────────

function PayrollTab() {
  const payroll = useCollection<PayrollRecord>('bo_payroll', seedPayrolls);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<PayrollRecord | null>(null);

  const totalNet = payroll.items.reduce((a, p) => a + p.netPay, 0);
  const totalPaye = payroll.items.reduce((a, p) => a + p.payeTax, 0);
  const totalPension = payroll.items.reduce((a, p) => a + p.pensionContribution, 0);
  const pendingCount = payroll.items.filter(p => !p.paidDate).length;

  return (
    <div className="space-y-4">
      <SectionHeader title={`Payroll (${payroll.items.length} records)`}>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Add Record</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Net Pay Due" value={naira(totalNet)} sub="Total net" color="bg-green-50 text-green-700" />
        <MetricCard label="PAYE" value={naira(totalPaye)} sub="7% withheld" color="bg-blue-50 text-blue-700" />
        <MetricCard label="Pension" value={naira(totalPension)} sub="8% employee" color="bg-amber-50 text-amber-700" />
        <MetricCard label="Unpaid" value={pendingCount} sub="Awaiting payment" color="bg-red-50 text-red-700" />
      </div>
      {showForm && (
        <PayrollForm initial={editItem} onSave={(p) => {
          if (editItem) payroll.replace(p.id, p); else payroll.add(p);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {payroll.items.map(p => (
            <div key={p.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
              <div className="flex-1 min-w-0">
                <div className="font-bold">{p.staffName} <span className="text-zinc-400 font-normal text-sm">{p.department}</span></div>
                <div className="text-xs text-zinc-500 mt-0.5">
                  Basic {naira(p.basicSalary)} + Allow {naira(p.allowances)} − Deduct {naira(p.deductions)}
                  <span className="ml-2 text-[10px] text-zinc-400">PAYE {naira(p.payeTax)} • Pension {naira(p.pensionContribution)}</span>
                </div>
                <div className="text-[10px] text-zinc-400 mt-0.5">Period {p.periodStart} → {p.periodEnd} {p.paidDate && `• Paid ${fmtDate(p.paidDate)}`}</div>
              </div>
              <div className="flex items-center gap-3 flex-wrap">
                <span className="font-bold">{naira(p.netPay)}</span>
                <StatusChip status={p.paidDate ? 'paid' : 'pending'} label={p.paidDate ? 'Paid' : 'Pending'} />
                {!p.paidDate && (
                  <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => payroll.update(p.id, { paidDate: today() })}><Check size={12} /> Mark Paid</Btn>
                )}
                <IconBtn onClick={() => { setEditItem(p); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                <IconBtn tone="red" onClick={() => payroll.remove(p.id)}><Trash2 size={14} /></IconBtn>
              </div>
            </div>
          ))}
          {payroll.items.length === 0 && <EmptyState text="No payroll records" />}
        </div>
      </Card>
    </div>
  );
}

function PayrollForm({ initial, onSave, onCancel }: { initial: PayrollRecord | null; onSave: (p: PayrollRecord) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { staffName: initial.staffName, department: initial.department, basicSalary: String(initial.basicSalary), allowances: String(initial.allowances), deductions: String(initial.deductions), periodStart: initial.periodStart, periodEnd: initial.periodEnd }
    : { staffName: '', department: '', basicSalary: '', allowances: '0', deductions: '0', periodStart: monthStart(), periodEnd: monthEnd() });

  const gross = (Number(f.basicSalary) || 0) + (Number(f.allowances) || 0) - (Number(f.deductions) || 0);
  const payeV = paye(gross);
  const pensV = pension(gross);

  return (
    <FormCard title={initial ? 'Edit Payroll' : 'Add Payroll Record'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Staff Name"><TextInput value={f.staffName} onChange={e => setF({ ...f, staffName: e.target.value })} placeholder="Staff name" /></Field>
        <Field label="Department"><TextInput value={f.department} onChange={e => setF({ ...f, department: e.target.value })} placeholder="Department" /></Field>
        <Field label="Basic Salary (₦)"><NumberInput value={f.basicSalary} onChange={e => setF({ ...f, basicSalary: e.target.value })} placeholder="Basic" /></Field>
        <Field label="Allowances (₦)"><NumberInput value={f.allowances} onChange={e => setF({ ...f, allowances: e.target.value })} placeholder="Allowances" /></Field>
        <Field label="Deductions (₦)"><NumberInput value={f.deductions} onChange={e => setF({ ...f, deductions: e.target.value })} placeholder="Deductions" /></Field>
        <Field label="Net Pay (auto)"><div className="border rounded-xl px-4 py-2.5 text-sm font-bold bg-zinc-50">{naira(netPay(gross))}</div></Field>
        <Field label="Period Start"><DateInput value={f.periodStart} onChange={e => setF({ ...f, periodStart: e.target.value })} /></Field>
        <Field label="Period End"><DateInput value={f.periodEnd} onChange={e => setF({ ...f, periodEnd: e.target.value })} /></Field>
      </FieldGrid>
      <div className="mt-4 text-xs text-zinc-500">PAYE {naira(payeV)} • Pension {naira(pensV)} • Net {naira(netPay(gross))}</div>
      <div className="mt-2 flex gap-2">
        <Btn onClick={() => { if (!f.staffName) return alert('Staff name required'); const g = gross; onSave({ id: initial?.id || uid('bo'), ...f, basicSalary: Number(f.basicSalary) || 0, allowances: Number(f.allowances) || 0, deductions: Number(f.deductions) || 0, payeTax: paye(g), pensionContribution: pension(g), netPay: netPay(g), paidDate: initial?.paidDate }); }}>{initial ? 'Update' : 'Add Record'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Tax Configuration ───────────────────────────────────────────────────────

function TaxConfigTab() {
  const [cfg, setCfg] = useKeyValue<TaxConfiguration>('bo_taxconfig', seedTaxConfig());
  const [draft, setDraft] = useState<TaxConfiguration>(cfg);
  const [saved, setSaved] = useState(false);

  const grossMonthly = 120000; // sample: average gross salary
  const grossAnnual = grossMonthly * 13;

  return (
    <div className="space-y-4">
      <SectionHeader title="Tax Configuration" sub="Statutory rates applied across the dashboard">
        <Btn onClick={() => { setCfg(draft); setSaved(true); setTimeout(() => setSaved(false), 1500); }}><Check size={14} /> {saved ? 'Saved!' : 'Save Config'}</Btn>
      </SectionHeader>
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-5 gap-4">
        <MetricCard label="VAT Rate" value={`${cfg.vatRate}%`} sub="Value added tax" color="bg-blue-50 text-blue-700" />
        <MetricCard label="CIT Rate" value={`${cfg.citRate}%`} sub="Company income tax" color="bg-green-50 text-green-700" />
        <MetricCard label="LGA Levy" value={`${cfg.lgaDevelopmentLevy}%`} sub="Dev. levy" color="bg-amber-50 text-amber-700" />
        <MetricCard label="Pension (EE)" value={`${cfg.pensionEmployeeRate}%`} sub="Employee" color="bg-zinc-50 text-zinc-700" />
        <MetricCard label="Pension (ER)" value={`${cfg.pensionEmployerRate}%`} sub="Employer" color="bg-zinc-50 text-zinc-700" />
      </div>
      <Card className="p-6 space-y-4">
        <h3 className="font-bold">Statutory Rates</h3>
        <FieldGrid>
          <Field label="VAT Rate (%)"><NumberInput value={String(draft.vatRate)} onChange={e => setDraft({ ...draft, vatRate: Number(e.target.value) || 0 })} /></Field>
          <Field label="Company Income Tax (%)"><NumberInput value={String(draft.citRate)} onChange={e => setDraft({ ...draft, citRate: Number(e.target.value) || 0 })} /></Field>
          <Field label="LGA Development Levy (%)"><NumberInput value={String(draft.lgaDevelopmentLevy)} onChange={e => setDraft({ ...draft, lgaDevelopmentLevy: Number(e.target.value) || 0 })} /></Field>
          <Field label="Pension — Employee (%)"><NumberInput value={String(draft.pensionEmployeeRate)} onChange={e => setDraft({ ...draft, pensionEmployeeRate: Number(e.target.value) || 0 })} /></Field>
          <Field label="Pension — Employer (%)"><NumberInput value={String(draft.pensionEmployerRate)} onChange={e => setDraft({ ...draft, pensionEmployerRate: Number(e.target.value) || 0 })} /></Field>
        </FieldGrid>
        <div className="rounded-xl bg-green-50 border border-green-100 p-4 text-sm">
          <div className="font-bold text-green-700 mb-1">Sample annual tax on ₦1.56M gross ({naira(grossMonthly)} × 13)</div>
          <div className="text-green-800/80">PAYE (7%): {naira(paye(grossMonthly) * 13)} • Pension (8%): {naira(pension(grossMonthly) * 13)} • Net: {naira(netPay(grossMonthly) * 13)}</div>
        </div>
      </Card>
    </div>
  );
}
