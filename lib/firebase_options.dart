import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyCbZnZEQdmhswAJQc0gSzlY_N9P6WvoPSg',
    appId: '1:332408601425:web:576c66d44738cb5d8cf170',
    messagingSenderId: '332408601425',
    projectId: 'code-analizer',
    authDomain: 'code-analizer.firebaseapp.com',
    databaseURL: 'https://code-analizer-default-rtdb.firebaseio.com',
    storageBucket: 'code-analizer.firebasestorage.app',
    measurementId: 'G-5MZ9LQXLL3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCuvCmo4vTjTekl53fnoGbA1kB-libUlI8',
    appId: '1:332408601425:android:0911bb76374856b78cf170',
    messagingSenderId: '332408601425',
    projectId: 'code-analizer',
    databaseURL: 'https://code-analizer-default-rtdb.firebaseio.com',
    storageBucket: 'code-analizer.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBqMIGVKVTrS8UT66JI5XW8gebYVlNxvMY',
    appId: '1:332408601425:ios:36451d41c477266e8cf170',
    messagingSenderId: '332408601425',
    projectId: 'code-analizer',
    databaseURL: 'https://code-analizer-default-rtdb.firebaseio.com',
    storageBucket: 'code-analizer.firebasestorage.app',
    iosBundleId: 'com.example.codeAnalyzer',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBqMIGVKVTrS8UT66JI5XW8gebYVlNxvMY',
    appId: '1:332408601425:ios:36451d41c477266e8cf170',
    messagingSenderId: '332408601425',
    projectId: 'code-analizer',
    databaseURL: 'https://code-analizer-default-rtdb.firebaseio.com',
    storageBucket: 'code-analizer.firebasestorage.app',
    iosBundleId: 'com.example.codeAnalyzer',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCbZnZEQdmhswAJQc0gSzlY_N9P6WvoPSg',
    appId: '1:332408601425:web:0a15422edf17ad5c8cf170',
    messagingSenderId: '332408601425',
    projectId: 'code-analizer',
    authDomain: 'code-analizer.firebaseapp.com',
    databaseURL: 'https://code-analizer-default-rtdb.firebaseio.com',
    storageBucket: 'code-analizer.firebasestorage.app',
    measurementId: 'G-JD87Q9C303',
  );

}