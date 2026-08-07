import { Department } from './rbac';

// ─── Core (shared across modules) ────────────────────────────────────────────

export type RoomStatus = 'available' | 'occupied' | 'maintenance';
export interface Room { id: string; number: string; type: string; status: RoomStatus; price: number; departments?: Department[] }

export type BookingStatus = 'confirmed' | 'checked-in' | 'checked-out' | 'cancelled';
export interface Booking { id: string; guest: string; phone: string; room: string; checkin: string; checkout: string; status: BookingStatus; amount: number; departments?: Department[] }

export interface Diesel { id: string; date: string; liters: number; cost: number; supplier: string; genHours: number; note: string; departments?: Department[] }

export interface InventoryItem { id: string; name: string; qty: number; low: number; cost: number; departments?: Department[] }

export interface Staff { id: string; name: string; role: string; salary: number; departments?: Department[] }

export interface Vendor { id: string; name: string; contact: string; category: string; departments?: Department[] }

export type POStatus = 'pending' | 'approved' | 'delivered';
export interface PurchaseOrder { id: string; vendorId: string; items: string; amount: number; date: string; status: POStatus; departments?: Department[] }

// ─── Expenses ────────────────────────────────────────────────────────────────

export const EXPENSE_CATEGORIES = [
  'F&B', 'Logistics / Transport', 'Toiletries & Amenities', 'Laundry & Linen',
  'Utilities (Power/Water)', 'Maintenance & Repairs', 'Marketing & Advertising',
  'Procurement', 'Administrative', 'Other',
] as const;
export type ExpenditureCategory = typeof EXPENSE_CATEGORIES[number];

export type PaymentMethod = 'Cash' | 'Transfer' | 'POS' | 'Card';
export interface ExpenditureRecord {
  id: string; date: string; category: ExpenditureCategory; subcategory: string;
  description: string; amount: number; vendor: string; paymentMethod: PaymentMethod;
  receiptRef: string; notes: string; departments?: Department[]; createdAt: string;
}

// ─── Subscriptions ───────────────────────────────────────────────────────────

export type BillingCycle = 'monthly' | 'quarterly' | 'annual';
export type SubscriptionStatus = 'active' | 'expiring' | 'expired' | 'cancelled';
export interface Subscription {
  id: string; name: string; provider: string; category: string; amount: number;
  billingCycle: BillingCycle; startDate: string; status: SubscriptionStatus;
  contactInfo?: string; notes?: string; autoLogExpenditure: boolean;
  departments?: Department[];
}

// ─── Compliance ──────────────────────────────────────────────────────────────

export interface ScumlTransaction {
  id: string; date: string; guestName: string; address: string; idType: string;
  idNumber: string; amount: number; purpose: string;
  submittedToScuml: boolean; submittedDate?: string; createdAt: string;
  departments?: Department[];
}
export const SCUML_THRESHOLD = 5000000;

export interface CashTransaction {
  id: string; date: string; guestName: string; receiptNumber: string;
  paymentMethod: 'cash' | 'pos' | 'transfer'; amount: number; purpose: string;
  flagged: boolean; createdAt: string; departments?: Department[];
}

export interface StateTaxConfig { stateName: string; rate: number; appliesToOtherServices: boolean; departments?: Department[] }

export type TaxReportStatus = 'pending' | 'filed' | 'paid';
export interface StateTaxReport {
  id: string; stateName: string; rate: number; totalSales: number; taxDue: number;
  periodStart: string; periodEnd: string; status: TaxReportStatus;
  departments?: Department[];
}

export type FireCertStatus = 'valid' | 'expired' | 'pending-renewal';
export interface FireServiceCert {
  id: string; certificateNumber: string; issueDate: string; expiryDate: string;
  fireServiceOffice: string; status: FireCertStatus; inspectionScore?: number;
  departments?: Department[];
}

export type NaptipIncidentType = 'humanTrafficking' | 'forcedLabour' | 'childLabour' | 'exploitation' | 'other';
export type NaptipStatus = 'pending' | 'investigated' | 'resolved';
export interface NaptipAlert {
  id: string; date: string; type: NaptipIncidentType; description: string;
  actionTaken: string; reportedTo: string; status: NaptipStatus;
  departments?: Department[];
}

export interface LgaInspection {
  id: string; inspectionDate: string; inspector: string; agency: string;
  certificateNumber: string; expiryDate?: string; score: number; status: string;
  passedItems: string[]; failedItems: string[]; departments?: Department[];
}

