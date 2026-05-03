import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';
import '../services/recording_service.dart';
import '../models/note.dart';
import '../models/recording.dart';
import 'notes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Select Category';
  bool _isRecording = false;
  bool _isLoading = false;
  File? _selectedFile;
  String? _fileName;
  String? _transcript;
  String? _errorMessage;
  String? _feedbackMessage;
  Color _feedbackColor = const Color(0xFF9859FF);

  final List<String> _categories = [
    'Business',
    'Computer Science',
    'Personal',
    'Education',
    'Meeting',
    'Interview',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF9859FF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Record',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Content area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    // Category dropdown
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        items: ['Select Category', ..._categories]
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null && value != 'Select Category') {
                            setState(() => _selectedCategory = value);
                          }
                        },
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF9859FF),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF9859FF),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFCCCCFF),
                        ),
                        isExpanded: true,
                      ),
                    ),
                    const SizedBox(height: 60),
                    // Microphone button (dummy)
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _isRecording = !_isRecording);
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF9859FF),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9859FF).withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Timer
                    Text(
                      _isRecording ? '00:00' : '00:00',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 60),
                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.withOpacity(0.3),
                              Colors.grey.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Upload audio file option
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Or upload an audio file',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _pickFile,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF9859FF),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFFCCCCFF).withOpacity(0.3),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.cloud_upload_outlined,
                                    color: Color(0xFF9859FF),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _fileName ?? 'Select audio file',
                                    style: const TextStyle(
                                      color: Color(0xFF9859FF),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Upload button
                    if (_selectedFile != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _uploadAndTranscribe,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9859FF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Transcribe',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (_feedbackMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Container(
                            key: ValueKey(_feedbackMessage),
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _feedbackColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _feedbackMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_feedbackMessage != null) const SizedBox(height: 20),
                    // Display transcript if available
                    if (_transcript != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCCCFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF9859FF),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Transcript:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9859FF),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _transcript!,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF9859FF,
                                  ).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Saved automatically to Transcripts & Audio',
                                  style: TextStyle(
                                    color: Color(0xFF3F007D),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Display error if any
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red, width: 2),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
        _transcript = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _uploadAndTranscribe() async {
    if (_selectedFile == null) return;

    setState(() {
      _isLoading = true;
      _transcript = null;
      _errorMessage = null;
    });

    try {
      // Step 1: Transcribe audio
      final transcriptResult = await ApiService.transcribeAudio(_selectedFile!);
      final transcript = transcriptResult['transcript'];

      setState(() {
        _transcript = transcript;
      });

      _showInlineFeedback('Transcript ready and saved');
      _autoSaveTranscriptAndPdf(transcript);
      if (_selectedFile != null) {
        _autoSaveCleanedAudio(_selectedFile!);
      }

      // Step 2: Generate notes from transcript
      try {
        final notesResult = await ApiService.generateNotes(transcript);

        // Step 3: Navigate to NotesScreen with generated notes
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotesScreen(
                title: notesResult['title'] ?? 'Notes',
                summary: notesResult['summary'] ?? '',
                content: notesResult['content'] ?? '',
                keyPoints: notesResult['key_points'] ?? '',
                transcript: transcript,
                audioFile: _selectedFile,
              ),
            ),
          );
        }
      } catch (e) {
        // If notes generation fails, still show transcript
        setState(() {
          _errorMessage = 'Transcript ready. Note generation failed: $e';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      _showInlineFeedback(
        _errorMessage ?? 'Unable to transcribe',
        color: Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _safeCategory() {
    return _selectedCategory == 'Select Category' || _selectedCategory.isEmpty
        ? 'General'
        : _selectedCategory;
  }

  Duration _estimateDuration(File file) {
    final fileSize = file.lengthSync();
    return Duration(seconds: (fileSize / 50000).round());
  }

  void _showInlineFeedback(
    String message, {
    Color color = const Color(0xFF9859FF),
  }) {
    setState(() {
      _feedbackMessage = message;
      _feedbackColor = color;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _feedbackMessage = null);
      }
    });
  }

  Future<void> _autoSaveTranscriptAndPdf(String transcript) async {
    if (_selectedFile == null) return;

    final recordingService = RecordingService();
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final title = _fileName ?? 'Transcript ${now.millisecondsSinceEpoch}';
    final category = _safeCategory();
    final duration = _estimateDuration(_selectedFile!);
    final filePath = _selectedFile!.path;

    recordingService.addTranscript(
      Recording(
        id: id,
        title: title,
        category: category,
        date: now,
        duration: duration,
        filePath: filePath,
        transcript: transcript,
        cleanedAudio: '',
      ),
    );

    try {
      final pdfBytes = await ApiService.generatePdfFromTranscript(transcript);
      final dir = await getApplicationDocumentsDirectory();
      final pdfPath =
          '${dir.path}/transcript_${now.millisecondsSinceEpoch}.pdf';
      await File(pdfPath).writeAsBytes(pdfBytes);
      await DBService().insert(
        Note(
          title: title,
          description: transcript.length > 100
              ? transcript.substring(0, 100)
              : transcript,
          date: now.toIso8601String().split('T').first,
          pdfPath: pdfPath,
          category: category,
        ),
      );
      if (mounted) {
        _showInlineFeedback('Transcript PDF ready and saved to library');
      }
    } catch (e) {
      if (mounted) {
        _showInlineFeedback(
          'Transcript saved, but PDF generation failed',
          color: Colors.orange,
        );
      }
      await DBService().insert(
        Note(
          title: title,
          description: transcript.length > 100
              ? transcript.substring(0, 100)
              : transcript,
          date: now.toIso8601String().split('T').first,
          category: category,
        ),
      );
    }
  }

  Future<void> _autoSaveCleanedAudio(File audioFile) async {
    final recordingService = RecordingService();
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final title = _fileName ?? 'Cleaned audio ${now.millisecondsSinceEpoch}';
    final category = _safeCategory();
    final duration = _estimateDuration(audioFile);
    final filePath = audioFile.path;

    if (mounted) {
      _showInlineFeedback('Cleaning audio...');
    }

    try {
      final cleanedBytes = await ApiService.cleanAudio(audioFile);
      final dir = await getApplicationDocumentsDirectory();
      final cleanedPath =
          '${dir.path}/cleaned_${now.millisecondsSinceEpoch}.wav';
      await File(cleanedPath).writeAsBytes(cleanedBytes);

      recordingService.addCleanedAudio(
        Recording(
          id: id,
          title: title,
          category: category,
          date: now,
          duration: duration,
          filePath: filePath,
          transcript: '',
          cleanedAudio: cleanedPath,
        ),
      );

      if (mounted) {
        _showInlineFeedback('Cleaned audio ready and added to recordings');
      }
    } catch (e) {
      if (mounted) {
        _showInlineFeedback('Audio cleaning failed', color: Colors.red);
      }
    }
  }
}
