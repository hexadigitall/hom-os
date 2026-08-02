'use client';

import { useState, useMemo } from 'react';
import { Download } from 'lucide-react';
import { ExpenditureRecord, ExpenditureCategory, EXPENSE_CATEGORIES } from '@/lib/types';
import { seedExpenditure } from '@/lib/seed';
import { useScopedCollection } from '@/lib/scoped';
import { useAuth } from '@/lib/auth';
import { today, naira, fmtDate } from '@/lib/format';
import { Card, MetricCard, SectionHeader, Btn, Select, EmptyState } from '../ui';

type Granularity = 'weekly' | 'monthly' | 'quarterly' | 'yearly';

interface Period { label: string; start: string; end: string }

function buildPeriods(g: Granularity): Period[] {
  const now = new Date();
  const iso = (d: Date) => d.toISOString().slice(0, 10);
  const periods: Period[] = [];
  if (g === 'weekly') {
    const wk = new Date(now); wk.setDate(wk.getDate() - wk.getDay());
    for (let i = 11; i >= 0; i--) {
      const end = new Date(wk); end.setDate(end.getDate() - i * 7 + 7);
      const start = new Date(end); start.setDate(end.getDate() - 7);
      periods.push({ label: `Week ${i + 1} (${fmtDate(iso(start))} - ${fmtDate(iso(end))})`, start: iso(start), end: iso(end) });
    }
  } else if (g === 'monthly') {
    for (let i = 5; i >= 0; i--) {
      const end = new Date(now.getFullYear(), now.getMonth() - i + 1, 0);
      const start = new Date(now.getFullYear(), now.getMonth() - i, 1);
      periods.push({ label: end.toLocaleString('en', { month: 'long', year: 'numeric' }), start: iso(start), end: iso(end) });
    }
  } else if (g === 'quarterly') {
    for (let i = 3; i >= 0; i--) {
      const m = now.getMonth() - i * 3;
      const end = new Date(now.getFullYear(), m + 3, 0);
      const start = new Date(now.getFullYear(), m - 2, 1);
      const q = Math.floor(m / 3) + 1;
      periods.push({ label: `Q${q} ${end.getFullYear()}`, start: iso(start), end: iso(end) });
    }
  } else {
    for (let i = 2; i >= 0; i--) {
      periods.push({ label: String(now.getFullYear() - i), start: `${now.getFullYear() - i}-01-01`, end: `${now.getFullYear() - i}-12-31` });
    }
  }
  return periods;
}

