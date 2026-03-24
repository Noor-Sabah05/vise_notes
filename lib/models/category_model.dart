import 'package:flutter/material.dart';

class Category {
  final String name;
  final String noteCount;
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