'use client';

import { useState } from 'react';
import { Plus, Trash2, Edit3, Link2, Split, Banknote, Wallet, CreditCard, Search, Upload } from 'lucide-react';
import {
  BankTransaction, ReconciliationMatch, SplitPayment, VirtualAccount,
  PosTerminal, PosSettlement, MatchEntityType, Booking, ExpenditureRecord,
} from '@/lib/types';
import {
  seedBankTransactions, seedMatches, seedVirtualAccounts, seedPosTerminals, seedPosSettlements, seedBookings, seedExpenditure,
} from '@/lib/seed';
import { useCollection } from '@/lib/storage';
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
  const txns = useCollection<BankTransaction>('rec_bank_txns', seedBankTransactions);
  const matches = useCollection<ReconciliationMatch>('rec_matches', seedMatches);
  const bookings = useCollection<Booking>('hom_bookings', seedBookings);
  const exp = useCollection<ExpenditureRecord>('expenditure_records', seedExpenditure);
  const [filter, setFilter] = useState<'all' | 'matched' | 'unmatched'>('all');
  const [search, setSearch] = useState('');
  const [matchTxn, setMatchTxn] = useState<BankTransaction | null>(null);

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
      entityLabel: entity.label, entityAmount: entity.amount, matchedAmount: amt, confidence: 1, isManual: true, matchedAt: nowISO(),
    });
    setMatchTxn(null);
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
          <TextInput value={search} onChange={e => setSearch(e.target.value)} placeholder="Search transactions..." className="!py-1.5 !pl-9 !w-56" />
        </div>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Transactions" value={txns.items.length} sub="On statement" color="bg-blue-50 text-blue-700" />
        <MetricCard label="Matched" value={matchedIds.size} sub="Reconciled" color="bg-green-50 text-green-700" />
        <MetricCard label="Unmatched" value={txns.items.length - matchedIds.size} sub="Awaiting match" color="bg-red-50 text-red-700" />
        <MetricCard label="Net Inflow" value={naira(totalCredits - totalDebits)} sub={`${naira(totalCredits)} CR • ${naira(totalDebits)} DR`} color="bg-amber-50 text-amber-700" />
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div className="h-2 bg-zinc-100 rounded-full overflow-hidden">
          <div className="h-full bg-hom-primary rounded-full" style={{ width: `${txns.items.length ? (matchedIds.size / txns.items.length) * 100 : 0}%` }} />
        </div>
        <div className="text-xs text-zinc-400 -mt-3">{txns.items.length ? ((matchedIds.size / txns.items.length) * 100).toFixed(0) : 0}% reconciled</div>
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
                    <IconBtn tone="red" title="Unmatch" onClick={() => matches.remove(m.id)}><Trash2 size={14} /></IconBtn>
                  ) : (
                    <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => setMatchTxn(t)}><Link2 size={12} /> Match</Btn>
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
    </div>
  );
}

// ─── Virtual Accounts ────────────────────────────────────────────────────────

