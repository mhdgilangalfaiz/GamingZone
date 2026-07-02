import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../providers/console_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/member_snack_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'rental/rental_screen.dart';
import 'transaction/transaction_screen.dart';
import 'member/member_screen.dart';
import 'report/report_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    RentalScreen(),
    TransactionScreen(),
    MemberScreen(),
    ReportScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLoad());
  }

  Future<void> _initLoad() async {
    await Future.wait([
      context.read<ConsoleProvider>().loadAll(),
      context.read<TransactionProvider>().loadActive(),
      context.read<TransactionProvider>().loadDashboard(),
      context.read<MemberProvider>().loadAll(),
      context.read<SnackProvider>().loadAll(),
    ]);
  }

  void navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
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
            children: [
              _buildNavItem(
                  0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
              _buildNavItem(1, Icons.sports_esports_outlined,
                  Icons.sports_esports, 'Rental'),
              _buildNavItemCenter(),
              _buildNavItem(3, Icons.people_outline, Icons.people, 'Member'),
              _buildNavItem(
                  4, Icons.bar_chart_outlined, Icons.bar_chart, 'Laporan'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppConstants.animNormal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.glowPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FAB-style center nav item for Transaksi
  Widget _buildNavItemCenter() {
    final isSelected = _currentIndex == 2;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isSelected
              ? AppColors.primaryGradient
              : const LinearGradient(
                  colors: [AppColors.surfaceLight, AppColors.surface],
                ),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: AppColors.glowPurple,
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.receipt_long,
          color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
          size: 24,
        ),
      ),
    );
  }
}
