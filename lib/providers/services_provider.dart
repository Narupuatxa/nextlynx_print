// services_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw; // Apenas widgets
import 'package:universal_html/html.dart' as html;
import '../models/service.dart';

class ServiceOrder {
  final String id;
  final String serviceId;
  final int quantity;
  final double totalPrice;
  final DateTime createdAt;
  final String employeeId;

  ServiceOrder({
    required this.id,
    required this.serviceId,
    required this.quantity,
    required this.totalPrice,
    required this.createdAt,
    required this.employeeId,
  });

  factory ServiceOrder.fromMap(Map<String, dynamic> map) {
    return ServiceOrder(
      id: map['id'] ?? '',
      serviceId: map['service_id'] ?? '',
      quantity: map['quantity'] ?? 0,
      totalPrice: (map['total_price'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      employeeId: map['employee_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_id': serviceId,
      'quantity': quantity,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      'employee_id': employeeId,
    };
  }
}

class ServicesProvider with ChangeNotifier {
  List<Service> _services = [];
  List<ServiceOrder> _serviceOrders = [];
  String? _currentUserRole;

  List<Service> get services => _services;
  List<ServiceOrder> get serviceOrders => _serviceOrders;

  Future<void> init() async {
    await fetchServices();
    await fetchServiceOrders();
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

  Future<void> fetchServices() async {
    try {
      final response = await Supabase.instance.client.from('services').select();
      _services = (response as List).map((e) => Service.fromMap(e)).toList();
      debugPrint('ServicesProvider: ${_services.length} serviços carregados');
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar serviços: $e');
      rethrow;
    }
  }

  Future<void> fetchServiceOrders() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      var query = Supabase.instance.client.from('service_orders').select();

      if (userId != null && _currentUserRole != 'admin') {
        query = query.eq('employee_id', userId);
      }

      final response = await query;
      _serviceOrders = (response as List).map((e) => ServiceOrder.fromMap(e)).toList();
      debugPrint('ServicesProvider: ${_serviceOrders.length} ordens carregadas');
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar ordens: $e');
      rethrow;
    }
  }

  Future<void> addService(Service service) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final newId = const Uuid().v4();
      final now = DateTime.now();

      final newService = Service(
        id: newId,
        name: service.name,
        category: service.category,
        fixedPrice: service.fixedPrice,
        type: service.type,
        description: service.description,
        purchaseCost: service.purchaseCost,
        materialCost: service.materialCost,
        saleValue: service.saleValue,
        dailyQuantitySold: 0,
        totalValue: 0.0,
        createdAt: now,
        employeeId: userId,
      );

      await Supabase.instance.client.from('services').insert(newService.toMap());

      await fetchServices();
    } catch (e) {
      debugPrint('Erro ao adicionar serviço: $e');
      rethrow;
    }
  }

  Future<void> editService(String id, Service service) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final updatedService = service.copyWith(id: id, employeeId: userId);
      await Supabase.instance.client
          .from('services')
          .update(updatedService.toMap())
          .eq('id', id);
      await fetchServices();
    } catch (e) {
      debugPrint('Erro ao editar serviço: $e');
      rethrow;
    }
  }

  Future<void> removeService(String id) async {
    try {
      if (_currentUserRole != 'admin') throw Exception('Apenas admin pode remover serviços');
      await Supabase.instance.client.from('services').delete().eq('id', id);
      await fetchServices();
    } catch (e) {
      debugPrint('Erro ao remover serviço: $e');
      rethrow;
    }
  }

  Future<void> registerServiceOrder(String serviceId, int quantity) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final service = _services.firstWhere((s) => s.id == serviceId);
      final totalPrice = quantity * service.saleValue;

      final orderId = const Uuid().v4();

      await Supabase.instance.client.from('service_orders').insert({
        'id': orderId,
        'service_id': serviceId,
        'quantity': quantity,
        'total_price': totalPrice,
        'employee_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      final newDailyQty = service.dailyQuantitySold + quantity;
      final newTotalValue = service.totalValue + totalPrice;

      await Supabase.instance.client.from('services').update({
        'daily_quantity_sold': newDailyQty,
        'total_value': newTotalValue,
      }).eq('id', serviceId);

      await fetchServiceOrders();
      await fetchServices();
    } catch (e) {
      debugPrint('Erro ao registrar ordem: $e');
      rethrow;
    }
  }

  double getDailyTotal(DateTime day) {
    return _serviceOrders
        .where((order) =>
            order.createdAt.year == day.year &&
            order.createdAt.month == day.month &&
            order.createdAt.day == day.day)
        .fold(0.0, (sum, order) => sum + order.totalPrice);
  }

  Map<DateTime, double> getDailyServicesMap() {
    final map = <DateTime, double>{};
    for (final order in _serviceOrders) {
      final day = DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day);
      map[day] = (map[day] ?? 0.0) + order.totalPrice;
    }
    return map;
  }

  Future<void> exportDailyReportPdf(DateTime day) async {
    final pdf = pw.Document();
    final total = getDailyTotal(day);
    final orders = _serviceOrders.where((o) => o.createdAt.day == day.day).toList();
    final fmt = NumberFormat.currency(locale: 'pt_MZ', symbol: 'MT');

    // CORRIGIDO: REMOVIDO `const` → DateFormat não é constante
    final title = pw.Text(
      'Relatório Diário de Serviços - ${DateFormat('dd/MM/yyyy').format(day)}',
      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
    );

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            title,
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Serviço', 'Qtd', 'Valor Unitário', 'Total', 'Hora'],
              data: orders.map((order) {
                final service = _services.firstWhere(
                  (s) => s.id == order.serviceId,
                  orElse: () => Service(
                    id: '',
                    name: 'Desconhecido',
                    category: '',
                    fixedPrice: 0,
                    type: '',
                    purchaseCost: 0,
                    materialCost: 0,
                    saleValue: 0,
                    dailyQuantitySold: 0,
                    totalValue: 0,
                    createdAt: DateTime.now(),
                    employeeId: '',
                  ),
                );
                return [
                  service.name,
                  order.quantity.toString(),
                  fmt.format(service.saleValue),
                  fmt.format(order.totalPrice),
                  DateFormat('HH:mm').format(order.createdAt),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            // CORRIGIDO: REMOVIDO `const`
            pw.Text(
              'Total do Dia: ${fmt.format(total)}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'relatorio_servicos_${DateFormat('yyyyMMdd').format(day)}.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}