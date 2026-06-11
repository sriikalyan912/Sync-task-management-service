import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/formatters.dart';

class AddExpenseScreen extends StatefulWidget {
  /// When non-null the screen edits an existing expense.
  final Expense? initial;

  const AddExpenseScreen({super.key, this.initial});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late DateTime _date;
  late String _paymentMethod;
  int? _categoryId;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _amountController = TextEditingController(
      text: initial == null ? '' : initial.amount.toStringAsFixed(2),
    );
    _titleController = TextEditingController(text: initial?.title ?? '');
    _noteController = TextEditingController(text: initial?.note ?? '');
    _date = initial?.date ?? DateTime.now();
    _paymentMethod = initial?.paymentMethod ?? PaymentMethod.cash;
    _categoryId = initial?.categoryId ??
        context.read<ExpenseProvider>().categories.firstOrNull?.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;

    final provider = context.read<ExpenseProvider>();
    final expense = Expense(
      id: widget.initial?.id,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      categoryId: _categoryId!,
      date: _date,
      paymentMethod: _paymentMethod,
      payeeVpa: widget.initial?.payeeVpa,
      payeeName: widget.initial?.payeeName,
      txnRef: widget.initial?.txnRef,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (_isEditing) {
      await provider.updateExpense(expense);
    } else {
      await provider.addExpense(expense);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ExpenseProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Lunch at cafe',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _categoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final category in categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Row(
                      children: [
                        Icon(category.icon, color: category.color, size: 20),
                        const SizedBox(width: 12),
                        Text(category.name),
                      ],
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _categoryId = value),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(formatShortDate(_date)),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: PaymentMethod.cash,
                  label: Text('Cash'),
                  icon: Icon(Icons.payments_outlined),
                ),
                ButtonSegment(
                  value: PaymentMethod.upi,
                  label: Text('UPI'),
                  icon: Icon(Icons.qr_code),
                ),
                ButtonSegment(
                  value: PaymentMethod.card,
                  label: Text('Card'),
                  icon: Icon(Icons.credit_card),
                ),
              ],
              selected: {_paymentMethod},
              onSelectionChanged: (selection) =>
                  setState(() => _paymentMethod = selection.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_isEditing ? 'Save changes' : 'Add expense'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
