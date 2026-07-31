import {
  Room, Booking, Diesel, InventoryItem, Staff, Vendor, PurchaseOrder,
  ExpenditureRecord, Subscription, ScumlTransaction, CashTransaction,
  StateTaxConfig, StateTaxReport, FireServiceCert, NaptipAlert, LgaInspection,
  DailyRevenue, CashDrop, HousekeepingLoss, BankTransaction, ReconciliationMatch,
  VirtualAccount, PosTerminal, PosSettlement, MenuItem, RestaurantTable, Order,
  Generator, MaintenanceTask, WaterTreatmentLog, TankDipLog, GridTariffConfig,
  HousekeepingTask, LaundryItem, LostFoundItem, LinenDamage,
  ProcurementOrder, PayrollRecord, TaxConfiguration, NightAuditLog,
  SecurityIncident, VisitorPass, ShiftHandover,
} from './types';
import { today, addDays, addMonths } from './format';
import { makeRng } from './storage';

const T = today();

// ─── Core ────────────────────────────────────────────────────────────────────

export const seedRooms = (): Room[] => [
  { id: 'r1', number: '101', type: 'Deluxe', status: 'available', price: 25000 },
  { id: 'r2', number: '102', type: 'Deluxe', status: 'occupied', price: 25000 },
  { id: 'r3', number: '103', type: 'Standard', status: 'available', price: 15000 },
  { id: 'r4', number: '201', type: 'Executive', status: 'maintenance', price: 40000 },
  { id: 'r5', number: '202', type: 'Executive', status: 'available', price: 40000 },
];

export const seedBookings = (): Booking[] => [
  { id: 'b1', guest: 'John Doe', phone: '08031234567', room: '102', checkin: addDays(T, -2), checkout: addDays(T, 1), status: 'checked-in', amount: 50000 },
];

export const seedDiesel = (): Diesel[] => [
  { id: 'd1', date: addDays(T, -1), liters: 200, cost: 240000, supplier: 'MRS PH', genHours: 12, note: 'No theft detected' },
];

export const seedInventory = (): InventoryItem[] => [
  { id: 'i1', name: 'Tissue Roll', qty: 50, low: 10, cost: 500 },
  { id: 'i2', name: 'Bottled Water', qty: 8, low: 20, cost: 200 },
  { id: 'i3', name: 'Towel Set', qty: 30, low: 10, cost: 2500 },
  { id: 'i4', name: 'Toiletry Kit', qty: 15, low: 5, cost: 1200 },
];

export const seedStaff = (): Staff[] => [
  { id: 's1', name: 'Amina Yusuf', role: 'Front Desk', salary: 120000 },
  { id: 's2', name: 'Chidi Okonkwo', role: 'Cleaner', salary: 70000 },
  { id: 's3', name: 'Blessing Eze', role: 'Manager', salary: 200000 },
];

export const seedVendors = (): Vendor[] => [
  { id: 'v1', name: 'MRS Petroleum', contact: '0801-234-5678', category: 'Fuel' },
  { id: 'v2', name: 'CleanPro Supplies', contact: '0809-876-5432', category: 'Cleaning' },
];

export const seedPOs = (): PurchaseOrder[] => [
  { id: 'po1', vendorId: 'v1', items: 'Diesel 500L', amount: 600000, date: addDays(T, -2), status: 'delivered' },
];

// ─── Expenses ────────────────────────────────────────────────────────────────

