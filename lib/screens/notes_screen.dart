import 'package:flutter/material.dart';

class NotesScreen extends StatelessWidget {
  final String title;
  final String summary;
  final String content;

  const NotesScreen({super.key, required this.title, required this.summary, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 20),
                      SizedBox(width: 8),
                      Text("AI SUMMARY", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(summary, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("Detailed Lecture Notes",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Divider(color: Colors.white12),
            const SizedBox(height: 10),
            Text(content,
                style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6, letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }
}