// ─── Operations ──────────────────────────────────────────────────────────────

export const TOTAL_ROOMS = 12;
export interface DailyRevenue { id: string; date: string; roomsSold: number; walkIns: number; totalRevenue: number; departments?: Department[] }

export type CashDropStatus = 'matched' | 'mismatched';
export type ShiftName = 'Morning' | 'Evening' | 'Night';
export interface CashDrop { id: string; date: string; shift: ShiftName; expectedAmount: number; actualAmount: number; status: CashDropStatus; notes?: string; departments?: Department[] }

export interface HousekeepingLoss { id: string; date: string; item: string; category: string; quantity: number; unitCost: number; roomNumber: string; departments?: Department[] }

// ─── Reconciliation ──────────────────────────────────────────────────────────

export interface BankTransaction {
  id: string; date: string; description: string; amount: number;
  reference?: string; balance?: number; source?: string; type: 'CR' | 'DR';
  departments?: Department[];
}

export type MatchEntityType = 'booking' | 'expenditure';
export interface ReconciliationMatch {
  id: string; bankTransactionId: string; entityType: MatchEntityType;
  entityId: string; entityLabel: string; entityAmount: number;
  matchedAmount: number; confidence: number; isManual: boolean; matchedAt: string;
  departments?: Department[];
}
export interface SplitAllocation { entityType: MatchEntityType; entityId: string; entityLabel: string; amount: number }
export interface SplitPayment { id: string; bankTransactionId: string; allocations: SplitAllocation[]; departments?: Department[] }

export type VirtualAccountStatus = 'pending' | 'active' | 'matched' | 'expired';
export interface VirtualAccount {
  id: string; bookingId: string; guestName: string; bankName: string;
  accountNumber: string; accountName: string; amount: number;
  status: VirtualAccountStatus; createdAt: string; expiresAt?: string;
  departments?: Department[];
}

export type PosStatus = 'active' | 'inactive';
export interface PosTerminal { id: string; terminalId: string; bankName: string; merchantCode: string; status: PosStatus; addedAt: string; departments?: Department[] }

export type SettlementStatus = 'pending' | 'settled' | 'flagged';
export interface PosSettlement { id: string; terminalId: string; terminalRef: string; amount: number; date: string; status: SettlementStatus; note?: string; departments?: Department[] }

// ─── F&B ─────────────────────────────────────────────────────────────────────

export type MenuCategory = 'food' | 'drink' | 'bar' | 'wine' | 'special';
export interface MenuItem { id: string; name: string; category: MenuCategory; price: number; description?: string; available: boolean; departments?: Department[] }

export type TableStatus = 'free' | 'occupied' | 'reserved' | 'cleaning';
export interface RestaurantTable { id: string; number: string; seats: number; status: TableStatus; departments?: Department[] }

export type OrderItemStatus = 'pending' | 'preparing' | 'ready' | 'served';
export interface OrderItem { id: string; menuItemId: string; name: string; quantity: number; unitPrice: number; status: OrderItemStatus; note?: string }
export type OrderStatus = 'open' | 'preparing' | 'served' | 'paid' | 'cancelled';
export interface Order {
  id: string; tableId: string; items: OrderItem[]; status: OrderStatus;
  discount?: number; paymentMethod?: string; note?: string;
  openedAt: string; closedAt?: string; servedBy?: string; departments?: Department[];
}

// ─── Engineering ─────────────────────────────────────────────────────────────

export type GeneratorStatus = 'running' | 'idle' | 'maintenance' | 'fault';
export interface Generator {
  id: string; name: string; model: string; capacityKva: number;
  currentRunHours: number; currentLoadKva: number; status: GeneratorStatus;
  lastServiceDate?: string; departments?: Department[];
}

export type MaintenancePriority = 'routine' | 'important' | 'urgent' | 'critical';
export type EquipmentType = 'generator' | 'hvac' | 'lift' | 'waterPump' | 'waterTreatment' | 'electrical' | 'plumbing' | 'other';
export interface MaintenanceTask {
  id: string; equipmentName: string; description?: string; assignedTo: string;
  equipmentType: EquipmentType; priority: MaintenancePriority;
  scheduledDate: string; completed: boolean; completedAt?: string; notes?: string;
  departments?: Department[];
}

export interface WaterTreatmentLog {
  id: string; date: string; source: string; treatmentAction: string;
  phLevel: number; chlorineLevel?: number; tdsLevel?: number;
  chemicalUsed?: string; chemicalDosageMl?: number; nextScheduledDate?: string;
  performedBy?: string; notes?: string; departments?: Department[];
}

