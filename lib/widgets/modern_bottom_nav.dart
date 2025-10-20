import 'package:flutter/material.dart';

class ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isAdmin;

  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _buildNavItems(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNavItems(BuildContext context) {
    if (isAdmin) {
      return [
        _buildNavItem(
          context,
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
          label: 'Dashboard',
          index: 0,
        ),
        _buildNavItem(
          context,
          icon: Icons.people_outline,
          activeIcon: Icons.people,
          label: 'Members',
          index: 1,
        ),
        _buildNavItem(
          context,
          icon: Icons.account_balance_outlined,
          activeIcon: Icons.account_balance,
          label: 'Loans',
          index: 2,
        ),
        _buildNavItem(
          context,
          icon: Icons.rotate_right_outlined,
          activeIcon: Icons.rotate_right,
          label: 'Allocations',
          index: 3,
        ),
        _buildNavItem(
          context,
          icon: Icons.analytics_outlined,
          activeIcon: Icons.analytics,
          label: 'Reports',
          index: 4,
        ),
        _buildNavItem(
          context,
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today,
          label: 'Meetings',
          index: 5,
        ),
      ];
    } else {
      return [
        _buildNavItem(
          context,
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
          label: 'Home',
          index: 0,
        ),
        _buildNavItem(
          context,
          icon: Icons.payment_outlined,
          activeIcon: Icons.payment,
          label: 'Payments',
          index: 1,
        ),
        _buildNavItem(
          context,
          icon: Icons.account_balance_outlined,
          activeIcon: Icons.account_balance,
          label: 'Loans',
          index: 2,
        ),
        _buildNavItem(
          context,
          icon: Icons.rotate_right_outlined,
          activeIcon: Icons.rotate_right,
          label: 'Allocations',
          index: 3,
        ),
        _buildNavItem(
          context,
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today,
          label: 'Meetings',
          index: 4,
        ),
        _buildNavItem(
          context,
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Profile',
          index: 5,
        ),
      ];
    }
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
