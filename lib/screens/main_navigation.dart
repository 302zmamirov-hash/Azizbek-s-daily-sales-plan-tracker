import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:daily_sales_plan_tracker/theme.dart';
import 'package:daily_sales_plan_tracker/nav.dart';
import 'package:daily_sales_plan_tracker/screens/dashboard_screen.dart';
import 'package:daily_sales_plan_tracker/screens/daily_entry_screen.dart';
import 'package:daily_sales_plan_tracker/screens/history_screen.dart';
import 'package:daily_sales_plan_tracker/screens/bonus_screen.dart';
import 'package:daily_sales_plan_tracker/screens/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  final int currentIndex;
  
  const MainNavigation({super.key, required this.currentIndex});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  void _onItemTapped(int index) {
    if (index == widget.currentIndex) return;
    
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.daily);
        break;
      case 2:
        context.go(AppRoutes.history);
        break;
      case 3:
        context.go(AppRoutes.bonus);
        break;
      case 4:
        context.go(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: widget.currentIndex,
        children: const [
          DashboardScreen(),
          DailyEntryScreen(),
          HistoryScreen(),
          BonusScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavBarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Дашборд',
                  isSelected: widget.currentIndex == 0,
                  onTap: () => _onItemTapped(0),
                ),
                _NavBarItem(
                  icon: Icons.edit_calendar_rounded,
                  label: 'Запись',
                  isSelected: widget.currentIndex == 1,
                  onTap: () => _onItemTapped(1),
                ),
                _NavBarItem(
                  icon: Icons.history_rounded,
                  label: 'История',
                  isSelected: widget.currentIndex == 2,
                  onTap: () => _onItemTapped(2),
                ),
                _NavBarItem(
                  icon: Icons.emoji_events_rounded,
                  label: 'Бонус',
                  isSelected: widget.currentIndex == 3,
                  onTap: () => _onItemTapped(3),
                ),
                _NavBarItem(
                  icon: Icons.settings_rounded,
                  label: 'Настройки',
                  isSelected: widget.currentIndex == 4,
                  onTap: () => _onItemTapped(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected 
        ? Theme.of(context).colorScheme.primary 
        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
        
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: context.textStyles.labelSmall?.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