export interface TankDipLog {
  id: string; date: string; tankName: string; dipReadingCm: number;
  tankCapacityL: number; calculatedVolumeL: number; expectedVolumeL?: number;
  performedBy: string; notes?: string; departments?: Department[];
}

export type GridBand = 'a' | 'b' | 'c';
export interface GridTariffConfig { id: string; band: GridBand; hoursPerDay: number; costPerKwh: number; label: string; description: string; departments?: Department[] }

// ─── Housekeeping ────────────────────────────────────────────────────────────

export type HousekeepingPriority = 'routine' | 'deepClean' | 'turndown' | 'vipSetup';
export interface HousekeepingTask {
  id: string; roomNumber: string; assignedTo: string; priority: HousekeepingPriority;
  scheduledDate: string; completed: boolean; completedAt?: string; notes?: string;
  departments?: Department[];
}

export type LaundryType = 'washIron' | 'dryCleanOnly' | 'selfService';
export type LaundryStatus = 'received' | 'washing' | 'drying' | 'ironing' | 'ready' | 'delivered';
export interface LaundryItem {
  id: string; guestName: string; roomNumber: string; itemDescription: string;
  type: LaundryType; status: LaundryStatus; chargeAmount: number;
  receivedDate?: string; deliveredDate?: string; departments?: Department[];
}

export type LostFoundCategory = 'electronics' | 'jewelry' | 'documents' | 'clothing' | 'luggage' | 'other';
export interface LostFoundItem {
  id: string; itemName: string; foundBy: string; locationFound: string;
  category: LostFoundCategory; guestName?: string; notes?: string;
  returned: boolean; returnedAt?: string; departments?: Department[];
}

export type LinenCategory = 'bedsheet' | 'towel' | 'pillowcase' | 'duvet' | 'mattressProtector' | 'bathrobe' | 'other';
export type LinenCondition = 'new' | 'good' | 'stained' | 'torn' | 'damaged';
export interface LinenDamage {
  id: string; itemName: string; roomNumber: string; category: LinenCategory;
  condition: LinenCondition; quantity: number; replacementCost?: number; notes?: string;
  departments?: Department[];
}

// ─── Back Office ─────────────────────────────────────────────────────────────

export type ProcurementStatus = 'draft' | 'approved' | 'ordered' | 'delivered' | 'cancelled';
export interface ProcurementOrder {
  id: string; vendorName: string; items: string; amount: number;
  status: ProcurementStatus; orderDate: string; deliveryDate?: string; notes?: string;
  departments?: Department[];
}

export type PayrollStatus = 'pending' | 'paid' | 'cancelled';
export interface PayrollRecord {
  id: string; staffName: string; department: string; basicSalary: number;
  allowances: number; deductions: number; payeTax: number; pensionContribution: number;
  netPay: number; periodStart: string; periodEnd: string; paidDate?: string;
  departments?: Department[];
}

export interface TaxConfiguration {
  id: string; vatRate: number; citRate: number; lgaDevelopmentLevy: number;
  pensionEmployeeRate: number; pensionEmployerRate: number;
  departments?: Department[];
}

// ─── Security & Audit ────────────────────────────────────────────────────────

export interface NightAuditLog {
  id: string; businessDate: string; totalRevenue: number; roomRevenue: number;
  fnbRevenue: number; otherRevenue: number; cashDropCount: number;
  cashDropTotal: number; closedBy?: string; locked: boolean; closedAt?: string;
  departments?: Department[];
}

export type IncidentType = 'theft' | 'fire' | 'medical' | 'intruder' | 'propertyDamage' | 'noiseComplaint' | 'other';
export type IncidentStatus = 'open' | 'investigating' | 'resolved';
export interface SecurityIncident {
  id: string; type: IncidentType; location: string; description: string;
  reportedBy: string; status: IncidentStatus; resolvedBy?: string;
  dateResolved?: string; notes?: string; departments?: Department[];
}

export interface VisitorPass {
  id: string; visitorName: string; purpose: string; hostName: string;
  badgeNumber: string; checkIn: string; checkOut?: string;
  departments?: Department[];
}

export type ShiftType = 'morning' | 'afternoon' | 'night';
export interface ShiftHandover {
  id: string; shiftType: ShiftType; openedAt: string; openedBy: string;
  notes?: string; closedAt?: string; closedBy?: string;
  departments?: Department[];
}
