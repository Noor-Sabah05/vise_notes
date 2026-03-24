import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'api_config.dart';

class AIService {
  late final GenerativeModel _model;

  AIService() {
    _model = GenerativeModel(
      model: 'models/gemini-2.5-flash',
      apiKey: ApiConfig.geminiApiKey,
      requestOptions: const RequestOptions(apiVersion: 'v1'),
    );
  }

  Future<Map<String, String>> generateNotes(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    try {
      final response = await _model.generateContent([
        Content.multi([
          DataPart('audio/mpeg', bytes),
          TextPart("""Provide a JSON academic analysis: 
          {"title": "Title", "summary": "Overview", "content": "Detailed Notes", "key_points": "Facts"}""")
        ])
      ]);

      final data = jsonDecode(response.text!.replaceAll('```json', '').replaceAll('```', '').trim());
      return {
        "title": data['title'] ?? "Note",
        "summary": data['summary'] ?? "",
        "content": "${data['content']}\n\nKey Points:\n${data['key_points']}"
      };
    } catch (e) {
      throw Exception("AI Failed: $e");
    }
  }
}