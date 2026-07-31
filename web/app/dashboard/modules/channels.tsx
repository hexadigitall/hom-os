'use client';

import { useState, useEffect } from 'react';
import Script from 'next/script';
import { CreditCard, MessageCircle, Globe, AlertTriangle } from 'lucide-react';
import { Card, MetricCard, SectionHeader, Btn } from '../ui';
import { useCollection, load } from '@/lib/storage';
import { Room } from '@/lib/types';
import { seedRooms } from '@/lib/seed';
import { sendWhatsApp } from '@/lib/whatsapp';
import { fetchBookingComBookings, checkOverbooking, ExternalBooking } from '@/lib/bookingcom';
import { WhatsAppLogEntry } from '@/lib/whatsapplog';

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
  const [log, setLog] = useState<WhatsAppLogEntry[]>([]);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    setLog(load<WhatsAppLogEntry[]>('hom_whatsapp_log', []));
  }, []);

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
          <div className="bg-zinc-50 rounded-xl p-4 text-center"><div className="text-2xl font-black">{log.filter(m => m.msg.includes('Payslip') || m.msg.includes('Net')).length}</div><div className="text-xs text-zinc-500">Payslips</div></div>
        </div>
      </Card>
      {log.length > 0 && (
        <Card className="border overflow-hidden">
          <div className="p-4 border-b font-bold text-sm">Message Log</div>
          <div className="divide-y max-h-80 overflow-y-auto">
            {log.map((m, i) => (
              <div key={i} className="p-3 text-sm">
                <div className="flex justify-between"><span className="font-medium">{m.to}</span><span className="text-[10px] text-zinc-400">{m.time}</span></div>
                <div className="text-xs text-zinc-600 mt-0.5 break-words">{m.msg}</div>
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
  const rooms = useCollection<Room>('hom_rooms', seedRooms);
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
