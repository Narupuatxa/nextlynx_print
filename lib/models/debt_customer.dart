// lib/models/debt_customer.dart
class DebtCustomer {
  final String id;
  final String name;
  final String? profession;
  final String phone;
  final int copiesQty;
  final double amount;
  final DateTime debtDate;
  final DateTime? paymentDate;
  final String employeeId; // NOVO: para RLS

  DebtCustomer({
    required this.id,
    required this.name,
    this.profession,
    required this.phone,
    required this.copiesQty,
    required this.amount,
    required this.debtDate,
    this.paymentDate,
    required this.employeeId,
  });

  // MÉTODO copyWith() ADICIONADO
  DebtCustomer copyWith({
    String? id,
    String? name,
    String? profession,
    String? phone,
    int? copiesQty,
    double? amount,
    DateTime? debtDate,
    DateTime? paymentDate,
    String? employeeId,
  }) {
    return DebtCustomer(
      id: id ?? this.id,
      name: name ?? this.name,
      profession: profession ?? this.profession,
      phone: phone ?? this.phone,
      copiesQty: copiesQty ?? this.copiesQty,
      amount: amount ?? this.amount,
      debtDate: debtDate ?? this.debtDate,
      paymentDate: paymentDate ?? this.paymentDate,
      employeeId: employeeId ?? this.employeeId,
    );
  }

  factory DebtCustomer.fromMap(Map<String, dynamic> map) {
    return DebtCustomer(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      profession: map['profession'],
      phone: map['phone'] ?? '',
      copiesQty: map['copies_qty'] ?? 0,
      amount: (map['amount'] ?? 0.0).toDouble(),
      debtDate: DateTime.parse(map['debt_date'] ?? DateTime.now().toIso8601String()),
      paymentDate: map['payment_date'] != null ? DateTime.parse(map['payment_date']) : null,
      employeeId: map['employee_id'] ?? '', // NOVO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, // ADICIONADO: necessário para update
      'name': name,
      'profession': profession,
      'phone': phone,
      'copies_qty': copiesQty,
      'amount': amount,
      'debt_date': debtDate.toIso8601String(),
      'payment_date': paymentDate?.toIso8601String(),
      'employee_id': employeeId, // ADICIONADO
    };
  }
}