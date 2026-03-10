// File generated as a template based on GoogleService-Info.plist and google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can find this in your Firebase console.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return iOS;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCLH5vDBZgdTD_SprPUCvHvsd_Gu_nulb8',
    appId: '1:762860087826:android:667c15fdd1151df9ac86cb',
    messagingSenderId: '762860087826',
    projectId: 'gen-lang-client-0860101261',
    storageBucket: 'gen-lang-client-0860101261.firebasestorage.app',
  );

  static const FirebaseOptions iOS = FirebaseOptions(
    apiKey: 'AIzaSyD4g0dCYP_4WFRLC3x8T4M2gKUJVCAlFas',
    appId: '1:762860087826:ios:71e54ae3aa3a3141ac86cb',
    messagingSenderId: '762860087826',
    projectId: 'gen-lang-client-0860101261',
    storageBucket: 'gen-lang-client-0860101261.firebasestorage.app',
    iosBundleId: 'com.example.healing-moments',
  );
}
