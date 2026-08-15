import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/sound_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final String title;

  const BarcodeScannerScreen({
    super.key,
    this.title = 'Barkod Tara',
  });

  static Future<String?> scan(BuildContext context, {String title = 'Barkod Tara'}) async {
    return Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(title: title),
      ),
    );
  }

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  final TextEditingController _manualController = TextEditingController();

  bool _isScanned = false;
  bool _scanSuccess = false;
  bool _torchOn = false;
  bool _hasPermission = false;
  bool _checkingPermission = true;
  double _zoomFactor = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 500,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.qrCode,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.itf14,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.aztec,
        BarcodeFormat.pdf417,
      ],
    );

    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _hasPermission = status.isGranted;
        _checkingPermission = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue?.trim();
      if (code != null && code.isNotEmpty) {
        _isScanned = true;
        SoundService.playBarcodeBeep();

        if (mounted) {
          setState(() {
            _scanSuccess = true;
          });
          Navigator.pop(context, code);
        }
        break;
      }
    }
  }

  void _submitManualCode() {
    final code = _manualController.text.trim();
    if (code.isNotEmpty && !_isScanned) {
      _isScanned = true;
      Navigator.pop(context, code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          context.tr('barkod_tara', 'Barkod Tara'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded, color: Colors.white),
            tooltip: context.tr('Kamera Değiştir', 'Kamera Değiştir'),
            onPressed: () => _controller.switchCamera(),
          ),
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _torchOn ? Colors.amber : Colors.white,
            ),
            tooltip: context.tr('Flaş', 'Flaş'),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: _checkingPermission
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
          : !_hasPermission
              ? _buildPermissionDeniedView()
              : Stack(
                  children: [
                    // Camera Preview Scanner
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.videocam_off_rounded, color: Colors.redAccent, size: 64),
                                const SizedBox(height: 12),
                                Text(
                                  context.tr('Kamera Başlatılamadı', 'Kamera Başlatılamadı'),
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Kamera donanım hatası: ${error.errorCode}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                                  onPressed: () => _controller.start(),
                                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                                  label: Text(context.tr('Yeniden Başlat', 'Yeniden Başlat'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Kare Çerçeve ve Ortasında Sabit Kırmızı Çizgi
                    Center(
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _scanSuccess ? Colors.greenAccent : Colors.white70,
                            width: 2.5,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 230,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: _scanSuccess ? Colors.greenAccent : Colors.redAccent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Top Info Hint Banner
                    Positioned(
                      top: 16,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _scanSuccess ? Icons.check_circle_rounded : Icons.qr_code_scanner_rounded,
                              color: _scanSuccess ? Colors.greenAccent : Colors.redAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _scanSuccess
                                    ? 'Barkod başarıyla okundu'
                                    : 'Barkodu kırmızı çizgiye hizalayınız',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Zoom Controls Bar
                    Positioned(
                      right: 16,
                      top: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 22),
                              onPressed: () {
                                setState(() {
                                  _zoomFactor = (_zoomFactor + 0.25).clamp(0.0, 1.0);
                                  _controller.setZoomScale(_zoomFactor);
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.zoom_out_rounded, color: Colors.white, size: 22),
                              onPressed: () {
                                setState(() {
                                  _zoomFactor = (_zoomFactor - 0.25).clamp(0.0, 1.0);
                                  _controller.setZoomScale(_zoomFactor);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Manual Code Input Sheet
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                          border: Border.all(color: AppTheme.darkCardBorder),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _manualController,
                                    style: GoogleFonts.inter(color: Colors.white),
                                    onSubmitted: (_) => _submitManualCode(),
                                    decoration: InputDecoration(
                                      hintText: context.tr('Elle barkod / kod giriniz...', 'Elle barkod / kod giriniz...'),
                                      hintStyle: GoogleFonts.inter(color: AppTheme.darkTextSecondary, fontSize: 13),
                                      prefixIcon: const Icon(Icons.keyboard_outlined, color: AppTheme.accentCyan, size: 20),
                                      filled: true,
                                      fillColor: const Color(0xFF141D38),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: AppTheme.darkCardBorder),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBlue,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: _submitManualCode,
                                  child: Text(context.tr('ekle', 'Ekle'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.redAccent, size: 64),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('Kamera İzni Gereklidir', 'Kamera İzni Gereklidir'),
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('Barkod okutma işlemi gerçekleştirebilmek için uygulamanın kamera erişim iznine ihtiyacı vardır.', 'Barkod okutma işlemi gerçekleştirebilmek için uygulamanın kamera erişim iznine ihtiyacı vardır.'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _checkCameraPermission,
              icon: const Icon(Icons.security_rounded, color: Colors.white),
              label: Text(context.tr('Kamera İznini Aç', 'Kamera İznini Aç'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
