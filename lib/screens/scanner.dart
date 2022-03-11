import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QrScanner extends StatelessWidget {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late final QRViewController controller;
  late final BuildContext _context;

  QrScanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _context = context;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      controller.stopCamera();
      controller.dispose();
      Navigator.pop(_context, scanData.code);
    });
  }
}
