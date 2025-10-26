import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  late Razorpay _razorpay;
  Function(PaymentSuccessResponse)? _onPaymentSuccess;
  Function(PaymentFailureResponse)? _onPaymentError;

  void initialize() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('✅✅✅ PAYMENT SUCCESS ✅✅✅');
    print('✅ Payment ID: ${response.paymentId}');
    print('✅ Order ID: ${response.orderId}');
    print('✅ Signature: ${response.signature}');
    
    if (_onPaymentSuccess != null) {
      _onPaymentSuccess!(response);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('❌❌❌ PAYMENT ERROR ❌❌❌');
    print('❌ Code: ${response.code}');
    print('❌ Message: ${response.message}');
    print('❌ Error: ${response.error}');
    
    if (_onPaymentError != null) {
      _onPaymentError!(response);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
  }

  // Create subscription
  Future<Map<String, dynamic>> createSubscription(String userId) async {
    try {
      print('💳 Creating subscription for user: $userId');
      print('💳 Endpoint: ${ApiConfig.subscriptionCreate}');
      
      final response = await http.post(
        Uri.parse(ApiConfig.subscriptionCreate),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'planType': 'monthly',
        }),
      );

      print('💳 Response status: ${response.statusCode}');
      print('💳 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Failed to create subscription: ${response.body}');
        throw Exception('Failed to create subscription');
      }
    } catch (e) {
      print('❌ Error creating subscription: $e');
      throw Exception('Error creating subscription: $e');
    }
  }

  // Open Razorpay checkout
  void openCheckout({
    required String subscriptionId,
    required int amount,
    required String userEmail,
    required String userName,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
  }) {
    _onPaymentSuccess = onSuccess;
    _onPaymentError = onError;

    print('💳 Opening Razorpay checkout');
    print('💳 Subscription ID: $subscriptionId');
    print('💳 Amount: $amount');
    print('💳 Email: $userEmail');
    print('💳 Name: $userName');

    var options = {
      'key': 'rzp_test_RY4swUGd5MvV6L', // Razorpay test key
      'subscription_id': subscriptionId,
      'amount': amount,
      'currency': 'INR',
      'name': 'FindMyTutor Premium',
      'description': 'Monthly Premium Subscription',
      'prefill': {
        'email': userEmail,
        'contact': '',
      },
      'theme': {
        'color': '#6C63FF',
      }
    };

    try {
      _razorpay.open(options);
      print('✅ Razorpay checkout opened successfully');
    } catch (e) {
      print('❌ Error opening Razorpay: $e');
    }
  }

  // Verify subscription payment
  Future<bool> verifySubscription({
    required String userId,
    required String subscriptionId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      print('🔐 ========== VERIFYING PAYMENT ==========');
      print('🔐 User ID: $userId');
      print('🔐 Subscription ID: $subscriptionId');
      print('🔐 Payment ID: $paymentId');
      print('🔐 Signature: $signature');
      print('🔐 Endpoint: ${ApiConfig.subscriptionVerify}');
      
      final requestBody = {
        'userId': userId,
        'razorpay_subscription_id': subscriptionId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      };
      
      print('🔐 Request Body: $requestBody');
      
      final response = await http.post(
        Uri.parse(ApiConfig.subscriptionVerify),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      print('🔐 Verify response status: ${response.statusCode}');
      print('🔐 Verify response body: ${response.body}');
      print('🔐 ========================================');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update local premium status
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isPremium', true);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error verifying subscription: $e');
      return false;
    }
  }

  // Get subscription status
  Future<Map<String, dynamic>> getSubscriptionStatus(String userId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.subscriptionStatus(userId)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Update local premium status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isPremium', data['isPremium'] ?? false);
        
        return data;
      } else {
        throw Exception('Failed to get subscription status');
      }
    } catch (e) {
      throw Exception('Error getting subscription status: $e');
    }
  }

  // Cancel subscription
  Future<bool> cancelSubscription(String userId) async {
    try {
      print('❌ Cancelling subscription for user: $userId');
      
      final response = await http.post(
        Uri.parse(ApiConfig.subscriptionCancel),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
      
      print('❌ Cancel response status: ${response.statusCode}');
      print('❌ Cancel response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update local premium status
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isPremium', false);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error cancelling subscription: $e');
      return false;
    }
  }

  // Check if user is premium
  Future<bool> isPremiumUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('isPremium') ?? false;
    } catch (e) {
      return false;
    }
  }
}