export const seedExpenditure = (): ExpenditureRecord[] => [
  { id: 'exp_seed1', date: addDays(T, -1), category: 'Procurement', subcategory: 'Supplies', description: 'Kitchen dry goods restock', amount: 185000, vendor: 'Fresh Foods Ltd', paymentMethod: 'Transfer', receiptRef: 'RCP-1042', notes: '', department: 'Kitchen', createdAt: new Date().toISOString() },
  { id: 'exp_seed2', date: addDays(T, -3), category: 'Utilities (Power/Water)', subcategory: 'Electricity', description: 'PHED invoice — main meter', amount: 620000, vendor: 'PHED', paymentMethod: 'Transfer', receiptRef: 'RCP-1041', notes: 'Billing period June', department: 'Engineering', createdAt: new Date().toISOString() },
  { id: 'exp_seed3', date: addDays(T, -5), category: 'F&B', subcategory: 'Beverage', description: 'Bar stock — beer & spirits', amount: 340000, vendor: 'CaterPlus Ltd', paymentMethod: 'Cash', receiptRef: 'RCP-1040', notes: '', department: 'Restaurants', createdAt: new Date().toISOString() },
];

// ─── Subscriptions ───────────────────────────────────────────────────────────

export const seedSubscriptions = (): Subscription[] => [
  { id: 'sub1', name: 'DSTV Premium Business', provider: 'Multichoice Nigeria', category: 'TV & Entertainment', amount: 185000, billingCycle: 'monthly', startDate: '2025-01-01', status: 'active', contactInfo: '0700-MULTICHOICE', notes: 'Premium bouquet — 12 rooms + lounge + bar', autoLogExpenditure: false },
  { id: 'sub2', name: 'Enterprise Fiber Internet', provider: 'MTN Business', category: 'Internet', amount: 350000, billingCycle: 'monthly', startDate: '2025-06-15', status: 'active', contactInfo: 'mtnbusiness@mtn.com', notes: '100Mbps dedicated fiber — 2yr contract', autoLogExpenditure: true },
  { id: 'sub3', name: 'MCSN Music License', provider: 'MCSN', category: 'License & Permits', amount: 450000, billingCycle: 'annual', startDate: '2025-03-01', status: 'expiring', contactInfo: 'info@mcson.org', notes: 'Annual copyright license for background music', autoLogExpenditure: false },
  { id: 'sub4', name: 'Backup LTE Internet', provider: 'Airtel Business', category: 'Internet', amount: 85000, billingCycle: 'monthly', startDate: '2026-02-01', status: 'active', contactInfo: '0800-AIRTEL-BIZ', notes: '4G LTE backup — 50GB data cap', autoLogExpenditure: false },
  { id: 'sub5', name: 'Showmax Pro Business', provider: 'Showmax / MultiChoice', category: 'TV & Entertainment', amount: 45000, billingCycle: 'monthly', startDate: '2026-05-01', status: 'active', contactInfo: 'business@showmax.com', notes: 'Sports + movies package for poolside bar', autoLogExpenditure: false },
];

// ─── Compliance ──────────────────────────────────────────────────────────────

export const seedScuml = (): ScumlTransaction[] => [
  { id: 'cmp_s1', date: addDays(T, -1), guestName: 'John Doe', address: '12 Admiralty Way, Lekki', idType: 'National ID', idNumber: 'NG-8842-1199', amount: 6000000, purpose: 'Room + event deposit', submittedToScuml: false, createdAt: new Date().toISOString() },
  { id: 'cmp_s2', date: addDays(T, -6), guestName: 'Mrs. Adaeze Obi', address: 'Plot 7, Asokoro, Abuja', idType: 'Passport', idNumber: 'A04588172', amount: 1800000, purpose: 'Conference package', submittedToScuml: true, submittedDate: addDays(T, -5), createdAt: new Date().toISOString() },
];

export const seedCash = (): CashTransaction[] => [
  { id: 'cmp_c1', date: addDays(T, -2), guestName: 'Walk-in Guest', receiptNumber: 'RC-00921', paymentMethod: 'cash', amount: 7500000, purpose: 'Suite booking + banquet', flagged: false, createdAt: new Date().toISOString() },
  { id: 'cmp_c2', date: addDays(T, -1), guestName: 'Ahmed Bello', receiptNumber: 'RC-00922', paymentMethod: 'pos', amount: 125000, purpose: 'Dinner table service', flagged: false, createdAt: new Date().toISOString() },
];

