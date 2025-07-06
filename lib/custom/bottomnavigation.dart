import 'package:flutter/material.dart';

BottomNavigationBarItem customBottomNavItem({
  required String imagePath,
  required String label,
  double size = 24,
}) {
  return BottomNavigationBarItem(
    icon: Image.asset(
      imagePath,
      width: size,
      height: size,
    ),
    label: label,
  );
}
