// This file is deprecated and kept for reference only.
// OTP verification is now handled directly in signup_screen.dart and login_screen.dart
// using Firebase Phone Authentication.
//
// The OTP verification flow is integrated into the respective screens:
// - signup_screen.dart: Phone verification during signup
// - login_screen.dart: Phone verification during login
//
// Firebase handles OTP sending and verification via:
// - FirebaseAuth.instance.verifyPhoneNumber()
// - PhoneAuthProvider.credential()
// - FirebaseAuth.instance.signInWithCredential()

// ignore_for_file: unused_import
import 'package:flutter/material.dart';

/// @deprecated This widget is no longer used.
/// OTP verification is now handled within signup_screen.dart and login_screen.dart
class OTPVerificationDialog extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;

  const OTPVerificationDialog({
    super.key,
    required this.email,
    required this.onVerified,
  });

  @override
  State<OTPVerificationDialog> createState() => _OTPVerificationDialogState();
}

class _OTPVerificationDialogState extends State<OTPVerificationDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Deprecated'),
      content: const Text(
        'This dialog is deprecated. OTP verification is now handled via Firebase Phone Authentication in the signup/login screens.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