export const seedTaxConfigs = (): StateTaxConfig[] => [
  { stateName: 'Lagos', rate: 5.0, appliesToOtherServices: false },
  { stateName: 'Rivers', rate: 5.0, appliesToOtherServices: false },
  { stateName: 'Federal Capital Territory', rate: 5.0, appliesToOtherServices: false },
  { stateName: 'Oyo', rate: 3.0, appliesToOtherServices: true },
  { stateName: 'Delta', rate: 2.5, appliesToOtherServices: false },
];

export const seedTaxReports = (): StateTaxReport[] => [];

export const seedFireCerts = (): FireServiceCert[] => [
  { id: 'cmp_f1', certificateNumber: 'FFSC-2026-0148', issueDate: addDays(T, -120), expiryDate: addDays(T, 245), fireServiceOffice: 'Lagos State Fire Service', status: 'valid', inspectionScore: 92 },
];

export const seedNaptip = (): NaptipAlert[] => [
  { id: 'cmp_n1', date: addDays(T, -4), type: 'forcedLabour', description: 'Guest mentioned staff held without contract in supplier facility', actionTaken: 'Logged and escalated to NAPTIP desk', reportedTo: 'NAPTIP Lagos Zonal Office', status: 'investigated' },
];

export const seedLga = (): LgaInspection[] => [
  { id: 'cmp_l1', inspectionDate: addDays(T, -30), inspector: 'Mrs. Ronke Adeyemi', agency: 'Lagos State H&S Agency', certificateNumber: 'LS-HS-00331', expiryDate: addDays(T, 335), score: 88, status: 'passed', passedItems: ['Fire exits', 'Kitchen hygiene', 'Staff records'], failedItems: [] },
];

// ─── Operations ──────────────────────────────────────────────────────────────

export function seedRevenues(): DailyRevenue[] {
  const rng = makeRng(42);
  const out: DailyRevenue[] = [];
  for (let i = 29; i >= 0; i--) {
    const date = addDays(T, -i);
    const d = new Date(date + 'T00:00:00').getDay();
    const weekend = d === 0 || d === 6;
    const roomsSold = weekend ? rng.nextInt(5) + 8 : rng.nextInt(4) + 5;
    const walkIns = weekend ? rng.nextInt(3) : rng.nextInt(10) < 3 ? rng.nextInt(2) : 0;
    const rate = weekend ? 25000 + rng.nextInt(5000) : 18000 + rng.nextInt(4000);
    out.push({ id: `rev_${i + 1}`, date, roomsSold, walkIns, totalRevenue: roomsSold * rate });
  }
  return out;
}

export function seedCashDrops(): CashDrop[] {
  const rng = makeRng(42);
  const shifts: CashDrop['shift'][] = ['Morning', 'Evening', 'Night'];
  const out: CashDrop[] = [];
  for (let i = 0; i < 14; i++) {
    const date = addDays(T, -(13 - i));
    const expectedAmount = 60000 + rng.nextInt(20000);
    const mismatch = rng.nextInt(5) === 0;
    const delta = mismatch ? rng.nextInt(7500) - 2500 : 0;
    out.push({
      id: `cd_${i + 1}`, date, shift: shifts[i % 3],
      expectedAmount, actualAmount: expectedAmount + delta,
      status: mismatch ? 'mismatched' : 'matched',
      notes: mismatch ? `Variance of ₦${(delta < 0 ? -delta : delta).toLocaleString('en-NG')}` : undefined,
    });
  }
  return out;
}

const LOSS_CATALOG: [string, string, number][] = [
  ['Bath Towel', 'Linen', 3500], ['Face Towel', 'Linen', 1800], ['Bedsheet King', 'Linen', 8500],
  ['Pillowcase', 'Linen', 1200], ['Bathrobe', 'Linen', 12000], ['Slippers', 'Amenity', 800],
  ['Soap', 'Amenity', 350], ['Shampoo', 'Amenity', 600], ['Lotion', 'Amenity', 750],
  ['Tea/Coffee', 'Amenity', 200], ['Water bottle', 'Amenity', 300], ['Wine glass', 'Furniture', 1500],
  ['Remote', 'Furniture', 2500], ['Light bulb', 'Maintenance', 800],
];

