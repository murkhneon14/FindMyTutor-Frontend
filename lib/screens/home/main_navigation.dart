import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/global_notification_manager.dart';
import 'explore_screen.dart';
import 'messages_screen.dart';
import 'account_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.initialIndex = 1});

  final int initialIndex; // 0=Messages, 1=Explore, 2=Account

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  final GlobalNotificationManager _notificationManager = GlobalNotificationManager();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 2);
    _pageController = PageController(initialPage: _currentIndex);
    // Initialize global notification manager after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationManager.initialize(context);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const MessagesScreen(),
    const ExploreScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        physics: const BouncingScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          final isDarkMode = themeNotifier.isDarkMode;
          return Container(
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: 'Messages',
                      index: 0,
                      isDarkMode: isDarkMode,
                    ),
                    _buildNavItem(
                      icon: Icons.explore_outlined,
                      activeIcon: Icons.explore,
                      label: 'Explore',
                      index: 1,
                      isDarkMode: isDarkMode,
                    ),
                    _buildNavItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Account',
                      index: 2,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isDarkMode,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive
                    ? AppTheme.primaryColor
                    : isDarkMode
                    ? Colors.white70
                    : AppTheme.textSecondary,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? AppTheme.primaryColor
                    : isDarkMode
                    ? Colors.white70
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
