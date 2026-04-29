import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';

class DBService {
  static Database? _db;

  Future<Database> get db async {
    _db ??= await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), "visenotes_v1.db");

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          summary TEXT,
          date TEXT,
          pdfPath TEXT,
          category TEXT
        )
        ''');
      },
    );
  }

  Future<void> insert(Note note) async {
    final database = await db;
    await database.insert(
      "notes",
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Note>> getNotes() async {
    final database = await db;
    final res = await database.query("notes", orderBy: "id DESC");
    return res.map((e) => Note.fromMap(e)).toList();
  }

  Future<List<Note>> getNotesByCategory(String category) async {
    final database = await db;
    final res = await database.query(
      "notes",
      where: "category = ?",
      whereArgs: [category],
      orderBy: "id DESC",
    );
    return res.map((e) => Note.fromMap(e)).toList();
  }

  Future<List<String>> getUniqueCategories() async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT DISTINCT category FROM notes ORDER BY category ASC',
    );
    return result.map((row) => row['category'] as String).toList();
  }

  Future<int> getCategoryNoteCount(String category) async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM notes WHERE category = ?',
      [category],
    );
    return (result[0]['count'] as int?) ?? 0;
  }

  Future<String> getCategoryLastUpdated(String category) async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT date FROM notes WHERE category = ? ORDER BY date DESC LIMIT 1',
      [category],
    );
    if (result.isEmpty) return 'Never';

    final dateStr = result[0]['date'] as String?;
    if (dateStr == null) return 'Never';

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date).inDays;

      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      if (diff < 7) return '$diff days ago';
      if (diff < 30) return '${(diff / 7).ceil()} weeks ago';
      return '${(diff / 30).ceil()} months ago';
    } catch (e) {
      return 'Never';
    }
  }

  Future<void> deleteNote(int id) async {
    final database = await db;
    await database.delete("notes", where: "id = ?", whereArgs: [id]);
  }
}
