// ─── Core (shared across modules) ────────────────────────────────────────────

export type RoomStatus = 'available' | 'occupied' | 'maintenance';
export interface Room { id: string; number: string; type: string; status: RoomStatus; price: number }

export type BookingStatus = 'confirmed' | 'checked-in' | 'checked-out' | 'cancelled';
export interface Booking { id: string; guest: string; phone: string; room: string; checkin: string; checkout: string; status: BookingStatus; amount: number }

export interface Diesel { id: string; date: string; liters: number; cost: number; supplier: string; genHours: number; note: string }

export interface InventoryItem { id: string; name: string; qty: number; low: number; cost: number }

export interface Staff { id: string; name: string; role: string; salary: number }

export interface Vendor { id: string; name: string; contact: string; category: string }

export type POStatus = 'pending' | 'approved' | 'delivered';
export interface PurchaseOrder { id: string; vendorId: string; items: string; amount: number; date: string; status: POStatus }

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
  receiptRef: string; notes: string; department?: string; createdAt: string;
}

// ─── Subscriptions ───────────────────────────────────────────────────────────

export type BillingCycle = 'monthly' | 'quarterly' | 'annual';
export type SubscriptionStatus = 'active' | 'expiring' | 'expired';
export interface Subscription {
  id: string; name: string; provider: string; category: string; amount: number;
  billingCycle: BillingCycle; startDate: string; status: SubscriptionStatus;
  contactInfo?: string; notes?: string; autoLogExpenditure: boolean;
}

// ─── Compliance ──────────────────────────────────────────────────────────────

export interface ScumlTransaction {
  id: string; date: string; guestName: string; address: string; idType: string;
  idNumber: string; amount: number; purpose: string;
  submittedToScuml: boolean; submittedDate?: string; createdAt: string;
}
export const SCUML_THRESHOLD = 5000000;

export interface CashTransaction {
  id: string; date: string; guestName: string; receiptNumber: string;
  paymentMethod: 'cash' | 'pos' | 'transfer'; amount: number; purpose: string;
  flagged: boolean; createdAt: string;
}

export interface StateTaxConfig { stateName: string; rate: number; appliesToOtherServices: boolean }

export type TaxReportStatus = 'pending' | 'filed' | 'paid';
export interface StateTaxReport {
  id: string; stateName: string; rate: number; totalSales: number; taxDue: number;
  periodStart: string; periodEnd: string; status: TaxReportStatus;
}

export type FireCertStatus = 'valid' | 'expired' | 'pending-renewal';
export interface FireServiceCert {
  id: string; certificateNumber: string; issueDate: string; expiryDate: string;
  fireServiceOffice: string; status: FireCertStatus; inspectionScore?: number;
}

export type NaptipIncidentType = 'humanTrafficking' | 'forcedLabour' | 'childLabour' | 'exploitation' | 'other';
export type NaptipStatus = 'pending' | 'investigated' | 'resolved';
export interface NaptipAlert {
  id: string; date: string; type: NaptipIncidentType; description: string;
  actionTaken: string; reportedTo: string; status: NaptipStatus;
}

export interface LgaInspection {
  id: string; inspectionDate: string; inspector: string; agency: string;
  certificateNumber: string; expiryDate?: string; score: number; status: string;
  passedItems: string[]; failedItems: string[];
}

// ─── Operations ──────────────────────────────────────────────────────────────

export const TOTAL_ROOMS = 12;
export interface DailyRevenue { id: string; date: string; roomsSold: number; walkIns: number; totalRevenue: number }

export type CashDropStatus = 'matched' | 'mismatched';
export type ShiftName = 'Morning' | 'Evening' | 'Night';
export interface CashDrop { id: string; date: string; shift: ShiftName; expectedAmount: number; actualAmount: number; status: CashDropStatus; notes?: string }

export interface HousekeepingLoss { id: string; date: string; item: string; category: string; quantity: number; unitCost: number; roomNumber: string }

// ─── Reconciliation ──────────────────────────────────────────────────────────

export interface BankTransaction {
  id: string; date: string; description: string; amount: number;
  reference?: string; balance?: number; source?: string; type: 'CR' | 'DR';
}

export type MatchEntityType = 'booking' | 'expenditure';
export interface ReconciliationMatch {
  id: string; bankTransactionId: string; entityType: MatchEntityType;
  entityId: string; entityLabel: string; entityAmount: number;
  matchedAmount: number; confidence: number; isManual: boolean; matchedAt: string;
}
export interface SplitAllocation { entityType: MatchEntityType; entityId: string; entityLabel: string; amount: number }
export interface SplitPayment { id: string; bankTransactionId: string; allocations: SplitAllocation[] }

export type VirtualAccountStatus = 'pending' | 'active' | 'matched' | 'expired';
export interface VirtualAccount {
  id: string; bookingId: string; guestName: string; bankName: string;
  accountNumber: string; accountName: string; amount: number;
  status: VirtualAccountStatus; createdAt: string; expiresAt?: string;
}

export type PosStatus = 'active' | 'inactive';
export interface PosTerminal { id: string; terminalId: string; bankName: string; merchantCode: string; status: PosStatus; addedAt: string }

export type SettlementStatus = 'pending' | 'settled' | 'flagged';
export interface PosSettlement { id: string; terminalId: string; terminalRef: string; amount: number; date: string; status: SettlementStatus; note?: string }

// ─── F&B ─────────────────────────────────────────────────────────────────────

export type MenuCategory = 'food' | 'drink' | 'bar' | 'wine' | 'special';
export interface MenuItem { id: string; name: string; category: MenuCategory; price: number; description?: string; available: boolean }

export type TableStatus = 'free' | 'occupied' | 'reserved' | 'cleaning';
export interface RestaurantTable { id: string; number: string; seats: number; status: TableStatus }

