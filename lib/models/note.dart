class Note {
  final String id;
  final String content;
  final DateTime date;
  final String employeeId; // NOVO

  Note({
    required this.id,
    required this.content,
    required this.date,
    required this.employeeId,
  });

  Note copyWith({
    String? id,
    String? content,
    DateTime? date,
    String? employeeId,
  }) {
    return Note(
      id: id ?? this.id,
      content: content ?? this.content,
      date: date ?? this.date,
      employeeId: employeeId ?? this.employeeId,
    );
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      employeeId: map['employee_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'date': date.toIso8601String(),
      'employee_id': employeeId,
    };
  }
}