import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_alert/screens/profile_page.dart';
import 'package:security_alert/screens/subscriptionPage/subscription_plans_page.dart';
import 'package:security_alert/screens/theard_database.dart';
import '../provider/auth_provider.dart';
import '../screens/login.dart';
import 'server_reports_page.dart';
class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const CircleAvatar(
                        radius: 18,
                        backgroundImage: AssetImage(
                          'assets/image/security1.jpg',
                        ), // Use your logo asset
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Security Alert',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DrawerMenuItem(icon: Icons.person, label: 'Profile', onTap: () {Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(),
                  ),
                );}),
            _DrawerMenuItem(
              icon: Icons.bug_report,
              label: 'Thread Data Base',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ThreadDatabaseFilterPage(),
                  ),
                );
              },
            ),
            _DrawerMenuItem(
              icon: Icons.search,
              label: 'Smart Search',
              onTap: () {},
            ),
            _DrawerMenuItem(
              icon: Icons.attach_money,
              label: 'Subscription',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubscriptionPlansPage(),
                  ),
                );
              },
            ),
            _DrawerMenuItem(
              icon: Icons.star_border,
              label: 'Rate App',
              onTap: () {},
            ),
            _DrawerMenuItem(
              icon: Icons.share,
              label: 'Share App',
              onTap: () {},
            ),
            _DrawerMenuItem(
              icon: Icons.chat_bubble_outline,
              label: 'Feedback',
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.cloud),
              title: Text('Server Reports'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ServerReportsPage()),
                );
              },
            ),
            const Spacer(),
            _DrawerMenuItem(
              icon: Icons.logout,
              label: 'Logout',
              color: Colors.redAccent,
              onTap: () async {
                // Use the local context for navigation and provider
                await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).logout();
                Navigator.of(context).pop(); // Close the drawer
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
