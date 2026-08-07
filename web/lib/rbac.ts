// ──────────────────────────────────────────────────────────────
// Six Integrated Pillars of HOM
// ──────────────────────────────────────────────────────────────
// 1. ROOMS DIVISION (Front of House)
// 2. HOUSEKEEPING & ASSETS (Back of House)
// 3. ENGINEERING & UTILITIES (Standalone — biggest OPEX)
// 4. F&B & BANQUETING
// 5. BACK OFFICE & SUPPLY CHAIN
// 6. COMPLIANCE, SECURITY & AUDIT
// ──────────────────────────────────────────────────────────────
// Zero-trust, additive RBAC — mirrors mobile/lib/models/role.dart
// and mobile/lib/data/role_store.dart. Keep BOTH in lockstep:
// every change here must be mirrored in the Flutter app.

export type AccountStatus = 'pending' | 'active' | 'suspended';

export const ACCOUNT_STATUS_LABEL: Record<AccountStatus, string> = {
  pending: 'Awaiting Assignment',
  active: 'Active',
  suspended: 'Suspended',
};

export const DEPARTMENTS = [
  'management', 'reception', 'concierge', 'reservations', 'housekeeping',
  'laundry', 'engineering', 'restaurants', 'kitchen', 'banqueting',
  'procurement', 'accounts', 'humanResources', 'security', 'healthSafety',
] as const;
export type Department = typeof DEPARTMENTS[number];

export const isDepartment = (s: string): s is Department =>
  (DEPARTMENTS as readonly string[]).includes(s);

export const DEPARTMENT_LABEL: Record<Department, string> = {
  management: 'Management',
  reception: 'Reception',
  concierge: 'Concierge',
  reservations: 'Reservations',
  housekeeping: 'Housekeeping',
  laundry: 'Laundry',
  engineering: 'Engineering',
  restaurants: 'Restaurants',
  kitchen: 'Kitchen',
  banqueting: 'Banqueting',
  procurement: 'Procurement',
  accounts: 'Accounts',
  humanResources: 'Human Resources',
  security: 'Security',
  healthSafety: 'Health & Safety',
};

// ──────────────────────────────────────────────────────────────
// 85+ PERMISSIONS — ORGANISED BY PILLAR
// ──────────────────────────────────────────────────────────────

