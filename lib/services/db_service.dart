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
    final path = join(await getDatabasesPath(), "notes_v3.db");

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
          pdfPath TEXT
        )
        ''');
      },
    );
  }

  Future<void> insert(Note note) async {
    final database = await db;
    await database.insert("notes", note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Note>> getNotes() async {
    final database = await db;
    final res = await database.query("notes", orderBy: "id DESC");
    return res.map((e) => Note.fromMap(e)).toList();
  }
}