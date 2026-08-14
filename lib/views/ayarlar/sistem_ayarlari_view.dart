import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../../core/constants/api_constants.dart';
import '../../core/storage/save_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/printer_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/barcode_scanner_view.dart';
import '../../widgets/device_permissions_modal.dart';
import '../../widgets/dynamic_island_toast.dart';
import '../../widgets/printer_detail_modal.dart';
import '../db_listele_view.dart';
import 'ayarlar_views.dart';

class SistemAyarlariView extends StatefulWidget {
  const SistemAyarlariView({super.key});

  @override
  State<SistemAyarlariView> createState() => _SistemAyarlariViewState();
}

class _SistemAyarlariViewState extends State<SistemAyarlariView> {
  late bool _darkMode;
  String _cameraMode = 'Dahili Kamera';

  // Yazici Yonetimi
  String _printerType = SaveSettings.seciliYaziciTipi;
  List<DiscoveredPrinter> _networkPrinters = [];
  DiscoveredPrinter? _selectedNetworkPrinter;
  List<DiscoveredPrinter> _realBluetoothPrinters = [];
  DiscoveredPrinter? _selectedRealBluetooth;
  String _paperWidth = SaveSettings.yaziciKagizGenislik;
  bool _isScanningPrinters = false;

  final Map<String, bool> _stokTuruSecimleri = {
    'Ticari Mal': true,
    'Hammadde': true,
    'Yarı Mamul': true,
    'Mamul': true,
    'Tüketim Malzemesi': true,
    'Hizmet': true,
  };

  @override
  void initState() {
    super.initState();
    _darkMode = SaveSettings.isDarkMode;
    if (SaveSettings.seciliYaziciIp.isNotEmpty) {
      _selectedNetworkPrinter = DiscoveredPrinter(
        name: SaveSettings.seciliYaziciAdi.isNotEmpty && !SaveSettings.seciliYaziciAdi.contains('Seçilmedi')
            ? SaveSettings.seciliYaziciAdi
            : 'Termal Ağ Yazıcısı',
        type: PrinterConnectionType.network,
        ip: SaveSettings.seciliYaziciIp,
        port: SaveSettings.seciliYaziciPort,
      );
      _networkPrinters = [_selectedNetworkPrinter!];
    }
    _loadBluetoothPrinters();
  }

  Future<void> _loadBluetoothPrinters() async {
    final list = await PrinterService.getSystemAndBluetoothPrinters();
    if (mounted) {
      setState(() {
        _realBluetoothPrinters = list;
        if (list.isNotEmpty) {
          final existing = list.where((p) => p.name == SaveSettings.seciliYaziciAdi).firstOrNull;
          _selectedRealBluetooth = existing ?? list.first;
        }
      });
    }
  }

  String _getLanguageDisplayName(String code) {
    switch (code) {
      case 'tr':
        return 'Türkçe (TR)';
      case 'en':
        return 'English (EN)';
      case 'de':
        return 'Deutsch (DE)';
      case 'az':
        return 'Azərbaycan dili (AZ)';
      default:
        return 'Türkçe (TR)';
    }
  }

  Future<void> _scanNetworkPrinters() async {
    setState(() => _isScanningPrinters = true);

    final discovered = await PrinterService.autoDiscoverNetworkPrinters(defaultPort: 9100);

    if (mounted) {
      setState(() {
        _isScanningPrinters = false;
        _networkPrinters = discovered;
      });

      if (discovered.isNotEmpty) {
        final first = discovered.first;
        setState(() {
          _selectedNetworkPrinter = first;
        });
        await SaveSettings.savePrinterSettings(
          tip: 'Ağ / IP Yazıcı',
          ad: first.name,
          ip: first.ip ?? '',
          port: first.port,
          kagiz: _paperWidth,
        );
        if (!mounted) return;
        AppNotification.showSuccess(
          context,
          '${first.name} seçildi.',
          title: 'Yazıcı Bulundu',
        );
      } else {
        AppNotification.showWarning(
          context,
          'Ağda yazıcı bulunamadı. Cihazın WiFi ağına bağlı olduğundan emin olun.',
          title: 'Yazıcı Bulunamadı',
        );
      }
    }
  }

