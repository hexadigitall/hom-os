'use client';

import { useState } from 'react';
import { Menu, X, Search, LogOut, LayoutDashboard, CalendarCheck, BedDouble, Fuel, Package, Users, Store, Receipt, Repeat, Activity, Scale, UtensilsCrossed, Wrench, Sparkles, Briefcase, ShieldCheck, BarChart3, ScrollText, CreditCard, MessageCircle, Globe, UserCog, UserCircle } from 'lucide-react';
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
import { AccountsModule } from './modules/accounts';
import { AccountModule } from './modules/account';
import { AuthProvider, useAuth } from '../../lib/auth';
import { AuthGate } from './auth';
import { Permission, PERMISSIONS, hasPermission, primaryRole, hasIdentity } from '../../lib/rbac';

const NAV: { id: string; label: string; icon: any; module: () => JSX.Element; perm: Permission; always?: boolean }[] = [
  { id: 'overview', label: 'Overview', icon: LayoutDashboard, module: OverviewModule, perm: PERMISSIONS.viewReports },
  { id: 'bookings', label: 'Bookings', icon: CalendarCheck, module: BookingsModule, perm: PERMISSIONS.viewBookings },
  { id: 'rooms', label: 'Rooms', icon: BedDouble, module: RoomsModule, perm: PERMISSIONS.viewRooms },
  { id: 'operations', label: 'Operations', icon: Activity, module: OperationsModule, perm: PERMISSIONS.viewOperations },
  { id: 'reconciliation', label: 'Reconciliation', icon: Scale, module: ReconciliationModule, perm: PERMISSIONS.viewReconciliation },
  { id: 'expenses', label: 'Expenses', icon: Receipt, module: ExpensesModule, perm: PERMISSIONS.viewExpenditure },
  { id: 'subscriptions', label: 'Subscriptions', icon: Repeat, module: SubscriptionsModule, perm: PERMISSIONS.manageSubscriptions },
  { id: 'fnb', label: 'F&B', icon: UtensilsCrossed, module: FnbModule, perm: PERMISSIONS.managePOS },
  { id: 'engineering', label: 'Engineering', icon: Wrench, module: EngineeringModule, perm: PERMISSIONS.viewEngineering },
  { id: 'housekeeping', label: 'Housekeeping', icon: Sparkles, module: HousekeepingModule, perm: PERMISSIONS.viewHousekeeping },
  { id: 'back_office', label: 'Back Office', icon: Briefcase, module: BackOfficeModule, perm: PERMISSIONS.viewBackOffice },
  { id: 'security_audit', label: 'Security & Audit', icon: ShieldCheck, module: SecurityAuditModule, perm: PERMISSIONS.viewSecurityAudit },
  { id: 'reports', label: 'Reports', icon: BarChart3, module: ReportsModule, perm: PERMISSIONS.viewReports },
  { id: 'compliance', label: 'Compliance', icon: ScrollText, module: ComplianceModule, perm: PERMISSIONS.viewCompliance },
  { id: 'diesel', label: 'Diesel', icon: Fuel, module: DieselModule, perm: PERMISSIONS.viewFuel },
  { id: 'inventory', label: 'Inventory', icon: Package, module: InventoryModule, perm: PERMISSIONS.viewInventory },
  { id: 'staff', label: 'Staff & Payroll', icon: Users, module: StaffModule, perm: PERMISSIONS.viewStaff },
  { id: 'vendors', label: 'Vendors', icon: Store, module: VendorsModule, perm: PERMISSIONS.viewVendors },
  { id: 'paystack', label: 'Paystack', icon: CreditCard, module: PaystackModule, perm: PERMISSIONS.viewMultiCurrencyBilling },
  { id: 'whatsapp', label: 'WhatsApp', icon: MessageCircle, module: WhatsAppModule, perm: PERMISSIONS.manageWhatsApp },
  { id: 'bookingcom', label: 'Booking.com', icon: Globe, module: BookingComModule, perm: PERMISSIONS.manageChannelManager },
  { id: 'accounts', label: 'App Accounts', icon: UserCog, module: AccountsModule, perm: PERMISSIONS.manageUsers },
  { id: 'account', label: 'My Account', icon: UserCircle, module: AccountModule, perm: PERMISSIONS.viewReports, always: true },
];

function Brand() {
  return (
    <div className="flex items-center gap-3 mb-8 pb-4 border-b border-white/10">
      <div className="h-10 w-10 bg-white rounded-[12px] border-2 border-hom-primary p-1 flex-shrink-0"><img src="/logo.png" className="h-full w-full" alt="HOM" /></div>
      <div><div className="font-black text-sm">HOM</div><div className="text-[8px] text-green-300 tracking-widest leading-tight">HOSPITALITY OPERATIONS MANAGER</div></div>
    </div>
  );
}

