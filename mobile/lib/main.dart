import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'features/expenditure/expenditure_screen.dart';
import 'features/food_beverage/fnb_screen.dart';
import 'features/feed/feed_screen.dart';
import 'features/reports/report_screen.dart';
import 'features/compliance/compliance_screen.dart';
import 'features/subscriptions/subscriptions_screen.dart';
import 'features/whatsapp/whatsapp_screen.dart';
import 'features/operations/operations_screen.dart';
import 'features/reconciliation/reconciliation_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/engineering/engineering_screen.dart';
import 'features/housekeeping/housekeeping_screen.dart';
import 'features/back_office/back_office_screen.dart';
import 'features/security_audit/security_audit_screen.dart';
import 'features/home/home_dashboard.dart';
import 'features/auth/owner_registration_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/staff_registration_screen.dart';
import 'features/auth/invite_staff_sheet.dart';
import 'features/auth/google_connect_screen.dart';
import 'data/auth_service.dart';
import 'data/compliance_store.dart';
import 'data/back_office_store.dart';
import 'data/engineering_store.dart';
import 'data/expenditure_store.dart';
import 'data/fnb_store.dart';
import 'data/housekeeping_store.dart';
import 'data/security_audit_store.dart';
import 'data/notification_store.dart';
import 'data/operations_store.dart';
import 'data/reconciliation_store.dart';
import 'data/subscription_store.dart';
import 'data/user_store.dart';
import 'data/whatsapp_store.dart';
import 'data/persistence_service.dart';
import 'data/payment_store.dart';
import 'data/feed_store.dart';
import 'utils/theme.dart';
import 'data/profile_store.dart';
import 'data/role_store.dart';
import 'data/update_service.dart';
import 'data/sync_service.dart';
import 'data/store_sync.dart';
import 'models/role.dart';
import 'models/hotel_user.dart';
import 'models/expenditure.dart';
import 'models/fuel.dart';
import 'features/profile/profile_screen.dart';
import 'utils/role_gate.dart';
import 'widgets/hom_widgets.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
const String _tabStateKey = 'last_active_tab';

const Color primaryGreen = AppColors.primary;
const Color darkGreen = AppColors.primaryDark;
const Color inkBlack = AppColors.ink;

void _trace(String s) {
  // ignore: avoid_print
  print('[HOM-BOOT] $s');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _trace('binding initialized');

  if (!kIsWeb) {
    try {
      await Hive.initFlutter();
    } catch (e) {
      _trace('hive init failed: $e');
    }
  }

  // Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _trace('firebase ok');
  } catch (e) {
    _trace('firebase failed: $e');
  }

  // Hive boxes
  await PersistenceService.init();
  _trace('hive hom_data ok');
  await UserStore.init();
  _trace('hive hom_users ok');
  await ProfileStore.init();
  _trace('hive hom_profiles ok');
  try {
    await AuthService.init();
    _trace('auth service ok');
  } catch (e) {
    // Firebase Auth / Google Sign-In are not available on all platforms
    _trace('auth service failed: $e');
  }

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  try {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    _trace('notifications ok');
  } catch (e) {
    _trace('notifications failed: $e');
  }

  try {
    _initDeepLinks();
    _trace('deep links ok');
  } catch (e) {
    _trace('deep links failed: $e');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await HOMData.load();
  _trace('HOMData.load ok');
  HOMData.attach();
  _trace('HOMData.attach ok');
  CloudSync.attach();
  _trace('CloudSync.attach ok');
  await ExpenditureStore.load();
  _trace('ExpenditureStore ok');
  await ComplianceStore.load();
  _trace('ComplianceStore ok');
  await NotificationStore.load();
  _trace('NotificationStore ok');
  await FnbStore.load();
  _trace('FnbStore ok');
  await FeedStore.load();
  _trace('FeedStore ok');
  await EngineeringStore.load();
  _trace('EngineeringStore ok');
  await HousekeepingStore.load();
  _trace('HousekeepingStore ok');
  await BackOfficeStore.load();
  _trace('BackOfficeStore ok');
  await SecurityAuditStore.load();
  _trace('SecurityAuditStore ok');
  await OperationsStore.init();
  _trace('OperationsStore ok');
  await ReconciliationStore.init();
  _trace('ReconciliationStore ok');
  await PaymentStore.init();
  _trace('PaymentStore ok');
  await SubscriptionStore.load();
  _trace('SubscriptionStore ok');
  await WhatsAppStore.init();
  _trace('WhatsAppStore ok');
  _trace('RUNNING APP');
  UpdateService.check();
  Timer.periodic(const Duration(minutes: 30), (_) {
    if (!kIsWeb) UpdateService.check();
  });
  runApp(const HOMApp());
}

void _onNotificationTap(NotificationResponse response) {
  if (response.payload case final payload? when payload.isNotEmpty) {
    final parts = payload.split(':');
    if (parts.length >= 2) {
      final route = parts[0];
      final id = parts.sublist(1).join(':');
      navigatorKey.currentState?.pushNamed('/$route', arguments: id);
    }
  }
}

void _initDeepLinks() {
  final appLinks = AppLinks();
  // Cold start: capture the link before the navigator exists and route once
  // the first frame is up. On web the hash strategy already lands the app on
  // the right route, so this is the fallback for native app links + warm links.
  appLinks.getInitialLink().then((uri) {
    if (uri != null) _handleDeepLink(uri);
  }).catchError((_) {});
  appLinks.uriLinkStream.listen(_handleDeepLink);
}

({String route, Map<String, String> query})? _parseAppLink(Uri uri) {
  // Web uses hash routing:  app.hom.com.ng/#/staff-register?code=XXX
  // Native custom scheme:   hom://staff-register?code=XXX
  var raw = uri.fragment.isNotEmpty ? uri.fragment : uri.path;
  if (raw.startsWith('/')) raw = raw.substring(1);
  if (raw.isEmpty) return null;
  final idx = raw.indexOf('?');
  final path = idx >= 0 ? raw.substring(0, idx) : raw;
  final query = idx >= 0
      ? Uri.splitQueryString(raw.substring(idx + 1))
      : <String, String>{};
  if (path.isEmpty) return null;
  return (route: '/$path', query: query);
}

void _handleDeepLink(Uri uri) {
  final target = _parseAppLink(uri);
  if (target == null) return;
  // Ignore auth deep links when a session already exists so the login,
  // registration and invite screens are never stacked on top of an
  // authenticated shell.
  const ignoredAuthRoutes = {
    '/login',
    '/signin',
    '/register',
    '/staff-register',
    '/google-connect',
  };
  if (ignoredAuthRoutes.contains(target.route) && RoleStore.current.hasIdentity) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    navigatorKey.currentState?.pushNamed(target.route, arguments: target.query);
  });
}

class HOMApp extends StatelessWidget {
  const HOMApp({super.key});

  /// Deep-link URLs arrive with the query in the route name (web hash routing
  /// produces `/staff-register?code=XXX`). The named `routes` map can't match
  /// those, so we parse them here and hand the invite code to the screen.
  static Route<dynamic>? _deepLinkRoute(RouteSettings settings) {
    final name = settings.name;
    if (name == null || !name.contains('?')) return null;
    final uri = Uri.tryParse(name);
    if (uri == null) return null;
    switch (uri.path) {
      case '/staff-register':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => StaffRegistrationScreen(initialCode: uri.queryParameters['code']),
        );
      case '/register':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OwnerRegistrationScreen(),
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HOM',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const AuthGate(),
      routes: {
        '/home': (context) => const HomeShell(),
        '/login': (context) => const LoginScreen(),
        '/signin': (context) => const LoginScreen(),
        '/register': (context) => const OwnerRegistrationScreen(),
        '/staff-register': (context) => StaffRegistrationScreen(
          initialCode: _inviteCodeArg(ModalRoute.of(context)?.settings.arguments),
        ),
        '/google-connect': (context) => const GoogleConnectScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      onGenerateRoute: _deepLinkRoute,
      theme: AppTheme.light,
      builder: (context, child) => SafeArea(
        top: false,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  static String? _inviteCodeArg(Object? args) {
    if (args == null) return null;
    if (args is Map) {
      final value = args['code'];
      return value is String ? value : null;
    }
    return null;
  }
}

// ===================== ZERO-TRUST AUTH GATE =====================
// Every unauthenticated entry point routes through here. A fresh install
// shows owner registration (bootstrap) or login — never an admin shell.

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Session>(
      valueListenable: RoleStore.sessionNotifier,
      builder: (context, session, _) {
        if (!session.hasIdentity) {
          // Signed in to Firebase but not linked to a hotel yet → connect UI.
          if (AuthService.hasUnprovisionedFirebaseUser) {
            return const GoogleConnectScreen();
          }
          // Zero-trust: no session → login (with register + invite links).
          return const LoginScreen();
        }
        switch (session.status) {
          case AccountStatus.pending:
            return const AwaitingAssignmentScreen();
          case AccountStatus.suspended:
            return const SuspendedScreen();
          case AccountStatus.active:
            return const HomeShell();
        }
      },
    );
  }
}

class AwaitingAssignmentScreen extends StatelessWidget {
  const AwaitingAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.hourglass_top_rounded,
                  size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('Awaiting Admin Assignment',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 8),
              Text(
                'Your account is registered but has not been assigned roles or departments yet. '
                'Please contact your hotel administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.grey600),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  await AuthService.logout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class SuspendedScreen extends StatelessWidget {
  const SuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_rounded, size: 56, color: AppColors.red),
              const SizedBox(height: 16),
              const Text('Account Suspended',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 8),
              Text(
                'Your account has been deactivated. Access to HOM is revoked. '
                'Please contact your hotel administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.grey600),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  await AuthService.logout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ===================== SHELL =====================

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  final List<Widget> _tabScreens = [
    const HomeDashboard(),
    BookingsScreen(),
    RoomsScreen(),
    DieselScreen(),
    InventoryScreen(),
    StaffScreen(),
    VendorsScreen(),
    ExpenditureScreen(),
    ReportScreen(),
    ComplianceScreen(),
    SubscriptionsScreen(),
    WhatsAppScreen(),
    OperationsScreen(),
    ReconciliationScreen(),
    FnbScreen(),
    const EngineeringScreen(),
    const HousekeepingScreen(),
    const BackOfficeScreen(),
    const SecurityAuditScreen(),
    const FeedScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tab = _restoreTab();
    // Real-time access sync: promotion, department transfer, suspension and
    // assignment changes rebuild the tab set without an app restart.
    RoleStore.sessionNotifier.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    RoleStore.sessionNotifier.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) return;
    setState(() {
      final visible = _visibleTabs;
      if (visible.isNotEmpty && !visible.any((t) => t.index == _tab)) {
        _tab = visible.first.index;
      }
    });
  }

