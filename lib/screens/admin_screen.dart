import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/services_provider.dart';
import '../models/service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  DateTimeRange? _selectedDateRange;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  final ScrollController _servicesScrollController = ScrollController();
  final ScrollController _ordersScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Provider.of<ServicesProvider>(context, listen: false).fetchServices().catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar serviços: $error'), backgroundColor: Colors.red.shade700),
      );
    });
    Provider.of<ServicesProvider>(context, listen: false).fetchServiceOrders().catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar ordens: $error'), backgroundColor: Colors.red.shade700),
      );
    });
  }

  Future<void> _generateAndDownloadPdf(List<Service> services, List<ServiceOrder> orders) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('Relatório de Serviços - NetLynx Print')),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              'Serviço',
              'Cat.',
              'Tipo',
              'C.Compra',
              'C.Mat.',
              'V.Venda',
              'Qtd.',
              'V.Total',
              'L.Total',
              'Data',
            ],
            data: services.map((service) {
              final relatedOrders = orders.where((order) => order.serviceId == service.id).toList();
              final totalProfit = relatedOrders.fold<double>(
                0.0,
                (sum, order) => sum + (order.totalPrice - (service.purchaseCost + service.materialCost) * order.quantity),
              );
              return [
                service.name,
                service.category,
                service.type ?? 'N/A',
                service.purchaseCost.toStringAsFixed(0),
                service.materialCost.toStringAsFixed(0),
                service.saleValue.toStringAsFixed(0),
                service.dailyQuantitySold.toString(),
                service.totalValue.toStringAsFixed(0),
                totalProfit.toStringAsFixed(0),
                DateFormat('dd/MM').format(service.createdAt),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Ordens de Serviço', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            headers: ['Ordem ID', 'Serviço', 'Qtd.', 'Total', 'Data'],
            data: orders.map((order) {
              final service = services.firstWhere(
                (s) => s.id == order.serviceId,
                orElse: () => Service(
                  id: '',
                  name: 'Desconhecido',
                  category: '',
                  fixedPrice: 0.0,
                  type: '',
                  purchaseCost: 0.0,
                  materialCost: 0.0,
                  saleValue: 0.0,
                  dailyQuantitySold: 0,
                  totalValue: 0.0,
                  createdAt: DateTime.now(),
                  employeeId: '',
                ),
              );
              return [
                order.id,
                service.name,
                order.quantity.toString(),
                order.totalPrice.toStringAsFixed(0),
                DateFormat('dd/MM HH:mm').format(order.createdAt),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    try {
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'relatorio_netlynx_print.pdf');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Relatório PDF gerado com sucesso'),
          backgroundColor: Colors.teal.shade700,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar PDF: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.teal.shade700,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  List<Service> _filterServices(List<Service> services) {
    if (_selectedDateRange == null) return services;
    return services.where((service) {
      return service.createdAt.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
             service.createdAt.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  List<ServiceOrder> _filterOrders(List<ServiceOrder> orders) {
    if (_selectedDateRange == null) return orders;
    return orders.where((order) {
      return order.createdAt.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
             order.createdAt.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  double _calculateTotalProfit(List<Service> services, List<ServiceOrder> orders) {
    return services.fold<double>(
      0.0,
      (sum, service) {
        final relatedOrders = orders.where((order) => order.serviceId == service.id).toList();
        return sum +
            relatedOrders.fold<double>(
              0.0,
              (orderSum, order) => orderSum + (order.totalPrice - (service.purchaseCost + service.materialCost) * order.quantity),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicesProvider = Provider.of<ServicesProvider>(context);
    final allServices = servicesProvider.services;
    final allOrders = servicesProvider.serviceOrders;
    final filteredServices = _filterServices(allServices);
    final filteredOrders = _filterOrders(allOrders);
    final categoryTotals = <String, double>{
      'estampagem': 0.0,
      'design_grafico': 0.0,
      'reprografia': 0.0,
    };
    final totalProfit = _calculateTotalProfit(filteredServices, filteredOrders);

    for (var order in filteredOrders) {
      final service = filteredServices.firstWhere(
        (s) => s.id == order.serviceId,
        orElse: () => Service(
          id: '',
          name: 'Desconhecido',
          category: '',
          fixedPrice: 0.0,
          type: '',
          purchaseCost: 0.0,
          materialCost: 0.0,
          saleValue: 0.0,
          dailyQuantitySold: 0,
          totalValue: 0.0,
          createdAt: DateTime.now(),
          employeeId: '',
        ),
      );
      categoryTotals[service.category] = (categoryTotals[service.category] ?? 0.0) + order.totalPrice;
    }

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios do Administrador', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal.shade600,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white, size: 36),
            tooltip: 'Baixar Relatório em PDF',
            onPressed: () => _generateAndDownloadPdf(filteredServices, filteredOrders),
          ),
        ],
      ),
      body: Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relatórios do Administrador',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: _selectDateRange,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Intervalo', style: TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    if (_selectedDateRange != null)
                      Text(
                        '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                        style: const TextStyle(fontSize: 13, color: Colors.teal),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Análise por Categoria',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: categoryTotals['estampagem'] ?? 0.0,
                          title: 'Est.',
                          color: Colors.teal.shade400,
                          radius: 70,
                          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: categoryTotals['design_grafico'] ?? 0.0,
                          title: 'Des.',
                          color: Colors.teal.shade600,
                          radius: 70,
                          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: categoryTotals['reprografia'] ?? 0.0,
                          title: 'Rep.',
                          color: Colors.teal.shade800,
                          radius: 70,
                          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ],
                      sectionsSpace: 1,
                      centerSpaceRadius: 35,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Serviços Registrados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                // TABELA COM SCROLL HORIZONTAL + BOTÕES
                Column(
                  children: [
                    // BOTÕES DE NAVEGAÇÃO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.teal, size: 28),
                          onPressed: () {
                            _servicesScrollController.animateTo(
                              _servicesScrollController.offset - 120,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          tooltip: 'Esquerda',
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, color: Colors.teal, size: 28),
                          onPressed: () {
                            _servicesScrollController.animateTo(
                              _servicesScrollController.offset + 120,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          tooltip: 'Direita',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // TABELA COM SCROLL HORIZONTAL
                    SizedBox(
                      height: isMobile ? 300 : 400,
                      child: SingleChildScrollView(
                        controller: _servicesScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: isMobile ? size.width * 1.8 : size.width * 1.2,
                          ),
                          child: DataTable(
                            border: TableBorder.all(color: Colors.grey.shade300, width: 0.7),
                            columnSpacing: isMobile ? 12 : 16,
                            dataRowHeight: isMobile ? 70 : 60,
                            headingRowHeight: isMobile ? 50 : 55,
                            headingTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            dataTextStyle: const TextStyle(fontSize: 13),
                            columns: const [
                              DataColumn(label: Text('Serviço')),
                              DataColumn(label: Text('Cat.')),
                              DataColumn(label: Text('Tipo')),
                              DataColumn(label: Text('C.Compra')),
                              DataColumn(label: Text('C.Mat.')),
                              DataColumn(label: Text('V.Venda')),
                              DataColumn(label: Text('Qtd.')),
                              DataColumn(label: Text('V.Total')),
                              DataColumn(label: Text('L.Total')),
                              DataColumn(label: Text('Data')),
                            ],
                            rows: filteredServices.map((service) {
                              final relatedOrders = filteredOrders.where((order) => order.serviceId == service.id).toList();
                              final totalProfit = relatedOrders.fold<double>(
                                0.0,
                                (sum, order) => sum + (order.totalPrice - (service.purchaseCost + service.materialCost) * order.quantity),
                              );
                              return DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: isMobile ? 100 : 130,
                                      child: Text(
                                        service.name,
                                        overflow: TextOverflow.visible,
                                        softWrap: true,
                                        maxLines: 3,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(service.category, style: const TextStyle(fontSize: 13))),
                                  DataCell(Text(service.type ?? 'N/A', style: const TextStyle(fontSize: 13))),
                                  DataCell(Text(service.purchaseCost.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
                                  DataCell(Text(service.materialCost.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
                                  DataCell(Text(service.saleValue.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
                                  DataCell(Text(service.dailyQuantitySold.toString(), style: const TextStyle(fontSize: 13))),
                                  DataCell(Text(service.totalValue.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
                                  DataCell(Text(totalProfit.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
                                  DataCell(Text(DateFormat('dd/MM').format(service.createdAt), style: const TextStyle(fontSize: 13))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Text(
                  'Lucro Total: ${totalProfit.toStringAsFixed(0)} MT',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ordens de Serviço',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                // TABELA DE ORDENS
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.teal, size: 28),
                          onPressed: () {
                            _ordersScrollController.animateTo(
                              _ordersScrollController.offset - 120,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          tooltip: 'Esquerda',
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, color: Colors.teal, size: 28),
                          onPressed: () {
                            _ordersScrollController.animateTo(
                              _ordersScrollController.offset + 120,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          tooltip: 'Direita',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    SizedBox(
                      height: isMobile ? 250 : 300,
                      child: SingleChildScrollView(
                        controller: _ordersScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: isMobile ? size.width * 1.6 : size.width * 1.1,
                          ),
                          child: DataTable(
                            border: TableBorder.all(color: Colors.grey.shade300, width: 0.7),
                            columnSpacing: 16,
                            dataRowHeight: 60,
                            headingTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            dataTextStyle: const TextStyle(fontSize: 13),
                            columns: const [
                              DataColumn(label: Text('Ordem ID')),
                              DataColumn(label: Text('Serviço')),
                              DataColumn(label: Text('Qtd.')),
                              DataColumn(label: Text('Total')),
                              DataColumn(label: Text('Data')),
                            ],
                            rows: filteredOrders.map((order) {
                              final service = filteredServices.firstWhere(
                                (s) => s.id == order.serviceId,
                                orElse: () => Service(
                                  id: '',
                                  name: 'Desconhecido',
                                  category: '',
                                  fixedPrice: 0.0,
                                  type: '',
                                  purchaseCost: 0.0,
                                  materialCost: 0.0,
                                  saleValue: 0.0,
                                  dailyQuantitySold: 0,
                                  totalValue: 0.0,
                                  createdAt: DateTime.now(),
                                  employeeId: '',
                                ),
                              );
                              return DataRow(cells: [
                                DataCell(Text(order.id, style: const TextStyle(fontSize: 13))),
                                DataCell(
                                  SizedBox(
                                    width: isMobile ? 100 : 130,
                                    child: Text(
                                      service.name,
                                      overflow: TextOverflow.visible,
                                      softWrap: true,
                                      maxLines: 2,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                                DataCell(Text(order.quantity.toString(), style: const TextStyle(fontSize: 13))),
                                DataCell(Text(order.totalPrice.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
                                DataCell(Text(DateFormat('dd/MM HH:mm').format(order.createdAt), style: const TextStyle(fontSize: 13))),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _servicesScrollController.dispose();
    _ordersScrollController.dispose();
    super.dispose();
  }
}