import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../core/storage/save_settings.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../services/document_preview_service.dart';
import '../services/printer_service.dart';
import 'dynamic_island_toast.dart';
import 'printer_detail_modal.dart';

enum PreviewDocumentType {
  belge,
  rapor,
  tahsilat,
  etiket,
}

class BaskiOnizlemeDialog extends StatefulWidget {
  final PreviewDocumentType docType;
  final String title;
  final String? initialPaperFormat;

  // Belge verileri
  final String belgeNo;
  final String belgeTuru;
  final String cariAdi;
  final String tarih;
  final double genelToplam;
  final List<GetBelgeIcerik> urunler;
  final String aciklama;

  // Rapor verileri
  final double toplamSatis;
  final double toplamTahsilat;
  final double toplamNakit;
  final double toplamKrediKarti;
  final int belgeSayisi;
  final List<Map<String, dynamic>> raporIslemler;

  // Tahsilat verileri
  final String makbuzNo;
  final String islemTuru;
  final double tutar;
  final String kasaBankaAdi;

  // Etiket verileri
  final List<GetStok> etiketStoklar;
  final List<int> etiketMiktarlar;

  const BaskiOnizlemeDialog({
    super.key,
    required this.docType,
    this.title = 'Baskı Önizleme',
    this.initialPaperFormat,
    this.belgeNo = '',
    this.belgeTuru = 'Belge',
    this.cariAdi = '',
    this.tarih = '',
    this.genelToplam = 0.0,
    this.urunler = const [],
    this.aciklama = '',
    this.toplamSatis = 0.0,
    this.toplamTahsilat = 0.0,
    this.toplamNakit = 0.0,
    this.toplamKrediKarti = 0.0,
    this.belgeSayisi = 0,
    this.raporIslemler = const [],
    this.makbuzNo = '',
    this.islemTuru = 'Tahsilat',
    this.tutar = 0.0,
    this.kasaBankaAdi = '',
    this.etiketStoklar = const [],
    this.etiketMiktarlar = const [],
  });

  static Future<void> showBelge({
    required BuildContext context,
    required String belgeNo,
    required String belgeTuru,
    required String cariAdi,
    required String tarih,
    required double genelToplam,
    required List<GetBelgeIcerik> urunler,
    String aciklama = '',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BaskiOnizlemeDialog(
        docType: PreviewDocumentType.belge,
        title: '$belgeTuru Önizleme ($belgeNo)',
        belgeNo: belgeNo,
        belgeTuru: belgeTuru,
        cariAdi: cariAdi,
        tarih: tarih,
        genelToplam: genelToplam,
        urunler: urunler,
        aciklama: aciklama,
      ),
    );
  }

  static Future<void> showRapor({
    required BuildContext context,
    required String baslik,
    required String tarihAraligi,
    required double toplamSatis,
    required double toplamTahsilat,
    required double toplamNakit,
    required double toplamKrediKarti,
    required int belgeSayisi,
    required List<Map<String, dynamic>> islemler,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BaskiOnizlemeDialog(
        docType: PreviewDocumentType.rapor,
        title: baslik,
        tarih: tarihAraligi,
        toplamSatis: toplamSatis,
        toplamTahsilat: toplamTahsilat,
        toplamNakit: toplamNakit,
        toplamKrediKarti: toplamKrediKarti,
        belgeSayisi: belgeSayisi,
        raporIslemler: islemler,
      ),
    );
  }

  static Future<void> showTahsilat({
    required BuildContext context,
    required String makbuzNo,
    required String cariAdi,
    required String islemTuru,
    required double tutar,
    required String kasaBankaAdi,
    required String aciklama,
    required String tarih,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BaskiOnizlemeDialog(
        docType: PreviewDocumentType.tahsilat,
        title: 'Tahsilat Makbuzu Önizleme',
        makbuzNo: makbuzNo,
        cariAdi: cariAdi,
        islemTuru: islemTuru,
        tutar: tutar,
        kasaBankaAdi: kasaBankaAdi,
        aciklama: aciklama,
        tarih: tarih,
      ),
    );
  }

  static Future<void> showEtiket({
    required BuildContext context,
    required List<GetStok> stoklar,
    required List<int> miktarlar,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BaskiOnizlemeDialog(
        docType: PreviewDocumentType.etiket,
        title: 'Barkod & Etiket Önizleme',
        etiketStoklar: stoklar,
        etiketMiktarlar: miktarlar,
        initialPaperFormat: '80mm',
      ),
    );
  }

