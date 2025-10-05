// This is a basic Flutter widget test for the FindMyTutor app.
// It verifies that the main app loads and displays the onboarding screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_tutor/main.dart';
import 'package:find_my_tutor/screens/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('App loads and shows onboarding screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FindMyTutorApp());

    // Verify that the app title is shown
    expect(find.text('FindMyTutor'), findsOneWidget);
    
    // Verify that the onboarding screen is shown
    expect(find.byType(OnboardingScreen), findsOneWidget);
    
    // You can add more specific tests here based on your OnboardingScreen content
    // For example, if you have a 'Get Started' button:
    // expect(find.text('Get Started'), findsOneWidget);
  });
}
