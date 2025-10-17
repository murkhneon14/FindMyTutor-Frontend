import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding/onboarding_screen.dart';
import 'auth/auth_choice_screen.dart';
import 'home/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
    final authToken = prefs.getString('auth_token');
    final isLoggedIn = authToken != null && authToken.isNotEmpty;
    
    // Add a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Widget nextScreen;
      
      if (!hasCompletedOnboarding) {
        // First time - show onboarding
        nextScreen = const OnboardingScreen();
      } else if (isLoggedIn) {
        // Already logged in - go to main app
        nextScreen = const MainNavigation();
      } else {
        // Onboarding done but not logged in - show auth screen
        nextScreen = const AuthChoiceScreen();
      }
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_rounded,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'FindMyTutor',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
