// lib/widgets/tiffin_barcode_scanner_dialog.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/driver_order_service.dart';
import '../theme/app_theme.dart';

class TiffinBarcodeScannerDialog extends StatefulWidget {
  final int orderId;
  final String hotelName;
  final Function(String hotelName) onVerified;

  const TiffinBarcodeScannerDialog({
    super.key,
    required this.orderId,
    required this.hotelName,
    required this.onVerified,
  });

  @override
  State<TiffinBarcodeScannerDialog> createState() => _TiffinBarcodeScannerDialogState();
}

class _TiffinBarcodeScannerDialogState extends State<TiffinBarcodeScannerDialog> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isVerifying = false;
  bool _isTorchOn = false;
  String? _errorMessage;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isVerifying) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    final code = rawValue.trim();

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final res = await DriverOrderService.instance.verifyTiffinOtp(
        orderId: widget.orderId,
        otp: code,
      );

      if (res['success'] == true) {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onVerified(widget.hotelName);
        }
      } else {
        if (mounted) {
          setState(() {
            _isVerifying = false;
            _errorMessage = res['message'] ?? 'Invalid barcode scanned for ${widget.hotelName}.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Error verifying QR code: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // 1. Mobile Scanner Camera View
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),

          // 2. Scanner Overlay Box & Grid
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isVerifying
                      ? Colors.orange
                      : (_errorMessage != null ? AppColors.error : AppColors.primary),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withOpacity(0.1),
              ),
              child: Stack(
                children: [
                  if (_isVerifying)
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          SizedBox(height: 12),
                          Text(
                            'Verifying Barcode...',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 3. Header Bar
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      'Scan ${widget.hotelName} Tiffin QR',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _isTorchOn ? Colors.amber : Colors.white,
                    ),
                    onPressed: () async {
                      try {
                        await _scannerController.toggleTorch();
                        setState(() {
                          _isTorchOn = !_isTorchOn;
                        });
                      } catch (_) {}
                    },
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottom Instructions / Error Card
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151522).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Point camera at the QR code on ${widget.hotelName} tiffin box',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
