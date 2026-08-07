'use client';

import { useState, useEffect } from 'react';
import Script from 'next/script';
import { CreditCard, MessageCircle, Globe, AlertTriangle, Trash2, Plus, Edit3, Check, X } from 'lucide-react';
import { Card, MetricCard, SectionHeader, Btn, IconBtn, Field, TextInput, Select, TextArea, FieldGrid, EmptyState } from '../ui';
import { load } from '@/lib/storage';
import { useScopedCollection } from '@/lib/scoped';
import { useSyncedCollection } from '@/lib/synced';
import { Room } from '@/lib/types';
import { seedRooms } from '@/lib/seed';
import { useAuth } from '@/lib/auth';
import { hasPermission, PERMISSIONS, tagFor } from '@/lib/rbac';
import { uid } from '@/lib/format';
import { sendWhatsApp } from '@/lib/whatsapp';
import { seedWhatsAppTemplates, WhatsAppTemplate, WhatsAppTemplateEntity } from '@/lib/whatsapptemplates';
import { fetchBookingComBookings, checkOverbooking, ExternalBooking } from '@/lib/bookingcom';
import { WhatsAppLogEntry, removeWhatsAppLog, clearWhatsAppLog } from '@/lib/whatsapplog';

// ─── Paystack ────────────────────────────────────────────────────────────────

export function PaystackModule() {
  const [paystackKey] = useState(process.env.NEXT_PUBLIC_PAYSTACK_PUBLIC_KEY || '');
  const openPaystack = (email: string, amount: number) => {
    const key = paystackKey || 'pk_test_754731e7a9876ece4826c96a4f7734c189e7f7c6';
    // @ts-ignore
    const handler = window.PaystackPop?.setup({ key, email, amount, currency: 'NGN', callback: () => alert('Payment successful!'), onClose: () => {} });
    handler?.openIframe();
  };
  return (
    <>
      <Script src="https://js.paystack.co/v1/inline.js" strategy="lazyOnload" />
      <Card className="p-8 border max-w-lg mx-auto text-center">
        <CreditCard size={48} className="mx-auto text-hom-primary mb-4" />
        <h3 className="font-black text-2xl">Paystack Payments</h3>
        <p className="text-sm text-zinc-500 mt-2">Process payments via Paystack inline checkout.</p>
        <div className="mt-6 space-y-3">
          <Btn className="!w-full !justify-center" onClick={() => openPaystack('guest@hom.ng', 1500000)}>Pay ₦15,000 — Guest Payment</Btn>
          <Btn color="amber" className="!w-full !justify-center" onClick={() => openPaystack('vendor@hom.ng', 500000)}>Pay ₦5,000 — Vendor Payment</Btn>
        </div>
        <p className="text-[10px] text-zinc-400 mt-4">Key: {(paystackKey || 'pk_test_7547...').slice(0, 20)}...</p>
      </Card>
    </>
  );
}

// ─── WhatsApp ────────────────────────────────────────────────────────────────

