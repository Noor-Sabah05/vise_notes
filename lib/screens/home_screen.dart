import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../models/recording.dart';
import 'result_screen.dart';
import 'processing_screen.dart';
import 'save_recording_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  List<String> _categories = [];
  String? _selectedCategory;
  late TextEditingController _customCategoryController;
  bool _isUsingCustomCategory = false;
  File? _selectedFile;
  String? _fileName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _customCategoryController = TextEditingController();
    _loadCategories();
  }

  @override
  void dispose() {
    _customCategoryController.dispose();
    super.dispose();
  }

  /// Load available categories from backend
  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      setState(() => _categories = categories);
      if (categories.isNotEmpty) {
        setState(() => _selectedCategory = categories.first);
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  /// Pick audio file from device
  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        setState(() {
          _selectedFile = file;
          _fileName = result.files.single.name;
        });

        debugPrint(
          '📁 File selected: $_fileName (${file.lengthSync() / 1024}KB)',
        );
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  /// Upload audio and start processing
  Future<void> _uploadAudio() async {
    if (_selectedFile == null) {
      _showError('Please select an audio file');
      return;
    }

    // Determine which category to use
    String? categoryToUse;
    if (_isUsingCustomCategory && _customCategoryController.text.isNotEmpty) {
      categoryToUse = _customCategoryController.text.trim();
    } else {
      categoryToUse = _selectedCategory;
    }

    if (categoryToUse == null || categoryToUse.isEmpty) {
      _showError('Please select or enter a category');
      return;
    }

    // Show processing screen
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProcessingScreen(
          fileName: _fileName ?? 'audio',
          category: categoryToUse!,
          audioFile: _selectedFile!,
          onComplete: _onProcessingComplete,
        ),
      ),
    );
  }

  /// Called when processing completes
  void _onProcessingComplete(Recording recording) {
    // Go to save recording screen
    Navigator.of(context).pop();
    if (!mounted) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => SaveRecordingScreen(
              recording: recording,
              categories: _categories,
            ),
          ),
        )
        .then((_) {
          // Reset when returning
          setState(() {
            _selectedFile = null;
            _fileName = null;
          });
        });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('ViseNotes'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9859FF), Color(0xFF5A3BA5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Upload & Process',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Audio → Transcript → Notes',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Selection
                        const Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Predefined Categories Dropdown
                        if (!_isUsingCustomCategory && _categories.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF9859FF),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              underline: const SizedBox(),
                              hint: const Text('Select category'),
                              items: _categories
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                  _customCategoryController.clear();
                                });
                              },
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Custom Category Toggle
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
                              border: Border.all(
                                color: _isUsingCustomCategory
                                    ? const Color(0xFF9859FF)
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
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
                                  activeColor: const Color(0xFF9859FF),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Add custom category',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Custom Category Input
                        if (_isUsingCustomCategory)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: TextField(
                              controller: _customCategoryController,
                              decoration: InputDecoration(
                                hintText: 'Enter custom category name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF9859FF),
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF9859FF),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),

                        const SizedBox(height: 32),
                        // File Selection
                        const Text(
                          'Audio File',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _pickAudioFile,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF9859FF),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFF9859FF).withOpacity(0.05),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 48,
                                  color: const Color(0xFF9859FF),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _fileName ?? 'Tap to select audio file',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _fileName != null
                                        ? Colors.black87
                                        : Colors.grey[600],
                                    fontWeight: _fileName != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (_selectedFile != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Upload Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _uploadAudio,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9859FF),
                              disabledBackgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Process Audio',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Info Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Processing includes:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '✓ Noise reduction\n✓ Audio transcription\n✓ AI-powered notes\n✓ PDF generation',
                                style: TextStyle(
                                  color: Colors.blue[900],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