export function seedLosses(): HousekeepingLoss[] {
  const rng = makeRng(42);
  const out: HousekeepingLoss[] = [];
  for (let n = 1; n <= 20; n++) {
    const [item, category, unitCost] = LOSS_CATALOG[rng.nextInt(LOSS_CATALOG.length)];
    out.push({
      id: `loss_${n}`, date: addDays(T, -rng.nextInt(30)), item, category,
      quantity: rng.nextInt(4) + 1, unitCost, roomNumber: String(101 + rng.nextInt(12)),
    });
  }
  return out;
}

// ─── Reconciliation ──────────────────────────────────────────────────────────

export function seedBankTransactions(): BankTransaction[] {
  const rng = makeRng(42);
  const guests = ['John Doe', 'Maryam Bello', 'Mr Adekunle', 'Chioma Eze', 'Tunde Bakare'];
  const cats = ['Procurement', 'Laundry & Linen', 'Utilities (Power/Water)', 'F&B', 'Maintenance & Repairs'];
  const vendors = ['MRS Petroleum', 'FreshFarm Ltd', 'CleanPro Supplies', 'LinenHouse Ltd', 'PHED', 'CaterPlus Ltd'];
  const banks = ['GTBank', 'Access', 'FirstBank'];
  const out: BankTransaction[] = [];
  const ref = () => 'REF' + String(rng.nextInt(1000000)).padStart(6, '0');

  for (let i = 0; i < 25; i++) {
    const date = addDays(T, -i);
    if (i % 3 === 1) {
      out.push({
        id: `bt_${i}`, date, type: 'DR', source: 'Bank Statement',
        description: `TRF/${ref()}/${cats[rng.nextInt(cats.length)]}/${vendors[rng.nextInt(vendors.length)]}`,
        amount: (5 + rng.nextInt(50)) * 1000, reference: ref(), balance: 0,
      });
    } else {
      out.push({
        id: `bt_${i}`, date, type: 'CR', source: banks[i % 3],
        description: `POS/L3112345/${guests[i % guests.length]}/Room Booking Payment/${ref()}`,
        amount: (15 + rng.nextInt(30)) * 1000, reference: ref(), balance: 2500000 - i * 12000,
      });
    }
  }
  out.push({ id: 'bt_25', date: addDays(T, -3), type: 'DR', source: 'Bank Statement', description: 'ATM/WITHDRAWAL/Lagos', amount: 5000, reference: ref(), balance: 0 });
  out.push({ id: 'bt_26', date: addDays(T, -2), type: 'DR', source: 'Bank Statement', description: 'USSD/TRF/Chidi Okonkwo/Staff advance', amount: 15000, reference: ref(), balance: 0 });
  out.push({ id: 'bt_27', date: addDays(T, -1), type: 'DR', source: 'Bank Statement', description: 'POS/Providus/Office Supplies Ltd', amount: 8500, reference: ref(), balance: 0 });
  return out;
}

export function seedMatches(): ReconciliationMatch[] {
  return [{
    id: 'rm_seed1', bankTransactionId: 'bt_0', entityType: 'booking', entityId: 'b1',
    entityLabel: 'John Doe — Room 102', entityAmount: 50000, matchedAmount: 50000,
    confidence: 0.85, isManual: false, matchedAt: new Date().toISOString(),
  }];
}

