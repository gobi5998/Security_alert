import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../provider/dashboard_provider.dart';
import '../widget/graph_widget.dart';
import 'appDrawer.dart';
import '../services/biometric_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Load dashboard data when the page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const DashboardDrawer(),
      extendBody: true,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Security Alert", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              provider.loadDashboardData();
            },
          ),
          // Test biometric button (remove in production)
          IconButton(
            icon: const Icon(Icons.fingerprint, color: Colors.white),
            onPressed: () async {
              await BiometricService.testBiometric();
              final result = await BiometricService.authenticateWithBiometrics();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Biometric test result: $result')),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Report buttons row (separate from nav bar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF064FAD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Report Scam',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF064FAD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Report Malware',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF064FAD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Report Fraud',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom navigation bar
          BottomNavigationBar(
            backgroundColor: Color(0xFF064FAD),
            elevation: 8,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white60,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.system_update), label: 'Update'),
              BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Alert'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
            onTap: (index) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tapped: \\${['Home', 'Update', 'Alert', 'Profile'][index]}')),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF064FAD), Color(0xFFebebeb)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  
                  // Error message display
                  if (provider.errorMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.errorMessage,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.red.shade600, size: 20),
                            onPressed: () => provider.clearError(),
                          ),
                        ],
                      ),
                    ),

                  CarouselSlider(
                    options: CarouselOptions(
                      height: 160.0,
                      enlargeCenterPage: true,
                      enableInfiniteScroll: true,
                      autoPlay: true,
                    ),
                    items: [
                      "assets/image/security1.jpg",
                      "assets/image/security2.png",
                      "assets/image/security3.jpg",
                      "assets/image/security4.jpg",
                      "assets/image/security5.jpg",
                      "assets/image/security6.jpg",
                    ].map((imagePath) {
                      return Builder(
                        builder: (BuildContext context) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              width: MediaQuery.of(context).size.width,
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: provider.reportedFeatures.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(entry.key)),
                              Expanded(
                                flex: 5,
                                child: LinearProgressIndicator(
                                  value: (entry.value is int) ? entry.value.toDouble() : entry.value,
                                  color: Colors.blue,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text("${(entry.value * 100).toInt()}%"),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatCard(
                        label: provider.stats?.totalAlerts.toString() ?? '50K+',
                        desc: 'Total Alerts',
                      ),
                      _StatCard(
                        label: provider.stats?.resolvedAlerts.toString() ?? '10K+',
                        desc: 'Resolved',
                      ),
                      _StatCard(
                        label: '${provider.stats?.riskScore.toInt() ?? 75}%',
                        desc: 'Risk Score',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const GraphWidget(),

                  const SizedBox(height: 12),
                ],
              ),
            ),
            
            // Loading overlay
            if (provider.isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, desc;
  const _StatCard({required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(desc, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ReportButton({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.white,
          child: Icon(icon, color: Color(0xFF1E3A8A)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}

class _BottomReportButton extends StatelessWidget {
  final String label;
  const _BottomReportButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF064FAD), fontWeight: FontWeight.bold),
      ),
    );
  }
}

