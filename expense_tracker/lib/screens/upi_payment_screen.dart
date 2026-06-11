import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/upi_parser.dart';

/// Shown after a UPI QR code is scanned. Lets the user confirm the amount
/// and category, hands off to an installed UPI app (Google Pay, PhonePe,
/// Paytm, BHIM, ...) via the upi://pay deep link, and records the payment
/// as an expense in the local database.
class UpiPaymentScreen extends StatefulWidget {
  final UpiPaymentDetails details;

  const UpiPaymentScreen({super.key, required this.details});

  @override
  State<UpiPaymentScreen> createState() => _UpiPaymentScreenState();
}

class _UpiPaymentScreenState extends State<UpiPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  int? _categoryId;
  bool _launching = false;

  /// QR codes for fixed-amount payments lock the amount in the UPI app,
  /// so it is not editable here either.
  bool get _amountLocked => widget.details.amount != null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.details.amount?.toStringAsFixed(2) ?? '',
    );
    _noteController =
        TextEditingController(text: widget.details.transactionNote ?? '');
    final categories = context.read<ExpenseProvider>().categories;
    // Default to the catch-all category (seeded last) for scanned payments.
    _categoryId = categories.isEmpty ? null : categories.last.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  Future<void> _recordExpense() async {
    final details = widget.details;
    final note = _noteController.text.trim();
    final expense = Expense(
      title: details.displayName,
      amount: _amount,
      categoryId: _categoryId!,
      date: DateTime.now(),
      paymentMethod: PaymentMethod.upi,
      payeeVpa: details.payeeVpa,
      payeeName: details.payeeName,
      txnRef: details.transactionRef,
      note: note.isEmpty ? null : note,
    );
    await context.read<ExpenseProvider>().addExpense(expense);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _payWithUpiApp() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;

    setState(() => _launching = true);
    final uri = widget.details.toUri(
      overrideAmount: _amount,
      overrideNote: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!mounted) return;
    setState(() => _launching = false);

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No UPI app found on this device'),
        ),
      );
      return;
    }

    // The UPI app has been opened; once the user comes back, ask whether
    // the payment went through before recording it.
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Payment completed?'),
        content: const Text(
          'Did you complete the payment in your UPI app? '
          'If yes, it will be saved to your expenses.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No / Failed'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes, record it'),
          ),
        ],
      ),
    );

    if (completed == true && mounted) {
      await _recordExpense();
    }
  }

  Future<void> _recordOnly() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;
    await _recordExpense();
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.details;
    final categories = context.watch<ExpenseProvider>().categories;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('UPI Payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.storefront, color: colorScheme.primary),
                ),
                title: Text(details.displayName),
                subtitle: Text(details.payeeVpa),
                trailing: details.merchantCode != null
                    ? const Tooltip(
                        message: 'Verified merchant QR',
                        child: Icon(Icons.verified_outlined),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              enabled: !_amountLocked,
              autofocus: !_amountLocked,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: const OutlineInputBorder(),
                helperText: _amountLocked
                    ? 'Amount is fixed by this QR code'
                    : 'Enter the amount to pay',
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
            TextFormField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _launching ? null : _payWithUpiApp,
              icon: _launching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.open_in_new),
              label: const Text('Pay with UPI app'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _launching ? null : _recordOnly,
              child: const Text('Already paid — just record it'),
            ),
          ],
        ),
      ),
    );
  }
}
