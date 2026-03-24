import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/recording.dart';

class ProcessingScreen extends StatefulWidget {
  final String fileName;
  final String category;
  final File audioFile;
  final Function(Recording) onComplete;

  const ProcessingScreen({
    super.key,
    required this.fileName,
    required this.category,
    required this.audioFile,
    required this.onComplete,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  late ApiService _apiService;
  String _currentStep = 'Preparing...';
  List<String> _steps = [
    'Validating audio format',
    'Reducing background noise',
    'Normalizing audio',
    'Transcribing with AI',
    'Generating notes',
    'Creating PDF',
    'Saving to database',
  ];
  int _currentStepIndex = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    try {
      // Simulate step progression
      _updateStep(0);
      await Future.delayed(const Duration(seconds: 1));

      _updateStep(1);
      await Future.delayed(const Duration(seconds: 2));

      _updateStep(2);
      await Future.delayed(const Duration(seconds: 1));

      _updateStep(3);
      
      // Actually upload the file
      final recording = await _apiService.uploadAudioAndGenerateNotes(
        audioFile: widget.audioFile,
        category: widget.category,
      );

      _updateStep(4);
      await Future.delayed(const Duration(seconds: 1));

      _updateStep(5);
      await Future.delayed(const Duration(seconds: 1));

      _updateStep(6);
      await Future.delayed(const Duration(seconds: 1));

      // Success! Call completion callback
      if (mounted) {
        widget.onComplete(recording);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      debugPrint('Processing error: $e');
    }
  }

  void _updateStep(int index) {
    if (mounted) {
      setState(() {
        _currentStepIndex = index;
        _currentStep = _steps[index];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _error == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9859FF), Color(0xFF5A3BA5)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: Center(
                    child: _error == null
                        ? TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(seconds: 2),
                            builder: (context, value, child) {
                              return Transform.rotate(
                                angle: value * 6.28,
                                child: const Icon(
                                  Icons.mic,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              );
                            },
                          )
                        : const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                // File info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.fileName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '📁 ${widget.category}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Status text
                Text(
                  _error == null ? _currentStep : 'Processing failed',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Progress indicator
                if (_error == null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (_currentStepIndex + 1) / _steps.length,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_currentStepIndex + 1} of ${_steps.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
                // Steps list
                const SizedBox(height: 32),
                Column(
                  children: List.generate(
                    _steps.length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index < _currentStepIndex
                                  ? Colors.green
                                  : index == _currentStepIndex
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                            ),
                            child: Center(
                              child: index < _currentStepIndex
                                  ? const Icon(
                                      Icons.check,
                                      color: Color(0xFF5A3BA5),
                                      size: 18,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: index == _currentStepIndex
                                            ? Colors.black87
                                            : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _steps[index],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: index <= _currentStepIndex
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Error message
                if (_error != null) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Error occurred',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
