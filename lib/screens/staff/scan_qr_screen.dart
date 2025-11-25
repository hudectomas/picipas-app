import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import 'add_points_screen.dart';
import 'dart:convert';

// Conditional import - only import mobile_scanner on non-web platforms
import 'mobile_scanner_import.dart' if (dart.library.html) 'mobile_scanner_web_stub.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final _qrCodeController = TextEditingController();
  bool _isProcessing = false;
  bool _isScanning = false;
  final bool _isWeb = kIsWeb;
  dynamic _scannerController;
  dynamic _scannerWidget;

  @override
  void initState() {
    super.initState();
    if (!_isWeb) {
      _scannerController = createMobileScannerController();
      // Scanner sa nespúšťa automaticky - čaká na button
      _scannerWidget = createMobileScanner(
        controller: _scannerController,
        onDetect: _handleBarcode,
      );
    }
  }

  void _startScanning() {
    if (_isWeb || _scannerController == null) return;
    
    setState(() {
      _isScanning = true;
    });
    
    // Scanner sa spúšťa automaticky keď je widget zobrazený
    // Len nastavíme flag, aby callback reagoval
  }

  void _stopScanning() {
    if (_isWeb || _scannerController == null) return;
    
    setState(() {
      _isScanning = false;
    });
    
    // Scanner sa nezastaví, len nebudeme spracovávať výsledky
  }

  Future<void> _handleQrCode(String qrCode) async {
    if (_isProcessing || qrCode.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await ApiService.post('/points/qr-scan', {
        'qr_code': qrCode,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddPointsScreen(customer: data['user']),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Zákazník nebol nájdený'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleBarcode(dynamic barcodeCapture) async {
    if (_isProcessing || _isWeb) return;

    try {
      if (barcodeCapture.barcodes.isEmpty) return;
      final barcode = barcodeCapture.barcodes.first;
      if (barcode.rawValue == null) return;

      await _handleQrCode(barcode.rawValue!);
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    if (_scannerController != null) {
      disposeMobileScannerController(_scannerController);
    }
    _qrCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skenovať QR kód'),
      ),
      body: _isWeb ? _buildWebView() : _buildMobileView(),
    );
  }

  Widget _buildWebView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2D2D2D),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_scanner,
                size: 80,
                color: Color(0xFFFF6B35),
              ),
              const SizedBox(height: 32),
              const Text(
                'QR kód zákazníka',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Na web platforme zadajte QR kód manuálne\nalebo použite webkameru (ak je dostupná)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _qrCodeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'QR kód',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'Vložte QR kód zákazníka',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.qr_code, color: Color(0xFFFF6B35)),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF6B35)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF6B35)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                  ),
                ),
                onSubmitted: _handleQrCode,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _handleQrCode(_qrCodeController.text.trim()),
                  icon: const Icon(Icons.search),
                  label: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Vyhľadať zákazníka'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Button na spustenie webkamery (ak je dostupná)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          // Na web použijeme HTML5 QR scanner cez JavaScript
                          _startWebCameraScan();
                        },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Použiť webkameru'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B35),
                    side: const BorderSide(color: Color(0xFFFF6B35)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startWebCameraScan() {
    // Pre web platformu - použiť HTML5 QR scanner cez JavaScript
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          title: const Text('Webkamera QR Scanner', style: TextStyle(color: Colors.white)),
          content: const SizedBox(
            width: 400,
            height: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, size: 64, color: Color(0xFFFF6B35)),
                SizedBox(height: 16),
                Text(
                  'Pre skenovanie QR kódu pomocou webkamery na web platforme:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 16),
                Text(
                  '1. Povolte prístup k webkamere v prehliadači\n'
                  '2. Webkamera sa automaticky spustí\n'
                  '3. Namierte kamero na QR kód\n\n'
                  'Momentálne prosím zadajte QR kód manuálne do textového poľa, alebo použite mobilnú aplikáciu pre plnú funkcionalitu skenera.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Rozumiem', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implementovať plnú funkcionalitu webkamery pomocou html5-qrcode a js interop
                // Pre teraz používajte manuálny vstup
              },
              child: const Text('Použiť webkameru'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMobileView() {
    // Vždy zobraziť button, aj keď scanner nie je inicializovaný
    return Stack(
      children: [
        // Scanner widget - zobrazený len ak je inicializovaný
        if (_scannerWidget != null) _scannerWidget,
        
        // Ak scanner nie je inicializovaný, zobraziť placeholder
        if (_scannerWidget == null)
          Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, size: 80, color: Colors.white54),
                  SizedBox(height: 16),
                  Text(
                    'Inicializujem skener...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        
        // Overlay s inštrukciami - zobrazený len ak skenuje
        if (_isScanning)
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Namierte fotoaparát na QR kód zákazníka',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        
        // Button "Skenovať" - zobrazený len ak neprebieha skenovanie
        if (!_isScanning && !_isProcessing)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startScanning,
                icon: const Icon(Icons.qr_code_scanner, size: 28),
                label: const Text(
                  'Skenovať QR kód',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
              ),
            ),
          ),
        
        // Button "Zastaviť skenovanie" - zobrazený počas skenovania
        if (_isScanning && !_isProcessing)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _stopScanning,
                icon: const Icon(Icons.stop_circle, size: 28),
                label: const Text(
                  'Zastaviť skenovanie',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
              ),
            ),
          ),
        
        // Loading overlay počas spracovania
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Vyhľadávam zákazníka...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
