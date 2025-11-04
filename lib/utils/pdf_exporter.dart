import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart';

// ignore: unused_local_variable
Future<void> exportPdf({
  required String title,
  required List<String> headers,
  required List<List<String>> data,
  required String total,
  required String employeeName,
}) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => [
        pw.Header(level: 0, child: pw.Text(title, style: const pw.TextStyle(fontSize: 24))),
        pw.Table.fromTextArray(headers: headers, data: data),
        pw.SizedBox(height: 20),
        pw.Text('Total: $total MT'),
        pw.SizedBox(height: 20),
        pw.Text('Assinatura Digital: $employeeName', style: const pw.TextStyle(fontSize: 12)),
      ],
    ),
  );
  final bytes = await pdf.save();
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', 'relatorio_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf')
    ..click();
  html.Url.revokeObjectUrl(url);
}