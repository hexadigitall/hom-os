'use client';

import { useState } from 'react';
import { Plus, Trash2, Edit3, Upload } from 'lucide-react';
import {
  ExpenditureRecord, ExpenditureCategory, PaymentMethod, EXPENSE_CATEGORIES,
} from '@/lib/types';
import { seedExpenditure } from '@/lib/seed';
import { useCollection } from '@/lib/storage';
import { today, uid, naira, fmtDate } from '@/lib/format';
import { Card, MetricCard, StatusChip, SectionHeader, Btn, IconBtn, Field, TextInput, NumberInput, DateInput, Select, FormCard, FieldGrid, EmptyState } from '../ui';

const DEPARTMENTS = ['Management', 'Reception', 'Housekeeping', 'Engineering', 'Kitchen', 'Restaurants', 'Procurement', 'Accounts', 'Security'];

export function ExpensesModule() {
  const exp = useCollection<ExpenditureRecord>('expenditure_records', seedExpenditure);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<ExpenditureRecord | null>(null);
  const [search, setSearch] = useState('');
  const [cat, setCat] = useState('');
  const [method, setMethod] = useState('');

  const filtered = exp.items.filter(e =>
    (e.description + ' ' + e.vendor + ' ' + e.subcategory + ' ' + e.receiptRef).toLowerCase().includes(search.toLowerCase()) &&
    (!cat || e.category === cat) && (!method || e.paymentMethod === method));

  const total = filtered.reduce((a, e) => a + e.amount, 0);

  const importCsv = (file: File) => {
    const reader = new FileReader();
    reader.onload = () => {
      const rows = String(reader.result).split(/\r?\n/).filter(l => l.trim());
      if (rows.length === 0) return alert('File is empty');
      const header = rows[0].toLowerCase();
      const hasHeader = header.includes('date') || header.includes('amount') || header.includes('category');
      const dataRows = hasHeader ? rows.slice(1) : rows;
      let added = 0, skipped = 0;
      const records: ExpenditureRecord[] = [];
      for (const line of dataRows) {
        const cols = line.split(',').map(c => c.trim());
        if (cols.length < 5) { skipped++; continue; }
        const [date, category, subcategory, description, amount] = cols;
        const amt = Number(String(amount).replace(/[^\d.]/g, ''));
        if (!date || !amount || isNaN(amt) || amt <= 0) { skipped++; continue; }
        const catMatch = EXPENSE_CATEGORIES.find(c => c.toLowerCase().replace(/[\s/&-]/g, '') === category.toLowerCase().replace(/[\s/&-]/g, ''));
        records.push({
          id: uid('exp'), date, category: (catMatch as ExpenditureCategory) || 'Other',
          subcategory: subcategory || '', description: description || '', amount: amt,
          vendor: cols[5] || '', paymentMethod: (cols[6] as PaymentMethod) || 'Cash',
          receiptRef: cols[7] || '', notes: cols[8] || '', createdAt: new Date().toISOString(),
        });
        added++;
      }
      if (records.length) exp.set(prev => [...records, ...prev]);
      alert(`CSV import: ${added} added, ${skipped} skipped`);
    };
    reader.readAsText(file);
  };

  return (
    <div className="space-y-4">
      <SectionHeader title={`Expenditure (${filtered.length} records)`} sub={`Total: ${naira(total)}`}>
        <TextInput value={search} onChange={e => setSearch(e.target.value)} placeholder="Search..." className="!py-1.5 w-full sm:!w-48" />
        <Select value={cat} onChange={e => setCat(e.target.value)} className="!py-1.5 w-full sm:!w-44">
          <option value="">All Categories</option>
          {EXPENSE_CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
        </Select>
        <Select value={method} onChange={e => setMethod(e.target.value)} className="!py-1.5 w-full sm:!w-32">
          <option value="">All Methods</option>
          <option>Cash</option><option>Transfer</option><option>POS</option><option>Card</option>
        </Select>
        <label className="cursor-pointer">
          <Btn color="outline" onClick={() => {}}><Upload size={14} /> Import CSV</Btn>
          <input type="file" accept=".csv,text/csv" className="hidden" onChange={e => e.target.files?.[0] && importCsv(e.target.files[0])} />
        </label>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> New Expense</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="All Time Total" value={naira(exp.items.reduce((a, e) => a + e.amount, 0))} sub={`${exp.items.length} records`} color="bg-blue-50 text-blue-700" />
        <MetricCard label="Filtered Total" value={naira(total)} sub={`${filtered.length} shown`} color="bg-green-50 text-green-700" />
        <MetricCard label="This Month" value={naira(exp.items.filter(e => e.date.slice(0, 7) === today().slice(0, 7)).reduce((a, e) => a + e.amount, 0))} sub="Current month" color="bg-amber-50 text-amber-700" />
        <MetricCard label="Cash Spent" value={naira(exp.items.filter(e => e.paymentMethod === 'Cash').reduce((a, e) => a + e.amount, 0))} sub="Cash payments" color="bg-red-50 text-red-700" />
      </div>
      {showForm && (
        <ExpenseForm initial={editItem} onSave={(e) => {
          if (editItem) exp.replace(e.id, e); else exp.add(e);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {filtered.map(e => (
            <div key={e.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
              <div className="flex-1 min-w-0">
                <div className="font-bold flex items-center gap-2 flex-wrap">{e.description} <span className="text-zinc-400 font-normal text-sm">{naira(e.amount)}</span></div>
                <div className="text-xs text-zinc-500 mt-0.5">{fmtDate(e.date)} • {e.category}{e.subcategory ? ` / ${e.subcategory}` : ''} • {e.vendor || '—'} • {e.paymentMethod} • {e.receiptRef && `Ref ${e.receiptRef}`} • {e.department || '—'}</div>
              </div>
              <div className="flex items-center gap-2">
                <StatusChip status={e.paymentMethod} label={e.paymentMethod} />
                <IconBtn onClick={() => { setEditItem(e); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                <IconBtn tone="red" onClick={() => exp.remove(e.id)}><Trash2 size={14} /></IconBtn>
              </div>
            </div>
          ))}
          {filtered.length === 0 && <EmptyState text="No expenditure records — add one or import a CSV" />}
        </div>
      </Card>
    </div>
  );
}

function ExpenseForm({ initial, onSave, onCancel }: { initial: ExpenditureRecord | null; onSave: (e: ExpenditureRecord) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { date: initial.date, category: initial.category, subcategory: initial.subcategory, description: initial.description, amount: String(initial.amount), vendor: initial.vendor, paymentMethod: initial.paymentMethod, receiptRef: initial.receiptRef, notes: initial.notes, department: initial.department || '' }
    : { date: today(), category: 'F&B' as ExpenditureCategory, subcategory: '', description: '', amount: '', vendor: '', paymentMethod: 'Cash' as PaymentMethod, receiptRef: '', notes: '', department: '' });

  return (
    <FormCard title={initial ? 'Edit Expense' : 'New Expense'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Date"><DateInput value={f.date} onChange={e => setF({ ...f, date: e.target.value })} /></Field>
        <Field label="Category">
          <Select value={f.category} onChange={e => setF({ ...f, category: e.target.value as ExpenditureCategory })}>
            {EXPENSE_CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
          </Select>
        </Field>
        <Field label="Subcategory"><TextInput value={f.subcategory} onChange={e => setF({ ...f, subcategory: e.target.value })} placeholder="e.g. Supplies" /></Field>
        <Field label="Description"><TextInput value={f.description} onChange={e => setF({ ...f, description: e.target.value })} placeholder="Description" /></Field>
        <Field label="Amount (₦)"><NumberInput value={f.amount} onChange={e => setF({ ...f, amount: e.target.value })} placeholder="Amount" /></Field>
        <Field label="Vendor"><TextInput value={f.vendor} onChange={e => setF({ ...f, vendor: e.target.value })} placeholder="Vendor" /></Field>
        <Field label="Payment Method">
          <Select value={f.paymentMethod} onChange={e => setF({ ...f, paymentMethod: e.target.value as PaymentMethod })}>
            <option>Cash</option><option>Transfer</option><option>POS</option><option>Card</option>
          </Select>
        </Field>
        <Field label="Receipt Ref"><TextInput value={f.receiptRef} onChange={e => setF({ ...f, receiptRef: e.target.value })} placeholder="Receipt reference" /></Field>
        <Field label="Department">
          <Select value={f.department} onChange={e => setF({ ...f, department: e.target.value })}>
            <option value="">None</option>
            {DEPARTMENTS.map(d => <option key={d} value={d}>{d}</option>)}
          </Select>
        </Field>
        <Field label="Notes"><TextInput value={f.notes} onChange={e => setF({ ...f, notes: e.target.value })} placeholder="Notes" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.description || !f.amount) return alert('Description and amount required'); onSave({ id: initial?.id || uid('exp'), createdAt: initial?.createdAt || new Date().toISOString(), ...f, amount: Number(f.amount) }); }}>{initial ? 'Update' : 'Add Expense'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}
