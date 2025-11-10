import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/splash_screen.dart';
import 'config/theme.dart' show ThemeNotifier, AppTheme;
import 'config/navigator_key.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Load theme preference before running the app
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  
  // Initialize Firebase and messaging defensively so UI is not blocked on errors
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized');
  } catch (e, s) {
    // Do not block app startup if Firebase fails to init
    print('❌ Firebase initialize failed: $e');
    print(s);
  }

  try {
    // Set up background message handler (safe to call even if init failed)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {
    // ignore if messaging is unavailable
  }

  try {
    await FCMService().initialize();
  } catch (e, s) {
    print('❌ FCMService initialize failed: $e');
    print(s);
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier()..setDarkMode(isDarkMode),
      child: const FindMyTutorApp(),
    ),
  );
}

class FindMyTutorApp extends StatelessWidget {
  const FindMyTutorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return OverlaySupport.global(
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: 'FindMyTutor',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
