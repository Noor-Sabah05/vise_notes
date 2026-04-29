class Note {
  final int? id;
  final String title;
  final String description; // This acts as the summary
  final String date;
  final String? pdfPath;
  final String? category;

  Note({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    this.pdfPath,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "summary": description, // Database uses 'summary'
      "date": date,
      "pdfPath": pdfPath,
      "category": category,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map["id"],
      title: map["title"] ?? "",
      description: map["summary"] ?? "",
      date: map["date"] ?? "",
      pdfPath: map["pdfPath"],
      category: map["category"],
    );
  }
}
