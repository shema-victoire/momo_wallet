// File generated for MoMo Wallet Firebase initialization
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
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
      case TargetPlatform.fuchsia:
        return android; // fallback
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBN4FvcMf0js57kNk9Ici2jHC74VUEHh2A',
    appId: '1:6857069305:web:8498100fc1f108efc14828',
    messagingSenderId: '6857069305',
    projectId: 'momo-wallet-d9309',
    storageBucket: 'momo-wallet-d9309.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBN4FvcMf0js57kNk9Ici2jHC74VUEHh2A',
    appId: '1:6857069305:android:8498100fc1f108efc14828',
    messagingSenderId: '6857069305',
    projectId: 'momo-wallet-d9309',
    storageBucket: 'momo-wallet-d9309.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBN4FvcMf0js57kNk9Ici2jHC74VUEHh2A',
    appId: '1:6857069305:ios:8498100fc1f108efc14828',
    messagingSenderId: '6857069305',
    projectId: 'momo-wallet-d9309',
    storageBucket: 'momo-wallet-d9309.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBN4FvcMf0js57kNk9Ici2jHC74VUEHh2A',
    appId: '1:6857069305:ios:8498100fc1f108efc14828',
    messagingSenderId: '6857069305',
    projectId: 'momo-wallet-d9309',
    storageBucket: 'momo-wallet-d9309.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBN4FvcMf0js57kNk9Ici2jHC74VUEHh2A',
    appId: '1:6857069305:web:8498100fc1f108efc14828',
    messagingSenderId: '6857069305',
    projectId: 'momo-wallet-d9309',
    storageBucket: 'momo-wallet-d9309.firebasestorage.app',
  );
}