  int _restoreTab() {
    final saved = PersistenceService.load<int>(_tabStateKey, (v) => v as int);
    if (saved != null && _allTabs.any((t) => t.index == saved)) return saved;
    return 0;
  }

  void _saveTab(int index) {
    PersistenceService.save(_tabStateKey, index);
  }

  // Master tab definitions — screen, label, nav icon, required permission (null = always visible)
  static final List<_TabDef> _allTabs = [
    _TabDef(0, const HomeDashboard(), 'Home', Icons.home_rounded, null),
    _TabDef(1, BookingsScreen(), 'Bookings', Icons.calendar_month_rounded,
        Permission.viewBookings),
    _TabDef(2, RoomsScreen(), 'Rooms', Icons.bed_rounded, Permission.viewRooms),
    _TabDef(3, DieselScreen(), 'Fuel', Icons.local_gas_station_rounded,
        Permission.viewFuel),
    _TabDef(4, InventoryScreen(), 'Inventory', Icons.inventory_2_rounded,
        Permission.viewInventory),
    _TabDef(
        5, StaffScreen(), 'Staff', Icons.people_rounded, Permission.viewStaff),
    _TabDef(6, VendorsScreen(), 'Vendors', Icons.store_rounded,
        Permission.viewVendors),
    _TabDef(7, ExpenditureScreen(), 'Expenses', Icons.receipt_long_rounded,
        Permission.viewExpenditure),
    _TabDef(8, ReportScreen(), 'Reports', Icons.bar_chart_rounded,
        Permission.viewReports),
    _TabDef(9, ComplianceScreen(), 'Compliance', Icons.verified_rounded,
        Permission.viewCompliance),
    _TabDef(10, SubscriptionsScreen(), 'Subscriptions',
        Icons.subscriptions_rounded, Permission.manageSubscriptions),
    _TabDef(11, WhatsAppScreen(), 'WhatsApp', Icons.chat_rounded,
        Permission.manageWhatsApp),
    _TabDef(12, OperationsScreen(), 'Operations', Icons.dashboard_rounded,
        Permission.viewOperations, [
      Permission.viewOperations,
      Permission.viewRevPAR,
      Permission.viewNightAudit,
      Permission.viewHousekeeping,
    ]),
    _TabDef(13, ReconciliationScreen(), 'Reconciliation',
        Icons.compare_arrows_rounded, Permission.viewReconciliation),
    _TabDef(
        14, FnbScreen(), 'F&B', Icons.restaurant_rounded, Permission.managePOS,
        [Permission.managePOS, Permission.manageKDS]),
    _TabDef(15, const EngineeringScreen(), 'Engineering',
        Icons.precision_manufacturing_rounded, Permission.viewEngineering),
    _TabDef(16, const HousekeepingScreen(), 'Housekeeping',
        Icons.cleaning_services_rounded, Permission.viewHousekeeping),
    _TabDef(17, const BackOfficeScreen(), 'Back Office',
        Icons.account_balance_rounded, Permission.viewBackOffice),
    _TabDef(18, const SecurityAuditScreen(), 'Security & Audit',
        Icons.security_rounded, Permission.viewSecurityAudit),
    _TabDef(19, const FeedScreen(), 'Activity', Icons.rss_feed_rounded,
        Permission.viewActivityFeed),
  ];

  // Tabs the current role can see
  List<_TabDef> get _visibleTabs => _allTabs.where((t) {
        if (t.anyOf != null) return RoleStore.hasAny(t.anyOf!);
        return t.permission == null || RoleStore.has(t.permission!);
      }).toList();

  // Tabs eligible for bottom nav (first 4 that are visible)
  List<_TabDef> get _navTabs =>
      _visibleTabs.where((t) => t.index <= 4).toList();

  // The rest go in the More sheet
  List<_TabDef> get _moreTabs =>
      _visibleTabs.where((t) => t.index > 4).toList();

  // Clamp tab to valid range
  void _goToTab(int index) {
    final visible = _visibleTabs;
    if (visible.any((t) => t.index == index)) {
      setState(() {
        _tab = index;
        _saveTab(index);
      });
    } else if (visible.isNotEmpty) {
      setState(() {
        _tab = visible.first.index;
        _saveTab(visible.first.index);
      });
    }
  }

  String get _currentLabel {
    final found = _allTabs.where((t) => t.index == _tab);
    return found.isNotEmpty ? found.first.label : 'Overview';
  }

  // Full contextual header title for the active tab. Feature screens use
  // their short label in the shell nav, so expand the header back to the
  // complete feature name.
  String get _fullHeaderLabel {
    switch (_currentLabel) {
      case 'Reconciliation':
        return 'Payments & Reconciliation';
      case 'Back Office':
        return 'Back Office & Supply Chain';
      case 'Engineering':
        return 'Engineering & Power';
      case 'Housekeeping':
        return 'Housekeeping & Assets';
      case 'F&B':
        return 'F&B Operations';
      case 'Activity':
        return 'Activity Feed';
      case 'Expenses':
        return 'Expenditure';
      default:
        return _currentLabel;
    }
  }

  // Ultra-narrow fallback: drop modifiers rather than truncate mid-word.
  String get _abbrevHeaderLabel {
    switch (_fullHeaderLabel) {
      case 'Payments & Reconciliation':
        return 'Reconciliation';
      case 'Back Office & Supply Chain':
        return 'Back Office';
      case 'Engineering & Power':
        return 'Engineering';
      case 'Housekeeping & Assets':
        return 'Housekeeping';
      default:
        return _fullHeaderLabel;
    }
  }

  // Role identity badge in the header. Owner and Hotel Manager both hold
  // full access, so they are told apart by label + colour rather than by
  // the (identical) footer menu.
  String get _roleBadgeLabel {
    final ids = RoleStore.current.roleIds;
    if (ids.contains('super_admin')) return 'Owner';
    if (ids.contains('hotel_manager')) return 'Manager';
    return 'Staff';
  }

  Widget _headerProfileBtn() => IconButton(
        onPressed: () {
          final currentRoute = ModalRoute.of(context)?.settings.name;
          if (currentRoute != '/profile') {
            Navigator.pushNamed(context, '/profile');
          }
        },
        icon: const Icon(Icons.person_outline_rounded, size: 22),
        constraints: const BoxConstraints(),
      );

  Widget _headerBell(int unread) => Stack(clipBehavior: Clip.none, children: [
        IconButton(
            onPressed: _showNotifications,
            icon: const Icon(Icons.notifications_outlined, size: 22),
            constraints: const BoxConstraints()),
        if (unread > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: AppColors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text('$unread',
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center),
            ),
          ),
      ]);

  Widget _headerRoleBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: RoleStore.current.roleAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20)),
        child: Text(_roleBadgeLabel,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: RoleStore.current.roleAccent)),
      );

  Widget _headerLiveBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20)),
        child: const Text('LIVE',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, color: primaryGreen)),
      );

  // Adaptive shell header: single row on wide viewports, two-level stack
  // (brand + full-width title above, badges/actions below) on narrow phones.
  Widget _headerTitle(int unread) {
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width <= 400;
    final label = width < 340 ? _abbrevHeaderLabel : _fullHeaderLabel;
    final logo = Image.asset('assets/logo/logo.png',
        height: isNarrow ? 24 : 26,
        errorBuilder: (c, e, s) => const SizedBox.shrink());
    const titleStyle =
        TextStyle(fontWeight: FontWeight.w800, fontSize: 18);

    if (!isNarrow) {
      return Row(children: [
        logo,
        const SizedBox(width: 10),
        Flexible(
            child: Text(label,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: titleStyle)),
        const Spacer(),
        _headerProfileBtn(),
        _headerBell(unread),
        const SizedBox(width: 4),
        _headerRoleBadge(),
        const SizedBox(width: 4),
        _headerLiveBadge(),
      ]);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          logo,
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          _headerRoleBadge(),
          const SizedBox(width: 4),
          _headerLiveBadge(),
          const Spacer(),
          _headerBell(unread),
          _headerProfileBtn(),
        ]),
      ],
    );
  }

  void _showMoreSheet() {
    final items = _moreTabs;
    if (items.isEmpty) return;
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    if (isWide) {
      // Desktop/tablet: centered dialog with a wider adaptive grid.
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 660,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.72,
            ),
            child: SafeArea(child: _moreSheetContent(ctx, items, isWide: true)),
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) =>
          SafeArea(child: _moreSheetContent(ctx, items, isWide: false)),
    );
  }

  Widget _moreSheetContent(BuildContext ctx, List<_TabDef> items,
      {required bool isWide}) {
    final accent = RoleStore.current.roleAccent;
    final size = MediaQuery.sizeOf(ctx);
    final width = size.width;
    final columns = isWide
        ? (width >= 1100 ? 8 : (width >= 800 ? 6 : 5))
        : (width >= 420 ? 4 : 3);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: isWide ? 48 : 36,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('All Features',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 16),
        ConstrainedBox(
          // Cap the grid height so the sheet never overflows in landscape.
          constraints: BoxConstraints(maxHeight: size.height * 0.55),
          child: GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
            children: items
                .map((item) => GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _goToTab(item.index);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _tab == item.index
                              ? accent.withValues(alpha: 0.1)
                              : AppColors.grey50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: _tab == item.index
                                  ? accent.withValues(alpha: 0.3)
                                  : AppColors.grey200),
                        ),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item.icon,
                                  color: _tab == item.index
                                      ? accent
                                      : AppColors.grey700,
                                  size: isWide ? 24 : 26),
                              const SizedBox(height: 6),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(item.label,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _tab == item.index
                                            ? accent
                                            : AppColors.grey800),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                      ),
                    ))
                .toList(),
          ),
        ),
      ]),
    );
  }

  void _showNotifications() {
    Navigator.push(
            context, MaterialPageRoute(builder: (_) => NotificationsScreen()))
        .then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    // Zero-trust guard: revoked/pending accounts never see the shell.
    final session = RoleStore.current;
    if (session.isSuspended) return const SuspendedScreen();
    if (session.isPendingAssignment) return const AwaitingAssignmentScreen();
    if (!session.hasIdentity) return const LoginScreen();

    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 600;
    final unread = NotificationStore.unreadCount;
    final navTabs = _navTabs;
    final navCount = navTabs.length;
    final navIndices = navTabs.map((t) => t.index).toList();
    final navSel = navIndices.indexOf(_tab);
    final hasAnyNav = navCount > 0 || _moreTabs.isNotEmpty;

    final content = PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _tab != 0) {
          _goToTab(0);
        }
      },
      child: IndexedStack(
        index: _tab,
        children: _tabScreens,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: MediaQuery.sizeOf(context).width <= 400 ? 88 : null,
        title: _headerTitle(unread),
      ),
      body: Column(
        children: [
          if (!kIsWeb) const _UpdateBanner(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isWide && hasAnyNav)
                  NavigationRail(
                    selectedIndex: navSel >= 0 ? navSel : navCount,
                    onDestinationSelected: (i) {
                      if (i < navCount) {
                        _goToTab(navIndices[i]);
                      } else {
                        _showMoreSheet();
                      }
                    },
                    // Icon+text where it fits; icons-only where it would be squeezed.
                    // On short (landscape) viewports labels risk vertical overflow,
                    // so fall back to icons-only whenever the available height is tight.
                    extended: size.width >= 900,
                    labelType: size.width >= 900
                        ? null
                        : (size.height >= 480
                            ? NavigationRailLabelType.all
                            : NavigationRailLabelType.none),
                    groupAlignment: -0.95,
                    backgroundColor: AppColors.grey50,
                    selectedIconTheme: IconThemeData(
                        color: RoleStore.current.roleAccent),
                    unselectedIconTheme:
                        const IconThemeData(color: AppColors.grey600),
                    selectedLabelTextStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: RoleStore.current.roleAccent),
                    unselectedLabelTextStyle:
                        const TextStyle(color: AppColors.grey600),
                    destinations: [
                      for (final t in navTabs)
                        NavigationRailDestination(
                            icon: Icon(t.icon), label: Text(t.label)),
                      if (_moreTabs.isNotEmpty)
                        const NavigationRailDestination(
                            icon: Icon(Icons.grid_view_rounded),
                            label: Text('More')),
                    ],
                  ),
                Expanded(child: content),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isWide && hasAnyNav
          ? NavigationBar(
              selectedIndex: navSel >= 0 ? navSel : navCount,
              onDestinationSelected: (i) {
                if (i < navCount) {
                  _goToTab(navIndices[i]);
                } else {
                  _showMoreSheet();
                }
              },
              labelBehavior: size.width > 360
                  ? NavigationDestinationLabelBehavior.alwaysShow
                  : NavigationDestinationLabelBehavior.alwaysHide,
              destinations: [
                for (final t in navTabs)
                  NavigationDestination(
                      icon: Icon(t.icon, size: 22), label: t.label),
                if (_moreTabs.isNotEmpty)
                  const NavigationDestination(
                      icon: Icon(Icons.grid_view_rounded, size: 22),
                      label: 'More'),
              ],
            )
          : null,
    );
  }
}