export function ReportsModule() {
  const { session } = useAuth();
  const exp = useScopedCollection<ExpenditureRecord>('expenditure_records', seedExpenditure, session);
  const [gran, setGran] = useState<Granularity>('monthly');
  const [periodIdx, setPeriodIdx] = useState(0);
  const [catFilter, setCatFilter] = useState('');

  const periods = useMemo(() => buildPeriods(gran), [gran]);
  const period = periods[Math.min(periodIdx, periods.length - 1)];

  const inPeriod = (e: ExpenditureRecord) => e.date >= period.start && e.date <= period.end;

  const cats = useMemo(() => {
    const map = new Map<ExpenditureCategory, { total: number; count: number }>();
    EXPENSE_CATEGORIES.forEach(c => map.set(c, { total: 0, count: 0 }));
    exp.items.filter(inPeriod).forEach(e => {
      const cur = map.get(e.category) || { total: 0, count: 0 };
      map.set(e.category, { total: cur.total + e.amount, count: cur.count + 1 });
    });
    return map;
  }, [exp.items, period]);

  const grandTotal = Array.from(cats.values()).reduce((a, c) => a + c.total, 0);
  const totalCount = Array.from(cats.values()).reduce((a, c) => a + c.count, 0);
  const topCat = Array.from(cats.entries()).sort((a, b) => b[1].total - a[1].total)[0];

  const exportCsv = () => {
    const rows = [['Period', 'Category', 'Total', 'Count'], ...Array.from(cats.entries())
      .map(([c, v]) => [period.label, c, String(v.total), String(v.count)])];
    const csv = rows.map(r => r.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `HOM_Report_${period.label.replace(/\s+/g, '_')}.csv`;
    a.click();
  };

  const visible = Array.from(cats.entries()).filter(([c]) => !catFilter || c === catFilter);

  return (
    <div className="space-y-4">
      <SectionHeader title="Expenditure Reports" sub={`${period.label} • ${totalCount} records • ${naira(grandTotal)} total`}>
        <div className="flex gap-1.5">
          {(['weekly', 'monthly', 'quarterly', 'yearly'] as Granularity[]).map(g => (
            <button key={g} onClick={() => { setGran(g); setPeriodIdx(0); }}
              className={`px-3 py-1.5 rounded-full text-xs font-bold whitespace-nowrap ${gran === g ? 'bg-hom-primary text-white' : 'bg-white border text-zinc-600 hover:bg-zinc-50'}`}>{g[0].toUpperCase() + g.slice(1)}</button>
          ))}
        </div>
        <Select value={periodIdx} onChange={e => setPeriodIdx(Number(e.target.value))} className="!py-1.5 w-full sm:!w-64">
          {periods.map((p, i) => <option key={p.label} value={i}>{p.label}</option>)}
        </Select>
        <Select value={catFilter} onChange={e => setCatFilter(e.target.value)} className="!py-1.5 w-full sm:!w-44">
          <option value="">All Categories</option>
          {EXPENSE_CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
        </Select>
        <Btn color="outline" onClick={exportCsv}><Download size={14} /> Export CSV</Btn>
      </SectionHeader>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Grand Total" value={naira(grandTotal)} sub={`${totalCount} records`} color="bg-blue-50 text-blue-700" />
        <MetricCard label="Top Category" value={topCat ? topCat[0] : '—'} sub={topCat ? naira(topCat[1].total) : ''} color="bg-green-50 text-green-700" />
        <MetricCard label="Average / Record" value={totalCount ? naira(grandTotal / totalCount) : '—'} sub="Per record" color="bg-amber-50 text-amber-700" />
        <MetricCard label="Daily Avg" value={naira(grandTotal / (Math.max(1, Math.round((new Date(period.end).getTime() - new Date(period.start).getTime()) / 86400000) + 1)))} sub="Across period days" color="bg-red-50 text-red-700" />
      </div>

      <Card className="p-5">
        <h3 className="font-bold text-sm mb-4">Category Breakdown</h3>
        <div className="space-y-3">
          {visible.filter(([, v]) => v.total > 0).map(([c, v]) => (
            <div key={c}>
              <div className="flex justify-between text-sm mb-1">
                <span className="font-medium">{c} <span className="text-zinc-400 text-xs">({v.count})</span></span>
                <span className="font-bold">{naira(v.total)} <span className="text-zinc-400 font-normal">{grandTotal ? ((v.total / grandTotal) * 100).toFixed(1) : 0}%</span></span>
              </div>
              <div className="h-2.5 bg-zinc-100 rounded-full overflow-hidden">
                <div className="h-full bg-hom-primary rounded-full" style={{ width: `${grandTotal ? (v.total / grandTotal) * 100 : 0}%` }} />
              </div>
            </div>
          ))}
          {visible.every(([, v]) => v.total === 0) && <EmptyState text="No records in this period" />}
        </div>
      </Card>

      <Card className="p-5">
        <h3 className="font-bold text-sm mb-4">Period Records</h3>
        <div className="divide-y">
          {exp.items.filter(e => inPeriod(e) && (!catFilter || e.category === catFilter)).slice(0, 50).map(e => (
            <div key={e.id} className="py-2.5 flex justify-between items-center gap-3 text-sm">
              <div className="min-w-0">
                <span className="font-medium">{e.description}</span>
                <span className="text-zinc-400 text-xs ml-2">{e.category}{e.vendor ? ` • ${e.vendor}` : ''}</span>
              </div>
              <span className="font-bold shrink-0">{naira(e.amount)}</span>
            </div>
          ))}
          {exp.items.filter(e => inPeriod(e) && (!catFilter || e.category === catFilter)).length === 0 && <EmptyState text="No records in this period" />}
        </div>
      </Card>
    </div>
  );
}
