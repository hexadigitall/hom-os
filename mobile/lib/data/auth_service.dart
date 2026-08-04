import 'dart:async';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/role.dart';
import 'role_store.dart';
import 'user_store.dart';
import 'firestore_role_service.dart';
import 'hom_api_service.dart';

enum AuthStatus { ok, unprovisioned, failed }

/// Result of an auth attempt. `unprovisioned` means the Firebase account is
/// signed in but has no role document yet — the UI must route to invite
/// connect (staff) or hotel provisioning (owner).
class AuthResult {
  final AuthStatus status;
  final String? message;

  const AuthResult._(this.status, [this.message]);

  static const ok = AuthResult._(AuthStatus.ok);
  static const unprovisioned = AuthResult._(AuthStatus.unprovisioned);
  static AuthResult failed(String msg) => AuthResult._(AuthStatus.failed, msg);

  bool get isOk => status == AuthStatus.ok;
}

/// Firebase-first identity. Firebase Auth is the only sign-in; role
/// assignments are read from the `user_roles` Firestore doc (realtime) and
/// every mutation goes through Cloud Functions callables. The Hive box is
/// purely an offline cache — it is never treated as a source of truth.
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

    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      // Authoritative refresh from Firestore (self-read allowed by rules).
      final data = await FirestoreRoleService.readUserRole(firebaseUser.uid);
      if (data != null) {
        final session = FirestoreRoleService.buildSessionFromMap(data);
        if (session.userId.isNotEmpty) {
          RoleStore.setSession(session);
          await _persist(session);
          _subscribeToFirestore(firebaseUser.uid);
          _refreshAdminData(session);
          return;
        }
      }
      // Signed in but not provisioned — stay signed in to Firebase so
      // redeemInvite/provisionOwner can attach a role, but show login.
    }

    // Offline / no Firebase user — restore cached session (local cache only).
    await _restoreFromHive();
  }

  /// Zero-trust restore from the offline cache: NO admin fallback. A stored
  /// session that carries no identity or roles stays unauthenticated. The
  /// session doc itself is the only source — no dependency on the user cache.
  static Future<bool> _restoreFromHive() async {
    final raw = _box?.get('session');
    if (raw == null) return false;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final userId = data['userId'] as String;
      if (userId.isEmpty) return false;

      final roleIds = (data['roleIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      if (roleIds.isEmpty) return false;
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
          AccountStatus.pending;

      final session = Session(
        userId: userId,
        userName: data['userName']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        roleIds: roleIds,
        assignedDepartments: departments,
        customPermissions: custom,
        isHeadOfDepartment: heads,
        status: status,
        hotelId: data['hotelId']?.toString(),
        hotelName: data['hotelName']?.toString() ?? '',
      );
      RoleStore.setSession(session);
      return true;
    } catch (_) {
      return false;
    }
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
      _refreshAdminData(session);
    });
  }

  /// When the session is management-level, refresh the admin caches
  /// (users + invites) from the callables.
  static void _refreshAdminData(Session session) {
    if (session.has(Permission.manageStaff)) {
      UserStore.refreshInvites().catchError((_) {});
    }
    if (session.has(Permission.manageUsers)) {
      UserStore.refreshUsers().catchError((_) {});
    }
  }

  /// Attach the signed-in Firebase user's role doc to the session.
  static Future<AuthResult> _applyRoleDoc(String uid) async {
    Map<String, dynamic>? data;
    for (var attempt = 0; attempt < 6 && data == null; attempt++) {
      data = await FirestoreRoleService.readUserRole(uid);
      if (data == null) await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    if (data == null) return AuthResult.unprovisioned;

    final session = FirestoreRoleService.buildSessionFromMap(data);
    if (session.userId.isEmpty) return AuthResult.unprovisioned;
    RoleStore.setSession(session);
    await _persist(session);
    _subscribeToFirestore(uid);
    _refreshAdminData(session);
    return AuthResult.ok;
  }

  // ===================== EMAIL/PASSWORD LOGIN =====================

  static Future<AuthResult> login(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found' ||
          e.code == 'invalid-email') {
        return AuthResult.failed('Invalid email or password');
      }
      return AuthResult.failed(e.message ?? 'Login failed');
    } catch (e) {
      return AuthResult.failed('Login failed: $e');
    }
    final user = _firebaseAuth.currentUser;
    if (user == null) return AuthResult.failed('Sign-in failed.');
    return _applyRoleDoc(user.uid);
  }

  static Future<String?> sendPasswordReset(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Could not send reset email.';
    }
  }

  // ===================== GOOGLE SIGN-IN =====================

  static Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) return AuthResult.failed('Google sign-in incomplete.');
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken!);
      final userCred = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCred.user;
      if (firebaseUser == null) return AuthResult.failed('Google sign-in failed.');
      return _applyRoleDoc(firebaseUser.uid);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failed(e.message ?? 'Google sign-in failed.');
    } catch (e) {
      return AuthResult.failed('Google sign-in error: $e');
    }
  }

  /// True when Firebase is signed in but the account has no role document —
  /// used to decide whether to show the invite-connect / provision UI.
  static bool get hasUnprovisionedFirebaseUser =>
      _firebaseAuth.currentUser != null;

  // ===================== REGISTRATION =====================

  static Future<Session> registerOwner({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String hotelName,
  }) async {
    // The server creates the Auth user, hotel doc and super_admin role doc.
    await HomApiService.signupOwner(
      name: name,
      email: email,
      phone: phone,
      password: password,
      hotelName: hotelName,
    );
    // Sign in locally so the client has a Firebase Auth session.
    await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    final user = _firebaseAuth.currentUser;
    if (user == null) throw HomApiException('Sign-in after registration failed.');
    final result = await _applyRoleDoc(user.uid);
    if (!result.isOk) {
      throw HomApiException(result.message ?? 'Account created but role could not be loaded.');
    }
    return RoleStore.current;
  }

  static Future<Session?> registerStaff({
    required String inviteCode,
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await HomApiService.signupStaff(
      inviteCode: inviteCode,
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
    await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    final user = _firebaseAuth.currentUser;
    if (user == null) throw HomApiException('Sign-in after registration failed.');
    final result = await _applyRoleDoc(user.uid);
    if (!result.isOk) {
      throw HomApiException(result.message ?? 'Account created but role could not be loaded.');
    }
    return RoleStore.current;
  }

  /// Link the already-signed-in (Google) account to an invite code.
  static Future<Session> redeemInvite(String inviteCode) async {
    await HomApiService.redeemInvite(inviteCode);
    final user = _firebaseAuth.currentUser;
    if (user == null) throw HomApiException('Sign in required.');
    final result = await _applyRoleDoc(user.uid);
    if (!result.isOk) {
      throw HomApiException(result.message ?? 'Invite could not be redeemed.');
    }
    return RoleStore.current;
  }

  /// Provision a new hotel for the already-signed-in (Google) owner.
  static Future<Session> provisionOwner({
    required String name,
    required String phone,
    required String hotelName,
  }) async {
    await HomApiService.provisionOwner(
      name: name,
      phone: phone,
      hotelName: hotelName,
    );
    final user = _firebaseAuth.currentUser;
    if (user == null) throw HomApiException('Sign in required.');
    final result = await _applyRoleDoc(user.uid);
    if (!result.isOk) {
      throw HomApiException(result.message ?? 'Hotel could not be provisioned.');
    }
    return RoleStore.current;
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
      'hotelName': session.hotelName,
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
    await _firebaseAuth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await clear();
  }
}