class _UpdateBanner extends StatefulWidget {
  const _UpdateBanner();

  @override
  State<_UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<_UpdateBanner> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) UpdateService.onResumed();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UpdateInfo?>(
      valueListenable: UpdateService.status,
      builder: (context, info, _) {
        if (info == null) return const SizedBox.shrink();
        return ValueListenableBuilder<UpdateProgress>(
          valueListenable: UpdateService.progress,
          builder: (context, p, _) {
            return Material(
              color: AppColors.primary,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.system_update_alt_rounded,
                          color: AppColors.white, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p.phase == UpdatePhase.idle ||
                                      p.phase == UpdatePhase.error
                                  ? 'HOM ${info.latestTag} is available'
                                  : p.message,
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (p.phase == UpdatePhase.downloading)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: p.fraction,
                                    minHeight: 4,
                                    backgroundColor:
                                        AppColors.white.withValues(alpha: 0.2),
                                    valueColor: const AlwaysStoppedAnimation(
                                        AppColors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (p.phase == UpdatePhase.idle)
                        TextButton(
                          onPressed: () => UpdateService.downloadAndInstall(info),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.white,
                            backgroundColor:
                                AppColors.white.withValues(alpha: 0.15),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                          ),
                          child: const Text('Update'),
                        )
                      else if (p.phase == UpdatePhase.downloading ||
                          p.phase == UpdatePhase.verifying ||
                          p.phase == UpdatePhase.installing)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          ),
                        )
                      else if (p.phase == UpdatePhase.error)
                        TextButton(
                          onPressed: () =>
                              UpdateService.downloadAndInstall(info),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.white,
                            backgroundColor:
                                AppColors.white.withValues(alpha: 0.15),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                          ),
                          child: const Text('Retry'),
                        )
                      else
                        const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TabDef {
  final int index;
  final Widget screen;
  final String label;
  final IconData icon;
  final Permission? permission;
  final List<Permission>? anyOf;
  const _TabDef(
      this.index, this.screen, this.label, this.icon, this.permission,
      [this.anyOf]);
}

// ===================== MODELS =====================

class Room {
  String id, number, type, status;
  int price;
  Room(
      {required this.id,
      required this.number,
      required this.type,
      required this.status,
      required this.price});

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'type': type,
        'status': status,
        'price': price
      };
  factory Room.fromJson(Map<String, dynamic> j) => Room(
      id: j['id'],
      number: j['number'],
      type: j['type'],
      status: j['status'],
      price: j['price']);
}

class Booking {
  String id, guest, phone, room, checkin, checkout, status;
  int amount;
  Booking(
      {required this.id,
      required this.guest,
      required this.phone,
      required this.room,
      required this.checkin,
      required this.checkout,
      required this.status,
      required this.amount});

  Map<String, dynamic> toJson() => {
        'id': id,
        'guest': guest,
        'phone': phone,
        'room': room,
        'checkin': checkin,
        'checkout': checkout,
        'status': status,
        'amount': amount
      };
  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
      id: j['id'],
      guest: j['guest'],
      phone: j['phone'],
      room: j['room'],
      checkin: j['checkin'],
      checkout: j['checkout'],
      status: j['status'],
      amount: j['amount']);
}

class InventoryItem {
  String id, name;
  int qty, low, cost;
  InventoryItem(
      {required this.id,
      required this.name,
      required this.qty,
      required this.low,
      required this.cost});

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'qty': qty, 'low': low, 'cost': cost};
  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
      id: j['id'],
      name: j['name'],
      qty: j['qty'],
      low: j['low'],
      cost: j['cost']);
}

class StaffMember {
  String id, name, role, phone;
  int salary;
  StaffMember(
      {required this.id,
      required this.name,
      required this.role,
      required this.phone,
      required this.salary});

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'role': role, 'phone': phone, 'salary': salary};
  factory StaffMember.fromJson(Map<String, dynamic> j) => StaffMember(
      id: j['id'],
      name: j['name'],
      role: j['role'],
      phone: j['phone'],
      salary: j['salary']);
}

class Vendor {
  String id, name, contact, category;
  Vendor(
      {required this.id,
      required this.name,
      required this.contact,
      required this.category});

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'contact': contact, 'category': category};
  factory Vendor.fromJson(Map<String, dynamic> j) => Vendor(
      id: j['id'],
      name: j['name'],
      contact: j['contact'],
      category: j['category']);
}

class PurchaseOrder {
  String id, vendorId, items, date, status;
  int amount;
  PurchaseOrder(
      {required this.id,
      required this.vendorId,
      required this.items,
      required this.amount,
      required this.date,
      required this.status});

  Map<String, dynamic> toJson() => {
        'id': id,
        'vendorId': vendorId,
        'items': items,
        'amount': amount,
        'date': date,
        'status': status
      };
  factory PurchaseOrder.fromJson(Map<String, dynamic> j) => PurchaseOrder(
      id: j['id'],
      vendorId: j['vendorId'],
      items: j['items'],
      amount: j['amount'],
      date: j['date'],
      status: j['status']);
}

String _uid() => DateTime.now().millisecondsSinceEpoch.toRadixString(36);
String _today() => DateTime.now().toIso8601String().substring(0, 10);

// ===================== SHARED DATA =====================

class HOMData {
  static final rooms = <Room>[
    Room(
        id: 'r1',
        number: '101',
        type: 'Deluxe',
        status: 'available',
        price: 25000),
    Room(
        id: 'r2',
        number: '102',
        type: 'Deluxe',
        status: 'occupied',
        price: 25000),
    Room(
        id: 'r3',
        number: '103',
        type: 'Standard',
        status: 'available',
        price: 15000),
    Room(
        id: 'r4',
        number: '201',
        type: 'Executive',
        status: 'maintenance',
        price: 40000),
    Room(
        id: 'r5',
        number: '202',
        type: 'Executive',
        status: 'available',
        price: 40000),
  ];
  static final bookings = <Booking>[
    Booking(
        id: 'b1',
        guest: 'John Doe',
        phone: '08031234567',
        room: '102',
        checkin: '2026-07-27',
        checkout: '2026-07-29',
        status: 'checked-in',
        amount: 50000),
  ];
  static final fuelLogs = <FuelLog>[
    FuelLog(
        id: 'fl1',
        date: DateTime(2026, 7, 26),
        fuelType: FuelType.diesel,
        quantity: 200,
        cost: 240000,
        supplier: 'MRS PH',
        usageHours: 12,
        note: 'Main generator'),
    FuelLog(
        id: 'fl2',
        date: DateTime(2026, 7, 27),
        fuelType: FuelType.petrol,
        quantity: 25,
        cost: 30000,
        supplier: 'Total Energies',
        usageHours: 3,
        note: 'Office backup gen'),
    FuelLog(
        id: 'fl3',
        date: DateTime(2026, 7, 25),
        fuelType: FuelType.lpg,
        quantity: 50,
        cost: 45000,
        supplier: 'GasCo Ltd',
        usageHours: 8,
        note: 'Kitchen supply'),
    FuelLog(
        id: 'fl4',
        date: DateTime(2026, 7, 24),
        fuelType: FuelType.charcoal,
        quantity: 20,
        cost: 8000,
        supplier: 'Local supplier',
        note: 'Suya grill weekend'),
    FuelLog(
        id: 'fl5',
        date: DateTime(2026, 7, 27),
        fuelType: FuelType.grid,
        quantity: 480,
        cost: 72000,
        supplier: 'PHED',
        usageHours: 8,
        note: 'Peak hours supplement'),
  ];
  static final inventory = <InventoryItem>[
    InventoryItem(id: 'i1', name: 'Tissue Roll', qty: 50, low: 10, cost: 500),
    InventoryItem(id: 'i2', name: 'Bottled Water', qty: 8, low: 20, cost: 200),
    InventoryItem(id: 'i3', name: 'Towel Set', qty: 30, low: 10, cost: 2500),
  ];
  static final staff = <StaffMember>[
    StaffMember(
        id: 's1',
        name: 'Amina Yusuf',
        role: 'Front Desk',
        phone: '08031234501',
        salary: 120000),
    StaffMember(
        id: 's2',
        name: 'Chidi Okonkwo',
        role: 'Cleaner',
        phone: '08031234502',
        salary: 70000),
    StaffMember(
        id: 's3',
        name: 'Blessing Eze',
        role: 'Manager',
        phone: '08031234503',
        salary: 200000),
  ];
  static final vendors = <Vendor>[
    Vendor(
        id: 'v1',
        name: 'MRS Petroleum',
        contact: '0801-234-5678',
        category: 'Fuel'),
    Vendor(
        id: 'v2',
        name: 'CleanPro Supplies',
        contact: '0809-876-5432',
        category: 'Cleaning'),
  ];
  static final purchaseOrders = <PurchaseOrder>[
    PurchaseOrder(
        id: 'po1',
        vendorId: 'v1',
        items: 'Diesel 500L',
        amount: 600000,
        date: '2026-07-25',
        status: 'delivered'),
  ];
  static int paye(int s) => (s * 0.07).round();
  static int pension(int s) => (s * 0.08).round();
  static int netPay(int s) => s - paye(s) - pension(s);

