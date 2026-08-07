'use client';

import { useState } from 'react';
import { Menu, X, LogOut, LayoutDashboard, CalendarCheck, BedDouble, Fuel, Package, Users, Store, Receipt, Repeat, Activity, Rss, Scale, UtensilsCrossed, Wrench, Sparkles, Briefcase, ShieldCheck, BarChart3, ScrollText, CreditCard, MessageCircle, Globe, UserCog, UserCircle } from 'lucide-react';
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
import { FeedModule } from './modules/feed';
import { AuthProvider, useAuth } from '../../lib/auth';
import { AuthGate } from './auth';
import { Permission, PERMISSIONS, hasPermission, hasAnyPermission, primaryRole, hasIdentity, roleAccent } from '../../lib/rbac';

const NAV: { id: string; label: string; icon: any; module: () => JSX.Element; perm: Permission; permAny?: Permission[]; always?: boolean }[] = [
  { id: 'overview', label: 'Overview', icon: LayoutDashboard, module: OverviewModule, perm: PERMISSIONS.viewReports },
  { id: 'activity', label: 'Activity', icon: Rss, module: FeedModule, perm: PERMISSIONS.viewActivityFeed },
  { id: 'bookings', label: 'Bookings', icon: CalendarCheck, module: BookingsModule, perm: PERMISSIONS.viewBookings },
  { id: 'rooms', label: 'Rooms', icon: BedDouble, module: RoomsModule, perm: PERMISSIONS.viewRooms },
  { id: 'operations', label: 'Operations', icon: Activity, module: OperationsModule, perm: PERMISSIONS.viewOperations, permAny: [PERMISSIONS.viewOperations, PERMISSIONS.viewRevPAR, PERMISSIONS.viewNightAudit, PERMISSIONS.viewHousekeeping] },
  { id: 'reconciliation', label: 'Reconciliation', icon: Scale, module: ReconciliationModule, perm: PERMISSIONS.viewReconciliation },
  { id: 'expenses', label: 'Expenses', icon: Receipt, module: ExpensesModule, perm: PERMISSIONS.viewExpenditure },
  { id: 'subscriptions', label: 'Subscriptions', icon: Repeat, module: SubscriptionsModule, perm: PERMISSIONS.manageSubscriptions },
  { id: 'fnb', label: 'F&B', icon: UtensilsCrossed, module: FnbModule, perm: PERMISSIONS.managePOS, permAny: [PERMISSIONS.managePOS, PERMISSIONS.manageKDS] },
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

// Full contextual header titles: nav uses short labels, the module header
// expands them back to the complete feature name (mirrors the mobile shell).
const FULL_LABEL: Record<string, string> = {
  reconciliation: 'Payments & Reconciliation',
  back_office: 'Back Office & Supply Chain',
  engineering: 'Engineering & Power',
  housekeeping: 'Housekeeping & Assets',
  fnb: 'F&B Operations',
  expenses: 'Expenditure',
  activity: 'Activity Feed',
};
const headerTitle = (id?: string, fallback = 'HOM') =>
  id ? (FULL_LABEL[id] ?? NAV.find((n) => n.id === id)?.label ?? fallback) : fallback;

// Nav grouped by the six HOM pillars (see lib/rbac.ts) + system/channels, so
// menu items are scannable by department instead of one flat list.
const GROUPS: { label: string; items: string[] }[] = [
  { label: 'Front Office', items: ['overview', 'activity', 'bookings', 'rooms', 'operations'] },
  { label: 'Housekeeping & Assets', items: ['housekeeping', 'inventory'] },
  { label: 'Engineering & Utilities', items: ['engineering', 'diesel'] },
  { label: 'F&B & Banqueting', items: ['fnb'] },
  { label: 'Back Office & Supply Chain', items: ['expenses', 'staff', 'vendors', 'back_office', 'reconciliation', 'subscriptions'] },
  { label: 'Compliance, Security & Audit', items: ['compliance', 'security_audit', 'reports'] },
  { label: 'Channels', items: ['paystack', 'whatsapp', 'bookingcom'] },
  { label: 'System', items: ['accounts', 'account'] },
];

function Brand({ minimal }: { minimal?: boolean }) {
  return (
    <div className={`flex items-center gap-3 mb-8 pb-4 border-b border-white/10 ${minimal ? 'justify-center' : ''}`}>
      <div className="h-10 w-10 bg-white rounded-[12px] border-2 border-hom-primary p-1 flex-shrink-0"><img src="/logo.png" className="h-full w-full" alt="HOM" /></div>
      {!minimal && (
        <div className="min-w-0"><div className="font-black text-sm">HOM</div><div className="text-[10px] text-green-300 tracking-widest leading-tight">HOSPITALITY OPERATIONS MANAGER</div></div>
      )}
    </div>
  );
}

function DashboardInner() {
  const { session, logout } = useAuth();
  const visible = NAV.filter(n => n.always || hasPermission(session, n.perm) || (n.permAny && hasAnyPermission(session, n.permAny)));
  const [tab, setTab] = useState('');
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  const grouped = GROUPS
    .map(g => ({ ...g, items: g.items.map(id => visible.find(n => n.id === id)).filter((n): n is (typeof NAV)[number] => !!n) }))
    .filter(g => g.items.length > 0);

  const activeTab = tab && visible.some(n => n.id === tab) ? tab : (visible[0]?.id || '');
  const current = visible.find(n => n.id === activeTab) || visible[0];

  const goTab = (id: string) => { setTab(id); setMobileNavOpen(false); };

  const roleName = primaryRole(session)?.name;
  const accent = roleAccent(session);
  const initials = (session.userName || 'U').split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase();

  return (
    <main className="min-h-screen bg-hom-background flex">
      {/* Desktop / tablet sidebar — icon+text on lg, icon-only on md so content never gets squeezed */}
      <aside className="w-16 lg:w-64 bg-hom-ink text-white p-3 lg:p-4 hidden md:flex flex-col sticky top-0 h-screen overflow-y-auto">
        <Brand minimal />
        <nav className="space-y-0.5 flex-1">
          {grouped.map((g) => (
            <div key={g.label} className="mb-2">
              <p className="hidden lg:block text-[10px] font-bold uppercase tracking-widest text-green-300/60 px-3 mb-1">{g.label}</p>
              {g.items.map(({ id, label, icon: Icon }) => (
                <button key={id} onClick={() => goTab(id)} title={label}
                  className={`w-full flex items-center gap-2.5 rounded-xl px-3 py-2.5 transition-colors ${activeTab === id ? 'text-white' : 'hover:bg-white/10 text-zinc-400'} ${id === 'overview' ? 'mt-1' : ''}`}
                  style={activeTab === id ? { backgroundColor: accent } : undefined}>
                  <Icon size={16} className="shrink-0" />
                  <span className="hidden lg:inline text-sm truncate">{label}</span>
                </button>
              ))}
            </div>
          ))}
        </nav>
        <div className="hidden lg:block pt-4 border-t border-white/10 text-[10px] text-zinc-500">HOM v5 — Hexadigitall</div>
      </aside>

      <div className="flex-1 flex flex-col min-h-screen min-w-0">
        <header className="bg-white border-b p-4 flex justify-between items-center sticky top-0 z-30 gap-3" style={{ borderBottomColor: accent }}>
          <div className="flex items-center gap-2 min-w-0">
            <button className="md:hidden p-2 -ml-2" onClick={() => setMobileNavOpen(true)} aria-label="Open menu">
              <Menu size={20} />
            </button>
            <h1 title={headerTitle(current?.id)} className="font-bold capitalize flex items-center gap-2 min-w-0 truncate">
              {current && (() => { const Icon = current.icon; return <Icon size={20} className="shrink-0" style={{ color: accent }} />; })()}
              <span className="truncate">{headerTitle(current?.id)}</span>
            </h1>
          </div>
          <div className="flex items-center gap-2 min-w-0">
            <span className="text-[10px] bg-green-100 text-green-700 px-2.5 py-1 rounded-full font-medium whitespace-nowrap shrink-0">HOM LIVE</span>
            {hasIdentity(session) && (
              <div className="flex items-center gap-2 pl-2 border-l">
                <button onClick={() => goTab('account')} title="My Account" className="flex items-center gap-2 hover:opacity-80 transition-opacity">
                  <div className="h-8 w-8 rounded-full text-white flex items-center justify-center text-xs font-black shrink-0" style={{ backgroundColor: accent }}>{initials}</div>
                  <div className="hidden lg:block leading-tight min-w-0 text-left">
                    <div className="text-xs font-bold truncate max-w-[120px]">{session.userName}</div>
                    <div className="text-[10px] text-zinc-500 truncate max-w-[120px]">{roleName || 'Unassigned'}</div>
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
              <div className="flex items-center justify-between mb-4 pb-4 border-b border-white/10">
                <Brand />
                <button onClick={() => setMobileNavOpen(false)} aria-label="Close menu"><X size={20} /></button>
              </div>
              <nav className="space-y-0.5 flex-1 overflow-y-auto">
                {grouped.map((g) => (
                  <div key={g.label} className="mb-2">
                    <p className="text-[10px] font-bold uppercase tracking-widest text-green-300/60 px-3 mb-1 mt-3">{g.label}</p>
                    {g.items.map(({ id, label, icon: Icon }) => (
                      <button key={id} onClick={() => goTab(id)}
                        className={`w-full text-left px-3 py-2.5 rounded-xl flex items-center gap-2.5 transition-colors ${activeTab === id ? 'text-white' : 'hover:bg-white/10 text-zinc-400'}`}
                        style={activeTab === id ? { backgroundColor: accent } : undefined}>
                        <Icon size={16} /><span className="text-sm">{label}</span>
                      </button>
                    ))}
                  </div>
                ))}
              </nav>
              <div className="pt-4 border-t border-white/10 text-[10px] text-zinc-500 flex items-center justify-between">
                <span>HOM v5 — Hexadigitall</span>
                <button onClick={logout} className="flex items-center gap-1 text-red-300 text-[10px] font-bold"><LogOut size={12} /> Sign out</button>
              </div>
            </div>
          </div>
        )}

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