export function seedVirtualAccounts(): VirtualAccount[] {
  const rng = makeRng(123);
  const banks = ['Wema', 'Providus', 'Zenith', 'Access'];
  const guests = ['Chidi Okonkwo', 'Amina Yusuf', 'John Okafor', 'Chioma Eze'];
  const amounts = [50000, 75000, 35000, 120000];
  return guests.map((g, i) => ({
    id: `va_${i + 1}`, bookingId: `bk_${i + 1}`, guestName: g, bankName: banks[i % banks.length],
    accountNumber: '123' + String(rng.nextInt(10000000)).padStart(7, '0'),
    accountName: `HOM Hotel / ${g}`, amount: amounts[i],
    status: (i < 2 ? 'active' : 'matched') as VirtualAccount['status'],
    createdAt: addDays(T, -(10 - i)), expiresAt: addDays(addDays(T, -(10 - i)), 7),
  }));
}

export function seedPosTerminals(): PosTerminal[] {
  return [
    { id: 'pos_1', terminalId: 'TML-7812-A', bankName: 'FirstBank', merchantCode: 'MCH-001', status: 'active', addedAt: addDays(T, -90) },
    { id: 'pos_2', terminalId: 'TML-4529-B', bankName: 'GTBank', merchantCode: 'MCH-001', status: 'active', addedAt: addDays(T, -60) },
    { id: 'pos_3', terminalId: 'TML-1133-C', bankName: 'Access', merchantCode: 'MCH-002', status: 'inactive', addedAt: addDays(T, -30) },
  ];
}

export function seedPosSettlements(): PosSettlement[] {
  const rng = makeRng(456);
  const statuses: PosSettlement['status'][] = ['settled', 'settled', 'pending', 'pending'];
  const terms = ['TML-7812-A', 'TML-4529-B', 'TML-1133-C', 'TML-7812-A', 'TML-4529-B', 'TML-1133-C'];
  return terms.map((t, i) => ({
    id: `ps_${i + 1}`, terminalId: t, terminalRef: `STL-${1000 + i * 17}`,
    amount: (50 + rng.nextInt(200)) * 1000, date: addDays(T, -(5 - i)),
    status: statuses[i % 4], note: i === 4 ? 'Delayed settlement — bank holiday' : undefined,
  }));
}

// ─── F&B ─────────────────────────────────────────────────────────────────────

export const seedMenu = (): MenuItem[] => [
  { id: 'm_f1', name: 'Jollof Rice & Chicken', category: 'food', price: 4500, available: true },
  { id: 'm_f2', name: 'Egusi Soup & Pounded Yam', category: 'food', price: 5500, available: true },
  { id: 'm_f3', name: 'Grilled Tilapia', category: 'food', price: 6500, available: true },
  { id: 'm_f4', name: 'Pepper Soup Goat Meat', category: 'food', price: 5000, available: true },
  { id: 'm_d1', name: 'Bottled Water', category: 'drink', price: 500, available: true },
  { id: 'm_d2', name: 'Maltina', category: 'drink', price: 800, available: true },
  { id: 'm_d3', name: 'Chapman Mocktail', category: 'drink', price: 2500, available: true },
  { id: 'm_b1', name: 'Star Lager', category: 'bar', price: 1200, available: true },
  { id: 'm_b2', name: 'Heineken', category: 'bar', price: 1500, available: true },
  { id: 'm_b3', name: 'Jameson Whisky Shot', category: 'bar', price: 3000, available: true },
  { id: 'm_w1', name: 'South African Red Wine', category: 'wine', price: 15000, available: true },
  { id: 'm_s1', name: 'Nigerian Palm Wine', category: 'special', price: 2000, available: true },
];

export const seedTables = (): RestaurantTable[] => [
  { id: 't1', number: 'T1', seats: 2, status: 'free' },
  { id: 't2', number: 'T2', seats: 2, status: 'free' },
  { id: 't3', number: 'T3', seats: 4, status: 'free' },
  { id: 't4', number: 'T4', seats: 4, status: 'free' },
  { id: 't5', number: 'T5', seats: 6, status: 'free' },
  { id: 't6', number: 'VIP-1', seats: 8, status: 'free' },
  { id: 't7', number: 'VIP-2', seats: 8, status: 'free' },
  { id: 't8', number: 'Bar-1', seats: 1, status: 'reserved' },
];

