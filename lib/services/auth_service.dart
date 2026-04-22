import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';
import 'fcm_service.dart';

/// Service to handle OTP Authentication via Message Central (backend).
/// Replaces the old Firebase Phone Auth approach.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _verificationId;
  bool _isVerifying = false;

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

  /// Send OTP to phone number via backend (Message Central)
  Future<Map<String, dynamic>> sendOTP({
    required String phoneNumber,
  }) async {
    try {
      _isVerifying = true;

      // Clean phone number — just digits, no +91 prefix
      String cleanPhone = phoneNumber.trim();
      if (cleanPhone.startsWith('+91')) {
        cleanPhone = cleanPhone.substring(3);
      } else if (cleanPhone.startsWith('+')) {
        cleanPhone = cleanPhone.substring(1);
      }

      debugPrint('Sending OTP to: $cleanPhone');

      final response = await http.post(
        Uri.parse(ApiConfig.sendOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': cleanPhone,
          'countryCode': '91',
        }),
      );

      _isVerifying = false;

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['verificationId'] != null) {
        _verificationId = data['verificationId'] as String;
        debugPrint('OTP sent successfully. Verification ID: $_verificationId');
        return {
          'success': true,
          'verificationId': _verificationId,
          'timeout': data['timeout'],
          'message': data['message'] ?? 'OTP sent successfully',
        };
      } else {
        debugPrint('Send OTP failed: ${data['message']}');
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      _isVerifying = false;
      debugPrint('Send OTP error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify OTP and authenticate with backend
  /// This handles both login and registration
  Future<Map<String, dynamic>> verifyOTPAndAuthenticate({
    required String otp,
    required String phone,
    String? verificationId,
    String? name,
    String? role,
  }) async {
    try {
      final vId = verificationId ?? _verificationId;

      if (vId == null) {
        return {
          'success': false,
          'error': 'Verification ID not found. Please request OTP again.'
        };
      }

      // Normalize phone for backend
      String normalizedPhone = phone.trim();
      if (!normalizedPhone.startsWith('+')) {
        normalizedPhone = '+91$normalizedPhone';
      }

      debugPrint('Verifying OTP for $normalizedPhone...');

      final body = <String, dynamic>{
        'verificationId': vId,
        'code': otp,
        'phone': normalizedPhone,
      };

      // Include name and role for new user registration
      if (name != null && name.isNotEmpty) body['name'] = name;
      if (role != null && role.isNotEmpty) body['role'] = role;

      final response = await http.post(
        Uri.parse(ApiConfig.verifyOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('Verify OTP response: ${response.statusCode}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = data['token'] as String?;
        final user = data['user'] as Map<String, dynamic>?;
        final isNewUser = data['isNewUser'] as bool? ?? false;
        final requiresProfile = data['requiresProfile'] as bool? ?? false;

        if (requiresProfile) {
          // OTP verified but user needs to register (no name/role was provided)
          return {
            'success': true,
            'requiresProfile': true,
            'phone': data['phone'] ?? normalizedPhone,
            'message': data['message'],
          };
        }

        if (token != null) {
          // Save token and user info
          await _saveUserData(token, user);

          return {
            'success': true,
            'token': token,
            'user': user,
            'isNewUser': isNewUser,
            'message': data['message'],
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': data['message'] ?? 'Invalid or expired OTP',
        };
      }

      return {
        'success': false,
        'error': data['message'] ?? 'Verification failed',
      };
    } catch (e) {
      debugPrint('Verify OTP error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Complete registration for new users (after OTP verification)
  Future<Map<String, dynamic>> completeRegistration({
    required String phone,
    required String name,
    required String role,
  }) async {
    try {
      String normalizedPhone = phone.trim();
      if (!normalizedPhone.startsWith('+')) {
        normalizedPhone = '+91$normalizedPhone';
      }

      final response = await http.post(
        Uri.parse(ApiConfig.completeRegistration),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': normalizedPhone,
          'name': name,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final token = data['token'] as String?;
        final user = data['user'] as Map<String, dynamic>?;

        if (token != null) {
          await _saveUserData(token, user);

          return {
            'success': true,
            'token': token,
            'user': user,
            'isNewUser': true,
            'message': data['message'],
          };
        }
      }

      return {
        'success': false,
        'error': data['message'] ?? 'Registration failed',
      };
    } catch (e) {
      debugPrint('Complete registration error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Save user data to SharedPreferences
  Future<void> _saveUserData(String token, Map<String, dynamic>? user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);

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
      if (user['isPremium'] != null) await prefs.setBool('isPremium', user['isPremium'] == true);

      debugPrint(
          'Saved user data: ID=$userId, Name=$userName, Phone=$userPhone, Role=$userRole, isPremium=${user['isPremium']}');

      // Send FCM token to backend
      if (userId != null) {
        await FCMService().sendTokenToServer(userId);
      }
    }
  }

  /// Sign out and clear local data
  Future<void> signOut() async {
    try {
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

  /// Check if verification is in progress
  bool get isVerifying => _isVerifying;
}
