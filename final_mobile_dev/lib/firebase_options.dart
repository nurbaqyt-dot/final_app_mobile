import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static const bool isPlaceholder = false;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDj93wvcvfRXo6cEj0x8WoY8nup9V33pX8',
    appId: '1:71449805795:web:064633dd0e856097bd56d6',
    messagingSenderId: '71449805795',
    projectId: 'final-app-8aff9',
    authDomain: 'final-app-8aff9.firebaseapp.com',
    storageBucket: 'final-app-8aff9.firebasestorage.app',
    measurementId: 'G-JKSCN6MV9H',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD9dQ0WfF23sGnwXsdEfapi7tEmBo6cNe0',
    appId: '1:71449805795:android:e1779fb55c90cee6bd56d6',
    messagingSenderId: '71449805795',
    projectId: 'final-app-8aff9',
    storageBucket: 'final-app-8aff9.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCqo-DHSvakpDcli0sj69Uin8oxhw2XFVs',
    appId: '1:71449805795:ios:90ad574583bb5c55bd56d6',
    messagingSenderId: '71449805795',
    projectId: 'final-app-8aff9',
    storageBucket: 'final-app-8aff9.firebasestorage.app',
    iosBundleId: 'com.example.finalMobileDev',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCqo-DHSvakpDcli0sj69Uin8oxhw2XFVs',
    appId: '1:71449805795:ios:90ad574583bb5c55bd56d6',
    messagingSenderId: '71449805795',
    projectId: 'final-app-8aff9',
    storageBucket: 'final-app-8aff9.firebasestorage.app',
    iosBundleId: 'com.example.finalMobileDev',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDj93wvcvfRXo6cEj0x8WoY8nup9V33pX8',
    appId: '1:71449805795:web:35e20c917694989cbd56d6',
    messagingSenderId: '71449805795',
    projectId: 'final-app-8aff9',
    authDomain: 'final-app-8aff9.firebaseapp.com',
    storageBucket: 'final-app-8aff9.firebasestorage.app',
    measurementId: 'G-6RXSYP2E7H',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:web:jihcfocusdemo',
    messagingSenderId: '000000000000',
    projectId: 'jihc-focus-demo',
    authDomain: 'jihc-focus-demo.firebaseapp.com',
    storageBucket: 'jihc-focus-demo.appspot.com',
    measurementId: 'G-DEMO',
  );
}
