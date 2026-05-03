import 'package:flutter/material.dart';
import 'dart:io';
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

  /// Generate PDF from current transcript
  Future<void> _generatePdf() async {
    if (widget.transcript == null || widget.transcript!.isEmpty) {
      _showMessage('No transcript available', backgroundColor: Colors.red);
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
        _showMessage(
          'PDF generated successfully',
          backgroundColor: const Color(0xFF2563EB),
          actionLabel: 'Open',
          onAction: () => _openFile(file.path),
        );
      }
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      if (mounted) {
        _showMessage('Error generating PDF: $e', backgroundColor: Colors.red);
      }
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  /// Generate quiz from generated PDF
  Future<void> _generateQuiz() async {
    if (_pdfPath == null) {
      _showMessage('Generate PDF first', backgroundColor: Colors.red);
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

      if (mounted) {
        _showMessage(
          'Quiz generated successfully',
          backgroundColor: const Color(0xFF2563EB),
          actionLabel: 'Open',
          onAction: () => _openFile(file.path),
        );
      }
    } catch (e) {
      debugPrint('Error generating quiz: $e');
      if (mounted) {
        _showMessage('Error generating quiz: $e', backgroundColor: Colors.red);
      }
    } finally {
      setState(() => _isGeneratingQuiz = false);
    }
  }

  /// Show a transient toast-like snackbar.
  void _showMessage(
    String message, {
    Color backgroundColor = Colors.black87,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction,
                textColor: Colors.white,
              )
            : null,
      ),
    );
  }

  /// Open file with default application
  void _openFile(String filePath) async {
    try {
      OpenFile.open(filePath);
    } catch (e) {
      _showMessage('Cannot open file: $e', backgroundColor: Colors.red);
    }
  }

  /// Save note to local database
  Future<void> _saveNoteToLibrary() async {
    if (widget.title == null || widget.title!.isEmpty) {
      _showMessage('No note to save', backgroundColor: Colors.red);
      return;
    }

    if (_pdfPath == null || _pdfPath!.isEmpty) {
      _showMessage('Generate the PDF first before saving to library', backgroundColor: Colors.red);
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
        _showMessage(
          'Note saved to library',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error saving note: $e', backgroundColor: Colors.red);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final actionButtonWidth = screenWidth > 620 ? (screenWidth - 72) / 2 : double.infinity;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7D01DB), Color(0xFF3D00A3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.12),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 255, 255, 0.16),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          'AI Notes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.title ?? 'Study Notes',
                        style: const TextStyle(
                          fontSize: 34,
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
                            color: const Color.fromRGBO(255, 255, 255, 0.85),
                          ),
                        ),
                    ],
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
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFB678FF), Color(0xFF9859FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromRGBO(0, 0, 0, 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'AI SUMMARY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.summary!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.7,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Detailed Notes
                      if (widget.content != null && widget.content!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6FAFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF93C5FD)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromRGBO(59, 130, 246, 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.article, color: Color(0xFF1D4ED8)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Detailed Notes',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Read through the full note content below.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                widget.content!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.8,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Key Points
                      if (widget.keyPoints != null &&
                          widget.keyPoints!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFBBF24)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromRGBO(249, 115, 22, 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb,
                                    color: Color(0xFFB45309),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Key Points',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Quick takeaways to review fast.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF854D0E),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: widget.keyPoints!
                                    .split(RegExp(r'\n|•|-'))
                                    .map((point) => point.trim())
                                    .where((point) => point.isNotEmpty)
                                    .map(
                                      (point) => Chip(
                                        backgroundColor:
                                            const Color.fromRGBO(180, 83, 9, 0.12),
                                        label: Text(
                                          point,
                                          style: const TextStyle(
                                            color: Color(0xFF7C2D12),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
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
                      color: const Color.fromRGBO(0, 0, 0, 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: actionButtonWidth,
                          child: ElevatedButton.icon(
                            onPressed: _isGeneratingPdf || _pdfPath != null ? null : _generatePdf,
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
                              _isGeneratingPdf
                                  ? 'Generating...'
                                  : _pdfPath == null
                                      ? 'Make PDF'
                                      : 'PDF Created',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9859FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: actionButtonWidth,
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
                              _isGeneratingQuiz ? 'Generating...' : 'Create Quiz',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