  static Future<void> load() async {
    final r = PersistenceService.loadList('hom_rooms', Room.fromJson);
    if (r != null) {
      rooms.clear();
      rooms.addAll(r);
    }
    final b = PersistenceService.loadList('hom_bookings', Booking.fromJson);
    if (b != null) {
      bookings.clear();
      bookings.addAll(b);
    }
    final f = PersistenceService.loadList('hom_fuel_logs', FuelLog.fromJson);
    if (f != null) {
      fuelLogs.clear();
      fuelLogs.addAll(f);
    }
    final i =
        PersistenceService.loadList('hom_inventory', InventoryItem.fromJson);
    if (i != null) {
      inventory.clear();
      inventory.addAll(i);
    }
    final s = PersistenceService.loadList('hom_staff', StaffMember.fromJson);
    if (s != null) {
      staff.clear();
      staff.addAll(s);
    }
    final v = PersistenceService.loadList('hom_vendors', Vendor.fromJson);
    if (v != null) {
      vendors.clear();
      vendors.addAll(v);
    }
    final po = PersistenceService.loadList(
        'hom_purchase_orders', PurchaseOrder.fromJson);
    if (po != null) {
      purchaseOrders.clear();
      purchaseOrders.addAll(po);
    }
  }

  static Future<void> save() async {
    await PersistenceService.saveList('hom_rooms', rooms, (e) => e.toJson());
    await PersistenceService.saveList(
        'hom_bookings', bookings, (e) => e.toJson());
    await PersistenceService.saveList(
        'hom_fuel_logs', fuelLogs, (e) => e.toJson());
    await PersistenceService.saveList(
        'hom_inventory', inventory, (e) => e.toJson());
    await PersistenceService.saveList('hom_staff', staff, (e) => e.toJson());
    await PersistenceService.saveList(
        'hom_vendors', vendors, (e) => e.toJson());
    await PersistenceService.saveList(
        'hom_purchase_orders', purchaseOrders, (e) => e.toJson());
    await _syncNow();
  }

  // ===================== CLOUD SYNC =====================
  // Firestore is the master for these collections once a session is active;
  // the Hive lists stay as offline caches + live UI state. The sync follows
  // the session's hotel id (identity remains server-authoritative) and
  // Firestore's local persistence queues any write made while offline, so the
  // next reconnection syncs it automatically.
  // NOTE: local caches are stored under their own keys (e.g. `hom_fuel_logs`);
  // the Firestore collection names are the canonical `fuel_logs` etc.

  static final List<StreamSubscription<List<Map<String, dynamic>>>> _syncSubs =
      [];
  static String? _syncHotelId;
  static final Map<String, Map<String, dynamic>> _metas = {};

  /// Follows the session: subscribe to the cloud collections when a hotel is
  /// active, cancel when signed out or the hotel changes.
  static void attach() {
    RoleStore.sessionNotifier.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  static void _onSessionChanged() {
    final hotel = RoleStore.current.hotelId;
    if (hotel == null || hotel.isEmpty) {
      for (final s in _syncSubs) {
        s.cancel();
      }
      _syncSubs.clear();
      _syncHotelId = null;
      return;
    }
    if (_syncHotelId == hotel) return;
    _syncHotelId = hotel;
    _startSync();
  }

  static Future<void> _startSync() async {
    try {
      // One-time backfill: when a cloud collection is empty, push the local
      // data so Firestore becomes the master copy for this hotel.
      await Future.wait([
        _backfill('rooms', rooms, (e) => e.toJson()),
        _backfill('bookings', bookings, (e) => e.toJson()),
        _backfill('inventory', inventory, (e) => e.toJson()),
        _backfill('staff', staff, (e) => e.toJson()),
        _backfill('vendors', vendors, (e) => e.toJson()),
        _backfill('purchase_orders', purchaseOrders, (e) => e.toJson()),
        _backfill('fuel_logs', fuelLogs, (e) => e.toJson()),
      ]);
      for (final s in _syncSubs) {
        s.cancel();
      }
      _syncSubs.clear();
      _syncSubs.addAll([
        _listen('rooms', rooms, Room.fromJson, (e) => e.toJson(), 'hom_rooms'),
        _listen('bookings', bookings, Booking.fromJson, (e) => e.toJson(), 'hom_bookings'),
        _listen('inventory', inventory, InventoryItem.fromJson, (e) => e.toJson(), 'hom_inventory'),
        _listen('staff', staff, StaffMember.fromJson, (e) => e.toJson(), 'hom_staff'),
        _listen('vendors', vendors, Vendor.fromJson, (e) => e.toJson(), 'hom_vendors'),
        _listen('purchase_orders', purchaseOrders, PurchaseOrder.fromJson, (e) => e.toJson(), 'hom_purchase_orders'),
        _listen('fuel_logs', fuelLogs, FuelLog.fromJson, (e) => e.toJson(), 'hom_fuel_logs'),
      ]);
    } catch (_) {
      // No network / not provisioned — stay local-only for this run.
    }
  }

  static Future<void> _backfill<T>(String cloud, List<T> target,
      Map<String, dynamic> Function(T) toJson) async {
    try {
      final pushed = await SyncService.backfill(cloud, target.map(toJson).toList());
      _metas[cloud] = pushed;
      PersistenceService.save('hom_sync_meta_$cloud', pushed);
    } catch (_) {}
  }

  static StreamSubscription<List<Map<String, dynamic>>> _listen<T>(
    String cloud,
    List<T> target,
    T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> Function(T) toJson,
    String cacheKey,
  ) {
    return SyncService.watch(cloud).listen((docs) {
      final sorted = List<Map<String, dynamic>>.of(docs)
        ..sort((a, b) => _docTime(b).compareTo(_docTime(a)));
      final cloudItems = <T>[];
      for (final d in sorted) {
        try {
          cloudItems.add(fromJson(d));
        } catch (_) {/* skip malformed docs */}
      }
      final cloudIds = cloudItems.map((e) => (e as dynamic).id as String).toSet();
      // Cloud is authoritative; keep local-only items (pending offline writes)
      // visible until they reach the cloud.
      final localOnly =
          target.where((e) => !cloudIds.contains((e as dynamic).id)).toList();
      target
        ..clear()
        ..addAll([...cloudItems, ...localOnly]);
      PersistenceService.saveList(cacheKey, target, toJson);
    });
  }

  static Future<void> _syncNow() async {
    if (!SyncService.enabled) return;
    await Future.wait([
      _push('rooms', rooms, (e) => e.toJson()),
      _push('bookings', bookings, (e) => e.toJson()),
      _push('inventory', inventory, (e) => e.toJson()),
      _push('staff', staff, (e) => e.toJson()),
      _push('vendors', vendors, (e) => e.toJson()),
      _push('purchase_orders', purchaseOrders, (e) => e.toJson()),
      _push('fuel_logs', fuelLogs, (e) => e.toJson()),
    ]);
  }

  static Future<void> _push<T>(String cloud, List<T> target,
      Map<String, dynamic> Function(T) toJson) async {
    try {
      final next =
          await SyncService.pushDiff(cloud, target.map(toJson).toList(), _meta(cloud));
      _metas[cloud] = next;
      PersistenceService.save('hom_sync_meta_$cloud', next);
    } catch (_) {/* offline — the write is queued by Firestore */}
  }

  static Map<String, dynamic> _meta(String cloud) =>
      _metas[cloud] ??=
          PersistenceService.load<Map<String, dynamic>>(
                  'hom_sync_meta_$cloud', (v) => Map<String, dynamic>.from(v as Map)) ??
              const {};

  static DateTime _docTime(Map<String, dynamic> d) {
    final t = d['createdAt'];
    if (t is Timestamp) return t.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

// ===================== HELPERS =====================

Widget _sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          overflow: TextOverflow.ellipsis),
    );

Widget _statusChip(String s) {
  Color c;
  switch (s) {
    case 'checked-in':
    case 'available':
    case 'approved':
    case 'delivered':
      c = primaryGreen;
      break;
    case 'cancelled':
    case 'maintenance':
      c = AppColors.red;
      break;
    default:
      c = AppColors.blue;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20)),
    child: Text(s,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
  );
}

Future<void> _sendWhatsApp(
    BuildContext context, String rawPhone, String message) async {
  final cleaned = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
  final phone = cleaned.startsWith('0')
      ? '+234${cleaned.substring(1)}'
      : cleaned.startsWith('+')
          ? cleaned
          : '+234$cleaned';
  final text = Uri.encodeComponent(message);
  final uri = Uri.parse('https://wa.me/$phone?text=$text');
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Could not open WhatsApp. Please ensure WhatsApp is installed.'),
            backgroundColor: AppColors.red),
      );
    }
  }
}

void _showForm(BuildContext context, String title, List<Widget> fields,
    VoidCallback onSave) {
  final spaced = <Widget>[];
  for (int i = 0; i < fields.length; i++) {
    if (i > 0) spaced.add(const SizedBox(height: 12));
    spaced.add(fields[i]);
  }
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.grey300,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 16),
                ...spaced,
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                      child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(
                      flex: 2,
                      child: ElevatedButton(
                          onPressed: () {
                            onSave();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Save'))),
                ]),
              ]),
        ),
      ),
    ),
  );
}

