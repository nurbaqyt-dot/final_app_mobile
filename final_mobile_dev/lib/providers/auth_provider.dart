import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/planner_helpers.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firebase_bootstrap.dart';
import '../services/preferences_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthService authService,
    required PreferencesService preferencesService,
  }) : _authService = authService,
       _preferencesService = preferencesService;

  final AuthService _authService;
  final PreferencesService _preferencesService;

  StreamSubscription<AppUserModel?>? _subscription;
  AppUserModel? _user;
  bool _initialized = false;
  bool _busy = false;
  bool _onboardingSeen = false;
  String? _errorMessage;

  AppUserModel? get user => _user;
  bool get initialized => _initialized;
  bool get isBusy => _busy;
  bool get isAuthenticated => _user != null;
  bool get onboardingSeen => _onboardingSeen;
  bool get isDemoMode => !FirebaseBootstrap.isEnabled;
  String? get errorMessage => _errorMessage;
  String get displayName =>
      PlannerHelpers.normalizeUserName(_user?.name ?? 'Студент');

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _onboardingSeen = _preferencesService.getBool(
      AppConstants.onboardingSeenKey,
    );
    await _authService.initialize();
    _user = _normalize(await _authService.currentUser());
    _subscription = _authService.authStateChanges().listen((user) {
      _user = _normalize(user);
      notifyListeners();
    });
    _initialized = true;
    notifyListeners();
  }

  Future<void> markOnboardingSeen() async {
    _onboardingSeen = true;
    await _preferencesService.setBool(AppConstants.onboardingSeenKey, true);
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _perform(() async {
      _user = _normalize(
        await _authService.signInWithEmail(email: email, password: password),
      );
    });
  }

  Future<void> register({
    required String name,
    required String studentId,
    required String email,
    required String password,
  }) async {
    await _perform(() async {
      _user = _normalize(
        await _authService.register(
          name: name,
          studentId: studentId,
          email: email,
          password: password,
        ),
      );
    });
  }

  Future<void> signInWithGoogle() async {
    await _perform(() async {
      _user = _normalize(await _authService.signInWithGoogle());
    });
  }

  Future<void> saveProfile(AppUserModel profile) async {
    await _perform(() async {
      await _authService.updateProfile(profile);
      _user = _normalize(profile);
    }, withBusy: false);
  }

  Future<void> signOut() async {
    await _perform(() async {
      await _authService.signOut();
      _user = null;
    }, withBusy: false);
  }

  Future<void> _perform(
    Future<void> Function() action, {
    bool withBusy = true,
  }) async {
    _errorMessage = null;
    if (withBusy) {
      _busy = true;
      notifyListeners();
    }
    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  AppUserModel? _normalize(AppUserModel? user) {
    if (user == null) {
      return null;
    }
    return user.copyWith(
      name: PlannerHelpers.normalizeUserName(user.name),
      studentId: PlannerHelpers.normalizeStudentId(user.studentId),
      email: PlannerHelpers.normalizeEmail(user.email),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