  Future<void> _scanBluetoothPrinters() async {
    setState(() => _isScanningPrinters = true);
    final list = await PrinterService.getSystemAndBluetoothPrinters();
    if (mounted) {
      setState(() {
        _realBluetoothPrinters = list;
        _isScanningPrinters = false;
        if (list.isNotEmpty) {
          _selectedRealBluetooth = list.first;
        }
      });
      if (list.isNotEmpty) {
        AppNotification.showSuccess(
          context,
          '${list.length} cihaz listelendi.',
          title: 'Cihazlar',
        );
      } else {
        AppNotification.showWarning(
          context,
          'Eşleşmiş cihaz bulunamadı.',
          title: 'Bluetooth',
        );
      }
    }
  }

  Future<void> _testPrinterConnection() async {
    if (_printerType == 'Ağ / IP Yazıcı') {
      final ip = _selectedNetworkPrinter?.ip ?? SaveSettings.seciliYaziciIp;
      final port = _selectedNetworkPrinter?.port ?? SaveSettings.seciliYaziciPort;

      if (ip.isEmpty) {
        AppNotification.showError(
          context,
          'Lütfen "Otomatik Bul" butonuna basarak bir yazıcı seçiniz.',
          title: 'Ağ Yazıcısı Seçilmedi',
        );
        return;
      }

      final printerName = _selectedNetworkPrinter?.name ??
          (SaveSettings.seciliYaziciAdi.isNotEmpty ? SaveSettings.seciliYaziciAdi : 'Termal Ağ Yazıcısı');

      final island = AppNotification.showPrinting(
        context,
        title: 'Sınama Baskısı Gönderiliyor',
        docName: 'Sınama Sayfası (80mm/58mm)',
        printerInfo: printerName,
      );

      final isOfficePrinter = printerName.toLowerCase().contains('hp') ||
          printerName.toLowerCase().contains('smart tank') ||
          printerName.toLowerCase().contains('laserjet') ||
          printerName.toLowerCase().contains('deskjet') ||
          printerName.toLowerCase().contains('officejet') ||
          printerName.toLowerCase().contains('canon') ||
          printerName.toLowerCase().contains('brother') ||
          _paperWidth == 'A4' ||
          _paperWidth == 'A5';

      final res = isOfficePrinter
          ? await PrinterService.testBluetoothOrSystemPrinter(
              printerName: printerName,
              paperWidth: _paperWidth,
            )
          : await PrinterService.testNetworkPrinter(
              ip: ip,
              port: port,
              paperWidth: _paperWidth,
            );

      if (mounted) {
        if (res.success) {
          await SaveSettings.savePrinterSettings(
            tip: _printerType,
            ad: printerName,
            ip: ip,
            port: port,
            kagiz: _paperWidth,
          );
          island.updateSuccess(
            title: 'Sınama Baskısı Başarılı',
            message: 'Yazıcıdan test fişi çıktı',
          );
        } else {
          island.updateError(
            title: 'Yazıcıya Bağlanılamadı',
            message: res.message,
          );
        }
      }
    } else {
      if (_selectedRealBluetooth == null && _realBluetoothPrinters.isEmpty) {
        AppNotification.showError(
          context,
          'Lütfen cihazınızı eşleştirip "Cihazları Tara" butonuna basınız.',
          title: 'Bluetooth Yazıcı Bulunamadı',
        );
        return;
      }

      final target = _selectedRealBluetooth ?? _realBluetoothPrinters.first;

      final island = AppNotification.showPrinting(
        context,
        title: 'Sınama Sayfası Gönderiliyor',
        docName: 'Bluetooth / Sistem Testi',
        printerInfo: target.name,
      );

      final res = await PrinterService.testBluetoothOrSystemPrinter(
        printer: target.systemPrinter ?? Printer(url: target.url ?? target.name, name: target.name),
        paperWidth: _paperWidth,
      );

      if (mounted) {
        if (res.success) {
          await SaveSettings.savePrinterSettings(
            tip: _printerType,
            ad: target.name,
            ip: SaveSettings.seciliYaziciIp,
            port: SaveSettings.seciliYaziciPort,
            url: target.url ?? '',
            kagiz: _paperWidth,
          );
          island.updateSuccess(
            title: 'Sınama Başarılı',
            message: '${target.name} yazıcısına iletildi',
          );
        } else {
          island.updateError(
            title: 'Yazdırma Hatası',
            message: res.message,
          );
        }
      }
    }
  }

