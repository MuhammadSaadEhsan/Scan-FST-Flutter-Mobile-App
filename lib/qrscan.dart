import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;

// class QRCode extends StatelessWidget {
//   const QRCode({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Flutter Demo QR Code Scanner')),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () {
//             Navigator.of(context).push(MaterialPageRoute(
//               builder: (context) => const QRViewExample(),
//             ));
//           },
//           child: const Text('qrView'),
//         ),
//       ),
//     );
//   }
// }

class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool _isProcessing = false; // Show loader while processing
  bool _isSuccess = false; // Show green tick for success

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.red,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      if (!_isProcessing) {
        _processQRCode(scanData.code!);
      }
    });
  }

  Future<void> _processQRCode(String code) async {
    setState(() {
      _isProcessing = true; // Show loader
    });

    // const apiUrl = 'https://yourgutmap-food-sensitivity-423a2af84621.herokuapp.com/kitrecbyqr';
    const apiUrl = 'https://testforlife-a4b515517434.herokuapp.com/kitrecbyqr';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'qrCode': code}),
        // body: {'qrCode': code},
      );

      // if (response.statusCode == 200 && response.body.contains('saved')) {
      if (response.statusCode == 200) {
        setState(() {
          _isSuccess = true; // Show green tick
          _isProcessing = false;
        });

        // Show tick for 3 seconds and then allow new scan
        await Future.delayed(const Duration(seconds: 3));
        setState(() {
          _isSuccess = false;
        });
      }
      else {
  log('Failed to retrieve kit: ${response.body}');
  // Show error message
  setState(() {
    _isProcessing = false;
  });
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${response.body}')),
  );
}
    } catch (e) {
      log('Error sending QR code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('An error occurred: $e')),
  );
    } finally {
      setState(() {
        _isProcessing = false; // Hide loader
      });
    }
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildQrView(context),
          if (_isProcessing)
            Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          if (_isSuccess)
            Center(
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              ),
            ),
        ],
      ),
    );
  }
}
