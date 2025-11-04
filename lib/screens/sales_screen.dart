import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/sales_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart' as custom_app_bar;
import '../models/product.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController();
  String? _editingId;

  // FILTRO POR DATAS
  DateTimeRange? _selectedRange;
  DateTime _start = DateTime.now().subtract(const Duration(days: 7));
  DateTime _end = DateTime.now();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SalesProvider>(context, listen: false);
    provider.fetchProducts();
    provider.fetchSales();
  }

  // === FILTRO DE DATAS ===
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _start, end: _end),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.teal.shade600,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
        _start = picked.start;
        _end = picked.end;
      });
    }
  }

  List<Sale> _filterSales(List<Sale> sales) {
    if (_selectedRange == null) return sales;
    return sales.where((sale) {
      return sale.createdAt.isAfter(_selectedRange!.start.subtract(const Duration(days: 1))) &&
             sale.createdAt.isBefore(_selectedRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  double _calculateTotalSales(List<Sale> sales) {
    return sales.fold(0.0, (sum, sale) => sum + sale.total);
  }

  // === PDF ===
  Future<void> _generateSalesReportPdf(List<Sale> filteredSales) async {
    final salesProv = Provider.of<SalesProvider>(context, listen: false);
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(locale: 'pt_MZ', symbol: 'MT');
    final totalSales = _calculateTotalSales(filteredSales);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Relatório de Vendas - NetLynx Print',
              style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Período: ${_selectedRange != null ? '${dateFormat.format(_start)} - ${dateFormat.format(_end)}' : 'Todas as datas'}',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Gerado em: ${dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Produto', 'Qtd.', 'Preço Unit.', 'Total', 'Data'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
            cellStyle: const pw.TextStyle(fontSize: 11),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.center,
            },
            data: filteredSales.map((sale) {
              final product = salesProv.products.firstWhere(
                (p) => p.id == sale.productId,
                orElse: () => Product(id: '', name: 'Desconhecido', price: 0, cost: 0, stock: 0, lowStockThreshold: 5, employeeId: ''),
              );
              return [
                product.name,
                sale.quantity.toString(),
                currencyFormat.format(product.price),
                currencyFormat.format(sale.total),
                dateFormat.format(sale.createdAt),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal700,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'TOTAL: ${currencyFormat.format(totalSales)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColors.white),
              ),
            ),
          ),
        ],
      ),
    );

    try {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'relatorio_vendas_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Relatório baixado com sucesso!'),
          backgroundColor: Colors.green.shade700,
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

  // === DIALOGS ===
  void _showProductDialog({Product? product}) {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    if (product != null) {
      _editingId = product.id;
      _nameCtrl.text = product.name;
      _priceCtrl.text = product.price.toString();
      _costCtrl.text = product.cost.toString();
      _stockCtrl.text = product.stock.toString();
      _thresholdCtrl.text = product.lowStockThreshold.toString();
    } else {
      _editingId = null;
      _nameCtrl.clear();
      _priceCtrl.clear();
      _costCtrl.clear();
      _stockCtrl.clear();
      _thresholdCtrl.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.teal.shade50,
        title: Text(
          product == null ? 'Adicionar Produto' : 'Editar Produto',
          style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(_nameCtrl, 'Nome', Icons.label),
                _field(_priceCtrl, 'Preço (MT)', Icons.attach_money, TextInputType.number),
                _field(_costCtrl, 'Custo (MT)', Icons.paid, TextInputType.number),
                _field(_stockCtrl, 'Estoque', Icons.inventory, TextInputType.number),
                _field(_thresholdCtrl, 'Limite Baixo Estoque', Icons.warning_amber, TextInputType.number),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final salesProv = Provider.of<SalesProvider>(context, listen: false);

                if (_editingId == null) {
                  final newProduct = Product(
                    id: const Uuid().v4(),
                    name: _nameCtrl.text,
                    price: double.parse(_priceCtrl.text),
                    cost: double.parse(_costCtrl.text),
                    stock: int.parse(_stockCtrl.text),
                    lowStockThreshold: int.tryParse(_thresholdCtrl.text) ?? 5,
                    employeeId: userId,
                  );
                  salesProv.addProduct(newProduct);
                } else {
                  final updatedProduct = Product(
                    id: _editingId!,
                    name: _nameCtrl.text,
                    price: double.parse(_priceCtrl.text),
                    cost: double.parse(_costCtrl.text),
                    stock: int.parse(_stockCtrl.text),
                    lowStockThreshold: int.tryParse(_thresholdCtrl.text) ?? 5,
                    employeeId: userId,
                  );
                  salesProv.editProduct(_editingId!, updatedProduct);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, [TextInputType? kb]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal.shade700),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: kb,
        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
      ),
    );
  }

  void _showSaleDialog(String prodId, String name, double price) {
    final qtyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.teal.shade50,
        title: Text('Vender $name', style: TextStyle(color: Colors.teal.shade800)),
        content: TextFormField(
          controller: qtyCtrl,
          decoration: InputDecoration(
            labelText: 'Quantidade',
            prefixIcon: Icon(Icons.add_shopping_cart, color: Colors.teal.shade700),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.number,
          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white),
            onPressed: () async {
              final q = int.tryParse(qtyCtrl.text);
              if (q != null && q > 0) {
                try {
                  await Provider.of<SalesProvider>(context, listen: false).registerSale(prodId, q);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Venda registrada!'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  void _showRestockDialog(String prodId, String name, int currentStock) {
    final qtyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.teal.shade50,
        title: Text('Repor Estoque: $name', style: TextStyle(color: Colors.teal.shade800)),
        content: TextFormField(
          controller: qtyCtrl,
          decoration: InputDecoration(
            labelText: 'Quantidade a Repor',
            prefixIcon: Icon(Icons.add_box, color: Colors.green.shade700),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.number,
          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
            onPressed: () async {
              final q = int.tryParse(qtyCtrl.text);
              if (q != null && q > 0) {
                await Provider.of<SalesProvider>(context, listen: false).restockProduct(prodId, q);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Estoque de $name reposto!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Repor'),
          ),
        ],
      ),
    );
  }

  String _highlightText(int qty, int max, int min) {
    if (qty == max && max > 0) return 'Mais Vendido';
    if (qty == min && min > 0) return 'Menos Vendido';
    return 'Médio';
  }

  Color _bgColor(int qty, int max, int min) {
    if (qty == max && max > 0) return Colors.green.shade100;
    if (qty == min && min > 0) return Colors.red.shade100;
    return Colors.amber.shade100;
  }

  @override
  Widget build(BuildContext context) {
    final salesProv = Provider.of<SalesProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final isAdmin = authProv.role == 'admin';

    // FILTRO DE VENDAS
    final filteredSales = _filterSales(salesProv.sales);
    final totalSales = _calculateTotalSales(filteredSales);

    final Map<String, int> salesMap = {};
    for (final s in filteredSales) {
      salesMap[s.productId] = (salesMap[s.productId] ?? 0) + s.quantity;
    }
    final max = salesMap.values.isEmpty ? 0 : salesMap.values.reduce((a, b) => a > b ? a : b);
    final min = salesMap.values.isEmpty ? 0 : salesMap.values.reduce((a, b) => a < b ? a : b);

    final currencyFormat = NumberFormat.currency(locale: 'pt_MZ', symbol: 'MT');

    return Scaffold(
      appBar: const custom_app_bar.CustomAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TÍTULO + FILTRO + PDF
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Gestão de Produtos e Vendas',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.teal.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  // BOTÃO FILTRO
                  ElevatedButton.icon(
                    icon: const Icon(Icons.date_range, size: 20),
                    label: Text(
                      _selectedRange == null
                          ? 'Todas as datas'
                          : '${DateFormat('dd/MM').format(_start)} - ${DateFormat('dd/MM').format(_end)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _selectDateRange,
                  ),
                  const SizedBox(width: 12),
                  // BOTÃO PDF
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf, size: 20),
                    label: const Text(
                      'BAIXAR PDF',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _generateSalesReportPdf(filteredSales),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // BOTÃO ADICIONAR PRODUTO
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text(
                      'ADICIONAR PRODUTO',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _showProductDialog(),
                  ),
                  const SizedBox(width: 20),
                  // TOTAL VISÍVEL
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade700,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Text(
                      'TOTAL: ${currencyFormat.format(totalSales)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // LISTA DE PRODUTOS
              Expanded(
                flex: 2,
                child: ListView.builder(
                  itemCount: salesProv.products.length,
                  itemBuilder: (ctx, i) {
                    final p = salesProv.products[i];
                    final qty = salesMap[p.id] ?? 0;
                    final bg = _bgColor(qty, max, min);
                    final highlight = _highlightText(qty, max, min);
                    final isLowStock = p.stock <= p.lowStockThreshold;

                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Tooltip(
                        message: highlight,
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: isLowStock ? Colors.red.shade100 : bg,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isLowStock ? Colors.red.shade700 : Colors.teal.shade700,
                              child: Text(p.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, color: isLowStock ? Colors.red.shade900 : null)),
                            subtitle: Text(
                              'Preço: ${p.price.toStringAsFixed(2)} MT | Estoque: ${p.stock}${isLowStock ? ' (Baixo)' : ''}',
                              style: TextStyle(color: isLowStock ? Colors.red.shade800 : null),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.shopping_cart, color: Colors.teal, size: 28),
                                  onPressed: () => _showSaleDialog(p.id, p.name, p.price),
                                  tooltip: 'Vender',
                                ),
                                if (isLowStock)
                                  IconButton(
                                    icon: const Icon(Icons.add_box, color: Colors.green, size: 28),
                                    tooltip: 'Repor Estoque',
                                    onPressed: () => _showRestockDialog(p.id, p.name, p.stock),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange, size: 28),
                                  onPressed: () => _showProductDialog(product: p),
                                  tooltip: 'Editar',
                                ),
                                if (isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          backgroundColor: Colors.red.shade50,
                                          title: Row(
                                            children: [
                                              Icon(Icons.warning, color: Colors.red.shade700),
                                              const SizedBox(width: 8),
                                              const Text('Confirmar Exclusão', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                          content: Text('Tem certeza que deseja remover o produto "${p.name}"?\n\nEsta ação não pode ser desfeita.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(_, false),
                                              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(_, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red.shade600,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Remover'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        try {
                                          await salesProv.removeProduct(p.id);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    const Icon(Icons.check_circle, color: Colors.white),
                                                    const SizedBox(width: 8),
                                                    Text('Produto "${p.name}" removido com sucesso!'),
                                                  ],
                                                ),
                                                backgroundColor: Colors.green.shade700,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    const Icon(Icons.error, color: Colors.white),
                                                    const SizedBox(width: 8),
                                                    Text('Erro ao remover: $e'),
                                                  ],
                                                ),
                                                backgroundColor: Colors.red.shade700,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // RELATÓRIO DE VENDAS
              Expanded(
                flex: 2,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Relatório de Vendas',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.picture_as_pdf, size: 20),
                                  label: const Text(
                                    'BAIXAR PDF',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => _generateSalesReportPdf(filteredSales),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total no Período: ${currencyFormat.format(totalSales)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: DataTable(
                                    headingRowHeight: 56,
                                    dataRowHeight: 56,
                                    columnSpacing: 24,
                                    border: TableBorder.all(color: Colors.teal.shade300, width: 1.5),
                                    headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                    dataTextStyle: const TextStyle(fontSize: 14, color: Colors.black87),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [Colors.teal.shade100, Colors.teal.shade50]),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    columns: const [
                                      DataColumn(label: Center(child: Text('Produto'))),
                                      DataColumn(label: Center(child: Text('Qtd.'))),
                                      DataColumn(label: Center(child: Text('Total (MT)'))),
                                      DataColumn(label: Center(child: Text('Data'))),
                                    ],
                                    rows: filteredSales.map((s) {
                                      final p = salesProv.products.firstWhere(
                                        (e) => e.id == s.productId,
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
                                      return DataRow(
                                        cells: [
                                          DataCell(Center(child: Text(p.name))),
                                          DataCell(Center(child: Text(s.quantity.toString()))),
                                          DataCell(Center(child: Text(s.total.toStringAsFixed(2)))),
                                          DataCell(Center(child: Text(DateFormat('dd/MM/yyyy').format(s.createdAt)))),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}