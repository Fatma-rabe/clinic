// Firebase configuration for ortho-clinic-prod (Web app registered in Console).
// Flutter uses this file — NOT npm `firebase` or <script> tags.
//
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA4gE0TvAf6bpiaZ0Klm0TSFwWJoIKCXok',
    appId: '1:1022330598452:web:f4e89bcdab370ba0bd0661',
    messagingSenderId: '1022330598452',
    projectId: 'ortho-clinic-prod',
    authDomain: 'ortho-clinic-prod.firebaseapp.com',
    storageBucket: 'ortho-clinic-prod.firebasestorage.app',
    measurementId: 'G-SV9M0LQN88',
  );

  /// Windows desktop uses the same Firebase project (Web app credentials).
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA4gE0TvAf6bpiaZ0Klm0TSFwWJoIKCXok',
    appId: '1:1022330598452:web:f4e89bcdab370ba0bd0661',
    messagingSenderId: '1022330598452',
    projectId: 'ortho-clinic-prod',
    authDomain: 'ortho-clinic-prod.firebaseapp.com',
    storageBucket: 'ortho-clinic-prod.firebasestorage.app',
  );
}
