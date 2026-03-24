/// Data model for a recording with transcript and generated notes
class Recording {
  final String fileId;
  final String title;
  final String? summary;
  final String transcript;
  final String notes;
  final String category;
  final String language;
  final double duration;
  final String cleanedAudioPath;
  final String pdfPath;
  final DateTime createdAt;
  final String status; // completed, processing, failed

  Recording({
    required this.fileId,
    required this.title,
    this.summary,
    required this.transcript,
    required this.notes,
    required this.category,
    this.language = 'en',
    this.duration = 0.0,
    this.cleanedAudioPath = '',
    this.pdfPath = '',
    required this.createdAt,
    this.status = 'completed',
  });

  /// Create Recording from backend API response
  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      fileId: json['file_id'] ?? '',
      title: json['note_title'] ?? 'Untitled',
      summary: json['note_summary'],
      transcript: json['transcript'] ?? '',
      notes: json['note_content'] ?? '',
      category: json['category'] ?? 'General',
      language: json['language'] ?? 'en',
      duration: (json['duration_seconds'] ?? 0.0).toDouble(),
      cleanedAudioPath: json['cleaned_audio_path'] ?? '',
      pdfPath: json['pdf_path'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      status: json['status'] ?? 'completed',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'file_id': fileId,
      'note_title': title,
      'note_summary': summary,
      'transcript': transcript,
      'note_content': notes,
      'category': category,
      'language': language,
      'duration_seconds': duration,
      'cleaned_audio_path': cleanedAudioPath,
      'pdf_path': pdfPath,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }
}
