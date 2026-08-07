'use client';

import { useState, useRef } from 'react';
import { Plus, Trash2, Edit3, Link2, Split, Banknote, Wallet, CreditCard, Search, Upload } from 'lucide-react';
import {
  BankTransaction, ReconciliationMatch, SplitPayment, VirtualAccount,
  PosTerminal, PosSettlement, MatchEntityType, Booking, ExpenditureRecord,
} from '@/lib/types';
import {
  seedBankTransactions, seedMatches, seedVirtualAccounts, seedPosTerminals, seedPosSettlements, seedBookings, seedExpenditure,
} from '@/lib/seed';
import { useSyncedCollection } from '@/lib/synced';
import { useAuth } from '@/lib/auth';
import { hasPermission, PERMISSIONS, tagFor, type Department } from '@/lib/rbac';
import { parseBankCsv } from '@/lib/bankparser';
import { today, nowISO, uid, naira, fmtDate, addDays } from '@/lib/format';
import { Card, MetricCard, StatusChip, SectionHeader, Btn, IconBtn, Field, TextInput, NumberInput, DateInput, Select, FormCard, FieldGrid, EmptyState } from '../ui';

type SubTab = 'bank' | 'va' | 'pos';

const SUB_NAV: { id: SubTab; label: string }[] = [
  { id: 'bank', label: 'Bank Stmts' },
  { id: 'va', label: 'Virtual Accts' },
  { id: 'pos', label: 'POS' },
];

export function ReconciliationModule() {
  const [tab, setTab] = useState<SubTab>('bank');
  return (
    <div className="space-y-4">
      <div className="flex gap-1.5 overflow-x-auto pb-1">
        {SUB_NAV.map(s => (
          <button key={s.id} onClick={() => setTab(s.id)}
            className={`px-3 py-1.5 rounded-full text-xs font-bold whitespace-nowrap ${tab === s.id ? 'bg-hom-primary text-white' : 'bg-white border text-zinc-600 hover:bg-zinc-50'}`}>{s.label}</button>
        ))}
      </div>
      {tab === 'bank' && <BankTab />}
      {tab === 'va' && <VirtualAccountsTab />}
      {tab === 'pos' && <PosTab />}
    </div>
  );
}

// ─── Bank Statements ─────────────────────────────────────────────────────────

