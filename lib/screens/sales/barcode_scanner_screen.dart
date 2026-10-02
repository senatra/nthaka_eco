import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _found = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Scan barcode')),
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              onDetect: (capture) {
                if (_found) return;
                final code = capture.barcodes.firstOrNull?.rawValue;
                if (code == null || code.isEmpty) return;
                _found = true;
                Navigator.pop(context, code);
              },
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Place a product barcode inside the camera view.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
