import 'package:flutter/material.dart';

class ReportSuccess extends StatefulWidget {
  final String label;
  const ReportSuccess({super.key, required this.label});

  @override
  State<ReportSuccess> createState() => _ReportSuccessState();
}

class _ReportSuccessState extends State<ReportSuccess> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.7),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(widget.label, style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
              const Text("Successfully Submit", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
