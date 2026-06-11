import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../screens/add_expense_screen.dart';
import '../utils/formatters.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;

  const ExpenseTile({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();
    final category = provider.categoryById(expense.categoryId);

    final subtitleParts = <String>[
      category.name,
      PaymentMethod.label(expense.paymentMethod),
      if (expense.payeeVpa != null) expense.payeeVpa!,
    ];

    return Dismissible(
      key: ValueKey('expense-${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete expense?'),
          content: Text('"${expense.title}" will be removed permanently.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
      onDismissed: (_) => provider.deleteExpense(expense.id!),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.color.withOpacity(0.15),
          child: Icon(category.icon, color: category.color),
        ),
        title: Text(expense.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          subtitleParts.join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '- ${formatCurrency(expense.amount)}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddExpenseScreen(initial: expense)),
        ),
      ),
    );
  }
}
