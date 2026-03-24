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
}
