'use client';

import { useState } from 'react';
import { Menu, X, Search, LayoutDashboard, CalendarCheck, BedDouble, Fuel, Package, Users, Store, Receipt, Repeat, Activity, Scale, UtensilsCrossed, Wrench, Sparkles, Briefcase, ShieldCheck, BarChart3, ScrollText, CreditCard, MessageCircle, Globe } from 'lucide-react';
import { OverviewModule, BookingsModule, RoomsModule, DieselModule, InventoryModule, StaffModule, VendorsModule } from './modules/core';
import { ExpensesModule } from './modules/expenses';
import { SubscriptionsModule } from './modules/subscriptions';
import { OperationsModule } from './modules/operations';
import { ReconciliationModule } from './modules/reconciliation';
import { FnbModule } from './modules/fnb';
import { EngineeringModule } from './modules/engineering';
import { HousekeepingModule } from './modules/housekeeping';
import { BackOfficeModule } from './modules/back_office';
import { SecurityAuditModule } from './modules/security_audit';
import { ReportsModule } from './modules/reports';
import { ComplianceModule } from './modules/compliance';
import { PaystackModule, WhatsAppModule, BookingComModule } from './modules/channels';

const NAV: { id: string; label: string; icon: any; module: () => JSX.Element }[] = [
  { id: 'overview', label: 'Overview', icon: LayoutDashboard, module: OverviewModule },
  { id: 'bookings', label: 'Bookings', icon: CalendarCheck, module: BookingsModule },
  { id: 'rooms', label: 'Rooms', icon: BedDouble, module: RoomsModule },
  { id: 'operations', label: 'Operations', icon: Activity, module: OperationsModule },
  { id: 'reconciliation', label: 'Reconciliation', icon: Scale, module: ReconciliationModule },
  { id: 'expenses', label: 'Expenses', icon: Receipt, module: ExpensesModule },
  { id: 'subscriptions', label: 'Subscriptions', icon: Repeat, module: SubscriptionsModule },
  { id: 'fnb', label: 'F&B', icon: UtensilsCrossed, module: FnbModule },
  { id: 'engineering', label: 'Engineering', icon: Wrench, module: EngineeringModule },
  { id: 'housekeeping', label: 'Housekeeping', icon: Sparkles, module: HousekeepingModule },
  { id: 'back_office', label: 'Back Office', icon: Briefcase, module: BackOfficeModule },
  { id: 'security_audit', label: 'Security & Audit', icon: ShieldCheck, module: SecurityAuditModule },
  { id: 'reports', label: 'Reports', icon: BarChart3, module: ReportsModule },
  { id: 'compliance', label: 'Compliance', icon: ScrollText, module: ComplianceModule },
  { id: 'diesel', label: 'Diesel', icon: Fuel, module: DieselModule },
  { id: 'inventory', label: 'Inventory', icon: Package, module: InventoryModule },
  { id: 'staff', label: 'Staff & Payroll', icon: Users, module: StaffModule },
  { id: 'vendors', label: 'Vendors', icon: Store, module: VendorsModule },
  { id: 'paystack', label: 'Paystack', icon: CreditCard, module: PaystackModule },
  { id: 'whatsapp', label: 'WhatsApp', icon: MessageCircle, module: WhatsAppModule },
  { id: 'bookingcom', label: 'Booking.com', icon: Globe, module: BookingComModule },
];

