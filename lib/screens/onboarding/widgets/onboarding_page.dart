import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../onboarding_screen.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Title
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 32,
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
          const SizedBox(height: 80),
          // Animated Circle with Icons
          _buildAnimatedCircle(),
          const SizedBox(height: 80),
          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              height: 1.5,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCircle() {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circles
          ...List.generate(3, (index) {
            return Container(
              width: 300 - (index * 40),
              height: 300 - (index * 40),
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
            width: 140,
            height: 140,
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
              size: 70,
              color: Colors.white,
            ),
          ),
          // Floating subject icons
          _buildFloatingIcon(Icons.science_outlined, 0, -110, 0),
          _buildFloatingIcon(Icons.calculate_outlined, 95, -20, 1),
          _buildFloatingIcon(Icons.edit_outlined, 80, 70, 2),
          _buildFloatingIcon(Icons.computer_outlined, -10, 110, 3),
          _buildFloatingIcon(Icons.menu_book_outlined, -100, 50, 4),
        ],
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, double x, double y, int index) {
    return Positioned(
      left: 150 + x,
      top: 150 + y,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 800 + (index * 100)),
        curve: Curves.elasticOut,
        builder: (context, double value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              width: 50,
              height: 50,
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
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }
}
