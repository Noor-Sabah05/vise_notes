import 'package:flutter/material.dart';
import 'dart:io';
import '../models/recording.dart';
import '../models/note.dart';
import '../services/recording_service.dart';
import '../services/db_service.dart';

class SaveScreen extends StatefulWidget {
  final String? transcript;
  final File? selectedFile;
  final String? fileName;
  final String? selectedCategory;

  const SaveScreen({
    super.key,
    this.transcript,
    this.selectedFile,
    this.fileName,
    this.selectedCategory,
  });

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen> {
  late TextEditingController _titleController;
  late TextEditingController _transcriptController;
  late TextEditingController _cleanedAudioController;
  late TextEditingController _customCategoryController;
  String _selectedCategory = 'General';
  bool _saveTranscript = true;
  bool _saveCleanedAudio = false;

  final List<String> _categories = [
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _transcriptController = TextEditingController(
      text: widget.transcript ?? '',
    );
    _cleanedAudioController = TextEditingController();
    _customCategoryController = TextEditingController();

    // Pre-fill category if provided
    if (widget.selectedCategory != null &&
        widget.selectedCategory != 'Select Category' &&
        _categories.contains(widget.selectedCategory!)) {
      _selectedCategory = widget.selectedCategory!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _transcriptController.dispose();
    _cleanedAudioController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _addCustomCategory() {
    final customCategory = _customCategoryController.text.trim();
    if (customCategory.isNotEmpty && !_categories.contains(customCategory)) {
      setState(() {
        _categories.add(customCategory);
        _selectedCategory = customCategory;
        _customCategoryController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "$customCategory" added!'),
          backgroundColor: const Color(0xFF9859FF),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (_categories.contains(customCategory)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category already exists!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF9859FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Save Recording',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title input
            const Text(
              'Recording Title',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Enter recording title',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF9859FF),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF9859FF),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF7D01DB),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Category selector
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              items: _categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF9859FF),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF9859FF),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFCCCCFF).withOpacity(0.3),
              ),
              isExpanded: true,
            ),
            const SizedBox(height: 12),
            // Custom category input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customCategoryController,
                    decoration: InputDecoration(
                      hintText: 'Add custom category',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF9859FF),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF9859FF),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF7D01DB),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF9859FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addCustomCategory,
                    tooltip: 'Add custom category',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Transcript section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFCCCCFF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF9859FF), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _saveTranscript,
                        onChanged: (value) {
                          setState(() => _saveTranscript = value ?? false);
                        },
                        activeColor: const Color(0xFF9859FF),
                      ),
                      const Text(
                        'Save Transcript',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  if (_saveTranscript) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _transcriptController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'Transcript text',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF9859FF),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF9859FF),
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Cleaned audio section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFCCCCFF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF9859FF), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _saveCleanedAudio,
                        onChanged: (value) {
                          setState(() => _saveCleanedAudio = value ?? false);
                        },
                        activeColor: const Color(0xFF9859FF),
                      ),
                      const Text(
                        'Save Cleaned Audio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  if (_saveCleanedAudio) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF9859FF),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.fileName ?? 'No audio file selected',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.fileName != null)
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Color(0xFF9859FF),
                              ),
                              onPressed: () {},
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final title = _titleController.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a recording title'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final recordingService = RecordingService();
                  final now = DateTime.now();
                  final id = DateTime.now().millisecondsSinceEpoch.toString();

                  // Get file size to estimate duration (rough estimate: ~50KB per second)
                  final fileSize = widget.selectedFile?.lengthSync() ?? 0;
                  final estimatedDuration = Duration(
                    seconds: (fileSize / 50000).round(),
                  );
                  final filePath = widget.selectedFile?.path ?? '';

                  // Save transcript if enabled
                  if (_saveTranscript &&
                      _transcriptController.text.isNotEmpty) {
                    final transcriptRecording = Recording(
                      id: id,
                      title: title,
                      category: _selectedCategory,
                      date: now,
                      duration: estimatedDuration,
                      filePath: filePath,
                      transcript: _transcriptController.text,
                      cleanedAudio: '',
                    );
                    recordingService.addTranscript(transcriptRecording);

                    // Also save to database for library view
                    try {
                      final note = Note(
                        title: title,
                        description: _transcriptController.text.substring(
                          0,
                          _transcriptController.text.length > 100
                              ? 100
                              : _transcriptController.text.length,
                        ),
                        date: now.toString().split(' ')[0],
                        category: _selectedCategory,
                      );
                      await DBService().insert(note);
                    } catch (e) {
                      // Silently fail if database save fails
                      print('Error saving to database: $e');
                    }
                  }

                  // Save cleaned audio if enabled
                  if (_saveCleanedAudio && widget.selectedFile != null) {
                    final cleanedAudioRecording = Recording(
                      id: id,
                      title: title,
                      category: _selectedCategory,
                      date: now,
                      duration: estimatedDuration,
                      filePath: filePath,
                      transcript: '',
                      cleanedAudio: widget.fileName ?? 'cleaned_audio.wav',
                    );
                    recordingService.addCleanedAudio(cleanedAudioRecording);
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recording saved successfully!'),
                      backgroundColor: Color(0xFF9859FF),
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7D01DB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Recording',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
