// lib/widgets/report_table.dart
import 'package:flutter/material.dart';

class ReportTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> data;

  ReportTable({required this.headers, required this.data});

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: headers.map((header) => DataColumn(label: Text(header))).toList(),
      rows: data.map((row) => DataRow(cells: row.map((cell) => DataCell(Text(cell))).toList())).toList(),
    );
  }
}