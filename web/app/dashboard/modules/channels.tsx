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
import { hasPermission, isManagement, PERMISSIONS, tagFor } from '@/lib/rbac';
import { uid } from '@/lib/format';
import { apiCall } from '@/lib/firebase';
import { sendWhatsApp, waMeUrl } from '@/lib/whatsapp';
import { seedWhatsAppTemplates, WhatsAppTemplate, WhatsAppTemplateEntity } from '@/lib/whatsapptemplates';
import { fetchBookingComBookings, checkOverbooking, ExternalBooking } from '@/lib/bookingcom';
import { WhatsAppLogEntry, appendWhatsAppLog, removeWhatsAppLog, clearWhatsAppLog } from '@/lib/whatsapplog';

// ─── Channel Settings (Paystack / Booking.com) ───────────────────────────────

export function ChannelSettingsModule() {
  const { session } = useAuth();
  const canConfig = isManagement(session);
  const [form, setForm] = useState({
    payPublicKey: '', payBusinessName: '',
    bcAccountId: '', bcEmail: '', bcPropertyId: '', bcSync: false,
  });
  const [saved, setSaved] = useState('');
  const [busy, setBusy] = useState(false);

  const load = () => {
    apiCall<any>('GET', '/api/settings/channels').then((s) => {
      setForm({
        payPublicKey: s.paystack?.publicKey ?? '',
        payBusinessName: s.paystack?.businessName ?? '',
        bcAccountId: s.bookingCom?.accountId ?? '',
        bcEmail: s.bookingCom?.email ?? '',
        bcPropertyId: s.bookingCom?.propertyId ?? '',
        bcSync: s.bookingCom?.syncExternal === true,
      });
    }).catch(() => {});
  };

  useEffect(() => { load(); }, []);

  const save = async () => {
    setBusy(true); setSaved('');
    try {
      await apiCall<any>('POST', '/api/settings/channels', {
        paystack: { publicKey: form.payPublicKey.trim(), businessName: form.payBusinessName.trim() },
        bookingCom: { accountId: form.bcAccountId.trim(), email: form.bcEmail.trim(), propertyId: form.bcPropertyId.trim(), syncExternal: form.bcSync },
      });
      setSaved('Channel settings saved.');
    } catch (e: any) {
      setSaved(e.message ?? 'Failed to save.');
    } finally {
      setBusy(false);
    }
  };

  if (!canConfig) {
    return (
      <Card className="p-6 border">
        <h3 className="font-black text-xl flex items-center gap-2"><CreditCard size={20} className="text-hom-primary" /> Channel Settings</h3>
        <p className="text-sm text-zinc-600 mt-2">Hotel-scoped Paystack and Booking.com config is managed by management accounts.</p>
      </Card>
    );
  }

  return (
    <Card className="p-5 border">
      <SectionHeader title="Channel Settings" sub="Hotel-scoped Paystack public key and Booking.com credentials. Used by the Paystack and Booking.com modules." />
      <div className="mt-4 grid md:grid-cols-2 gap-4">
        <div className="border rounded-xl p-4 bg-zinc-50">
          <h4 className="font-bold text-sm text-hom-primary">Paystack</h4>
          <FieldGrid className="mt-2">
            <Field label="Public Key">
              <TextInput value={form.payPublicKey} onChange={e => setForm({ ...form, payPublicKey: e.target.value })} placeholder="pk_live_..." />
            </Field>
            <Field label="Business Name">
              <TextInput value={form.payBusinessName} onChange={e => setForm({ ...form, payBusinessName: e.target.value })} placeholder="e.g. HOM Hotel Ikoyi" />
            </Field>
          </FieldGrid>
        </div>
        <div className="border rounded-xl p-4 bg-zinc-50">
          <h4 className="font-bold text-sm text-blue-600">Booking.com</h4>
          <FieldGrid className="mt-2">
            <Field label="Account ID">
              <TextInput value={form.bcAccountId} onChange={e => setForm({ ...form, bcAccountId: e.target.value })} placeholder="Booking.com account id" />
            </Field>
            <Field label="Email">
              <TextInput value={form.bcEmail} onChange={e => setForm({ ...form, bcEmail: e.target.value })} placeholder="channel@hotel.ng" />
            </Field>
          </FieldGrid>
          <FieldGrid className="mt-2">
            <Field label="Property ID">
              <TextInput value={form.bcPropertyId} onChange={e => setForm({ ...form, bcPropertyId: e.target.value })} placeholder="Booking.com property id" />
            </Field>
            <Field label=" "><span className="inline-flex items-center gap-2 text-sm text-zinc-600 mt-1"><input type="checkbox" checked={form.bcSync} onChange={e => setForm({ ...form, bcSync: e.target.checked })} className="accent-blue-600" /> Sync external bookings</span></Field>
          </FieldGrid>
        </div>
      </div>
      <div className="mt-4 flex items-center gap-3">
        <Btn onClick={save} disabled={busy}><Check size={14} /> {busy ? 'Saving...' : 'Save Settings'}</Btn>
        {saved && <span className="text-sm text-zinc-500">{saved}</span>}
      </div>
    </Card>
  );
}

