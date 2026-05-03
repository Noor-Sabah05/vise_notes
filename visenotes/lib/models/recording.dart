import 'dart:convert';

class Recording {
  final String id;
  final String title;
  final String category;
  final DateTime date;
  final Duration duration;
  final String filePath;
  final String? transcript;
  final String? cleanedAudio;

  Recording({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.duration,
    required this.filePath,
    this.transcript,
    this.cleanedAudio,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'date': date.toIso8601String(),
      'duration': duration.inMilliseconds,
      'filePath': filePath,
      'transcript': transcript,
      'cleanedAudio': cleanedAudio,
    };
  }

  factory Recording.fromMap(Map<String, dynamic> map) {
    return Recording(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      duration: Duration(
        milliseconds: (map['duration'] is int)
            ? map['duration'] as int
            : int.tryParse(map['duration']?.toString() ?? '0') ?? 0,
      ),
      filePath: map['filePath'] as String? ?? '',
      transcript: map['transcript'] as String?,
      cleanedAudio: map['cleanedAudio'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Recording.fromJson(String source) => Recording.fromMap(jsonDecode(source));
}
