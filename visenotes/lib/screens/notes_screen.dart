import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';
import '../models/note.dart';
import '../models/category.dart';

class NotesScreen extends StatefulWidget {
  final String? title;
  final String? summary;
  final String? content;
  final String? keyPoints;
  final String? transcript;
  final File? audioFile;

  const NotesScreen({
    super.key,
    this.title,
    this.summary,
    this.content,
    this.keyPoints,
    this.transcript,
    this.audioFile,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool _isGeneratingPdf = false;
  bool _isGeneratingQuiz = false;
  String? _pdfPath;
  String? _quizPath;
  String? _errorMessage;

  /// Generate PDF from current transcript
  Future<void> _generatePdf() async {
    if (widget.transcript == null || widget.transcript!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No transcript available')));
      return;
    }

    setState(() => _isGeneratingPdf = true);
    try {
      final pdfBytes = await ApiService.generatePdfFromTranscript(
        widget.transcript!,
      );
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/notes_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(pdfBytes);

      setState(() => _pdfPath = file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF generated successfully'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => _openFile(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  /// Generate quiz from generated PDF
  Future<void> _generateQuiz() async {
    if (_pdfPath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generate PDF first')));
      return;
    }

    setState(() => _isGeneratingQuiz = true);
    try {
      final pdfFile = File(_pdfPath!);
      final quizBytes = await ApiService.generateQuizFromPdf(pdfFile);

      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/quiz_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(quizBytes);

      setState(() => _quizPath = file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Quiz generated successfully'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => _openFile(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isGeneratingQuiz = false);
    }
  }

  /// Open file with default application
  void _openFile(String filePath) async {
    try {
      OpenFile.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cannot open file: $e')));
    }
  }

  /// Save note to local database
  Future<void> _saveNoteToLibrary() async {
    if (widget.title == null || widget.title!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No note to save')));
      return;
    }

    // Show category selection dialog
    final selectedCategory = await _showCategorySelectionDialog();
    if (selectedCategory == null) return; // User cancelled

    try {
      final note = Note(
        title: widget.title!,
        description: widget.summary ?? '',
        date: DateTime.now().toString().split(' ')[0],
        pdfPath: _pdfPath,
        category: selectedCategory,
      );

      await DBService().insert(note);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note saved to library'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showCategorySelectionDialog() async {
    final categories = [
      'General',
      'Mathematics',
      'Physics',
      'Chemistry',
      'Programming',
      'AI & ML',
      'Science',
      'History',
      'Language',
    ];

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                leading: Icon(
                  getCategoryIcon(category),
                  color: getCategoryColor(category),
                ),
                title: Text(category),
                onTap: () => Navigator.pop(context, category),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF9859FF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title ?? 'Notes',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.title != null) const SizedBox(height: 8),
                  if (widget.title != null)
                    Text(
                      'Generated from transcript',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            if (widget.title == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.note,
                        size: 80,
                        color: Color(0xFF9859FF),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No Notes Yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Record or upload audio to generate notes',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Card
                      if (widget.summary != null && widget.summary!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9859FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF9859FF),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Color(0xFF9859FF),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'AI SUMMARY',
                                    style: TextStyle(
                                      color: Color(0xFF9859FF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.summary!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Detailed Notes
                      if (widget.content != null && widget.content!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detailed Notes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.content!,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      // Key Points
                      if (widget.keyPoints != null &&
                          widget.keyPoints!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Key Points',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.keyPoints!,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            // Action Buttons
            if (widget.title != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isGeneratingPdf ? null : _generatePdf,
                            icon: _isGeneratingPdf
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.picture_as_pdf),
                            label: Text(
                              _isGeneratingPdf ? 'Generating...' : 'PDF',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9859FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isGeneratingQuiz || _pdfPath == null
                                ? null
                                : _generateQuiz,
                            icon: _isGeneratingQuiz
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.quiz),
                            label: Text(
                              _isGeneratingQuiz ? 'Generating...' : 'Quiz',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9859FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveNoteToLibrary,
                        icon: const Icon(Icons.bookmark),
                        label: const Text('Save to Library'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