export const PERMISSIONS = {
  // ========= PILLAR 1: ROOMS (FRONT OF HOUSE) =========
  viewBookings: 'viewBookings', createBooking: 'createBooking',
  editBooking: 'editBooking', deleteBooking: 'deleteBooking',
  checkInGuest: 'checkInGuest', checkOutGuest: 'checkOutGuest',
  extendStay: 'extendStay',
  postRoomCharge: 'postRoomCharge', manageGuestProfiles: 'manageGuestProfiles',
  manageKeycards: 'manageKeycards',
  manageConciergeShuttles: 'manageConciergeShuttles',
  manageConciergeLuggage: 'manageConciergeLuggage',
  manageConciergeTours: 'manageConciergeTours',
  manageConciergeCarRental: 'manageConciergeCarRental',
  manageReservations: 'manageReservations', manageGroupBookings: 'manageGroupBookings',
  manageChannelManager: 'manageChannelManager',
  viewMultiCurrencyBilling: 'viewMultiCurrencyBilling',
  manageVirtualAccounts: 'manageVirtualAccounts',
  autoMatchBankTransfers: 'autoMatchBankTransfers',
  trackPOSTerminals: 'trackPOSTerminals',
  manageSplitPayments: 'manageSplitPayments', parseBankCSV: 'parseBankCSV',

  // ========= PILLAR 2: HOUSEKEEPING & ASSETS =========
  viewHousekeeping: 'viewHousekeeping',
  viewRooms: 'viewRooms', manageRooms: 'manageRooms', updateRoomStatus: 'updateRoomStatus',
  assignRoomAttendants: 'assignRoomAttendants', trackMiniBarConsumption: 'trackMiniBarConsumption',
  manageLostAndFound: 'manageLostAndFound', logLinenDamage: 'logLinenDamage',
  logMinibarLoss: 'logMinibarLoss', manageLaundry: 'manageLaundry',
  manageGuestDryCleaning: 'manageGuestDryCleaning',

  // ========= PILLAR 3: ENGINEERING & UTILITIES =========
  viewEngineering: 'viewEngineering',
  trackGeneratorRunHours: 'trackGeneratorRunHours',
  trackFuelDeliveryCycles: 'trackFuelDeliveryCycles',
  manageTankCalibration: 'manageTankCalibration',
  trackDieselConsumptionRate: 'trackDieselConsumptionRate',
  trackGridTariffUsage: 'trackGridTariffUsage', viewPowerCostAnalysis: 'viewPowerCostAnalysis',
  manageWaterTreatment: 'manageWaterTreatment', manageWaterTreatmentChemicals: 'manageWaterTreatmentChemicals',
  manageBackwashSchedule: 'manageBackwashSchedule', manageLifts: 'manageLifts', manageHVAC: 'manageHVAC',
  managePreventativeMaintenance: 'managePreventativeMaintenance',
  viewMaintenanceSchedule: 'viewMaintenanceSchedule',

  // ========= PILLAR 4: F&B & BANQUETING =========
  managePOS: 'managePOS', manageSplitChecks: 'manageSplitChecks', manageTableManagement: 'manageTableManagement',
  manageKDS: 'manageKDS', manageRecipeCosting: 'manageRecipeCosting',
  trackIngredientShortages: 'trackIngredientShortages',
  manageBanquetingHallRentals: 'manageBanquetingHallRentals', manageAVEquipment: 'manageAVEquipment',
  manageBuffetMenus: 'manageBuffetMenus', manageSeatingConfig: 'manageSeatingConfig',
  manageCorporateEvents: 'manageCorporateEvents',

  // ========= PILLAR 5: BACK OFFICE & SUPPLY CHAIN =========
  viewBackOffice: 'viewBackOffice',
  viewInventory: 'viewInventory', manageInventory: 'manageInventory',
  viewVendors: 'viewVendors', manageVendors: 'manageVendors', managePurchaseOrders: 'managePurchaseOrders',
  trackBulkFuelDeliveries: 'trackBulkFuelDeliveries', manageSupplierContracts: 'manageSupplierContracts',
  viewExpenditure: 'viewExpenditure', createExpenditure: 'createExpenditure', approveExpenditure: 'approveExpenditure',
  viewReconciliation: 'viewReconciliation', manageReconciliation: 'manageReconciliation',
  viewFuel: 'viewFuel', logFuel: 'logFuel',
  viewReports: 'viewReports', viewRevPAR: 'viewRevPAR', viewNightAudit: 'viewNightAudit', manageDailyAudit: 'manageDailyAudit',
  manageTaxConfig: 'manageTaxConfig', manageDualTaxConfig: 'manageDualTaxConfig', manageMultiCurrencyAccounting: 'manageMultiCurrencyAccounting',
  viewStaff: 'viewStaff', manageStaff: 'manageStaff', runPayroll: 'runPayroll',
  manageShiftScheduling: 'manageShiftScheduling', manageClockIn: 'manageClockIn', manageCasualWorkers: 'manageCasualWorkers',
  processPAYE: 'processPAYE', processPension: 'processPension',
  viewOperations: 'viewOperations',
  viewActivityFeed: 'viewActivityFeed',
  manageSubscriptions: 'manageSubscriptions', manageWhatsApp: 'manageWhatsApp', sendAutomatedWhatsApp: 'sendAutomatedWhatsApp',
  sendWhatsAppPayslips: 'sendWhatsAppPayslips', manageUsers: 'manageUsers',

  // ========= PILLAR 6: COMPLIANCE, SECURITY & AUDIT =========
  viewSecurityAudit: 'viewSecurityAudit',
  manageCompliance: 'manageCompliance', viewCompliance: 'viewCompliance',
  captureGuestNIN: 'captureGuestNIN', logCashTransactions: 'logCashTransactions',
  manageLGAHealthPermits: 'manageLGAHealthPermits', manageFireServiceCertificates: 'manageFireServiceCertificates',
  manageShiftHandover: 'manageShiftHandover', logCashDrop: 'logCashDrop',
  closeNightAudit: 'closeNightAudit', lockTransactions: 'lockTransactions',
  manageVisitorPasses: 'manageVisitorPasses', managePatrolCheckpoints: 'managePatrolCheckpoints',
  manageIncidentReports: 'manageIncidentReports',
  manageWaterQualityTests: 'manageWaterQualityTests', managePoolChemistry: 'managePoolChemistry',
  manageFoodSafetyInspections: 'manageFoodSafetyInspections',
} as const;

