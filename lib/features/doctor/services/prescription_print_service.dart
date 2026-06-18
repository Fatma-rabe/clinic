import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/patient.dart';

class PrescriptionPrintService {
  static Future<void> print({
    required Patient patient,
    required String diagnosis,
    required String prescription,
    required List<String> selectedDrugs,
    required String doctorName,
  }) async {
    final doc = pw.Document();
    final dateStr = DateFormat.yMMMMd().format(DateTime.now());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ORTHOPEDIC CLINIC',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Prescription · $dateStr'),
              pw.Divider(),
              pw.SizedBox(height: 16),
              pw.Text('Patient: ${patient.name}'),
              pw.Text('Age: ${patient.age} · Phone: ${patient.phone}'),
              pw.SizedBox(height: 20),
              pw.Text(
                'Diagnosis',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(diagnosis.isEmpty ? '—' : diagnosis),
              pw.SizedBox(height: 16),
              pw.Text(
                'Prescription',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (selectedDrugs.isNotEmpty) ...[
                      pw.Text(
                        'Medicines:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic),
                      ),
                      pw.SizedBox(height: 4),
                      ...selectedDrugs.map((d) => pw.Text('• $d')),
                      pw.SizedBox(height: 12),
                    ],
                    pw.Text(
                      prescription.isEmpty && selectedDrugs.isEmpty ? '—' : prescription,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 32),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(doctorName),
                    pw.Text('Orthopedic Surgeon'),
                    pw.SizedBox(height: 40),
                    pw.Container(
                      width: 180,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide()),
                      ),
                    ),
                    pw.Text('Signature'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }
}
