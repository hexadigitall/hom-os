import '../models/role.dart';

class Session {
  String userId;
  String userName;
  AppRole role;
  String? hotelId;

  Session({
    required this.userId,
    required this.userName,
    required this.role,
    this.hotelId,
  });
}

class RoleStore {
  static final AppRole superAdmin = AppRole(
    id: 'super_admin',
    name: 'Super Admin / Owner',
    permissions: Permission.values.toSet(),
  );

  static final AppRole hotelManager = AppRole(
    id: 'hotel_manager',
    name: 'Hotel Manager / GM',
    permissions: Permission.values.toSet(),
  );

  static const AppRole auditor = AppRole(
    id: 'auditor',
    name: 'Auditor / Owner (Read-only)',
    permissions: {
      // Pillar 1 — rooms view only
      Permission.viewBookings, Permission.viewRooms,
      Permission.viewMultiCurrencyBilling,
      // Pillar 3 — engineering view + power cost
      Permission.viewEngineering,
      Permission.viewPowerCostAnalysis,
      // Pillar 5 — back office + financial view only
      Permission.viewBackOffice,
      Permission.viewExpenditure,
      Permission.viewReconciliation,
      Permission.viewFuel, Permission.viewReports,
      Permission.viewRevPAR, Permission.viewNightAudit,
      Permission.viewCompliance, Permission.captureGuestNIN,
    },
  );

  static const AppRole frontDesk = AppRole(
    id: 'front_desk',
    name: 'Front Desk / Reception',
    department: Department.reception,
    permissions: {
      // Pillar 1 — full front office ops
      Permission.viewBookings, Permission.createBooking, Permission.editBooking,
      Permission.checkInGuest, Permission.checkOutGuest, Permission.extendStay,
      Permission.postRoomCharge, Permission.viewMultiCurrencyBilling,
      Permission.manageVirtualAccounts, Permission.trackPOSTerminals,
      Permission.manageSplitPayments,
      Permission.viewRooms, Permission.updateRoomStatus,
      Permission.viewInventory,
      Permission.manageKeycards,
      Permission.manageConciergeShuttles, Permission.manageConciergeLuggage,
      Permission.manageConciergeTours, Permission.manageConciergeCarRental,
      // Pillar 5 — WhatsApp
      Permission.manageWhatsApp, Permission.sendAutomatedWhatsApp,
      // Pillar 6 — security audit + shift & compliance
      Permission.viewSecurityAudit,
      Permission.manageShiftHandover, Permission.logCashDrop,
      Permission.captureGuestNIN, Permission.logCashTransactions,
      // Cross-pillar
      Permission.viewOperations,
    },
  );

  static const AppRole accountant = AppRole(
    id: 'accountant',
    name: 'Accountant / Finance',
    department: Department.accounts,
    permissions: {
      // Pillar 1 — room & booking view
      Permission.viewBookings, Permission.viewRooms,
      Permission.viewMultiCurrencyBilling,
      Permission.autoMatchBankTransfers, Permission.trackPOSTerminals,
      Permission.manageSplitPayments, Permission.parseBankCSV,
      // Pillar 3 — fuel cost view
      Permission.viewFuel, Permission.logFuel,
      Permission.viewPowerCostAnalysis,
      // Pillar 5 — back office + full financial control
      Permission.viewBackOffice,
      Permission.viewExpenditure, Permission.createExpenditure,
      Permission.approveExpenditure,
      Permission.viewReconciliation, Permission.manageReconciliation,
      Permission.viewReports, Permission.viewRevPAR,
      Permission.viewNightAudit, Permission.manageDailyAudit,
      Permission.manageTaxConfig, Permission.manageDualTaxConfig,
      Permission.manageMultiCurrencyAccounting,
      Permission.viewStaff, Permission.runPayroll,
      // Pillar 6 — security audit + audit & compliance
      Permission.viewSecurityAudit,
      Permission.manageShiftHandover, Permission.closeNightAudit,
      Permission.lockTransactions, Permission.logCashDrop,
      Permission.viewCompliance, Permission.manageCompliance,
      Permission.captureGuestNIN, Permission.logCashTransactions,
      Permission.manageLGAHealthPermits,
      Permission.manageFireServiceCertificates,
      // System
      Permission.manageSubscriptions,
    },
  );

  static const AppRole housekeeping = AppRole(
    id: 'housekeeping',
    name: 'Housekeeping',
    department: Department.housekeeping,
    permissions: {
      // Pillar 2 — full housekeeping ops
      Permission.viewHousekeeping,
      Permission.viewRooms, Permission.updateRoomStatus,
      Permission.assignRoomAttendants, Permission.trackMiniBarConsumption,
      Permission.manageLostAndFound, Permission.logLinenDamage,
      Permission.logMinibarLoss,
      Permission.manageLaundry, Permission.manageGuestDryCleaning,
      // Cross-pillar
      Permission.viewOperations,
    },
  );

  static const AppRole kitchen = AppRole(
    id: 'kitchen',
    name: 'Kitchen / Bar',
    department: Department.kitchen,
    permissions: {
      // Pillar 4 — full culinary ops
      Permission.viewInventory, Permission.manageInventory,
      Permission.manageKDS, Permission.manageRecipeCosting,
      Permission.trackIngredientShortages,
      Permission.managePOS, Permission.manageSplitChecks,
      Permission.manageTableManagement,
      Permission.createExpenditure,
      // Cross-pillar
      Permission.viewOperations,
    },
  );

  static const AppRole departmentHead = AppRole(
    id: 'dept_head',
    name: 'Department Head',
    permissions: {
      // Pillar 5 — their dept only
      Permission.viewInventory, Permission.manageInventory,
      Permission.createExpenditure,
      Permission.viewStaff, Permission.manageStaff,
      // Pillar 3 — engineering view
      Permission.viewEngineering,
      // Pillar 5 — back office
      Permission.viewBackOffice,
      // Pillar 6 — security audit
      Permission.viewSecurityAudit,
      // Cross-pillar
      Permission.viewOperations, Permission.viewCompliance,
    },
  );

  static List<AppRole> get prebuiltRoles => [
    superAdmin, hotelManager, auditor, frontDesk, accountant,
    housekeeping, kitchen, departmentHead,
  ];

  static Session _currentSession = Session(
    userId: 'admin_001',
    userName: 'Demo Admin',
    role: superAdmin,
    hotelId: 'hotel_001',
  );

  static Session get current => _currentSession;
  static AppRole get currentRole => _currentSession.role;

  static void setSession(Session session) {
    _currentSession = session;
  }

  static bool has(Permission permission) => currentRole.has(permission);
  static bool hasAny(Iterable<Permission> perms) => currentRole.hasAny(perms);
}
