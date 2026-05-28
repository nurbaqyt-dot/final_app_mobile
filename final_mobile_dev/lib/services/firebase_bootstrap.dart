import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static bool _initialized = false;
  static bool _enabled = false;
  static String _status =
      'Firebase has not been initialized yet for JIHC Focus.';

  static bool get isEnabled => _enabled;
  static String get status => _status;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      if (DefaultFirebaseOptions.isPlaceholder) {
        _enabled = false;
        _status =
            'Demo mode active. Replace lib/firebase_options.dart with your real Firebase configuration.';
        _initialized = true;
        return;
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _enabled = true;
      _status = 'Firebase connected successfully.';
    } catch (error) {
      _enabled = false;
      _status = 'Demo mode active because Firebase failed: $error';
    } finally {
      _initialized = true;
    }
  }
}
