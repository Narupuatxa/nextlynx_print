class Product {
  final String id;
  final String name;
  final double price;
  final double cost;
  final int stock;
  final int lowStockThreshold;
  final String employeeId; // NOVO: para RLS

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.cost,
    required this.stock,
    this.lowStockThreshold = 5,
    required this.employeeId,
  });

  // MÉTODO copyWith() ADICIONADO
  Product copyWith({
    String? id,
    String? name,
    double? price,
    double? cost,
    int? stock,
    int? lowStockThreshold,
    String? employeeId,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      employeeId: employeeId ?? this.employeeId,
    );
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      cost: (map['cost'] ?? 0.0).toDouble(),
      stock: map['stock'] ?? 0,
      lowStockThreshold: map['low_stock_threshold'] ?? 5,
      employeeId: map['employee_id'] ?? '', // NOVO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, // ADICIONADO: necessário para update
      'name': name,
      'price': price,
      'cost': cost,
      'stock': stock,
      'low_stock_threshold': lowStockThreshold,
      'employee_id': employeeId, // ADICIONADO
    };
  }
}