function VirtualAccountsTab() {
  const vas = useCollection<VirtualAccount>('rec_vas', seedVirtualAccounts);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<VirtualAccount | null>(null);

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
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Create VA</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Pending" value={pending} sub="Awaiting activation" color="bg-blue-50 text-blue-700" />
        <MetricCard label="Active" value={active} sub="Live & accepting funds" color="bg-green-50 text-green-700" />
        <MetricCard label="Matched" value={matched} sub="Funds received" color="bg-amber-50 text-amber-700" />
        <MetricCard label="Outstanding" value={naira(unmatachedValue)} sub="Awaiting payment" color="bg-red-50 text-red-700" />
      </div>
      {showForm && (
        <VaForm initial={editItem} onSave={(v) => {
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
                {v.status !== 'matched' && (
                  <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => advance(v)}>Mark {v.status === 'pending' ? 'Active' : 'Matched'}</Btn>
                )}
                <IconBtn onClick={() => { setEditItem(v); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
                <IconBtn tone="red" onClick={() => vas.remove(v.id)}><Trash2 size={14} /></IconBtn>
              </div>
            </div>
          ))}
          {vas.items.length === 0 && <EmptyState text="No virtual accounts" />}
        </div>
      </Card>
    </div>
  );
}

function VaForm({ initial, onSave, onCancel }: { initial: VirtualAccount | null; onSave: (v: VirtualAccount) => void; onCancel: () => void }) {
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
        <Btn onClick={() => { if (!f.guestName || !f.accountNumber || !f.amount) return alert('Guest, account number, and amount required'); onSave({ id: initial?.id || uid('rec'), ...f, amount: Number(f.amount), status: initial?.status || 'pending', createdAt: initial?.createdAt || nowISO(), expiresAt: initial?.expiresAt || addDays(today(), 7) }); }}>{initial ? 'Update' : 'Create VA'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── POS ─────────────────────────────────────────────────────────────────────

function PosTab() {
  const terminals = useCollection<PosTerminal>('rec_pos_terminals', seedPosTerminals);
  const settlements = useCollection<PosSettlement>('rec_pos_settlements', seedPosSettlements);
  const [showTerminal, setShowTerminal] = useState(false);
  const [showSettlement, setShowSettlement] = useState(false);
  const [editTerminal, setEditTerminal] = useState<PosTerminal | null>(null);

  const pending = settlements.items.filter(s => s.status === 'pending');
  const settled = settlements.items.filter(s => s.status === 'settled');
  const flagged = settlements.items.filter(s => s.status === 'flagged');
  const pendingValue = pending.reduce((a, s) => a + s.amount, 0);

  return (
    <div className="space-y-4">
      <SectionHeader title="POS Terminals & Settlements" sub="Card payments reconciliation">
        <Btn color="outline" onClick={() => { setShowTerminal(true); setEditTerminal(null); }}><Plus size={14} /> Add Terminal</Btn>
        <Btn onClick={() => setShowSettlement(true)}><Plus size={14} /> Log Settlement</Btn>
      </SectionHeader>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Active Terminals" value={terminals.items.filter(t => t.status === 'active').length} sub={`${terminals.items.length} total`} color="bg-blue-50 text-blue-700" />
        <MetricCard label="Pending Settlements" value={pending.length} sub={naira(pendingValue)} color="bg-amber-50 text-amber-700" />
        <MetricCard label="Settled" value={settled.length} sub={naira(settled.reduce((a, s) => a + s.amount, 0))} color="bg-green-50 text-green-700" />
        <MetricCard label="Flagged" value={flagged.length} sub="Needs attention" color="bg-red-50 text-red-700" />
      </div>
      {showTerminal && (
        <TerminalForm initial={editTerminal} onSave={(t) => {
          if (editTerminal) terminals.replace(t.id, t); else terminals.add(t);
          setShowTerminal(false); setEditTerminal(null);
        }} onCancel={() => { setShowTerminal(false); setEditTerminal(null); }} />
      )}
      {showSettlement && (
        <SettlementForm terminals={terminals.items} onSave={(s) => { settlements.add(s); setShowSettlement(false); }} onCancel={() => setShowSettlement(false)} />
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
                <button onClick={() => terminals.update(t.id, { status: t.status === 'active' ? 'inactive' : 'active' })}
                  className="text-[10px] px-2 py-1 rounded-full border font-medium hover:bg-zinc-50">{t.status === 'active' ? 'Deactivate' : 'Activate'}</button>
                <IconBtn onClick={() => { setEditTerminal(t); setShowTerminal(true); }}><Edit3 size={13} /></IconBtn>
                <IconBtn tone="red" onClick={() => terminals.remove(t.id)}><Trash2 size={13} /></IconBtn>
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
                {s.status !== 'settled' && (
                  <Btn color="outline" className="!px-3 !py-1 !text-[11px]" onClick={() => settlements.update(s.id, { status: 'settled' })}>Mark Settled</Btn>
                )}
                {s.status !== 'flagged' && (
                  <IconBtn tone="amber" title="Flag" onClick={() => settlements.update(s.id, { status: 'flagged' })}><Split size={14} /></IconBtn>
                )}
              </div>
            </div>
          ))}
          {settlements.items.length === 0 && <EmptyState text="No settlements logged" />}
        </div>
      </Card>
    </div>
  );
}

function TerminalForm({ initial, onSave, onCancel }: { initial: PosTerminal | null; onSave: (t: PosTerminal) => void; onCancel: () => void }) {
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
        <Btn onClick={() => { if (!f.terminalId) return alert('Terminal ID required'); onSave({ id: initial?.id || uid('rec'), ...f, status: initial?.status || 'active', addedAt: initial?.addedAt || nowISO() }); }}>{initial ? 'Update' : 'Add Terminal'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

function SettlementForm({ terminals, onSave, onCancel }: { terminals: PosTerminal[]; onSave: (s: PosSettlement) => void; onCancel: () => void }) {
  const [f, setF] = useState({ terminalId: terminals[0]?.terminalId || '', terminalRef: '', amount: '', date: today() });
  return (
    <FormCard title="Log Settlement" onCancel={onCancel}>
      <FieldGrid>
        <Field label="Terminal">
          <Select value={f.terminalId} onChange={e => setF({ ...f, terminalId: e.target.value })}>
            {terminals.map(t => <option key={t.id} value={t.terminalId}>{t.terminalId}</option>)}
          </Select>
        </Field>
        <Field label="Settlement Ref"><TextInput value={f.terminalRef} onChange={e => setF({ ...f, terminalRef: e.target.value })} placeholder="Settlement ref" /></Field>
        <Field label="Amount (₦)"><NumberInput value={f.amount} onChange={e => setF({ ...f, amount: e.target.value })} placeholder="Amount" /></Field>
        <Field label="Date"><DateInput value={f.date} onChange={e => setF({ ...f, date: e.target.value })} /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.amount) return alert('Amount required'); onSave({ id: uid('rec'), ...f, amount: Number(f.amount), status: 'pending' }); }}>Log Settlement</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}
