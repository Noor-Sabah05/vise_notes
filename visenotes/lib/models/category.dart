import 'package:flutter/material.dart';

class Category {
  final String name;
  final int noteCount;
  final String lastUpdated;
  final IconData icon;
  final Color color;

  Category({
    required this.name,
    required this.noteCount,
    required this.lastUpdated,
    required this.icon,
    required this.color,
  });
}

// Map category names to icons and colors
final Map<String, IconData> categoryIcons = {
  'Mathematics': Icons.functions,
  'Physics': Icons.fitness_center,
  'Chemistry': Icons.science_outlined,
  'Programming': Icons.desktop_windows_outlined,
  'AI & ML': Icons.smart_toy_outlined,
  'General': Icons.memory_outlined,
  'Science': Icons.science,
  'History': Icons.history_edu,
  'Language': Icons.language,
};

final Map<String, Color> categoryColors = {
  'Mathematics': Color(0xFF7B78D8),
  'Physics': Color(0xFFFFA069),
  'Chemistry': Color(0xFFFF6B6B),
  'Programming': Color(0xFF38A3A5),
  'AI & ML': Color(0xFFD471D4),
  'General': Color(0xFF6B6B6B),
  'Science': Color(0xFF00BCD4),
  'History': Color(0xFF8B4513),
  'Language': Color(0xFF4CAF50),
};

IconData getCategoryIcon(String categoryName) {
  return categoryIcons[categoryName] ?? Icons.memory_outlined;
}

Color getCategoryColor(String categoryName) {
  return categoryColors[categoryName] ?? const Color(0xFF6B6B6B);
}
