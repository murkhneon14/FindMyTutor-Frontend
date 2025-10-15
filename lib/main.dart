import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:overlay_support/overlay_support.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'config/theme.dart' show ThemeNotifier, AppTheme;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Load theme preference before running the app
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  
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
            title: 'FindMyTutor',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const OnboardingScreen(),
          ),
        );
      },
    );
  }
}