// ─── Paystack ────────────────────────────────────────────────────────────────

export function PaystackModule() {
  const [paystackKey, setPaystackKey] = useState('');
  const [businessName, setBusinessName] = useState('');
  useEffect(() => {
    apiCall<any>('GET', '/api/settings/channels').then((s) => {
      setPaystackKey(s.paystack?.publicKey ?? '');
      setBusinessName(s.paystack?.businessName ?? '');
    }).catch(() => {});
  }, []);
  const openPaystack = (email: string, amount: number) => {
    // Hotel-scoped public key from settings. No hardcoded test keys.
    const key = paystackKey;
    if (!key) return alert('No Paystack public key configured. Set it in Settings.');
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
        <p className="text-sm text-zinc-500 mt-2">Process payments via Paystack inline checkout using your hotel's own key.</p>
        <div className="mt-6 space-y-3">
          <Btn className="!w-full !justify-center" onClick={() => openPaystack('guest@hom.ng', 1500000)}>Pay ₦15,000 — Guest Payment</Btn>
          <Btn color="amber" className="!w-full !justify-center" onClick={() => openPaystack('vendor@hom.ng', 500000)}>Pay ₦5,000 — Vendor Payment</Btn>
        </div>
        <p className="text-[10px] text-zinc-400 mt-4">Key: {paystackKey ? `${paystackKey.slice(0, 14)}…` : 'not configured'}{businessName ? ` • ${businessName}` : ''}</p>
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
  const canConfig = canManage && isManagement(session);
  const depts = tagFor(session, 'management');

  const emptyWaba = {
    phoneId: '', wabaId: '', displayName: '', verified: false, templateApprovals: [] as string[],
    autoSend: { bookingConfirm: true, guestWelcome: false, checkoutReminder: true, payslip: false, purchaseOrder: false },
  };
  const [waba, setWaba] = useState(emptyWaba);
  const [token, setToken] = useState('');
  const [wabaMsg, setWabaMsg] = useState('');
  const [wabaBusy, setWabaBusy] = useState(false);

  const loadWaba = async () => {
    try {
      const s = await apiCall<any>('GET', '/api/whatsapp/settings');
      setWaba({
        phoneId: s.phoneId ?? '', wabaId: s.wabaId ?? '', displayName: s.displayName ?? '',
        verified: !!s.verified, templateApprovals: s.templateApprovals ?? [],
        autoSend: { ...emptyWaba.autoSend, ...(s.autoSend ?? {}) },
      });
    } catch (e: any) {
      console.log('WABA settings load failed', e);
    }
  };

  const saveWaba = async () => {
    setWabaBusy(true);
    setWabaMsg('');
    try {
      await apiCall<any>('POST', '/api/whatsapp/settings', { ...waba, token: token.trim() });
      setToken('');
      setWabaMsg('Saved. WhatsApp now sends via the server (Admin SDK).');
    } catch (e: any) {
      setWabaMsg(e.message ?? 'Failed to save settings.');
    } finally {
      setWabaBusy(false);
    }
  };

  useEffect(() => {
    setLog(load<WhatsAppLogEntry[]>('hom_whatsapp_log', []));
    if (canConfig) loadWaba();
  }, [canConfig]);

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
            <p className="text-sm text-zinc-600 mt-2">Messages are sent through HOM's server (Admin SDK). Configure your WABA below to go live; until then, sends fall back to wa.me links and a local mock log.</p>
          </div>
          <Btn color="outline" onClick={async () => {
            setRefreshing(true);
            const r = await sendWhatsApp('+2348000000000', 'HOM WhatsApp test message');
            if (!r.ok && r.mocked) {
              appendWhatsAppLog('+2348000000000', '[wa.me fallback] HOM WhatsApp test message');
            }
            setLog(load<WhatsAppLogEntry[]>('hom_whatsapp_log', []));
            setRefreshing(false);
          }}>{refreshing ? 'Sending...' : 'Send Test'}</Btn>
        </div>
        <div className="mt-4 grid md:grid-cols-3 gap-3">
          <div className="bg-green-50 rounded-xl p-4 text-center"><div className="text-2xl font-black">{log.length}</div><div className="text-xs text-green-700">Messages Sent</div></div>
          <div className="bg-zinc-50 rounded-xl p-4 text-center"><div className="text-2xl font-black">{log.filter(m => m.msg.includes('booking')).length}</div><div className="text-xs text-zinc-500">Booking Confirms</div></div>
          <div className="bg-zinc-50 rounded-xl p-4 text-center"><div className="text-2xl font-black">{templates.items.length}</div><div className="text-xs text-zinc-500">Templates</div></div>
        </div>
      </Card>

      {canConfig && (
        <Card className="p-5 border">
          <SectionHeader title="WABA Settings" sub="Per-hotel WhatsApp Business config. The access token is stored server-side only and never exposed to the browser." />
          <FieldGrid className="mt-3">
            <Field label="Phone ID">
              <TextInput value={waba.phoneId} onChange={e => setWaba({ ...waba, phoneId: e.target.value })} placeholder="e.g. 123456789012345" />
            </Field>
            <Field label="WABA ID">
              <TextInput value={waba.wabaId} onChange={e => setWaba({ ...waba, wabaId: e.target.value })} placeholder="e.g. 987654321098765" />
            </Field>
          </FieldGrid>
          <FieldGrid className="mt-3">
            <Field label="Display Name">
              <TextInput value={waba.displayName} onChange={e => setWaba({ ...waba, displayName: e.target.value })} placeholder="e.g. HOM Hotel Ikoyi" />
            </Field>
            <Field label="Access Token (secret — leave blank to keep)">
              <TextInput type="password" value={token} onChange={e => setToken(e.target.value)} placeholder="••••••••••••••••" />
            </Field>
          </FieldGrid>
          <div className="mt-3 flex flex-wrap items-center gap-x-6 gap-y-2">
            <label className="flex items-center gap-2 text-sm text-zinc-600">
              <input type="checkbox" checked={waba.verified} onChange={e => setWaba({ ...waba, verified: e.target.checked })} className="accent-green-600" /> Business verified
            </label>
            {Object.entries(waba.autoSend).map(([k, v]) => (
              <label key={k} className="flex items-center gap-2 text-sm text-zinc-600">
                <input type="checkbox" checked={v} onChange={e => setWaba({ ...waba, autoSend: { ...waba.autoSend, [k]: e.target.checked } })} className="accent-hom-primary" />
                {k === 'bookingConfirm' ? 'Booking confirm' : k === 'guestWelcome' ? 'Guest welcome' : k === 'checkoutReminder' ? 'Checkout reminder' : k === 'payslip' ? 'Payslip' : 'Purchase order'}
              </label>
            ))}
          </div>
          <div className="mt-4 flex items-center gap-3">
            <Btn onClick={saveWaba} disabled={wabaBusy}><Check size={14} /> {wabaBusy ? 'Saving...' : 'Save Settings'}</Btn>
            {wabaMsg && <span className="text-sm text-zinc-500">{wabaMsg}</span>}
          </div>
        </Card>
      )}

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
      <ChannelSettingsModule />
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
