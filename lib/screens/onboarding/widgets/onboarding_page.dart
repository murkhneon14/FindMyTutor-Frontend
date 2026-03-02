import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../onboarding_screen.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    // Scale circle size based on screen dimensions
    final circleSize = (screenWidth * 0.65).clamp(180.0, 300.0);
    final spacing = (screenHeight * 0.04).clamp(16.0, 60.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 160, // leave room for bottom nav
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: spacing * 0.5),
              // Title
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: screenWidth < 360 ? 26 : 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                  children: [
                    TextSpan(text: data.title),
                    TextSpan(
                      text: data.titleHighlight,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing),
              // Animated Circle with Icons
              _buildAnimatedCircle(circleSize),
              SizedBox(height: spacing),
              // Description
              Text(
                data.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth < 360 ? 16 : 18,
                  height: 1.5,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: spacing * 0.5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCircle(double size) {
    final iconContainerSize = size * 0.47;
    final floatingIconSize = size * 0.16;
    final halfSize = size / 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Outer circles
          ...List.generate(3, (index) {
            return Container(
              width: size - (index * (size * 0.13)),
              height: size - (index * (size * 0.13)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.1 + (index * 0.1)),
                  width: 1,
                ),
              ),
            );
          }),
          // Center icon container
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              data.icon,
              size: iconContainerSize * 0.5,
              color: Colors.white,
            ),
          ),
          // Floating subject icons - positioned relative to circle size
          _buildFloatingIcon(Icons.science_outlined, 0, -halfSize * 0.73, 0, floatingIconSize),
          _buildFloatingIcon(Icons.calculate_outlined, halfSize * 0.63, -halfSize * 0.13, 1, floatingIconSize),
          _buildFloatingIcon(Icons.edit_outlined, halfSize * 0.53, halfSize * 0.47, 2, floatingIconSize),
          _buildFloatingIcon(Icons.computer_outlined, -halfSize * 0.07, halfSize * 0.73, 3, floatingIconSize),
          _buildFloatingIcon(Icons.menu_book_outlined, -halfSize * 0.67, halfSize * 0.33, 4, floatingIconSize),
        ],
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, double x, double y, int index, double iconSize) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: Align(
        alignment: Alignment(
          (x / 150).clamp(-1.0, 1.0),
          (y / 150).clamp(-1.0, 1.0),
        ),
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 800 + (index * 100)),
          curve: Curves.elasticOut,
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: iconSize * 0.48,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
