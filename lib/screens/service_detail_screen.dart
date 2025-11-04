import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/services_provider.dart';
import '../models/service.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String category;
  final String categoryName;
  final String image;
  final bool isAdmin;

  const ServiceDetailScreen({
    super.key,
    required this.category,
    required this.categoryName,
    required this.image,
    required this.isAdmin,
  });

  @override
  _ServiceDetailScreenState createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purchaseCostController = TextEditingController();
  final _materialCostController = TextEditingController();
  final _saleValueController = TextEditingController();
  final _quantityController = TextEditingController();
  String? _editingId;

  // CONTROLES DE SCROLL
  final ScrollController _servicesScrollController = ScrollController();
  final ScrollController _ordersScrollController = ScrollController();

  Future<void> _generateAndDownloadPdf(List<Service> services, List<ServiceOrder> orders) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('Relatório de Serviços - ${widget.categoryName}')),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              'Serviço',
              'Tipo',
              'Desc.',
              'C.Compra',
              widget.category == 'reprografia' ? 'C.Mat.' : 'C.Mat.',
              widget.category == 'reprografia' ? 'Venda' : 'V.Venda',
              widget.category == 'reprografia' ? 'Qtd.' : 'Qtd.',
              widget.category == 'reprografia' ? 'Total' : 'V.Total',
              'Data',
            ],
            data: services.map((service) {
              return [
                service.name,
                service.type ?? 'N/A',
                service.description ?? 'N/A',
                service.purchaseCost.toStringAsFixed(0),
                service.materialCost.toStringAsFixed(0),
                service.saleValue.toStringAsFixed(0),
                service.dailyQuantitySold.toString(),
                service.totalValue.toStringAsFixed(0),
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
                  category: widget.category,
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
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'relatorio_${widget.category}.pdf');
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

  void _showServiceDialog({Service? service}) {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    bool isNewService = service == null;
    _editingId = service?.id;
    _nameController.text = service?.name ?? '';
    _typeController.text = service?.type ?? '';
    _descriptionController.text = service?.description ?? '';
    _purchaseCostController.text = service?.purchaseCost.toString() ?? '';
    _materialCostController.text = service?.materialCost.toString() ?? '';
    _saleValueController.text = service?.saleValue.toString() ?? '';
    _quantityController.text = service?.dailyQuantitySold.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isNewService ? 'Adicionar Serviço' : 'Editar Serviço'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nome do Serviço'),
                        validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
                      ),
                      TextFormField(
                        controller: _typeController,
                        decoration: InputDecoration(
                          labelText: widget.category == 'estampagem'
                              ? 'Tipo de Estampagem'
                              : widget.category == 'design_grafico'
                                  ? 'Tipo de Design Gráfico'
                                  : 'Tipo de Serviço',
                        ),
                        validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Descrição (Opcional)'),
                      ),
                      TextFormField(
                        controller: _purchaseCostController,
                        decoration: const InputDecoration(labelText: 'Custo de Compra (MT)'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
                      ),
                      TextFormField(
                        controller: _materialCostController,
                        decoration: const InputDecoration(labelText: 'Custo de Material (MT)'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
                      ),
                      TextFormField(
                        controller: _saleValueController,
                        decoration: const InputDecoration(labelText: 'Valor de Venda (MT)'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
                      ),
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(labelText: 'Quantidade Vendida Diária'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final saleValue = double.tryParse(_saleValueController.text) ?? 0.0;
                      final quantity = int.tryParse(_quantityController.text) ?? 0;
                      final totalValue = saleValue * quantity;
                      final serviceData = Service(
                        id: _editingId ?? const Uuid().v4(),
                        name: _nameController.text,
                        category: widget.category,
                        fixedPrice: saleValue,
                        type: _typeController.text,
                        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
                        purchaseCost: double.tryParse(_purchaseCostController.text) ?? 0.0,
                        materialCost: double.tryParse(_materialCostController.text) ?? 0.0,
                        saleValue: saleValue,
                        dailyQuantitySold: quantity,
                        totalValue: totalValue,
                        createdAt: DateTime.now(),
                        employeeId: userId,
                      );
                      final servicesProvider = Provider.of<ServicesProvider>(context, listen: false);
                      try {
                        if (isNewService) {
                          await servicesProvider.addService(serviceData);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Serviço adicionado com sucesso'),
                              backgroundColor: Colors.teal.shade700,
                            ),
                          );
                        } else {
                          await servicesProvider.editService(_editingId!, serviceData);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Serviço editado com sucesso'),
                              backgroundColor: Colors.teal.shade700,
                            ),
                          );
                        }
                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao salvar serviço: $e'),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showOrderDialog(String serviceId, String serviceName, double saleValue) {
    final _orderFormKey = GlobalKey<FormState>();
    final _quantityController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Registrar Ordem de $serviceName'),
        content: Form(
          key: _orderFormKey,
          child: TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(labelText: 'Quantidade'),
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_orderFormKey.currentState!.validate()) {
                final quantity = int.tryParse(_quantityController.text);
                if (quantity != null && quantity > 0) {
                  final servicesProvider = Provider.of<ServicesProvider>(context, listen: false);
                  try {
                    await servicesProvider.registerServiceOrder(serviceId, quantity);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ordem registrada: $quantity x $serviceName'),
                        backgroundColor: Colors.teal.shade700,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao registrar ordem: $e'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicesProvider = Provider.of<ServicesProvider>(context);
    final services = servicesProvider.services.where((service) => service.category == widget.category).toList();
    final today = DateTime.now();
    final orders = servicesProvider.serviceOrders.where((order) {
      return order.createdAt.year == today.year &&
          order.createdAt.month == today.month &&
          order.createdAt.day == today.day &&
          services.any((service) => service.id == order.serviceId);
    }).toList();
    final totalDailyValue = orders.fold<double>(0.0, (sum, order) => sum + order.totalPrice);

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal.shade600,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white, size: 36),
            tooltip: 'Baixar Relatório em PDF',
            onPressed: () => _generateAndDownloadPdf(services, orders),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 36),
            tooltip: 'Adicionar Serviço',
            onPressed: () => _showServiceDialog(),
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
                Image.asset(
                  widget.image,
                  height: 50,
                  width: 50,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Serviços de ${widget.categoryName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                // TABELA DE SERVIÇOS COM SCROLL + BOTÕES
                services.isEmpty
                    ? const Center(child: Text('Nenhum serviço nesta categoria.', style: TextStyle(fontSize: 15)))
                    : Column(
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
                                  columns: [
                                    const DataColumn(label: Text('Serviço')),
                                    const DataColumn(label: Text('Tipo')),
                                    const DataColumn(label: Text('Desc.')),
                                    const DataColumn(label: Text('C.Compra')),
                                    DataColumn(label: Text(widget.category == 'reprografia' ? 'C.Mat.' : 'C.Mat.')),
                                    DataColumn(label: Text(widget.category == 'reprografia' ? 'Venda' : 'V.Venda')),
                                    DataColumn(label: Text(widget.category == 'reprografia' ? 'Qtd.' : 'Qtd.')),
                                    DataColumn(label: Text(widget.category == 'reprografia' ? 'Total' : 'V.Total')),
                                    const DataColumn(label: Text('Data')),
                                    const DataColumn(label: Text('Ações')),
                                  ],
                                  rows: services.map((service) {
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
                                        DataCell(Text(service.type ?? 'N/A', style: const TextStyle(fontSize: 13))),
                                        DataCell(
                                          SizedBox(
                                            width: isMobile ? 100 : 130,
                                            child: Text(
                                              service.description ?? 'N/A',
                                              overflow: TextOverflow.visible,
                                              softWrap: true,
                                              maxLines: 3,
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(service.purchaseCost.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
                                        DataCell(Text(service.materialCost.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
                                        DataCell(Text(service.saleValue.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
                                        DataCell(Text(service.dailyQuantitySold.toString(), style: const TextStyle(fontSize: 13))),
                                        DataCell(Text(service.totalValue.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
                                        DataCell(Text(DateFormat('dd/MM').format(service.createdAt), style: const TextStyle(fontSize: 13))),
                                        // AÇÕES COM ESPAÇO
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // ADICIONAR ORDEM
                                              Container(
                                                margin: const EdgeInsets.only(right: 12),
                                                child: IconButton(
                                                  icon: const Icon(Icons.add_circle, color: Colors.teal, size: 24),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () => _showOrderDialog(service.id, service.name, service.saleValue),
                                                  tooltip: 'Adicionar Ordem',
                                                ),
                                              ),
                                              // EDITAR
                                              Container(
                                                margin: const EdgeInsets.only(right: 12),
                                                child: IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.orange, size: 24),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () => _showServiceDialog(service: service),
                                                  tooltip: 'Editar Serviço',
                                                ),
                                              ),
                                              // EXCLUIR (APENAS ADMIN)
                                              if (widget.isAdmin)
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () => servicesProvider.removeService(service.id),
                                                  tooltip: 'Excluir Serviço',
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                const SizedBox(height: 12),
                Text(
                  'Relatório Diário de ${widget.categoryName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                // TABELA DE ORDENS COM SCROLL + BOTÕES
                orders.isEmpty
                    ? const Center(child: Text('Nenhuma ordem registrada hoje.', style: TextStyle(fontSize: 15)))
                    : Column(
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
                                    DataColumn(label: Text('Serviço')),
                                    DataColumn(label: Text('Qtd.')),
                                    DataColumn(label: Text('Total')),
                                    DataColumn(label: Text('Data')),
                                  ],
                                  rows: orders.map((order) {
                                    final service = services.firstWhere(
                                      (s) => s.id == order.serviceId,
                                      orElse: () => Service(
                                        id: '',
                                        name: 'Desconhecido',
                                        category: widget.category,
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

                const SizedBox(height: 8),
                Text(
                  'Valor Total Diário: ${totalDailyValue.toStringAsFixed(0)} MT',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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