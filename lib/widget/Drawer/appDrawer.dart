import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_alert/screens/menu/profile_page.dart';
import 'package:security_alert/screens/subscriptionPage/subscription_plans_page.dart';
import 'package:security_alert/screens/menu/theard_database.dart';

import '../../custom/Image/image.dart';
import 'drawer_menu_item.dart';


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
            DrawerMenuItem(
              ImagePath: ImagePath.profile,
              label: 'Profile',
              routeName: '/profile',
            ),
            DrawerMenuItem(
              ImagePath: ImagePath.thread,
              label: 'Thread Database',
              routeName: '/thread',
            ),
            DrawerMenuItem(
              ImagePath: ImagePath.subscription,
              label: 'Subscription',
             routeName: '/subscription',
            ),
            DrawerMenuItem(
              ImagePath: ImagePath.rate,
              label: 'Rate App',
              routeName: '/rate',
            ),
            DrawerMenuItem(
              ImagePath: ImagePath.share,
              label: 'Share App',
              routeName: '/share',
            ),
            DrawerMenuItem(
              ImagePath:  ImagePath.feedback,
              label: 'Feedback',
              routeName: '/feedback',
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}