export const seedOrders = (): Order[] => [];

// ─── Engineering ─────────────────────────────────────────────────────────────

export const seedGenerators = (): Generator[] => [
  { id: 'eng_g1', name: 'Main DG', model: 'Cat C18', capacityKva: 500, currentRunHours: 12450, currentLoadKva: 320, status: 'running' },
  { id: 'eng_g2', name: 'Standby', model: 'Perkins', capacityKva: 250, currentRunHours: 3200, currentLoadKva: 0, status: 'idle' },
  { id: 'eng_g3', name: 'Pool House Gen', model: 'FG Wilson', capacityKva: 100, currentRunHours: 890, currentLoadKva: 0, status: 'maintenance', lastServiceDate: addDays(T, -45) },
  { id: 'eng_g4', name: 'Kitchen Backup', model: 'Cummins', capacityKva: 75, currentRunHours: 2100, currentLoadKva: 45, status: 'fault' },
];

export const seedMaintenance = (): MaintenanceTask[] => [
  { id: 'eng_m1', equipmentName: 'Main DG', description: 'Oil change + filter replacement', assignedTo: 'Segun', equipmentType: 'generator', priority: 'urgent', scheduledDate: addDays(T, 3), completed: false },
  { id: 'eng_m2', equipmentName: 'AC Chiller 1', description: 'Condenser cleaning', assignedTo: 'Emeka', equipmentType: 'hvac', priority: 'important', scheduledDate: addDays(T, 7), completed: false },
  { id: 'eng_m3', equipmentName: 'Water Pump — Borehole', description: 'Impeller replacement', assignedTo: 'Segun', equipmentType: 'waterPump', priority: 'routine', scheduledDate: addDays(T, -2), completed: false },
  { id: 'eng_m4', equipmentName: 'Elevator — Building A', description: 'Safety certificate renewal', assignedTo: 'LiftCo', equipmentType: 'lift', priority: 'critical', scheduledDate: addDays(T, 14), completed: false },
];

export const seedWater = (): WaterTreatmentLog[] => [
  { id: 'eng_w1', date: addDays(T, -6), source: 'RO Plant', treatmentAction: 'Backwash', phLevel: 7.2, chlorineLevel: 0.5, tdsLevel: 45, chemicalUsed: 'Antiscalant', chemicalDosageMl: 50, nextScheduledDate: addDays(T, 7) },
  { id: 'eng_w2', date: addDays(T, -2), source: 'Swimming Pool', treatmentAction: 'Chemical dosing', phLevel: 7.8, chlorineLevel: 1.2, chemicalUsed: 'Muriatic Acid', chemicalDosageMl: 200, nextScheduledDate: addDays(T, 3) },
  { id: 'eng_w3', date: addDays(T, -1), source: 'STP', treatmentAction: 'Sample test', phLevel: 6.9, tdsLevel: 320, nextScheduledDate: addDays(T, 21) },
];

export const seedTankDips = (): TankDipLog[] => [
  { id: 'eng_t1', date: addDays(T, -1), tankName: 'Main Diesel Tank', dipReadingCm: 85, tankCapacityL: 5000, calculatedVolumeL: 4250, expectedVolumeL: 4300, performedBy: 'Segun', notes: 'Within tolerance' },
  { id: 'eng_t2', date: addDays(T, -3), tankName: 'Main Diesel Tank', dipReadingCm: 120, tankCapacityL: 5000, calculatedVolumeL: 6000, expectedVolumeL: 6100, performedBy: 'Segun', notes: 'Full capacity reading' },
  { id: 'eng_t3', date: addDays(T, -1), tankName: 'Generator Day Tank', dipReadingCm: 48, tankCapacityL: 500, calculatedVolumeL: 240, expectedVolumeL: 250, performedBy: 'Kelechi', notes: '' },
];

