import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/storage/save_settings.dart';
import 'permission_service.dart';

enum PrinterConnectionType {
  network, // WiFi / Ethernet Raw TCP Socket (Port 9100)
  bluetooth, // Bluetooth Serial / POS
  system, // OS / Platform Printer
}

class DiscoveredPrinter {
  final String name;
  final PrinterConnectionType type;
  final String? ip;
  final int port;
  final String? url;
  final Printer? systemPrinter;
  final bool isConnected;

  DiscoveredPrinter({
    required this.name,
    required this.type,
    this.ip,
    this.port = 9100,
    this.url,
    this.systemPrinter,
    this.isConnected = true,
  });

  String get typeLabel {
    switch (type) {
      case PrinterConnectionType.network:
        return 'Ağ (WiFi / IP)';
      case PrinterConnectionType.bluetooth:
        return 'Bluetooth';
      case PrinterConnectionType.system:
        return 'Sistem Yazıcısı';
    }
  }

  String get detailLabel {
    if (type == PrinterConnectionType.network) {
      return '$ip:$port';
    }
    return url ?? name;
  }
}

class PrintResult {
  final bool success;
  final String message;
  final Object? error;

  PrintResult({
    required this.success,
    required this.message,
    this.error,
  });
}

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  /// Sistem ve Bluetooth yazıcılarını gerçek olarak tarar ve döndürür
  static Future<List<DiscoveredPrinter>> getSystemAndBluetoothPrinters() async {
    final list = <DiscoveredPrinter>[];
    try {
      // Bluetooth ve yazıcı izinlerini güvenceye al
      await PermissionService.requestPrinterAndBluetoothPermissions();

      final printers = await Printing.listPrinters();
      for (final p in printers) {
        final cleanName = _cleanHostOrModelName(p.name);
        final isBt = p.name.toLowerCase().contains('bt') ||
            p.name.toLowerCase().contains('bluetooth') ||
            p.name.toLowerCase().contains('pos') ||
            p.name.toLowerCase().contains('thermal') ||
            p.name.toLowerCase().contains('zebra') ||
            p.name.toLowerCase().contains('bixolon') ||
            p.name.toLowerCase().contains('xprinter') ||
            p.name.toLowerCase().contains('pax') ||
            (p.url.toLowerCase().contains('bluetooth'));

        list.add(DiscoveredPrinter(
          name: cleanName.isNotEmpty ? cleanName : p.name,
          type: isBt ? PrinterConnectionType.bluetooth : PrinterConnectionType.system,
          url: p.url,
          systemPrinter: p,
          isConnected: p.isAvailable,
        ));
      }
    } catch (e) {
      debugPrint('Printing.listPrinters error: $e');
    }
    return list;
  }

  /// Yerel ağdaki IP yazıcılarını tarar (Belirli subnet üzerinde Port 9100 testi)
  static Future<List<DiscoveredPrinter>> scanNetworkPrinters({
    String baseSubnet = '192.168.1',
    int startRange = 1,
    int endRange = 254,
    int port = 9100,
    Duration timeout = const Duration(milliseconds: 300),
  }) async {
    return autoDiscoverNetworkPrinters(defaultPort: port, timeout: timeout);
  }

  /// Algoritmik olarak cihazın aktif ağ kartlarını ve yerel subnet'leri tespit edip
  /// ağdaki tüm IP yazıcıları (Port 9100, 631, 80) yüksek hızlı paralel taramayla bulur.
  static Future<List<DiscoveredPrinter>> autoDiscoverNetworkPrinters({
    int defaultPort = 9100,
    Duration timeout = const Duration(milliseconds: 320),
  }) async {
    final discovered = <DiscoveredPrinter>[];
    final subnetsToScan = <String>{};

    try {
      // 1. Cihazın aktif ağ kartlarındaki IP'leri ve subnetleri tespit et
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ipStr = addr.address;
          if (ipStr.contains('.') && !ipStr.startsWith('127.')) {
            final lastDot = ipStr.lastIndexOf('.');
            final subnet = ipStr.substring(0, lastDot);
            subnetsToScan.add(subnet);
          }
        }
      }
    } catch (e) {
      debugPrint('NetworkInterface.list error: $e');
    }

    // Varsayılan yaygın subnet'leri de ekle
    subnetsToScan.add('192.168.1');
    if (!subnetsToScan.contains('192.168.0')) subnetsToScan.add('192.168.0');

    // 2. Bilinen ofis yazıcı IP'lerini (örn 192.168.1.238 ve kayıtlı IP) öncelikli test et
    final priorityIps = <String>{};
    if (SaveSettings.seciliYaziciIp.isNotEmpty) priorityIps.add(SaveSettings.seciliYaziciIp);
    priorityIps.add('192.168.1.238');

    for (final pIp in priorityIps) {
      final p = await _probeSingleIp(pIp, defaultPort, timeout);
      if (p != null && !discovered.any((d) => d.ip == p.ip)) {
        discovered.add(p);
      }
    }

    // 3. Subnet'leri yüksek hızlı paralel (batch size 64) soketler ile tara
    const batchSize = 64;

    for (final subnet in subnetsToScan) {
      for (int i = 1; i <= 254; i += batchSize) {
        final end = (i + batchSize - 1) > 254 ? 254 : (i + batchSize - 1);
        final batchFutures = <Future>[];

        for (int j = i; j <= end; j++) {
          final ip = '$subnet.$j';
          if (discovered.any((d) => d.ip == ip)) continue;

          batchFutures.add(_probeSingleIp(ip, defaultPort, timeout).then((printer) {
            if (printer != null && !discovered.any((d) => d.ip == printer.ip)) {
              discovered.add(printer);
            }
          }));
        }

        await Future.wait(batchFutures);
      }
    }

    return discovered;
  }

  /// Tek bir IP adresini standart yazıcı portları üzerinden (9100, 631, 80, 443) test eder
  static Future<DiscoveredPrinter?> _probeSingleIp(
    String ip,
    int defaultPort,
    Duration timeout,
  ) async {
    // 1. Port 9100 (RAW / JetDirect / ESC-POS / Thermal / Laser)
    try {
      final s = await Socket.connect(ip, defaultPort, timeout: timeout);
      s.destroy();
      final modelName = await _resolveDynamicPrinterName(ip);
      return DiscoveredPrinter(
        name: modelName,
        type: PrinterConnectionType.network,
        ip: ip,
        port: defaultPort,
      );
    } catch (_) {}

    // 2. Port 631 (IPP / IPPS - AirPrint, CUPS, HP/Canon/Epson Network Printers)
    try {
      final s = await Socket.connect(ip, 631, timeout: timeout);
      s.destroy();
      final modelName = await _resolveDynamicPrinterName(ip);
      return DiscoveredPrinter(
        name: modelName,
        type: PrinterConnectionType.network,
        ip: ip,
        port: 631,
      );
    } catch (_) {}

    // 3. Port 80 / 443 / 8080 (Embedded Web Server - Sadece gerçek yazıcılar)
    for (final port in [80, 443, 8080]) {
      try {
        final s = await Socket.connect(ip, port, timeout: timeout);
        s.destroy();
        final modelName = await _resolveDynamicPrinterName(ip);
        // Sadece gerçek yazıcı tespiti yapıldıysa ekle (IIS/Router/Web sunucularını ele)
        if (modelName != 'Ağ Yazıcısı' && modelName != 'Termal Ağ Yazıcısı' && !modelName.toLowerCase().contains('iis') && !modelName.toLowerCase().contains('router')) {
          return DiscoveredPrinter(
            name: modelName,
            type: PrinterConnectionType.network,
            ip: ip,
            port: 9100,
          );
        }
      } catch (_) {}
    }

    return null;
  }

  /// Ağdaki bir IP adresinin gerçek marka ve modelini dinamik olarak tespit eder
  static Future<String> _resolveDynamicPrinterName(String ip) async {
    // 1. Port 9100 üzerinden PJL (Printer Job Language) INFO ID Sorgusu (HP, Brother, Canon, Kyocera, Lexmark)
    try {
      final ps = await Socket.connect(ip, 9100, timeout: const Duration(milliseconds: 600));
      ps.write('\x1B%-12345X@PJL\r\n@PJL INFO ID\r\n\x1B%-12345X\r\n');
      await ps.flush();
      final completer = Completer<String?>();
      ps.listen((d) {
        if (!completer.isCompleted) completer.complete(String.fromCharCodes(d));
      }, onError: (_) {
        if (!completer.isCompleted) completer.complete(null);
      });
      final res = await completer.future.timeout(const Duration(milliseconds: 800), onTimeout: () => null);
      ps.destroy();
      if (res != null && res.isNotEmpty) {
        final match = RegExp(r'"([^"]+)"').firstMatch(res);
        if (match != null) {
          final clean = _cleanHostOrModelName(match.group(1)!);
          if (clean.isNotEmpty && clean != 'Ağ Yazıcısı') return clean;
        }
      }
    } catch (_) {}

    // 2. HTTP / HTTPS / IPP Web Arayüzü Başlık & Model Taraması (Port 80, 443, 631, 8080)
    for (final port in [80, 443, 631, 8080]) {
      try {
        final client = HttpClient()
          ..connectionTimeout = const Duration(milliseconds: 1000)
          ..badCertificateCallback = (cert, host, port) => true;
        final uri = Uri(scheme: port == 443 ? 'https' : 'http', host: ip, port: port, path: '/');
        final request = await client.getUrl(uri);
        final response = await request.close().timeout(const Duration(milliseconds: 1500));

        final server = response.headers.value('server') ?? '';
        final modelHeader = response.headers.value('x-printer-model') ?? response.headers.value('printer-name') ?? '';

        if (modelHeader.isNotEmpty) {
          final clean = _cleanHostOrModelName(modelHeader);
          if (clean.isNotEmpty) return clean;
        }
        if (server.isNotEmpty && !server.toLowerCase().contains('iis') && !server.toLowerCase().contains('apache') && !server.toLowerCase().contains('nginx')) {
          final clean = _cleanHostOrModelName(server);
          if (clean.isNotEmpty && clean != 'Ağ Yazıcısı') return clean;
        }

        final bodyBytes = await response.take(4096).toList();
        final bodyStr = utf8.decode(bodyBytes.expand((x) => x).toList(), allowMalformed: true);
        final titleMatch = RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false).firstMatch(bodyStr);
        if (titleMatch != null) {
          final title = titleMatch.group(1)?.trim() ?? '';
          final clean = _cleanHostOrModelName(title);
          if (clean.isNotEmpty && !clean.toLowerCase().contains('router') && !clean.toLowerCase().contains('gateway') && !clean.toLowerCase().contains('403') && !clean.toLowerCase().contains('iis') && clean != 'Ağ Yazıcısı') {
            return clean;
          }
        }
      } catch (_) {}
    }

    // 3. Reverse DNS / Hostname Çözümlemesi
    try {
      final addr = InternetAddress(ip);
      final reverse = await addr.reverse();
      if (reverse.host.isNotEmpty && reverse.host != ip) {
        final sanitized = _cleanHostOrModelName(reverse.host);
        if (sanitized.isNotEmpty && !sanitized.toLowerCase().startsWith('android') && !sanitized.toLowerCase().startsWith('pc') && sanitized != 'Ağ Yazıcısı') {
          return sanitized;
        }
      }
    } catch (_) {}

    return 'Ağ Yazıcısı';
  }

  /// Ham hostname veya HTTP/PJL başlıklarından marka/modeli temizleyip formatlar
  static String _cleanHostOrModelName(String raw) {
    var text = raw.replaceAll(RegExp(r'\.local|\.lan|\.home|\.internal|\.domain|http://|https://', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();

    // Remove generic Server prefixes like "HP HTTP Server;", "Server: "
    text = text.replaceAll(RegExp(r'HP HTTP Server;?\s*', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'Built:.*$', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'Serial Number:.*$', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'\{[A-Za-z0-9]+\}', caseSensitive: false), '');
    text = text.trim();
    if (text.endsWith(';')) text = text.substring(0, text.length - 1).trim();

    final lower = text.toLowerCase();

    // 1. HP Yazıcılar (Smart Tank, LaserJet, DeskJet, OfficeJet, ENVY, PageWide, Ink Tank)
    if (lower.contains('hp') || lower.contains('laserjet') || lower.contains('smart tank') || lower.contains('deskjet') || lower.contains('officejet') || lower.contains('ink tank')) {
      final match = RegExp(r'(HP\s+(?:Smart\s+Tank(?:\s+[0-9\-]+(?:\s+series)?)?|LaserJet(?:\s+Pro)?(?:\s+[A-Za-z0-9\-]+)?|DeskJet(?:\s+[A-Za-z0-9\-]+)?|OfficeJet(?:\s+Pro)?(?:\s+[A-Za-z0-9\-]+)?|ENVY|PageWide|Ink\s+Tank)[^\;\,\r\n\{\}]*)', caseSensitive: false).firstMatch(text);
      if (match != null) {
        var name = match.group(1)!.trim();
        name = name.replaceAll(RegExp(r'\s+-\s+[A-F0-9]{4,8}$'), '');
        return name;
      }
      final cleanHp = text.replaceAll(RegExp(r'\s+-\s+[A-F0-9]{4,8}$'), '').trim();
      if (cleanHp.isNotEmpty && !cleanHp.toLowerCase().contains('http server')) return cleanHp;
      return 'HP Yazıcı';
    }

    // 2. Epson Yazıcılar (TM-T POS, EcoTank, WorkForce, L-serisi)
    if (lower.contains('epson')) {
      final match = RegExp(r'(Epson\s+[^\;\,\r\n\{\}]+)', caseSensitive: false).firstMatch(text);
      return match != null ? match.group(1)!.trim() : 'Epson Yazıcı';
    }

    // 3. Canon Yazıcılar (PIXMA, i-SENSYS, MAXIFY, LBP)
    if (lower.contains('canon')) {
      final match = RegExp(r'(Canon\s+[^\;\,\r\n\{\}]+)', caseSensitive: false).firstMatch(text);
      return match != null ? match.group(1)!.trim() : 'Canon Yazıcı';
    }

    // 4. Brother Yazıcılar (HL, DCP, MFC, QL)
    if (lower.contains('brother')) {
      final match = RegExp(r'(Brother\s+[^\;\,\r\n\{\}]+)', caseSensitive: false).firstMatch(text);
      return match != null ? match.group(1)!.trim() : 'Brother Yazıcı';
    }

    // 5. Zebra Etiket Yazıcıları
    if (lower.contains('zebra')) {
      final match = RegExp(r'(Zebra\s+[^\;\,\r\n\{\}]+)', caseSensitive: false).firstMatch(text);
      return match != null ? match.group(1)!.trim() : 'Zebra Etiket Yazıcısı';
    }

    // 6. Termal POS Markaları
    if (lower.contains('xprinter')) return 'Xprinter Termal Fiş Yazıcısı';
    if (lower.contains('bixolon')) return 'Bixolon Termal Fiş Yazıcısı';
    if (lower.contains('rongta')) return 'Rongta Termal Fiş Yazıcısı';
    if (lower.contains('star') || lower.contains('tsp')) return 'Star Micronics Yazıcı';
    if (lower.contains('hprt')) return 'HPRT Termal Yazıcı';
    if (lower.contains('pax')) return 'PAX POS Cihazı';

    if (text.length > 32) {
      text = text.substring(0, 32).trim();
    }
    return text.isNotEmpty ? text : 'Ağ Yazıcısı';
  }

  /// Tüm gerçek yazıcıları (Ağ + Bluetooth + Sistem) birleştirerek getirir
  static Future<List<DiscoveredPrinter>> getAllAvailablePrinters() async {
    final results = <DiscoveredPrinter>[];

    // 1. Ekli kayıtlı IP yazıcısı varsa ekle
    if (SaveSettings.seciliYaziciIp.isNotEmpty) {
      final cleanName = SaveSettings.seciliYaziciAdi.isNotEmpty && !SaveSettings.seciliYaziciAdi.contains('Seçilmedi')
          ? SaveSettings.seciliYaziciAdi
          : 'Termal Ağ Yazıcısı';
      results.add(DiscoveredPrinter(
        name: cleanName,
        type: PrinterConnectionType.network,
        ip: SaveSettings.seciliYaziciIp,
        port: SaveSettings.seciliYaziciPort,
      ));
    }

    // 2. Sistem & Bluetooth Yazıcıları
    final sysPrinters = await getSystemAndBluetoothPrinters();
    results.addAll(sysPrinters);

    return results;
  }

  /// Ağdaki IP Yazıcıya ham byte/ESC-POS verisi gönderir
  static Future<PrintResult> printToNetworkSocket({
    required String ip,
    int port = 9100,
    required List<int> bytes,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: timeout);
      socket.add(bytes);
      await socket.flush();
      await socket.close();
      return PrintResult(
        success: true,
        message: 'Baskı yazıcıya başarıyla iletildi.',
      );
    } catch (e) {
      debugPrint('printToNetworkSocket error: $e');
      String userMsg = 'Yazıcıya bağlanılamadı.';
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('timed out') || errStr.contains('110')) {
        userMsg = 'Yazıcıya ulaşılamadı. Cihazın açık ve ağa bağlı olduğunu kontrol ediniz.';
      } else if (errStr.contains('connection refused') || errStr.contains('111')) {
        userMsg = 'Yazıcı bağlantısı reddedildi.';
      } else if (errStr.contains('network is unreachable') || errStr.contains('no route')) {
        userMsg = 'Ağa ulaşılamıyor. WiFi bağlantınızı kontrol ediniz.';
      } else {
        userMsg = 'Yazıcı bağlantı hatası: $e';
      }
      return PrintResult(
        success: false,
        message: userMsg,
        error: e,
      );
    }
  }

  /// Sistem veya Bluetooth eşleşmelerinde adı veya URL'si ile kayıtlı yazıcıyı bulur
  static Future<Printer?> findMatchingPrinter({String? name, String? url}) async {
    try {
      final printers = await Printing.listPrinters();
      if (printers.isEmpty) return null;

      // 1. URL ile tam eşleşme
      if (url != null && url.isNotEmpty) {
        for (final p in printers) {
          if (p.url == url) return p;
        }
      }

      // 2. İsim ile tam eşleşme
      if (name != null && name.isNotEmpty) {
        final cleanTarget = EscPosBuilder._normalizeTurkishChars(name).toLowerCase().trim();
        for (final p in printers) {
          final cleanPName = EscPosBuilder._normalizeTurkishChars(p.name).toLowerCase().trim();
          if (cleanPName == cleanTarget) return p;
        }
      }

      // 3. Kısmi isim eşleşmesi (Örn: "POS", "Thermal", "Bluetooth", "Printer")
      if (name != null && name.isNotEmpty) {
        final cleanTarget = EscPosBuilder._normalizeTurkishChars(name).toLowerCase().trim();
        for (final p in printers) {
          final cleanPName = EscPosBuilder._normalizeTurkishChars(p.name).toLowerCase().trim();
          if (cleanPName.contains(cleanTarget) || cleanTarget.contains(cleanPName)) {
            return p;
          }
        }
      }

      return printers.first;
    } catch (e) {
      debugPrint('findMatchingPrinter error: $e');
      return null;
    }
  }

  /// Bluetooth veya Sistem Yazıcısına PDF formatında baskı gönderir
  static Future<PrintResult> printPdfToPrinter({
    required Uint8List pdfBytes,
    Printer? targetPrinter,
    String? printerName,
    String? printerUrl,
    String docName = 'BYM360_Belge',
    bool useLayoutDialogIfNoPrinter = true,
  }) async {
    try {
      // Android / iOS / Web üzerinde sistem yazdırma arayüzünü açar
      final success = await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: docName,
      );

      return PrintResult(
        success: success,
        message: success
            ? 'Yazdırma işlemi tamamlandı.'
            : 'Yazdırma iptal edildi veya tamamlanamadı.',
      );
    } catch (e) {
      debugPrint('printPdfToPrinter error: $e');
      return PrintResult(
        success: false,
        message: 'Yazdırma sırasında hata oluştu: $e',
        error: e,
      );
    }
  }

  /// Ağ Yazıcısı Bağlantı & Sınama Testi
  static Future<PrintResult> testNetworkPrinter({
    required String ip,
    int port = 9100,
    String paperWidth = '80mm',
  }) async {
    final builder = EscPosBuilder(paperWidth: paperWidth);
    builder.init();
    builder.alignCenter();
    builder.bold(true);
    builder.doubleHeight(true);
    builder.text('BYM 360 MOBIL');
    builder.doubleHeight(false);
    builder.text('YAZICI SINAMA BASKISI');
    builder.bold(false);
    builder.divider();
    builder.alignLeft();
    builder.text('Tarih  : ${DateTime.now().toString().substring(0, 19)}');
    builder.text('IP     : $ip');
    builder.text('Port   : $port');
    builder.text('Kagit  : $paperWidth Termal');
    builder.text('Tip    : Ag / WiFi IP Yazici');
    builder.divider();
    builder.alignCenter();
    builder.bold(true);
    builder.text('** BAGLANTI VE TEST BASARILI **');
    builder.bold(false);
    builder.text('BYM 360 ERP & Depo Yonetimi');
    builder.feed(3);
    builder.cut();

    return await printToNetworkSocket(
      ip: ip,
      port: port,
      bytes: builder.bytes,
    );
  }

  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;

  static Future<pw.Font> _getRegularFont() async {
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

  static Future<pw.Font> _getBoldFont() async {
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

  /// Bluetooth / Sistem Yazıcısı Sınama Testi
  static Future<PrintResult> testBluetoothOrSystemPrinter({
    Printer? printer,
    String? printerName,
    String? printerUrl,
    String paperWidth = '80mm',
  }) async {
    try {
      final fontRegular = await _getRegularFont();
      final fontBold = await _getBoldFont();
      final docTheme = pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      );

      final pdf = pw.Document(theme: docTheme);
      final pageFormat = paperWidth == '58mm'
          ? PdfPageFormat.roll57
          : (paperWidth == '80mm' ? PdfPageFormat.roll80 : PdfPageFormat.a4);

      final name = printer?.name ?? printerName ?? 'Sistem Yazıcısı';
      final cleanName = EscPosBuilder._normalizeTurkishChars(name);
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          theme: docTheme,
          margin: const pw.EdgeInsets.all(10),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('BYM 360 MOBIL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, font: fontBold)),
              pw.Text('YAZICI SINAMA BASKISI', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, font: fontBold)),
              pw.Divider(),
              pw.Text('Yazici: $cleanName', style: pw.TextStyle(fontSize: 9, font: fontRegular)),
              pw.Text('Tarih: ${DateTime.now().toString().substring(0, 19)}', style: pw.TextStyle(fontSize: 8, font: fontRegular)),
              pw.Text('Kagit: $paperWidth', style: pw.TextStyle(fontSize: 8, font: fontRegular)),
              pw.Divider(),
              pw.Text('** BAGLANTI VE TEST BASARILI **', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, font: fontBold)),
              pw.Text('BYM 360 ERP & Depo Yonetimi', style: pw.TextStyle(fontSize: 8, font: fontRegular)),
            ],
          ),
        ),
      );

      final pdfBytes = await pdf.save();
      return await printPdfToPrinter(
        pdfBytes: pdfBytes,
        targetPrinter: printer,
        printerName: printer?.name ?? printerName,
        printerUrl: printer?.url ?? printerUrl,
        docName: 'BYM360_Sinama_Baskisi',
      );
    } catch (e) {
      return PrintResult(
        success: false,
        message: 'Sınama baskısı gönderilemedi: $e',
        error: e,
      );
    }
  }
}

