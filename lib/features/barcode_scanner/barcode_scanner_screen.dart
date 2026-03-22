import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/models/item.dart';
import '../../providers/database_provider.dart';

/// Full-screen barcode/QR scanner.
/// Scans and searches the DB for matching items (by model code).
/// If found, opens the item detail. Otherwise shows a "not found" message.
class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  String? _lastScanned;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;
    final code = barcode.rawValue!;
    if (code == _lastScanned) return;

    _lastScanned = code;
    setState(() => _processing = true);
    await _controller.stop();

    // Check if it's a PartVault QR share string
    if (code.startsWith('PV1|')) {
      if (mounted) {
        Navigator.pop(context, _QrScanResult(shareString: code));
      }
      return;
    }

    // Otherwise search by model code
    final items = await ref.read(itemRepositoryProvider).search(code);
    final matches =
        items.where((i) => i.modelCode?.trim().toLowerCase() == code.toLowerCase()).toList();

    if (!mounted) return;

    if (matches.isNotEmpty) {
      Navigator.pop(context, _BarcodeScanResult(item: matches.first));
    } else {
      // Show result and let user try again
      _showNotFoundDialog(code);
    }
  }

  void _showNotFoundDialog(String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nessun risultato'),
        content: Text('Nessun oggetto trovato con codice:\n"$code"'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _processing = false);
              _lastScanned = null;
              _controller.start();
            },
            child: const Text('Riprova'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, _BarcodeScanResult(code: code));
            },
            child: const Text('Usa come codice'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scansiona codice'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, value, child) {
                return Icon(
                  value.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: _controller.toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Viewfinder overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: cs.primary, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Bottom hint
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Inquadra barcode o QR code',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
          if (_processing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _BarcodeScanResult {
  final Item? item;
  final String? code;
  _BarcodeScanResult({this.item, this.code});
}

class _QrScanResult {
  final String shareString;
  _QrScanResult({required this.shareString});
}

/// Helper used by other screens to launch the scanner and get a result.
Future<String?> scanBarcodeForCode(BuildContext context) async {
  final result = await Navigator.push<dynamic>(
    context,
    MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
  );
  if (result is _BarcodeScanResult) {
    return result.item?.modelCode ?? result.code;
  }
  return null;
}

Future<Item?> scanBarcodeForItem(BuildContext context) async {
  final result = await Navigator.push<dynamic>(
    context,
    MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
  );
  if (result is _BarcodeScanResult) return result.item;
  return null;
}

Future<String?> scanBarcodeForShareString(BuildContext context) async {
  final result = await Navigator.push<dynamic>(
    context,
    MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
  );
  if (result is _QrScanResult) return result.shareString;
  return null;
}
