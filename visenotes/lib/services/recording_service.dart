import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/recording.dart';

class RecordingService {
  static final RecordingService _instance = RecordingService._internal();

  factory RecordingService() {
    return _instance;
  }

  RecordingService._internal();

  final List<Recording> _savedTranscripts = [];
  final List<Recording> _cleanedAudios = [];
  bool _initialized = false;

  List<Recording> get savedTranscripts => _savedTranscripts;
  List<Recording> get cleanedAudios => _cleanedAudios;

  Future<void> init() async {
    if (_initialized) return;
    final file = await _getStorageFile();
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        try {
          final data = jsonDecode(content) as Map<String, dynamic>;
          final transcripts = data['savedTranscripts'] as List<dynamic>?;
          final audios = data['cleanedAudios'] as List<dynamic>?;
          _savedTranscripts.clear();
          _cleanedAudios.clear();
          if (transcripts != null) {
            _savedTranscripts.addAll(
              transcripts
                  .map((item) => Recording.fromMap(item as Map<String, dynamic>)),
            );
          }
          if (audios != null) {
            _cleanedAudios.addAll(
              audios
                  .map((item) => Recording.fromMap(item as Map<String, dynamic>)),
            );
          }
        } catch (_) {
          // If file is corrupt or unreadable, start fresh.
          _savedTranscripts.clear();
          _cleanedAudios.clear();
        }
      }
    }
    _initialized = true;
  }

  Future<File> _getStorageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/recordings.json');
  }

  Future<void> _saveToDisk() async {
    try {
      final file = await _getStorageFile();
      final jsonData = jsonEncode({
        'savedTranscripts': _savedTranscripts.map((r) => r.toMap()).toList(),
        'cleanedAudios': _cleanedAudios.map((r) => r.toMap()).toList(),
      });
      await file.writeAsString(jsonData);
    } catch (_) {
      // Ignore disk write failures for now.
    }
  }

  void addTranscript(Recording recording) {
    _savedTranscripts.add(recording);
    _saveToDisk();
  }

  void addCleanedAudio(Recording recording) {
    _cleanedAudios.add(recording);
    _saveToDisk();
  }

  void removeTranscript(String id) {
    _savedTranscripts.removeWhere((rec) => rec.id == id);
    _saveToDisk();
  }

  void removeCleanedAudio(String id) {
    _cleanedAudios.removeWhere((rec) => rec.id == id);
    _saveToDisk();
  }

  void clear() {
    _savedTranscripts.clear();
    _cleanedAudios.clear();
    _saveToDisk();
  }

  /// Download cleaned audio to device storage
  Future<bool> downloadCleanedAudio(Recording recording) async {
    try {
      if (recording.cleanedAudio == null) {
        throw Exception('No cleaned audio available');
      }

      final sourceFile = File(recording.cleanedAudio!);
      if (!sourceFile.existsSync()) {
        throw Exception('Source file not found');
      }

      final applicationDocDir = await FilePicker.platform.saveFile(
        fileName: '${recording.title}.flac',
        type: FileType.audio,
      );

      if (applicationDocDir != null) {
        await sourceFile.copy(applicationDocDir);
        return true;
      }
      return false;
    } catch (e) {
      print('Error downloading audio: $e');
      return false;
    }
  }

  /// Play cleaned audio (returns file path for audio player)
  Future<String?> getPlayableAudioPath(Recording recording) async {
    try {
      if (recording.cleanedAudio == null) {
        throw Exception('No cleaned audio available');
      }

      final sourceFile = File(recording.cleanedAudio!);
      if (!sourceFile.existsSync()) {
        throw Exception('Source file not found');
      }

      return recording.cleanedAudio;
    } catch (e) {
      print('Error getting audio path: $e');
      return null;
    }
  }
}
