import '../models/recording.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class RecordingService {
  static final RecordingService _instance = RecordingService._internal();

  factory RecordingService() {
    return _instance;
  }

  RecordingService._internal();

  final List<Recording> _savedTranscripts = [];
  final List<Recording> _cleanedAudios = [];

  List<Recording> get savedTranscripts => _savedTranscripts;
  List<Recording> get cleanedAudios => _cleanedAudios;

  void addTranscript(Recording recording) {
    _savedTranscripts.add(recording);
  }

  void addCleanedAudio(Recording recording) {
    _cleanedAudios.add(recording);
  }

  void removeTranscript(String id) {
    _savedTranscripts.removeWhere((rec) => rec.id == id);
  }

  void removeCleanedAudio(String id) {
    _cleanedAudios.removeWhere((rec) => rec.id == id);
  }

  void clear() {
    _savedTranscripts.clear();
    _cleanedAudios.clear();
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
