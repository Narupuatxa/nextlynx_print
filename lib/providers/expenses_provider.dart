// expenses_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';
import '../models/note.dart';

class ExpensesProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  List<Note> _notes = [];

  List<Expense> get expenses => _expenses;
  List<Note> get notes => _notes;

  Future<void> fetchExpenses({DateTime? startDate, DateTime? endDate}) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      var query = Supabase.instance.client.from('expenses').select();

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }

      // Employee vê apenas suas despesas
      if (userId != null && !await _isAdmin(userId)) {
        query = query.eq('employee_id', userId);
      }

      final response = await query;
      _expenses = (response as List).map((map) => Expense.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar despesas: $e');
      rethrow;
    }
  }

  Future<void> fetchNotes() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      var query = Supabase.instance.client.from('notes').select();

      if (userId != null && !await _isAdmin(userId)) {
        query = query.eq('employee_id', userId);
      }

      final response = await query;
      _notes = (response as List).map((map) => Note.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar notas: $e');
      rethrow;
    }
  }

  Future<bool> _isAdmin(String userId) async {
    final roleResponse = await Supabase.instance.client
        .from('roles')
        .select('role')
        .eq('user_id', userId)
        .maybeSingle();
    return roleResponse?['role'] == 'admin';
  }

  // === ADICIONAR DESPESA ===
  Future<void> addExpense(Expense expense) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final newExpense = expense.copyWith(employeeId: userId);
      final map = newExpense.toMap();
      map.remove('id');
      await Supabase.instance.client.from('expenses').insert(map);
      await fetchExpenses();
      await _logAction('add_expense', {'description': expense.description});
    } catch (e) {
      debugPrint('Erro ao adicionar despesa: $e');
      rethrow;
    }
  }

  // === ADICIONAR NOTA ===
  Future<void> addNote(Note note) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final newNote = note.copyWith(employeeId: userId);
      final map = newNote.toMap();
      map.remove('id');
      await Supabase.instance.client.from('notes').insert(map);
      await fetchNotes();
      await _logAction('add_note', {'content': note.content});
    } catch (e) {
      debugPrint('Erro ao adicionar nota: $e');
      rethrow;
    }
  }

  // === ATUALIZAR DESPESA ===
  Future<void> updateExpense(Expense expense) async {
    if (expense.id.isEmpty) throw Exception('ID obrigatório');

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final newExpense = expense.copyWith(employeeId: userId);
      final map = newExpense.toMap();
      map.remove('employeeId');
      map.remove('date');

      await Supabase.instance.client
          .from('expenses')
          .update(map)
          .eq('id', expense.id);

      await fetchExpenses();
      await _logAction('update_expense', {
        'id': expense.id,
        'description': expense.description,
        'amount': expense.amount,
      });
    } catch (e) {
      debugPrint('Erro ao atualizar despesa: $e');
      rethrow;
    }
  }

  // === ATUALIZAR NOTA ===
  Future<void> updateNote(Note note) async {
    if (note.id.isEmpty) throw Exception('ID obrigatório');

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final newNote = note.copyWith(employeeId: userId);
      final map = newNote.toMap();
      map.remove('employeeId');
      map.remove('date');

      await Supabase.instance.client
          .from('notes')
          .update(map)
          .eq('id', note.id);

      await fetchNotes();
      await _logAction('update_note', {
        'id': note.id,
        'content': note.content,
      });
    } catch (e) {
      debugPrint('Erro ao atualizar nota: $e');
      rethrow;
    }
  }

  // === DELETAR DESPESA ===
  Future<void> deleteExpense(String id) async {
    try {
      await Supabase.instance.client.from('expenses').delete().eq('id', id);
      await fetchExpenses();
      await _logAction('delete_expense', {'id': id});
    } catch (e) {
      debugPrint('Erro ao remover despesa: $e');
      rethrow;
    }
  }

  // === DELETAR NOTA ===
  Future<void> deleteNote(String id) async {
    try {
      await Supabase.instance.client.from('notes').delete().eq('id', id);
      await fetchNotes();
      await _logAction('delete_note', {'id': id});
    } catch (e) {
      debugPrint('Erro ao remover nota: $e');
      rethrow;
    }
  }

  double getDailyTotal(DateTime date) {
    return _expenses
        .where((exp) =>
            exp.date.year == date.year &&
            exp.date.month == date.month &&
            exp.date.day == date.day)
        .fold(0.0, (sum, exp) => sum + exp.amount);
  }

  Future<void> _logAction(String action, Map<String, dynamic> details) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('audit_logs').insert({
        'action': action,
        'user_id': userId,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Erro ao registrar log: $e');
    }
  }
}