// ===================== BOOKINGS =====================

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  void _add() {
    final guest = TextEditingController(),
        phone = TextEditingController(),
        checkin = TextEditingController(text: _today()),
        checkout = TextEditingController(text: _today());
    String room = HOMData.rooms
        .firstWhere((r) => r.status == 'available',
            orElse: () => HOMData.rooms.first)
        .number;
    _showForm(context, 'New Booking', [
      TextField(
          controller: guest,
          decoration: const InputDecoration(labelText: 'Guest name')),
      TextField(
          controller: phone,
          decoration: const InputDecoration(labelText: 'Phone')),
      StatefulBuilder(
          builder: (ctx, setSB) => DropdownButtonFormField<String>(
                initialValue: room,
                items: HOMData.rooms
                    .where((r) => r.status == 'available')
                    .map((r) => DropdownMenuItem(
                        value: r.number,
                        child: Text('${r.number} — ₦${r.price}')))
                    .toList(),
                onChanged: (v) => setSB(() => room = v!),
                decoration: const InputDecoration(labelText: 'Room'),
              )),
      TextField(
          controller: checkin,
          decoration: const InputDecoration(labelText: 'Check-in')),
      TextField(
          controller: checkout,
          decoration: const InputDecoration(labelText: 'Check-out')),
    ], () {
      if (guest.text.isEmpty) return;
      final r = HOMData.rooms.firstWhere((rr) => rr.number == room);
      final booking = Booking(
        id: _uid(),
        guest: guest.text,
        phone: phone.text,
        room: room,
        checkin: checkin.text,
        checkout: checkout.text,
        status: 'confirmed',
        amount: r.price,
      );
      HOMData.bookings.insert(0, booking);
      r.status = 'occupied';
      setState(() {});
      HOMData.save();
      FeedStore.log(
        dept: 'reception',
        action: 'booking.created',
        message: 'New booking — ${booking.guest} in Room ${booking.room}',
        refId: booking.id,
      );
    });
  }

  void _edit(Booking b) {
    final guest = TextEditingController(text: b.guest),
        phone = TextEditingController(text: b.phone),
        checkin = TextEditingController(text: b.checkin),
        checkout = TextEditingController(text: b.checkout),
        amount = TextEditingController(text: b.amount.toString());
    String room = b.room;
    _showForm(context, 'Edit Booking', [
      TextField(
          controller: guest,
          decoration: const InputDecoration(labelText: 'Guest')),
      TextField(
          controller: phone,
          decoration: const InputDecoration(labelText: 'Phone')),
      StatefulBuilder(
          builder: (ctx, setSB) => DropdownButtonFormField<String>(
                initialValue: room,
                items: HOMData.rooms
                    .map((r) => DropdownMenuItem(
                        value: r.number,
                        child: Text('${r.number} • ${r.type}')))
                    .toList(),
                onChanged: (v) => setSB(() => room = v!),
                decoration: const InputDecoration(labelText: 'Room'),
              )),
      TextField(
          controller: checkin,
          decoration:
              const InputDecoration(labelText: 'Check-in (yyyy-mm-dd)')),
      TextField(
          controller: checkout,
          decoration:
              const InputDecoration(labelText: 'Check-out (yyyy-mm-dd)')),
      TextField(
          controller: amount,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (₦)')),
    ], () {
      b.guest = guest.text;
      b.phone = phone.text;
      b.room = room;
      b.checkin = checkin.text;
      b.checkout = checkout.text;
      b.amount = int.tryParse(amount.text) ?? b.amount;
      if (b.status != 'checked-out' && b.status != 'cancelled') {
        final nr = HOMData.rooms.where((rr) => rr.number == room).toList();
        if (nr.isNotEmpty) nr.first.status = 'occupied';
      }
      setState(() {});
      HOMData.save();
    });
  }

  void _checkout(Booking b) {
    b.status = 'checked-out';
    final r = HOMData.rooms.where((rr) => rr.number == b.room).toList();
    if (r.isNotEmpty) r.first.status = 'available';
    setState(() {});
    HOMData.save();
    FeedStore.log(
      dept: 'reception',
      action: 'booking.checkedOut',
      message: 'Checked out ${b.guest} — Room ${b.room}',
      refId: b.id,
    );
  }

  void _cancel(Booking b) {
    b.status = 'cancelled';
    final r = HOMData.rooms.where((rr) => rr.number == b.room).toList();
    if (r.isNotEmpty) r.first.status = 'available';
    setState(() {});
    HOMData.save();
    FeedStore.log(
      dept: 'reception',
      action: 'booking.cancelled',
      message: 'Cancelled booking — ${b.guest} (Room ${b.room})',
      refId: b.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(
            child: Text('Bookings (${HOMData.bookings.length})',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                overflow: TextOverflow.ellipsis)),
        RoleGate(
            requiredPermission: Permission.createBooking,
            child: ElevatedButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New'))),
      ]),
      const SizedBox(height: 8),
      ...HOMData.bookings.map((b) => Card(
              child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(
                    child: Text(b.guest,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                        overflow: TextOverflow.ellipsis)),
                _statusChip(b.status),
              ]),
              const SizedBox(height: 4),
              Text(
                  'Room ${b.room} • ${b.checkin} → ${b.checkout} • ₦${b.amount}',
                  style: TextStyle(fontSize: 12, color: AppColors.grey600),
                  overflow: TextOverflow.ellipsis),
              Row(children: [
                Flexible(
                    child: Text(b.phone,
                        style:
                            TextStyle(fontSize: 11, color: AppColors.grey500),
                        overflow: TextOverflow.ellipsis)),
                const Spacer(),
                if (b.phone.isNotEmpty)
                  GestureDetector(
                    onTap: () => _sendWhatsApp(context, b.phone,
                        'Dear ${b.guest}, your booking at HOM Hotel is confirmed! Room ${b.room}, Check-in: ${b.checkin}, Check-out: ${b.checkout}. Thank you!'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.whatsapp.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.chat_rounded,
                            size: 12, color: AppColors.whatsapp),
                        SizedBox(width: 4),
                        Text('WhatsApp',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.whatsapp)),
                      ]),
                    ),
                  ),
              ]),
              Wrap(spacing: 4, children: [
                if (b.status != 'checked-out' && b.status != 'cancelled') ...[
                  RoleGate(
                      requiredPermission: Permission.editBooking,
                      child: IconButton(
                          onPressed: () => _edit(b),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          tooltip: 'Edit')),
                  RoleGate(
                      requiredPermission: Permission.checkOutGuest,
                      child: IconButton(
                          onPressed: () => _checkout(b),
                          icon: const Icon(Icons.logout_rounded,
                              size: 18, color: primaryGreen),
                          tooltip: 'Check out')),
                  RoleGate(
                      requiredPermission: Permission.editBooking,
                      child: IconButton(
                          onPressed: () => _cancel(b),
                          icon: const Icon(Icons.cancel_rounded,
                              size: 18, color: AppColors.red),
                          tooltip: 'Cancel')),
                ],
                RoleGate(
                    requiredPermission: Permission.deleteBooking,
                    child: IconButton(
                        onPressed: () {
                          setState(() => HOMData.bookings.remove(b));
                          HOMData.save();
                        },
                        icon: const Icon(Icons.delete_rounded,
                            size: 18, color: AppColors.redAccent),
                        tooltip: 'Delete')),
              ]),
            ]),
          ))),
    ]);
  }
}

// ===================== ROOMS =====================

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});
  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  List<String> _knownRoomTypes() => {
        'Standard',
        'Deluxe',
        'Executive',
        'Suite',
        ...HOMData.rooms.map((r) => r.type),
      }.toList();

  void _promptNewType(BuildContext ctx, StateSetter setSB,
      void Function(String) onChanged) {
    final ctl = TextEditingController();
    showDialog<String>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: const Text('New room type'),
        content: TextField(
            controller: ctl,
            autofocus: true,
            decoration: const InputDecoration(
                labelText: 'Type name', border: OutlineInputBorder())),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final v = ctl.text.trim();
              if (v.isNotEmpty) onChanged(v);
              Navigator.pop(dctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _typePicker(String current, void Function(String) onChanged) {
    final options = _knownRoomTypes();
    return StatefulBuilder(
      builder: (ctx, setSB) => DropdownButtonFormField<String>(
        key: ValueKey('room-type-$current'),
        initialValue: current,
        items: [
          ...options.map((t) => DropdownMenuItem(value: t, child: Text(t))),
          const DropdownMenuItem(
              value: '__new__', child: Text('+ New type…')),
        ],
        onChanged: (v) {
          if (v == '__new__') {
            _promptNewType(ctx, setSB, onChanged);
          } else if (v != null) {
            setSB(() => onChanged(v));
          }
        },
        decoration: const InputDecoration(labelText: 'Type'),
      ),
    );
  }

  void _add() {
    final num = TextEditingController(), price = TextEditingController();
    String type = 'Deluxe';
    _showForm(context, 'Add Room', [
      TextField(
          controller: num,
          decoration: const InputDecoration(labelText: 'Room number')),
      _typePicker(type, (t) => type = t),
      TextField(
          controller: price,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Price per night')),
    ], () {
      if (num.text.isEmpty) return;
      HOMData.rooms.insert(
          0,
          Room(
              id: _uid(),
              number: num.text,
              type: type,
              status: 'available',
              price: int.tryParse(price.text) ?? 0));
      setState(() {});
      HOMData.save();
    });
  }

  void _edit(Room r) {
    final numCtl = TextEditingController(text: r.number);
    final price = TextEditingController(text: r.price.toString());
    String type = r.type;
    _showForm(context, 'Edit Room ${r.number}', [
      TextField(
          controller: numCtl,
          decoration: const InputDecoration(labelText: 'Room number')),
      _typePicker(type, (t) => type = t),
      TextField(
          controller: price,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Price')),
    ], () {
      if (numCtl.text.trim().isNotEmpty) r.number = numCtl.text.trim();
      r.type = type;
      r.price = int.tryParse(price.text) ?? r.price;
      setState(() {});
      HOMData.save();
    });
  }

  void _toggleStatus(Room r) {
    final statuses = <String>{'available', 'occupied', 'maintenance'}
      ..addAll(HOMData.rooms.map((rr) => rr.status));
    showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Set Status',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16))),
              ...statuses.map((s) => ListTile(
                    title: Text(s.toUpperCase()),
                    leading: Icon(
                        s == 'available'
                            ? Icons.check_circle_rounded
                            : s == 'occupied'
                                ? Icons.person_rounded
                                : s == 'maintenance'
                                    ? Icons.build_rounded
                                    : Icons.flag_rounded,
                        color:
                            s == r.status ? primaryGreen : AppColors.grey500),
                    onTap: () {
                      r.status = s;
                      Navigator.pop(ctx);
                      setState(() {});
                      HOMData.save();
                      FeedStore.log(
                        dept: 'reception',
                        action: 'room.status',
                        message: 'Room ${r.number} marked $s',
                        refId: r.id,
                      );
                    },
                  )),
            ])));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(
            child: Text('Rooms (${HOMData.rooms.length})',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                overflow: TextOverflow.ellipsis)),
        RoleGate(
            requiredPermission: Permission.manageRooms,
            child: ElevatedButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'))),
      ]),
      const SizedBox(height: 8),
      ...HOMData.rooms.map((r) => Card(
              child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(
                    child: Text('Room ${r.number}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 20),
                        overflow: TextOverflow.ellipsis)),
                _statusChip(r.status),
              ]),
              Text('${r.type} — ₦${r.price}/night',
                  style: TextStyle(fontSize: 13, color: AppColors.grey600)),
              const SizedBox(height: 8),
              Wrap(spacing: 4, children: [
                RoleGate(
                    requiredPermission: Permission.updateRoomStatus,
                    child: TextButton.icon(
                        onPressed: () => _toggleStatus(r),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                        label: const Text('Status'))),
                RoleGate(
                    requiredPermission: Permission.manageRooms,
                    child: IconButton(
                        onPressed: () => _edit(r),
                        icon: const Icon(Icons.edit_rounded, size: 18))),
                RoleGate(
                    requiredPermission: Permission.manageRooms,
                    child: IconButton(
                        onPressed: () {
                          setState(() => HOMData.rooms.remove(r));
                          HOMData.save();
                        },
                        icon: const Icon(Icons.delete_rounded,
                            size: 18, color: AppColors.redAccent))),
              ]),
            ]),
          ))),
    ]);
  }
}

