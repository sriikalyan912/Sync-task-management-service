import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/formatters.dart';
import '../widgets/expense_tile.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _addExpense(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    if (!provider.loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add expense',
            onPressed: () => _addExpense(context),
          ),
        ],
      ),
      body: provider.expenses.isEmpty
          ? _EmptyState(onAdd: () => _addExpense(context))
          : _ExpenseList(provider: provider),
    );
  }
}

class _ExpenseList extends StatelessWidget {
  final ExpenseProvider provider;

  const _ExpenseList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final groups = <DateTime, List<Expense>>{};
    for (final expense in provider.expenses) {
      final day =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      groups.putIfAbsent(day, () => []).add(expense);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _SummaryCard(provider: provider),
        for (final day in days) ...[
          _DayHeader(
            day: day,
            total: groups[day]!.fold(0.0, (sum, e) => sum + e.amount),
          ),
          for (final expense in groups[day]!) ExpenseTile(expense: expense),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ExpenseProvider provider;

  const _SummaryCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.tertiary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spent this month',
            style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency(provider.totalThisMonth),
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryStat(
                label: 'Today',
                value: formatCurrency(provider.totalToday),
                color: colorScheme.onPrimary,
              ),
              const SizedBox(width: 32),
              _SummaryStat(
                label: 'Transactions',
                value: '${provider.countThisMonth}',
                color: colorScheme.onPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime day;
  final double total;

  const _DayHeader({required this.day, required this.total});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(formatDay(day), style: style),
          Text(formatCurrency(total), style: style),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Add an expense or scan a UPI QR code to pay & track.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add expense'),
          ),
        ],
      ),
    );
  }
}
