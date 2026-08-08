import 'package:flutter/foundation.dart';
import 'dart:ui' show Color;
import '../models/role.dart';
import '../models/user_profile.dart' show UserPreferences;

/// Reactive, additive permission context for the signed-in user.
///
/// Zero-Trust rules:
/// * A fresh install starts as [Session.empty] — NO default admin.
/// * `has()` only ever returns true for an [AccountStatus.active] account,
///   granting the union of all assigned roles plus any custom grants.
/// * Unknown roles never fall back to an admin; they resolve to nothing.
class Session {
  String userId;
  String userName;
  String email;

  /// Additive role ids (e.g. ['front_desk', 'dept_head']).
  List<String> roleIds;

  /// Departments this user is scoped to. Empty = unrestricted (management).
  List<Department> assignedDepartments;

  /// Ad-hoc extra grants that sit on top of the role union.
  Set<Permission> customPermissions;

  /// Heads-of-department flags, e.g. {kitchen: true, laundry: true}.
  Map<Department, bool> isHeadOfDepartment;

  AccountStatus status;
  String? hotelId;
  String hotelName;

  /// Self-service profile fields — mirrored from the `user_roles` doc so
  /// name/phone/avatar/preferences stay uniform across every device.
  String phone;
  String? photoUrl;
  UserPreferences preferences;

  Session({
    required this.userId,
    required this.userName,
    this.email = '',
    this.roleIds = const [],
    this.assignedDepartments = const [],
    this.customPermissions = const {},
    this.isHeadOfDepartment = const {},
    this.status = AccountStatus.pending,
    this.hotelId,
    this.hotelName = '',
    this.phone = '',
    this.photoUrl,
    UserPreferences? preferences,
  }) : preferences = preferences ?? UserPreferences();

  /// Backward-compatible constructor for a single primary role.
  Session.withRole({
    required this.userId,
    required this.userName,
    required AppRole role,
    this.email = '',
    List<Department>? assignedDepartments,
    this.customPermissions = const {},
    this.isHeadOfDepartment = const {},
    this.status = AccountStatus.active,
    this.hotelId,
    this.hotelName = '',
    this.phone = '',
    this.photoUrl,
    UserPreferences? preferences,
  }) : roleIds = [role.id],
       assignedDepartments = assignedDepartments ??
           (role.department != null ? [role.department!] : const []),
       preferences = preferences ?? UserPreferences();

  /// Zero-trust sentinel — no identity, no roles, no permissions.
  factory Session.empty() => Session(
    userId: '',
    userName: '',
    status: AccountStatus.pending,
  );

  bool get hasIdentity => userId.isNotEmpty;
  bool get isAccountActive => hasIdentity && status == AccountStatus.active;
  bool get isSuspended => hasIdentity && status == AccountStatus.suspended;
  bool get isPendingAssignment => hasIdentity && status == AccountStatus.pending;

  /// The first resolvable role (used for display / legacy `department`).
  AppRole? get primaryRole {
    for (final id in roleIds) {
      final role = RoleStore.findRoleById(id);
      if (role != null) return role;
    }
    return null;
  }

  /// Every role this account holds, resolved from the additive `roleIds`.
  List<AppRole> get resolvedRoles =>
      roleIds.map(RoleStore.findRoleById).whereType<AppRole>().toList();

  bool get isManagement =>
      roleIds.contains('super_admin') || roleIds.contains('hotel_manager');