// ===================== FUEL & ENERGY =====================

class DieselScreen extends StatefulWidget {
  const DieselScreen({super.key});
  @override
  State<DieselScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<DieselScreen> {
  FuelType? _filter;
  bool _linkExpenditure = true;

  List<FuelLog> get _logs {
    final all = HOMData.fuelLogs;
    if (_filter == null) return all;
    return all.where((f) => f.fuelType == _filter).toList();
  }

  Map<FuelType, double> _costByType() {
    final map = <FuelType, double>{};
    for (final f in HOMData.fuelLogs) {
      map[f.fuelType] = (map[f.fuelType] ?? 0) + f.cost;
    }
    return map;
  }

  int get _theftCount =>
      HOMData.fuelLogs.where((f) => f.theftAlertRate != null).length;

  void _add() {
    final qtyCtl = TextEditingController();
    final costCtl = TextEditingController();
    final supCtl = TextEditingController();
    final hrsCtl = TextEditingController();
    final noteCtl = TextEditingController();
    FuelType type = _filter ?? FuelType.diesel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSB) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                              child: Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                      color: AppColors.grey300,
                                      borderRadius: BorderRadius.circular(2)))),
                          const SizedBox(height: 16),
                          const Text('Log Fuel Purchase',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 17)),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<FuelType>(
                            initialValue: type,
                            items: FuelType.values
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Row(children: [
                                        Icon(t.icon, size: 18),
                                        const SizedBox(width: 8),
                                        Text(t.displayName)
                                      ]),
                                    ))
                                .toList(),
                            onChanged: (v) => setSB(() => type = v!),
                            decoration:
                                const InputDecoration(labelText: 'Fuel Type'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                              controller: qtyCtl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: 'Quantity (${type.unit})',
                                  hintText: 'e.g. 200')),
                          const SizedBox(height: 12),
                          TextField(
                              controller: costCtl,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'Cost (₦)')),
                          const SizedBox(height: 12),
                          TextField(
                              controller: supCtl,
                              decoration:
                                  const InputDecoration(labelText: 'Supplier')),
                          if (type.usageLabel != null) ...[
                            const SizedBox(height: 12),
                            TextField(
                                controller: hrsCtl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                    labelText: type.usageLabel!,
                                    hintText: 'e.g. 8')),
                          ],
                          const SizedBox(height: 12),
                          TextField(
                              controller: noteCtl,
                              decoration:
                                  const InputDecoration(labelText: 'Note')),
                          const SizedBox(height: 8),
                          if (type.category == FuelCategory.power)
                            CheckboxListTile(
                              title: const Text('Log to Expenditure',
                                  style: TextStyle(fontSize: 13)),
                              subtitle: const Text(
                                  'Auto-categorize as Utilities',
                                  style: TextStyle(fontSize: 11)),
                              value: _linkExpenditure,
                              onChanged: (v) =>
                                  setSB(() => _linkExpenditure = v!),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                final qty = double.tryParse(qtyCtl.text) ?? 0;
                                final cost = double.tryParse(costCtl.text) ?? 0;
                                if (qty <= 0 || cost <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Quantity and cost must be greater than zero')));
                                  return;
                                }
                                final hrs = double.tryParse(hrsCtl.text);
                                final log = FuelLog(
                                  id: _uid(),
                                  date: DateTime.now(),
                                  fuelType: type,
                                  quantity: qty,
                                  cost: cost,
                                  supplier: supCtl.text,
                                  usageHours: hrs,
                                  note: noteCtl.text,
                                );
                                HOMData.fuelLogs.insert(0, log);
                                if (_linkExpenditure &&
                                    type.category == FuelCategory.power) {
                                  ExpenditureStore.add(ExpenditureRecord(
                                    id: 'fuel_${_uid()}',
                                    date: DateTime.now(),
                                    category: ExpenditureCategory.utilities,
                                    subcategory: type.displayName,
                                    description:
                                        '${qty.toStringAsFixed(0)}${type.unit} ${type.displayName}${supCtl.text.isNotEmpty ? ' from $supCtl.text' : ''}${noteCtl.text.isNotEmpty ? ' — $noteCtl.text' : ''}',
                                    amount: cost,
                                    vendor: supCtl.text,
                                  ));
                                }
                                if (log.theftAlertRate != null) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        'THEFT ALERT: ${log.theftAlertRate!.toStringAsFixed(1)} ${log.fuelType.efficiencyUnit}!'),
                                    backgroundColor: AppColors.red,
                                  ));
                                  NotificationStore.notifyFuelTheft(
                                      log.theftAlertRate!,
                                      log.fuelType.displayName,
                                      log.supplier);
                                }
                                Navigator.pop(ctx);
                                setState(() {});
                                HOMData.save();
                              },
                              style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14)),
                              child: const Text('Save'),
                            ),
                          ),
                        ]),
                  ),
                ),
              )),
    );
  }

  void _edit(FuelLog log) {
    final qtyCtl = TextEditingController(text: log.quantity.toString());
    final costCtl = TextEditingController(text: log.cost.toString());
    final supCtl = TextEditingController(text: log.supplier);
    final hrsCtl =
        TextEditingController(text: log.usageHours?.toString() ?? '');
    final noteCtl = TextEditingController(text: log.note);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                              color: AppColors.grey300,
                              borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text('Edit ${log.fuelType.displayName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 16),
                  TextField(
                      controller: qtyCtl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: 'Quantity (${log.fuelType.unit})')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: costCtl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cost (₦)')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: supCtl,
                      decoration: const InputDecoration(labelText: 'Supplier')),
                  if (log.fuelType.usageLabel != null) ...[
                    const SizedBox(height: 12),
                    TextField(
                        controller: hrsCtl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: log.fuelType.usageLabel!)),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                      controller: noteCtl,
                      decoration: const InputDecoration(labelText: 'Note')),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        log.quantity =
                            double.tryParse(qtyCtl.text) ?? log.quantity;
                        log.cost = double.tryParse(costCtl.text) ?? log.cost;
                        log.supplier = supCtl.text;
                        log.usageHours = double.tryParse(hrsCtl.text);
                        log.note = noteCtl.text;
                        Navigator.pop(ctx);
                        setState(() {});
                        HOMData.save();
                      },
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Save'),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final costs = _costByType();
    final totalCost = costs.values.fold(0.0, (a, b) => a + b);
    final monthLogs = HOMData.fuelLogs
        .where((f) =>
            f.date.month == DateTime.now().month &&
            f.date.year == DateTime.now().year)
        .toList();
    final monthCost = monthLogs.fold(0.0, (s, f) => s + f.cost);
    final totalExp = ExpenditureStore.totalAll;

    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [AppColors.amber700, AppColors.amber500]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FUEL & ENERGY DASHBOARD',
              style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          Row(children: [
            _statBlock('₦${_fmtShort(monthCost)}', 'This Month',
                Icons.monetization_on_rounded),
            const SizedBox(width: 12),
            _statBlock('${_logs.length}',
                '${_filter?.displayName ?? 'All'} Logs', Icons.menu_rounded),
            const SizedBox(width: 12),
            _statBlock('$_theftCount', 'Theft Alerts', Icons.warning_rounded),
          ]),
          if (totalExp > 0 && monthCost > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (monthCost / totalExp).clamp(0.0, 1.0),
                backgroundColor: AppColors.white.withValues(alpha: 0.3),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.white),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
                'Energy is ${(monthCost / totalExp * 100).toStringAsFixed(0)}% of total expenditure',
                style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.8),
                    fontSize: 11)),
          ],
        ]),
      ),
      const SizedBox(height: 16),
      if (totalCost > 0)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cost Breakdown by Fuel Type',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.grey800)),
              const SizedBox(height: 10),
              ...FuelType.values.where((t) => (costs[t] ?? 0) > 0).map((t) {
                final pct = costs[t]! / totalCost * 100;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Icon(t.icon, size: 16, color: AppColors.amber700),
                    const SizedBox(width: 8),
                    Flexible(
                        flex: 2,
                        child: Text(t.displayName,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis)),
                    Expanded(
                      flex: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          backgroundColor: AppColors.grey200,
                          minHeight: 14,
                        ),
                      ),
                    ),
                    SizedBox(
                        width: 56,
                        child: Text('₦${_fmtShort(costs[t]!)}',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis)),
                  ]),
                );
              }),
            ]),
          ),
        ),
      const SizedBox(height: 12),
      SizedBox(
        height: 36,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          _chip(null, 'All', Icons.all_inclusive_rounded),
          ...FuelType.values.map((t) => _chip(t, t.displayName, t.icon)),
        ]),
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(
            child: Text(
                '${_filter?.displayName ?? 'Fuel'} Logs (${_logs.length})',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                overflow: TextOverflow.ellipsis)),
        RoleGate(
            requiredPermission: Permission.logFuel,
            child: ElevatedButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Log'))),
      ]),
      const SizedBox(height: 8),
      ..._logs.map((f) {
        final theft = f.theftAlertRate;
        return Card(
          color: theft != null ? AppColors.red50 : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Row(children: [
                    Icon(f.fuelType.icon,
                        size: 16,
                        color:
                            theft != null ? AppColors.red : AppColors.amber700),
                    const SizedBox(width: 6),
                    Flexible(
                        child: Text(
                            '${f.quantity.toStringAsFixed(0)}${f.fuelType.unit} — ${f.supplier}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13),
                            overflow: TextOverflow.ellipsis)),
                  ]),
                ),
                if (theft != null)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                        '${theft.toStringAsFixed(1)} ${f.fuelType.efficiencyUnit}',
                        style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                RoleGate(
                    requiredPermission: Permission.trackFuelDeliveryCycles,
                    child: IconButton(
                        onPressed: () => _edit(f),
                        icon: const Icon(Icons.edit_rounded, size: 16))),
                RoleGate(
                    requiredPermission: Permission.trackFuelDeliveryCycles,
                    child: IconButton(
                        onPressed: () {
                          setState(() => HOMData.fuelLogs.remove(f));
                          HOMData.save();
                        },
                        icon: const Icon(Icons.delete_rounded,
                            size: 16, color: AppColors.redAccent))),
              ]),
              const SizedBox(height: 4),
              Text(
                  '${_fmtDate(f.date)} • ${f.fuelType.displayName} • ₦${f.cost.toStringAsFixed(0)}${f.usageHours != null ? ' • ${f.usageHours!.toStringAsFixed(0)} hrs' : ''}${f.note.isNotEmpty ? ' • ${f.note}' : ''}',
                  style: TextStyle(fontSize: 11, color: AppColors.grey600)),
            ]),
          ),
        );
      }),
    ]);
  }

  Widget _chip(FuelType? t, String label, IconData icon) {
    final active = _filter == t;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        avatar: Icon(icon,
            size: 14, color: active ? AppColors.white : AppColors.grey600),
        label: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                color: active ? AppColors.white : null)),
        selected: active,
        onSelected: (_) => setState(() => _filter = t),
        selectedColor: AppColors.amber700,
        backgroundColor: AppColors.grey100,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _statBlock(String value, String label, IconData icon) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppColors.white.withValues(alpha: 0.9), size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15)),
          ),
        ]),
        Text(label,
            style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.8), fontSize: 10)),
      ]),
    );
  }

  String _fmtShort(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ===================== INVENTORY =====================

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  void _add() {
    final name = TextEditingController(),
        qty = TextEditingController(),
        low = TextEditingController(),
        cost = TextEditingController();
    _showForm(context, 'Add Item', [
      TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Name')),
      TextField(
          controller: qty,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantity')),
      TextField(
          controller: low,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Low stock threshold')),
      TextField(
          controller: cost,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Unit cost')),
    ], () {
      if (name.text.isEmpty) return;
      HOMData.inventory.insert(
          0,
          InventoryItem(
              id: _uid(),
              name: name.text,
              qty: int.tryParse(qty.text) ?? 0,
              low: int.tryParse(low.text) ?? 5,
              cost: int.tryParse(cost.text) ?? 0));
      setState(() {});
      HOMData.save();
    });
  }

  void _edit(InventoryItem it) {
    final name = TextEditingController(text: it.name);
    final qty = TextEditingController(text: it.qty.toString());
    final low = TextEditingController(text: it.low.toString());
    final cost = TextEditingController(text: it.cost.toString());
    _showForm(context, 'Edit Item', [
      TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Name')),
      TextField(
          controller: qty,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantity')),
      TextField(
          controller: low,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Low threshold')),
      TextField(
          controller: cost,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Unit cost')),
    ], () {
      it.name = name.text;
      it.qty = int.tryParse(qty.text) ?? it.qty;
      it.low = int.tryParse(low.text) ?? it.low;
      it.cost = int.tryParse(cost.text) ?? it.cost;
      setState(() {});
      HOMData.save();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(
            child: Text('Inventory (${HOMData.inventory.length})',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                overflow: TextOverflow.ellipsis)),
        RoleGate(
            requiredPermission: Permission.manageInventory,
            child: ElevatedButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'))),
      ]),
      const SizedBox(height: 8),
      ...HOMData.inventory.map((it) => Card(
              child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(
                    child: Text(it.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis)),
                if (it.qty <= it.low)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.red100,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Text('LOW',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.red)),
                  ),
              ]),
              Text('Qty: ${it.qty} • Min: ${it.low} • ₦${it.cost}',
                  style: TextStyle(fontSize: 12, color: AppColors.grey600)),
              const SizedBox(height: 8),
              Wrap(alignment: WrapAlignment.center, spacing: 4, children: [
                RoleGate(
                    requiredPermission: Permission.manageInventory,
                    child: IconButton(
                        onPressed: () {
                          setState(() {
                            it.qty = (it.qty - 1).clamp(0, 99999);
                            if (it.qty <= it.low && it.qty > 0)
                              NotificationStore.notifyLowInventory(
                                  it.name, it.qty, it.low);
                          });
                          HOMData.save();
                        },
                        icon:
                            const Icon(Icons.remove_circle_outline, size: 28))),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('${it.qty}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16))),
                RoleGate(
                    requiredPermission: Permission.manageInventory,
                    child: IconButton(
                        onPressed: () {
                          setState(() => it.qty += 10);
                          HOMData.save();
                        },
                        icon: const Icon(Icons.add_circle,
                            size: 28, color: primaryGreen))),
                RoleGate(
                    requiredPermission: Permission.manageInventory,
                    child: IconButton(
                        onPressed: () => _edit(it),
                        icon: const Icon(Icons.edit_rounded, size: 18))),
                RoleGate(
                    requiredPermission: Permission.manageInventory,
                    child: IconButton(
                        onPressed: () {
                          setState(() => HOMData.inventory.remove(it));
                          HOMData.save();
                        },
                        icon: const Icon(Icons.delete_rounded,
                            size: 18, color: AppColors.redAccent))),
              ]),
            ]),
          ))),
    ]);
  }
}

