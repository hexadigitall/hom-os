import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/role.dart';
import 'role_store.dart';
import 'user_store.dart';
import 'firestore_role_service.dart';

class AuthService {
  static Box<String>? _box;
  static final _firebaseAuth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn.instance;

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

  static Future<bool> _restoreFromHive() async {
    final raw = _box?.get('session');
    if (raw == null) return false;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final roleId = data['roleId'] as String;
      final userId = data['userId'] as String;
      final user = UserStore.findById(userId);
      if (user != null) {
        final role = _findRole(roleId);
        if (role != null) {
          RoleStore.setSession(Session(
            userId: userId,
            userName: user.name,
            role: role,
            hotelId: user.hotelId,
          ));
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  static Future<void> _restoreFromFirestore(String uid) async {
    final data = await FirestoreRoleService.readUserRole(uid);
    if (data == null) return;
    final session = FirestoreRoleService.buildSession(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      roleId: data['roleId'] ?? '',
      hotelId: data['hotelId'] ?? '',
    );
    if (session.userId.isNotEmpty) {
      RoleStore.setSession(session);
      await _persist(session);
    }
  }

  static AppRole? _findRole(String roleId) {
    for (final r in RoleStore.prebuiltRoles) {
      if (r.id == roleId) return r;
    }
    return null;
  }

  // ===================== EMAIL/PASSWORD LOGIN =====================

  static Future<bool> login(String email, String password) async {
    final user = UserStore.findByEmail(email);
    if (user == null) return false;
    if (!UserStore.verifyPassword(password, user.passwordHash)) return false;
    final role = _findRole(user.roleId);
    if (role == null) return false;

    final session = Session(
      userId: user.userId,
      userName: user.name,
      role: role,
      hotelId: user.hotelId,
    );
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
          roleId: session.role.id,
          userName: session.userName,
          hotelId: session.hotelId ?? '',
          email: email,
        );
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
          final role = _findRole(localUser.roleId);
          if (role == null) return false;
          final session = Session(
            userId: localUser.userId,
            userName: localUser.name,
            role: role,
            hotelId: localUser.hotelId,
          );
          RoleStore.setSession(session);
          await _persist(session);
          await FirestoreRoleService.writeUserRole(
            uid: firebaseUser.uid,
            userId: localUser.userId,
            roleId: localUser.roleId,
            userName: localUser.name,
            hotelId: localUser.hotelId,
            email: firebaseUser.email ?? '',
          );
          return true;
        }
        // Unknown Google user — cannot proceed without an invite
        await _firebaseAuth.signOut();
        await _googleSignIn.signOut();
        return false;
      }

      final session = FirestoreRoleService.buildSession(
        userId: data['userId'] ?? '',
        userName: data['userName'] ?? '',
        roleId: data['roleId'] ?? '',
        hotelId: data['hotelId'] ?? '',
      );
      if (session.userId.isEmpty) return false;
      RoleStore.setSession(session);
      await _persist(session);
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
    final role = _findRole('super_admin')!;
    final session = Session(
      userId: user.userId,
      userName: user.name,
      role: role,
      hotelId: user.hotelId,
    );
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
    final role = _findRole(user.roleId);
    if (role == null) return null;
    final session = Session(
      userId: user.userId,
      userName: user.name,
      role: role,
      hotelId: user.hotelId,
    );
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
          roleId: session.role.id,
          userName: session.userName,
          hotelId: session.hotelId ?? '',
          email: email,
        );
      }
    } catch (_) {}
  }

  // ===================== PERSISTENCE =====================

  static Future<void> _persist(Session session) async {
    final data = {
      'userId': session.userId,
      'userName': session.userName,
      'roleId': session.role.id,
      'hotelId': session.hotelId,
    };
    await _box?.put('session', jsonEncode(data));
  }

  static Future<void> clear() async {
    await _box?.delete('session');
    RoleStore.setSession(Session(
      userId: '',
      userName: '',
      role: RoleStore.prebuiltRoles.first,
    ));
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