  /// Per-role accent so staff instantly know whose context they are in.
  /// Mirrors `ROLE_ACCENT` in web/lib/rbac.ts — keep in lockstep.
  Color get roleAccent {
    switch (primaryRole?.id) {
      case 'auditor':
        return const Color(0xFF3B82F6);
      case 'front_desk':
        return const Color(0xFF06B6D4);
      case 'accountant':
        return const Color(0xFFF59E0B);
      case 'housekeeping':
        return const Color(0xFF8B5CF6);
      case 'kitchen':
        return const Color(0xFFF43F5E);
      case 'dept_head':
        return const Color(0xFF6366F1);
      case 'events_coordinator':
        return const Color(0xFFEC4899);
      case 'wellness_attendant':
        return const Color(0xFF14B8A6);
      case 'gift_shop_cashier':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF0E9F6E);
    }
  }

  /// Union of every assigned role's permissions.
  Set<Permission> get rolePermissions =>
      resolvedRoles.expand((r) => r.permissions).toSet();

  /// Effective permissions = union(roles) ∪ custom grants.
  Set<Permission> get effectivePermissions =>
      {...rolePermissions, ...customPermissions};

  /// Zero-trust union check. Denies everything for pending/suspended
  /// accounts and for permissions not granted by ANY assigned role.
  bool has(Permission permission) {
    if (!isAccountActive) return false;
    if (customPermissions.contains(permission)) return true;
    return resolvedRoles.any((r) => r.has(permission));
  }

  bool hasAny(Iterable<Permission> permissions) => permissions.any(has);

  bool hasAll(Iterable<Permission> permissions) => permissions.every(has);

  /// Department scoping. Management bypasses scope; everyone else is
  /// restricted to the departments they are assigned to or head.
  bool canAccessDepartment(Department dept) {
    if (!isAccountActive) return false;
    if (isManagement) return true;
    return assignedDepartments.contains(dept) ||
        (isHeadOfDepartment[dept] ?? false);
  }

  /// True when the account carries an explicit department scope.
  bool get hasDepartmentScope =>
      assignedDepartments.isNotEmpty || isHeadOfDepartment.isNotEmpty;

  /// Combined department scope (assignments + heads + role defaults).
  /// Empty list = unrestricted (management-level visibility).
  List<Department> get departmentScope {
    final scope = <Department>{
      ...assignedDepartments,
      ...isHeadOfDepartment.keys,
    };
    for (final role in resolvedRoles) {
      if (role.department != null) scope.add(role.department!);
    }
    return scope.toList();
  }

  /// True when [dept] is a department this user heads.
  bool isHeadOf(Department dept) => isHeadOfDepartment[dept] ?? false;
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
      Permission.viewCompliance,
      Permission.viewFacilities,
      // Internal chat — read only (no send)
      Permission.viewDepartmentChat,
      Permission.viewActivityFeed,
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
      Permission.postRoomCharge,       Permission.viewMultiCurrencyBilling,
      Permission.manageVirtualAccounts, Permission.trackPOSTerminals,
      Permission.manageSplitPayments,
      Permission.viewRooms, Permission.updateRoomStatus,
      Permission.viewInventory,
      Permission.manageKeycards,
      Permission.manageConciergeShuttles, Permission.manageConciergeLuggage,
      Permission.manageConciergeTours, Permission.manageConciergeCarRental,
      // Facilities & Amenities — front desk handles guest amenity inquiries
      Permission.viewFacilities,
      // Pillar 4 — room-service F&B orders at the front desk
      Permission.managePOS, Permission.manageSplitChecks,
      Permission.manageTableManagement,
      // Pillar 5 — WhatsApp
      Permission.manageWhatsApp, Permission.sendAutomatedWhatsApp,
      // Pillar 6 — security audit + shift & compliance
      Permission.viewSecurityAudit,
      Permission.manageShiftHandover, Permission.logCashDrop,
      Permission.captureGuestNIN, Permission.logCashTransactions,
      // Internal chat — department channels + DMs
      Permission.viewDepartmentChat, Permission.sendChatMessage,
      // Cross-pillar
      Permission.viewActivityFeed,
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
      // Internal chat — department channels + DMs
      Permission.viewDepartmentChat, Permission.sendChatMessage,
      // System
      Permission.viewActivityFeed,
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
      // Internal chat — department channels + DMs
      Permission.viewDepartmentChat, Permission.sendChatMessage,
      // Cross-pillar
      Permission.viewActivityFeed,
    },
  );

  static const AppRole kitchen = AppRole(
    id: 'kitchen',
    name: 'Kitchen / Bar',
    department: Department.kitchen,
    permissions: {
      // Pillar 4 — full F&B operations: the floor (tables/bars) plus
      // orders + menu CRUD, alongside KDS confirm/ready and culinary costing.
      Permission.managePOS, Permission.manageTableManagement,
      Permission.manageKDS, Permission.manageRecipeCosting,
      Permission.viewInventory, Permission.manageInventory,
      Permission.trackIngredientShortages,
      Permission.createExpenditure,
      // Internal chat — department channels + DMs
      Permission.viewDepartmentChat, Permission.sendChatMessage,
      // Cross-pillar
      Permission.viewActivityFeed,
    },
  );

  static const AppRole departmentHead = AppRole(
    id: 'dept_head',
    name: 'Department Head',
    permissions: {
      // Their department only — everything here is department-scoped.
      // HODs get hotel-wide views via an additive management/role grant,
      // never from this role alone.
      Permission.viewInventory, Permission.manageInventory,
      Permission.createExpenditure,
      Permission.viewStaff, Permission.manageStaff,
      // Facilities & Amenities — HODs configure their amenities
      Permission.viewFacilities, Permission.manageFacilities,
      // Internal chat — channels + DMs, and broadcast to #hotel-general
      Permission.viewDepartmentChat, Permission.sendChatMessage,
      Permission.manageChat,
      // Cross-pillar
      Permission.viewActivityFeed,
    },
  );

  static const AppRole eventsCoordinator = AppRole(
    id: 'events_coordinator',
    name: 'Events Coordinator / Banqueting',
    department: Department.banqueting,
    permissions: {
      // Pillar 4 — full event & banquet operation
      Permission.manageBanquetingHallRentals, Permission.manageAVEquipment,
      Permission.manageBuffetMenus, Permission.manageSeatingConfig,
      Permission.manageCorporateEvents,
      // Facilities & Amenities — halls + events + amenity revenue
      Permission.viewFacilities, Permission.manageFacilities,
      Permission.manageFacilityAccess,
      // Back office — departmental spends + stock visibility
      Permission.viewInventory, Permission.manageInventory,
      Permission.createExpenditure,
      // Internal chat — banqueting channels + DMs
      Permission.viewDepartmentChat, Permission.sendChatMessage,
      // Cross-pillar
      Permission.viewActivityFeed,
    },
  );

  static const AppRole wellnessAttendant = AppRole(
    id: 'wellness_attendant',
    name: 'Gym / Pool Attendant',
    department: Department.healthSafety,
    permissions: {
      // Facilities & Amenities — sell passes, check-in members
      Permission.viewFacilities, Permission.manageFacilityAccess,
      // Back office — departmental spends
      Permission.viewInventory, Permission.createExpenditure,
      // Internal chat — wellness channels + DMs
      Permission.viewDepartmentChat, Permission.sendChatMessage,
      // Cross-pillar
      Permission.viewActivityFeed,
    },
  );

  static const AppRole giftShopCashier = AppRole(
    id: 'gift_shop_cashier',
    name: 'Gift Shop Cashier',
    department: Department.concierge,
    permissions: {
      // Facilities & Amenities — retail POS + inventory
      Permission.viewFacilities, Permission.manageGiftShop,
      // Back office — retail inventory + departmental spends
      Permission.viewInventory, Permission.manageInventory,
      Permission.createExpenditure,
      // Internal chat — concierge channels + DMs
      Permission.viewDepartmentChat, Permission.sendChatMessage,
      // Cross-pillar
      Permission.viewActivityFeed,
    },
  );

  static List<AppRole> get prebuiltRoles => [
    superAdmin, hotelManager, auditor, frontDesk, accountant,
    housekeeping, kitchen, departmentHead,
    eventsCoordinator, wellnessAttendant, giftShopCashier,
  ];

  static AppRole? findRoleById(String roleId) {
    for (final r in prebuiltRoles) {
      if (r.id == roleId) return r;
    }
    return null;
  }

  // ─────────────────── REACTIVE SESSION ───────────────────
  // Rebuilds the shell, tabs and gates the moment the session changes
  // (promotion, department transfer, suspension, assignment).

  static final ValueNotifier<Session> sessionNotifier =
      ValueNotifier<Session>(Session.empty());

  static Session get current => sessionNotifier.value;

  static void setSession(Session session) => sessionNotifier.value = session;

  /// True when a real identity is signed in (any status).
  static bool get hasSession => current.hasIdentity;

  /// Zero-trust: session is authenticated AND active.
  static bool get isActive => current.isAccountActive;

  static bool has(Permission permission) => current.has(permission);
  static bool hasAny(Iterable<Permission> permissions) =>
      current.hasAny(permissions);

  /// Effective departments this user can operate within (empty = all).
  static List<Department> get departments => current.departmentScope;
  static bool canAccessDepartment(Department dept) =>
      current.canAccessDepartment(dept);

  /// The first role in the additive set, or null (legacy display helper).
  static AppRole? get currentRole => current.primaryRole;
}
