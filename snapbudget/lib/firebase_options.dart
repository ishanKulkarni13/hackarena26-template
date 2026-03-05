import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBbDBNpZiuPRIg_o65l-ERosPUNoshj_gA',
    appId: '1:796431080700:web:24d6830ac0f34732a20b79',
    messagingSenderId: '796431080700',
    projectId: 'snapbudget-40853',
    authDomain: 'snapbudget-40853.firebaseapp.com',
    storageBucket: 'snapbudget-40853.firebasestorage.app',
    measurementId: 'G-W5E2GR09Q9',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCPedgNhvZk4V3lyMG0-IoWmljOdxYzR5s',
    appId: '1:796431080700:ios:c3340e563dea7bf1a20b79',
    messagingSenderId: '796431080700',
    projectId: 'snapbudget-40853',
    storageBucket: 'snapbudget-40853.firebasestorage.app',
    androidClientId: '796431080700-iighh9317uup1ec5gfse7r2f4hrm487m.apps.googleusercontent.com',
    iosClientId: '796431080700-6lpp2mpnbakvgcda1bhqbh019gjbr3jq.apps.googleusercontent.com',
    iosBundleId: 'com.example.snapbudget',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCPedgNhvZk4V3lyMG0-IoWmljOdxYzR5s',
    appId: '1:796431080700:ios:c3340e563dea7bf1a20b79',
    messagingSenderId: '796431080700',
    projectId: 'snapbudget-40853',
    storageBucket: 'snapbudget-40853.firebasestorage.app',
    androidClientId: '796431080700-iighh9317uup1ec5gfse7r2f4hrm487m.apps.googleusercontent.com',
    iosClientId: '796431080700-6lpp2mpnbakvgcda1bhqbh019gjbr3jq.apps.googleusercontent.com',
    iosBundleId: 'com.example.snapbudget',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDcLGBQje-vXRDOTjAl5mk9po-LvKbfbk0',
    appId: '1:796431080700:android:e1677a9f4a0ad618a20b79',
    messagingSenderId: '796431080700',
    projectId: 'snapbudget-40853',
    storageBucket: 'snapbudget-40853.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBbDBNpZiuPRIg_o65l-ERosPUNoshj_gA',
    appId: '1:796431080700:web:5c78084f3df9b767a20b79',
    messagingSenderId: '796431080700',
    projectId: 'snapbudget-40853',
    authDomain: 'snapbudget-40853.firebaseapp.com',
    storageBucket: 'snapbudget-40853.firebasestorage.app',
    measurementId: 'G-HV7LXL4WDL',
  );

}