  @override
  State<BaskiOnizlemeDialog> createState() => _BaskiOnizlemeDialogState();
}

class _BaskiOnizlemeDialogState extends State<BaskiOnizlemeDialog> {
  late String _selectedFormat;
  bool _isPrinting = false;
  Uint8List? _generatedPdfBytes;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.initialPaperFormat ?? SaveSettings.yaziciKagizGenislik;
    if (_selectedFormat.isEmpty) _selectedFormat = '80mm';
  }

  Future<Uint8List> _buildPdfDocument(PdfPageFormat format) async {
    Uint8List bytes;
    switch (widget.docType) {
      case PreviewDocumentType.belge:
        bytes = await DocumentPreviewService.generateBelgePdf(
          belgeNo: widget.belgeNo,
          belgeTuru: widget.belgeTuru,
          cariAdi: widget.cariAdi,
          tarih: widget.tarih,
          genelToplam: widget.genelToplam,
          urunler: widget.urunler,
          paperFormat: _selectedFormat,
          aciklama: widget.aciklama,
        );
        break;
      case PreviewDocumentType.rapor:
        bytes = await DocumentPreviewService.generateRaporPdf(
          baslik: widget.title,
          tarihAraligi: widget.tarih,
          toplamSatis: widget.toplamSatis,
          toplamTahsilat: widget.toplamTahsilat,
          toplamNakit: widget.toplamNakit,
          toplamKrediKarti: widget.toplamKrediKarti,
          belgeSayisi: widget.belgeSayisi,
          islemler: widget.raporIslemler,
          paperFormat: _selectedFormat,
        );
        break;
      case PreviewDocumentType.tahsilat:
        bytes = await DocumentPreviewService.generateTahsilatMakbuzPdf(
          makbuzNo: widget.makbuzNo,
          cariAdi: widget.cariAdi,
          islemTuru: widget.islemTuru,
          tutar: widget.tutar,
          kasaBankaAdi: widget.kasaBankaAdi,
          aciklama: widget.aciklama,
          tarih: widget.tarih,
          paperFormat: _selectedFormat,
        );
        break;
      case PreviewDocumentType.etiket:
        bytes = await DocumentPreviewService.generateEtiketPdf(
          stoklar: widget.etiketStoklar,
          miktarlar: widget.etiketMiktarlar,
          paperFormat: _selectedFormat,
        );
        break;
    }

    _generatedPdfBytes = bytes;
    return bytes;
  }

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);

    final docLabel = widget.belgeNo.isNotEmpty ? 'Evrak #${widget.belgeNo}' : widget.title;
    
    // Yazıcı ismi: IP adresi yerine doğrudan yazıcı adı gösterilir
    String printerLabel = SaveSettings.seciliYaziciAdi.isNotEmpty
        ? SaveSettings.seciliYaziciAdi
        : (SaveSettings.seciliYaziciTipi == 'Ağ / IP Yazıcı' ? 'Termal Ağ Yazıcısı' : 'Bluetooth / Sistem Yazıcısı');

    // Eğer yazıcı adında parantez içinde IP varsa (örn: "Ağ Yazıcısı (192.168.1.181)") temizleyip sadece ismi alalım
    if (printerLabel.contains('(') && printerLabel.contains(')')) {
      final cleanName = printerLabel.split('(').first.trim();
      if (cleanName.isNotEmpty) {
        printerLabel = cleanName;
      }
    }

    final island = DynamicIslandNotification.showPrinting(
      context,
      title: 'Yazıcıya Gönderiliyor...',
      docName: docLabel,
      printerInfo: printerLabel,
    );

    try {
      final bool isOfficeOrLaser = printerLabel.toLowerCase().contains('hp') ||
          printerLabel.toLowerCase().contains('smart tank') ||
          printerLabel.toLowerCase().contains('laserjet') ||
          printerLabel.toLowerCase().contains('deskjet') ||
          printerLabel.toLowerCase().contains('officejet') ||
          printerLabel.toLowerCase().contains('ink tank') ||
          printerLabel.toLowerCase().contains('canon') ||
          printerLabel.toLowerCase().contains('brother') ||
          _selectedFormat == 'A4' ||
          _selectedFormat == 'A5' ||
          widget.docType == PreviewDocumentType.tahsilat ||
          widget.docType == PreviewDocumentType.rapor;

      if (SaveSettings.seciliYaziciTipi == 'Ağ / IP Yazıcı' && !isOfficeOrLaser) {
        // POS Termal Ağ Yazıcısı (Epson, Bixolon, Xprinter vb.): Doğrudan TCP Soket ESC/POS
        final ip = SaveSettings.seciliYaziciIp;
        final port = SaveSettings.seciliYaziciPort;

        if (ip.isEmpty) {
          island.updateError(
            title: 'Yazıcı Seçilmedi',
            message: 'Lütfen Ayarlardan geçerli bir IP Yazıcı belirleyiniz.',
          );
          setState(() => _isPrinting = false);
          return;
        }

        List<int> bytes;
        if (widget.docType == PreviewDocumentType.belge) {
          bytes = DocumentPreviewService.generateBelgeEscPos(
            belgeNo: widget.belgeNo,
            belgeTuru: widget.belgeTuru,
            cariAdi: widget.cariAdi,
            tarih: widget.tarih,
            genelToplam: widget.genelToplam,
            urunler: widget.urunler,
            paperWidth: _selectedFormat,
            aciklama: widget.aciklama,
          );
        } else {
          final builder = EscPosBuilder(paperWidth: _selectedFormat);
          builder.init();
          builder.alignCenter();
          builder.bold(true);
          builder.text(SaveSettings.firma.isNotEmpty ? SaveSettings.firma : 'BYM 360 MOBIL');
          builder.text(widget.title);
          builder.bold(false);
          builder.divider();
          builder.feed(2);
          builder.cut();
          bytes = builder.bytes;
        }

        final result = await PrinterService.printToNetworkSocket(
          ip: ip,
          port: port,
          bytes: bytes,
        );

        if (result.success) {
          island.updateSuccess(
            title: 'Baskı Başarılı',
            message: '$docLabel yazıcıya iletildi',
          );
          if (mounted) Navigator.pop(context, true);
        } else {
          // Soket başarısız olursa PDF arayüzü ile yazdırmayı dene
          final pageFormat = _selectedFormat == '58mm'
              ? PdfPageFormat.roll57
              : (_selectedFormat == '80mm'
                  ? PdfPageFormat.roll80
                  : (_selectedFormat == 'A5' ? PdfPageFormat.a5 : PdfPageFormat.a4));

          _generatedPdfBytes ??= await _buildPdfDocument(pageFormat);

          final pdfRes = await PrinterService.printPdfToPrinter(
            pdfBytes: _generatedPdfBytes!,
            printerName: SaveSettings.seciliYaziciAdi,
            printerUrl: SaveSettings.seciliYaziciUrl,
            docName: widget.title,
            useLayoutDialogIfNoPrinter: true,
          );

          if (pdfRes.success) {
            island.updateSuccess(
              title: 'Baskı Başarılı',
              message: '$docLabel yazıcıya gönderildi',
            );
            if (mounted) Navigator.pop(context, true);
          } else {
            island.updateError(
              title: 'Yazdırma Hatası',
              message: result.message,
            );
          }
        }
      } else {
        // HP Smart Tank, LaserJet, Canon, Brother veya Bluetooth/Sistem Yazıcısı: PDF Formatında Gönder
        final pageFormat = _selectedFormat == '58mm'
            ? PdfPageFormat.roll57
            : (_selectedFormat == '80mm'
                ? PdfPageFormat.roll80
                : (_selectedFormat == 'A5' ? PdfPageFormat.a5 : PdfPageFormat.a4));

        _generatedPdfBytes ??= await _buildPdfDocument(pageFormat);

        final result = await PrinterService.printPdfToPrinter(
          pdfBytes: _generatedPdfBytes!,
          printerName: SaveSettings.seciliYaziciAdi,
          printerUrl: SaveSettings.seciliYaziciUrl,
          docName: widget.title,
          useLayoutDialogIfNoPrinter: true,
        );

        if (result.success) {
          island.updateSuccess(
            title: 'Baskı Başarılı',
            message: '$docLabel yazıcıya gönderildi',
          );
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          island.updateError(
            title: 'Yazdırma Hatası',
            message: result.message,
          );
        }
      }
    } catch (e) {
      island.updateError(
        title: 'Baskı Gönderilemedi',
        message: '$e',
      );
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  void _openPrinterSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const RealPrinterPickerDialog(),
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      child: Container(
        width: size.width > 650 ? 650 : double.infinity,
        height: size.height * 0.88,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Üst Başlık & Kapat
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.print_rounded, color: AppTheme.primaryBlue, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Baskı Önizleme ve Gerçek Yazıcı Çıktısı',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Kağıt Formatı Seçim Sekmeleri (80mm, 58mm, A4, A5)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _formatChip('80mm', '80mm Termal POS', Icons.receipt_long_rounded),
                  const SizedBox(width: 8),
                  _formatChip('58mm', '58mm Termal Fiş', Icons.receipt_rounded),
                  const SizedBox(width: 8),
                  _formatChip('A4', 'A4 Evrak/Fatura', Icons.article_rounded),
                  const SizedBox(width: 8),
                  _formatChip('A5', 'A5 İrsaliye/Makbuz', Icons.description_rounded),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Seçili Yazıcı Durum Çubuğu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    SaveSettings.seciliYaziciTipi == 'Ağ / IP Yazıcı' ? Icons.wifi_rounded : Icons.bluetooth_rounded,
                    size: 18,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          SaveSettings.seciliYaziciAdi.isNotEmpty && !SaveSettings.seciliYaziciAdi.contains('Seçilmedi')
                              ? SaveSettings.seciliYaziciAdi
                              : (SaveSettings.seciliYaziciTipi == 'Ağ / IP Yazıcı' ? 'Termal Ağ Yazıcısı' : 'Bluetooth Yazıcı'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Yazıcı tipi: ${SaveSettings.seciliYaziciTipi}',
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Değiştir', style: TextStyle(fontSize: 12)),
                    onPressed: _openPrinterSelector,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Canlı PDF Önizleme Alanı
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: Colors.grey.shade200,
                  child: PdfPreview(
                    build: _buildPdfDocument,
                    allowPrinting: false,
                    allowSharing: true,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                    loadingWidget: const Center(
                      child: CircularProgressIndicator(),
                    ),
                    previewPageMargin: const EdgeInsets.all(8),
                    pdfFileName: '${widget.title.replaceAll(' ', '_')}.pdf',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Alt Aksiyon Butonları
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Vazgeç'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.print_rounded, size: 20),
                    label: Text(
                      _isPrinting ? 'YAZDIRILIYOR...' : 'YAZDIR',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: _isPrinting ? null : _handlePrint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _formatChip(String formatKey, String label, IconData icon) {
    final isSelected = _selectedFormat == formatKey;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.primaryBlue),
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppTheme.primaryBlue,
      labelStyle: TextStyle(color: isSelected ? Colors.white : null),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFormat = formatKey;
            SaveSettings.yaziciKagizGenislik = formatKey;
          });
        }
      },
    );
  }
}

