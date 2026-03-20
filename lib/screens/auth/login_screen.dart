import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../home/main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _otpSent = false;
  String? _verificationId;
  
  // OTP controllers
  final List<TextEditingController> _otpControllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  
  int _resendCountdown = 0;
  bool _canResend = false;
  bool _isResending = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
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
    final normalizedPhone = phone.startsWith('+') ? phone : '+91$phone';

    // Check if phone exists in our system
    final checkResult = await _authService.checkPhoneExists(normalizedPhone);
    
    if (checkResult['exists'] != true) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number not registered. Please sign up first.'),
          ),
        );
      }
      return;
    }

    // Send OTP via backend (Message Central)
    final result = await _authService.sendOTP(phoneNumber: phone);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() {
        _otpSent = true;
        _verificationId = result['verificationId'] as String?;
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
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to send OTP')),
        );
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend || _isResending) return;

    setState(() => _isResending = true);

    final result = await _authService.sendOTP(
      phoneNumber: _phoneController.text.trim(),
    );

    setState(() => _isResending = false);

    if (result['success'] == true) {
      setState(() {
        _verificationId = result['verificationId'] as String?;
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
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to resend OTP')),
        );
      }
    }
  }

  Future<void> _verifyOTP() async {
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
    final phone = _phoneController.text.trim();

    final result = await _authService.verifyOTPAndAuthenticate(
      otp: otp,
      phone: phone,
      verificationId: _verificationId,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const MainNavigation(initialIndex: 2),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Verification failed')),
      );
    }
  }

  void _onOTPChange(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
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
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Back Button
              Align(
                alignment: Alignment.centerLeft,
                child: Consumer<ThemeNotifier>(
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
              ),
              const SizedBox(height: 20),
              // Header
              Text(
                _otpSent ? 'Verify Phone' : 'Welcome Back!',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent 
                    ? 'Enter the 4-digit code sent to +91 ${_phoneController.text}'
                    : 'Login with your phone number',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 40),
              
              if (!_otpSent) ...[
                _buildPhoneForm(),
              ] else ...[
                _buildOTPForm(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneForm() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Phone Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone Number',
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
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
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
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your 10-digit phone number',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.white54 : AppTheme.textSecondary,
                    ),
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.primaryColor),
                    prefixText: '+91 ',
                    prefixStyle: TextStyle(
                      color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
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
          ),
          const SizedBox(height: 30),
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
                      : const Text(
                          'Send OTP',
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
        ],
      ),
    );
  }

  Widget _buildOTPForm() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // OTP Input Fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) {
            return SizedBox(
              width: 60,
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
                        'Verify & Login',
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
        const SizedBox(height: 10),
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
}
