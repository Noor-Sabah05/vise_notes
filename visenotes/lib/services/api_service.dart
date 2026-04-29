import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Unified API Service for ViseNotes Backend
/// Handles all audio, notes, PDF, and quiz operations
class ApiService {
  /// Backend base URL - change to your server IP/domain
  static const String baseUrl = 'http://192.168.100.55:8000';

  // ─────────────────────────────────────────────────────────────
  // AUDIO PROCESSING
  // ─────────────────────────────────────────────────────────────

  /// Clean/preprocess audio file (remove noise)
  /// Returns: cleaned audio file as bytes
  static Future<List<int>> cleanAudio(File audioFile) async {
    final uri = Uri.parse('$baseUrl/clean-audio');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath('file', audioFile.path),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(minutes: 5),
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw ApiException(response, 'Failed to clean audio');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // TRANSCRIPTION
  // ─────────────────────────────────────────────────────────────

  /// Transcribe audio file to text using Whisper
  /// Returns: {file_id, transcript, language, duration}
  static Future<Map<String, dynamic>> transcribeAudio(File audioFile) async {
    final uri = Uri.parse('$baseUrl/transcribe');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath('file', audioFile.path),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(minutes: 15), // Whisper can be slow
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response, 'Failed to transcribe audio');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // NOTES GENERATION
  // ─────────────────────────────────────────────────────────────

  /// Generate structured notes from transcript
  /// Returns: {title, summary, content, key_points}
  static Future<Map<String, dynamic>> generateNotes(String transcript) async {
    final uri = Uri.parse('$baseUrl/generate-notes');

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'transcript': transcript}),
        )
        .timeout(const Duration(minutes: 5));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response, 'Failed to generate notes');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // PDF GENERATION
  // ─────────────────────────────────────────────────────────────

  /// Generate PDF from transcript
  /// Returns: PDF file as bytes
  static Future<List<int>> generatePdfFromTranscript(String transcript) async {
    final uri = Uri.parse('$baseUrl/generate-pdf');

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'transcript': transcript}),
        )
        .timeout(const Duration(minutes: 5));

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw ApiException(response, 'Failed to generate PDF');
    }
  }

  /// Convert audio file to PDF (single-step pipeline)
  /// Returns: PDF file as bytes
  static Future<List<int>> audioPdf(File audioFile) async {
    final uri = Uri.parse('$baseUrl/audio-to-pdf');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath('file', audioFile.path),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(minutes: 20),
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw ApiException(response, 'Failed to convert audio to PDF');
    }
  }

  /// Full pipeline: transcribe + generate notes + create PDF from raw audio
  /// Returns: PDF file as bytes
  static Future<List<int>> processAudio(File audioFile) async {
    final uri = Uri.parse('$baseUrl/process-audio');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath('file', audioFile.path),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(minutes: 20),
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw ApiException(response, 'Failed to process audio');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // QUIZ GENERATION
  // ─────────────────────────────────────────────────────────────

  /// Generate quiz from PDF file
  /// Returns: Quiz PDF file as bytes
  static Future<List<int>> generateQuizFromPdf(File pdfFile) async {
    final uri = Uri.parse('$baseUrl/generate-quiz-pdf');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath('file', pdfFile.path));

    final streamedResponse = await request.send().timeout(
      const Duration(minutes: 10),
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw ApiException(response, 'Failed to generate quiz');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // HEALTH CHECK
  // ─────────────────────────────────────────────────────────────

  /// Check if backend is running
  static Future<bool> healthCheck() async {
    try {
      final uri = Uri.parse('$baseUrl/');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final http.Response response;
  final String message;

  ApiException(this.response, this.message);

  @override
  String toString() {
    try {
      final body = jsonDecode(response.body);
      final detail = body['detail'] ?? message;
      return 'API Error: $detail (${response.statusCode})';
    } catch (e) {
      return 'API Error: $message (${response.statusCode})';
    }
  }
}
