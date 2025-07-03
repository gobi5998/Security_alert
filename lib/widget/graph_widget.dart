import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/dashboard_provider.dart';

class GraphWidget extends StatelessWidget {
  const GraphWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);

    return Container(

      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Thread Analysis", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['1D', '5D', '1M', '1Y', 'ALL'].map((label) {
              final isSelected = provider.selectedTab == label;
              return GestureDetector(
                onTap: () => provider.changeTab(label),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade800 : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: _LineGraphPainter(provider.threatDataLine),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineGraphPainter extends CustomPainter {
  final List<double> points;

  _LineGraphPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (points.isNotEmpty) {
      final dx = size.width / (points.length - 1);
      path.moveTo(0, size.height - points[0]);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(dx * i, size.height - points[i]);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LineGraphPainter oldDelegate) => true;
}