export const seedTariffs = (): GridTariffConfig[] => [
  { id: 'eng_c1', band: 'a', hoursPerDay: 20, costPerKwh: 125, label: 'Premium', description: 'Band A — 20h supply' },
  { id: 'eng_c2', band: 'b', hoursPerDay: 16, costPerKwh: 95, label: 'Standard', description: 'Band B — 16h supply' },
  { id: 'eng_c3', band: 'c', hoursPerDay: 8, costPerKwh: 60, label: 'Basic', description: 'Band C — 8h supply' },
];

// ─── Housekeeping ────────────────────────────────────────────────────────────

export const seedHkTasks = (): HousekeepingTask[] => [
  { id: 'hk_t1', roomNumber: '101', assignedTo: 'Fatima', priority: 'routine', scheduledDate: T, completed: false },
  { id: 'hk_t2', roomNumber: '102', assignedTo: 'Fatima', priority: 'routine', scheduledDate: T, completed: false },
  { id: 'hk_t3', roomNumber: '103', assignedTo: 'Blessing', priority: 'deepClean', scheduledDate: addDays(T, 1), completed: false },
  { id: 'hk_t4', roomNumber: '201', assignedTo: 'Blessing', priority: 'vipSetup', scheduledDate: T, completed: false },
  { id: 'hk_t5', roomNumber: '202', assignedTo: 'Chidi', priority: 'turndown', scheduledDate: T, completed: false },
];

export const seedLaundry = (): LaundryItem[] => [
  { id: 'hk_l1', guestName: 'John Doe', roomNumber: '102', itemDescription: '2x Suit — Dry Clean', type: 'dryCleanOnly', status: 'received', chargeAmount: 8000, receivedDate: addDays(T, -1) },
  { id: 'hk_l2', guestName: 'Maryam Bello', roomNumber: '201', itemDescription: '3x Shirts, 2x Trousers', type: 'washIron', status: 'washing', chargeAmount: 6500, receivedDate: addDays(T, -1) },
  { id: 'hk_l3', guestName: 'Mr. Adekunle', roomNumber: '105', itemDescription: '1x bedsheet (stained) — Self', type: 'selfService', status: 'received', chargeAmount: 0, receivedDate: addDays(T, -2) },
];

export const seedLostFound = (): LostFoundItem[] => [
  { id: 'hk_lf1', itemName: 'iPhone 15 Pro', foundBy: 'Fatima', locationFound: 'Room 101 bedside drawer', category: 'electronics', notes: 'Charged and kept in safe', returned: false },
  { id: 'hk_lf2', itemName: 'Gold Wedding Ring', foundBy: 'Blessing', locationFound: 'Room 201 bathroom', category: 'jewelry', guestName: '', notes: 'Guest will collect at checkout', returned: false },
  { id: 'hk_lf3', itemName: 'Navy Blue Passport', foundBy: 'Chidi', locationFound: 'Lobby reception', category: 'documents', guestName: 'Oluwaseun Ojo', returned: false },
];

export const seedLinen = (): LinenDamage[] => [
  { id: 'hk_ln1', itemName: 'King Bedsheet', roomNumber: '101', category: 'bedsheet', condition: 'stained', quantity: 2, replacementCost: 8500, notes: 'Red wine stain' },
  { id: 'hk_ln2', itemName: 'Bath Towel XL', roomNumber: '103', category: 'towel', condition: 'torn', quantity: 1, replacementCost: 3500, notes: '' },
  { id: 'hk_ln3', itemName: 'Pillowcase', roomNumber: '202', category: 'pillowcase', condition: 'condemned', quantity: 4, replacementCost: 2200, notes: 'Yellowed beyond recovery' },
];

// ─── Back Office ─────────────────────────────────────────────────────────────

