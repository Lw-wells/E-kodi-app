import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';


class TenantAppLayout extends StatelessWidget {
  final Widget child;
  final String currentLocation;

  const TenantAppLayout({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile    = screenWidth < 768;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: const Text('E-Kodi'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _confirmSignOut(context),
                ),
              ],
            )
          : null,
      drawer: isMobile ? _buildDrawer(context) : null,
      body: isMobile
          ? child
          : Row(
              children: [
                _buildSidebar(context),
                Expanded(child: child),
              ],
            ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 240,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: Theme.of(context).colorScheme.primary,
            child: const Row(
              children: [
                Icon(Icons.person, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Home',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text('Tenant Portal',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _navItem(context, '/tenant/dashboard', Icons.dashboard,
                    'Dashboard'),
                _navItem(context, '/tenant/bills',    Icons.receipt,
                    'My Bills'),
                _navItem(context, '/tenant/payments', Icons.payment,
                    'Payment History'),
                _navItem(context, '/tenant/messages', Icons.message,
                    'Messages'),
                _navItem(context, '/tenant/settings',  Icons.settings,
                    'Settings'),
              ],
            ),
          ),

          // Sign out
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out',
                  style: TextStyle(color: Colors.red)),
              onTap: () => _confirmSignOut(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Row(
              children: [
                Icon(Icons.person, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Home',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    Text('Tenant Portal',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          _navItem(context, '/tenant/dashboard', Icons.dashboard, 'Dashboard'),
          _navItem(context, '/tenant/bills',     Icons.receipt,   'My Bills'),
          _navItem(context, '/tenant/payments',  Icons.payment,   'Payment History'),
          _navItem(context, '/tenant/messages',  Icons.message,   'Messages'),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title:
                const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, String route, IconData icon, String label) {
    final isActive = currentLocation == route;
    return ListTile(
      leading: Icon(icon,
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : null),
      title: Text(label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : null,
          )),
      tileColor: isActive
          ? Theme.of(context).colorScheme.primary.withAlpha(20)
          : null,
      onTap: () {
        context.go(route);
        if (MediaQuery.of(context).size.width < 768) {
          Navigator.pop(context);
        }
      },
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) context.go('/login');
    }
  }
}