export function WhatsAppModule() {
  const { session } = useAuth();
  const [log, setLog] = useState<WhatsAppLogEntry[]>([]);
  const [refreshing, setRefreshing] = useState(false);
  const templates = useScopedCollection<WhatsAppTemplate>('hom_whatsapp_templates', seedWhatsAppTemplates, session);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState({ name: '', entityType: 'other' as WhatsAppTemplateEntity, message: '' });

  const canManage = hasPermission(session, PERMISSIONS.manageWhatsApp);
  const depts = tagFor(session, 'management');

  useEffect(() => {
    setLog(load<WhatsAppLogEntry[]>('hom_whatsapp_log', []));
  }, []);

  const startNew = () => {
    setForm({ name: '', entityType: 'other', message: '' });
    setEditId('new');
  };

  const startEdit = (t: WhatsAppTemplate) => {
    setForm({ name: t.name, entityType: t.entityType, message: t.message });
    setEditId(t.id);
  };

  const saveTemplate = () => {
    if (!form.name.trim() || !form.message.trim()) return;
    if (editId === 'new') {
      templates.add({ id: uid('tmp'), name: form.name.trim(), entityType: form.entityType, message: form.message, departments: depts });
    } else if (editId) {
      templates.replace(editId, { id: editId, name: form.name.trim(), entityType: form.entityType, message: form.message, departments: depts });
    }
    setEditId(null);
  };

  return (
    <div className="space-y-4">
      <Card className="p-6 border">
        <div className="flex justify-between items-start gap-3 flex-wrap">
          <div>
            <h3 className="font-black text-xl flex items-center gap-2"><MessageCircle size={20} className="text-green-600" /> WhatsApp Cloud API</h3>
            <p className="text-sm text-zinc-600 mt-2">Set <code>NEXT_PUBLIC_WHATSAPP_TOKEN</code> and <code>NEXT_PUBLIC_WHATSAPP_PHONE_ID</code> in .env to enable live messaging.</p>
          </div>
          <Btn color="outline" onClick={async () => { setRefreshing(true); await sendWhatsApp('+2348000000000', 'HOM WhatsApp test message'); setLog(load<WhatsAppLogEntry[]>('hom_whatsapp_log', [])); setRefreshing(false); }}>{refreshing ? 'Sending...' : 'Send Test'}</Btn>
        </div>
        <div className="mt-4 grid md:grid-cols-3 gap-3">
          <div className="bg-green-50 rounded-xl p-4 text-center"><div className="text-2xl font-black">{log.length}</div><div className="text-xs text-green-700">Messages Sent</div></div>
          <div className="bg-zinc-50 rounded-xl p-4 text-center"><div className="text-2xl font-black">{log.filter(m => m.msg.includes('booking')).length}</div><div className="text-xs text-zinc-500">Booking Confirms</div></div>
          <div className="bg-zinc-50 rounded-xl p-4 text-center"><div className="text-2xl font-black">{templates.items.length}</div><div className="text-xs text-zinc-500">Templates</div></div>
        </div>
      </Card>

      <Card className="border p-5">
        <div className="flex justify-between items-center gap-3 flex-wrap">
          <SectionHeader title={`Message Templates (${templates.items.length})`} sub="Placeholders like [Guest], [Room] are replaced at send time." />
          {canManage && <Btn onClick={startNew}><Plus size={14} /> New Template</Btn>}
        </div>
        {editId && canManage && (
          <div className="mt-4 border rounded-xl p-4 bg-zinc-50 space-y-3">
            <FieldGrid>
              <Field label="Template Name">
                <TextInput value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} placeholder="e.g. Booking Confirmation" />
              </Field>
              <Field label="Entity Type">
                <Select value={form.entityType} onChange={e => setForm({ ...form, entityType: e.target.value as WhatsAppTemplateEntity })}>
                  {(['booking', 'staff', 'vendor', 'subscription', 'compliance', 'other'] as const).map(e => (
                    <option key={e} value={e}>{e.charAt(0).toUpperCase() + e.slice(1)}</option>
                  ))}
                </Select>
              </Field>
            </FieldGrid>
            <Field label="Message">
              <TextArea value={form.message} onChange={e => setForm({ ...form, message: e.target.value })} rows={5} placeholder="Dear [Guest], your booking at HOM Hotel is confirmed!" />
            </Field>
            <div className="flex gap-2">
              <Btn onClick={saveTemplate}><Check size={14} /> Save</Btn>
              <Btn color="outline" onClick={() => setEditId(null)}><X size={14} /> Cancel</Btn>
            </div>
          </div>
        )}
        <div className="mt-4 space-y-2">
          {templates.items.length === 0 && <EmptyState text="No templates yet. Create your first one." />}
          {templates.items.map(t => (
            <div key={t.id} className="border rounded-xl p-3 flex items-start gap-3">
              <div className="flex-1 min-w-0">
                <div className="font-bold text-sm">{t.name} <span className="ml-1 text-[10px] uppercase bg-green-100 text-green-700 rounded-full px-2 py-0.5">{t.entityType}</span></div>
                <div className="text-xs text-zinc-500 mt-0.5 break-words">{t.message.replace(/\[[^\]]*\]/g, '…')}</div>
              </div>
              {canManage && (
                <div className="flex gap-1 shrink-0">
                  <IconBtn title="Edit" onClick={() => startEdit(t)}><Edit3 size={13} /></IconBtn>
                  <IconBtn tone="red" title="Delete" onClick={() => templates.remove(t.id)}><Trash2 size={13} /></IconBtn>
                </div>
              )}
            </div>
          ))}
        </div>
      </Card>

      {log.length > 0 && (
        <Card className="border overflow-hidden">
          <div className="p-4 border-b font-bold text-sm flex items-center justify-between">
            <span>Message Log</span>
            <Btn color="outline" className="!px-3 !py-1 !text-[11px] !text-red-500" onClick={() => { clearWhatsAppLog(); setLog([]); }}><Trash2 size={12} /> Clear Log</Btn>
          </div>
          <div className="divide-y max-h-80 overflow-y-auto">
            {log.map((m, i) => (
              <div key={i} className="p-3 text-sm flex items-start gap-2">
                <div className="flex-1 min-w-0">
                  <div className="flex justify-between"><span className="font-medium">{m.to}</span><span className="text-[10px] text-zinc-400">{m.time}</span></div>
                  <div className="text-xs text-zinc-600 mt-0.5 break-words">{m.msg}</div>
                </div>
                <IconBtn tone="red" title="Delete entry" onClick={() => { removeWhatsAppLog(i); setLog(load<WhatsAppLogEntry[]>('hom_whatsapp_log', [])); }}><Trash2 size={12} /></IconBtn>
              </div>
            ))}
          </div>
        </Card>
      )}
    </div>
  );
}

