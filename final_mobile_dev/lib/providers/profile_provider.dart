import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/storage_service.dart';
import 'auth_provider.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({
    required StorageService storageService,
    required AuthProvider authProvider,
  }) : _storageService = storageService,
       _authProvider = authProvider;

  final StorageService _storageService;
  final AuthProvider _authProvider;

  bool _busy = false;

  bool get isBusy => _busy;

  Future<void> updateProfile({
    required String name,
    required String studentId,
  }) async {
    final user = _authProvider.user;
    if (user == null) {
      return;
    }
    await _run(
      () => _authProvider.saveProfile(
        user.copyWith(name: name, studentId: studentId),
      ),
    );
  }

  Future<void> uploadPhoto(ImageSource source) async {
    final user = _authProvider.user;
    if (user == null) {
      return;
    }
    await _run(() async {
      final photoUrl = await _storageService.pickAndUploadProfilePhoto(
        userId: user.id,
        source: source,
      );
      if (photoUrl == null) {
        return;
      }
      await _authProvider.saveProfile(user.copyWith(photoUrl: photoUrl));
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
