/// Parsed contents of a UPI payment QR code.
///
/// UPI QR codes encode a deep link of the form:
///   upi://pay?pa=<payee-vpa>&pn=<payee-name>&am=<amount>&tn=<note>&cu=INR
class UpiPaymentDetails {
  final String payeeVpa;
  final String? payeeName;
  final double? amount;
  final String? transactionNote;
  final String? transactionRef;
  final String? merchantCode;
  final String currency;

  const UpiPaymentDetails({
    required this.payeeVpa,
    this.payeeName,
    this.amount,
    this.transactionNote,
    this.transactionRef,
    this.merchantCode,
    this.currency = 'INR',
  });

  /// Parses a raw QR payload. Returns null if it is not a valid UPI
  /// payment link (wrong scheme or missing payee address).
  static UpiPaymentDetails? fromString(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme.toLowerCase() != 'upi') return null;

    final params = <String, String>{};
    uri.queryParameters.forEach((key, value) {
      params[key.toLowerCase()] = value;
    });

    final payeeVpa = params['pa'];
    if (payeeVpa == null || payeeVpa.trim().isEmpty) return null;

    return UpiPaymentDetails(
      payeeVpa: payeeVpa.trim(),
      payeeName: _nonEmpty(params['pn']),
      amount: double.tryParse(params['am'] ?? ''),
      transactionNote: _nonEmpty(params['tn']),
      transactionRef: _nonEmpty(params['tr']),
      merchantCode: _nonEmpty(params['mc']),
      currency: _nonEmpty(params['cu']) ?? 'INR',
    );
  }

  static String? _nonEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Builds the upi://pay deep link used to hand off to an installed UPI
  /// app (Google Pay, PhonePe, Paytm, BHIM, ...).
  Uri toUri({double? overrideAmount, String? overrideNote}) {
    final effectiveAmount = overrideAmount ?? amount;
    final effectiveNote = overrideNote ?? transactionNote;
    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': payeeVpa,
        if (payeeName != null) 'pn': payeeName!,
        if (effectiveAmount != null && effectiveAmount > 0)
          'am': effectiveAmount.toStringAsFixed(2),
        if (effectiveNote != null) 'tn': effectiveNote,
        if (transactionRef != null) 'tr': transactionRef!,
        if (merchantCode != null) 'mc': merchantCode!,
        'cu': currency,
      },
    );
  }

  String get displayName => payeeName ?? payeeVpa;
}