/// Saf Dart ile çalışan, Türkçe karakterleri normalize eden ESC/POS Komut Oluşturucu
class EscPosBuilder {
  final String paperWidth; // '80mm' (48 karakter) veya '58mm' (32 karakter)
  final List<int> _bytes = [];

  EscPosBuilder({this.paperWidth = '80mm'});

  List<int> get bytes => Uint8List.fromList(_bytes);

  int get maxColumns => paperWidth == '58mm' ? 32 : 48;

  void init() {
    _bytes.addAll([0x1B, 0x40]); // ESC @ (Initialize)
  }

  void alignLeft() {
    _bytes.addAll([0x1B, 0x61, 0x00]); // ESC a 0
  }

  void alignCenter() {
    _bytes.addAll([0x1B, 0x61, 0x01]); // ESC a 1
  }

  void alignRight() {
    _bytes.addAll([0x1B, 0x61, 0x02]); // ESC a 2
  }

  void bold(bool enable) {
    _bytes.addAll([0x1B, 0x45, enable ? 0x01 : 0x00]); // ESC E n
  }

  void underline(bool enable) {
    _bytes.addAll([0x1B, 0x2D, enable ? 0x01 : 0x00]); // ESC - n
  }

  void doubleHeight(bool enable) {
    _bytes.addAll([0x1B, 0x21, enable ? 0x10 : 0x00]); // ESC ! n
  }

