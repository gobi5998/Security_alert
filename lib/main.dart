import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_alert/provider/scam_report_provider.dart';
import 'package:security_alert/screens/menu/feedbackPage.dart';
import 'package:security_alert/screens/menu/profile_page.dart';
import 'package:security_alert/screens/menu/ratepage.dart';
import 'package:security_alert/screens/scam/scam_report_service.dart';
import 'package:security_alert/screens/menu/shareApp.dart';
import 'package:security_alert/screens/subscriptionPage/subscription_plans_page.dart';
import 'package:security_alert/screens/menu/theard_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:security_alert/provider/auth_provider.dart';
import 'package:security_alert/provider/dashboard_provider.dart';
import 'package:security_alert/screens/SplashScreen.dart';
import 'package:security_alert/screens/dashboard_page.dart';
import 'package:security_alert/screens/login.dart';
import 'package:security_alert/services/biometric_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'models/scam_report_model.dart'; // ✅ Make sure this file contains: part 'scam_report_model.g.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(ScamReportModelAdapter());

  // Try to open the box, if it fails due to unknown type IDs, clear and recreate
  try {
    await Hive.openBox<ScamReportModel>('scam_reports');
  } catch (e) {
    if (e.toString().contains('unknown typeId')) {
      print('Clearing Hive database due to unknown type IDs');
      await Hive.deleteBoxFromDisk('scam_reports');
      await Hive.openBox<ScamReportModel>('scam_reports');
    } else {
      rethrow;
    }
  }
  
  // await Hive.deleteBoxFromDisk('scam_reports');

  Connectivity().onConnectivityChanged.listen((result) {
    if (result != ConnectivityResult.none) {
      print('Internet connection restored, syncing reports...');
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
      // home: const SplashScreen(),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/profile': (context) =>  ProfilePage(),
        '/thread': (context) =>  ThreadDatabaseFilterPage(),
        '/subscription': (context) =>  SubscriptionPlansPage(),
        '/rate': (context) =>  Ratepage(),
        '/share': (context) =>  Shareapp(),
        '/feedback': (context) =>  Feedbackpage(),
         '/splashScreen':(context)=> SplashScreen()
      },

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
    return _showAuthWrapper ? const AuthWrapper() : const SplashScreen();
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
    await Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
    setState(() {
      _authChecked = true;
    });
  }

  Future<void> _checkBiometrics(AuthProvider authProvider) async {
    if (!_biometricChecked && authProvider.isLoggedIn) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final bioEnabled = prefs.getBool('biometric_enabled') ?? false;

        if (bioEnabled) {
          final isAvailable = await BiometricService.isBiometricAvailable();
          if (isAvailable) {
            _biometricChecked = true;
            final passed = await BiometricService.authenticateWithBiometrics();
            if (!passed) {
              await authProvider.logout();
            }
            setState(() {
              _biometricPassed = passed;
            });
          } else {
            setState(() {
              _biometricPassed = true;
            });
          }
        } else {
          setState(() {
            _biometricPassed = true;
          });
        }
      } catch (e) {
        print('Biometric check error: $e');
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
        if (!_authChecked || authProvider.isLoading) {
          return const SplashScreen();
        }

        if (authProvider.isLoggedIn) {
          if (!_biometricChecked) {
            _checkBiometrics(authProvider);
            return const SplashScreen();
          }

          return _biometricPassed ? const DashboardPage() : const LoginPage();
        }

        return const LoginPage();
      },
    );
  }
}
