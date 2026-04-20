import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart' show ThemeNotifier, AppTheme;
import '../../config/api.dart';
import '../auth/auth_choice_screen.dart';
import 'main_navigation.dart';
import 'profile_details_screen.dart';
import 'faq_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';
import '../subscription/subscription_screen.dart';
import '../../services/auth_service.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isLoggedIn = false; // This would come from your auth state management
  bool _loading = false;
  bool _isPremium = false;
  SubscriptionModel? _subscription;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final hasToken = token != null && token.isNotEmpty;
    setState(() {
      _isLoggedIn = hasToken;
    });
    if (hasToken) {
      await _fetchMe(token!);
    }
    // Check premium status and fetch subscription details
    final isPremium = await SubscriptionService().isPremiumUser();
    if (mounted) {
      setState(() => _isPremium = isPremium);
    }
    if (isPremium) {
      await _fetchSubscriptionDetails();
    }
  }

  Future<void> _fetchMe(String token) async {
    setState(() {
      _loading = true;
    });
    try {
      print('🔍 Fetching user profile from: ${ApiConfig.me}');
      final response = await http.get(
        Uri.parse(ApiConfig.me),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('👤 Profile response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>?;
        print(
          '✅ User profile loaded: ${user?['_id']} - ${user?['name']} (${user?['email']})',
        );
        setState(() {
          _user = user;
        });
      } else {
        print('❌ Failed to fetch profile: ${response.statusCode}');
        // If token invalid, treat as logged out
        setState(() {
          _isLoggedIn = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching profile: $e');
      // network error - keep prior state
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchSubscriptionDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return;

      final status = await SubscriptionService().getSubscriptionStatus(userId);
      if (status['subscription'] != null && mounted) {
        setState(() {
          _subscription = SubscriptionModel.fromJson(status['subscription']);
        });
      }
    } catch (e) {
      print('❌ Error fetching subscription details: $e');
    }
  }

  Widget _buildSubscriptionStatusCard() {
    final endDate = _subscription != null
        ? '${_subscription!.endDate.day}/${_subscription!.endDate.month}/${_subscription!.endDate.year}'
        : 'N/A';
    final status = _subscription?.status.toUpperCase() ?? 'ACTIVE';

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
      ).then((_) => _bootstrap()),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF059669),
              Color(0xFF10B981),
              Color(0xFF34D399),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, color: Colors.amber[300], size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              'PREMIUM ACTIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You\'re a Premium Member! ✨',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Valid until: $endDate',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn ? _buildProfileView() : _buildAuthView();
  }

  Widget _buildAuthView() {
    // Use a FutureBuilder to handle the initial auth check
    return FutureBuilder<bool>(
      future: _checkAuthStatus(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth status
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If not logged in, show the AuthChoiceScreen with bottom navigation
        return AuthChoiceScreen(
          showBackButton: false, // Don't show back button in bottom nav flow
          onLoginSuccess: () {
            // After successful login, navigate to Explore tab (index 1)
            if (mounted) {
              // This assumes the parent widget has a way to change tabs
              // You might need to adjust this based on your actual app's navigation structure
              // Pop all routes and navigate to main navigation with Explore tab selected
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 1),
                ),
                (route) => false,
              );
            }
          },
        );
      },
    );
  }

  Future<bool> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  void _showProfileDetails(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final height = isLandscape
        ? 0.8
        : 0.7; // Use 80% height in landscape, 70% in portrait

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: mediaQuery.size.height * height,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Draggable handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Main content
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: ProfileDetailsScreen(
                  user: _user,
                  onProfileUpdated: () {
                    Navigator.pop(context);
                    _bootstrap(); // Refresh user data
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Text(
                  'My Profile',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text: 'Check out FindMyTutor - Find the best tutors near you!\n\nhttps://play.google.com/store/apps/details?id=com.findmytutor.app&hl=en_IN',
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Profile Card (tappable)
            InkWell(
              onTap: () => _showProfileDetails(context),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_loading)
                            const SizedBox(
                              height: 22,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.white24,
                                color: Colors.white,
                              ),
                            )
                          else
                            Text(
                              (_user != null
                                  ? (_user!['name'] as String? ?? 'User')
                                  : 'User'),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          if (!_loading && _user != null && _user!['phone'] != null && (_user!['phone'] as String).isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _user!['phone'] as String,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            (_user != null
                                ? (_user!['email'] as String? ?? '')
                                : ''),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Premium status card for premium users, or promo card for free users
            if (_isPremium) ...[
              _buildSubscriptionStatusCard(),
              const SizedBox(height: 16),
            ] else ...[
              _buildPremiumPromotionalCard(),
              const SizedBox(height: 16),
            ],
            // Advertisement Banner
            _buildAdvertisementBanner(),
            const SizedBox(height: 20),
            // Menu Items (hide Premium upgrade for premium users)
            if (!_isPremium)
              _buildMenuItem(
                Icons.workspace_premium,
                'Premium',
                'Upgrade to unlock premium features',
                () => _showPremiumDialog(context),
                isPremium: true,
              ),
            _buildMenuItem(
              Icons.help_outline,
              'FAQ',
              'Frequently asked questions',
              () => _navigateToFAQ(context),
            ),
            _buildMenuItem(
              Icons.privacy_tip_outlined,
              'Privacy Policy',
              'Read our privacy policy',
              () => _navigateToPrivacyPolicy(context),
            ),
            _buildMenuItem(
              Icons.description_outlined,
              'Terms & Conditions',
              'Read our terms and conditions',
              () => _navigateToTerms(context),
            ),
            _buildMenuItem(
              Icons.info_outline,
              'About Us',
              'Learn more about FindMyTutor',
              () => _showAboutDialog(context),
            ),
            // Dark Mode Toggle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(
                      255,
                      208,
                      85,
                      85,
                    ).withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Consumer<ThemeNotifier>(
                      builder: (context, themeNotifier, _) {
                        final isDarkMode = themeNotifier.isDarkMode;
                        return Icon(
                          isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: isDarkMode
                              ? Colors.amber
                              : Theme.of(context).primaryColor,
                          size: 24,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dark Mode',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Switch between light and dark theme',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Consumer<ThemeNotifier>(
                    builder: (context, themeNotifier, _) {
                      return Switch(
                        value: themeNotifier.isDarkMode,
                        onChanged: (bool value) {
                          themeNotifier.toggleTheme(value);
                        },
                        activeColor: Theme.of(context).primaryColor,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () async {
                  await AuthService().signOut();
                  setState(() {
                    _isLoggedIn = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: BorderSide(color: AppTheme.errorColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumPromotionalCard() {
    return InkWell(
      onTap: () => _showPremiumDialog(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B46C1), // Purple
              Color(0xFF9333EA), // Violet
              Color(0xFFEC4899), // Pink
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9333EA).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              color: Colors.amber[300],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'PREMIUM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unlock Premium\nFeatures Today! 🚀',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Get unlimited access to all tutors, priority support, and exclusive features',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6120D4),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '₹49/month',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: Color(0xFF6120D4),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvertisementBanner() {
    return InkWell(
      onTap: () async {
        final url = Uri.parse('https://wa.me/918798053612?text=Hi%2C%20I%20want%20to%20advertise%20on%20FindMyTutor');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0EA5E9), // Sky blue
              Color(0xFF2563EB), // Blue
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative pattern
            Positioned(
              right: -10,
              top: -10,
              child: Icon(
                Icons.school_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Icon(
                Icons.campaign_rounded,
                size: 100,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '📢 ADVERTISE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Promote Your School, College,\nCoaching, Institute, Study Hub,\nPG, or Educational Event Here!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect with Students and Parents Instantly and Grow Your Reach Today!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.chat,
                        color: Color(0xFF25D366),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '+91 8798053612',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isPremium = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: isPremium ? AppTheme.primaryGradient : null,
        color: isPremium ? null : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isPremium
                ? AppTheme.primaryColor.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: isPremium ? 12 : 10,
            offset: Offset(0, isPremium ? 6 : 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPremium
                ? Colors.white.withOpacity(0.2)
                : AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isPremium ? Colors.white : AppTheme.primaryColor,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isPremium ? Colors.white : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: isPremium ? Colors.white70 : AppTheme.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isPremium ? Colors.white : null,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Go Premium'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unlock premium features:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildPremiumFeature('✨ Unlimited tutor searches'),
            _buildPremiumFeature('💬 Priority chat support'),
            _buildPremiumFeature('🔔 Instant notifications'),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    'Premium Plan',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹49/month',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Maybe Later'),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionScreen(),
                          ),
                        ).then((_) => _bootstrap());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Upgrade Now',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: const TextStyle(fontSize: 15)),
    );
  }

  void _navigateToFAQ(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FAQScreen()),
    );
  }

  void _navigateToPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
    );
  }

  void _navigateToTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsScreen()),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: Row(
          children: [
            Icon(Icons.school_rounded, color: AppTheme.primaryColor, size: 28),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'About FindMyTutor',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // About Us
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'About Us',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Find My Tutor is a reliable Educational platform designed to connect students and parents with qualified academic tutors and skill-based mentors. From academic subjects to specialized skills like music, baking, and more, learners can easily find and connect with the right educators based on their needs.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  '"Discover the Mentor Within Your Reach"',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'We make it easier for learners to access trusted guidance and begin their learning journey with confidence.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                // Mission
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Mission',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  const TextSpan(
                    style: TextStyle(fontSize: 13, height: 1.5),
                    children: [
                      TextSpan(
                        text: 'To make quality education accessible and connect students with trusted tutors nearby. We are committed to empowering teachers by providing a platform that promotes ',
                      ),
                      TextSpan(
                        text: 'freelancing opportunities',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ', financial independence, and professional growth\u2014allowing educators to teach with flexibility and purpose.\n\nWith a vision of ',
                      ),
                      TextSpan(
                        text: '\u201cHar Ghar Education\u201d',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      TextSpan(
                        text: ', we aim to bring learning to every home and create equal opportunities for all. Together, we are building a future where ',
                      ),
                      TextSpan(
                        text: 'every student finds the right guide, and every teacher finds the right platform.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Vision
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Vision',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'We strive to build a system where education is not limited by location, time, or resources, but is driven by accessibility, innovation, and trust.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Version: 1.0.0',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                const Text(
                  '© 2025 FindMyTutor. All rights reserved.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