export type Permission = typeof PERMISSIONS[keyof typeof PERMISSIONS];

export const ALL_PERMISSIONS = Object.values(PERMISSIONS);

// ──────────────────────────────────────────────────────────────

export interface AppRole {
  id: string;
  name: string;
  department?: Department;
  permissions: Permission[];
}

const P = PERMISSIONS;

// Mirrors RoleStore.prebuiltRoles in mobile/lib/data/role_store.dart.
export const PREBUILT_ROLES: AppRole[] = [
  {
    id: 'super_admin',
    name: 'Super Admin / Owner',
    permissions: ALL_PERMISSIONS,
  },
  {
    id: 'hotel_manager',
    name: 'Hotel Manager / GM',
    permissions: ALL_PERMISSIONS,
  },
  {
    id: 'auditor',
    name: 'Auditor / Owner (Read-only)',
    permissions: [
      // Pillar 1 — rooms view only
      P.viewBookings, P.viewRooms, P.viewMultiCurrencyBilling,
      // Pillar 3 — engineering view + power cost
      P.viewEngineering, P.viewPowerCostAnalysis,
      // Pillar 5 — back office + financial view only
      P.viewBackOffice, P.viewExpenditure, P.viewReconciliation,
      P.viewFuel, P.viewReports, P.viewRevPAR, P.viewNightAudit,
      P.viewCompliance, P.captureGuestNIN,
      P.viewActivityFeed,
    ],
  },
  {
    id: 'front_desk',
    name: 'Front Desk / Reception',
    department: 'reception',
    permissions: [
      // Pillar 1 — full front office ops
      P.viewBookings, P.createBooking, P.editBooking,
      P.checkInGuest, P.checkOutGuest, P.extendStay,
      P.postRoomCharge, P.viewMultiCurrencyBilling,
      P.manageVirtualAccounts, P.trackPOSTerminals, P.manageSplitPayments,
      P.viewRooms, P.updateRoomStatus, P.viewInventory,
      P.manageKeycards,
      P.manageConciergeShuttles, P.manageConciergeLuggage,
      P.manageConciergeTours, P.manageConciergeCarRental,
      // Pillar 4 — room-service F&B orders at the front desk
      P.managePOS, P.manageSplitChecks, P.manageTableManagement,
      // Pillar 5 — WhatsApp
      P.manageWhatsApp, P.sendAutomatedWhatsApp,
      // Pillar 6 — security audit + shift & compliance
      P.viewSecurityAudit,
      P.manageShiftHandover, P.logCashDrop,
      P.captureGuestNIN, P.logCashTransactions,
      // Cross-pillar
      P.viewOperations,
      P.viewActivityFeed,
    ],
  },
  {
    id: 'accountant',
    name: 'Accountant / Finance',
    department: 'accounts',
    permissions: [
      // Pillar 1 — room & booking view
      P.viewBookings, P.viewRooms, P.viewMultiCurrencyBilling,
      P.autoMatchBankTransfers, P.trackPOSTerminals,
      P.manageSplitPayments, P.parseBankCSV,
      // Pillar 3 — fuel cost view
      P.viewFuel, P.logFuel, P.viewPowerCostAnalysis,
      // Pillar 5 — back office + full financial control
      P.viewBackOffice,
      P.viewExpenditure, P.createExpenditure, P.approveExpenditure,
      P.viewReconciliation, P.manageReconciliation,
      P.viewReports, P.viewRevPAR, P.viewNightAudit, P.manageDailyAudit,
      P.manageTaxConfig, P.manageDualTaxConfig, P.manageMultiCurrencyAccounting,
      P.viewStaff, P.runPayroll,
      // Pillar 6 — security audit + audit & compliance
      P.viewSecurityAudit,
      P.manageShiftHandover, P.closeNightAudit,
      P.lockTransactions, P.logCashDrop,
      P.viewCompliance, P.manageCompliance,
      P.captureGuestNIN, P.logCashTransactions,
      P.manageLGAHealthPermits, P.manageFireServiceCertificates,
      // System
      P.manageSubscriptions,
      P.viewActivityFeed,
    ],
  },
  {
    id: 'housekeeping',
    name: 'Housekeeping',
    department: 'housekeeping',
    permissions: [
      // Pillar 2 — full housekeeping ops
      P.viewHousekeeping,
      P.viewRooms, P.updateRoomStatus,
      P.assignRoomAttendants, P.trackMiniBarConsumption,
      P.manageLostAndFound, P.logLinenDamage, P.logMinibarLoss,
      P.manageLaundry, P.manageGuestDryCleaning,
      // Cross-pillar
      P.viewOperations,
      P.viewActivityFeed,
    ],
  },
  {
    id: 'kitchen',
    name: 'Kitchen / Bar',
    department: 'kitchen',
    permissions: [
      // Pillar 4 — full culinary ops
      P.viewInventory, P.manageInventory,
      P.manageKDS, P.manageRecipeCosting, P.trackIngredientShortages,
      P.managePOS, P.manageSplitChecks, P.manageTableManagement,
      P.createExpenditure,
      // Cross-pillar
      P.viewOperations,
      P.viewActivityFeed,
    ],
  },
  {
    id: 'dept_head',
    name: 'Department Head',
    permissions: [
      // Pillar 5 — their dept only
      P.viewInventory, P.manageInventory, P.createExpenditure,
      P.viewStaff, P.manageStaff,
      // Pillar 3 — engineering view
      P.viewEngineering,
      // Pillar 5 — back office
      P.viewBackOffice,
      // Pillar 6 — security audit
      P.viewSecurityAudit,
      // Cross-pillar
      P.viewOperations, P.viewCompliance,
      P.viewActivityFeed,
    ],
  },
];

