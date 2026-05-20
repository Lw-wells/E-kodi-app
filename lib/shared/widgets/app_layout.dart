import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final String currentLocation;

  const AppLayout({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if we are on a large screen
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isTablet = MediaQuery.of(context).size.width >= 768 && !isDesktop;
    final showSidebar = isDesktop || isTablet;

    return Scaffold(
      appBar: !showSidebar
          ? AppBar(title: const Text('E-Kodi Owner Dashboard'))
          : null,
      drawer: !showSidebar ? _buildSidebar(context) : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSidebar) SizedBox(width: 250, child: _buildSidebar(context)),
          Expanded(
            child: Column(
              children: [
                if (showSidebar)
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor.withAlpha(50),
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 16),
                        const CircleAvatar(
                          radius: 16,
                          child: Icon(Icons.person, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text('Admin'),
                      ],
                    ),
                  ),
                Expanded(
                  child: Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withAlpha(50),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(
                  Icons.home_work,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'E-KODI',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  isSelected: currentLocation == AppRoutes.dashboard,
                  onTap: () => context.go(AppRoutes.dashboard),
                ),
                _SidebarItem(
                  icon: Icons.business_outlined,
                  title: 'Properties',
                  isSelected: currentLocation == AppRoutes.properties,
                  onTap: () => context.go(AppRoutes.properties),
                ),
                _SidebarItem(
                  icon: Icons.people_outline,
                  title: 'Tenants',
                  isSelected: currentLocation == AppRoutes.tenants,
                  onTap: () => context.go(AppRoutes.tenants),
                ),
                _SidebarItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Finances & MPesa',
                  isSelected: currentLocation == AppRoutes.finances,
                  onTap: () => context.go(AppRoutes.finances),
                ),
                _SidebarItem(
                  icon: Icons.forum_outlined,
                  title: 'Communications',
                  isSelected: currentLocation == AppRoutes.communications,
                  onTap: () => context.go(AppRoutes.communications),
                ),
              ],
            ),
          ),
          const Divider(),
          _SidebarItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            isSelected: currentLocation == '/settings',
            onTap: () => context.go('/settings'),
          ),
          _SidebarItem(
            icon: Icons.logout,
            title: 'Logout',
            isSelected: false,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
          // _SidebarItem(
          //   icon: Icons.logout,
          //   title: 'Logout',
          //   isSelected: false,
          //   onTap: () {
          //     context.go(AppRoutes.login);
          //   },
          // ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).iconTheme.color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withAlpha(25),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
