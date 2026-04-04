import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final authState = context.watch<AuthBloc>().state;
    final isOrganizer = authState is AuthAuthenticated &&
        (authState.user.isOrganizer || authState.user.isAdmin);

    int currentIndex = 0;
    if (location.startsWith('/tickets')) currentIndex = 1;
    if (location.startsWith('/notifications')) currentIndex = 2;
    if (location.startsWith('/profile')) currentIndex = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: isOrganizer
                ? _OrganizerNavBar(currentIndex: currentIndex)
                : _AttendeeNavBar(currentIndex: currentIndex),
          ),
        ),
      ),
    );
  }
}

// 5-slot: Explore | Tickets | [Scan FAB] | Inbox | Profile
class _OrganizerNavBar extends StatelessWidget {
  final int currentIndex;
  const _OrganizerNavBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _NavItem(
          icon: Icons.explore_outlined,
          activeIcon: Icons.explore,
          label: 'Explore',
          isActive: currentIndex == 0,
          onTap: () => context.go('/home'),
        ),
        _NavItem(
          icon: Icons.confirmation_number_outlined,
          activeIcon: Icons.confirmation_number,
          label: 'Tickets',
          isActive: currentIndex == 1,
          onTap: () => context.go('/tickets'),
        ),
        _ScanFab(onTap: () => context.push('/scan')),
        _NavItem(
          icon: Icons.notifications_outlined,
          activeIcon: Icons.notifications,
          label: 'Inbox',
          isActive: currentIndex == 2,
          onTap: () => context.go('/notifications'),
        ),
        _NavItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Profile',
          isActive: currentIndex == 3,
          onTap: () => context.go('/profile'),
        ),
      ],
    );
  }
}

// 4-slot: Explore | Tickets | Inbox | Profile
class _AttendeeNavBar extends StatelessWidget {
  final int currentIndex;
  const _AttendeeNavBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _NavItem(
          icon: Icons.explore_outlined,
          activeIcon: Icons.explore,
          label: 'Explore',
          isActive: currentIndex == 0,
          onTap: () => context.go('/home'),
        ),
        _NavItem(
          icon: Icons.confirmation_number_outlined,
          activeIcon: Icons.confirmation_number,
          label: 'Tickets',
          isActive: currentIndex == 1,
          onTap: () => context.go('/tickets'),
        ),
        _NavItem(
          icon: Icons.notifications_outlined,
          activeIcon: Icons.notifications,
          label: 'Inbox',
          isActive: currentIndex == 2,
          onTap: () => context.go('/notifications'),
        ),
        _NavItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Profile',
          isActive: currentIndex == 3,
          onTap: () => context.go('/profile'),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x556366F1),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
      ),
    );
  }
}