// ─── Booking.com ─────────────────────────────────────────────────────────────

export function BookingComModule() {
  const { session } = useAuth();
  const rooms = useSyncedCollection<Room>('rooms', 'hom_rooms', seedRooms, session);
  const [external, setExternal] = useState<ExternalBooking[]>([]);

  useEffect(() => {
    fetchBookingComBookings().then(setExternal);
  }, []);

  return (
    <div className="space-y-4">
      <Card className="p-6 border">
        <h3 className="font-black text-xl flex items-center gap-2"><Globe size={20} className="text-blue-600" /> Booking.com Channel Manager</h3>
        <p className="text-sm text-zinc-600 mt-2">Sync external bookings and prevent overbooking between Booking.com and walk-ins.</p>
      </Card>
      <div className="grid md:grid-cols-2 gap-4">
        <Card className="border p-5">
          <h4 className="font-bold text-sm">External Bookings ({external.length})</h4>
          <div className="mt-3 divide-y">
            {external.map(b => (
              <div key={b.id} className="py-3 text-sm">
                <div className="font-medium">{b.guest}</div>
                <div className="text-xs text-zinc-500">{b.roomType} • {b.checkin} → {b.checkout}</div>
              </div>
            ))}
          </div>
        </Card>
        <Card className="border p-5">
          <h4 className="font-bold text-sm flex items-center gap-2"><AlertTriangle size={14} /> Overbooking Check</h4>
          <div className="mt-3">
            {(() => {
              const result = checkOverbooking(rooms.items, external, new Date().toISOString().slice(0, 10));
              return (
                <div className="space-y-2 text-sm">
                  <div>Available rooms: <span className="font-bold">{result.available}</span></div>
                  <div>Externally occupied: <span className="font-bold">{result.occupied}</span></div>
                  <div className={`p-3 rounded-xl font-medium ${result.risk ? 'bg-red-50 text-red-700' : 'bg-green-50 text-green-700'}`}>
                    {result.risk ? 'HIGH RISK — Overbooking detected!' : 'SAFE — Can accept new bookings'}
                  </div>
                </div>
              );
            })()}
          </div>
        </Card>
      </div>
    </div>
  );
}