export type OrderItemStatus = 'pending' | 'preparing' | 'ready' | 'served';
export interface OrderItem { id: string; menuItemId: string; name: string; quantity: number; unitPrice: number; status: OrderItemStatus; note?: string }
export type OrderStatus = 'open' | 'preparing' | 'served' | 'paid' | 'cancelled';
export interface Order {
  id: string; tableId: string; items: OrderItem[]; status: OrderStatus;
  discount?: number; paymentMethod?: string; note?: string;
  openedAt: string; closedAt?: string; servedBy?: string;
}

// ─── Engineering ─────────────────────────────────────────────────────────────

export type GeneratorStatus = 'running' | 'idle' | 'maintenance' | 'fault';
export interface Generator {
  id: string; name: string; model: string; capacityKva: number;
  currentRunHours: number; currentLoadKva: number; status: GeneratorStatus;
  lastServiceDate?: string;
}

export type MaintenancePriority = 'routine' | 'important' | 'urgent' | 'critical';
export type EquipmentType = 'generator' | 'hvac' | 'lift' | 'waterPump' | 'waterTreatment' | 'electrical' | 'plumbing' | 'other';
export interface MaintenanceTask {
  id: string; equipmentName: string; description?: string; assignedTo: string;
  equipmentType: EquipmentType; priority: MaintenancePriority;
  scheduledDate: string; completed: boolean; completedAt?: string; notes?: string;
}

export interface WaterTreatmentLog {
  id: string; date: string; source: string; treatmentAction: string;
  phLevel: number; chlorineLevel?: number; tdsLevel?: number;
  chemicalUsed?: string; chemicalDosageMl?: number; nextScheduledDate?: string;
  performedBy?: string; notes?: string;
}

export interface TankDipLog {
  id: string; date: string; tankName: string; dipReadingCm: number;
  tankCapacityL: number; calculatedVolumeL: number; expectedVolumeL?: number;
  performedBy: string; notes?: string;
}

export type GridBand = 'a' | 'b' | 'c';
export interface GridTariffConfig { id: string; band: GridBand; hoursPerDay: number; costPerKwh: number; label: string; description: string }

// ─── Housekeeping ────────────────────────────────────────────────────────────

export type HousekeepingPriority = 'routine' | 'deepClean' | 'turndown' | 'vipSetup';
export interface HousekeepingTask {
  id: string; roomNumber: string; assignedTo: string; priority: HousekeepingPriority;
  scheduledDate: string; completed: boolean; completedAt?: string; notes?: string;
}

export type LaundryType = 'washIron' | 'dryCleanOnly' | 'selfService';
export type LaundryStatus = 'received' | 'washing' | 'drying' | 'ironing' | 'ready' | 'delivered';
export interface LaundryItem {
  id: string; guestName: string; roomNumber: string; itemDescription: string;
  type: LaundryType; status: LaundryStatus; chargeAmount: number;
  receivedDate?: string; deliveredDate?: string;
}

export type LostFoundCategory = 'electronics' | 'jewelry' | 'documents' | 'clothing' | 'luggage' | 'other';
export interface LostFoundItem {
  id: string; itemName: string; foundBy: string; locationFound: string;
  category: LostFoundCategory; guestName?: string; notes?: string;
  returned: boolean; returnedAt?: string;
}

export type LinenCategory = 'bedsheet' | 'towel' | 'pillowcase' | 'duvet' | 'other';
export type LinenCondition = 'stained' | 'torn' | 'damaged' | 'condemned';
export interface LinenDamage {
  id: string; itemName: string; roomNumber: string; category: LinenCategory;
  condition: LinenCondition; quantity: number; replacementCost?: number; notes?: string;
}

// ─── Back Office ─────────────────────────────────────────────────────────────

export type ProcurementStatus = 'draft' | 'approved' | 'ordered' | 'delivered' | 'cancelled';
export interface ProcurementOrder {
  id: string; vendorName: string; items: string; amount: number;
  status: ProcurementStatus; orderDate: string; deliveryDate?: string; notes?: string;
}

export type PayrollStatus = 'pending' | 'paid' | 'cancelled';
export interface PayrollRecord {
  id: string; staffName: string; department: string; basicSalary: number;
  allowances: number; deductions: number; payeTax: number; pensionContribution: number;
  netPay: number; periodStart: string; periodEnd: string; paidDate?: string;
}

export interface TaxConfiguration {
  id: string; vatRate: number; citRate: number; lgaDevelopmentLevy: number;
  pensionEmployeeRate: number; pensionEmployerRate: number;
}

// ─── Security & Audit ────────────────────────────────────────────────────────

export interface NightAuditLog {
  id: string; businessDate: string; totalRevenue: number; roomRevenue: number;
  fnbRevenue: number; otherRevenue: number; cashDropCount: number;
  cashDropTotal: number; closedBy?: string; locked: boolean; closedAt?: string;
}

export type IncidentType = 'theft' | 'fire' | 'medical' | 'intruder' | 'propertyDamage' | 'noiseComplaint' | 'other';
export type IncidentStatus = 'open' | 'investigating' | 'resolved';
export interface SecurityIncident {
  id: string; type: IncidentType; location: string; description: string;
  reportedBy: string; status: IncidentStatus; resolvedBy?: string;
  dateResolved?: string; notes?: string;
}

export interface VisitorPass {
  id: string; visitorName: string; purpose: string; hostName: string;
  badgeNumber: string; checkIn: string; checkOut?: string;
}

export type ShiftType = 'morning' | 'afternoon' | 'night';
export interface ShiftHandover {
  id: string; shiftType: ShiftType; openedAt: string; openedBy: string;
  notes?: string; closedAt?: string; closedBy?: string;
}
