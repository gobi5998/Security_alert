import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_alert/provider/auth_provider.dart';
import 'package:security_alert/provider/dashboard_provider.dart';
import 'package:security_alert/screens/SplashScreen.dart';
import 'package:security_alert/screens/dashboard_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const DashboardPage(),
    );
  }
}
