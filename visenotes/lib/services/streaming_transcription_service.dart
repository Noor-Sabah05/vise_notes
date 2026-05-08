import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class StreamingTranscriptionService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _transcriptionController;
  String _baseUrl;

  StreamingTranscriptionService({String? baseUrl})
    : _baseUrl = baseUrl ?? 'ws://192.168.100.9:8000';

  Stream<Map<String, dynamic>>? get transcriptionStream =>
      _transcriptionController?.stream;

  bool get isConnected => _channel != null;

  Future<void> connect() async {
    if (_channel != null) {
      return;
    }

    try {
      print(
        'Connecting to transcription WebSocket: $_baseUrl/ws/transcribe-stream',
      );

      _channel = WebSocketChannel.connect(
        Uri.parse('$_baseUrl/ws/transcribe-stream'),
      );

      _transcriptionController =
          StreamController<Map<String, dynamic>>.broadcast();

      // Listen to WebSocket messages
      _channel!.stream.listen(
        (message) {
          try {
            final decoded = jsonDecode(message);
            print('Received from WebSocket: ${decoded['type']}');
            _transcriptionController?.add(decoded);
          } catch (e) {
            print('Error decoding WebSocket message: $e');
            _transcriptionController?.addError('Decoding error: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _transcriptionController?.addError(error);
        },
        onDone: () {
          print('WebSocket connection closed');
          _transcriptionController?.close();
          _channel = null;
        },
      );
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      rethrow;
    }
  }

  void sendAudioChunk(Uint8List audioBytes) {
    if (_channel == null) {
      print('WebSocket not connected, cannot send audio chunk');
      return;
    }

    try {
      _channel!.sink.add(audioBytes);
    } catch (e) {
      print('Error sending audio chunk: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      if (_channel != null) {
        print('Closing WebSocket connection');
        await _channel!.sink.close(status.goingAway);
        _channel = null;
      }

      if (_transcriptionController != null) {
        await _transcriptionController!.close();
        _transcriptionController = null;
      }
    } catch (e) {
      print('Error closing WebSocket: $e');
    }
  }

  void updateBaseUrl(String newUrl) {
    _baseUrl = newUrl;
  }
}
