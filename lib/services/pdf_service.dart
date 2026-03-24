import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PDFService {
  Future<String> createPDF(String title, String content) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(content, style: const pw.TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final safeTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
    final file = File("${dir.path}/${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf");

    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}