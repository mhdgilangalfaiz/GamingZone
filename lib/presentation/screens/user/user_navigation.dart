import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import 'user_home_screen.dart';
import 'user_booking_screen.dart';
import 'user_snack_order_screen.dart';
import 'user_profile_screen.dart';

class UserNavigation extends StatefulWidget {
  const UserNavigation({super.key});
  @override
  State<UserNavigation> createState() => UserNavigationState();
}

class UserNavigationState extends State<UserNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    UserHomeScreen(),
    UserBookingScreen(),
    UserSnackOrderScreen(),
    UserProfileScreen(),
  ];

  /// Pindah tab dari luar, mis. dari tombol quick-action di Beranda:
  /// `context.findAncestorStateOfType<UserNavigationState>()?.navigateTo(1)`
  void navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    final items = [
      (Icons.home_outlined, Icons.home, 'Beranda'),
      (Icons.calendar_today_outlined, Icons.calendar_today, 'Booking'),
      (Icons.fastfood_outlined, Icons.fastfood, 'Order'),
      (Icons.person_outline, Icons.person, 'Profil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border:
            const Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final (outIcon, fillIcon, label) = items[i];
              final sel = _currentIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppConstants.animNormal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.glowPurple : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sel ? fillIcon : outIcon,
                        color:
                            sel ? AppColors.primary : AppColors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          color: sel ? AppColors.primary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
