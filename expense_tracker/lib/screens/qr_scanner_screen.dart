import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../utils/upi_parser.dart';
import 'upi_payment_screen.dart';

/// Scans UPI payment QR codes. On a successful scan the user is taken to
/// [UpiPaymentScreen], which hands off to an installed UPI app and records
/// the payment as an expense.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _handling = false;
  DateTime _lastWarning = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _warnInvalidCode() {
    final now = DateTime.now();
    if (now.difference(_lastWarning).inSeconds < 3) return;
    _lastWarning = now;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Not a UPI payment QR code'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;

    String? raw;
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        raw = barcode.rawValue;
        break;
      }
    }
    if (raw == null) return;

    final details = UpiPaymentDetails.fromString(raw);
    if (details == null) {
      _warnInvalidCode();
      return;
    }

    _handling = true;
    await _controller.stop();
    if (!mounted) return;

    final recorded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UpiPaymentScreen(details: details)),
    );

    if (!mounted) return;
    if (recorded == true) {
      Navigator.of(context).pop(true);
    } else {
      _handling = false;
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanBoxSize = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan UPI QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Toggle torch',
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            tooltip: 'Switch camera',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Camera unavailable.\n'
                  'Please grant camera permission to scan QR codes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          Container(
            width: scanBoxSize,
            height: scanBoxSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Text(
              'Point the camera at a UPI QR code.\n'
              'You will be redirected to your UPI app to pay, and the '
              'payment is tracked here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
            ),
          ),
        ],
      ),
    );
  }
}
