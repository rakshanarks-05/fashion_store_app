// Replace with output of: dart run flutterfire_cli:flutterfire configure
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux — '
          'run flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCo3wNi6nguEWujjgbErsT0H2RhL91n8cM',
    appId: '1:398558398277:web:665d8b50ac17bc8455a02c',
    messagingSenderId: '398558398277',
    projectId: 'fashionstoreapp-6c254',
    authDomain: 'fashionstoreapp-6c254.firebaseapp.com',
    storageBucket: 'fashionstoreapp-6c254.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCw0mnc5BJ_FZ__7Airy75OQS0CAAMQNnU',
    appId: '1:398558398277:android:90947dad93fabbca55a02c',
    messagingSenderId: '398558398277',
    projectId: 'fashionstoreapp-6c254',
    storageBucket: 'fashionstoreapp-6c254.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCtr_Q8oTTgUfBRS0I_mVq3L0f0DnPiTUc',
    appId: '1:398558398277:ios:4a9a7938e207d70055a02c',
    messagingSenderId: '398558398277',
    projectId: 'fashionstoreapp-6c254',
    storageBucket: 'fashionstoreapp-6c254.firebasestorage.app',
    iosBundleId: 'com.example.fashionStoreApplication',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCtr_Q8oTTgUfBRS0I_mVq3L0f0DnPiTUc',
    appId: '1:398558398277:ios:4a9a7938e207d70055a02c',
    messagingSenderId: '398558398277',
    projectId: 'fashionstoreapp-6c254',
    storageBucket: 'fashionstoreapp-6c254.firebasestorage.app',
    iosBundleId: 'com.example.fashionStoreApplication',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCo3wNi6nguEWujjgbErsT0H2RhL91n8cM',
    appId: '1:398558398277:web:474779206ba9870255a02c',
    messagingSenderId: '398558398277',
    projectId: 'fashionstoreapp-6c254',
    authDomain: 'fashionstoreapp-6c254.firebaseapp.com',
    storageBucket: 'fashionstoreapp-6c254.firebasestorage.app',
  );

}