function BankTab() {
  const { session } = useAuth();
  const txns = useSyncedCollection<BankTransaction>('rec_bank_txns', 'rec_bank_txns', seedBankTransactions, session);
  const matches = useSyncedCollection<ReconciliationMatch>('rec_matches', 'rec_matches', seedMatches, session);
  const splits = useSyncedCollection<SplitPayment>('rec_split_payments', 'rec_split_payments', () => [], session);
  const bookings = useSyncedCollection<Booking>('bookings', 'hom_bookings', seedBookings, session);
  const exp = useSyncedCollection<ExpenditureRecord>('expenditure', 'expenditure_records', seedExpenditure, session);
  const [filter, setFilter] = useState<'all' | 'matched' | 'unmatched'>('all');
  const [search, setSearch] = useState('');
  const [matchTxn, setMatchTxn] = useState<BankTransaction | null>(null);
  const [editTxn, setEditTxn] = useState<BankTransaction | null>(null);
  const [editMatchTxn, setEditMatchTxn] = useState<BankTransaction | null>(null);
  const [splitTxn, setSplitTxn] = useState<BankTransaction | null>(null);
  const [importMsg, setImportMsg] = useState('');
  const [addTxn, setAddTxn] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);
  const depts = tagFor(session, 'accounts');

  const canManage = hasPermission(session, PERMISSIONS.manageReconciliation);
  const canParse = hasPermission(session, PERMISSIONS.parseBankCSV);
  const canSplit = hasPermission(session, PERMISSIONS.manageSplitPayments);

  const matchedIds = new Set(matches.items.map(m => m.bankTransactionId));
  const filtered = txns.items.filter(t => {
    if (filter === 'matched' && !matchedIds.has(t.id)) return false;
    if (filter === 'unmatched' && matchedIds.has(t.id)) return false;
    if (search && !(t.description + ' ' + (t.reference || '')).toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  const totalCredits = txns.items.filter(t => t.type === 'CR').reduce((a, t) => a + t.amount, 0);
  const totalDebits = txns.items.filter(t => t.type === 'DR').reduce((a, t) => a + t.amount, 0);

  const matchEntities: { type: MatchEntityType; id: string; label: string; amount: number }[] = [
    ...bookings.items.map(b => ({ type: 'booking' as MatchEntityType, id: b.id, label: `${b.guest} — Room ${b.room}`, amount: b.amount })),
    ...exp.items.map(e => ({ type: 'expenditure' as MatchEntityType, id: e.id, label: e.description, amount: e.amount })),
  ];

  const saveMatch = (entity: { type: MatchEntityType; id: string; label: string; amount: number }, amt: number) => {
    if (!matchTxn) return;
    matches.add({
      id: uid('rec'), bankTransactionId: matchTxn.id, entityType: entity.type, entityId: entity.id,
      entityLabel: entity.label, entityAmount: entity.amount, matchedAmount: amt, confidence: 1, isManual: true, matchedAt: nowISO(), departments: depts,
    });
    setMatchTxn(null);
  };

  const handleImport = (file: File) => {
    const reader = new FileReader();
    reader.onload = () => {
      const raw = String(reader.result || '');
      const parsed = parseBankCsv(raw, file.name);
      if (parsed.transactions.length > 0) {
        parsed.transactions.forEach(t => txns.add({ ...t, departments: depts }));
      }
      setImportMsg(`${parsed.parsedCount} transactions parsed (${parsed.skippedCount} skipped)${parsed.errors.length ? ' — see console for errors' : ''}`);
      if (parsed.errors.length) console.warn('Bank CSV parse errors:', parsed.errors);
      setTimeout(() => setImportMsg(''), 5000);
      if (fileRef.current) fileRef.current.value = '';
    };
    reader.readAsText(file);
  };

  const filterChip = (id: 'all' | 'matched' | 'unmatched', label: string) => (
    <button key={id} onClick={() => setFilter(id)}
      className={`px-3 py-1 rounded-full text-[11px] font-bold whitespace-nowrap ${filter === id ? 'bg-hom-primary text-white' : 'bg-white border text-zinc-600'}`}>{label}</button>
  );

  return (
    <div className="space-y-4">
      <SectionHeader title="Bank Statements" sub="Match bank transactions to bookings & expenditure">
        <div className="flex gap-1.5">
          {filterChip('all', `All (${txns.items.length})`)}
          {filterChip('matched', `Matched (${matchedIds.size})`)}
          {filterChip('unmatched', `Unmatched (${txns.items.length - matchedIds.size})`)}
        </div>
        <div className="relative">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-400" />
          <TextInput value={search} onChange={e => setSearch(e.target.value)} placeholder="Search transactions..." className="!py-1.5 !pl-9 w-full sm:!w-56" />
        </div>
        {canParse && (
          <>
            <input ref={fileRef} type="file" accept=".csv,text/csv" className="hidden" onChange={e => { if (e.target.files?.[0]) handleImport(e.target.files[0]); }} />
            <Btn onClick={() => fileRef.current?.click()}><Upload size={14} /> Import CSV</Btn>
          </>
        )}
        {canManage && <Btn onClick={() => { setAddTxn(true); setEditTxn(null); }}><Plus size={14} /> New Transaction</Btn>}
      </SectionHeader>
      {importMsg && <div className="text-xs font-medium text-green-700 bg-green-50 border border-green-200 rounded-xl px-4 py-2.5">{importMsg}</div>}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Transactions" value={txns.items.length} sub="On statement" color="bg-blue-50 text-blue-700" />
        <MetricCard label="Matched" value={matchedIds.size} sub="Reconciled" color="bg-green-50 text-green-700" />
        <MetricCard label="Unmatched" value={txns.items.length - matchedIds.size} sub="Awaiting match" color="bg-red-50 text-red-700" />
        <MetricCard label="Net Inflow" value={naira(totalCredits - totalDebits)} sub={`${naira(totalCredits)} CR • ${naira(totalDebits)} DR`} color="bg-amber-50 text-amber-700" />
      </div>
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
        <div className="flex-1 h-2 bg-zinc-100 rounded-full overflow-hidden">
          <div className="h-full bg-hom-primary rounded-full" style={{ width: `${txns.items.length ? (matchedIds.size / txns.items.length) * 100 : 0}%` }} />
        </div>
        <div className="text-xs text-zinc-400 sm:w-40 sm:text-right sm:shrink-0">{txns.items.length ? ((matchedIds.size / txns.items.length) * 100).toFixed(0) : 0}% reconciled</div>
      </div>
      <Card className="overflow-hidden">
        <div className="divide-y">
          {filtered.map(t => {
            const m = matches.items.find(x => x.bankTransactionId === t.id);
            return (
              <div key={t.id} className={`p-4 flex flex-col md:flex-row md:items-center justify-between gap-3 ${m ? 'bg-green-50/40' : ''}`}>
                <div className="flex-1 min-w-0">
                  <div className="font-bold flex items-center gap-2 flex-wrap">
                    <span className={t.type === 'CR' ? 'text-hom-primary' : 'text-red-600'}>{t.type === 'CR' ? '+' : '−'}{naira(t.amount)}</span>
                    <StatusChip status={t.type === 'CR' ? 'matched' : 'cancelled'} label={t.type === 'CR' ? 'CREDIT' : 'DEBIT'} />
                  </div>
                  <div className="text-xs text-zinc-500 mt-0.5">{fmtDate(t.date)} • {t.description} {t.reference && `• ${t.reference}`} {t.source && `• ${t.source}`}</div>
                  {m && <div className="text-xs text-green-700 mt-1 font-medium"><Link2 size={11} className="inline" /> Matched → {m.entityLabel} ({naira(m.matchedAmount)})</div>}
                </div>
                <div className="flex items-center gap-2">
                  {m ? (
                    <>
                      <IconBtn title="Edit match" onClick={() => setEditMatchTxn(t)}><Edit3 size={14} /></IconBtn>
                      <IconBtn tone="red" title="Unmatch" onClick={() => matches.remove(m.id)}><Trash2 size={14} /></IconBtn>
                    </>
                  ) : (
                    <>
                      <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => setMatchTxn(t)}><Link2 size={12} /> Match</Btn>
                      {canSplit && <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => setSplitTxn(t)}><Split size={12} /> Split</Btn>}
                    </>
                  )}
                  {canManage && (
                    <>
                      <IconBtn title="Edit" onClick={() => setEditTxn(t)}><Edit3 size={14} /></IconBtn>
                      <IconBtn tone="red" title="Delete" onClick={() => { matches.items.filter(x => x.bankTransactionId === t.id).forEach(x => matches.remove(x.id)); txns.remove(t.id); }}><Trash2 size={14} /></IconBtn>
                    </>
                  )}
                </div>
              </div>
            );
          })}
          {filtered.length === 0 && <EmptyState text="No transactions match this filter" />}
        </div>
      </Card>

      {matchTxn && (
        <Card className="p-6">
          <h3 className="font-bold mb-1">Match Transaction</h3>
          <div className="text-xs text-zinc-500 mb-4">{fmtDate(matchTxn.date)} • {matchTxn.description} • {naira(matchTxn.amount)} ({matchTxn.type})</div>
          <div className="divide-y max-h-72 overflow-y-auto rounded-xl border">
            {matchEntities.map(ent => (
              <button key={ent.id} onClick={() => saveMatch(ent, ent.amount)}
                className="w-full text-left p-3 hover:bg-green-50 flex items-center justify-between gap-3 text-sm">
                <div className="min-w-0">
                  <div className="font-medium truncate">{ent.label}</div>
                  <div className="text-[10px] text-zinc-400 uppercase">{ent.type}</div>
                </div>
                <span className="font-bold shrink-0">{naira(ent.amount)}</span>
              </button>
            ))}
            {matchEntities.length === 0 && <EmptyState text="No bookings or expenditure to match" />}
          </div>
          <div className="mt-4 flex gap-2">
            <Btn color="outline" onClick={() => setMatchTxn(null)}>Cancel</Btn>
          </div>
        </Card>
      )}

      {(addTxn || (editTxn && canManage)) && (
        <TxnForm initial={editTxn} depts={depts} onSave={(t) => {
          if (editTxn) txns.replace(t.id, t); else txns.add(t);
          setEditTxn(null); setAddTxn(false);
        }} onCancel={() => { setEditTxn(null); setAddTxn(false); }} />
      )}

      {editMatchTxn && (() => {
        const m = matches.items.find(x => x.bankTransactionId === editMatchTxn.id);
        if (!m) return null;
        return <MatchEditForm txn={editMatchTxn} match={m} entities={matchEntities}
          onSave={(patch) => { matches.update(m.id, patch); setEditMatchTxn(null); }}
          onCancel={() => setEditMatchTxn(null)} />;
      })()}

      {splitTxn && canSplit && (
        <SplitForm txn={splitTxn} entities={matchEntities} depts={depts} onSave={(allocs) => {
          allocs.forEach(a => matches.add({
            id: uid('rec'), bankTransactionId: splitTxn.id, entityType: a.entityType, entityId: a.entityId,
            entityLabel: a.entityLabel, entityAmount: a.amount, matchedAmount: a.amount, confidence: 1, isManual: true, matchedAt: nowISO(), departments: depts,
          }));
          splits.add({ id: uid('rec'), bankTransactionId: splitTxn.id, allocations: allocs, departments: depts });
          setSplitTxn(null);
        }} onCancel={() => setSplitTxn(null)} />
      )}

      {canSplit && splits.items.length > 0 && (
        <Card className="overflow-hidden">
          <div className="p-4 border-b font-bold text-sm flex items-center gap-2"><Split size={14} /> Split Payments</div>
          <div className="divide-y">
            {splits.items.map(s => {
              const t = txns.items.find(x => x.id === s.bankTransactionId);
              return (
                <div key={s.id} className="p-3 flex flex-col md:flex-row md:items-center justify-between gap-3">
                  <div className="min-w-0">
                    <div className="font-bold text-sm">{t ? `${naira(t.amount)} — ${t.description}` : s.bankTransactionId}</div>
                    <div className="text-[11px] text-zinc-500 mt-0.5">
                      {s.allocations.map(a => `${a.entityLabel} (${naira(a.amount)})`).join('  +  ') || 'No allocations'}
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <IconBtn title="Delete split" onClick={() => splits.remove(s.id)}><Trash2 size={14} /></IconBtn>
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

function TxnForm({ initial, depts, onSave, onCancel }: { initial: BankTransaction | null; depts: Department[]; onSave: (t: BankTransaction) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? {
        date: initial.date, description: initial.description, amount: String(initial.amount),
        type: initial.type, reference: initial.reference || '', source: initial.source || '',
      }
    : {
        date: today(), description: '', amount: '', type: 'CR' as 'CR' | 'DR', reference: '', source: '',
      });
  return (
    <FormCard title={initial ? 'Edit Transaction' : 'Add Transaction'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Date"><DateInput value={f.date} onChange={e => setF({ ...f, date: e.target.value })} /></Field>
        <Field label="Type">
          <Select value={f.type} onChange={e => setF({ ...f, type: e.target.value as 'CR' | 'DR' })}>
            <option value="CR">Credit</option><option value="DR">Debit</option>
          </Select>
        </Field>
        <Field label="Description"><TextInput value={f.description} onChange={e => setF({ ...f, description: e.target.value })} placeholder="Description" /></Field>
        <Field label="Amount (₦)"><NumberInput value={f.amount} onChange={e => setF({ ...f, amount: e.target.value })} placeholder="Amount" /></Field>
        <Field label="Reference"><TextInput value={f.reference} onChange={e => setF({ ...f, reference: e.target.value })} placeholder="Reference" /></Field>
        <Field label="Source"><TextInput value={f.source} onChange={e => setF({ ...f, source: e.target.value })} placeholder="Source (bank)" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.date || !f.amount) return alert('Date and amount required'); onSave({ id: initial?.id || uid('rec'), ...f, amount: Number(f.amount), reference: f.reference || undefined, source: f.source || undefined, departments: initial?.departments || depts }); }}>{initial ? 'Save Changes' : 'Add Transaction'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

function MatchEditForm({ txn, match, entities, onSave, onCancel }: {
  txn: BankTransaction;
  match: ReconciliationMatch;
  entities: { type: MatchEntityType; id: string; label: string; amount: number }[];
  onSave: (patch: { entityType: MatchEntityType; entityId: string; entityLabel: string; entityAmount: number; matchedAmount: number }) => void;
  onCancel: () => void;
}) {
  const [entityId, setEntityId] = useState(match.entityId);
  const [amount, setAmount] = useState(String(match.matchedAmount));
  return (
    <Card className="p-6">
      <h3 className="font-bold mb-1">Edit Match</h3>
      <div className="text-xs text-zinc-500 mb-4">{fmtDate(txn.date)} • {txn.description} • {naira(txn.amount)} ({txn.type})</div>
      <FieldGrid>
        <Field label="Matched to">
          <Select value={entityId} onChange={e => setEntityId(e.target.value)}>
            <option value="">Select booking / expense...</option>
            {entities.map(en => <option key={en.id} value={en.id}>{en.label} — {naira(en.amount)}</option>)}
          </Select>
        </Field>
        <Field label="Matched amount (₦)"><NumberInput value={amount} onChange={e => setAmount(e.target.value)} /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => {
          if (!entityId || !amount) return alert('Entity and amount required');
          const e = entities.find(x => x.id === entityId)!;
          onSave({ entityType: e.type, entityId: e.id, entityLabel: e.label, entityAmount: e.amount, matchedAmount: Number(amount) });
        }}>Save Changes</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </Card>
  );
}

function SplitForm({ txn, entities, depts, onSave, onCancel }: {
  txn: BankTransaction;
  entities: { type: MatchEntityType; id: string; label: string; amount: number }[];
  depts: Department[];
  onSave: (allocs: { entityType: MatchEntityType; entityId: string; entityLabel: string; amount: number }[]) => void;
  onCancel: () => void;
}) {
  const [rows, setRows] = useState<{ entityId: string; amount: string }[]>([]);
  const total = rows.reduce((a, r) => a + (Number(r.amount) || 0), 0);
  const remaining = txn.amount - total;

  const setRow = (i: number, patch: Partial<{ entityId: string; amount: string }>) => {
    setRows(rows.map((r, idx) => idx === i ? { ...r, ...patch } : r));
  };

  return (
    <Card className="p-6">
      <h3 className="font-bold mb-1">Split Payment</h3>
      <div className="text-xs text-zinc-500 mb-4">{fmtDate(txn.date)} • {txn.description} • {naira(txn.amount)} ({txn.type})</div>
      <div className="text-sm font-bold mb-3">Total: {naira(txn.amount)} • Remaining: {naira(Math.max(0, remaining))}</div>
      <div className="space-y-2">
        {rows.map((r, i) => {
          const ent = entities.find(e => e.id === r.entityId);
          return (
            <div key={i} className="flex gap-2 items-start">
              <div className="flex-1">
                <Select value={r.entityId} onChange={e => setRow(i, { entityId: e.target.value })}>
                  <option value="">Select booking / expense...</option>
                  {entities.map(en => <option key={en.id} value={en.id}>{en.label} — {naira(en.amount)}</option>)}
                </Select>
              </div>
              <div className="w-32">
                <NumberInput value={r.amount} onChange={e => setRow(i, { amount: e.target.value })} placeholder="Amount" />
              </div>
              <IconBtn tone="red" onClick={() => setRows(rows.filter((_, idx) => idx !== i))}><Trash2 size={14} /></IconBtn>
            </div>
          );
        })}
      </div>
      {rows.length === 0 && <div className="text-xs text-zinc-400 mb-2">No allocations yet.</div>}
      <div className="mt-3 flex gap-2 flex-wrap">
        <Btn color="outline" disabled={remaining <= 0} onClick={() => setRows([...rows, { entityId: entities[0]?.id || '', amount: String(Math.round(Math.min(remaining, entities[0]?.amount || remaining))) }])}><Plus size={14} /> Add Allocation</Btn>
        <Btn color="amber" disabled={rows.length === 0 || remaining > 0} onClick={() => onSave(rows.map(r => {
          const ent = entities.find(e => e.id === r.entityId)!;
          return { entityType: ent.type, entityId: ent.id, entityLabel: ent.label, amount: Number(r.amount) };
        }))}>Save Allocations ({naira(txn.amount)})</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </Card>
  );
}

// ─── Virtual Accounts ────────────────────────────────────────────────────────

function VirtualAccountsTab() {
  const { session } = useAuth();
  const canManage = hasPermission(session, PERMISSIONS.manageVirtualAccounts);
  const vas = useSyncedCollection<VirtualAccount>('rec_vas', 'rec_vas', seedVirtualAccounts, session);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<VirtualAccount | null>(null);
  const depts = tagFor(session, 'accounts');

  const t = today();
  const active = vas.items.filter(v => v.status === 'active').length;
  const matched = vas.items.filter(v => v.status === 'matched').length;
  const expired = vas.items.filter(v => v.status === 'expired').length;
  const pending = vas.items.filter(v => v.status === 'pending').length;
  const unmatachedValue = vas.items.filter(v => v.status !== 'matched').reduce((a, v) => a + v.amount, 0);

  const advance = (v: VirtualAccount) => {
    const next = v.status === 'pending' ? 'active' : v.status === 'active' ? 'matched' : v.status;
    vas.update(v.id, { status: next, expiresAt: next === 'active' && !v.expiresAt ? addDays(today(), 7) : v.expiresAt });
  };

  return (
    <div className="space-y-4">
      <SectionHeader title="Virtual Accounts" sub="Per-booking dedicated account numbers">
        {canManage && <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Create VA</Btn>}
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Pending" value={pending} sub="Awaiting activation" color="bg-blue-50 text-blue-700" />
        <MetricCard label="Active" value={active} sub="Live & accepting funds" color="bg-green-50 text-green-700" />
        <MetricCard label="Matched" value={matched} sub="Funds received" color="bg-amber-50 text-amber-700" />
        <MetricCard label="Outstanding" value={naira(unmatachedValue)} sub="Awaiting payment" color="bg-red-50 text-red-700" />
      </div>
      {showForm && (
        <VaForm initial={editItem} depts={depts} onSave={(v) => {
          if (editItem) vas.replace(v.id, v); else vas.add(v);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="divide-y">
          {vas.items.map(v => (
            <div key={v.id} className="p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
              <div className="flex-1 min-w-0">
                <div className="font-bold flex items-center gap-2 flex-wrap"><Banknote size={16} className="text-hom-primary" /> {v.guestName} <span className="text-zinc-400 font-normal text-sm">{v.bankName}</span></div>
                <div className="text-xs text-zinc-500 mt-0.5">{v.accountNumber} • {v.accountName} • Booking {v.bookingId}</div>
                <div className="text-xs text-zinc-400 mt-0.5">Created {fmtDate(v.createdAt)}{v.expiresAt && ` • Expires ${fmtDate(v.expiresAt)}`}</div>
              </div>
              <div className="flex items-center gap-3 flex-wrap">
                <span className="font-bold">{naira(v.amount)}</span>
                <StatusChip status={v.status} />
                {canManage && v.status !== 'matched' && (
                  <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => advance(v)}>Mark {v.status === 'pending' ? 'Active' : 'Matched'}</Btn>
                )}
                {canManage && <IconBtn onClick={() => { setEditItem(v); setShowForm(true); }}><Edit3 size={14} /></IconBtn>}
                {canManage && <IconBtn tone="red" onClick={() => vas.remove(v.id)}><Trash2 size={14} /></IconBtn>}
              </div>
            </div>
          ))}
          {vas.items.length === 0 && <EmptyState text="No virtual accounts" />}
        </div>
      </Card>
    </div>
  );
}

function VaForm({ initial, depts, onSave, onCancel }: { initial: VirtualAccount | null; depts: Department[]; onSave: (v: VirtualAccount) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { bookingId: initial.bookingId, guestName: initial.guestName, bankName: initial.bankName, accountNumber: initial.accountNumber, accountName: initial.accountName, amount: String(initial.amount) }
    : { bookingId: '', guestName: '', bankName: 'Wema', accountNumber: '', accountName: '', amount: '' });
  return (
    <FormCard title={initial ? 'Edit Virtual Account' : 'Create Virtual Account'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Guest Name"><TextInput value={f.guestName} onChange={e => setF({ ...f, guestName: e.target.value })} placeholder="Guest name" /></Field>
        <Field label="Booking ID"><TextInput value={f.bookingId} onChange={e => setF({ ...f, bookingId: e.target.value })} placeholder="Booking ID" /></Field>
        <Field label="Bank">
          <Select value={f.bankName} onChange={e => setF({ ...f, bankName: e.target.value })}>
            <option>Wema</option><option>Providus</option><option>Zenith</option><option>Access</option><option>GTBank</option>
          </Select>
        </Field>
        <Field label="Account Number"><TextInput value={f.accountNumber} onChange={e => setF({ ...f, accountNumber: e.target.value })} placeholder="Account number" /></Field>
        <Field label="Account Name"><TextInput value={f.accountName} onChange={e => setF({ ...f, accountName: e.target.value })} placeholder="Account name" /></Field>
        <Field label="Amount (₦)"><NumberInput value={f.amount} onChange={e => setF({ ...f, amount: e.target.value })} placeholder="Amount" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.guestName || !f.accountNumber || !f.amount) return alert('Guest, account number, and amount required'); onSave({ id: initial?.id || uid('rec'), ...f, amount: Number(f.amount), status: initial?.status || 'pending', createdAt: initial?.createdAt || nowISO(), expiresAt: initial?.expiresAt || addDays(today(), 7), departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Create VA'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── POS ─────────────────────────────────────────────────────────────────────

function PosTab() {
  const { session } = useAuth();
  const canManage = hasPermission(session, PERMISSIONS.trackPOSTerminals);
  const terminals = useSyncedCollection<PosTerminal>('rec_pos_terminals', 'rec_pos_terminals', seedPosTerminals, session);
  const settlements = useSyncedCollection<PosSettlement>('rec_pos_settlements', 'rec_pos_settlements', seedPosSettlements, session);
  const [showTerminal, setShowTerminal] = useState(false);
  const [showSettlement, setShowSettlement] = useState(false);
  const [editTerminal, setEditTerminal] = useState<PosTerminal | null>(null);
  const [editSettlement, setEditSettlement] = useState<PosSettlement | null>(null);
  const depts = tagFor(session, 'accounts');

  const pending = settlements.items.filter(s => s.status === 'pending');
  const settled = settlements.items.filter(s => s.status === 'settled');
  const flagged = settlements.items.filter(s => s.status === 'flagged');
  const pendingValue = pending.reduce((a, s) => a + s.amount, 0);

  return (
    <div className="space-y-4">
      <SectionHeader title="POS Terminals & Settlements" sub="Card payments reconciliation">
        {canManage && <Btn color="outline" onClick={() => { setShowTerminal(true); setEditTerminal(null); }}><Plus size={14} /> Add Terminal</Btn>}
        {canManage && <Btn onClick={() => { setShowSettlement(true); setEditSettlement(null); }}><Plus size={14} /> Log Settlement</Btn>}
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Active Terminals" value={terminals.items.filter(t => t.status === 'active').length} sub={`${terminals.items.length} total`} color="bg-blue-50 text-blue-700" />
        <MetricCard label="Pending Settlements" value={pending.length} sub={naira(pendingValue)} color="bg-amber-50 text-amber-700" />
        <MetricCard label="Settled" value={settled.length} sub={naira(settled.reduce((a, s) => a + s.amount, 0))} color="bg-green-50 text-green-700" />
        <MetricCard label="Flagged" value={flagged.length} sub="Needs attention" color="bg-red-50 text-red-700" />
      </div>
      {showTerminal && (
        <TerminalForm initial={editTerminal} depts={depts} onSave={(t) => {
          if (editTerminal) terminals.replace(t.id, t); else terminals.add(t);
          setShowTerminal(false); setEditTerminal(null);
        }} onCancel={() => { setShowTerminal(false); setEditTerminal(null); }} />
      )}
      {showSettlement && (
        <SettlementForm initial={editSettlement} terminals={terminals.items} depts={depts} onSave={(s) => {
          if (editSettlement) settlements.replace(s.id, s); else settlements.add(s);
          setShowSettlement(false); setEditSettlement(null);
        }} onCancel={() => { setShowSettlement(false); setEditSettlement(null); }} />
      )}
      <Card className="overflow-hidden">
        <div className="p-4 border-b font-bold text-sm flex items-center gap-2"><CreditCard size={14} /> Terminals</div>
        <div className="divide-y">
          {terminals.items.map(t => (
            <div key={t.id} className="p-3 flex items-center justify-between gap-3">
              <div className="min-w-0">
                <div className="font-bold text-sm">{t.terminalId} <span className="text-zinc-400 font-normal">— {t.bankName}</span></div>
                <div className="text-[10px] text-zinc-500">Merchant {t.merchantCode} • Added {fmtDate(t.addedAt)}</div>
              </div>
              <div className="flex items-center gap-2">
                <StatusChip status={t.status} />
                {canManage && (
                  <>
                    <button onClick={() => terminals.update(t.id, { status: t.status === 'active' ? 'inactive' : 'active' })}
                      className="text-[10px] px-2 py-1 rounded-full border font-medium hover:bg-zinc-50">{t.status === 'active' ? 'Deactivate' : 'Activate'}</button>
                    <IconBtn onClick={() => { setEditTerminal(t); setShowTerminal(true); }}><Edit3 size={13} /></IconBtn>
                    <IconBtn tone="red" onClick={() => terminals.remove(t.id)}><Trash2 size={13} /></IconBtn>
                  </>
                )}
              </div>
            </div>
          ))}
          {terminals.items.length === 0 && <EmptyState text="No POS terminals" />}
        </div>
      </Card>
      <Card className="overflow-hidden">
        <div className="p-4 border-b font-bold text-sm flex items-center gap-2"><Wallet size={14} /> Settlements</div>
        <div className="divide-y">
          {settlements.items.map(s => (
            <div key={s.id} className="p-3 flex flex-col md:flex-row md:items-center justify-between gap-3">
              <div className="min-w-0">
                <div className="font-bold text-sm">{naira(s.amount)} <span className="text-zinc-400 font-normal text-xs">— {s.terminalId}</span></div>
                <div className="text-[10px] text-zinc-500">{fmtDate(s.date)} • Ref {s.terminalRef} {s.note && `• ${s.note}`}</div>
              </div>
              <div className="flex items-center gap-2">
                <StatusChip status={s.status} />
                {canManage && s.status !== 'settled' && (
                  <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => settlements.update(s.id, { status: 'settled' })}>Mark Settled</Btn>
                )}
                {canManage && s.status !== 'flagged' && (
                  <IconBtn tone="amber" title="Flag" onClick={() => settlements.update(s.id, { status: 'flagged' })}><Split size={14} /></IconBtn>
                )}
                {canManage && <IconBtn title="Edit" onClick={() => { setEditSettlement(s); setShowSettlement(true); }}><Edit3 size={13} /></IconBtn>}
                {canManage && <IconBtn tone="red" title="Delete" onClick={() => settlements.remove(s.id)}><Trash2 size={13} /></IconBtn>}
              </div>
            </div>
          ))}
          {settlements.items.length === 0 && <EmptyState text="No settlements logged" />}
        </div>
      </Card>
    </div>
  );
}

function TerminalForm({ initial, depts, onSave, onCancel }: { initial: PosTerminal | null; depts: Department[]; onSave: (t: PosTerminal) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { terminalId: initial.terminalId, bankName: initial.bankName, merchantCode: initial.merchantCode }
    : { terminalId: '', bankName: 'GTBank', merchantCode: '' });
  return (
    <FormCard title={initial ? 'Edit Terminal' : 'Add Terminal'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Terminal ID"><TextInput value={f.terminalId} onChange={e => setF({ ...f, terminalId: e.target.value })} placeholder="Terminal ID" /></Field>
        <Field label="Bank">
          <Select value={f.bankName} onChange={e => setF({ ...f, bankName: e.target.value })}>
            <option>GTBank</option><option>FirstBank</option><option>Access</option><option>Zenith</option><option>Union</option>
          </Select>
        </Field>
        <Field label="Merchant Code"><TextInput value={f.merchantCode} onChange={e => setF({ ...f, merchantCode: e.target.value })} placeholder="Merchant code" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.terminalId) return alert('Terminal ID required'); onSave({ id: initial?.id || uid('rec'), ...f, status: initial?.status || 'active', addedAt: initial?.addedAt || nowISO(), departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Add Terminal'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

function SettlementForm({ initial, terminals, depts, onSave, onCancel }: { initial: PosSettlement | null; terminals: PosTerminal[]; depts: Department[]; onSave: (s: PosSettlement) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { terminalId: initial.terminalId, terminalRef: initial.terminalRef, amount: String(initial.amount), date: initial.date, note: initial.note || '' }
    : { terminalId: terminals[0]?.terminalId || '', terminalRef: '', amount: '', date: today(), note: '' });
  return (
    <FormCard title={initial ? 'Edit Settlement' : 'Log Settlement'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Terminal">
          <Select value={f.terminalId} onChange={e => setF({ ...f, terminalId: e.target.value })}>
            {terminals.map(t => <option key={t.id} value={t.terminalId}>{t.terminalId}</option>)}
          </Select>
        </Field>
        <Field label="Settlement Ref"><TextInput value={f.terminalRef} onChange={e => setF({ ...f, terminalRef: e.target.value })} placeholder="Settlement ref" /></Field>
        <Field label="Amount (₦)"><NumberInput value={f.amount} onChange={e => setF({ ...f, amount: e.target.value })} placeholder="Amount" /></Field>
        <Field label="Date"><DateInput value={f.date} onChange={e => setF({ ...f, date: e.target.value })} /></Field>
        <Field label="Note"><TextInput value={f.note} onChange={e => setF({ ...f, note: e.target.value })} placeholder="Optional note" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.amount) return alert('Amount required'); onSave({ id: initial?.id || uid('rec'), ...f, amount: Number(f.amount), note: f.note || undefined, status: initial?.status || 'pending', departments: initial?.departments || depts }); }}>{initial ? 'Update Settlement' : 'Log Settlement'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}
