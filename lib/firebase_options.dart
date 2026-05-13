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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyDljEZjQNwTu4RbCWGMWQP41q39YDUw-JA',
    appId: '1:463365642651:web:d91b991907e74fbc25a93e',
    messagingSenderId: '463365642651',
    projectId: 'e-kodi-dashboard',
    authDomain: 'e-kodi-dashboard.firebaseapp.com',
    storageBucket: 'e-kodi-dashboard.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDhnXY1MvKZOMdMBIfVuyxtVLavwT9IleY',
    appId: '1:463365642651:android:2f70bcaa81b2656725a93e',
    messagingSenderId: '463365642651',
    projectId: 'e-kodi-dashboard',
    storageBucket: 'e-kodi-dashboard.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAOKULszRq8EMkfkdv9c0WvwJdx7CJjHhI',
    appId: '1:463365642651:ios:b55011cd5f5a3a8425a93e',
    messagingSenderId: '463365642651',
    projectId: 'e-kodi-dashboard',
    storageBucket: 'e-kodi-dashboard.firebasestorage.app',
    iosBundleId: 'com.ekodi.eKodi',
  );
}


















// import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
// import 'package:flutter/foundation.dart'
//     show defaultTargetPlatform, kIsWeb, TargetPlatform;
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// class DefaultFirebaseOptions {
//   static FirebaseOptions get currentPlatform {
//     if (kIsWeb) {
//       return web;
//     }
//     switch (defaultTargetPlatform) {
//       case TargetPlatform.android:
//         return android;
//       case TargetPlatform.iOS:
//         return ios;
//       case TargetPlatform.macOS:
//         throw UnsupportedError(
//           'DefaultFirebaseOptions have not been configured for macos - '
//           'you can reconfigure this by running the FlutterFire CLI again.',
//         );
//       case TargetPlatform.windows:
//         throw UnsupportedError(
//           'DefaultFirebaseOptions have not been configured for windows - '
//           'you can reconfigure this by running the FlutterFire CLI again.',
//         );
//       case TargetPlatform.linux:
//         throw UnsupportedError(
//           'DefaultFirebaseOptions have not been configured for linux - '
//           'you can reconfigure this by running the FlutterFire CLI again.',
//         );
//       default:
//         throw UnsupportedError(
//           'DefaultFirebaseOptions are not supported for this platform.',
//         );
//     }
//   }

//   // ✅ Web uses hardcoded values — dotenv not available on web
//   static const FirebaseOptions web = FirebaseOptions(
//     apiKey: 'AIzaSyDljEZjQNwTu4RbCWGMWQP41q39YDUw-JA',
//     appId: '1:463365642651:web:d91b991907e74fbc25a93e',
//     messagingSenderId: '463365642651',
//     projectId: 'e-kodi-dashboard',
//     authDomain: 'e-kodi-dashboard.firebaseapp.com',
//     storageBucket: 'e-kodi-dashboard.firebasestorage.app',
//   );

//   // ✅ Android and iOS still use dotenv
//   static FirebaseOptions get android => FirebaseOptions(
//     apiKey: dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '',
//     appId: dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '',
//     messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
//     projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
//     storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
//   );

//   static FirebaseOptions get ios => FirebaseOptions(
//     apiKey: dotenv.env['FIREBASE_IOS_API_KEY'] ?? '',
//     appId: dotenv.env['FIREBASE_IOS_APP_ID'] ?? '',
//     messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
//     projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
//     storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
//     iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? '',
//   );
// }















// // File generated by FlutterFire CLI.
// // ignore_for_file: type=lint
// import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
// import 'package:flutter/foundation.dart'
//     show defaultTargetPlatform, kIsWeb, TargetPlatform;
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// /// Default [FirebaseOptions] for use with your Firebase apps.
// ///
// /// Example:
// /// ```dart
// /// import 'firebase_options.dart';
// /// // ...
// /// await Firebase.initializeApp(
// ///   options: DefaultFirebaseOptions.currentPlatform,
// /// );
// /// ```
// class DefaultFirebaseOptions {
//   static FirebaseOptions get currentPlatform {
//     if (kIsWeb) {
//       return web;
//     }
//     switch (defaultTargetPlatform) {
//       case TargetPlatform.android:
//         return android;
//       case TargetPlatform.iOS:
//         return ios;
//       case TargetPlatform.macOS:
//         throw UnsupportedError(
//           'DefaultFirebaseOptions have not been configured for macos - '
//           'you can reconfigure this by running the FlutterFire CLI again.',
//         );
//       case TargetPlatform.windows:
//         throw UnsupportedError(
//           'DefaultFirebaseOptions have not been configured for windows - '
//           'you can reconfigure this by running the FlutterFire CLI again.',
//         );
//       case TargetPlatform.linux:
//         throw UnsupportedError(
//           'DefaultFirebaseOptions have not been configured for linux - '
//           'you can reconfigure this by running the FlutterFire CLI again.',
//         );
//       default:
//         throw UnsupportedError(
//           'DefaultFirebaseOptions are not supported for this platform.',
//         );
//     }
//   }

//   static FirebaseOptions get web => FirebaseOptions(
//         apiKey: dotenv.env['FIREBASE_WEB_API_KEY'] ?? '',
//         appId: dotenv.env['FIREBASE_WEB_APP_ID'] ?? '',
//         messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
//         projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
//         authDomain: dotenv.env['FIREBASE_WEB_AUTH_DOMAIN'] ?? '',
//         storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
//       );

//   static FirebaseOptions get android => FirebaseOptions(
//         apiKey: dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '',
//         appId: dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '',
//         messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
//         projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
//         storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
//       );

//   static FirebaseOptions get ios => FirebaseOptions(
//         apiKey: dotenv.env['FIREBASE_IOS_API_KEY'] ?? '',
//         appId: dotenv.env['FIREBASE_IOS_APP_ID'] ?? '',
//         messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
//         projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
//         storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
//         iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? '',
//       );
// }


// // static FirebaseOptions get web => FirebaseOptions(
// //   apiKey: "AIzaSyDljEZjQNwTu4RbCWGMWQP41q39YDUw-JA",
// //   appId: "1:463365642651:web:d91b991907e74fbc25a93e",
// //   messagingSenderId: "463365642651",
// //   projectId: "e-kodi-dashboard",
// //   authDomain: "e-kodi-dashboard.firebaseapp.com",
// //   storageBucket: "e-kodi-dashboard.firebasestorage.app",
// // );
