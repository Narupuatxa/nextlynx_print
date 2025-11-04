import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';

class Sale {
  final String id;
  final String productId;
  final int quantity;
  final double total;
  final DateTime createdAt;
  final String employeeId;

  Sale({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.total,
    required this.createdAt,
    required this.employeeId,
  });

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] ?? '',
      productId: map['product_id'] ?? '',
      quantity: map['quantity'] ?? 0,
      total: (map['total'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      employeeId: map['employee_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
      'total': total,
      'date': createdAt.toIso8601String(),
      'employee_id': employeeId,
    };
  }
}

class SalesProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Sale> _sales = [];
  double _totalProfit = 0.0;
  String? _currentUserRole;

  List<Product> get products => _products;
  List<Sale> get sales => _sales;

  // Lucro SÓ para admin
  double get totalProfit => _currentUserRole == 'admin' ? _totalProfit : 0.0;

  Future<void> initSummary() async {
    try {
      final exists = await Supabase.instance.client
          .from('sales_summary')
          .select()
          .eq('id', 'global')
          .maybeSingle();

      if (exists == null) {
        await Supabase.instance.client.from('sales_summary').insert({
          'id': 'global',
          'total_profit': 0.0,
          'updated_at': DateTime.now().toIso8601String(),
        });
        _totalProfit = 0.0;
      } else {
        _totalProfit = (exists['total_profit'] ?? 0.0).toDouble();
      }

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
    } catch (e) {
      debugPrint('Erro ao inicializar sales_summary: $e');
    }
  }

  // TODOS VEEM TODOS OS PRODUTOS
  Future<void> fetchProducts() async {
    try {
      final response = await Supabase.instance.client.from('products').select();
      _products = (response as List).map((e) => Product.fromMap(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar produtos: $e');
      rethrow;
    }
  }

  // TODOS VEEM TODAS AS VENDAS
  Future<void> fetchSales() async {
    try {
      final response = await Supabase.instance.client.from('sales').select();
      _sales = (response as List).map((e) => Sale.fromMap(e)).toList();

      if (_currentUserRole == 'admin') {
        await _recalculateTotalProfit();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar vendas: $e');
      rethrow;
    }
  }

  Future<void> _recalculateTotalProfit() async {
    try {
      double total = 0.0;
      for (final sale in _sales) {
        final product = _products.firstWhere(
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
        total += profitPerUnit * sale.quantity;
      }

      _totalProfit = total;
      await Supabase.instance.client
          .from('sales_summary')
          .update({'total_profit': total, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', 'global');
    } catch (e) {
      debugPrint('Erro ao recalcular lucro total: $e');
    }
  }

  // === FUNCIONÁRIO PODE CADASTRAR PRODUTO ===
  Future<void> addProduct(Product product) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final newProduct = product.copyWith(employeeId: userId);
      await Supabase.instance.client.from('products').insert(newProduct.toMap());
      await fetchProducts();
    } catch (e) {
      debugPrint('Erro ao adicionar produto: $e');
      rethrow;
    }
  }

  // === FUNCIONÁRIO PODE EDITAR PRODUTO (só o que criou) ===
  Future<void> editProduct(String id, Product product) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final newProduct = product.copyWith(id: id, employeeId: userId);
      await Supabase.instance.client.from('products').update(newProduct.toMap()).eq('id', id);
      await fetchProducts();
      await fetchSales();
    } catch (e) {
      debugPrint('Erro ao editar produto: $e');
      rethrow;
    }
  }

  // === APENAS ADMIN PODE DELETAR PRODUTO ===
  Future<void> removeProduct(String id) async {
    try {
      final isAdmin = _currentUserRole == 'admin';
      if (!isAdmin) throw Exception('Apenas admin pode deletar produtos');

      await Supabase.instance.client.from('sales').delete().eq('product_id', id);
      await Supabase.instance.client.from('products').delete().eq('id', id);
      await fetchProducts();
      await fetchSales();
    } catch (e) {
      debugPrint('Erro ao remover produto: $e');
      rethrow;
    }
  }

  // === REPOR ESTOQUE ===
  Future<void> restockProduct(String productId, int quantity) async {
    try {
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final updatedStock = _products[index].stock + quantity;
        await Supabase.instance.client
            .from('products')
            .update({'stock': updatedStock}).eq('id', productId);
        await fetchProducts();
      }
    } catch (e) {
      debugPrint('Erro ao repor estoque: $e');
      rethrow;
    }
  }

  // === REGISTRAR VENDA ===
  Future<void> registerSale(String productId, int quantity) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final product = _products.firstWhere((p) => p.id == productId);
      final total = quantity * product.price;
      final newStock = product.stock - quantity;

      if (newStock < 0) throw Exception('Estoque insuficiente');

      await Supabase.instance.client
          .from('products')
          .update({'stock': newStock}).eq('id', productId);

      final saleId = const Uuid().v4();
      await Supabase.instance.client.from('sales').insert({
        'id': saleId,
        'product_id': productId,
        'quantity': quantity,
        'total': total,
        'employee_id': userId,
        'date': DateTime.now().toIso8601String(),
      });

      await fetchProducts();
      await fetchSales();
    } catch (e) {
      debugPrint('Erro ao registrar venda: $e');
      rethrow;
    }
  }

  // === RELATÓRIO DIÁRIO (para employee) ===
  double getDailyTotal(DateTime day) {
    return _sales
        .where((s) =>
            s.createdAt.year == day.year &&
            s.createdAt.month == day.month &&
            s.createdAt.day == day.day)
        .fold(0.0, (sum, s) => sum + s.total);
  }

  // === GRÁFICO DE VENDAS POR DIA ===
  Map<DateTime, double> getDailySalesMap() {
    final map = <DateTime, double>{};
    for (final sale in _sales) {
      final day = DateTime(sale.createdAt.year, sale.createdAt.month, sale.createdAt.day);
      map[day] = (map[day] ?? 0.0) + sale.total;
    }
    return map;
  }

  // === LUCRO TOTAL DO PERÍODO (só admin) ===
  double getTotalProfitInRange(DateTime? start, DateTime? end) {
    if (_currentUserRole != 'admin') return 0.0;

    final filtered = _sales.where((s) {
      if (start != null && s.createdAt.isBefore(start)) return false;
      if (end != null && s.createdAt.isAfter(end)) return false;
      return true;
    }).toList();

    double total = 0.0;
    for (final sale in filtered) {
      final product = _products.firstWhere(
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
      total += profitPerUnit * sale.quantity;
    }
    return total;
  }
}