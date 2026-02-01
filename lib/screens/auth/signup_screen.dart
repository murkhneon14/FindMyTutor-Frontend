import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import 'signup_step2_screen.dart';
import '../../services/firebase_auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _userType = 'student'; // 'student' or 'teacher'
  bool _isLoading = false;
  bool _otpSent = false;
  String? _verificationId;
  int? _resendToken;
  
  // OTP controllers
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  int _resendCountdown = 0;
  bool _canResend = false;
  bool _isResending = false;

  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
          if (_resendCountdown > 0) {
            _startResendCountdown();
          } else {
            _canResend = true;
          }
        });
      }
    });
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final phone = _phoneController.text.trim();

    await _authService.sendOTP(
      phoneNumber: phone,
      forceResendingToken: _resendToken,
      onCodeSent: (verificationId, resendToken) {
        setState(() {
          _isLoading = false;
          _otpSent = true;
          _verificationId = verificationId;
          _resendToken = resendToken;
        });
        _startResendCountdown();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent to your phone number'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      },
      onError: (error) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      },
      onAutoVerified: (credential) async {
        // Auto verification (Android only)
        setState(() => _isLoading = true);
        await _handleCredential(credential);
      },
    );
  }

  Future<void> _resendOTP() async {
    if (!_canResend || _isResending) return;

    setState(() => _isResending = true);

    await _authService.sendOTP(
      phoneNumber: _phoneController.text.trim(),
      forceResendingToken: _resendToken,
      onCodeSent: (verificationId, resendToken) {
        setState(() {
          _isResending = false;
          _verificationId = verificationId;
          _resendToken = resendToken;
        });
        _startResendCountdown();
        
        // Clear OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP resent to your phone number'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      },
      onError: (error) {
        setState(() => _isResending = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      },
      onAutoVerified: (credential) async {
        setState(() => _isResending = false);
        await _handleCredential(credential);
      },
    );
  }

  Future<void> _verifyOTP() async {
    // Check if all OTP fields are filled
    for (var controller in _otpControllers) {
      if (controller.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the complete OTP')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final otp = _otpControllers.map((c) => c.text).join();

    final result = await _authService.verifyOTP(
      otp: otp,
      verificationId: _verificationId,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final user = result['user'] as User;
      await _authenticateAndProceed(user);
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Verification failed')),
      );
    }
  }

  Future<void> _handleCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _authenticateAndProceed(userCredential.user!);
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification failed')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _authenticateAndProceed(User firebaseUser) async {
    // Authenticate with backend
    final result = await _authService.authenticateWithBackend(
      firebaseUser: firebaseUser,
      name: _nameController.text.trim(),
      role: _userType,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Navigate to Step 2 for profile completion
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignupStep2Screen(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            userType: _userType,
          ),
        ),
      );
    } else if (result['requiresProfile'] == true) {
      // New user needs to complete profile - same flow
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignupStep2Screen(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            userType: _userType,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Authentication failed')),
      );
    }
  }

  void _onOTPChange(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOTP();
      }
    }
  }

  void _onOTPKeyPress(KeyEvent event, int index) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpControllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              AppTheme.accentColor.withOpacity(0.02),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button and progress
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Consumer<ThemeNotifier>(
                          builder: (context, themeNotifier, _) {
                            final isDarkMode = themeNotifier.isDarkMode;
                            return IconButton(
                              onPressed: () {
                                if (_otpSent) {
                                  setState(() => _otpSent = false);
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: isDarkMode ? AppTheme.darkCardColor : Colors.white,
                                padding: const EdgeInsets.all(12),
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        // Progress Indicator
                        _buildProgressIndicator(_otpSent ? 1 : 1, 2),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _otpSent ? 'Verify Phone' : 'Create Account',
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _otpSent 
                                ? 'Enter the 6-digit code sent to +91 ${_phoneController.text}'
                                : 'Step 1 of 2 - Basic Information',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Form Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  children: [
                    if (!_otpSent) ...[
                      _buildSignupForm(),
                    ] else ...[
                      _buildOTPForm(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Type Selection
          Text(
            'I am a',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildUserTypeCard(
                  'Student/Parent',
                  Icons.school_outlined,
                  'student',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUserTypeCard(
                  'Teacher',
                  Icons.person_outline,
                  'teacher',
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Name Field
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          // Phone Field
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'Enter your 10-digit phone number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            prefixText: '+91 ',
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (value.length != 10) {
                return 'Please enter a valid 10-digit number';
              }
              return null;
            },
          ),
          const SizedBox(height: 40),
          // Send OTP Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _sendOTP,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Send OTP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildOTPForm() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // OTP Input Fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 50,
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) => _onOTPKeyPress(event, index),
                child: TextFormField(
                  controller: _otpControllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: Theme.of(context).textTheme.titleLarge,
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    filled: true,
                    fillColor: isDarkMode ? AppTheme.darkCardColor : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.white24 : Theme.of(context).dividerColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.white24 : Theme.of(context).dividerColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) => _onOTPChange(value, index),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 30),
        // Verify Button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _verifyOTP,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Verify & Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Resend OTP
        Center(
          child: TextButton(
            onPressed: _canResend ? _resendOTP : null,
            child: _isResending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _canResend
                        ? 'Resend OTP'
                        : 'Resend OTP in ${_resendCountdown}s',
                    style: TextStyle(
                      color: _canResend
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).hintColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        // Change Number
        Center(
          child: TextButton(
            onPressed: () => setState(() => _otpSent = false),
            child: Text(
              'Change Phone Number',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(int current, int total) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Text(
          'Step $current of $total',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white70 : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        ...List.generate(
          total,
          (index) => Container(
            margin: const EdgeInsets.only(left: 4),
            width: 30,
            height: 4,
            decoration: BoxDecoration(
              color: index < current
                  ? AppTheme.primaryColor
                  : isDarkMode 
                      ? Colors.white24 
                      : AppTheme.textSecondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserTypeCard(String title, IconData icon, String type) {
    final isSelected = _userType == type;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => setState(() => _userType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected 
              ? null 
              : isDarkMode 
                  ? AppTheme.darkCardColor 
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : isDarkMode 
                    ? Colors.white24 
                    : AppTheme.textSecondary.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : isDarkMode 
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 10,
              offset: Offset(0, isSelected ? 6 : 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected 
                  ? Colors.white 
                  : isDarkMode 
                      ? Colors.white70 
                      : AppTheme.primaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? Colors.white 
                    : isDarkMode 
                        ? Colors.white70 
                        : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? prefixText,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            inputFormatters: inputFormatters,
            style: TextStyle(
              color: isDarkMode ? Colors.white : AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.white54 : AppTheme.textSecondary,
              ),
              prefixIcon: Icon(icon, color: AppTheme.primaryColor),
              prefixText: prefixText,
              prefixStyle: TextStyle(
                color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDarkMode ? AppTheme.darkCardColor : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
