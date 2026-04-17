import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription_model.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = false;
  bool _isPremium = false;
  SubscriptionModel? _subscription;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _subscriptionService.initialize();
    _loadUserData();
  }

  @override
  void dispose() {
    _subscriptionService.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');
      
      print('📱 Subscription Screen - Loading user data');
      print('📱 User ID: ${_userId ?? "NULL"}');

      if (_userId != null) {
        final status = await _subscriptionService.getSubscriptionStatus(_userId!);
        setState(() {
          _isPremium = status['isPremium'] ?? false;
          if (status['subscription'] != null) {
            _subscription = SubscriptionModel.fromJson(status['subscription']);
          }
        });
      }
    } catch (e) {
      _showError('Failed to load subscription status');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _subscribeToPremium() async {
    print('📱 Subscribe button pressed');
    print('📱 Current User ID: ${_userId ?? "NULL"}');
    
    if (_userId == null) {
      print('❌ User ID is null - showing error');
      _showError('User not found. Please login again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get user details
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email') ?? '';
      final userName = prefs.getString('user_name') ?? '';

      // Create subscription
      print('📱 Creating subscription for user: $_userId');
      final result = await _subscriptionService.createSubscription(_userId!);

      print('📱 Create subscription result: $result');

      if (result['success'] == true) {
        final razorpaySubscriptionId = result['subscriptionId'];
        final amount = result['amount'];

        print('💳 Razorpay Subscription ID: $razorpaySubscriptionId');
        print('💳 Amount: $amount');

        if (razorpaySubscriptionId == null ||
            razorpaySubscriptionId.isEmpty) {
          _showError('Invalid subscription ID received from server');
          return;
        }

        // Open Razorpay checkout
        _subscriptionService.openCheckout(
          subscriptionId: razorpaySubscriptionId,
          amount: result['amount'],
          userEmail: userEmail,
          userName: userName,
          onSuccess: (PaymentSuccessResponse response) async {
            print('💳 Payment Success Response:');
            print('💳 Payment ID: ${response.paymentId}');
            print('💳 Order ID: ${response.orderId}');
            print('💳 Signature: ${response.signature}');
            
            // Show loading during verification
            setState(() => _isLoading = true);
            
            try {
              // Validate payment response
              if (response.paymentId == null || response.paymentId!.isEmpty ||
                  response.signature == null || response.signature!.isEmpty) {
                setState(() => _isLoading = false);
                _showError('Invalid payment response. Please contact support with Payment ID: ${response.paymentId ?? "N/A"}');
                return;
              }
              
              // Verify payment - use the stored subscription ID, not order ID
              print('🔐 Starting payment verification...');
              final verified = await _subscriptionService.verifySubscription(
                userId: _userId!,
                subscriptionId: razorpaySubscriptionId,
                paymentId: response.paymentId!,
                signature: response.signature!,
              );

              setState(() => _isLoading = false);

              if (verified) {
                // Wait a moment for database to sync
                await Future.delayed(const Duration(milliseconds: 500));
                
                // Reload user data to reflect premium status
                await _loadUserData();
                
                // Verify premium status was actually updated
                if (_isPremium) {
                  _showSuccess('Subscription activated successfully!');
                } else {
                  // Premium status not updated yet, but verification succeeded
                  _showSuccess('Payment verified! Premium status will be activated shortly.');
                  // Try reloading again after a delay
                  Future.delayed(const Duration(seconds: 2), () async {
                    await _loadUserData();
                  });
                }
              } else {
                // Payment succeeded but verification failed
                _showError(
                  'Payment received but verification failed. '
                  'Your payment has been processed. Please wait a few moments and refresh, '
                  'or contact support with Payment ID: ${response.paymentId}'
                );
                // Still reload data in case it was updated
                await _loadUserData();
              }
            } catch (e) {
              setState(() => _isLoading = false);
              print('❌ Error during verification: $e');
              _showError(
                'Error verifying payment: $e. '
                'Your payment has been processed. Please wait a few moments and refresh, '
                'or contact support with Payment ID: ${response.paymentId ?? "N/A"}'
              );
              // Still reload data in case it was updated
              await _loadUserData();
            }
          },
          onError: (PaymentFailureResponse response) {
            print('❌ Payment Error Response:');
            print('❌ Code: ${response.code}');
            print('❌ Message: ${response.message}');
            _showError('Payment failed: ${response.message}');
          },
        );
      } else {
        _showError('Failed to create subscription');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelSubscription() async {
    if (_userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your premium subscription? You will lose access to messaging features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final success = await _subscriptionService.cancelSubscription(_userId!);
        if (success) {
          _showSuccess('Subscription cancelled successfully');
          _loadUserData();
        } else {
          _showError('Failed to cancel subscription');
        }
      } catch (e) {
        _showError('Error: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Green theme color
  static const Color _themeGreen = Color(0xFF2E7D32);
  static const Color _themeGreenLight = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Subscription'),
        backgroundColor: _themeGreen,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _themeGreen))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Premium Badge — only shown when user IS premium
                        if (_isPremium) ...[
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Premium Member',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Subscription Status (premium users)
                        if (_isPremium && _subscription != null) ...[
                          _buildInfoCard(
                            'Subscription Status',
                            _subscription!.status.toUpperCase(),
                            Icons.info,
                            _themeGreen,
                          ),
                          const SizedBox(height: 15),
                          _buildInfoCard(
                            'Valid Until',
                            _formatDate(_subscription!.endDate),
                            Icons.calendar_today,
                            _themeGreenLight,
                          ),
                          if (_subscription!.nextBillingDate != null) ...[
                            const SizedBox(height: 15),
                            _buildInfoCard(
                              'Next Billing',
                              _formatDate(_subscription!.nextBillingDate!),
                              Icons.payment,
                              Colors.orange,
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],

                        // Pricing Card — shown first for non-premium users
                        if (!_isPremium) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                            decoration: BoxDecoration(
                              color: _themeGreen.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _themeGreen,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Monthly Subscription',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: const [
                                    Text(
                                      '₹',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: _themeGreen,
                                      ),
                                    ),
                                    Text(
                                      '49',
                                      style: TextStyle(
                                        fontSize: 44,
                                        fontWeight: FontWeight.bold,
                                        height: 1,
                                        color: _themeGreen,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '/month',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Features List
                        const Text(
                          'Premium Features',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem('Unlimited messaging with teachers and students'),
                        _buildFeatureItem('Direct chat access from search results'),
                        _buildFeatureItem('Real-time notifications'),
                        _buildFeatureItem('Priority support'),
                        const SizedBox(height: 20),

                        // Pricing card for premium users (shown below features)
                        if (_isPremium) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                            decoration: BoxDecoration(
                              color: _themeGreen.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _themeGreen,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Monthly Subscription',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: const [
                                    Text(
                                      '₹',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: _themeGreen,
                                      ),
                                    ),
                                    Text(
                                      '49',
                                      style: TextStyle(
                                        fontSize: 44,
                                        fontWeight: FontWeight.bold,
                                        height: 1,
                                        color: _themeGreen,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '/month',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ),

                // Sticky Action Button at bottom
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isPremium ? _cancelSubscription : _subscribeToPremium,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPremium ? Colors.red : _themeGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        _isPremium ? 'Cancel Subscription' : 'Subscribe Now',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: _themeGreen,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