export const findRoleById = (roleId: string): AppRole | undefined =>
  PREBUILT_ROLES.find(r => r.id === roleId);

// ──────────────────────────────────────────────────────────────
// SESSION — additive, zero-trust
// ──────────────────────────────────────────────────────────────

export interface Session {
  userId: string;
  userName: string;
  email: string;
  roleIds: string[];
  assignedDepartments: Department[];
  customPermissions: Permission[];
  isHeadOfDepartment: Record<string, boolean>;
  status: AccountStatus;
  hotelId?: string;
  phone?: string;
  photoUrl?: string;
  preferences?: UserPreferences;
}

export const emptySession = (): Session => ({
  userId: '',
  userName: '',
  email: '',
  roleIds: [],
  assignedDepartments: [],
  customPermissions: [],
  isHeadOfDepartment: {},
  status: 'pending',
  preferences: { ...DEFAULT_PREFERENCES },
});

export interface UserPreferences {
  notificationsEnabled: boolean;
  compactMode: boolean;
  language: string;
}

export const DEFAULT_PREFERENCES: UserPreferences = {
  notificationsEnabled: true,
  compactMode: false,
  language: 'en',
};

export const LANGUAGES = [
  { code: 'en', label: 'English' },
  { code: 'fr', label: 'French' },
  { code: 'es', label: 'Spanish' },
  { code: 'ha', label: 'Hausa' },
  { code: 'yo', label: 'Yoruba' },
  { code: 'ig', label: 'Igbo' },
];

export const hasIdentity = (s: Session) => s.userId.length > 0;
export const isAccountActive = (s: Session) => hasIdentity(s) && s.status === 'active';
export const isSuspended = (s: Session) => hasIdentity(s) && s.status === 'suspended';
export const isPendingAssignment = (s: Session) => hasIdentity(s) && s.status === 'pending';

export const resolvedRoles = (s: Session): AppRole[] =>
  s.roleIds.map(findRoleById).filter((r): r is AppRole => !!r);

export const primaryRole = (s: Session): AppRole | undefined =>
  s.roleIds.map(findRoleById).find((r): r is AppRole => !!r);

export const isManagement = (s: Session) =>
  s.roleIds.includes('super_admin') || s.roleIds.includes('hotel_manager');

// ──────────────────────────────────────────────────────────────
// ROLE THEMING — per-role accent so staff instantly know whose
// context they are working in. Mirrors the Flutter app.
// ──────────────────────────────────────────────────────────────

export const ROLE_ACCENT: Record<string, string> = {
  super_admin: '#0E9F6E',
  hotel_manager: '#0E9F6E',
  auditor: '#3B82F6',
  front_desk: '#06B6D4',
  accountant: '#F59E0B',
  housekeeping: '#8B5CF6',
  kitchen: '#F43F5E',
  dept_head: '#6366F1',
};

