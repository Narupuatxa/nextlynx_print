// lib/providers/customers_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart'; // ADICIONADO
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;
import '../models/loyal_customer.dart';
import '../models/debt_customer.dart';

class CustomersProvider extends ChangeNotifier {
  List<LoyalCustomer> _loyalCustomers = [];
  List<DebtCustomer> _debtCustomers = [];
  String? _currentUserRole;

  List<LoyalCustomer> get loyalCustomers => _loyalCustomers;
  List<DebtCustomer> get debtCustomers => _debtCustomers;

  Future<void> init() async {
    await fetchLoyalCustomers();
    await fetchDebtCustomers();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final roleResponse = await Supabase.instance.client
          .from('roles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();
      _currentUserRole = roleResponse?['role'] ?? 'employee';
    }
    notifyListeners();
  }

  Future<void> fetchLoyalCustomers() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    var query = Supabase.instance.client.from('loyal_customers').select();

    if (userId != null && _currentUserRole != 'admin') {
      query = query.eq('employee_id', userId);
    }

    final response = await query;
    _loyalCustomers = (response as List).map((map) => LoyalCustomer.fromMap(map)).toList();
    notifyListeners();
  }

  Future<void> fetchDebtCustomers() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    var query = Supabase.instance.client.from('debt_customers').select();

    if (userId != null && _currentUserRole != 'admin') {
      query = query.eq('employee_id', userId);
    }

    final response = await query;
    _debtCustomers = (response as List).map((map) => DebtCustomer.fromMap(map)).toList();
    notifyListeners();
  }

  Future<void> addLoyalCustomer(LoyalCustomer customer) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final newCustomer = customer.copyWith(employeeId: userId);
    await Supabase.instance.client.from('loyal_customers').insert(newCustomer.toMap());
    await fetchLoyalCustomers();
    await _logAction('add_loyal_customer', {'name': customer.name});
  }

  Future<void> addDebtCustomer(DebtCustomer customer) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final newCustomer = customer.copyWith(employeeId: userId);
    await Supabase.instance.client.from('debt_customers').insert(newCustomer.toMap());
    await fetchDebtCustomers();
    await _logAction('add_debt_customer', {'name': customer.name});
  }

  Future<void> editLoyalCustomer(String id, LoyalCustomer updated) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final newCustomer = updated.copyWith(id: id, employeeId: userId);
    await Supabase.instance.client
        .from('loyal_customers')
        .update(newCustomer.toMap())
        .eq('id', id);
    await fetchLoyalCustomers();
    await _logAction('edit_loyal_customer', {'id': id});
  }

  Future<void> editDebtCustomer(String id, DebtCustomer updated) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final newCustomer = updated.copyWith(id: id, employeeId: userId);
    await Supabase.instance.client
        .from('debt_customers')
        .update(newCustomer.toMap())
        .eq('id', id);
    await fetchDebtCustomers();
    await _logAction('edit_debt_customer', {'id': id});
  }

  Future<void> removeLoyalCustomer(String id) async {
    await Supabase.instance.client.from('loyal_customers').delete().eq('id', id);
    await fetchLoyalCustomers();
    await _logAction('remove_loyal_customer', {'id': id});
  }

  Future<void> removeDebtCustomer(String id) async {
    await Supabase.instance.client.from('debt_customers').delete().eq('id', id);
    await fetchDebtCustomers();
    await _logAction('remove_debt_customer', {'id': id});
  }

  Future<void> _logAction(String action, Map<String, dynamic> details) async {
    await Supabase.instance.client.from('audit_logs').insert({
      'action': action,
      'user_id': Supabase.instance.client.auth.currentUser!.id,
      'details': details,
    });
  }

  Future<void> exportCustomersReportPdf() async {
    final pdf = pw.Document();
    final fmt = NumberFormat.currency(locale: 'pt_MZ', symbol: 'MT');
    final today = DateTime.now();

    final dailyDebt = _debtCustomers
        .where((c) => c.debtDate.year == today.year && c.debtDate.month == today.month && c.debtDate.day == today.day)
        .fold(0.0, (sum, c) => sum + c.amount);

    final totalDebt = _debtCustomers.fold(0.0, (sum, c) => sum + c.amount);

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Relatório de Clientes - NetLynx Print', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('Data: ${DateFormat('dd/MM/yyyy HH:mm').format(today)}'),
            pw.SizedBox(height: 20),
            pw.Text('DÍVIDA TOTAL: ${fmt.format(totalDebt)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
            pw.Text('DÍVIDA DO DIA: ${fmt.format(dailyDebt)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700)),
            pw.SizedBox(height: 20),
            pw.Text('Clientes com Dívida', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Table.fromTextArray(
              headers: ['Nome', 'Telefone', 'Cópias', 'Valor', 'Dívida', 'Pagamento'],
              data: _debtCustomers.map((c) => [
                c.name,
                c.phone,
                c.copiesQty.toString(),
                fmt.format(c.amount),
                DateFormat('dd/MM/yyyy').format(c.debtDate),
                c.paymentDate != null ? DateFormat('dd/MM/yyyy').format(c.paymentDate!) : 'Pendente',
              ]).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Clientes Fiéis', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Table.fromTextArray(
              headers: ['Nome', 'Telefone', 'Cópias', 'Pago', 'Total'],
              data: _loyalCustomers.map((c) => [
                c.name,
                c.phone,
                c.copiesQty.toString(),
                fmt.format(c.paidValue),
                fmt.format(c.totalValue),
              ]).toList(),
            ),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'relatorio_clientes_${DateFormat('yyyyMMdd').format(today)}.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}