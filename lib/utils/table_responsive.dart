// lib/utils/responsive_table.dart
import 'package:flutter/material.dart';

class ResponsiveTable extends StatelessWidget {
  final String title;
  final List<DataColumn> columns;
  final List<DataRow> rows;

  const ResponsiveTable({
    Key? key,
    required this.title,
    required this.columns,
    required this.rows,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    // ALTURA OTIMIZADA
    final tableHeight = isMobile ? size.height * 0.38 : size.height * 0.55;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 17 : 19,
              ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: tableHeight,
          child: Scrollbar(
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double availableWidth = constraints.maxWidth;
                  final int columnCount = columns.length;
                  final double spacing = isMobile ? 8 : 12;
                  final double totalSpacing = spacing * (columnCount - 1);
                  final double columnWidth = (availableWidth - totalSpacing) / columnCount;

                  return DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.teal.shade50),
                    columnSpacing: spacing,
                    dataRowHeight: isMobile ? 78 : 68,
                    headingRowHeight: isMobile ? 50 : 60,
                    headingTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    dataTextStyle: const TextStyle(fontSize: 13),
                    columns: columns,
                    rows: rows.map((row) {
                      return DataRow(
                        cells: row.cells.asMap().entries.map((entry) {
                          final index = entry.key;
                          final cell = entry.value;
                          final isActionColumn = index == columns.length - 1;

                          return DataCell(
                            SizedBox(
                              width: columnWidth,
                              child: DefaultTextStyle(
                                style: const TextStyle(fontSize: 13),
                                child: isActionColumn
                                    ? cell.child
                                    : Text(
                                        (cell.child is Text)
                                            ? (cell.child as Text).data ?? ''
                                            : '',
                                        overflow: TextOverflow.visible,
                                        softWrap: true,
                                        maxLines: 4,
                                      ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}