  void _showStokTuruDialog() {
    final tempMap = Map<String, bool>.from(_stokTuruSecimleri);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('stok_turu_filtresi', 'Stok Türü Filtresi'),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                ...tempMap.keys.map((key) {
                  return CheckboxListTile(
                    title: Text(key, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
                    value: tempMap[key],
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (val) {
                      setModalState(() {
                        tempMap[key] = val ?? false;
                      });
                    },
                  );
                }),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.35), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      setState(() {
                        _stokTuruSecimleri.clear();
                        _stokTuruSecimleri.addAll(tempMap);
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Stok türü filtreleri güncellendi.'),
                          backgroundColor: AppTheme.accentGreen,
                        ),
                      );
                    },
                    child: Text(context.tr('onayla', 'Filtreleri Uygula'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('sistemayarlari', 'Sistem & Donanım Ayarları'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Modül & Sistem Parametreleri Section (Matching bymmobil-master)
          _sectionHeader('Modül & Sistem Parametreleri', isDark),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
            ),
            child: Column(
              children: [
                _settingsListTile(
                  context,
                  title: context.tr('modulanasayfaayarlari', 'Modül Parametreleri'),
                  subtitle: 'Sayım, Depo Transfer, Mal Kabul, Satış, Sipariş ve Stok ayarları',
                  icon: Icons.dashboard_customize_rounded,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModulAnasayfaAyarlariView())),
                ),
                const Divider(height: 1),
                _settingsListTile(
                  context,
                  title: context.tr('kullanici_profil_ayarlari', 'Kullanıcı Tercihleri'),
                  subtitle: 'Fiş gün sayısı, klavye, hızlı işlemler ve profil parametreleri',
                  icon: Icons.person_rounded,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KullaniciAyarlariView())),
                ),
                const Divider(height: 1),
                _settingsListTile(
                  context,
                  title: context.tr('stok_turu_filtresi', 'Stok Türü Filtresi'),
                  subtitle: '${_stokTuruSecimleri.values.where((v) => v).length} / ${_stokTuruSecimleri.length} stok türü aktif',
                  icon: Icons.filter_alt_rounded,
                  onTap: _showStokTuruDialog,
                ),
                const Divider(height: 1),
                _settingsListTile(
                  context,
                  title: context.tr('veritabani_baglantisi', 'Veritabanı Bağlantısı'),
                  subtitle: SaveSettings.cstring.isNotEmpty ? SaveSettings.cstring : 'Aktif Veritabanı Seçimi',
                  icon: Icons.storage_rounded,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DbListeleView())),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Donanim & Cevre Birimleri Section
          _sectionHeader(context.tr('donanim_ve_yazici', 'Donanım & Çevre Birimleri'), isDark),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.print_rounded, color: AppTheme.primaryBlue, size: 24),
                  ),
                  title: Text(
                    context.tr('varsayilan_yazici_barkod', 'Yazıcı ve Kağıt Ayarları'),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${SaveSettings.seciliYaziciAdi.isNotEmpty && !SaveSettings.seciliYaziciAdi.contains('Seçilmedi') ? SaveSettings.seciliYaziciAdi : (_printerType == "Ağ / IP Yazıcı" ? "Termal Ağ Yazıcısı" : (_selectedRealBluetooth?.name ?? "Bluetooth Yazıcı"))} • ${SaveSettings.yaziciKagizGenislik}',
                      style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => _openYaziciBarkodBottomSheet(context),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _cameraMode,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.tr('kamera_barkod_okuma_modu', 'Kamera / Barkod Okuma Modu'),
                          prefixIcon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryBlue, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Dahili Kamera',
                            child: Text(
                              context.tr('dahili_kamera_desc', 'Dahili Kamera (Gelişmiş Kamera Okuyucu)'),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Harici Okuyucu',
                            child: Text(
                              context.tr('harici_okuyucu_desc', 'Harici Barkod Okuyucu (Bluetooth/USB Scanner)'),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _cameraMode = val);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: isDark ? 0.5 : 0.35), width: 1.2),
                                backgroundColor: isDark ? AppTheme.primaryBlue.withValues(alpha: 0.12) : AppTheme.primaryBlue.withValues(alpha: 0.06),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final code = await BarcodeScannerScreen.scan(context, title: 'Barkod Okuyucu Sınaması');
                                if (code != null && mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Sınama Başarılı! Okunan Barkod: $code'),
                                      backgroundColor: AppTheme.accentGreen,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryBlue, size: 18),
                              label: Text(context.tr('barkod_test_et', 'Barkod Sına'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: isDark ? 0.5 : 0.35), width: 1.2),
                                backgroundColor: isDark ? AppTheme.primaryBlue.withValues(alpha: 0.12) : AppTheme.primaryBlue.withValues(alpha: 0.06),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _openYaziciBarkodBottomSheet(context),
                              icon: const Icon(Icons.tune_rounded, color: AppTheme.primaryBlue, size: 18),
                              label: const Text('Yazıcı Yapılandır', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C6FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.security_rounded, color: Color(0xFF0072FF), size: 22),
                  ),
                  title: Text(
                    context.tr('cihaz_ve_sistem_izinleri', 'Cihaz & Sistem İzinleri'),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Kamera, Bluetooth, yerel ağ ve bildirim yetkilendirmeleri',
                    style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () => DevicePermissionsModal.show(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. Gorunum & Dil Tercihleri Section
          _sectionHeader(context.tr('gorunum_tema', 'Görünüm & Dil'), isDark),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(context.tr('karanlik_mod', 'Karanlık Mod (Dark Mode)'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(context.tr('karanlik_mod_desc', 'Göz yormayan koyu tema rengini kullan'), style: GoogleFonts.inter(fontSize: 12)),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.dark_mode_rounded, color: AppTheme.primaryBlue, size: 20),
                  ),
                  value: _darkMode,
                  activeTrackColor: AppTheme.primaryBlue,
                  onChanged: (val) async {
                    setState(() => _darkMode = val);
                    await SaveSettings.toggleDarkMode(val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(context.tr('sesli_uyari', 'Sesli Bildirim & Bip Sesi'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(context.tr('sesli_uyari_desc', 'Barkod okuma ve işlem uyarı seslerini etkinleştir'), style: GoogleFonts.inter(fontSize: 12)),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.volume_up_rounded, color: AppTheme.primaryBlue, size: 20),
                  ),
                  value: SaveSettings.sesliUyariAktif,
                  activeTrackColor: AppTheme.primaryBlue,
                  onChanged: (val) async {
                    setState(() {});
                    await SaveSettings.saveSoundSettings(val);
                    if (val) {
                      SoundService.playBarcodeBeep();
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.translate_rounded, color: AppTheme.primaryBlue, size: 20),
                  ),
                  title: Text(context.tr('uygulama_dili', 'Uygulama Dili'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(_getLanguageDisplayName(SaveSettings.selectedLanguage), style: GoogleFonts.inter(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DilAyarlariView())),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 5. Sistem & Lisans Bilgileri Section
          _sectionHeader(context.tr('sistem_bilgileri', 'Sistem & Lisans Bilgileri'), isDark),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryBlue, size: 20),
                  ),
                  title: Text(context.tr('uygulamaversiyonu', 'Uygulama Sürümü'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('BYM 360 v${ApiConstants.appVersion} (Build ${ApiConstants.appVersionCode})', style: TextStyle(fontSize: 12)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.corporate_fare_rounded, color: AppTheme.primaryBlue, size: 20),
                  ),
                  title: Text(context.tr('hakkinda', 'Geliştirici & Lisans'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(context.tr('hakkinda_sub', 'BYM Yazılım - Kurumsal Mobil Çözümler'), style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _settingsListTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
      ),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }

  void _openYaziciBarkodBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.print_rounded, color: AppTheme.primaryBlue, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('varsayilan_yazici_barkod', 'Yazıcı & Donanım Yapılandırması'),
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
                                ),
                                Text(
                                  context.tr('yazici_barkod_desc', 'Varsayılan yazdırma formatı ve bağlantı tercihleri'),
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
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

                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // 1. Live Active Status Card
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _printerType == 'Ağ / IP Yazıcı' ? Icons.lan_rounded : Icons.bluetooth_connected_rounded,
                                  color: AppTheme.primaryBlue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Yazıcı Bağlantısı',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _printerType == 'Ağ / IP Yazıcı'
                                          ? (_selectedNetworkPrinter?.name.isNotEmpty == true
                                              ? _selectedNetworkPrinter!.name
                                              : (SaveSettings.seciliYaziciAdi.isNotEmpty && !SaveSettings.seciliYaziciAdi.contains('Seçilmedi')
                                                  ? SaveSettings.seciliYaziciAdi
                                                  : 'Termal Ağ Yazıcısı'))
                                          : (_selectedRealBluetooth?.name ?? (SaveSettings.seciliYaziciAdi.isNotEmpty && !SaveSettings.seciliYaziciAdi.contains('Seçilmedi') ? SaveSettings.seciliYaziciAdi : 'Bluetooth Yazıcı')),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.filledTonal(
                                tooltip: 'Hızlı Sınama Baskısı',
                                icon: const Icon(Icons.print_rounded, size: 20),
                                onPressed: _testPrinterConnection,
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                                  foregroundColor: AppTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 2. Segmented Mode Switcher
                      Text(
                        'Varsayılan Bağlantı Türü',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setSheetState(() => _printerType = 'Ağ / IP Yazıcı');
                                setState(() => _printerType = 'Ağ / IP Yazıcı');
                                SaveSettings.savePrinterSettings(
                                  tip: 'Ağ / IP Yazıcı',
                                  ad: _selectedNetworkPrinter?.name ?? 'Ağ Yazıcısı',
                                  ip: _selectedNetworkPrinter?.ip ?? SaveSettings.seciliYaziciIp,
                                  port: _selectedNetworkPrinter?.port ?? SaveSettings.seciliYaziciPort,
                                  kagiz: _paperWidth,
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: _printerType == 'Ağ / IP Yazıcı'
                                      ? AppTheme.primaryBlue.withValues(alpha: isDark ? 0.25 : 0.1)
                                      : (isDark ? Colors.white10 : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _printerType == 'Ağ / IP Yazıcı' ? AppTheme.primaryBlue : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.wifi_tethering_rounded,
                                      size: 18,
                                      color: _printerType == 'Ağ / IP Yazıcı' ? AppTheme.primaryBlue : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Ağ / WiFi Yazıcı',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: _printerType == 'Ağ / IP Yazıcı' ? FontWeight.bold : FontWeight.w500,
                                          color: _printerType == 'Ağ / IP Yazıcı' ? AppTheme.primaryBlue : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setSheetState(() => _printerType = 'Bluetooth / Sistem Yazıcısı');
                                setState(() => _printerType = 'Bluetooth / Sistem Yazıcısı');
                                SaveSettings.savePrinterSettings(
                                  tip: 'Bluetooth / Sistem Yazıcısı',
                                  ad: _selectedRealBluetooth?.name ?? 'Bluetooth Yazıcı',
                                  ip: SaveSettings.seciliYaziciIp,
                                  port: SaveSettings.seciliYaziciPort,
                                  kagiz: _paperWidth,
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: _printerType == 'Bluetooth / Sistem Yazıcısı'
                                      ? AppTheme.primaryBlue.withValues(alpha: isDark ? 0.25 : 0.1)
                                      : (isDark ? Colors.white10 : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _printerType == 'Bluetooth / Sistem Yazıcısı'
                                        ? AppTheme.primaryBlue : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bluetooth_rounded,
                                      size: 18,
                                      color: _printerType == 'Bluetooth / Sistem Yazıcısı' ? AppTheme.primaryBlue : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Bluetooth / Sistem',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: _printerType == 'Bluetooth / Sistem Yazıcısı' ? FontWeight.bold : FontWeight.w500,
                                          color: _printerType == 'Bluetooth / Sistem Yazıcısı' ? AppTheme.primaryBlue : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 3. Paper Format Grid Chips
                      Text(
                        'Varsayılan Kağıt Formatı & Rulo',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSheetPaperChip('80mm', '80mm Termal POS', Icons.receipt_long_rounded, isDark, setSheetState),
                          _buildSheetPaperChip('58mm', '58mm Mobil Fiş', Icons.receipt_rounded, isDark, setSheetState),
                          _buildSheetPaperChip('A4', 'A4 Standart Fatura', Icons.description_rounded, isDark, setSheetState),
                          _buildSheetPaperChip('A5', 'A5 İrsaliye & Makbuz', Icons.feed_rounded, isDark, setSheetState),
                        ],
                      ),

                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // 4. Detail Configurations (Network or Bluetooth)
                      if (_printerType == 'Ağ / IP Yazıcı') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ağdaki Yazıcılar (${_networkPrinters.length})',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: _isScanningPrinters ? null : () async {
                                setSheetState(() => _isScanningPrinters = true);
                                await _scanNetworkPrinters();
                                setSheetState(() => _isScanningPrinters = false);
                                setState(() {});
                              },
                              icon: _isScanningPrinters
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.autorenew_rounded, size: 16),
                              label: Text(_isScanningPrinters ? 'Taranıyor...' : 'Otomatik Bul'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryBlue,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        if (_networkPrinters.isEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.wifi_find_rounded, color: AppTheme.primaryBlue, size: 36),
                                const SizedBox(height: 10),
                                Text(
                                  'Ağdaki yazıcıları aramak için butona dokunun.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isScanningPrinters ? null : () async {
                                      setSheetState(() => _isScanningPrinters = true);
                                      await _scanNetworkPrinters();
                                      setSheetState(() => _isScanningPrinters = false);
                                      setState(() {});
                                    },
                                    icon: _isScanningPrinters
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Icon(Icons.wifi_find_rounded, size: 18),
                                    label: Text(
                                      _isScanningPrinters ? 'Taranıyor...' : 'Yazıcıları Ara',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: isDark ? 0.5 : 0.35), width: 1.2),
                                      backgroundColor: isDark ? AppTheme.primaryBlue.withValues(alpha: 0.12) : AppTheme.primaryBlue.withValues(alpha: 0.06),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Column(
                            children: _networkPrinters.map((p) {
                              final isSelected = (_selectedNetworkPrinter?.ip == p.ip) ||
                                  (_selectedNetworkPrinter == null && _networkPrinters.first.ip == p.ip);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: isSelected
                                      ? AppTheme.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.08)
                                      : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: isSelected ? AppTheme.primaryBlue : (isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    onLongPress: () {
                                      PrinterDetailModal.show(
                                        context,
                                        printer: p,
                                        onPrinterSelected: () {
                                          setSheetState(() => _selectedNetworkPrinter = p);
                                          setState(() => _selectedNetworkPrinter = p);
                                        },
                                      );
                                    },
                                    leading: Icon(
                                      Icons.lan_rounded,
                                      color: isSelected ? AppTheme.primaryBlue : Colors.grey,
                                    ),
                                    title: Text(
                                      p.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'IP: ${p.ip}  •  Port: ${p.port} (Hazır)',
                                      style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.info_outline_rounded, size: 18),
                                          color: Colors.grey.shade500,
                                          tooltip: 'Cihaz Detayları',
                                          onPressed: () {
                                            PrinterDetailModal.show(
                                              context,
                                              printer: p,
                                              onPrinterSelected: () {
                                                setSheetState(() => _selectedNetworkPrinter = p);
                                                setState(() => _selectedNetworkPrinter = p);
                                              },
                                            );
                                          },
                                        ),
                                        isSelected
                                            ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue)
                                            : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                                      ],
                                    ),
                                    onTap: () async {
                                      setSheetState(() => _selectedNetworkPrinter = p);
                                      setState(() => _selectedNetworkPrinter = p);
                                      await SaveSettings.savePrinterSettings(
                                        tip: 'Ağ / IP Yazıcı',
                                        ad: p.name,
                                        ip: p.ip ?? '',
                                        port: p.port,
                                        kagiz: _paperWidth,
                                      );
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                side: BorderSide(color: AppTheme.accentGreen.withValues(alpha: 0.4), width: 1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              onPressed: _testPrinterConnection,
                              icon: const Icon(Icons.print_rounded, size: 18),
                              label: const Text(
                                'Ağ Sınama Baskısı Gönder',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ] else ...[
                        // Bluetooth & System Printers Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Eşleşen Cihazlar (${_realBluetoothPrinters.length})',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: _isScanningPrinters ? null : () async {
                                setSheetState(() => _isScanningPrinters = true);
                                await _scanBluetoothPrinters();
                                setSheetState(() => _isScanningPrinters = false);
                                setState(() {});
                              },
                              icon: _isScanningPrinters
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(_isScanningPrinters ? 'Taranıyor...' : 'Cihazları Tara'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryBlue,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        if (_realBluetoothPrinters.isEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bluetooth_searching_rounded, color: Colors.orange, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Cihaza bağlı Bluetooth veya sistem yazıcısı bulunamadı. Lütfen Bluetooth eşleşmelerinizi kontrol edip "Cihazları Tara" butonuna basınız.',
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Column(
                            children: _realBluetoothPrinters.map((p) {
                              final isSelected = (_selectedRealBluetooth?.name == p.name) ||
                                  (_selectedRealBluetooth == null && _realBluetoothPrinters.first.name == p.name);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: isSelected
                                      ? AppTheme.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.08)
                                      : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: isSelected ? AppTheme.primaryBlue : (isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    onLongPress: () {
                                      PrinterDetailModal.show(
                                        context,
                                        printer: p,
                                        onPrinterSelected: () {
                                          setSheetState(() => _selectedRealBluetooth = p);
                                          setState(() => _selectedRealBluetooth = p);
                                        },
                                      );
                                    },
                                    leading: Icon(
                                      Icons.print_rounded,
                                      color: isSelected ? AppTheme.primaryBlue : Colors.grey,
                                    ),
                                    title: Text(
                                      p.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Basılı tutun • Detayları gör',
                                      style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.info_outline_rounded, size: 18),
                                          color: Colors.grey.shade500,
                                          tooltip: 'Cihaz Detayları',
                                          onPressed: () {
                                            PrinterDetailModal.show(
                                              context,
                                              printer: p,
                                              onPrinterSelected: () {
                                                setSheetState(() => _selectedRealBluetooth = p);
                                                setState(() => _selectedRealBluetooth = p);
                                              },
                                            );
                                          },
                                        ),
                                        isSelected
                                            ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue)
                                            : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                                      ],
                                    ),
                                    onTap: () async {
                                      setSheetState(() => _selectedRealBluetooth = p);
                                      setState(() => _selectedRealBluetooth = p);
                                      await SaveSettings.savePrinterSettings(
                                        tip: 'Bluetooth / Sistem Yazıcısı',
                                        ad: p.name,
                                        ip: SaveSettings.seciliYaziciIp,
                                        port: SaveSettings.seciliYaziciPort,
                                        kagiz: _paperWidth,
                                      );
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: BorderSide(color: AppTheme.accentGreen.withValues(alpha: 0.4), width: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: _testPrinterConnection,
                            icon: const Icon(Icons.print_rounded, size: 18),
                            label: const Text('Bluetooth / Sistem Sınama Baskısı', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.35), width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {});
                          },
                          child: Text(
                            context.tr('kaydet_ve_kapat', 'Ayarları Kaydet ve Kapat'),
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  Widget _buildSheetPaperChip(String val, String label, IconData icon, bool isDark, StateSetter setSheetState) {
    final isSelected = _paperWidth == val;
    return InkWell(
      onTap: () {
        setSheetState(() => _paperWidth = val);
        setState(() => _paperWidth = val);
        SaveSettings.yaziciKagizGenislik = val;
        SaveSettings.savePrinterSettings(
          tip: _printerType,
          ad: _printerType == 'Ağ / IP Yazıcı'
              ? (_selectedNetworkPrinter?.name ?? 'Ağ Yazıcısı')
              : (_selectedRealBluetooth?.name ?? 'Bluetooth Yazıcı'),
          ip: _selectedNetworkPrinter?.ip ?? SaveSettings.seciliYaziciIp,
          port: _selectedNetworkPrinter?.port ?? SaveSettings.seciliYaziciPort,
          kagiz: val,
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : (isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppTheme.primaryBlue : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.primaryBlue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
