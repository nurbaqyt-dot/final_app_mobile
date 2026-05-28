import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/app_constants.dart';
import '../models/app_user.dart';
import 'firebase_bootstrap.dart';
import 'preferences_service.dart';

class AuthService {
  AuthService({required PreferencesService preferencesService})
    : _preferencesService = preferencesService;

  final PreferencesService _preferencesService;
  final StreamController<AppUserModel?> _demoController =
      StreamController<AppUserModel?>.broadcast();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> initialize() async {
    if (!FirebaseBootstrap.isEnabled) {
      _demoController.add(_loadDemoUser());
    }
  }

  Stream<AppUserModel?> authStateChanges() {
    if (FirebaseBootstrap.isEnabled) {
      return FirebaseAuth.instance.authStateChanges().asyncMap(_resolveUser);
    }
    return _demoController.stream;
  }

  Future<AppUserModel?> currentUser() async {
    if (FirebaseBootstrap.isEnabled) {
      return _resolveUser(FirebaseAuth.instance.currentUser);
    }
    return _loadDemoUser();
  }

  Future<AppUserModel> register({
    required String name,
    required String studentId,
    required String email,
    required String password,
  }) async {
    try {
      if (FirebaseBootstrap.isEnabled) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        final profile = AppUserModel(
          id: credential.user!.uid,
          name: name,
          studentId: studentId,
          email: email,
          photoUrl: credential.user?.photoURL ?? '',
          createdAt: DateTime.now(),
          totalFocusMinutes: 0,
          currentStreak: 0,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(profile.id)
            .set(profile.toMap(), SetOptions(merge: true));
        return profile;
      }

      final profile = AppUserModel(
        id: 'demo-user',
        name: name,
        studentId: studentId,
        email: email,
        photoUrl: '',
        createdAt: DateTime.now(),
        totalFocusMinutes: 0,
        currentStreak: 0,
      );
      await _saveDemoUser(profile);
      _demoController.add(profile);
      return profile;
    } catch (_) {
      rethrow;
    }
  }

  Future<AppUserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (FirebaseBootstrap.isEnabled) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = await currentUser();
        if (user == null) {
          throw Exception('Unable to load profile after sign in.');
        }
        return user;
      }

      final existing = _loadDemoUser();
      final profile =
          existing?.copyWith(email: email) ??
          AppUserModel(
            id: 'demo-user',
            name: _displayNameFromEmail(email),
            studentId: AppConstants.developerStudentId,
            email: email,
            photoUrl: '',
            createdAt: DateTime.now(),
            totalFocusMinutes: 0,
            currentStreak: 0,
          );
      await _saveDemoUser(profile);
      _demoController.add(profile);
      return profile;
    } catch (_) {
      rethrow;
    }
  }

  Future<AppUserModel> signInWithGoogle() async {
    try {
      if (FirebaseBootstrap.isEnabled) {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('Google Sign-In was cancelled.');
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        final user = await currentUser();
        if (user == null) {
          throw Exception('Unable to load Google profile.');
        }
        return user;
      }

      final profile = AppUserModel(
        id: 'demo-user',
        name: 'JIHC Demo Student',
        studentId: AppConstants.developerStudentId,
        email: 'demo@jihcfocus.app',
        photoUrl: '',
        createdAt: DateTime.now(),
        totalFocusMinutes: 90,
        currentStreak: 4,
      );
      await _saveDemoUser(profile);
      _demoController.add(profile);
      return profile;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> updateProfile(AppUserModel profile) async {
    try {
      if (FirebaseBootstrap.isEnabled) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(profile.id)
            .set(profile.toMap(), SetOptions(merge: true));
        return;
      }
      await _saveDemoUser(profile);
      _demoController.add(profile);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      if (FirebaseBootstrap.isEnabled) {
        await FirebaseAuth.instance.signOut();
        await _googleSignIn.signOut();
        return;
      }
      await _preferencesService.remove(AppConstants.demoUserKey);
      _demoController.add(null);
    } catch (_) {
      rethrow;
    }
  }

  Future<AppUserModel?> _resolveUser(User? firebaseUser) async {
    if (firebaseUser == null) {
      return null;
    }
    final reference = FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid);
    final snapshot = await reference.get();
    if (snapshot.exists && snapshot.data() != null) {
      return AppUserModel.fromMap(firebaseUser.uid, snapshot.data()!);
    }

    final profile = AppUserModel(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'JIHC Student',
      studentId: AppConstants.developerStudentId,
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL ?? '',
      createdAt: DateTime.now(),
      totalFocusMinutes: 0,
      currentStreak: 0,
    );
    await reference.set(profile.toMap(), SetOptions(merge: true));
    return profile;
  }

  AppUserModel? _loadDemoUser() {
    final raw = _preferencesService.getMap(AppConstants.demoUserKey);
    if (raw == null) {
      return null;
    }
    return AppUserModel.fromMap(raw['id'] as String? ?? 'demo-user', raw);
  }

  Future<void> _saveDemoUser(AppUserModel profile) async {
    await _preferencesService.setMap(
      AppConstants.demoUserKey,
      <String, dynamic>{'id': profile.id, ...profile.toMap()},
    );
  }

  String _displayNameFromEmail(String email) {
    final local = email.split('@').first;
    if (local.isEmpty) {
      return 'JIHC Student';
    }
    return local
        .split(RegExp(r'[_\-.]'))
        .map(
          (part) => part.isEmpty
              ? ''
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}
