import 'dart:async';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/role.dart';
import '../models/hotel_user.dart';
import 'role_store.dart';
import 'user_store.dart';
import 'firestore_role_service.dart';

class AuthService {
  static Box<String>? _box;
  static final _firebaseAuth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn.instance;
  static StreamSubscription? _sessionSubscription;

  static Future<void> init() async {
    _box = await Hive.openBox<String>('hom_auth');

    // Initialize Google Sign-In
    try {
      await _googleSignIn.initialize();
    } catch (_) {}

    // Try restoring session from Hive first
    final restored = await _restoreFromHive();
    if (restored) return;

    // If Firebase Auth has a current user, try restoring from Firestore
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      await _restoreFromFirestore(firebaseUser.uid);
    }
  }

  /// Zero-trust restore: NO admin fallback. A stored session that no longer
  /// resolves to a known user or roles stays unauthenticated.
  static Future<bool> _restoreFromHive() async {
    final raw = _box?.get('session');
    if (raw == null) return false;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final userId = data['userId'] as String;
      if (userId.isEmpty) return false;
      final user = UserStore.findById(userId);
      if (user == null) return false;

      final roleIds = (data['roleIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      final departments = (data['assignedDepartments'] as List<dynamic>? ?? [])
          .map((e) => Department.values.asNameMap()[e.toString()])
          .whereType<Department>()
          .toList();
      final custom = (data['customPermissions'] as List<dynamic>? ?? [])
          .map((e) => Permission.values.asNameMap()[e.toString()])
          .whereType<Permission>()
          .toSet();
      final heads = (data['isHeadOfDepartment'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(
            Department.values.asNameMap()[k] ?? Department.management,
            v == true,
          ));
      final status = AccountStatus.values.asNameMap()[data['status']] ??
          (roleIds.isEmpty ? AccountStatus.pending : AccountStatus.active);

      final session = Session(
        userId: user.userId,
        userName: user.name,
        email: user.email,
        roleIds: roleIds.isNotEmpty ? roleIds : user.roleIds,
        assignedDepartments:
            departments.isNotEmpty ? departments : user.assignedDepartments,
        customPermissions: custom.isNotEmpty ? custom : user.customPermissions,
        isHeadOfDepartment: heads.isNotEmpty ? heads : user.isHeadOfDepartment,
        status: user.isSuspended ? AccountStatus.suspended : status,
        hotelId: user.hotelId,
      );
      RoleStore.setSession(session);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _restoreFromFirestore(String uid) async {
    final data = await FirestoreRoleService.readUserRole(uid);
    if (data == null) return;
    final session = FirestoreRoleService.buildSessionFromMap(data);
    if (session.userId.isEmpty) return;
    RoleStore.setSession(session);
    await _persist(session);
    _subscribeToFirestore(uid);
  }

  /// Real-time access sync: promotion, department transfer and suspension
  /// propagate to the device the moment the Firestore doc changes.
  static void _subscribeToFirestore(String uid) {
    _sessionSubscription?.cancel();
    _sessionSubscription = FirestoreRoleService.listen(uid).listen((data) {
      if (data == null) {
        // Account removed in cloud — lock the app down to login.
        clear();
        return;
      }
      final session = FirestoreRoleService.buildSessionFromMap(data);
      if (session.userId.isEmpty) return;
      RoleStore.setSession(session);
      _persist(session);
    });
  }

  static Session _buildSessionForUser(HotelUser user) {
    return Session(
      userId: user.userId,
      userName: user.name,
      email: user.email,
      roleIds: user.roleIds,
      assignedDepartments: user.assignedDepartments,
      customPermissions: user.customPermissions,
      isHeadOfDepartment: user.isHeadOfDepartment,
      status: user.status,
      hotelId: user.hotelId,
    );
  }

  // ===================== EMAIL/PASSWORD LOGIN =====================

  static Future<bool> login(String email, String password) async {
    final user = UserStore.findByEmail(email);
    if (user == null) return false;
    if (!UserStore.verifyPassword(password, user.passwordHash)) return false;

    final session = _buildSessionForUser(user);
    RoleStore.setSession(session);
    await _persist(session);

    // Background: create Firebase Auth user + write role to Firestore
    _syncToFirebase(user.email, password, session, user.userId);
    return true;
  }

  static Future<void> _syncToFirebase(
    String email,
    String password,
    Session session,
    String userId,
  ) async {
    try {
      UserCredential? cred;
      try {
        cred = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          cred = await _firebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }
      if (cred.user != null) {
        await FirestoreRoleService.writeUserRole(
          uid: cred.user!.uid,
          userId: userId,
          roleIds: session.roleIds,
          userName: session.userName,
          hotelId: session.hotelId ?? '',
          email: email,
          assignedDepartments: session.assignedDepartments,
          customPermissions: session.customPermissions,
          isHeadOfDepartment: session.isHeadOfDepartment,
          status: session.status,
        );
        await _rememberFirebaseUid(userId, cred.user!.uid);
        _subscribeToFirestore(cred.user!.uid);
      }
    } catch (_) {}
  }

  // ===================== GOOGLE SIGN-IN =====================

  static Future<bool> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) return false;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken!,
      );
      final userCred = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCred.user;
      if (firebaseUser == null) return false;

      // Look up role in Firestore
      final data = await FirestoreRoleService.readUserRole(firebaseUser.uid);
      if (data == null) {
        // New Google user — check if email is in local UserStore
        final localUser = UserStore.findByEmail(firebaseUser.email ?? '');
        if (localUser != null) {
          // Known user: write role to Firestore and proceed
          final session = _buildSessionForUser(localUser);
          RoleStore.setSession(session);
          await _persist(session);
          await FirestoreRoleService.writeUserRole(
            uid: firebaseUser.uid,
            userId: localUser.userId,
            roleIds: localUser.roleIds,
            userName: localUser.name,
            hotelId: localUser.hotelId,
            email: firebaseUser.email ?? '',
            assignedDepartments: localUser.assignedDepartments,
            customPermissions: localUser.customPermissions,
            isHeadOfDepartment: localUser.isHeadOfDepartment,
            status: localUser.status,
          );
          _subscribeToFirestore(firebaseUser.uid);
          return true;
        }
        // Unknown Google user — cannot proceed without an invite
        await _firebaseAuth.signOut();
        await _googleSignIn.signOut();
        return false;
      }

      final session = FirestoreRoleService.buildSessionFromMap(data);
      if (session.userId.isEmpty) return false;
      RoleStore.setSession(session);
      await _persist(session);
      _subscribeToFirestore(firebaseUser.uid);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ===================== REGISTRATION =====================

  static Future<Session> registerOwner({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String hotelName,
  }) async {
    final user = await UserStore.registerOwner(
      name: name,
      email: email,
      phone: phone,
      password: password,
      hotelName: hotelName,
    );
    final session = _buildSessionForUser(user);
    RoleStore.setSession(session);
    await _persist(session);

    // Create Firebase Auth user + write role claim
    _firebaseCreateUser(email, password, session, user.userId);
    return session;
  }

  static Future<Session?> registerStaff({
    required String inviteCode,
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final user = await UserStore.registerStaff(
      inviteCode: inviteCode,
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
    if (user == null) return null;
    final session = _buildSessionForUser(user);
    RoleStore.setSession(session);
    await _persist(session);

    _firebaseCreateUser(email, password, session, user.userId);
    return session;
  }

  static Future<void> _firebaseCreateUser(
    String email,
    String password,
    Session session,
    String userId,
  ) async {
    try {
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user != null) {
        await FirestoreRoleService.writeUserRole(
          uid: cred.user!.uid,
          userId: userId,
          roleIds: session.roleIds,
          userName: session.userName,
          hotelId: session.hotelId ?? '',
          email: email,
          assignedDepartments: session.assignedDepartments,
          customPermissions: session.customPermissions,
          isHeadOfDepartment: session.isHeadOfDepartment,
          status: session.status,
        );
        await _rememberFirebaseUid(userId, cred.user!.uid);
        _subscribeToFirestore(cred.user!.uid);
      }
    } catch (_) {}
  }

  /// Persist the Firebase Auth UID onto the local user so admin edits can
  /// push updated assignments to the right Firestore role document.
  static Future<void> _rememberFirebaseUid(String userId, String uid) async {
    final local = UserStore.findById(userId);
    if (local != null && local.firebaseUid != uid) {
      local.firebaseUid = uid;
      await UserStore.updateUser(local);
    }
  }

  // ===================== PERSISTENCE =====================

  static Future<void> _persist(Session session) async {
    final data = {
      'userId': session.userId,
      'userName': session.userName,
      'roleIds': session.roleIds,
      'assignedDepartments':
          session.assignedDepartments.map((d) => d.name).toList(),
      'customPermissions':
          session.customPermissions.map((p) => p.name).toList(),
      'isHeadOfDepartment':
          session.isHeadOfDepartment.map((k, v) => MapEntry(k.name, v)),
      'status': session.status.name,
      'hotelId': session.hotelId,
    };
    await _box?.put('session', jsonEncode(data));
  }

  static Future<void> clear() async {
    await _box?.delete('session');
    _sessionSubscription?.cancel();
    _sessionSubscription = null;
    RoleStore.setSession(Session.empty());
  }

  static Future<void> logout() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid != null) {
      await FirestoreRoleService.clearUserRole(uid);
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
    }
    await clear();
  }
}
