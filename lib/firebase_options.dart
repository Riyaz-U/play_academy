// ─────────────────────────────────────────────────────────────────────────────
// THIS FILE IS A PLACEHOLDER.
//
// Run the following command to generate the real version:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// That command will overwrite this file with your actual Firebase project
// configuration and also place google-services.json in android/app/.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform. '
          'Run flutterfire configure to generate the correct options.',
        );
    }
  }

  // ── Replace all values below with output from `flutterfire configure` ──

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDgp8iFQg6oy2OuWpU_rAJjwPVSfOihYwk',
    appId: '1:609499275767:android:d037be2ccf01fe91fb4ef2',
    messagingSenderId: '609499275767',
    projectId: 'play-academy-a73b2',
    storageBucket: 'play-academy-a73b2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDBiyductG-jB3VJ6l7yEjIcb5eX43hnLg',
    appId: '1:609499275767:ios:a59beb3b1d0c3ca3fb4ef2',
    messagingSenderId: '609499275767',
    projectId: 'play-academy-a73b2',
    storageBucket: 'play-academy-a73b2.firebasestorage.app',
    iosBundleId: 'com.example.playAcademy',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA7CgsAytat8-pRTdbFLwpmnK4Hj4pyzS0',
    appId: '1:609499275767:web:10838e14a118f2e8fb4ef2',
    messagingSenderId: '609499275767',
    projectId: 'play-academy-a73b2',
    authDomain: 'play-academy-a73b2.firebaseapp.com',
    storageBucket: 'play-academy-a73b2.firebasestorage.app',
    measurementId: 'G-2EB7F1HSQE',
  );

}