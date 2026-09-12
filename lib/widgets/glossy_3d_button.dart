import 'package:flutter/material.dart';

/// Reusable 3D Glossy / Neumorphic Black Pill Button widget.
/// Recreates a premium 3D layered shadow effect with smooth continuous gradients and zero harsh edges.
/// 
/// Specs:
/// - Base fill color: #1D1B1A
/// - Shape: fully rounded pill (borderRadius ~ height/2)
/// - Layered Outer Shadows:
///   1. Offset(0, 40), blurRadius 35, color Colors.black.withOpacity(0.25)
///   2. Offset(0, 13), blurRadius 20, spreadRadius 2, color Colors.black.withOpacity(0.45)
///   3. Offset(0, 5), blurRadius 5, color Colors.black.withOpacity(0.25)
///   4. Offset(0, 1), blurRadius 2, color Colors.black.withOpacity(0.25)
/// - Inset Highlights:
///   - Full-height continuous LinearGradients with soft color stops (0.0 to 1.0)
///   - Completely smooth, no abrupt container edges or straight lines across the middle.
class Glossy3DButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final double height;
  final double? width;
  final TextStyle? textStyle;

  const Glossy3DButton({
    Key? key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 52.0,
    this.width,
    this.textStyle,
  }) : super(key: key);

  @override
  State<Glossy3DButton> createState() => _Glossy3DButtonState();
}

class _Glossy3DButtonState extends State<Glossy3DButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double buttonHeight = widget.height;
    final double borderRadius = buttonHeight / 2;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: buttonHeight,
          width: widget.width ?? double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1D1B1A), // Base fill color #1D1B1A
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.0,
            ),
            boxShadow: [
              // Outer shadow 1: Offset(0, 40), blurRadius 35
              BoxShadow(
                offset: const Offset(0, 40),
                blurRadius: _isPressed ? 18 : 35,
                color: Colors.black.withOpacity(0.25),
              ),
              // Outer shadow 2: Offset(0, 13), blurRadius 20, spreadRadius 2
              BoxShadow(
                offset: const Offset(0, 13),
                blurRadius: _isPressed ? 10 : 20,
                spreadRadius: 2,
                color: Colors.black.withOpacity(0.45),
              ),
              // Outer shadow 3: Offset(0, 5), blurRadius 5
              BoxShadow(
                offset: const Offset(0, 5),
                blurRadius: _isPressed ? 2 : 5,
                color: Colors.black.withOpacity(0.25),
              ),
              // Outer shadow 4: Offset(0, 1), blurRadius 2
              BoxShadow(
                offset: const Offset(0, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.25),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              children: [
                // Base smooth 3D gradient fill across 100% height (NO sharp lines)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF3F3B38), // Top subtle rim highlight
                        const Color(0xFF282524), // Upper body
                        const Color(0xFF1D1B1A), // Base center #1D1B1A
                        const Color(0xFF141212), // Lower body
                        const Color(0xFF0C0B0A), // Bottom deep shadow
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.8, 1.0],
                    ),
                  ),
                ),
                // Smooth continuous glossy sheen overlay over 100% height
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.28), // Top glossy highlight
                        Colors.white.withOpacity(0.08),
                        Colors.transparent,             // Smooth transition
                        Colors.black.withOpacity(0.40), // Bottom depth
                      ],
                      stops: const [0.0, 0.35, 0.65, 1.0],
                    ),
                  ),
                ),
                // Centered white/light-grey label text with icon
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: const Color(0xFFF5F5F7),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: widget.textStyle ??
                            const TextStyle(
                              color: Color(0xFFF5F5F7),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
