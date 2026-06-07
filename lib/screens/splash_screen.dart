import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'onboarding/onboarding_screen.dart';
import 'auth/auth_choice_screen.dart';
import 'auth/signup_step2_screen.dart';
import 'home/main_navigation.dart';
import '../config/api.dart';

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
        // Check if profile is complete before going to main app
        nextScreen = await _getNextScreenForLoggedInUser(authToken!);
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

  /// Check if the logged-in user has completed their profile.
  /// If not, redirect them to SignupStep2Screen to finish setup.
  Future<Widget> _getNextScreenForLoggedInUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.me),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>?;

        if (user != null) {
          final role = user['role']?.toString() ?? 'student';
          final hasTeacherProfile = user['teacherProfile'] != null;
          final hasStudentProfile = user['studentProfile'] != null;

          final isProfileComplete =
              (role == 'teacher' && hasTeacherProfile) ||
              (role == 'student' && hasStudentProfile);

          if (!isProfileComplete) {
            print('⚠️ Profile incomplete — redirecting to SignupStep2');
            return SignupStep2Screen(
              name: user['name']?.toString() ?? '',
              phone: user['phone']?.toString() ?? '',
              userType: role,
            );
          }
        }
      } else if (response.statusCode == 401) {
        // Token expired/invalid — clear it and go to auth
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        print('🔑 Token invalid — redirecting to AuthChoiceScreen');
        return const AuthChoiceScreen();
      }
    } catch (e) {
      print('❌ Profile check failed: $e — proceeding to MainNavigation');
    }

    // Default: profile is complete or check failed, go to main app
    print('➡️ Navigating to MainNavigation');
    return const MainNavigation();
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