/// Gerçek Bluetooth ve WiFi Yazıcı Seçim & Tarama Penceresi
class RealPrinterPickerDialog extends StatefulWidget {
  const RealPrinterPickerDialog({super.key});

  @override
  State<RealPrinterPickerDialog> createState() => _RealPrinterPickerDialogState();
}

class _RealPrinterPickerDialogState extends State<RealPrinterPickerDialog> {
  String _selectedTab = 'wifi'; // 'wifi' | 'bluetooth'
  bool _isScanning = false;
  List<DiscoveredPrinter> _discoveredList = [];

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    if (!mounted) return;
    setState(() => _isScanning = true);

    if (_selectedTab == 'bluetooth') {
      final list = await PrinterService.getSystemAndBluetoothPrinters();
      if (mounted) {
        setState(() {
          _discoveredList = list;
          _isScanning = false;
        });
      }
    } else {
      // WiFi / Ağ yazıcılarını algoritmik ve yüksek hızla otomatik tara
      final list = await PrinterService.autoDiscoverNetworkPrinters();
      if (mounted) {
        setState(() {
          _discoveredList = list;
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _saveAndSelectNetworkPrinter(DiscoveredPrinter item) async {
    final name = item.name.isNotEmpty ? item.name : 'Termal Ağ Yazıcısı';
    await SaveSettings.savePrinterSettings(
      tip: 'Ağ / IP Yazıcı',
      ad: name,
      ip: item.ip ?? '',
      port: item.port,
      kagiz: SaveSettings.yaziciKagizGenislik,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ağ Yazıcısı seçildi: $name'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _saveAndSelectBtPrinter(DiscoveredPrinter p) async {
    await SaveSettings.savePrinterSettings(
      tip: 'Bluetooth / Sistem Yazıcısı',
      ad: p.name,
      ip: SaveSettings.seciliYaziciIp,
      port: SaveSettings.seciliYaziciPort,
      url: p.url ?? '',
      kagiz: SaveSettings.yaziciKagizGenislik,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yazıcı seçildi: ${p.name}'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.print_rounded, color: AppTheme.primaryBlue, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Yazıcı Bağlantısı',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Tab Seçici
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  avatar: const Icon(Icons.wifi_rounded, size: 16),
                  label: const Text('WiFi / IP Yazıcı'),
                  selected: _selectedTab == 'wifi',
                  selectedColor: AppTheme.primaryBlue,
                  labelStyle: TextStyle(color: _selectedTab == 'wifi' ? Colors.white : null),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedTab = 'wifi');
                      _loadPrinters();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  avatar: const Icon(Icons.bluetooth_rounded, size: 16),
                  label: const Text('Bluetooth / Sistem'),
                  selected: _selectedTab == 'bluetooth',
                  selectedColor: AppTheme.primaryBlue,
                  labelStyle: TextStyle(color: _selectedTab == 'bluetooth' ? Colors.white : null),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedTab = 'bluetooth');
                      _loadPrinters();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Durum ve Yeniden Tara Başlığı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _selectedTab == 'wifi'
                      ? 'Ağdaki Yazıcılar (${_discoveredList.length})'
                      : 'Bluetooth / Sistem (${_discoveredList.length})',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _isScanning ? null : _loadPrinters,
                icon: _isScanning
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: Text(_isScanning ? 'Taranıyor...' : 'Yazıcıları Tara'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Bulunan Cihazlar Listesi
          SizedBox(
            height: 220,
            child: _isScanning
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          _selectedTab == 'wifi'
                              ? 'Ağdaki yazıcılar taranıyor...'
                              : 'Bluetooth cihazlar taranıyor...',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _discoveredList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedTab == 'wifi' ? Icons.wifi_off_rounded : Icons.bluetooth_disabled_rounded,
                                color: Colors.grey.shade400,
                                size: 36,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedTab == 'wifi'
                                    ? 'Ağda yazıcı bulunamadı.'
                                    : 'Eşleşmiş cihaz bulunamadı.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _discoveredList.length,
                        itemBuilder: (context, index) {
                          final item = _discoveredList[index];
                          final isCurrent = (_selectedTab == 'wifi' && item.ip == SaveSettings.seciliYaziciIp) ||
                              (_selectedTab == 'bluetooth' && item.name == SaveSettings.seciliYaziciAdi);

                          return Card(
                            elevation: 0,
                            color: isCurrent
                                ? AppTheme.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.08)
                                : (isDark ? Colors.white10 : Colors.grey.shade100),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isCurrent ? AppTheme.primaryBlue : (isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                                width: isCurrent ? 1.5 : 1,
                              ),
                            ),
                            child: ListTile(
                              onLongPress: () {
                                PrinterDetailModal.show(
                                  context,
                                  printer: item,
                                  onPrinterSelected: () => setState(() {}),
                                );
                              },
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppTheme.primaryBlue.withValues(alpha: 0.15)
                                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item.type == PrinterConnectionType.network ? Icons.wifi_rounded : Icons.bluetooth_rounded,
                                  color: AppTheme.primaryBlue,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                item.name,
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              subtitle: Text(
                                item.type == PrinterConnectionType.network
                                    ? 'IP: ${item.ip}  •  Port: ${item.port} (Hazır)'
                                    : (item.detailLabel.isNotEmpty ? item.detailLabel : 'Basılı tutun • Detayları gör'),
                                style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.info_outline_rounded, size: 20),
                                    color: Colors.grey.shade500,
                                    tooltip: 'Cihaz Detayları',
                                    onPressed: () {
                                      PrinterDetailModal.show(
                                        context,
                                        printer: item,
                                        onPrinterSelected: () => setState(() {}),
                                      );
                                    },
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isCurrent ? AppTheme.accentGreen : AppTheme.primaryBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    child: Text(isCurrent ? 'Seçili' : 'Seç'),
                                    onPressed: () {
                                      if (item.type == PrinterConnectionType.network) {
                                        _saveAndSelectNetworkPrinter(item);
                                      } else {
                                        _saveAndSelectBtPrinter(item);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
