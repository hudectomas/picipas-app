import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import '../../services/offline_service.dart';
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
  final bool _isWeb = kIsWeb;
  dynamic _scannerController;
  dynamic _scannerWidget;
  bool _scannerReady = false;

  @override
  void initState() {
    super.initState();
    if (!_isWeb) {
      _initMobileScanner();
    }
  }

  void _initMobileScanner() {
    _scannerController = createMobileScannerController();
    _scannerWidget = createMobileScanner(
      controller: _scannerController,
      onDetect: _handleBarcode,
    );
    // Scanner automaticky funguje
    setState(() {
      _scannerReady = true;
    });
  }

  Future<void> _handleQrCode(String qrCode) async {
    if (_isProcessing || qrCode.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    final offlineService = OfflineService();
    final isOnline = await offlineService.isOnline();

    try {
      if (isOnline) {
        // Online - použiť API
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
      } else {
        // Offline - hľadať v cache podľa QR kódu
        final cachedUsers = await offlineService.getCachedUsers();
        final user = cachedUsers.firstWhere(
          (u) => u['qr_code'] == qrCode,
          orElse: () => <String, dynamic>{},
        );

        if (user.isNotEmpty && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddPointsScreen(customer: user),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Zákazník nebol nájdený v offline dátach'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Skúsiť offline ak online zlyhá
      try {
        final cachedUsers = await offlineService.getCachedUsers();
        final user = cachedUsers.firstWhere(
          (u) => u['qr_code'] == qrCode,
          orElse: () => <String, dynamic>{},
        );

        if (user.isNotEmpty && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddPointsScreen(customer: user),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chyba: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (offlineError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chyba: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
                'Na web platforme zadajte QR kód manuálne',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileView() {
    return Stack(
      children: [
        // Scanner widget - zobrazený automaticky
        if (_scannerWidget != null && _scannerReady) _scannerWidget,
        
        // Ak scanner nie je inicializovaný, zobraziť placeholder
        if (_scannerWidget == null || !_scannerReady)
          Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFF6B35)),
                  SizedBox(height: 16),
                  Text(
                    'Spúšťam fotoaparát...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        
        // Overlay s inštrukciami - vždy viditeľný
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
        
        // Rámček pre QR kód
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFFF6B35),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(20),
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