export const roleAccent = (s: Session): string => {
  const r = primaryRole(s);
  return (r && ROLE_ACCENT[r.id]) || '#0E9F6E';
};

export const rolePermissions = (s: Session): Permission[] => {
  const out: Permission[] = [];
  for (const r of resolvedRoles(s)) {
    for (const p of r.permissions) {
      if (!out.includes(p)) out.push(p);
    }
  }
  return out;
};

export const effectivePermissions = (s: Session): Permission[] => {
  const out = rolePermissions(s);
  for (const p of s.customPermissions) {
    if (!out.includes(p)) out.push(p);
  }
  return out;
};

/** Zero-trust union check. Denies everything for pending/suspended accounts. */
export const hasPermission = (s: Session, p: Permission): boolean => {
  if (!isAccountActive(s)) return false;
  if (s.customPermissions.includes(p)) return true;
  return resolvedRoles(s).some(r => r.permissions.includes(p));
};

export const hasAnyPermission = (s: Session, perms: Permission[]): boolean =>
  perms.some(p => hasPermission(s, p));

export const hasAllPermissions = (s: Session, perms: Permission[]): boolean =>
  perms.every(p => hasPermission(s, p));

/** Department scoping. Management bypasses scope; everyone else restricted. */
export const canAccessDepartment = (s: Session, dept: Department): boolean => {
  if (!isAccountActive(s)) return false;
  if (isManagement(s)) return true;
  return s.assignedDepartments.includes(dept) || s.isHeadOfDepartment[dept] === true;
};

export const isHeadOf = (s: Session, dept: Department): boolean =>
  s.isHeadOfDepartment[dept] === true;

/** Combined scope (assignments + heads + role defaults). Empty = unrestricted. */
export const departmentScope = (s: Session): Department[] => {
  const scope: Department[] = [...s.assignedDepartments];
  for (const d of Object.keys(s.isHeadOfDepartment)) {
    if (isDepartment(d) && !scope.includes(d)) scope.push(d);
  }
  for (const r of resolvedRoles(s)) {
    if (r.department && !scope.includes(r.department)) scope.push(r.department);
  }
  return scope;
};

/** Departments the user may create records for. Unrestricted when scope is empty. */
export const scopeOptions = (s: Session): Department[] => {
  const scope = departmentScope(s);
  return scope.length === 0 ? [...DEPARTMENTS] : scope;
};

/**
 * Departments a new record in a fixed-department module should be tagged with.
 * Keeps the record inside the creator's scope so they never lose visibility.
 */
export const tagFor = (s: Session, dept: Department): Department[] => {
  const scope = scopeOptions(s);
  return scope.length === 0 || scope.includes(dept) ? [dept] : scope;
};

/**
 * Filters records by the user's department scope. Management / unrestricted
 * sessions see everything. Untagged records are visible to all scoped users.
 */
export const scopedRecords = <T extends { departments?: Department[] }>(
  list: T[],
  s: Session,
): T[] => {
  const scope = departmentScope(s);
  if (scope.length === 0) return list;
  return list.filter(r =>
    !r.departments || r.departments.length === 0 ||
    r.departments.some(d => scope.includes(d)));
};

// ──────────────────────────────────────────────────────────────
// APP ACCOUNTS (mirrors HotelUser + InviteCode on mobile)
// ──────────────────────────────────────────────────────────────

export interface HotelUser {
  userId: string;
  name: string;
  email: string;
  phone: string;
  passwordHash: string;
  roleId: string;
  roleIds: string[];
  assignedDepartments: Department[];
  customPermissions: Permission[];
  isHeadOfDepartment: Record<string, boolean>;
  status: AccountStatus;
  hotelId: string;
  hotelName: string;
  createdAt: string;
  photoUrl?: string;
  preferences?: UserPreferences;
}

export interface InviteCode {
  code: string;
  roleId: string;
  roleName: string;
  departments: Department[];
  isHead: boolean;
  hotelId: string;
  hotelName: string;
  createdAt: string;
  usedByUserId?: string;
  usedAt?: string;
}

export const hashPassword = (pw: string): string =>
  btoa(encodeURIComponent(pw));

export const verifyPassword = (pw: string, hash: string): boolean =>
  hashPassword(pw) === hash;
