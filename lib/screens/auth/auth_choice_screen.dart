import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// Soft top tint so the status bar / top inset is not a flat white header strip.
const Color _authGradientTop = Color(0xFFE8F4FC);

class AuthChoiceScreen extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onLoginSuccess;

  const AuthChoiceScreen({
    super.key,
    this.showBackButton = true,
    this.onLoginSuccess,
  });

  @override
  State<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends State<AuthChoiceScreen> {
  static final SystemUiOverlayStyle _lightStatusBar = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.cardColor,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(_lightStatusBar);
    });
  }

  /// Avoid popping the last route (empty navigator shows a black screen).
  void _handleBack() {
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = AnnotatedRegion<SystemUiOverlayStyle>(
      value: _lightStatusBar,
      child: SizedBox.expand(
        child: ColoredBox(
          color: _authGradientTop,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomRight,
                colors: [
                  _authGradientTop,
                  AppTheme.primaryColor.withOpacity(0.12),
                  AppTheme.accentColor.withOpacity(0.07),
                ],
                stops: const [0.0, 0.38, 1.0],
              ),
            ),
            child: SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.showBackButton)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap: _handleBack,
                              borderRadius: BorderRadius.circular(24),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 20,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!widget.showBackButton) const SizedBox(height: 40),
                    if (widget.showBackButton) const SizedBox(height: 8),
                    // Logo/Icon
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 140,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Welcome Text
                    Text(
                      'Welcome to',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        'Find My Tutor',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connect with qualified teachers for\nface-to-face tutoring',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                    ),
                    const Spacer(),
                    // Create Account Button (Primary)
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: const Center(
                            child: Text(
                              'Create Account',
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
                    const SizedBox(height: 16),
                    // Login Button (Secondary)
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppTheme.primaryGradient.createShader(bounds),
                              child: const Text(
                                'Login',
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
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.showBackButton) {
      return content;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: content,
    );
  }
}
