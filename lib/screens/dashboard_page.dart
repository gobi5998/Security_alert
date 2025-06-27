import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../provider/dashboard_provider.dart';
import '../widget/graph_widget.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);

    return Scaffold(

      extendBody: true,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Security Alert", style: TextStyle(color: Colors.white)),
        actions: const [Icon(Icons.notifications, color: Colors.white)],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _BottomReportButton(label: 'Report Scam'),
                  _BottomReportButton(label: 'Report Malware'),
                  _BottomReportButton(label: 'Report Fraud'),
                ],
              ),
            ),
            BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white30,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.system_update), label: 'Update'),
                BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Alert'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ],
              onTap: (index) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tapped: ${['Home', 'Update', 'Alert', 'Profile'][index]}')),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF064FAD), Color(0xFFebebeb)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const SizedBox(height: 8),
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
                              value: entry.value,
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
                children: const [
                  _StatCard(label: '50K+', desc: 'Scams Reported'),
                  _StatCard(label: '10K+', desc: 'Malware Samples'),
                  _StatCard(label: '24/7', desc: 'Threat Monitoring'),
                ],
              ),

              const SizedBox(height: 16),

              const GraphWidget(),

              const SizedBox(height: 12),
            ],
          ),
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
