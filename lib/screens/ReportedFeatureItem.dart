import 'package:flutter/material.dart';

class ReportedFeatureItem extends StatelessWidget {
  final String iconPath;
  final String title;
  final double progress; // From 0.0 to 1.0
  final String percentage;
  final String onAdd;

  const ReportedFeatureItem({
    super.key,
    required this.iconPath,
    required this.title,
    required this.progress,
    required this.percentage,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60, // 👈 Fixed height to ensure vertical centering
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Image.asset(iconPath, width: 40, height: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600,color: Colors.white)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20,height: 40,),
          Row(
            children: [
              Text(percentage, style: const TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
              const SizedBox(width: 10,),
              GestureDetector(
                onTap: (){ Navigator.pop(context); // Close drawer
                Navigator.pushNamed(context, onAdd);},

                  child: Image.asset('assets/icon/add.png',width: 24,height: 24, ),

              ),
            ],
          )
        ],
      ),
    );
  }
}
