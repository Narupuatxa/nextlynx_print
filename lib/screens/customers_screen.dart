import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/customers_provider.dart';
import '../providers/auth_provider.dart';
import '../models/loyal_customer.dart';
import '../models/debt_customer.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _loyalFormKey = GlobalKey<FormState>();
  final _loyalNameController = TextEditingController();
  final _loyalPhoneController = TextEditingController();
  final _loyalCopiesController = TextEditingController();
  final _loyalPaidController = TextEditingController();
  final _loyalTotalController = TextEditingController();
  String? _editingLoyalId;

  final _debtFormKey = GlobalKey<FormState>();
  final _debtNameController = TextEditingController();
  final _debtProfessionController = TextEditingController();
  final _debtPhoneController = TextEditingController();
  final _debtCopiesController = TextEditingController();
  final _debtAmountController = TextEditingController();
  DateTime? _debtDate;
  DateTime? _paymentDate;
  String? _editingDebtId;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<CustomersProvider>(context, listen: false);
    provider.init().then((_) {
      _checkUpcomingPayments(provider.debtCustomers);
    });
  }

  void _checkUpcomingPayments(List<DebtCustomer> debts) {
    final now = DateTime.now();
    final upcoming = debts.where((c) {
      if (c.paymentDate == null) return false;
      final diff = c.paymentDate!.difference(now).inDays;
      return diff >= 0 && diff <= 3;
    }).toList();

    if (upcoming.isNotEmpty && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Pagamentos Próximos'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: upcoming.length,
                itemBuilder: (context, i) {
                  final c = upcoming[i];
                  final days = c.paymentDate!.difference(now).inDays;
                  return ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Pagamento em $days dia(s)'),
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      });
    }
  }

  void _showLoyalDialog({LoyalCustomer? customer}) {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    if (customer != null) {
      _editingLoyalId = customer.id;
      _loyalNameController.text = customer.name;
      _loyalPhoneController.text = customer.phone;
      _loyalCopiesController.text = customer.copiesQty.toString();
      _loyalPaidController.text = customer.paidValue.toStringAsFixed(2);
      _loyalTotalController.text = customer.totalValue.toStringAsFixed(2);
    } else {
      _editingLoyalId = null;
      _clearLoyalControllers();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(customer == null ? 'Adicionar Cliente Fiel' : 'Editar Cliente Fiel'),
        content: Form(
          key: _loyalFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_loyalNameController, 'Nome', Icons.person),
                _buildTextField(_loyalPhoneController, 'Telefone', Icons.phone, TextInputType.phone),
                _buildTextField(_loyalCopiesController, 'Cópias', Icons.copy, TextInputType.number),
                _buildTextField(_loyalPaidController, 'Valor Pago', Icons.paid, TextInputType.number),
                _buildTextField(_loyalTotalController, 'Valor Total', Icons.attach_money, TextInputType.number),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent),
            onPressed: () {
              if (_loyalFormKey.currentState!.validate()) {
                final provider = Provider.of<CustomersProvider>(context, listen: false);
                final copies = int.parse(_loyalCopiesController.text);
                final paid = double.parse(_loyalPaidController.text);
                final total = double.parse(_loyalTotalController.text);

                if (_editingLoyalId == null) {
                  provider.addLoyalCustomer(LoyalCustomer(
                    id: const Uuid().v4(),
                    name: _loyalNameController.text.trim(),
                    phone: _loyalPhoneController.text.trim(),
                    copiesQty: copies,
                    paidValue: paid,
                    totalValue: total,
                    date: DateTime.now(),
                    employeeId: userId,
                  ));
                } else {
                  provider.editLoyalCustomer(_editingLoyalId!, LoyalCustomer(
                    id: _editingLoyalId!,
                    name: _loyalNameController.text.trim(),
                    phone: _loyalPhoneController.text.trim(),
                    copiesQty: copies,
                    paidValue: paid,
                    totalValue: total,
                    date: DateTime.now(),
                    employeeId: userId,
                  ));
                }
                _clearLoyalControllers();
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showDebtDialog({DebtCustomer? customer}) {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    if (customer != null) {
      _editingDebtId = customer.id;
      _debtNameController.text = customer.name;
      _debtProfessionController.text = customer.profession ?? '';
      _debtPhoneController.text = customer.phone;
      _debtCopiesController.text = customer.copiesQty.toString();
      _debtAmountController.text = customer.amount.toStringAsFixed(2);
      _debtDate = customer.debtDate;
      _paymentDate = customer.paymentDate;
    } else {
      _editingDebtId = null;
      _clearDebtControllers();
      _debtDate = null;
      _paymentDate = null;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(customer == null ? 'Adicionar Cliente com Dívida' : 'Editar Cliente com Dívida'),
        content: Form(
          key: _debtFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_debtNameController, 'Nome', Icons.person),
                _buildTextField(_debtProfessionController, 'Profissão', Icons.work),
                _buildTextField(_debtPhoneController, 'Telefone', Icons.phone, TextInputType.phone),
                _buildTextField(_debtCopiesController, 'Cópias', Icons.copy, TextInputType.number),
                _buildTextField(_debtAmountController, 'Valor a Pagar', Icons.attach_money, TextInputType.number),
                _buildDateButton('Data da Dívida', _debtDate, (d) => setState(() => _debtDate = d)),
                _buildDateButton('Data de Pagamento', _paymentDate, (d) => setState(() => _paymentDate = d)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              if (_debtFormKey.currentState!.validate() && _debtDate != null) {
                final provider = Provider.of<CustomersProvider>(context, listen: false);
                final copies = int.parse(_debtCopiesController.text);
                final amount = double.parse(_debtAmountController.text);

                if (_editingDebtId == null) {
                  provider.addDebtCustomer(DebtCustomer(
                    id: const Uuid().v4(),
                    name: _debtNameController.text.trim(),
                    profession: _debtProfessionController.text.isEmpty ? null : _debtProfessionController.text.trim(),
                    phone: _debtPhoneController.text.trim(),
                    copiesQty: copies,
                    amount: amount,
                    debtDate: _debtDate!,
                    paymentDate: _paymentDate,
                    employeeId: userId,
                  ));
                } else {
                  provider.editDebtCustomer(_editingDebtId!, DebtCustomer(
                    id: _editingDebtId!,
                    name: _debtNameController.text.trim(),
                    profession: _debtProfessionController.text.isEmpty ? null : _debtProfessionController.text.trim(),
                    phone: _debtPhoneController.text.trim(),
                    copiesQty: copies,
                    amount: amount,
                    debtDate: _debtDate!,
                    paymentDate: _paymentDate,
                    employeeId: userId,
                  ));
                }
                _clearDebtControllers();
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, [TextInputType? type]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        keyboardType: type,
        validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, Function(DateTime) onSelect) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) onSelect(picked);
        },
        icon: const Icon(Icons.calendar_today, color: Colors.white),
        label: Text(
          date == null ? label : DateFormat('dd/MM/yyyy').format(date),
          style: const TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade600,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _clearLoyalControllers() {
    _loyalNameController.clear();
    _loyalPhoneController.clear();
    _loyalCopiesController.clear();
    _loyalPaidController.clear();
    _loyalTotalController.clear();
  }

  void _clearDebtControllers() {
    _debtNameController.clear();
    _debtProfessionController.clear();
    _debtPhoneController.clear();
    _debtCopiesController.clear();
    _debtAmountController.clear();
  }

  Color _getPaymentColor(DateTime? paymentDate) {
    if (paymentDate == null) return Colors.grey;
    final days = paymentDate.difference(DateTime.now()).inDays;
    if (days < 0) return Colors.red;
    if (days <= 3) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final customersProvider = Provider.of<CustomersProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.role == 'admin';

    // RESPONSIVIDADE: AJUSTA PADDING E FONTE
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth < 600 ? 12.0 : 16.0;
    final titleFontSize = screenWidth < 600 ? 20.0 : 24.0;
    final sectionFontSize = screenWidth < 600 ? 16.0 : 18.0;

    return Scaffold(
      appBar: const CustomAppBar(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add_loyal',
            onPressed: () => _showLoyalDialog(),
            backgroundColor: Colors.teal,
            child: const Icon(Icons.person_add),
            tooltip: 'Cliente Fiel',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_debt',
            onPressed: () => _showDebtDialog(),
            backgroundColor: Colors.orange,
            child: const Icon(Icons.warning),
            tooltip: 'Cliente com Dívida',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestão de Clientes',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.teal.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Clientes Fiéis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.teal.shade700,
                    fontSize: sectionFontSize,
                  ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: customersProvider.loyalCustomers.isEmpty
                  ? const Center(child: Text('Nenhum cliente fiel.'))
                  : ListView.builder(
                      itemCount: customersProvider.loyalCustomers.length,
                      itemBuilder: (context, index) {
                        final c = customersProvider.loyalCustomers[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(
                                c.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'Tel: ${c.phone} | Cópias: ${c.copiesQty} | Pago: ${c.paidValue.toStringAsFixed(2)} MT',
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showLoyalDialog(customer: c),
                                  tooltip: 'Editar',
                                ),
                                if (isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => customersProvider.removeLoyalCustomer(c.id),
                                    tooltip: 'Excluir',
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              'Clientes com Dívidas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.orange.shade700,
                    fontSize: sectionFontSize,
                  ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: customersProvider.debtCustomers.isEmpty
                  ? const Center(child: Text('Nenhum cliente com dívida.'))
                  : ListView.builder(
                      itemCount: customersProvider.debtCustomers.length,
                      itemBuilder: (context, index) {
                        final c = customersProvider.debtCustomers[index];
                        final color = _getPaymentColor(c.paymentDate);

                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: color.withOpacity(0.15),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color,
                              child: Icon(
                                c.paymentDate == null ? Icons.schedule : Icons.warning,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tel: ${c.phone} | Cópias: ${c.copiesQty}', style: const TextStyle(fontSize: 12)),
                                Text('Valor: ${c.amount.toStringAsFixed(2)} MT', style: const TextStyle(fontSize: 12)),
                                Text('Dívida: ${DateFormat('dd/MM/yyyy').format(c.debtDate)}', style: const TextStyle(fontSize: 12)),
                                // PAGAMENTO VISÍVEL COM FUNDO BRANCO
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.payment, size: 16, color: color),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Pagamento: ${c.paymentDate != null ? DateFormat('dd/MM/yyyy').format(c.paymentDate!) : 'Pendente'}',
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showDebtDialog(customer: c),
                                  tooltip: 'Editar',
                                ),
                                if (isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => customersProvider.removeDebtCustomer(c.id),
                                    tooltip: 'Excluir',
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}