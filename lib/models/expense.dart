class Expense {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String employeeId; // NOVO

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.employeeId,
  });

  Expense copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    String? employeeId,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      employeeId: employeeId ?? this.employeeId,
    );
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      employeeId: map['employee_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'employee_id': employeeId,
    };
  }
}