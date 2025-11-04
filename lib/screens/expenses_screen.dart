import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expenses_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart' as custom_app_bar;
import '../models/expense.dart';
import '../models/note.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _expenseFormKey = GlobalKey<FormState>();
  final _expenseDescController = TextEditingController();
  final _expenseAmountController = TextEditingController();

  final _noteFormKey = GlobalKey<FormState>();
  final _noteContentController = TextEditingController();

  DateTimeRange? _selectedRange;
  DateTime _start = DateTime.now().subtract(const Duration(days: 7));
  DateTime _end = DateTime.now();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ExpensesProvider>(context, listen: false);
    provider.fetchExpenses();
    provider.fetchNotes();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _start, end: _end),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.red.shade600,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
        _start = picked.start;
        _end = picked.end;
      });
    }
  }

  void _clearExpenseControllers() {
    _expenseDescController.clear();
    _expenseAmountController.clear();
  }

  void _showExpenseDialog({Expense? expense}) {
    if (expense != null) {
      _expenseDescController.text = expense.description;
      _expenseAmountController.text = expense.amount.toStringAsFixed(2);
    } else {
      _clearExpenseControllers();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(expense == null ? 'Adicionar Despesa' : 'Editar Despesa'),
        content: Form(
          key: _expenseFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _expenseDescController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: _expenseAmountController,
                decoration: const InputDecoration(labelText: 'Valor (MT)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v!.trim().isEmpty) return 'Obrigatório';
                  final val = double.tryParse(v);
                  if (val == null || val <= 0) return 'Valor inválido';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearExpenseControllers();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_expenseFormKey.currentState!.validate()) {
                final userId = Provider.of<AuthProvider>(context, listen: false).user!.id;
                final updatedExpense = Expense(
                  id: expense?.id ?? '',
                  description: _expenseDescController.text.trim(),
                  amount: double.parse(_expenseAmountController.text),
                  date: expense?.date ?? DateTime.now(),
                  employeeId: userId,
                );

                final prov = Provider.of<ExpensesProvider>(context, listen: false);
                if (expense == null) {
                  prov.addExpense(updatedExpense);
                } else {
                  prov.updateExpense(updatedExpense);
                }

                Navigator.pop(context);
                _clearExpenseControllers();
              }
            },
            child: Text(expense == null ? 'Adicionar' : 'Salvar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExpense(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Despesa'),
        content: const Text('Tem certeza que deseja excluir esta despesa?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<ExpensesProvider>(context, listen: false).deleteExpense(id);
              Navigator.pop(context);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _clearNoteController() => _noteContentController.clear();

  void _showNoteDialog({Note? note}) {
    if (note != null) {
      _noteContentController.text = note.content;
    } else {
      _clearNoteController();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(note == null ? 'Adicionar Nota' : 'Editar Nota'),
        content: Form(
          key: _noteFormKey,
          child: TextFormField(
            controller: _noteContentController,
            decoration: const InputDecoration(labelText: 'Conteúdo da nota'),
            maxLines: 5,
            validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearNoteController();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_noteFormKey.currentState!.validate()) {
                final userId = Provider.of<AuthProvider>(context, listen: false).user!.id;
                final updatedNote = Note(
                  id: note?.id ?? '',
                  content: _noteContentController.text.trim(),
                  date: note?.date ?? DateTime.now(),
                  employeeId: userId,
                );

                final prov = Provider.of<ExpensesProvider>(context, listen: false);
                if (note == null) {
                  prov.addNote(updatedNote);
                } else {
                  prov.updateNote(updatedNote);
                }

                Navigator.pop(context);
                _clearNoteController();
              }
            },
            child: Text(note == null ? 'Adicionar' : 'Salvar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteNote(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Nota'),
        content: const Text('Tem certeza que deseja excluir esta nota?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<ExpensesProvider>(context, listen: false).deleteNote(id);
              Navigator.pop(context);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  double _calculateTotalExpenses(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  List<Expense> _filterExpenses(List<Expense> expenses) {
    if (_selectedRange == null) return expenses;
    return expenses.where((e) {
      return e.date.isAfter(_selectedRange!.start.subtract(const Duration(days: 1))) &&
             e.date.isBefore(_selectedRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpensesProvider>(context);
    final filteredExpenses = _filterExpenses(provider.expenses);
    final totalExpenses = _calculateTotalExpenses(filteredExpenses);
    final currencyFormat = NumberFormat.currency(locale: 'pt_MZ', symbol: 'MT');

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    // ALTURAS AJUSTADAS
    final expenseCardHeight = isMobile ? 140.0 : 160.0;
    final noteCardMinHeight = isMobile ? 180.0 : 200.0;

    return Scaffold(
      appBar: custom_app_bar.CustomAppBar(),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/despesas.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // CABEÇALHO FIXO E VISÍVEL
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 20,
                  vertical: isMobile ? 12 : 16,
                ),
                color: Colors.white.withOpacity(0.95),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TÍTULO
                    Text(
                      'Gestão de Despesas e Notas',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.black87,
                            fontSize: isMobile ? 22 : 26,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // FILTRO + TOTAL
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectDateRange,
                            icon: const Icon(Icons.date_range, size: 20),
                            label: Text(
                              _selectedRange == null
                                  ? 'TODAS AS DATAS'
                                  : '${DateFormat('dd/MM').format(_start)} - ${DateFormat('dd/MM').format(_end)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_selectedRange != null)
                          TextButton.icon(
                            onPressed: () => setState(() => _selectedRange = null),
                            icon: const Icon(Icons.clear, size: 18),
                            label: const Text('LIMPAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // TOTAL
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Text(
                        'TOTAL NO PERÍODO: ${currencyFormat.format(totalExpenses)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // BOTÕES DE AÇÃO
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showExpenseDialog(),
                        icon: const Icon(Icons.add_circle_outline, size: 22),
                        label: const Text(
                          'ADICIONAR DESPESA',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showNoteDialog(),
                        icon: const Icon(Icons.note_add_outlined, size: 22),
                        label: const Text(
                          'ADICIONAR NOTA',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // CONTEÚDO COM SCROLL
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // DESPESAS
                      Text(
                        'Despesas',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      filteredExpenses.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhuma despesa no período',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredExpenses.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final e = filteredExpenses[i];
                                return Card(
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    side: BorderSide(color: Colors.red.shade200, width: 1.5),
                                  ),
                                  child: Container(
                                    height: expenseCardHeight,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.red.shade50, Colors.red.shade100],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: isMobile ? 24 : 28,
                                          backgroundColor: Colors.red.shade700,
                                          child: Icon(Icons.paid, color: Colors.white, size: isMobile ? 24 : 28),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                e.description,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: isMobile ? 15 : 16,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '${e.amount.toStringAsFixed(2)} MT',
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontSize: isMobile ? 18 : 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat('dd/MM/yyyy HH:mm').format(e.date),
                                                style: TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: isMobile ? 13 : 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit, color: Colors.blue.shade700, size: isMobile ? 22 : 24),
                                              onPressed: () => _showExpenseDialog(expense: e),
                                              tooltip: 'Editar',
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete, color: Colors.red.shade700, size: isMobile ? 22 : 24),
                                              onPressed: () => _confirmDeleteExpense(e.id),
                                              tooltip: 'Excluir',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                      const SizedBox(height: 32),

                      // NOTAS
                      Text(
                        'Notas',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      provider.notes.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhuma nota cadastrada',
                                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: provider.notes.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (_, i) {
                                final n = provider.notes[i];
                                return Card(
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: Colors.orange.shade300, width: 2),
                                  ),
                                  child: Container(
                                    constraints: BoxConstraints(minHeight: noteCardMinHeight),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: isMobile ? 22 : 26,
                                              backgroundColor: Colors.orange.shade700,
                                              child: Icon(Icons.note, color: Colors.white, size: isMobile ? 22 : 26),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Text(
                                                DateFormat('dd/MM/yyyy HH:mm').format(n.date),
                                                style: TextStyle(
                                                  fontSize: isMobile ? 14 : 15,
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.edit, color: Colors.blue.shade700, size: isMobile ? 22 : 24),
                                                  onPressed: () => _showNoteDialog(note: n),
                                                  tooltip: 'Editar',
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete, color: Colors.red.shade700, size: isMobile ? 22 : 24),
                                                  onPressed: () => _confirmDeleteNote(n.id),
                                                  tooltip: 'Excluir',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            physics: const BouncingScrollPhysics(),
                                            child: Text(
                                              n.content,
                                              style: TextStyle(
                                                fontSize: isMobile ? 15 : 16,
                                                color: Colors.black87,
                                                height: 1.6,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _expenseDescController.dispose();
    _expenseAmountController.dispose();
    _noteContentController.dispose();
    super.dispose();
  }
}