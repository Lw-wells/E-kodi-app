// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this for dotenv

// import 'config/routes.dart';
// import 'config/theme.dart';
// import 'firebase_options.dart'; // ✅ Fixed import path

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//   try {
//     // Load environment variables
//     await dotenv.load();
//     print('✅ Environment variables loaded');
    
//     // Initialize Hive
//     await Hive.initFlutter();
//     print('✅ Hive initialized');
    
//     // Initialize Firebase
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//     print('✅ Firebase initialized for ${kIsWeb ? 'web' : 'mobile'}');
    
//   } catch (e, stackTrace) {
//     print('❌ Initialization error: $e');
//     print('Stack trace: $stackTrace');
//   }

//   runApp(
//     const ProviderScope(
//       child: EKodiApp(),
//     ),
//   );
// }

// class EKodiApp extends ConsumerWidget {
//   const EKodiApp({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return MaterialApp.router(
//       title: 'E-Kodi',
//       theme: AppTheme.lightTheme,
//       darkTheme: AppTheme.darkTheme,
//       themeMode: ThemeMode.system,
//       routerConfig: AppRoutes.router,
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }

























// // import 'package:flutter/material.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:hive_flutter/hive_flutter.dart';
// // import 'package:firebase_core/firebase_core.dart';

// // import 'config/routes.dart';
// // import 'config/theme.dart';
// // import 'config/firebase_options.dart'; // Uncomment when generated

// // void main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
  
// //   // Initialize Hive
// //   await Hive.initFlutter();
  
// //   // Initialize Firebase
// //   // await Firebase.initializeApp(
// //   //   options: DefaultFirebaseOptions.currentPlatform,
// //   // );

// //   runApp(
// //     const ProviderScope(
// //       child: EKodiApp(),
// //     ),
// //   );
// // }

// // class EKodiApp extends ConsumerWidget {
// //   const EKodiApp({super.key});

// //   @override
// //   Widget build(BuildContext context, WidgetRef ref) {
// //     return MaterialApp.router(
// //       title: 'E-Kodi',
// //       theme: AppTheme.lightTheme,
// //       darkTheme: AppTheme.darkTheme,
// //       themeMode: ThemeMode.system,
// //       routerConfig: AppRoutes.router,
// //       debugShowCheckedModeBanner: false,
// //     );
// //   }
// // }


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables - this is crucial!
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded');
    print('🔑 Project ID: ${dotenv.env['FIREBASE_PROJECT_ID']}');
    
    // Initialize Hive
    await Hive.initFlutter();
    print('✅ Hive initialized');
    
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized for ${kIsWeb ? 'web' : 'mobile'}');
    
  } catch (e, stackTrace) {
    print('❌ Initialization error: $e');
    print('Stack trace: $stackTrace');
  }

  runApp(
    const ProviderScope(
      child: EKodiApp(),
    ),
  );
}

class EKodiApp extends ConsumerWidget {
  const EKodiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'E-Kodi',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRoutes.router,
      debugShowCheckedModeBanner: false,
    );
  }
}