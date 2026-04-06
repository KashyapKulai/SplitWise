import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';
import 'dashboard_page.dart';
import 'groups_page.dart';
import 'settlements_page.dart';
import 'activity_page.dart';
import 'group_detail_page.dart';

/// Main app shell with responsive sidebar/bottom navigation
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _navItems = [
    _NavItem(Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(Icons.group_rounded, 'Groups'),
    _NavItem(Icons.account_balance_wallet_rounded, 'Settle'),
    _NavItem(Icons.timeline_rounded, 'Activity'),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        // If viewing a group detail, show that page
        if (provider.activeGroupId != null) {
          return GroupDetailPage(groupId: provider.activeGroupId!);
        }

        final isDesktop = MediaQuery.of(context).size.width > 900;
        final isTablet = MediaQuery.of(context).size.width > 600;

        return Scaffold(
          body: Row(
            children: [
              // ── Sidebar Navigation (desktop/tablet) ──
              if (isTablet) _buildSidebar(context, provider, isDesktop),

              // ── Main Content ──
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.02, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildPage(provider.selectedIndex),
                ),
              ),
            ],
          ),
          // ── Bottom Navigation (mobile) ──
          bottomNavigationBar: isTablet ? null : _buildBottomNav(context, provider),
        );
      },
    );
  }

  Widget _buildSidebar(
      BuildContext context, AppProvider provider, bool expanded) {
    final isDark = provider.isDark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: expanded ? 260 : 80,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? AppTheme.glassBorder : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // ── Logo / Brand ──
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 24 : 12,
              vertical: 16,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: 12),
                  Text(
                    'ClearLedger',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Nav Items ──
          ...List.generate(_navItems.length, (i) {
            final item = _navItems[i];
            final selected = provider.selectedIndex == i;

            return _SidebarItem(
              icon: item.icon,
              label: item.label,
              selected: selected,
              expanded: expanded,
              onTap: () => provider.setSelectedIndex(i),
            );
          }),

          const Spacer(),

          // ── Theme Toggle ──
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 16 : 8,
              vertical: 16,
            ),
            child: _ThemeToggle(expanded: expanded),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, AppProvider provider) {
    final isDark = provider.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.glassBorder : Colors.grey.shade200,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final selected = provider.selectedIndex == i;

              return _BottomNavItem(
                icon: item.icon,
                label: item.label,
                selected: selected,
                onTap: () => provider.setSelectedIndex(i),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const DashboardPage(key: ValueKey('dashboard'));
      case 1:
        return const GroupsPage(key: ValueKey('groups'));
      case 2:
        return const SettlementsPage(key: ValueKey('settlements'));
      case 3:
        return const ActivityPage(key: ValueKey('activity'));
      default:
        return const DashboardPage(key: ValueKey('dashboard'));
    }
  }
}

// ─────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(
            horizontal: widget.expanded ? 12 : 8,
            vertical: 2,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.expanded ? 16 : 0,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppTheme.primaryPurple.withValues(alpha: 0.15)
                : _isHovered
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: widget.selected
                ? Border.all(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: widget.expanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: widget.selected
                    ? AppTheme.primaryPurple
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                size: 22,
              ),
              if (widget.expanded) ...[
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.selected
                        ? AppTheme.primaryPurple
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                    fontWeight:
                        widget.selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryPurple.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected
                  ? AppTheme.primaryPurple
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppTheme.primaryPurple
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final bool expanded;
  const _ThemeToggle({required this.expanded});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return GestureDetector(
      onTap: provider.toggleTheme,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 16 : 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: provider.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment:
                expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: Tween(begin: 0.5, end: 1.0).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Icon(
                  provider.isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  key: ValueKey(provider.isDark),
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (expanded) ...[
                const SizedBox(width: 12),
                Text(
                  provider.isDark ? 'Light Mode' : 'Dark Mode',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
