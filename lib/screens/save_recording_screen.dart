import 'package:flutter/material.dart';
import '../models/recording.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class SaveRecordingScreen extends StatefulWidget {
  final Recording recording;
  final List<String> categories;

  const SaveRecordingScreen({
    super.key,
    required this.recording,
    required this.categories,
  });

  @override
  State<SaveRecordingScreen> createState() => _SaveRecordingScreenState();
}

class _SaveRecordingScreenState extends State<SaveRecordingScreen> {
  late TextEditingController _titleController;
  late TextEditingController _customCategoryController;
  late List<String> _availableCategories;
  String? _selectedCategory;
  bool _isUsingCustomCategory = false;
  bool _saveTranscript = true;
  bool _saveCleanedAudio = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.recording.title.isEmpty ? '' : widget.recording.title,
    );
    _customCategoryController = TextEditingController();

    // Initialize available categories with a copy of widget.categories
    _availableCategories = List<String>.from(widget.categories);

    // Set selected category from recording or use first available
    if (widget.recording.category.isNotEmpty) {
      _selectedCategory = widget.recording.category;
    } else if (_availableCategories.isNotEmpty) {
      _selectedCategory = _availableCategories.first;
    } else {
      _selectedCategory = null;
    }

    debugPrint(
      '📋 SaveRecordingScreen initialized with categories: $_availableCategories',
    );
    debugPrint('📋 Selected category: $_selectedCategory');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _saveRecording() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    // Determine which category to use
    String? finalCategory;
    if (_isUsingCustomCategory && _customCategoryController.text.isNotEmpty) {
      finalCategory = _customCategoryController.text.trim();
    } else {
      finalCategory = _selectedCategory;
    }

    if (finalCategory == null || finalCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a category')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Update recording with user-provided title and category
      final updatedRecording = Recording(
        fileId: widget.recording.fileId,
        title: title,
        summary: widget.recording.summary,
        transcript: _saveTranscript ? widget.recording.transcript : '',
        notes: widget.recording.notes,
        category: finalCategory,
        language: widget.recording.language,
        duration: widget.recording.duration,
        cleanedAudioPath: _saveCleanedAudio
            ? widget.recording.cleanedAudioPath
            : '',
        pdfPath: widget.recording.pdfPath,
        createdAt: widget.recording.createdAt,
        status: widget.recording.status,
      );

      // Navigate to ResultScreen with updated recording
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResultScreen(recording: updatedRecording),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF9859FF),
        elevation: 0,
        title: const Text('Save Recording'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF9859FF), Color(0xFFD4A5FF)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recording Title Section
                const Text(
                  'Recording Title',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter recording title',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 20),

                // Category Section
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                // Predefined Categories Dropdown
                if (!_isUsingCustomCategory && _availableCategories.isNotEmpty)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      hint: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Select category',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _availableCategories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(category),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                  ),

                const SizedBox(height: 12),

                // Custom Category Toggle Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isUsingCustomCategory = !_isUsingCustomCategory;
                      if (!_isUsingCustomCategory) {
                        _customCategoryController.clear();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isUsingCustomCategory
                            ? Colors.blue
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _isUsingCustomCategory,
                          onChanged: (value) {
                            setState(() {
                              _isUsingCustomCategory = value ?? false;
                              if (!_isUsingCustomCategory) {
                                _customCategoryController.clear();
                              }
                            });
                          },
                          activeColor: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Add custom category',
                          style: TextStyle(color: Colors.black87, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                // Custom Category Input Field
                if (_isUsingCustomCategory)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      controller: _customCategoryController,
                      decoration: InputDecoration(
                        hintText: 'Enter custom category name',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Save Transcript Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _saveTranscript,
                              onChanged: (value) {
                                setState(() => _saveTranscript = value ?? true);
                              },
                              activeColor: const Color(0xFF9859FF),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Save Transcript',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_saveTranscript) ...[
                        Divider(color: Colors.grey[300]),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              widget.recording.transcript.isEmpty
                                  ? 'No transcript available'
                                  : widget.recording.transcript,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Save Cleaned Audio Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _saveCleanedAudio,
                          onChanged: (value) {
                            setState(() => _saveCleanedAudio = value ?? false);
                          },
                          activeColor: const Color(0xFF9859FF),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Save Cleaned Audio',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7539C9),
                      disabledBackgroundColor: Colors.grey[400],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
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
        ),
      ),
    );
  }
}