export default function Dashboard() {
  const [tab, setTab] = useState('overview');
  const [search, setSearch] = useState('');
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  const goTab = (id: string) => { setTab(id); setMobileNavOpen(false); };
  const current = NAV.find(n => n.id === tab) || NAV[0];
  const Module = current.module;

  return (
    <main className="min-h-screen bg-hom-background flex">
      <aside className="w-64 bg-hom-ink text-white p-4 hidden md:flex flex-col sticky top-0 h-screen overflow-y-auto">
        <div className="flex items-center gap-3 mb-8 pb-4 border-b border-white/10">
          <div className="h-10 w-10 bg-white rounded-[12px] border-2 border-hom-primary p-1 flex-shrink-0"><img src="/logo.png" className="h-full w-full" alt="HOM" /></div>
          <div><div className="font-black text-sm">HOM</div><div className="text-[8px] text-green-300 tracking-widest leading-tight">HOSPITALITY OPERATIONS MANAGER</div></div>
        </div>
        <nav className="space-y-0.5 flex-1">
          {NAV.map(({ id, label, icon: Icon }) => (
            <button key={id} onClick={() => goTab(id)}
              className={`w-full text-left px-3 py-2.5 rounded-xl flex items-center gap-2.5 transition-colors ${tab === id ? 'bg-hom-primary text-white' : 'hover:bg-white/10 text-zinc-400'}`}>
              <Icon size={16} /><span className="text-sm truncate">{label}</span>
            </button>
          ))}
        </nav>
        <div className="pt-4 border-t border-white/10 text-[10px] text-zinc-500">HOM v5 — Hexadigitall</div>
      </aside>

      <div className="flex-1 flex flex-col min-h-screen">
        <header className="bg-white border-b p-4 flex justify-between items-center sticky top-0 z-30 gap-3">
          <div className="flex items-center gap-2 min-w-0">
            <button className="md:hidden p-2 -ml-2" onClick={() => setMobileNavOpen(true)} aria-label="Open menu">
              <Menu size={20} />
            </button>
            <h1 className="font-bold capitalize flex items-center gap-2 min-w-0 truncate">
              {(() => { const Icon = current.icon; return <Icon size={20} className="text-hom-primary shrink-0" />; })()}
              <span className="truncate">{current.label}</span>
            </h1>
          </div>
          <div className="flex items-center gap-2 shrink-0">
            <div className="relative hidden sm:block">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-400" />
              <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search..." className="pl-8 pr-3 py-1.5 border rounded-lg text-sm w-36 lg:w-48" />
            </div>
            <span className="text-[10px] bg-green-100 text-green-700 px-2.5 py-1 rounded-full font-medium whitespace-nowrap">HOM LIVE</span>
          </div>
        </header>

        {mobileNavOpen && (
          <div className="fixed inset-0 z-40 md:hidden">
            <div className="absolute inset-0 bg-black/50" onClick={() => setMobileNavOpen(false)} />
            <div className="absolute left-0 top-0 h-full w-72 max-w-[85vw] bg-hom-ink text-white p-4 flex flex-col shadow-2xl">
              <div className="flex items-center justify-between mb-8 pb-4 border-b border-white/10">
                <div className="flex items-center gap-3">
                  <div className="h-10 w-10 bg-white rounded-[12px] border-2 border-hom-primary p-1 flex-shrink-0"><img src="/logo.png" className="h-full w-full" alt="HOM" /></div>
                  <div><div className="font-black text-sm">HOM</div><div className="text-[8px] text-green-300 tracking-widest leading-tight">HOSPITALITY OPERATIONS MANAGER</div></div>
                </div>
                <button onClick={() => setMobileNavOpen(false)} aria-label="Close menu"><X size={20} /></button>
              </div>
              <nav className="space-y-0.5 flex-1 overflow-y-auto">
                {NAV.map(({ id, label, icon: Icon }) => (
                  <button key={id} onClick={() => goTab(id)}
                    className={`w-full text-left px-3 py-2.5 rounded-xl flex items-center gap-2.5 transition-colors ${tab === id ? 'bg-hom-primary text-white' : 'hover:bg-white/10 text-zinc-400'}`}>
                    <Icon size={16} /><span className="text-sm">{label}</span>
                  </button>
                ))}
              </nav>
              <div className="pt-4 border-t border-white/10 text-[10px] text-zinc-500">HOM v5 — Hexadigitall</div>
            </div>
          </div>
        )}

        <div className="md:hidden flex gap-1.5 overflow-x-auto p-3 pb-2">
          {NAV.map(({ id, label, icon: Icon }) => (
            <button key={id} onClick={() => goTab(id)}
              className={`px-3 py-1.5 rounded-full text-xs whitespace-nowrap flex items-center gap-1 ${tab === id ? 'bg-hom-primary text-white' : 'bg-white border text-zinc-600'}`}>
              <Icon size={12} />{label}
            </button>
          ))}
        </div>

        <div className="p-4 md:p-6 flex-1">
          <Module />
        </div>
      </div>
    </main>
  );
}
