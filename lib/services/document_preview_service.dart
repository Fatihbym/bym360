import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/storage/save_settings.dart';
import '../models/models.dart';
import 'printer_service.dart';

class DocumentPreviewService {
  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;

  /// PDF motorunda Unicode / Latin-1 font kilitlenmesini ve decode hatalarını önlemek için güvenli metin dönüştürücü
  static String safe(String input) {
    if (input.isEmpty) return '';
    return input
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'G')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'I')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 'S')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'O')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'C')
        .replaceAll('₺', 'TL');
  }

  /// Türkçe karakterleri tam destekleyen Unicode Fontu yükler
  static Future<pw.Font> getRegularFont() async {
    if (_cachedRegularFont != null) return _cachedRegularFont!;
    try {
      _cachedRegularFont = await PdfGoogleFonts.robotoRegular();
    } catch (_) {
      try {
        final fontData = await rootBundle.load('assets/fonts/Exo2-Regular.otf');
        _cachedRegularFont = pw.Font.ttf(fontData);
      } catch (_) {
        _cachedRegularFont = pw.Font.helvetica();
      }
    }
    return _cachedRegularFont!;
  }

  /// Türkçe karakterleri tam destekleyen Kalın Unicode Fontu yükler
  static Future<pw.Font> getBoldFont() async {
    if (_cachedBoldFont != null) return _cachedBoldFont!;
    try {
      _cachedBoldFont = await PdfGoogleFonts.robotoBold();
    } catch (_) {
      try {
        final fontData = await rootBundle.load('assets/fonts/Exo2-Bold.otf');
        _cachedBoldFont = pw.Font.ttf(fontData);
      } catch (_) {
        _cachedBoldFont = pw.Font.helveticaBold();
      }
    }
    return _cachedBoldFont!;
  }

  /// Belge (Fatura, İrsaliye, Sipariş vb.) için PDF oluşturur
  static Future<Uint8List> generateBelgePdf({
    required String belgeNo,
    required String belgeTuru,
    required String cariAdi,
    required String tarih,
    required double genelToplam,
    required List<GetBelgeIcerik> urunler,
    String paperFormat = '80mm', // '80mm', '58mm', 'A4', 'A5'
    String aciklama = '',
  }) async {
    final fontRegular = await getRegularFont();
    final fontBold = await getBoldFont();
    final docTheme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);
    final pdf = pw.Document(theme: docTheme);
    final pageFormat = _getPageFormat(paperFormat);
    final isRoll = paperFormat == '80mm' || paperFormat == '58mm';
    final currencyFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: 'TL');

    double araToplam = 0.0;
    double toplamMiktar = 0.0;
    for (final u in urunler) {
      final lineTutar = u.tutar > 0 ? u.tutar : (u.birimFiyat * u.miktar);
      araToplam += lineTutar;
      toplamMiktar += u.miktar;
    }
    final netGenelToplam = genelToplam > 0 ? genelToplam : araToplam;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: isRoll
            ? const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12)
            : const pw.EdgeInsets.all(24),
        build: (context) {
          if (isRoll) {
            return _buildThermalRollLayout(
              belgeNo: belgeNo,
              belgeTuru: belgeTuru,
              cariAdi: cariAdi,
              tarih: tarih,
              genelToplam: netGenelToplam,
              araToplam: araToplam,
              toplamMiktar: toplamMiktar,
              urunler: urunler,
              paperFormat: paperFormat,
              aciklama: aciklama,
              currencyFormatter: currencyFormatter,
              fontRegular: fontRegular,
              fontBold: fontBold,
            );
          } else {
            return _buildStandardPageLayout(
              belgeNo: belgeNo,
              belgeTuru: belgeTuru,
              cariAdi: cariAdi,
              tarih: tarih,
              genelToplam: netGenelToplam,
              araToplam: araToplam,
              toplamMiktar: toplamMiktar,
              urunler: urunler,
              paperFormat: paperFormat,
              aciklama: aciklama,
              currencyFormatter: currencyFormatter,
              fontRegular: fontRegular,
              fontBold: fontBold,
            );
          }
        },
      ),
    );

    return pdf.save();
  }

  /// Belge için doğrudan ESC/POS Termal Fiş Komutları Üretir
  static List<int> generateBelgeEscPos({
    required String belgeNo,
    required String belgeTuru,
    required String cariAdi,
    required String tarih,
    required double genelToplam,
    required List<GetBelgeIcerik> urunler,
    String paperWidth = '80mm',
    String aciklama = '',
  }) {
    final builder = EscPosBuilder(paperWidth: paperWidth);
    builder.init();

    // Başlık
    builder.alignCenter();
    builder.bold(true);
    builder.doubleHeight(true);
    builder.text(SaveSettings.firma.isNotEmpty ? SaveSettings.firma : 'BYM 360 MOBIL');
    builder.doubleHeight(false);
    builder.text('** $belgeTuru **');
    builder.bold(false);
    builder.doubleDivider();

    // Bilgiler
    builder.alignLeft();
    builder.row2Column('Belge No:', belgeNo.isNotEmpty ? belgeNo : '-');
    builder.row2Column('Tarih:', tarih.isNotEmpty ? tarih : DateTime.now().toString().substring(0, 16));
    if (cariAdi.isNotEmpty) {
      builder.row2Column('Cari:', cariAdi);
    }
    if (SaveSettings.kullaniciAdi.isNotEmpty) {
      builder.row2Column('Personel:', SaveSettings.kullaniciAdi);
    }
    builder.divider();

    double toplamMik = 0.0;
    double calculatedTotal = 0.0;

    // Kalemler Tablosu
    if (paperWidth == '58mm') {
      builder.row3Column('URUN', 'MIK', 'TUTAR');
      builder.divider();
      for (final item in urunler) {
        final lineTotal = item.tutar > 0 ? item.tutar : (item.birimFiyat * item.miktar);
        toplamMik += item.miktar;
        calculatedTotal += lineTotal;
        builder.row3Column(
          item.stokAdi,
          '${item.miktar.toStringAsFixed(0)} ${item.birim}',
          '${lineTotal.toStringAsFixed(2)} TL',
        );
      }
    } else {
      builder.row4Column('URUN ADI', 'MIKTAR', 'FIYAT', 'TUTAR');
      builder.divider();
      for (final item in urunler) {
        final lineTotal = item.tutar > 0 ? item.tutar : (item.birimFiyat * item.miktar);
        toplamMik += item.miktar;
        calculatedTotal += lineTotal;
        builder.row4Column(
          item.stokAdi,
          '${item.miktar.toStringAsFixed(0)} ${item.birim}',
          item.birimFiyat.toStringAsFixed(2),
          '${lineTotal.toStringAsFixed(2)} TL',
        );
      }
    }

    final netGenelToplam = genelToplam > 0 ? genelToplam : calculatedTotal;

    builder.divider();

    // Dip Toplamlar
    builder.row2Column('Toplam Kalem / Mik:', '${urunler.length} / ${toplamMik.toStringAsFixed(0)}');
    builder.bold(true);
    builder.doubleHeight(true);
    builder.row2Column('GENEL TOPLAM:', '${netGenelToplam.toStringAsFixed(2)} TL');
    builder.doubleHeight(false);
    builder.bold(false);
    builder.doubleDivider();

    if (aciklama.isNotEmpty) {
      builder.alignLeft();
      builder.text('Not: $aciklama');
      builder.divider();
    }

    // Alt Not
    builder.alignCenter();
    builder.text('Bizi tercih ettiginiz icin tesekkur ederiz.');
    builder.text('BYM 360 Mobil Sistemleri');
    builder.feed(3);
    builder.cut();

    return builder.bytes;
  }

  /// Gün Sonu & Kullanıcı Raporu için PDF oluşturur
  static Future<Uint8List> generateRaporPdf({
    required String baslik,
    required String tarihAraligi,
    required double toplamSatis,
    required double toplamTahsilat,
    required double toplamNakit,
    required double toplamKrediKarti,
    required int belgeSayisi,
    required List<Map<String, dynamic>> islemler,
    String paperFormat = '80mm',
  }) async {
    final fontRegular = await getRegularFont();
    final fontBold = await getBoldFont();
    final docTheme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);
    final pdf = pw.Document(theme: docTheme);
    final pageFormat = _getPageFormat(paperFormat);
    final isRoll = paperFormat == '80mm' || paperFormat == '58mm';

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: isRoll
            ? const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12)
            : const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  safe(SaveSettings.firma.isNotEmpty ? SaveSettings.firma : 'BYM 360 ERP'),
                  style: pw.TextStyle(font: fontBold, fontSize: isRoll ? 14 : 18),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  safe(baslik),
                  style: pw.TextStyle(font: fontBold, fontSize: isRoll ? 12 : 15, color: PdfColors.blue900),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  safe('Tarih: $tarihAraligi'),
                  style: pw.TextStyle(font: fontRegular, fontSize: isRoll ? 8 : 10, color: PdfColors.grey700),
                ),
              ),
              pw.Divider(thickness: 1),

              // Özet Kutusu
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  children: [
                    _pdfRow2Col('Kullanici / Kasiyer:', SaveSettings.kullaniciAdi.isNotEmpty ? SaveSettings.kullaniciAdi : 'Admin', fontBold, fontRegular, isRoll),
                    _pdfRow2Col('Toplam Belge Adedi:', belgeSayisi.toString(), fontBold, fontRegular, isRoll),
                    pw.Divider(height: 6, thickness: 0.5),
                    _pdfRow2Col('Toplam Satis Tutari:', '${toplamSatis.toStringAsFixed(2)} TL', fontBold, fontBold, isRoll, color: PdfColors.blue800),
                    _pdfRow2Col('Toplam Tahsilat:', '${toplamTahsilat.toStringAsFixed(2)} TL', fontBold, fontBold, isRoll, color: PdfColors.green800),
                    _pdfRow2Col(' - Nakit Giris:', '${toplamNakit.toStringAsFixed(2)} TL', fontRegular, fontRegular, isRoll),
                    _pdfRow2Col(' - Kredi Karti POS:', '${toplamKrediKarti.toStringAsFixed(2)} TL', fontRegular, fontRegular, isRoll),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),
              pw.Text('Islem Dokumu', style: pw.TextStyle(font: fontBold, fontSize: isRoll ? 10 : 12)),
              pw.Divider(height: 4, thickness: 0.5),

              if (islemler.isEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Text('Listelenecek islem kaydi bulunamadi.', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                )
              else
                pw.ListView.builder(
                  itemCount: islemler.length,
                  itemBuilder: (context, index) {
                    final item = islemler[index];
                    final turStr = item['tur'] ?? 'Belge';
                    final cariStr = item['cari'] ?? '-';
                    final tutarVal = (item['tutar'] is num) ? (item['tutar'] as num).toDouble() : 0.0;
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              safe('$turStr - $cariStr'),
                              style: pw.TextStyle(font: fontRegular, fontSize: isRoll ? 8 : 10),
                              maxLines: 1,
                            ),
                          ),
                          pw.Text(
                            safe('${tutarVal.toStringAsFixed(2)} TL'),
                            style: pw.TextStyle(font: fontBold, fontSize: isRoll ? 8 : 10),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              pw.Divider(thickness: 1),
              pw.Center(
                child: pw.Text(
                  'Rapor Basim: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(font: fontRegular, fontSize: isRoll ? 7 : 9, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Kasa Tahsilat & Tediye Makbuzu için PDF oluşturur
  static Future<Uint8List> generateTahsilatMakbuzPdf({
    required String makbuzNo,
    required String cariAdi,
    required String islemTuru, // 'Nakit Tahsilat', 'Kredi Kartı', 'Nakit Tediye'
    required double tutar,
    required String kasaBankaAdi,
    required String aciklama,
    required String tarih,
    String paperFormat = '80mm',
  }) async {
    final fontRegular = await getRegularFont();
    final fontBold = await getBoldFont();
    final docTheme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);
    final pdf = pw.Document(theme: docTheme);
    final pageFormat = _getPageFormat(paperFormat);
    final isRoll = paperFormat == '80mm' || paperFormat == '58mm';

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: isRoll
            ? const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12)
            : const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  safe(SaveSettings.firma.isNotEmpty ? SaveSettings.firma : 'BYM 360 MOBIL'),
                  style: pw.TextStyle(font: fontBold, fontSize: isRoll ? 14 : 18),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'TAHSILAT / TEDIYE MAKBUZU',
                  style: pw.TextStyle(font: fontBold, fontSize: isRoll ? 11 : 14, color: PdfColors.blue900),
                ),
              ),
              pw.Divider(thickness: 1),

              _pdfRow2Col('Makbuz No:', makbuzNo.isNotEmpty ? makbuzNo : '#${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}', fontBold, fontRegular, isRoll),
              _pdfRow2Col('Tarih / Saat:', tarih.isNotEmpty ? tarih : DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()), fontBold, fontRegular, isRoll),
              _pdfRow2Col('Islem Turu:', islemTuru, fontBold, fontRegular, isRoll),
              _pdfRow2Col('Cari Unvani:', cariAdi.isNotEmpty ? cariAdi : 'Genel Cari', fontBold, fontBold, isRoll),
              _pdfRow2Col('Kasa / Hesap:', kasaBankaAdi.isNotEmpty ? kasaBankaAdi : 'Merkez Kasa', fontBold, fontRegular, isRoll),
              if (aciklama.isNotEmpty)
                _pdfRow2Col('Aciklama:', aciklama, fontBold, fontRegular, isRoll),

              pw.Divider(height: 12, thickness: 1),

              // Büyük Tutar Kutusu
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('TAHSIL EDILEN TUTAR', style: pw.TextStyle(font: fontRegular, fontSize: isRoll ? 8 : 10)),
                      pw.Text(
                        safe('${tutar.toStringAsFixed(2)} TL'),
                        style: pw.TextStyle(font: fontBold, fontSize: isRoll ? 16 : 22, color: PdfColors.green900),
                      ),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 14),

              // İmza Alanı
              if (!isRoll)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('Teslim Eden', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                        pw.SizedBox(height: 30),
                        pw.Text('Imza: ........................', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Teslim Alan (Kasiyer)', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                        pw.SizedBox(height: 30),
                        pw.Text('Imza: ........................', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                      ],
                    ),
                  ],
                ),

              pw.Divider(thickness: 0.5),
              pw.Center(
                child: pw.Text(
                  'Bu makbuz BYM 360 Mobil ERP ile duzenlenmistir.',
                  style: pw.TextStyle(font: fontRegular, fontSize: isRoll ? 7 : 8, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Ürün Barkod ve Raf Etiketi için PDF oluşturur
  static Future<Uint8List> generateEtiketPdf({
    required List<GetStok> stoklar,
    required List<int> miktarlar,
    String paperFormat = '80mm',
  }) async {
    final fontRegular = await getRegularFont();
    final fontBold = await getBoldFont();
    final docTheme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);
    final pdf = pw.Document(theme: docTheme);

    for (int i = 0; i < stoklar.length; i++) {
      final stok = stoklar[i];
      final miktar = (i < miktarlar.length) ? miktarlar[i] : 1;

      for (int m = 0; m < miktar; m++) {
        pdf.addPage(
          pw.Page(
            pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, 50 * PdfPageFormat.mm, marginAll: 4 * PdfPageFormat.mm),
            build: (context) {
              return pw.Container(
                decoration: pw.BoxDecoration(
                  // Premium light dotted border serving as a cutting/alignment guideline, rather than a heavy black box
                  border: pw.Border.all(
                    color: PdfColors.grey400,
                    width: 0.5,
                    style: pw.BorderStyle.dashed,
                  ),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // Header: Company Name & Date
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          safe(SaveSettings.firma.isNotEmpty ? SaveSettings.firma : 'BYM 360'),
                          style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          DateFormat('dd.MM.yyyy').format(DateTime.now()),
                          style: pw.TextStyle(font: fontRegular, fontSize: 7, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),

                    // Product Title
                    pw.Text(
                      safe(stok.stokAdi),
                      style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.black),
                      maxLines: 2,
                      overflow: pw.TextOverflow.clip,
                    ),

                    // Subtle separation line
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Divider(thickness: 0.5, color: PdfColors.grey400, borderStyle: pw.BorderStyle.dashed),
                    ),

                    // Barcode & Price Section
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        // Left: Barcode and Product Info
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (stok.barkod.isNotEmpty)
                              pw.BarcodeWidget(
                                barcode: pw.Barcode.code128(),
                                data: stok.barkod,
                                width: 110,
                                height: 28,
                                drawText: true,
                                textStyle: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: PdfColors.black),
                              )
                            else
                              pw.Text(
                                safe('Barkod Yok'),
                                style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600),
                              ),
                            pw.SizedBox(height: 4),
                            pw.Row(
                              children: [
                                pw.Text(
                                  safe('KOD: ${stok.stokKodu}'),
                                  style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfColors.grey800),
                                ),
                                pw.SizedBox(width: 6),
                                pw.Text(
                                  safe('BİRİM: ${stok.birim}'),
                                  style: pw.TextStyle(font: fontRegular, fontSize: 7, color: PdfColors.grey700),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Right: Price Box
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Text(
                              'KDV DAHİL FİYAT',
                              style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: PdfColors.grey700),
                            ),
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Text(
                                  safe('₺${stok.satisFiyati.toStringAsFixed(2)}'),
                                  style: pw.TextStyle(font: fontBold, fontSize: 17, color: PdfColors.black),
                                ),
                              ],
                            ),
                            pw.Text(
                              safe('1 ${stok.birim}'),
                              style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: PdfColors.grey600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }
    }

    return pdf.save();
  }

  // --- Yardımcı Render Metotları ---

  static pw.Widget _buildThermalRollLayout({
    required String belgeNo,
    required String belgeTuru,
    required String cariAdi,
    required String tarih,
    required double genelToplam,
    required double araToplam,
    required double toplamMiktar,
    required List<GetBelgeIcerik> urunler,
    required String paperFormat,
    required String aciklama,
    required NumberFormat currencyFormatter,
    required pw.Font fontRegular,
    required pw.Font fontBold,
  }) {
    final is58 = paperFormat == '58mm';
    final fontSizeSmall = is58 ? 7.0 : 8.5;
    final fontSizeNormal = is58 ? 8.0 : 9.5;
    final fontSizeTitle = is58 ? 11.0 : 13.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text(
            safe(SaveSettings.firma.isNotEmpty ? SaveSettings.firma : 'BYM 360 MOBIL'),
            style: pw.TextStyle(font: fontBold, fontSize: fontSizeTitle),
          ),
        ),
        pw.Center(
          child: pw.Text(
            safe(belgeTuru),
            style: pw.TextStyle(font: fontBold, fontSize: fontSizeNormal, color: PdfColors.blue900),
          ),
        ),
        pw.Divider(thickness: 1),

        _pdfRow2Col('Belge No:', belgeNo.isNotEmpty ? belgeNo : '-', fontBold, fontRegular, true, is58: is58),
        _pdfRow2Col('Tarih:', tarih.isNotEmpty ? tarih : DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()), fontBold, fontRegular, true, is58: is58),
        if (cariAdi.isNotEmpty)
          _pdfRow2Col('Cari:', cariAdi, fontBold, fontRegular, true, is58: is58),
        _pdfRow2Col('Personel:', SaveSettings.kullaniciAdi.isNotEmpty ? SaveSettings.kullaniciAdi : 'Kullanici', fontBold, fontRegular, true, is58: is58),

        pw.Divider(thickness: 0.5),

        // Başlık Satırı
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(flex: 3, child: pw.Text('Urun Adi', style: pw.TextStyle(font: fontBold, fontSize: fontSizeSmall))),
            pw.Expanded(flex: 1, child: pw.Text('Mik', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: fontSizeSmall))),
            pw.Expanded(flex: 2, child: pw.Text('Tutar', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: fontSizeSmall))),
          ],
        ),
        pw.Divider(thickness: 0.5),

        // Ürün Satırları
        ...urunler.map((item) {
          final lineTotal = item.tutar > 0 ? item.tutar : (item.birimFiyat * item.miktar);
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(safe(item.stokAdi), style: pw.TextStyle(font: fontRegular, fontSize: fontSizeSmall), maxLines: 2),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(item.miktar.toStringAsFixed(0), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontRegular, fontSize: fontSizeSmall)),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(safe('${lineTotal.toStringAsFixed(2)} TL'), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: fontSizeSmall)),
                ),
              ],
            ),
          );
        }),

        pw.Divider(thickness: 1),

        _pdfRow2Col('Toplam Kalem / Miktar:', '${urunler.length} / ${toplamMiktar.toStringAsFixed(0)}', fontRegular, fontRegular, true, is58: is58),
        _pdfRow2Col('Ara Toplam:', '${araToplam.toStringAsFixed(2)} TL', fontRegular, fontRegular, true, is58: is58),

        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('GENEL TOPLAM:', style: pw.TextStyle(font: fontBold, fontSize: fontSizeNormal + 2)),
              pw.Text(safe('${(genelToplam > 0 ? genelToplam : araToplam).toStringAsFixed(2)} TL'), style: pw.TextStyle(font: fontBold, fontSize: fontSizeNormal + 2, color: PdfColors.black)),
            ],
          ),
        ),

        if (aciklama.isNotEmpty) ...[
          pw.Divider(thickness: 0.5),
          pw.Text(safe('Not: $aciklama'), style: pw.TextStyle(font: fontRegular, fontSize: fontSizeSmall)),
        ],

        pw.Divider(thickness: 1),
        pw.Center(
          child: pw.Text('Tesekkur Eder, Iyi Gunler Dileriz.', style: pw.TextStyle(font: fontRegular, fontSize: fontSizeSmall, color: PdfColors.grey700)),
        ),
      ],
    );
  }

  static pw.Widget _buildStandardPageLayout({
    required String belgeNo,
    required String belgeTuru,
    required String cariAdi,
    required String tarih,
    required double genelToplam,
    required double araToplam,
    required double toplamMiktar,
    required List<GetBelgeIcerik> urunler,
    required String paperFormat,
    required String aciklama,
    required NumberFormat currencyFormatter,
    required pw.Font fontRegular,
    required pw.Font fontBold,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Antet & Belge Başlığı
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  safe(SaveSettings.firma.isNotEmpty ? SaveSettings.firma : 'BYM 360'),
                  style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue900),
                ),
                pw.SizedBox(height: 2),
                pw.Text('Depo & Satis Yonetim Sistemi', style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey700)),
                pw.Text(safe('Sube: ${SaveSettings.subeAdi.isNotEmpty ? SaveSettings.subeAdi : "Merkez Sube"}'), style: pw.TextStyle(font: fontRegular, fontSize: 9)),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue900, width: 1.5),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(safe(belgeTuru.toUpperCase()), style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blue900)),
                  pw.Text(safe('No: ${belgeNo.isNotEmpty ? belgeNo : "-"}'), style: pw.TextStyle(font: fontBold, fontSize: 11)),
                  pw.Text(safe('Tarih: $tarih'), style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 12),

        // Cari Bilgi Kartı
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('SAYIN / MUSTERI BILGILERI:', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey700)),
                  pw.SizedBox(height: 2),
                  pw.Text(safe(cariAdi.isNotEmpty ? cariAdi : 'Muhtelif Musteri'), style: pw.TextStyle(font: fontBold, fontSize: 12)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(safe('Duzenleyen Personel: ${SaveSettings.kullaniciAdi.isNotEmpty ? SaveSettings.kullaniciAdi : "Admin"}'), style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                  pw.Text(safe('Depo: ${SaveSettings.depoAdi.isNotEmpty ? SaveSettings.depoAdi : "Ana Depo"}'), style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 12),

        // Kalemler Tablosu
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(0.6), // Sıra
            1: pw.FlexColumnWidth(3.0), // Ürün Adı
            2: pw.FlexColumnWidth(1.2), // Miktar
            3: pw.FlexColumnWidth(1.2), // Birim Fiyat
            4: pw.FlexColumnWidth(1.4), // Tutar
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue800),
              children: [
                _tableHeader('Sira', fontBold),
                _tableHeader('Stok / Urun Aciklamasi', fontBold),
                _tableHeader('Miktar', fontBold, align: pw.TextAlign.right),
                _tableHeader('Birim Fiyat', fontBold, align: pw.TextAlign.right),
                _tableHeader('Toplam Tutar', fontBold, align: pw.TextAlign.right),
              ],
            ),
            ...urunler.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;
              final lineTotal = item.tutar > 0 ? item.tutar : (item.birimFiyat * item.miktar);
              final isEven = entry.key % 2 == 0;
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : PdfColors.grey50),
                children: [
                  _tableCell(idx.toString(), fontRegular, align: pw.TextAlign.center),
                  _tableCell(safe(item.stokAdi), fontRegular),
                  _tableCell('${item.miktar.toStringAsFixed(0)} ${safe(item.birim)}', fontRegular, align: pw.TextAlign.right),
                  _tableCell('${item.birimFiyat.toStringAsFixed(2)} TL', fontRegular, align: pw.TextAlign.right),
                  _tableCell('${lineTotal.toStringAsFixed(2)} TL', fontBold, align: pw.TextAlign.right),
                ],
              );
            }),
          ],
        ),

        pw.SizedBox(height: 12),

        // Dip Toplamlar & İmzalar
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (aciklama.isNotEmpty) ...[
                    pw.Text('Aciklama / Notlar:', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                    pw.Text(safe(aciklama), style: pw.TextStyle(font: fontRegular, fontSize: 8.5)),
                    pw.SizedBox(height: 12),
                  ],
                  pw.Row(
                    children: [
                      pw.Column(
                        children: [
                          pw.Text('Teslim Eden', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                          pw.SizedBox(height: 24),
                          pw.Text('Imza: ...................', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                        ],
                      ),
                      pw.SizedBox(width: 40),
                      pw.Column(
                        children: [
                          pw.Text('Teslim Alan', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                          pw.SizedBox(height: 24),
                          pw.Text('Imza: ...................', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  children: [
                    _pdfRow2Col('Toplam Kalem:', urunler.length.toString(), fontRegular, fontBold, false),
                    _pdfRow2Col('Toplam Miktar:', toplamMiktar.toStringAsFixed(0), fontRegular, fontBold, false),
                    _pdfRow2Col('Ara Toplam:', '${araToplam.toStringAsFixed(2)} TL', fontRegular, fontBold, false),
                    pw.Divider(thickness: 1),
                    _pdfRow2Col('GENEL TOPLAM:', '${(genelToplam > 0 ? genelToplam : araToplam).toStringAsFixed(2)} TL', fontBold, fontBold, false, color: PdfColors.blue900),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableHeader(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(safe(text), textAlign: align, style: pw.TextStyle(font: font, fontSize: 8.5, color: PdfColors.white)),
    );
  }

  static pw.Widget _tableCell(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(safe(text), textAlign: align, style: pw.TextStyle(font: font, fontSize: 8.5)),
    );
  }

  static pw.Widget _pdfRow2Col(
    String label,
    String value,
    pw.Font fontLabel,
    pw.Font fontValue,
    bool isRoll, {
    bool is58 = false,
    PdfColor? color,
  }) {
    final size = isRoll ? (is58 ? 7.5 : 8.5) : 9.5;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(safe(label), style: pw.TextStyle(font: fontLabel, fontSize: size, color: color)),
          pw.Text(safe(value), style: pw.TextStyle(font: fontValue, fontSize: size, color: color)),
        ],
      ),
    );
  }

  static PdfPageFormat _getPageFormat(String format) {
    switch (format) {
      case '58mm':
        return PdfPageFormat.roll57;
      case '80mm':
        return PdfPageFormat.roll80;
      case 'A5':
        return PdfPageFormat.a5;
      case 'A4':
      default:
        return PdfPageFormat.a4;
    }
  }
}
