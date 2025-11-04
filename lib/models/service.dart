class Service {
  final String id;
  final String name;
  final String category;
  final double fixedPrice;
  final String? description;
  final String? type;
  final double purchaseCost;
  final double materialCost;
  final double saleValue;
  final int dailyQuantitySold;
  final double totalValue;
  final DateTime createdAt;
  final String employeeId;

  Service({
    required this.id,
    required this.name,
    required this.category,
    required this.fixedPrice,
    this.description,
    this.type,
    required this.purchaseCost,
    required this.materialCost,
    required this.saleValue,
    required this.dailyQuantitySold,
    required this.totalValue,
    required this.createdAt,
    required this.employeeId,
  });

  Service copyWith({
    String? id,
    String? name,
    String? category,
    double? fixedPrice,
    String? description,
    String? type,
    double? purchaseCost,
    double? materialCost,
    double? saleValue,
    int? dailyQuantitySold,
    double? totalValue,
    DateTime? createdAt,
    String? employeeId,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      fixedPrice: fixedPrice ?? this.fixedPrice,
      description: description ?? this.description,
      type: type ?? this.type,
      purchaseCost: purchaseCost ?? this.purchaseCost,
      materialCost: materialCost ?? this.materialCost,
      saleValue: saleValue ?? this.saleValue,
      dailyQuantitySold: dailyQuantitySold ?? this.dailyQuantitySold,
      totalValue: totalValue ?? this.totalValue,
      createdAt: createdAt ?? this.createdAt,
      employeeId: employeeId ?? this.employeeId,
    );
  }

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      fixedPrice: (map['fixed_price'] ?? 0.0).toDouble(),
      description: map['description'],
      type: map['type'],
      purchaseCost: (map['purchase_cost'] ?? 0.0).toDouble(),
      materialCost: (map['material_cost'] ?? 0.0).toDouble(),
      saleValue: (map['sale_value'] ?? 0.0).toDouble(),
      dailyQuantitySold: map['daily_quantity_sold'] ?? 0,
      totalValue: (map['total_value'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      employeeId: map['employee_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'fixed_price': fixedPrice,
      'description': description,
      'type': type,
      'purchase_cost': purchaseCost,
      'material_cost': materialCost,
      'sale_value': saleValue,
      'daily_quantity_sold': dailyQuantitySold,
      'total_value': totalValue,
      'created_at': createdAt.toIso8601String(),
      'employee_id': employeeId,
    };
  }
}