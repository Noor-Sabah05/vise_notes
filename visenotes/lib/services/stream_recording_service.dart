import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:typed_data';

class StreamRecordingService {
  static final StreamRecordingService _instance =
      StreamRecordingService._internal();

  factory StreamRecordingService() {
    return _instance;
  }

  StreamRecordingService._internal();

  late FlutterSoundRecorder _recorder;
  bool _isInitialized = false;
  bool _isRecording = false;

  // Stream for audio data from recording
  final StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>.broadcast();

  // Duration timer
  Timer? _durationTimer;
  int _recordingDurationMs = 0;

  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  int get recordingDurationMs => _recordingDurationMs;
  bool get isRecording => _isRecording;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _recorder = FlutterSoundRecorder();
    await _recorder.openRecorder();
    _isInitialized = true;
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> startRecording() async {
    if (!_isInitialized) {
      throw Exception(
        'StreamRecordingService not initialized. Call initialize() first.',
      );
    }

    if (_isRecording) {
      return;
    }

    // Clear previous recording duration
    _recordingDurationMs = 0;

    // Request microphone permission
    final hasPermission = await requestMicrophonePermission();
    if (!hasPermission) {
      throw Exception('Microphone permission denied');
    }

    // Start recording with PCM output (for streaming)
    // Using raw PCM: mono, 16-bit, 16kHz
    await _recorder.startRecorder(
      toStream: _audioStreamController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
    );

    _isRecording = true;

    // Start duration timer
    _durationTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      _recordingDurationMs += 100;
    });
  }

  Future<void> stopRecording() async {
    if (!_isRecording) {
      return;
    }

    _durationTimer?.cancel();
    _isRecording = false;

    // Stop recorder (will close stream)
    await _recorder.stopRecorder();
  }

  Future<void> pauseRecording() async {
    if (!_isRecording) {
      return;
    }

    _durationTimer?.cancel();
    _isRecording = false;

    await _recorder.pauseRecorder();
  }

  Future<void> resumeRecording() async {
    if (_isRecording) {
      return;
    }

    _isRecording = true;

    await _recorder.resumeRecorder();

    // Resume duration timer
    _durationTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      _recordingDurationMs += 100;
    });
  }

  Future<void> dispose() async {
    _durationTimer?.cancel();
    _recorder.closeRecorder();
    await _audioStreamController.close();
    _isInitialized = false;
  }

  String getFormattedDuration() {
    final seconds = (_recordingDurationMs ~/ 1000) % 60;
    final minutes = _recordingDurationMs ~/ 60000;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
