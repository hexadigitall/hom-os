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

enum Division {
  roomsFrontOfHouse,
  roomsBackOfHouse,
  engineeringPower,
  foodBeverage,
  backOfficeSupplyChain,
  complianceSecurityAudit,
}

enum Department {
  management,
  reception,
  concierge,
  reservations,
  housekeeping,
  laundry,
  engineering,
  restaurants,
  kitchen,
  banqueting,
  procurement,
  accounts,
  humanResources,
  security,
  healthSafety;
}

// ──────────────────────────────────────────────────────────────
// 85+ PERMISSIONS — ORGANISED BY PILLAR
// ──────────────────────────────────────────────────────────────

enum Permission {
  // ========= PILLAR 1: ROOMS (FRONT OF HOUSE) =========
  // Front Office
  viewBookings, createBooking, editBooking, deleteBooking,
  checkInGuest, checkOutGuest, extendStay,
  postRoomCharge, manageGuestProfiles, manageKeycards,
  // Concierge
  manageConciergeShuttles, manageConciergeLuggage,
  manageConciergeTours, manageConciergeCarRental,
  // Reservations & Channel Manager
  manageReservations, manageGroupBookings, manageChannelManager,
  // Multi-Currency & Digital Payments
  viewMultiCurrencyBilling, manageVirtualAccounts,
  autoMatchBankTransfers, trackPOSTerminals, manageSplitPayments,
  parseBankCSV,

  // ========= PILLAR 2: HOUSEKEEPING & ASSETS =========
  viewHousekeeping,
  viewRooms, manageRooms, updateRoomStatus,
  assignRoomAttendants, trackMiniBarConsumption,
  manageLostAndFound, logLinenDamage, logMinibarLoss,
  manageLaundry, manageGuestDryCleaning,

  // ========= PILLAR 3: ENGINEERING & UTILITIES =========
  viewEngineering,
  // Generator & Fuel
  trackGeneratorRunHours, trackFuelDeliveryCycles,
  manageTankCalibration, trackDieselConsumptionRate,
  // Grid & Cost Optimisation
  trackGridTariffUsage, viewPowerCostAnalysis,
  // Water & Facility
  manageWaterTreatment, manageWaterTreatmentChemicals,
  manageBackwashSchedule, manageLifts, manageHVAC,
  managePreventativeMaintenance, viewMaintenanceSchedule,

  // ========= PILLAR 4: F&B & BANQUETING =========
  // POS
  managePOS, manageSplitChecks, manageTableManagement,
  // Kitchen / KDS
  manageKDS, manageRecipeCosting, trackIngredientShortages,
  // Banqueting
  manageBanquetingHallRentals, manageAVEquipment,
  manageBuffetMenus, manageSeatingConfig, manageCorporateEvents,

  // ========= PILLAR 5: BACK OFFICE & SUPPLY CHAIN =========
  viewBackOffice,
  // Procurement
  viewInventory, manageInventory,
  viewVendors, manageVendors, managePurchaseOrders,
  trackBulkFuelDeliveries, manageSupplierContracts,
  // Finance
  viewExpenditure, createExpenditure, approveExpenditure,
  viewReconciliation, manageReconciliation,
  viewFuel, logFuel,
  viewReports, viewRevPAR, viewNightAudit, manageDailyAudit,
  manageTaxConfig, manageDualTaxConfig, manageMultiCurrencyAccounting,
  // HR & Payroll
  viewStaff, manageStaff, runPayroll,
  manageShiftScheduling, manageClockIn, manageCasualWorkers,
  processPAYE, processPension,
  // Operations (cross-pillar)
  viewOperations,
  // Subscriptions, WhatsApp, System
  manageSubscriptions, manageWhatsApp, sendAutomatedWhatsApp,
  sendWhatsAppPayslips, manageUsers,

  // ========= PILLAR 6: COMPLIANCE, SECURITY & AUDIT =========
  viewSecurityAudit,
  // SCUML / EFCC
  manageCompliance, viewCompliance,
  captureGuestNIN, logCashTransactions,
  // Tax & Licences
  manageLGAHealthPermits, manageFireServiceCertificates,
  // Night Audit & Shift Controls
  manageShiftHandover, logCashDrop,
  closeNightAudit, lockTransactions,
  // Security
  manageVisitorPasses, managePatrolCheckpoints, manageIncidentReports,
  // Health & Safety
  manageWaterQualityTests, managePoolChemistry,
  manageFoodSafetyInspections,
}

// ──────────────────────────────────────────────────────────────

extension DepartmentDivision on Department {
  Division get division {
    switch (this) {
      case Department.reception:
      case Department.concierge:
      case Department.reservations:
        return Division.roomsFrontOfHouse;
      case Department.housekeeping:
      case Department.laundry:
        return Division.roomsBackOfHouse;
      case Department.engineering:
        return Division.engineeringPower;
      case Department.restaurants:
      case Department.kitchen:
      case Department.banqueting:
        return Division.foodBeverage;
      case Department.procurement:
      case Department.accounts:
      case Department.humanResources:
        return Division.backOfficeSupplyChain;
      case Department.security:
      case Department.healthSafety:
        return Division.complianceSecurityAudit;
      case Department.management:
        return Division.backOfficeSupplyChain;
    }
  }
}

// ──────────────────────────────────────────────────────────────

class AppRole {
  final String id;
  final String name;
  final Department? department;
  final Set<Permission> permissions;

  const AppRole({
    required this.id,
    required this.name,
    this.department,
    required this.permissions,
  });

  bool has(Permission permission) => permissions.contains(permission);
  bool hasAny(Iterable<Permission> perms) => perms.any((p) => permissions.contains(p));
  bool hasAll(Iterable<Permission> perms) => perms.every((p) => permissions.contains(p));
}
