class PaymentMethod {
  static const String cash = 'cash';
  static const String upi = 'upi';
  static const String card = 'card';

  static String label(String method) {
    switch (method) {
      case upi:
        return 'UPI';
      case card:
        return 'Card';
      default:
        return 'Cash';
    }
  }
}

class Expense {
  final int? id;
  final String title;
  final double amount;
  final int categoryId;
  final DateTime date;
  final String paymentMethod;

  /// UPI payee details, populated when the expense was recorded through the
  /// QR scan-and-pay flow.
  final String? payeeVpa;
  final String? payeeName;
  final String? txnRef;
  final String? note;

  const Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.paymentMethod = PaymentMethod.cash,
    this.payeeVpa,
    this.payeeName,
    this.txnRef,
    this.note,
  });

  Expense copyWith({
    int? id,
    String? title,
    double? amount,
    int? categoryId,
    DateTime? date,
    String? paymentMethod,
    String? payeeVpa,
    String? payeeName,
    String? txnRef,
    String? note,
  }) =>
      Expense(
        id: id ?? this.id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        categoryId: categoryId ?? this.categoryId,
        date: date ?? this.date,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        payeeVpa: payeeVpa ?? this.payeeVpa,
        payeeName: payeeName ?? this.payeeName,
        txnRef: txnRef ?? this.txnRef,
        note: note ?? this.note,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category_id': categoryId,
        'date': date.toIso8601String(),
        'payment_method': paymentMethod,
        'payee_vpa': payeeVpa,
        'payee_name': payeeName,
        'txn_ref': txnRef,
        'note': note,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as int?,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        categoryId: map['category_id'] as int,
        date: DateTime.parse(map['date'] as String),
        paymentMethod: map['payment_method'] as String? ?? PaymentMethod.cash,
        payeeVpa: map['payee_vpa'] as String?,
        payeeName: map['payee_name'] as String?,
        txnRef: map['txn_ref'] as String?,
        note: map['note'] as String?,
      );
}
