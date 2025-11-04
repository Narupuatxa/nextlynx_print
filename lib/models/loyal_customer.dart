// lib/models/loyal_customer.dart
class LoyalCustomer {
  final String id;
  final String name;
  final String phone;
  final int copiesQty;
  final double paidValue;
  final double totalValue;
  final DateTime date;
  final String employeeId; // NOVO: para RLS

  LoyalCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.copiesQty,
    required this.paidValue,
    required this.totalValue,
    required this.date,
    required this.employeeId,
  });

  // MÉTODO copyWith() ADICIONADO
  LoyalCustomer copyWith({
    String? id,
    String? name,
    String? phone,
    int? copiesQty,
    double? paidValue,
    double? totalValue,
    DateTime? date,
    String? employeeId,
  }) {
    return LoyalCustomer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      copiesQty: copiesQty ?? this.copiesQty,
      paidValue: paidValue ?? this.paidValue,
      totalValue: totalValue ?? this.totalValue,
      date: date ?? this.date,
      employeeId: employeeId ?? this.employeeId,
    );
  }

  factory LoyalCustomer.fromMap(Map<String, dynamic> map) {
    return LoyalCustomer(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      copiesQty: map['copies_qty'] ?? 0,
      paidValue: (map['paid_value'] ?? 0.0).toDouble(),
      totalValue: (map['total_value'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      employeeId: map['employee_id'] ?? '', // NOVO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, // ADICIONADO: necessário para update
      'name': name,
      'phone': phone,
      'copies_qty': copiesQty,
      'paid_value': paidValue,
      'total_value': totalValue,
      'date': date.toIso8601String(),
      'employee_id': employeeId, // ADICIONADO
    };
  }
}