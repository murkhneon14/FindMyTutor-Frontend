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
    print('🟦 Splash -> hasCompletedOnboarding=$hasCompletedOnboarding isLoggedIn=$isLoggedIn');
    
    // Add a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Widget nextScreen;
      
      if (!hasCompletedOnboarding) {
        // First time - show onboarding
        nextScreen = const OnboardingScreen();
        print('➡️ Navigating to Onboarding');
      } else if (isLoggedIn) {
        // Already logged in - go to main app
        nextScreen = const MainNavigation();
        print('➡️ Navigating to MainNavigation');
      } else {
        // Onboarding done but not logged in - show auth screen
        nextScreen = const AuthChoiceScreen();
        print('➡️ Navigating to AuthChoiceScreen');
      }
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: screenWidth * 0.6,
              ),
              SizedBox(height: screenHeight * 0.03),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