function DashboardInner() {
  const { session, logout } = useAuth();
  const visible = NAV.filter(n => n.always || hasPermission(session, n.perm));
  const [tab, setTab] = useState('');
  const [search, setSearch] = useState('');
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  const activeTab = tab && visible.some(n => n.id === tab) ? tab : (visible[0]?.id || '');
  const current = visible.find(n => n.id === activeTab) || visible[0];

  const goTab = (id: string) => { setTab(id); setMobileNavOpen(false); };

  const roleName = primaryRole(session)?.name;
  const initials = (session.userName || 'U').split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase();

  return (
    <main className="min-h-screen bg-hom-background flex overflow-x-clip">
      <aside className="w-64 bg-hom-ink text-white p-4 hidden md:flex flex-col sticky top-0 h-screen overflow-y-auto">
        <Brand />
        <nav className="space-y-0.5 flex-1">
          {visible.map(({ id, label, icon: Icon }) => (
            <button key={id} onClick={() => goTab(id)}
              className={`w-full text-left px-3 py-2.5 rounded-xl flex items-center gap-2.5 transition-colors ${activeTab === id ? 'bg-hom-primary text-white' : 'hover:bg-white/10 text-zinc-400'}`}>
              <Icon size={16} /><span className="text-sm truncate">{label}</span>
            </button>
          ))}
        </nav>
        <div className="pt-4 border-t border-white/10 text-[10px] text-zinc-500">HOM v5 — Hexadigitall</div>
      </aside>

      <div className="flex-1 flex flex-col min-h-screen min-w-0">
        <header className="bg-white border-b p-4 flex justify-between items-center sticky top-0 z-30 gap-3">
          <div className="flex items-center gap-2 min-w-0">
            <button className="md:hidden p-2 -ml-2" onClick={() => setMobileNavOpen(true)} aria-label="Open menu">
              <Menu size={20} />
            </button>
            <h1 className="font-bold capitalize flex items-center gap-2 min-w-0 truncate">
              {current && (() => { const Icon = current.icon; return <Icon size={20} className="text-hom-primary shrink-0" />; })()}
              <span className="truncate">{current?.label || 'HOM'}</span>
            </h1>
          </div>
          <div className="flex items-center gap-2 min-w-0">
            <div className="relative hidden md:block">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-400" />
              <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search..." className="pl-8 pr-3 py-1.5 border rounded-lg text-sm w-36 lg:w-48" />
            </div>
            <span className="hidden sm:inline-flex text-[10px] bg-green-100 text-green-700 px-2.5 py-1 rounded-full font-medium whitespace-nowrap shrink-0">HOM LIVE</span>
            {hasIdentity(session) && (
              <div className="hidden sm:flex items-center gap-2 pl-2 border-l">
                <button onClick={() => goTab('account')} title="My Account" className="flex items-center gap-2 hover:opacity-80 transition-opacity">
                  <div className="h-8 w-8 rounded-full bg-hom-primary text-white flex items-center justify-center text-xs font-black shrink-0">{initials}</div>
                  <div className="hidden lg:block leading-tight min-w-0 text-left">
                    <div className="text-xs font-bold truncate max-w-[120px]">{session.userName}</div>
                    <div className="text-[9px] text-zinc-500 truncate max-w-[120px]">{roleName || 'Unassigned'}</div>
                  </div>
                </button>
                <button onClick={logout} title="Sign out" className="p-1.5 rounded-lg hover:bg-red-50 text-zinc-400 hover:text-red-500">
                  <LogOut size={15} />
                </button>
              </div>
            )}
          </div>
        </header>

        {mobileNavOpen && (
          <div className="fixed inset-0 z-40 md:hidden">
            <div className="absolute inset-0 bg-black/50" onClick={() => setMobileNavOpen(false)} />
            <div className="absolute left-0 top-0 h-full w-72 max-w-[85vw] bg-hom-ink text-white p-4 flex flex-col shadow-2xl">
              <div className="flex items-center justify-between mb-8 pb-4 border-b border-white/10">
                <Brand />
                <button onClick={() => setMobileNavOpen(false)} aria-label="Close menu"><X size={20} /></button>
              </div>
              <nav className="space-y-0.5 flex-1 overflow-y-auto">
                {visible.map(({ id, label, icon: Icon }) => (
                  <button key={id} onClick={() => goTab(id)}
                    className={`w-full text-left px-3 py-2.5 rounded-xl flex items-center gap-2.5 transition-colors ${activeTab === id ? 'bg-hom-primary text-white' : 'hover:bg-white/10 text-zinc-400'}`}>
                    <Icon size={16} /><span className="text-sm">{label}</span>
                  </button>
                ))}
              </nav>
              <div className="pt-4 border-t border-white/10 text-[10px] text-zinc-500 flex items-center justify-between">
                <span>HOM v5 — Hexadigitall</span>
                <button onClick={logout} className="flex items-center gap-1 text-red-300 text-[10px] font-bold"><LogOut size={12} /> Sign out</button>
              </div>
            </div>
          </div>
        )}

        <div className="md:hidden flex gap-1.5 overflow-x-auto p-3 pb-2">
          {visible.map(({ id, label, icon: Icon }) => (
            <button key={id} onClick={() => goTab(id)}
              className={`px-3 py-1.5 rounded-full text-xs whitespace-nowrap flex items-center gap-1 ${activeTab === id ? 'bg-hom-primary text-white' : 'bg-white border text-zinc-600'}`}>
              <Icon size={12} />{label}
            </button>
          ))}
        </div>

        <div className="p-4 md:p-6 flex-1 min-w-0">
          <div className="w-full max-w-7xl mx-auto">
            {current ? <current.module /> : <div className="p-8 text-center text-sm text-zinc-400">No modules available for your access level.</div>}
          </div>
        </div>
      </div>
    </main>
  );
}

export default function Dashboard() {
  return (
    <AuthProvider>
      <AuthGate>
        <DashboardInner />
      </AuthGate>
    </AuthProvider>
  );
}
