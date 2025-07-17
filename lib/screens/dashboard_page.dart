import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:security_alert/custom/Image/image.dart';
import 'package:security_alert/screens/scam/report_scam_1.dart';
import 'package:security_alert/screens/scam/scam_report_service.dart';
import '../custom/PeriodDropdown.dart';
import '../custom/bottomnavigation.dart';
import '../custom/customButton.dart';
import '../provider/dashboard_provider.dart';
import '../widget/graph_widget.dart';
import '../widget/Drawer/appDrawer.dart';
import '../services/biometric_service.dart';
import 'ReportedFeatureCard.dart';
import 'ReportedFeatureItem.dart';
import 'alert.dart';
import 'malware/report_malware_1.dart';
import 'menu/theard_database.dart';
import 'server_reports_page.dart';
import 'menu/profile_page.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> reportTypes = [];
  bool isLoadingTypes = true;
  List<Map<String, dynamic>> reportCategories = [];
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    // Load dashboard data when the page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(
        context,
        listen: false,
      ).loadDashboardData();
    });
    _loadReportTypes();
    _loadReportCategories();
  }

  Future<void> _loadReportTypes() async {
    reportTypes = await ScamReportService.fetchReportTypes();
    print('report$reportTypes');
    setState(() {
      isLoadingTypes = false;
    });
  }

  Future<void> _loadReportCategories() async {
    reportCategories = await ScamReportService.fetchReportCategories();
    print('Loaded categories: $reportCategories'); // Debug print
    setState(() {
      isLoadingCategories = false;
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.center,
              colors: <Color>[
                Color(0xFF236cc5), // Start color
                Color(0xFF236cc5),
              ],
            ),
          ),
        ),

        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Security Alert",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Image.asset('assets/icon/menu.png'),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
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
              final result =
                  await BiometricService.authenticateWithBiometrics();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Biometric test result: $result')),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Color(0xFFf0f2f5)),

        child: Column(
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
                      child: CustomButton(
                        text: 'Report Scam',
                        onPressed: () async {
                          if (isLoadingTypes) return;
                          Map<String, dynamic>? scamCategory;
                          try {
                            scamCategory = reportCategories.firstWhere((e) => e['name'] == 'Report Scam');
                          } catch (_) {
                            scamCategory = null;
                          }
                          if (scamCategory == null) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportScam1(categoryId: scamCategory!['_id']),
                            ),
                          );
                        }, fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: CustomButton(
                        text: 'Report Malware',
                        onPressed: () async {
                          if (isLoadingTypes) return;
                          Map<String, dynamic>? MalwareCategory;
                          try {
                            MalwareCategory = reportCategories.firstWhere((e) => e['name'] == 'Report Malware');
                          } catch (_) {
                            MalwareCategory = null;
                          }
                          if (MalwareCategory == null) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>  MalwareReportPage1(),
                            ),
                          );
                          return;
                        },
                        fontSize: 14,
                        borderCircular: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: CustomButton(
                        text: 'Report Fraud',
                        onPressed: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>  MalwareReportPage1(),
                            ),
                          );
                          return;
                        },
                        fontSize: 14,
                        borderCircular: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom navigation bar
            BottomNavigationBar(
              backgroundColor: Color(0xFFf0f2f5),
              elevation: 8,
              selectedItemColor: Colors.black,

              items: [
                customBottomNavItem(
                    BottomNav: BottomNav.home,
                    label: 'Home'),

                customBottomNavItem(
                    BottomNav: BottomNav.alert,
                    label: 'Alert'),
                customBottomNavItem(
                  BottomNav: BottomNav.profile,
                  label: 'Profile',
                ),
              ],
              onTap: (index) {
                if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ThreadDatabaseFilterPage(),
                    ),
                  );
                } else if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(),
                    ),
                  );
                }
                // Do nothing for Home (index 0)
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF064FAD), // Deep blue at the top
              Color(0xFFB8D4F5), // Light bluish-white fade in between
              Color(0xFFFFFFFF), // White at the bottom
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: ListView(
                        children: [
                          const SizedBox(height: 8),

                          // Show error message
                          if (provider.errorMessage.isNotEmpty)
                            // Carousel
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),

                              child: CarouselSlider(
                                options: CarouselOptions(
                                  height: 170.0,
                                  enlargeCenterPage: true,
                                  enableInfiniteScroll: true,
                                  autoPlay: true,
                                ),
                                items:
                                    [
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.asset(
                                              imagePath,
                                              fit: BoxFit.cover,
                                              width: MediaQuery.of(
                                                context,
                                              ).size.width,
                                            ),
                                          );
                                        },
                                      );
                                    }).toList(),
                              ),
                            ),

                          // ScamCarousel(),
                          const SizedBox(height: 16),

                          // Feature stats
                          // Container(
                          //   padding: const EdgeInsets.all(16),
                          //   decoration: BoxDecoration(
                          //     color: Colors.black.withOpacity(0.2),
                          //     borderRadius: BorderRadius.circular(16),
                          //   ),
                          //   child: Column(
                          //     children: provider.reportedFeatures.entries.map((
                          //       entry,
                          //     ) {
                          //       return Padding(
                          //         padding: const EdgeInsets.symmetric(
                          //           vertical: 8.0,
                          //         ),
                          //         child: Row(
                          //           children: [
                          //             Expanded(flex: 2, child: Text(entry.key)),
                          //             Expanded(
                          //               flex: 5,
                          //               child: LinearProgressIndicator(
                          //                 value: (entry.value is int)
                          //                     ? entry.value.toDouble()
                          //                     : entry.value,
                          //                 color: Colors.blue,
                          //                 backgroundColor: Colors.white,
                          //               ),
                          //             ),
                          //             const SizedBox(width: 8),
                          //             Text("${(entry.value * 100).toInt()}%"),
                          //           ],
                          //         ),
                          //       );
                          //     }).toList(),
                          //   ),
                          // ),
                          ReportedFeaturesPanel(),
                          const SizedBox(height: 16),

                          // Stats
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(20),

                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Thread Statistics",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    PeriodDropdown(),
                                    // Container(
                                    //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    //   decoration: BoxDecoration(
                                    //     color: Colors.white,
                                    //     borderRadius: BorderRadius.circular(8),
                                    //   ),
                                    //   child: Row(
                                    //     children: const [
                                    //       Text(
                                    //         "Weekly",
                                    //         style: TextStyle(
                                    //           color: Colors.black87,
                                    //           fontWeight: FontWeight.w600,
                                    //         ),
                                    //       ),
                                    //       Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
                                    //     ],
                                    //   ),
                                    // ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _StatCard(
                                      label: '50K+',
                                      desc: 'Scams Reported',
                                      highlight: true,
                                    ),
                                    _StatCard(
                                      label: '10K+',
                                      desc: 'Malware Samples',
                                      highlight: true,
                                    ),
                                    _StatCard(
                                      label: '24/7',
                                      desc: 'Threat Monitoring',
                                      highlight: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          ThreadAnalysisCard(),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
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
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, desc;
  final bool highlight;

  const _StatCard({
    required this.label,
    required this.desc,
    this.highlight = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: 100,
          height: 100,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
            decoration: BoxDecoration(
              color: highlight
                  ? const Color(0xFF042E6F)
                  : const Color(0xFF064FAD),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // const SizedBox(height: 4),
                Expanded(
                  child: Center(
                    child: Text(
                      desc,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// class _ReportButton extends StatelessWidget {
//   final String label;
//   final IconData icon;
//
//   const _ReportButton({required this.label, required this.icon});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         CircleAvatar(
//           radius: 26,
//           backgroundColor: Colors.white,
//           child: Icon(icon, color: Color(0xFF1E3A8A)),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           label,
//           style: const TextStyle(color: Colors.white, fontSize: 12),
//         ),
//       ],
//     );
//   }
// }
//
// class _BottomReportButton extends StatelessWidget {
//   final String label;
//   const _BottomReportButton({required this.label});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         label,
//         style: const TextStyle(color: Color(0xFF064FAD), fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }
