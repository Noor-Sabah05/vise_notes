import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/recording.dart';

class ApiService {
  static String baseURL =
      'http://192.168.0.106:8000'; // ← Change to your backend IP
  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseURL,
        connectTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(
          minutes: 15,
        ), // Extended timeout for Whisper transcription and Gemini note generation
        contentType: 'application/json',
      ),
    );

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          responseHeader: false,
        ),
      );
    }
  }

  /// Main endpoint: Upload audio and get complete pipeline result
  /// Returns: transcript, notes, pdf path, cleaned audio path, etc.
  Future<Recording> uploadAudioAndGenerateNotes({
    required File audioFile,
    required String category,
  }) async {
    try {
      if (!audioFile.existsSync()) {
        throw Exception('Audio file not found: ${audioFile.path}');
      }

      final fileName = audioFile.path.split('/').last;

      // Create multipart form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFile.path,
          filename: fileName,
        ),
        'category': category,
      });

      debugPrint('📤 Uploading audio: $fileName');
      debugPrint('📁 File size: ${audioFile.lengthSync() / 1024 / 1024} MB');
      debugPrint('🏷️  Category: $category');

      // Call the main integrated endpoint
      final response = await _dio.post('/api/upload', data: formData);

      if (response.statusCode == 200) {
        debugPrint('✅ Upload successful');
        final recording = Recording.fromJson(response.data);
        debugPrint('📝 Transcript length: ${recording.transcript.length}');
        debugPrint('📄 Notes length: ${recording.notes.length}');
        return recording;
      } else {
        throw Exception('Upload failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      debugPrint('❌ Error uploading audio: ${e.message}');
      if (e.response != null) {
        throw Exception(
          'Upload failed: ${e.response?.data['detail'] ?? e.message}',
        );
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      throw Exception('Error: $e');
    }
  }

  /// Get all recordings
  Future<Map<String, dynamic>> getAllRecordings({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/api/recordings',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return {
          'recordings': (data['recordings'] as List)
              .map((r) => Recording.fromJson(r as Map<String, dynamic>))
              .toList(),
          'total': data['total'],
          'limit': data['limit'],
          'offset': data['offset'],
        };
      } else {
        throw Exception('Failed to fetch recordings');
      }
    } on DioException catch (e) {
      throw Exception('Error fetching recordings: ${e.message}');
    }
  }

  /// Get recordings by category
  Future<Map<String, dynamic>> getRecordingsByCategory({
    required String category,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/api/recordings/category/$category',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return {
          'recordings': (data['recordings'] as List)
              .map((r) => Recording.fromJson(r as Map<String, dynamic>))
              .toList(),
          'total': data['total'],
        };
      } else {
        throw Exception('Failed to fetch recordings');
      }
    } on DioException catch (e) {
      throw Exception('Error: ${e.message}');
    }
  }

  /// Get single recording by file ID
  Future<Recording> getRecordingById(String fileId) async {
    try {
      final response = await _dio.get('/api/recordings/$fileId');

      if (response.statusCode == 200) {
        return Recording.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Recording not found');
      }
    } on DioException catch (e) {
      throw Exception('Error: ${e.message}');
    }
  }

  /// Get available categories
  Future<List<String>> getCategories() async {
    try {
      final response = await _dio.get('/api/categories');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return List<String>.from(data['categories'] as List);
      } else {
        throw Exception('Failed to fetch categories');
      }
    } on DioException catch (e) {
      // Return default categories if API fails
      debugPrint('⚠️  Could not fetch categories: ${e.message}');
      return [
        'Mathematics',
        'Physics',
        'Chemistry',
        'Biology',
        'History',
        'Literature',
        'Programming',
        'General',
      ];
    }
  }

  /// Download PDF file
  Future<bool> downloadPdf(String fileId) async {
    try {
      final response = await _dio.get(
        '/api/download/pdf/$fileId',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        // Implementation would save to device
        debugPrint('✅ PDF downloaded');
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('❌ Error downloading PDF: ${e.message}');
      return false;
    }
  }

  /// Download cleaned audio file
  Future<bool> downloadAudio(String fileId) async {
    try {
      final response = await _dio.get(
        '/api/download/audio/$fileId',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Audio downloaded');
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('❌ Error downloading audio: ${e.message}');
      return false;
    }
  }

  /// Delete recording
  Future<bool> deleteRecording(String fileId) async {
    try {
      final response = await _dio.delete('/api/recordings/$fileId');

      if (response.statusCode == 200) {
        debugPrint('✅ Recording deleted');
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('❌ Error deleting recording: ${e.message}');
      return false;
    }
  }

  /// Health check
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/api/health');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Health check failed: $e');
      return false;
    }
  }
}
