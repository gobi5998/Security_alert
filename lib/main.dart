import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:security_alert/screens/scam/scam_report_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:security_alert/provider/auth_provider.dart';
import 'package:security_alert/provider/dashboard_provider.dart';
import 'package:security_alert/screens/SplashScreen.dart';
import 'package:security_alert/screens/dashboard_page.dart';
import 'package:security_alert/screens/login.dart';
import 'package:security_alert/services/biometric_service.dart';

import 'models/scam_report_model.dart';
import 'models/scam_report_provider.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(ScamReportModelAdapter());
  await Hive.openBox<ScamReportModel>('scam_reports');

  Connectivity().onConnectivityChanged.listen((result) {
    if (result != ConnectivityResult.none) {
      ScamReportService.syncReports();
    }
  });


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ScamReportProvider()),
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
      home: const SplashScreen(),
    );
  }
}

class SplashToAuth extends StatefulWidget {
  const SplashToAuth({super.key});

  @override
  State<SplashToAuth> createState() => _SplashToAuthState();
}

class _SplashToAuthState extends State<SplashToAuth> {
  bool _showAuthWrapper = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showAuthWrapper = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showAuthWrapper) {
      return const AuthWrapper();
    } else {
      return const SplashScreen();
    }
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _authChecked = false;
  bool _biometricChecked = false;
  bool _biometricPassed = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Check auth status first
    await Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
    setState(() {
      _authChecked = true;
    });
  }

  Future<void> _checkBiometrics(AuthProvider authProvider) async {
    if (!_biometricChecked && authProvider.isLoggedIn) {
      try {
        // Check if biometric is enabled
        final prefs = await SharedPreferences.getInstance();
        final bioEnabled = prefs.getBool('biometric_enabled') ?? false;
        
        if (bioEnabled) {
          // Check if biometric is available
          final isAvailable = await BiometricService.isBiometricAvailable();
          if (isAvailable) {
            _biometricChecked = true;
            final passed = await BiometricService.authenticateWithBiometrics();
            if (!passed) {
              // Biometric failed, logout
              await authProvider.logout();
            }
            setState(() {
              _biometricPassed = passed;
            });
          } else {
            // Biometric not available, allow access
            setState(() {
              _biometricPassed = true;
            });
          }
        } else {
          // Biometric not enabled, allow access
          setState(() {
            _biometricPassed = true;
          });
        }
      } catch (e) {
        print('Biometric check error: $e');
        // On error, allow access
        setState(() {
          _biometricPassed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show splash while checking auth
        if (!_authChecked || authProvider.isLoading) {
          return const SplashScreen();
        }

        // User is logged in
        if (authProvider.isLoggedIn) {
          // Check biometrics if not already checked
          if (!_biometricChecked) {
            _checkBiometrics(authProvider);
            return const SplashScreen();
          }

          // Show dashboard if biometric passed or not required
          if (_biometricPassed) {
            return const DashboardPage();
          } else {
            // Biometric failed, show login
            return const LoginPage();
          }
        }

        // User is not logged in
        return const LoginPage();
      },
    );
  }
}

