import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  }) : super(key: key);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (size.width >= 1100) {
      return desktop;
    } else if (size.width >= 650 && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

// EXTENSÃO ULTRA OTIMIZADA
extension ResponsiveExtension on BuildContext {
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);

  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;

  // ALTURA RESPONSIVA (MAIS ESPAÇO PARA TABELA)
  double tableHeight([double mobile = 0.38, double tablet = 0.50, double desktop = 0.60]) {
    if (isMobile) return height * mobile;
    if (isTablet) return height * tablet;
    return height * desktop;
  }

  // TABELA ESTICADA AO MÁXIMO
  Widget responsiveTable({
    required String title,
    required List<DataColumn> columns,
    required List<DataRow> rows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(this).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 16 : 18,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: tableHeight(),
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
                  final double spacing = isMobile ? 6 : 10;
                  final double totalSpacing = spacing * (columnCount - 1);
                  final double columnWidth = (availableWidth - totalSpacing) / columnCount;

                  return DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.teal.shade50),
                    columnSpacing: spacing,
                    dataRowHeight: isMobile ? 70 : 60,
                    headingRowHeight: isMobile ? 45 : 55,
                    headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    dataTextStyle: const TextStyle(fontSize: 11),
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
                                style: const TextStyle(fontSize: 11),
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