export const seedProcurements = (): ProcurementOrder[] => [
  { id: 'bo_p1', vendorName: 'MRS Petroleum', items: 'Diesel 500L, Engine Oil 20L', amount: 620000, status: 'delivered', orderDate: addDays(T, -5), deliveryDate: addDays(T, -4) },
  { id: 'bo_p2', vendorName: 'Fresh Foods Ltd', items: 'Vegetables, Rice, Cooking Oil', amount: 185000, status: 'approved', orderDate: addDays(T, -2), notes: 'Weekly kitchen supply' },
  { id: 'bo_p3', vendorName: 'CleanPro Supplies', items: 'Detergent 50L, Bleach 20L, Mops x10', amount: 95000, status: 'draft', orderDate: addDays(T, -1) },
];

export function seedPayrolls(): PayrollRecord[] {
  const start = new Date();
  start.setDate(1);
  const end = new Date(start.getFullYear(), start.getMonth() + 1, 0);
  const periodStart = start.toISOString().slice(0, 10);
  const periodEnd = end.toISOString().slice(0, 10);
  return [
    { id: 'bo_pl1', staffName: 'Amina Yusuf', department: 'Front Desk', basicSalary: 120000, allowances: 15000, deductions: 2000, payeTax: 8400, pensionContribution: 9600, netPay: 115000, periodStart, periodEnd, paidDate: addDays(T, -1) },
    { id: 'bo_pl2', staffName: 'Chidi Okonkwo', department: 'Housekeeping', basicSalary: 70000, allowances: 5000, deductions: 1000, payeTax: 4900, pensionContribution: 5600, netPay: 63500, periodStart, periodEnd },
    { id: 'bo_pl3', staffName: 'Blessing Eze', department: 'Management', basicSalary: 200000, allowances: 30000, deductions: 5000, payeTax: 14000, pensionContribution: 16000, netPay: 195000, periodStart, periodEnd },
  ];
}

export const seedTaxConfig = (): TaxConfiguration => ({
  id: 'tax_default', vatRate: 7.5, citRate: 30, lgaDevelopmentLevy: 1, pensionEmployeeRate: 8, pensionEmployerRate: 10,
});

// ─── Security & Audit ────────────────────────────────────────────────────────

export const seedNightAudits = (): NightAuditLog[] => [
  { id: 'sa_na1', businessDate: addDays(T, -1), totalRevenue: 485000, roomRevenue: 350000, fnbRevenue: 95000, otherRevenue: 40000, cashDropCount: 2, cashDropTotal: 120000, closedBy: 'Lateef', locked: true, closedAt: addDays(T, -1) + 'T23:59:00' },
  { id: 'sa_na2', businessDate: addDays(T, -2), totalRevenue: 412000, roomRevenue: 300000, fnbRevenue: 82000, otherRevenue: 30000, cashDropCount: 1, cashDropTotal: 65000, closedBy: 'Lateef', locked: true, closedAt: addDays(T, -2) + 'T23:59:00' },
];

export const seedIncidents = (): SecurityIncident[] => [
  { id: 'sa_i1', type: 'theft', location: 'Room 103', description: 'Guest reported missing laptop from room', reportedBy: 'Fatima (HK)', status: 'investigating' },
  { id: 'sa_i2', type: 'propertyDamage', location: 'Pool Area', description: 'Broken sun lounger', reportedBy: 'Pool Attendant', status: 'resolved', resolvedBy: 'Maintenance', dateResolved: addDays(T, -1), notes: 'Lounger replaced' },
];

export const seedVisitors = (): VisitorPass[] => [
  { id: 'sa_v1', visitorName: 'Mr. Adebayo Oke', purpose: 'Meeting with GM', hostName: 'Blessing Eze', badgeNumber: 'V-001', checkIn: addDays(T, 0) + 'T10:30:00' },
  { id: 'sa_v2', visitorName: 'Dr. Ngozi Okonkwo', purpose: 'Health Inspection', hostName: 'Management', badgeNumber: 'V-002', checkIn: addDays(T, 0) + 'T11:00:00' },
];

export const seedShifts = (): ShiftHandover[] => [];
