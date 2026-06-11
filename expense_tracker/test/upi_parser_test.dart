import 'package:expense_tracker/utils/upi_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpiPaymentDetails.fromString', () {
    test('parses a full UPI QR payload', () {
      final details = UpiPaymentDetails.fromString(
        'upi://pay?pa=merchant@okaxis&pn=Tea%20Stall&am=45.50'
        '&tn=Morning%20chai&tr=TXN12345&mc=5411&cu=INR',
      );

      expect(details, isNotNull);
      expect(details!.payeeVpa, 'merchant@okaxis');
      expect(details.payeeName, 'Tea Stall');
      expect(details.amount, 45.50);
      expect(details.transactionNote, 'Morning chai');
      expect(details.transactionRef, 'TXN12345');
      expect(details.merchantCode, '5411');
      expect(details.currency, 'INR');
    });

    test('parses a minimal QR with only a payee address', () {
      final details = UpiPaymentDetails.fromString('upi://pay?pa=friend@ybl');

      expect(details, isNotNull);
      expect(details!.payeeVpa, 'friend@ybl');
      expect(details.payeeName, isNull);
      expect(details.amount, isNull);
      expect(details.currency, 'INR');
      expect(details.displayName, 'friend@ybl');
    });

    test('handles uppercase scheme and parameter keys', () {
      final details =
          UpiPaymentDetails.fromString('UPI://pay?PA=shop@paytm&PN=Shop');

      expect(details, isNotNull);
      expect(details!.payeeVpa, 'shop@paytm');
      expect(details.payeeName, 'Shop');
    });

    test('rejects non-UPI QR contents', () {
      expect(UpiPaymentDetails.fromString('https://example.com'), isNull);
      expect(UpiPaymentDetails.fromString('hello world'), isNull);
      expect(UpiPaymentDetails.fromString(''), isNull);
    });

    test('rejects UPI links without a payee address', () {
      expect(UpiPaymentDetails.fromString('upi://pay?pn=NoVpa'), isNull);
      expect(UpiPaymentDetails.fromString('upi://pay?pa='), isNull);
    });
  });

  group('UpiPaymentDetails.toUri', () {
    test('builds a upi://pay deep link with overrides', () {
      final details = UpiPaymentDetails.fromString(
        'upi://pay?pa=merchant@okaxis&pn=Tea Stall',
      )!;

      final uri = details.toUri(overrideAmount: 120, overrideNote: 'Snacks');

      expect(uri.scheme, 'upi');
      expect(uri.host, 'pay');
      expect(uri.queryParameters['pa'], 'merchant@okaxis');
      expect(uri.queryParameters['pn'], 'Tea Stall');
      expect(uri.queryParameters['am'], '120.00');
      expect(uri.queryParameters['tn'], 'Snacks');
      expect(uri.queryParameters['cu'], 'INR');
    });

    test('omits the amount when none is set', () {
      final details = UpiPaymentDetails.fromString('upi://pay?pa=a@b')!;
      expect(details.toUri().queryParameters.containsKey('am'), isFalse);
    });
  });
}
