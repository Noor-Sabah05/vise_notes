import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../models/category_model.dart';
import '../models/note.dart';
import '../services/db_service.dart';

class NotesListScreen extends StatefulWidget {
  final Category category;
  const NotesListScreen({super.key, required this.category});

  @override
  _NotesListScreenState createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  List<Note> notes = [];
  final Color primaryColor = const Color(0xFF915BFF);

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  _loadNotes() async {
    final data = await DBService().getNotes();
    setState(() => notes = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        toolbarHeight: 120,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.category.name, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            Text("${notes.length} Notes", style: const TextStyle(color: Colors.white, fontSize: 20)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: notes.length,
              itemBuilder: (context, index) => _buildNoteCard(notes[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: primaryColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(note.description, style: const TextStyle(color: Colors.black87, fontSize: 16)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(note.date, style: const TextStyle(color: Colors.black54, fontSize: 16)),
              Row(
                children: [
                  _btnIcon(Icons.list_alt, () => OpenFile.open(note.pdfPath)),
                  _btnIcon(Icons.download_outlined, () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF is already saved in local storage.")));
                  }),
                  _btnIcon(Icons.share_outlined, () => Share.shareXFiles([XFile(note.pdfPath)])),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _btnIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: primaryColor),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: Colors.black87, size: 26),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search",
          prefixIcon: Icon(Icons.search, color: primaryColor, size: 28),
          suffixIcon: Icon(Icons.mic, color: primaryColor, size: 28),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(35), borderSide: BorderSide(color: primaryColor, width: 2)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(35), borderSide: BorderSide(color: primaryColor, width: 2)),
        ),
      ),
    );
  }
}