  void doubleWidth(bool enable) {
    _bytes.addAll([0x1B, 0x21, enable ? 0x20 : 0x00]);
  }

  void text(String text) {
    final clean = _normalizeTurkishChars(text);
    _bytes.addAll(latin1.encode('$clean\n'));
  }

  void divider({String char = '-'}) {
    final line = char * maxColumns;
    text(line);
  }

  void doubleDivider() {
    divider(char: '=');
  }

  void row2Column(String left, String right) {
    final cleanLeft = _normalizeTurkishChars(left);
    final cleanRight = _normalizeTurkishChars(right);
    final space = maxColumns - cleanLeft.length - cleanRight.length;
    if (space > 0) {
      final line = cleanLeft + (' ' * space) + cleanRight;
      text(line);
    } else {
      text('$cleanLeft $cleanRight');
    }
  }

  void row3Column(String col1, String col2, String col3) {
    final total = maxColumns;
    final w1 = (total * 0.45).floor();
    final w2 = (total * 0.25).floor();
    final w3 = total - w1 - w2;

    final c1 = _fitText(col1, w1, alignRight: false);
    final c2 = _fitText(col2, w2, alignRight: true);
    final c3 = _fitText(col3, w3, alignRight: true);

    text('$c1$c2$c3');
  }

  void row4Column(String col1, String col2, String col3, String col4) {
    final total = maxColumns;
    final w1 = (total * 0.40).floor();
    final w2 = (total * 0.18).floor();
    final w3 = (total * 0.20).floor();
    final w4 = total - w1 - w2 - w3;

    final c1 = _fitText(col1, w1, alignRight: false);
    final c2 = _fitText(col2, w2, alignRight: true);
    final c3 = _fitText(col3, w3, alignRight: true);
    final c4 = _fitText(col4, w4, alignRight: true);

    text('$c1$c2$c3$c4');
  }

  void feed([int lines = 1]) {
    for (int i = 0; i < lines; i++) {
      _bytes.addAll([0x0A]);
    }
  }

  void cut() {
    _bytes.addAll([0x1D, 0x56, 0x42, 0x00]); // GS V B 0 (Cut paper)
  }

  void drawerPulse() {
    _bytes.addAll([0x1B, 0x70, 0x00, 0x19, 0xFA]); // ESC p 0 25 250 (Open cash drawer)
  }

  static String _fitText(String text, int width, {bool alignRight = false}) {
    final clean = _normalizeTurkishChars(text);
    if (clean.length > width) {
      return clean.substring(0, width);
    }
    final pad = ' ' * (width - clean.length);
    return alignRight ? '$pad$clean' : '$clean$pad';
  }

  static String _normalizeTurkishChars(String input) {
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
}