// ===================== STAFF / HR PAYROLL =====================

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  @override
  void initState() {
    super.initState();
    // Pull the hotel's users + invites from the callables into the cache.
    UserStore.refreshUsers().then((_) => mounted ? setState(() {}) : null);
    UserStore.refreshInvites();
  }

  void _add() {
    final name = TextEditingController(),
        role = TextEditingController(),
        phone = TextEditingController(),
        sal = TextEditingController();
    _showForm(context, 'Add Staff', [
      TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Full name')),
      TextField(
          controller: role,
          decoration: const InputDecoration(labelText: 'Role')),
      TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone (for WhatsApp)')),
      TextField(
          controller: sal,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monthly salary (₦)')),
    ], () {
      if (name.text.isEmpty) return;
      HOMData.staff.insert(
          0,
          StaffMember(
              id: _uid(),
              name: name.text,
              role: role.text,
              phone: phone.text,
              salary: int.tryParse(sal.text) ?? 0));
      setState(() {});
      HOMData.save();
    });
  }

  void _edit(StaffMember s) {
    final name = TextEditingController(text: s.name);
    final role = TextEditingController(text: s.role);
    final phone = TextEditingController(text: s.phone);
    final sal = TextEditingController(text: s.salary.toString());
    _showForm(context, 'Edit Staff', [
      TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Name')),
      TextField(
          controller: role,
          decoration: const InputDecoration(labelText: 'Role')),
      TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone')),
      TextField(
          controller: sal,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Salary')),
    ], () {
      s.name = name.text;
      s.role = role.text;
      s.phone = phone.text;
      s.salary = int.tryParse(sal.text) ?? s.salary;
      setState(() {});
      HOMData.save();
    });
  }

  Future<void> _sendPayslip(StaffMember s) async {
    final p = HOMData.paye(s.salary),
        pe = HOMData.pension(s.salary),
        net = HOMData.netPay(s.salary);
    if (s.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('No phone number for this staff member'),
        action: SnackBarAction(label: 'Edit', onPressed: () => _edit(s)),
      ));
      return;
    }
    final msg = 'HOM PAYROLL — ${s.name}\n'
        'Gross: ₦${s.salary}\nPAYE (7%): ₦$p\n'
        'Pension (8%): ₦$pe\nNet Pay: ₦$net\n'
        'Thank you for your service.';
    final raw = s.phone.replaceAll(RegExp(r'[^\d+]'), '');
    final phone = raw.startsWith('0')
        ? '+234${raw.substring(1)}'
        : raw.startsWith('+')
            ? raw
            : '+234$raw';
    final text = Uri.encodeComponent(msg);
    final uri = Uri.parse('https://wa.me/$phone?text=$text');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not open WhatsApp'),
            backgroundColor: AppColors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(
            child: Text('Staff & Payroll (${HOMData.staff.length})',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                overflow: TextOverflow.ellipsis)),
        Row(mainAxisSize: MainAxisSize.min, children: [
          RoleGate(
              requiredPermission: Permission.manageStaff,
              child: TextButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16))),
                  builder: (_) => const InviteStaffSheet(),
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Invite'),
              )),
          RoleGate(
              requiredPermission: Permission.manageStaff,
              child: ElevatedButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'))),
        ]),
      ]),
      const SizedBox(height: 8),
      ...HOMData.staff.map((s) {
        final p = HOMData.paye(s.salary),
            pe = HOMData.pension(s.salary),
            net = HOMData.netPay(s.salary);
        return Card(
            child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(
                  child: Text(s.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                      overflow: TextOverflow.ellipsis)),
              Row(children: [
                if (s.phone.isNotEmpty)
                  RoleGate(
                      requiredPermission: Permission.runPayroll,
                      child: IconButton(
                          onPressed: () => _sendPayslip(s),
                          icon: const Icon(Icons.chat_rounded,
                              size: 18, color: AppColors.whatsapp),
                          tooltip: 'WhatsApp')),
                RoleGate(
                    requiredPermission: Permission.manageStaff,
                    child: IconButton(
                        onPressed: () => _edit(s),
                        icon: const Icon(Icons.edit_rounded, size: 18))),
                RoleGate(
                    requiredPermission: Permission.manageStaff,
                    child: IconButton(
                        onPressed: () {
                          setState(() => HOMData.staff.remove(s));
                          HOMData.save();
                        },
                        icon: const Icon(Icons.delete_rounded,
                            size: 18, color: AppColors.redAccent))),
              ]),
            ]),
            Text(s.role,
                style: TextStyle(fontSize: 12, color: AppColors.grey600)),
            if (s.phone.isNotEmpty)
              Text(s.phone,
                  style: TextStyle(fontSize: 11, color: AppColors.grey500)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gross: ₦${s.salary}',
                        style: const TextStyle(fontSize: 12)),
                    Text('PAYE 7%: ₦$p',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.grey600)),
                    Text('Pension 8%: ₦$pe',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.grey600)),
                    Text('Net: ₦$net',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: primaryGreen)),
                  ]),
            ),
          ]),
        ));
      }),
      if (RoleStore.has(Permission.manageUsers)) ...[
        const SizedBox(height: 20),
        ValueListenableBuilder<int>(
          valueListenable: UserStore.usersVersion,
          builder: (context, _, __) {
            final accounts = UserStore.getUsers()
                .where((u) => u.userId != RoleStore.current.userId)
                .toList();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(
                    child: Text('App Accounts (${UserStore.getUsers().length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                        overflow: TextOverflow.ellipsis)),
                IconButton(
                  onPressed: () {
                    UserStore.getUsers()
                        .where((u) => u.userId == RoleStore.current.userId)
                        .forEach(_showAppAccountSheet);
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.manage_accounts_rounded, size: 20),
                  tooltip: 'Manage my own access',
                ),
              ]),
              const SizedBox(height: 8),
              ...accounts.map((u) => _accountTile(u)),
            ]);
          },
        ),
      ],
    ]);
  }

  Widget _accountTile(HotelUser u) {
    final roles = u.roleIds
        .map((id) => RoleStore.findRoleById(id)?.name ?? id)
        .join(', ');
    final scope = u.assignedDepartments.isEmpty
        ? 'All (Management)'
        : u.assignedDepartments.map((d) => d.name).join(', ');
    final heads = u.isHeadOfDepartment.entries
        .where((e) => e.value)
        .map((e) => e.key.name)
        .toList();
    final statusColor = switch (u.status) {
      AccountStatus.suspended => AppColors.redAccent,
      AccountStatus.pending => AppColors.grey500,
      AccountStatus.active => primaryGreen,
    };
    return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(u.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                  Text(u.email,
                      style: TextStyle(fontSize: 11, color: AppColors.grey500),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(roles,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(scope,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    if (heads.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('Heads ${heads.join(', ')}',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(u.status.label,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor)),
                    ),
                  ]),
                ])),
            IconButton(
              onPressed: () => _showAppAccountSheet(u),
              icon: const Icon(Icons.edit_rounded, size: 18),
              tooltip: 'Manage access',
            ),
          ]),
        ));
  }

  Future<void> _showAppAccountSheet(HotelUser u) async {
    final roleIds = List<String>.of(u.roleIds);
    final depts = List<Department>.of(u.assignedDepartments);
    var isHead = u.isHeadOfDepartment.entries.any((e) => e.value);
    var status = u.status;
    final roles = RoleStore.prebuiltRoles;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSB) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Manage ${u.name}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(u.email,
                        style:
                            TextStyle(fontSize: 12, color: AppColors.grey500)),
                    const SizedBox(height: 14),
                    const Text('Roles (additive)',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 4),
                    ...roles.map((r) => CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(r.name,
                              style: const TextStyle(fontSize: 13)),
                          value: roleIds.contains(r.id),
                          onChanged:
                              r.id == 'super_admin' && u.roleId == 'super_admin'
                                  ? null
                                  : (v) => setSB(() {
                                        v == true
                                            ? roleIds.add(r.id)
                                            : roleIds.remove(r.id);
                                      }),
                        )),
                    const SizedBox(height: 8),
                    const Text('Department scope',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final d in Department.values)
                        FilterChip(
                          label: Text(d.name,
                              style: const TextStyle(fontSize: 12)),
                          selected: depts.contains(d),
                          onSelected: (v) => setSB(() {
                            v ? depts.add(d) : depts.remove(d);
                            if (depts.isEmpty) isHead = false;
                          }),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Department Head',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      value: isHead,
                      onChanged:
                          depts.isEmpty ? null : (v) => setSB(() => isHead = v),
                    ),
                    DropdownButtonFormField<AccountStatus>(
                      initialValue: status,
                      decoration:
                          const InputDecoration(labelText: 'Account status'),
                      items: [
                        for (final s in AccountStatus.values)
                          DropdownMenuItem(value: s, child: Text(s.label)),
                      ],
                      onChanged: (v) => setSB(() => status = v ?? status),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.redAccent),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final confirmed = await _confirm('Delete account',
                                'Remove ${u.name}? Their access ends immediately.');
                            if (confirmed != true) return;
                            try {
                              await UserStore.deleteUser(u.firebaseUid ?? u.userId);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Delete failed: $e'),
                                        backgroundColor: AppColors.red));
                              }
                            }
                            if (mounted) setState(() {});
                          },
                          child: const Text('Delete'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final isOwner = u.roleId == 'super_admin';
                            if (isOwner && status != AccountStatus.active) {
                              final ok = await _confirm('Suspend owner',
                                  'You are about to suspend the owner account. Proceed?');
                              if (ok != true) return;
                            }
                            if (u.status != status &&
                                status == AccountStatus.suspended &&
                                !isOwner) {
                              final ok = await _confirm('Suspend account',
                                  '${u.name} will be locked out immediately. Proceed?');
                              if (ok != true) return;
                            }
                            u.roleIds
                              ..clear()
                              ..addAll(roleIds);
                            if (u.roleId.isEmpty ||
                                !roleIds.contains(u.roleId)) {
                              u.roleId =
                                  roleIds.isNotEmpty ? roleIds.first : u.roleId;
                            }
                            u.assignedDepartments
                              ..clear()
                              ..addAll(depts);
                            u.isHeadOfDepartment
                              ..clear()
                              ..addAll({for (final d in depts) d: isHead});
                            u.status = status;
                            try {
                              await UserStore.updateUser(u);
                            } catch (e) {
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Save failed: $e'),
                                      backgroundColor: AppColors.red));
                              return;
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (!mounted) return;
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('${u.name} access updated'),
                                  backgroundColor: primaryGreen),
                            );
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ]),
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirm(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Proceed')),
        ],
      ),
    );
  }
}

