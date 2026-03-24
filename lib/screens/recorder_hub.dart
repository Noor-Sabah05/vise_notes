import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/pdf_service.dart';
import '../services/db_service.dart';
import '../models/note.dart';
import 'notes_screen.dart';

class RecorderHub extends StatefulWidget {
  @override
  _RecorderHubState createState() => _RecorderHubState();
}

class _RecorderHubState extends State<RecorderHub> {
  bool isRecording = false;
  bool isProcessing = false;
  final AIService _aiService = AIService();

  // Ensure this points to a real path on your device for testing
  String get mockFilePath => "/storage/emulated/0/Download/lecture.mp3";

  void _handleAIProcessing() async {
    setState(() => isProcessing = true);
    try {
      // 1. Generate AI Content
      final results = await _aiService.generateNotes(mockFilePath);

      // 2. Create PDF
      final pdfPath = await PDFService().createPDF(
        results['title']!,
        results['content']!,
      );

      // 3. Save to Local Database
      final newNote = Note(
        title: results['title']!,
        description: results['summary']!,
        date: DateTime.now().toString().split(' ')[0],
        pdfPath: pdfPath,
      );
      await DBService().insert(newNote);

      // 4. Navigate to View
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotesScreen(
            title: results['title']!,
            summary: results['summary']!,
            content: results['content']!,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recorder Hub",
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.person, color: Colors.white)),
                ],
              ),
            ),
            const Spacer(),
            Center(
              child: GestureDetector(
                onTap: () => setState(() => isRecording = !isRecording),
                child: Container(
                  height: 200, width: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRecording ? Colors.red.withOpacity(0.1) : Colors.blueAccent.withOpacity(0.05),
                    border: Border.all(color: isRecording ? Colors.red : Colors.blueAccent, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: isRecording ? Colors.red.withOpacity(0.3) : Colors.blueAccent.withOpacity(0.2),
                          blurRadius: 30, spreadRadius: 5
                      )
                    ],
                  ),
                  child: Icon(
                    isRecording ? Icons.stop : Icons.mic,
                    size: 80, color: isRecording ? Colors.red : Colors.blueAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(isRecording ? "Recording Lecture..." : "Tap to Start Recording",
                style: const TextStyle(color: Colors.white70, fontSize: 18)),
            const Spacer(),
            if (isProcessing)
              const CircularProgressIndicator(color: Colors.blueAccent)
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size(double.infinity, 65),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 10,
                  ),
                  onPressed: _handleAIProcessing,
                  child: const Text("Generate AI Study Notes",
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}