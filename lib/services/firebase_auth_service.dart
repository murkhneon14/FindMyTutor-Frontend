import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';
import 'fcm_service.dart';

/// Service to handle Firebase Phone Authentication (production).
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  int? _resendToken;
  bool _isVerifying = false;

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Check if a phone number is already registered in our backend
  Future<Map<String, dynamic>> checkPhoneExists(String phone) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.checkPhone),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'exists': false, 'error': 'Failed to check phone'};
    } catch (e) {
      debugPrint('Check phone error: $e');
      return {'exists': false, 'error': e.toString()};
    }
  }

  /// Send OTP to phone number using Firebase
  Future<Map<String, dynamic>> sendOTP({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String error) onError,
    required Function(PhoneAuthCredential credential) onAutoVerified,
    int? forceResendingToken,
  }) async {
    try {
      _isVerifying = true;

      // Normalize phone number - ensure it has +91 prefix
      String normalizedPhone = phoneNumber.trim();
      if (!normalizedPhone.startsWith('+')) {
        normalizedPhone = '+91$normalizedPhone';
      }

      debugPrint('Sending OTP to: $normalizedPhone');

      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('Auto verification completed');
          _isVerifying = false;
          onAutoVerified(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Verification failed: ${e.code} - ${e.message}');
          _isVerifying = false;

          String errorMessage = 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number format';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many requests. Please try again later';
          } else if (e.code == 'quota-exceeded') {
            errorMessage = 'SMS quota exceeded. Please try again later';
          } else if (e.message != null && e.message!.contains('BILLING_NOT_ENABLED')) {
            errorMessage = 'Phone verification is not available. Please try again later.';
          } else if (e.message != null && e.message!.toLowerCase().contains('recaptcha')) {
            errorMessage = 'Verification is temporarily unavailable. Please try again later.';
          } else {
            errorMessage = e.message ?? 'Verification failed';
          }

          onError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('OTP sent successfully. Verification ID: $verificationId');
          _verificationId = verificationId;
          _resendToken = resendToken;
          _isVerifying = false;
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto retrieval timeout');
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendingToken,
      );

      return {'success': true};
    } catch (e) {
      _isVerifying = false;
      debugPrint('Send OTP error: $e');
      onError(e.toString());
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify OTP and sign in with Firebase
  Future<Map<String, dynamic>> verifyOTP({
    required String otp,
    String? verificationId,
  }) async {
    try {
      final vId = verificationId ?? _verificationId;
      
      if (vId == null) {
        return {'success': false, 'error': 'Verification ID not found. Please request OTP again.'};
      }

      debugPrint('Verifying OTP...');

      // Create credential
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: vId,
        smsCode: otp,
      );

      // Sign in with credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        debugPrint('Firebase sign in successful. UID: ${userCredential.user!.uid}');
        return {
          'success': true,
          'user': userCredential.user,
          'isNewUser': userCredential.additionalUserInfo?.isNewUser ?? false,
        };
      }

      return {'success': false, 'error': 'Failed to verify OTP'};
    } on FirebaseAuthException catch (e) {
      debugPrint('Verify OTP error: ${e.code} - ${e.message}');
      
      String errorMessage = 'Invalid OTP';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Invalid OTP. Please check and try again';
      } else if (e.code == 'session-expired') {
        errorMessage = 'OTP expired. Please request a new one';
      }
      
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      debugPrint('Verify OTP error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Authenticate with backend using Firebase ID token
  /// This handles both login and registration
  Future<Map<String, dynamic>> authenticateWithBackend({
    required User firebaseUser,
    String? name,
    String? role,
  }) async {
    try {
      // Get Firebase ID token
      String? idToken = await firebaseUser.getIdToken();
      
      if (idToken == null) {
        return {'success': false, 'error': 'Failed to get Firebase token'};
      }

      debugPrint('Authenticating with backend...');

      final body = <String, dynamic>{
        'firebaseToken': idToken,
      };

      // Include name and role for new users
      if (name != null) body['name'] = name;
      if (role != null) body['role'] = role;

      final response = await http.post(
        Uri.parse(ApiConfig.authenticate),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('Backend response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        final user = data['user'] as Map<String, dynamic>?;
        final isNewUser = data['isNewUser'] as bool? ?? false;

        if (token != null) {
          // Save token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);

          // Save user info
          if (user != null) {
            final userId = user['_id']?.toString();
            final userName = user['name']?.toString();
            final userPhone = user['phone']?.toString();
            final userEmail = user['email']?.toString();
            final userRole = user['role']?.toString();

            if (userId != null) await prefs.setString('user_id', userId);
            if (userName != null) await prefs.setString('user_name', userName);
            if (userPhone != null) await prefs.setString('user_phone', userPhone);
            if (userEmail != null) await prefs.setString('user_email', userEmail);
            if (userRole != null) await prefs.setString('user_role', userRole);

            debugPrint('Saved user data: ID=$userId, Name=$userName, Phone=$userPhone, Role=$userRole');

            // Send FCM token to backend
            if (userId != null) {
              await FCMService().sendTokenToServer(userId);
            }
          }

          return {
            'success': true,
            'token': token,
            'user': user,
            'isNewUser': isNewUser,
            'message': data['message'],
          };
        }
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        if (data['isNewUser'] == true || data['requiresProfile'] == true) {
          return {
            'success': false,
            'requiresProfile': true,
            'message': data['message'],
          };
        }
        return {'success': false, 'error': data['message'] ?? 'Authentication failed'};
      }

      return {'success': false, 'error': 'Authentication failed'};
    } catch (e) {
      debugPrint('Backend auth error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Sign out from Firebase and clear local data
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      
      final prefs = await SharedPreferences.getInstance();
      
      // Save non-user preferences
      final isDarkMode = prefs.getBool('isDarkMode');
      final hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding');
      
      // Clear all cached data completely
      await prefs.clear();
      
      // Restore non-user preferences
      if (isDarkMode != null) {
        await prefs.setBool('isDarkMode', isDarkMode);
      }
      if (hasCompletedOnboarding != null) {
        await prefs.setBool('hasCompletedOnboarding', hasCompletedOnboarding);
      }
      
      debugPrint('User signed out completely');
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Get stored verification ID (for resend)
  String? get verificationId => _verificationId;
  
  /// Get resend token
  int? get resendToken => _resendToken;
  
  /// Check if verification is in progress
  bool get isVerifying => _isVerifying;
}