// ===================== VENDORS & PURCHASE ORDERS =====================

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key});
  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  void _addVendor() {
    final name = TextEditingController(),
        contact = TextEditingController(),
        cat = TextEditingController();
    _showForm(context, 'Add Vendor', [
      TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Name')),
      TextField(
          controller: contact,
          decoration: const InputDecoration(labelText: 'Contact')),
      TextField(
          controller: cat,
          decoration: const InputDecoration(labelText: 'Category')),
    ], () {
      if (name.text.isEmpty) return;
      HOMData.vendors.insert(
          0,
          Vendor(
              id: _uid(),
              name: name.text,
              contact: contact.text,
              category: cat.text));
      setState(() {});
      HOMData.save();
    });
  }

  void _editVendor(Vendor v) {
    final name = TextEditingController(text: v.name);
    final contact = TextEditingController(text: v.contact);
    final cat = TextEditingController(text: v.category);
    _showForm(context, 'Edit Vendor', [
      TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Name')),
      TextField(
          controller: contact,
          decoration: const InputDecoration(labelText: 'Contact')),
      TextField(
          controller: cat,
          decoration: const InputDecoration(labelText: 'Category')),
    ], () {
      if (name.text.isEmpty) return;
      v.name = name.text;
      v.contact = contact.text;
      v.category = cat.text;
      setState(() {});
      HOMData.save();
    });
  }

  void _addPO() {
    final items = TextEditingController(), amt = TextEditingController();
    String vendorId =
        HOMData.vendors.isNotEmpty ? HOMData.vendors.first.id : '';
    _showForm(context, 'New Purchase Order', [
      StatefulBuilder(
          builder: (ctx, setSB) => DropdownButtonFormField<String>(
                initialValue: vendorId,
                items: HOMData.vendors
                    .map((v) =>
                        DropdownMenuItem(value: v.id, child: Text(v.name)))
                    .toList(),
                onChanged: (v) => setSB(() => vendorId = v!),
                decoration: const InputDecoration(labelText: 'Vendor'),
              )),
      TextField(
          controller: items,
          decoration: const InputDecoration(labelText: 'Items')),
      TextField(
          controller: amt,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (₦)')),
    ], () {
      if (items.text.isEmpty) return;
      HOMData.purchaseOrders.insert(
          0,
          PurchaseOrder(
            id: _uid(),
            vendorId: vendorId,
            items: items.text,
            amount: int.tryParse(amt.text) ?? 0,
            date: _today(),
            status: 'pending',
          ));
      setState(() {});
      HOMData.save();
    });
  }

  void _editPO(PurchaseOrder po) {
    final items = TextEditingController(text: po.items);
    final amt = TextEditingController(text: po.amount.toString());
    String vendorId = po.vendorId;
    _showForm(context, 'Edit Purchase Order', [
      StatefulBuilder(
          builder: (ctx, setSB) => DropdownButtonFormField<String>(
                initialValue: vendorId,
                items: HOMData.vendors
                    .map((v) =>
                        DropdownMenuItem(value: v.id, child: Text(v.name)))
                    .toList(),
                onChanged: (v) => setSB(() => vendorId = v!),
                decoration: const InputDecoration(labelText: 'Vendor'),
              )),
      TextField(
          controller: items,
          decoration: const InputDecoration(labelText: 'Items')),
      TextField(
          controller: amt,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (₦)')),
    ], () {
      if (items.text.isEmpty) return;
      po.vendorId = vendorId;
      po.items = items.text;
      po.amount = int.tryParse(amt.text) ?? 0;
      setState(() {});
      HOMData.save();
    });
  }

  void _cycleStatus(PurchaseOrder po) {
    final statuses = ['pending', 'approved', 'delivered'];
    final i = statuses.indexOf(po.status);
    po.status = statuses[(i + 1) % statuses.length];
    setState(() {});
    HOMData.save();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Flexible(
            child: Text('Vendors & POs',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                overflow: TextOverflow.ellipsis)),
        Row(mainAxisSize: MainAxisSize.min, children: [
          RoleGate(
              requiredPermission: Permission.manageVendors,
              child: TextButton.icon(
                  onPressed: _addVendor,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Vendor'))),
          RoleGate(
              requiredPermission: Permission.managePurchaseOrders,
              child: ElevatedButton.icon(
                  onPressed: _addPO,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('PO'))),
        ]),
      ]),
      const SizedBox(height: 12),
      _sectionTitle('Vendors (${HOMData.vendors.length})'),
      ...HOMData.vendors.map((v) => Card(
              child: ListTile(
            title: Text(v.name,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${v.contact} • ${v.category}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (v.contact.isNotEmpty)
                HomTileAction(
                    onPressed: () => _sendWhatsApp(context, v.contact,
                        'Hello ${v.name}, this is HOM Hotel. We have a new purchase order for you.'),
                    icon: Icons.chat_rounded,
                    color: AppColors.whatsapp,
                    tooltip: 'WhatsApp'),
              RoleGate(
                  requiredPermission: Permission.manageVendors,
                  child: HomTileAction(
                      onPressed: () => _editVendor(v),
                      icon: Icons.edit_rounded)),
              RoleGate(
                  requiredPermission: Permission.manageVendors,
                  child: HomTileAction(
                      onPressed: () {
                        setState(() {
                          HOMData.vendors.remove(v);
                          HOMData.purchaseOrders
                              .removeWhere((po) => po.vendorId == v.id);
                        });
                        HOMData.save();
                      },
                      icon: Icons.delete_rounded,
                      color: AppColors.redAccent)),
            ]),
          ))),
      const SizedBox(height: 16),
      _sectionTitle('Purchase Orders (${HOMData.purchaseOrders.length})'),
      ...HOMData.purchaseOrders.map((po) {
        final vName = HOMData.vendors
                .where((v) => v.id == po.vendorId)
                .map((v) => v.name)
                .firstOrNull ??
            'Unknown';
        return Card(
            child: ListTile(
          title: Text(po.items,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('$vName • ₦${po.amount} • ${po.date}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            RoleGate(
                requiredPermission: Permission.managePurchaseOrders,
                child: GestureDetector(
                    onTap: () => _cycleStatus(po),
                    child: _statusChip(po.status))),
            RoleGate(
                requiredPermission: Permission.managePurchaseOrders,
                child: HomTileAction(
                    onPressed: () => _editPO(po),
                    icon: Icons.edit_rounded)),
            RoleGate(
                requiredPermission: Permission.managePurchaseOrders,
                child: HomTileAction(
                    onPressed: () {
                      setState(() => HOMData.purchaseOrders.remove(po));
                      HOMData.save();
                    },
                    icon: Icons.delete_rounded,
                    color: AppColors.redAccent)),
          ]),
        ));
      }),
    ]);
  }
}
