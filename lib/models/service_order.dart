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

  ServiceOrder copyWith({
    String? id,
    String? serviceId,
    int? quantity,
    double? totalPrice,
    DateTime? createdAt,
    String? employeeId,
  }) {
    return ServiceOrder(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      employeeId: employeeId ?? this.employeeId,
    );
  }

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