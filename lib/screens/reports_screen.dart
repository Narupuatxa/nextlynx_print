import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/sales_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart' as custom_app_bar;
import '../models/product.dart';
import 'package:universal_html/html.dart' as html;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'daily';
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    salesProvider.initSummary();
    salesProvider.fetchSales();
  }

  Future<void> _selectCustomRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null && mounted) {
      setState(() {
        _customRange = range;
        _selectedPeriod = 'custom';
      });
    }
  }

  List<Sale> _filterSales(SalesProvider provider) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'daily':
        return provider.sales.where((sale) =>
            sale.createdAt.year == now.year &&
            sale.createdAt.month == now.month &&
            sale.createdAt.day == now.day).toList();
      case 'weekly':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return provider.sales.where((sale) =>
            sale.createdAt.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            sale.createdAt.isBefore(endOfWeek.add(const Duration(days: 1)))).toList();
      case 'monthly':
        return provider.sales.where((sale) =>
            sale.createdAt.year == now.year &&
            sale.createdAt.month == now.month).toList();
      case 'custom':
        if (_customRange != null) {
          return provider.sales.where((sale) =>
              sale.createdAt.isAfter(_customRange!.start.subtract(const Duration(days: 1))) &&
              sale.createdAt.isBefore(_customRange!.end.add(const Duration(days: 1)))).toList();
        }
        return provider.sales;
      default:
        return provider.sales;
    }
  }

  double _calculateTotalProfit(List<Sale> sales, List<Product> products) {
    return sales.fold(0.0, (sum, sale) {
      final product = products.firstWhere(
        (p) => p.id == sale.productId,
        orElse: () => Product(
          id: '',
          name: '',
          price: 0,
          cost: 0,
          stock: 0,
          lowStockThreshold: 5,
          employeeId: '',
        ),
      );
      final profitPerUnit = product.price - product.cost;
      return sum + (profitPerUnit * sale.quantity);
    });
  }

  Future<void> _exportToPdf(List<Sale> sales, List<Product> products, String employeeName) async {
    final pdf = pw.Document();
    final totalProfit = _calculateTotalProfit(sales, products);
    final fmt = NumberFormat.currency(locale: 'pt_MZ', symbol: 'MT');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('Relatório de Vendas - NetLynx Print', style: const pw.TextStyle(fontSize: 24))),
          pw.SizedBox(height: 10),
          pw.Text('Período: ${_getPeriodLabel()}'),
          pw.Text('Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Produto', 'Qtd', 'Preço', 'Custo', 'Lucro Unit.', 'Margem (%)', 'Data'],
            data: sales.map((sale) {
              final product = products.firstWhere(
                (p) => p.id == sale.productId,
                orElse: () => Product(
                  id: '',
                  name: 'Desconhecido',
                  price: 0,
                  cost: 0,
                  stock: 0,
                  lowStockThreshold: 5,
                  employeeId: '',
                ),
              );
              final profit = product.price - product.cost;
              final margin = product.price > 0 ? (profit / product.price * 100).toStringAsFixed(1) : '0.0';
              return [
                product.name,
                sale.quantity.toString(),
                fmt.format(product.price),
                fmt.format(product.cost),
                fmt.format(profit),
                margin,
                DateFormat('dd/MM/yyyy').format(sale.createdAt),
              ];
            }).toList(),
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total de Vendas: ${fmt.format(sales.fold(0.0, (s, sale) => s + sale.total))}'),
              pw.Text('Lucro Total: ${fmt.format(totalProfit)}', style: pw.TextStyle(color: PdfColors.green700, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Text('Assinatura Digital: $employeeName', style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );

    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'relatorio_vendas_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _exportToExcel(List<Sale> sales, List<Product> products) async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    final totalProfit = _calculateTotalProfit(sales, products);

    sheet.getRangeByName('A1').setText('Produto');
    sheet.getRangeByName('B1').setText('Qtd');
    sheet.getRangeByName('C1').setText('Preço');
    sheet.getRangeByName('D1').setText('Custo');
    sheet.getRangeByName('E1').setText('Lucro Unit.');
    sheet.getRangeByName('F1').setText('Margem (%)');
    sheet.getRangeByName('G1').setText('Data');
    sheet.getRangeByName('A1:G1').cellStyle.bold = true;

    for (int i = 0; i < sales.length; i++) {
      final sale = sales[i];
      final product = products.firstWhere(
        (p) => p.id == sale.productId,
        orElse: () => Product(
          id: '',
          name: 'Desconhecido',
          price: 0,
          cost: 0,
          stock: 0,
          lowStockThreshold: 5,
          employeeId: '',
        ),
      );
      final profit = product.price - product.cost;
      final margin = product.price > 0 ? (profit / product.price * 100).toStringAsFixed(1) : '0.0';
      final row = i + 2;
      sheet.getRangeByName('A$row').setText(product.name);
      sheet.getRangeByName('B$row').setNumber(sale.quantity.toDouble());
      sheet.getRangeByName('C$row').setNumber(product.price);
      sheet.getRangeByName('D$row').setNumber(product.cost);
      sheet.getRangeByName('E$row').setNumber(profit);
      sheet.getRangeByName('F$row').setText(margin);
      sheet.getRangeByName('G$row').setText(DateFormat('dd/MM/yyyy').format(sale.createdAt));
    }

    final totalRow = sales.length + 3;
    sheet.getRangeByName('A$totalRow').setText('TOTAL');
    sheet.getRangeByName('C$totalRow').setNumber(sales.fold(0.0, (s, sale) => s + sale.total));
    sheet.getRangeByName('E$totalRow').setNumber(totalProfit);
    sheet.getRangeByName('A$totalRow:F$totalRow').cellStyle.bold = true;

    final bytes = workbook.saveAsStream();
    final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'relatorio_vendas_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);
    workbook.dispose();
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'daily': return 'Hoje';
      case 'weekly': return 'Esta Semana';
      case 'monthly': return 'Este Mês';
      case 'custom': return 'Período Personalizado';
      default: return 'Todos os Registros';
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesProvider = Provider.of<SalesProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.role == 'admin';
    final filteredSales = _filterSales(salesProvider);
    final totalRevenue = filteredSales.fold(0.0, (sum, sale) => sum + sale.total);
    final totalProfit = isAdmin ? _calculateTotalProfit(filteredSales, salesProvider.products) : 0.0;
    final fmt = NumberFormat.currency(locale: 'pt_MZ', symbol: 'MT');

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      appBar: custom_app_bar.CustomAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/reports_bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black12, BlendMode.darken),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relatórios de Vendas',
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: Colors.teal.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 20 : 24,
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            DropdownButton<String>(
                              value: _selectedPeriod,
                              items: const [
                                DropdownMenuItem(value: 'daily', child: Text('Diário')),
                                DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                                DropdownMenuItem(value: 'monthly', child: Text('Mensal')),
                                DropdownMenuItem(value: 'custom', child: Text('Personalizado')),
                              ],
                              onChanged: (value) async {
                                setState(() {
                                  _selectedPeriod = value!;
                                  if (value != 'custom') _customRange = null;
                                });
                                if (value == 'custom') await _selectCustomRange(context);
                              },
                            ),

                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final employeeName = authProvider.user?.email ?? 'Funcionário';
                                    await _exportToPdf(filteredSales, salesProvider.products, employeeName);
                                    Fluttertoast.showToast(msg: 'PDF exportado com sucesso!', backgroundColor: Colors.green);
                                  },
                                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                  label: const Text('Exportar PDF', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await _exportToExcel(filteredSales, salesProvider.products);
                                    Fluttertoast.showToast(msg: 'Excel exportado com sucesso!', backgroundColor: Colors.green);
                                  },
                                  icon: const Icon(Icons.table_chart, color: Colors.green),
                                  label: const Text('Exportar Excel', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade50,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Card(
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Resumo Financeiro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _summaryBox('Receita Total', fmt.format(totalRevenue), Colors.blue),
                            if (isAdmin) _summaryBox('Lucro Total', fmt.format(totalProfit), Colors.green),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: isMobile ? 180 : 200,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: true),
                              titlesData: const FlTitlesData(show: true),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: filteredSales.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.total)).toList(),
                                  isCurved: true,
                                  color: Colors.teal,
                                  dotData: const FlDotData(show: true),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // TABELA DO RELATÓRIO DO ADMINISTRADOR (100% PRESERVADA)
                Card(
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Detalhes das Vendas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),

                        // TABELA ORIGINAL (SEM RESUMO)
                        Scrollbar(
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: SizedBox(
                              width: 1000,
                              child: DataTable(
                                border: TableBorder.all(color: Colors.grey.shade400, width: 1.0),
                                columnSpacing: 24,
                                dataRowHeight: 48,
                                headingTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                dataTextStyle: const TextStyle(fontSize: 14),
                                columns: const [
                                  DataColumn(label: Text('Produto')),
                                  DataColumn(label: Text('Qtd')),
                                  DataColumn(label: Text('Preço')),
                                  DataColumn(label: Text('Custo')),
                                  DataColumn(label: Text('Lucro Unit.')),
                                  DataColumn(label: Text('Margem (%)')),
                                  DataColumn(label: Text('Data')),
                                ],
                                rows: filteredSales.map((sale) {
                                  final product = salesProvider.products.firstWhere(
                                    (p) => p.id == sale.productId,
                                    orElse: () => Product(
                                      id: '',
                                      name: 'Desconhecido',
                                      price: 0,
                                      cost: 0,
                                      stock: 0,
                                      lowStockThreshold: 5,
                                      employeeId: '',
                                    ),
                                  );
                                  final profit = product.price - product.cost;
                                  final margin = product.price > 0 ? (profit / product.price * 100).toStringAsFixed(1) : '0.0';
                                  return DataRow(cells: [
                                    DataCell(Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Text(product.name),
                                    )),
                                    DataCell(Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Text(sale.quantity.toString()),
                                    )),
                                    DataCell(Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Text(fmt.format(product.price)),
                                    )),
                                    DataCell(Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Text(fmt.format(product.cost)),
                                    )),
                                    DataCell(Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Text(fmt.format(profit)),
                                    )),
                                    DataCell(Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Text('$margin%'),
                                    )),
                                    DataCell(Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Text(DateFormat('dd/MM/yyyy').format(sale.createdAt)),
                                    )),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: Colors.teal.shade700)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
        ],
      ),
    );
  }
}

extension on double? {
  double? operator +(double other) {
    return null;
  }
}