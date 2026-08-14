import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/storage/save_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/printer_service.dart';
import 'sistem_ayarlari_view.dart';

// ============================================================
// Dil Ayarları (Activity_DilAyarlari)
// ============================================================
class DilAyarlariView extends StatefulWidget {
  const DilAyarlariView({super.key});

  @override
  State<DilAyarlariView> createState() => _DilAyarlariViewState();
}

class _DilAyarlariViewState extends State<DilAyarlariView> {
  late String _selected;

  final List<Map<String, String>> _languages = [
    {'code': 'tr', 'name': 'Türkçe', 'native': 'Türkçe', 'tag': 'TR', 'region': 'Türkiye (TR)'},
    {'code': 'en', 'name': 'English', 'native': 'English', 'tag': 'EN', 'region': 'Global / International (EN)'},
    {'code': 'de', 'name': 'Deutsch', 'native': 'Deutsch', 'tag': 'DE', 'region': 'Deutschland (DE)'},
    {'code': 'az', 'name': 'Azərbaycan Türkçəsi', 'native': 'Azərbaycan dili', 'tag': 'AZ', 'region': 'Azərbaycan (AZ)'},
  ];

  @override
  void initState() {
    super.initState();
    _selected = SaveSettings.selectedLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('dilayarlari', 'Dil & Bölge Ayarları'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [

          Text(
            'Desteklenen Diller',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlue),
          ),
          const SizedBox(height: 10),

          ..._languages.map((lang) {
            final code = lang['code']!;
            final name = lang['name']!;
            final native = lang['native']!;
            final tag = lang['tag']!;
            final region = lang['region']!;
            final isSelected = _selected == code;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryBlue : (isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryBlue.withValues(alpha: 0.15)
                        : (isDark ? Colors.white10 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryBlue : (isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tag,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? AppTheme.primaryBlue : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        native,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (name != native) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '($name)',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(region, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                trailing: isSelected
                    ? Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                      )
                    : const Icon(Icons.radio_button_unchecked_rounded, color: Colors.grey),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  setState(() => _selected = code);
                  await SaveSettings.setLanguage(code);
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Uygulama dili değiştirildi: $native'),
                        backgroundColor: AppTheme.accentGreen,
                      ),
                    );
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================
// Sayım Ayarları (Activity_SayimAyarlari)
// ============================================================
class SayimAyarlariView extends StatefulWidget {
  const SayimAyarlariView({super.key});

  @override
  State<SayimAyarlariView> createState() => _SayimAyarlariViewState();
}

class _SayimAyarlariViewState extends State<SayimAyarlariView> {
  String _fiyatOnDeger = 'Alış Fiyatı';
  bool _miktarKontrol = true;
  bool _otomatikBarkod = false;
  bool _ciftOkutmaEngeli = true;

  final List<String> _fiyatTurleri = [
    'Alış Fiyatı',
    'Satış Fiyatı',
    'Son Alış Fiyatı',
    'Son Satış Fiyatı',
    'Ortalama Maliyet',
    'Son Maliyet',
  ];

  void _saveSettings() {
    SaveSettings.sayimBirimFiyat = _fiyatOnDeger;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sayım ayarları başarıyla kaydedildi.'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Sayım Ayarları', 'Sayım Ayarları'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          ListTile(
            leading: const Icon(Icons.sell_rounded, color: AppTheme.primaryBlue),
            title: Text(context.tr('Sayım Birim Fiyat Ön Değeri', 'Sayım Birim Fiyat Ön Değeri'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(context.tr('Sayım evrakına eklenecek varsayılan birim fiyat', 'Sayım evrakına eklenecek varsayılan birim fiyat'), style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _fiyatOnDeger,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                items: _fiyatTurleri.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _fiyatOnDeger = val);
                },
              ),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.tr('Miktar Kontrol', 'Miktar Kontrol'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Okutulduğunda miktar doğrulaması yap', 'Okutulduğunda miktar doğrulaması yap')),
            value: _miktarKontrol,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _miktarKontrol = val),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.tr('Otomatik Barkod Gönder', 'Otomatik Barkod Gönder'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Barkod okutulduğunda doğrudan ekle', 'Barkod okutulduğunda doğrudan ekle')),
            value: _otomatikBarkod,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _otomatikBarkod = val),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.tr('Çift Okutma Engeli', 'Çift Okutma Engeli'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Aynı barkod tekrar okutulduğunda uyar', 'Aynı barkod tekrar okutulduğunda uyar')),
            value: _ciftOkutmaEngeli,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _ciftOkutmaEngeli = val),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.35), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(context.tr('kaydet', 'SAYIM AYARLARINI KAYDET'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Depo Transfer Ayarları (Activity_DepoTransferAyarlari)
// ============================================================
class DepoTransferAyarlariView extends StatefulWidget {
  const DepoTransferAyarlariView({super.key});

  @override
  State<DepoTransferAyarlariView> createState() => _DepoTransferAyarlariViewState();
}

class _DepoTransferAyarlariViewState extends State<DepoTransferAyarlariView> {
  String _fiyatOnDeger = 'Alış Fiyatı';
  String _miktarKontrol = 'Kontrol Var';
  bool _kontrolluTransfer = true;
  bool _otomatikVaris = false;

  final List<String> _fiyatTurleri = ['Alış Fiyatı', 'Satış Fiyatı', 'Son Alış Fiyatı', 'Son Satış Fiyatı'];
  final List<String> _miktarKontrolModlari = ['Kontrol Var', 'Kontrol Yok'];

  void _saveSettings() {
    SaveSettings.depoTransferBirimFiyat = _fiyatOnDeger;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Depo transfer ayarları başarıyla kaydedildi.'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Depo Transfer Ayarları', 'Depo Transfer Ayarları'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          ListTile(
            leading: const Icon(Icons.sell_rounded, color: AppTheme.primaryBlue),
            title: Text(context.tr('Transfer Fiyat Ön Değeri', 'Transfer Fiyat Ön Değeri'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(context.tr('Transfer evrakında varsayılan fiyat', 'Transfer evrakında varsayılan fiyat'), style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _fiyatOnDeger,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                items: _fiyatTurleri.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _fiyatOnDeger = val);
                },
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.primaryBlue),
            title: Text(context.tr('Miktar Kontrol Modu', 'Miktar Kontrol Modu'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(context.tr('Transfer sırasında stok miktar kontrolü', 'Transfer sırasında stok miktar kontrolü'), style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _miktarKontrol,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                items: _miktarKontrolModlari.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _miktarKontrol = val);
                },
              ),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.tr('Kontrollü Transfer', 'Kontrollü Transfer'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Transfer barkod doğrulaması gerektirsin', 'Transfer barkod doğrulaması gerektirsin')),
            value: _kontrolluTransfer,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _kontrolluTransfer = val),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.tr('Otomatik Varış Depo Seçimi', 'Otomatik Varış Depo Seçimi'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Varsayılan varış deposu kullanılsın', 'Varsayılan varış deposu kullanılsın')),
            value: _otomatikVaris,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _otomatikVaris = val),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.35), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(context.tr('kaydet', 'TRANSFER AYARLARINI KAYDET'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Mal Kabul Ayarları (Activity_MalKabulAyarlari)
// ============================================================
class MalKabulAyarlariView extends StatefulWidget {
  const MalKabulAyarlariView({super.key});

  @override
  State<MalKabulAyarlariView> createState() => _MalKabulAyarlariViewState();
}

class _MalKabulAyarlariViewState extends State<MalKabulAyarlariView> {
  String _faturaFiyatOnDeger = 'Alış Fiyatı';
  String _irsaliyeFiyatOnDeger = 'Alış Fiyatı';
  String _fisFiyatOnDeger = 'Alış Fiyatı';
  bool _miktarKontrolu = true;
  bool _fiyatGoruntuleme = true;
  bool _otomatikEtiket = false;

  final List<String> _fiyatTurleri = ['Alış Fiyatı', 'Satış Fiyatı', 'Son Alış Fiyatı', 'Son Satış Fiyatı', 'Ortalama Maliyet'];

  void _saveSettings() {
    SaveSettings.malAlimFaturaBirimFiyat = _faturaFiyatOnDeger;
    SaveSettings.malAlimIrsaliyeBirimFiyat = _irsaliyeFiyatOnDeger;
    SaveSettings.malAlimFisBirimFiyat = _fisFiyatOnDeger;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mal kabul ayarları başarıyla kaydedildi.'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Mal Kabul Ayarları', 'Mal Kabul Ayarları'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          ListTile(
            leading: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryBlue),
            title: Text(context.tr('Fatura Kabul Fiyat Ön Değeri', 'Fatura Kabul Fiyat Ön Değeri'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _faturaFiyatOnDeger,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                items: _fiyatTurleri.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _faturaFiyatOnDeger = val);
                },
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.local_shipping_rounded, color: AppTheme.primaryBlue),
            title: Text(context.tr('İrsaliye Kabul Fiyat Ön Değeri', 'İrsaliye Kabul Fiyat Ön Değeri'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _irsaliyeFiyatOnDeger,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                items: _fiyatTurleri.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _irsaliyeFiyatOnDeger = val);
                },
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.subtitles_rounded, color: AppTheme.primaryBlue),
            title: Text(context.tr('Fiş Kabul Fiyat Ön Değeri', 'Fiş Kabul Fiyat Ön Değeri'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _fisFiyatOnDeger,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                items: _fiyatTurleri.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _fisFiyatOnDeger = val);
                },
              ),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.tr('Miktar Kontrolü', 'Miktar Kontrolü'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Gelen mal miktarını kontrol et', 'Gelen mal miktarını kontrol et')),
            value: _miktarKontrolu,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _miktarKontrolu = val),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.tr('Fiyat Görüntüleme', 'Fiyat Görüntüleme'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Kabul sırasında fiyat bilgisini göster', 'Kabul sırasında fiyat bilgisini göster')),
            value: _fiyatGoruntuleme,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _fiyatGoruntuleme = val),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.tr('Otomatik Etiket Bas', 'Otomatik Etiket Bas'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Kabul sonrası otomatik etiket yazdır', 'Kabul sonrası otomatik etiket yazdır')),
            value: _otomatikEtiket,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _otomatikEtiket = val),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.35), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(context.tr('kaydet', 'MAL KABUL AYARLARINI KAYDET'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Satış Ayarları (Activity_SatisAyarlari)
// ============================================================
class SatisAyarlariView extends StatefulWidget {
  const SatisAyarlariView({super.key});

  @override
  State<SatisAyarlariView> createState() => _SatisAyarlariViewState();
}

class _SatisAyarlariViewState extends State<SatisAyarlariView> {
  bool _stokKontrolu = true;
  bool _iskontoKullan = true;
  bool _riskLimiti = true;
  bool _fiyatDegistirme = false;

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Satış ayarları başarıyla kaydedildi.'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Satış Ayarları', 'Satış Ayarları'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          SwitchListTile(
            title: Text(context.tr('Stok Kontrolü', 'Stok Kontrolü'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Satış sırasında stok miktarını kontrol et', 'Satış sırasında stok miktarını kontrol et')),
            value: _stokKontrolu,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _stokKontrolu = val),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.tr('İskonto Kullan', 'İskonto Kullan'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Satır iskontosu uygulama izni', 'Satır iskontosu uygulama izni')),
            value: _iskontoKullan,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _iskontoKullan = val),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.tr('Cari Risk Limiti Kontrolü', 'Cari Risk Limiti Kontrolü'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Satış sırasında cari risk limitini kontrol et', 'Satış sırasında cari risk limitini kontrol et')),
            value: _riskLimiti,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _riskLimiti = val),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.tr('Fiyat Değiştirme İzni', 'Fiyat Değiştirme İzni'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Satış fiyatını kullanıcı değiştirebilsin', 'Satış fiyatını kullanıcı değiştirebilsin')),
            value: _fiyatDegistirme,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _fiyatDegistirme = val),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.35), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(context.tr('kaydet', 'SATIŞ AYARLARINI KAYDET'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Sipariş Ayarları (Activity_SiparisAyarlari)
// ============================================================
class SiparisAyarlariView extends StatefulWidget {
  const SiparisAyarlariView({super.key});

  @override
  State<SiparisAyarlariView> createState() => _SiparisAyarlariViewState();
}

class _SiparisAyarlariViewState extends State<SiparisAyarlariView> {
  bool _stokMiktari = true;
  bool _teslimTarihiZorunlu = false;
  bool _cariSiparisKontrol = true;

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sipariş ayarları başarıyla kaydedildi.'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Sipariş Ayarları', 'Sipariş Ayarları'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          SwitchListTile(
            title: Text(context.tr('Stok Miktarı Kontrolü', 'Stok Miktarı Kontrolü'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Siparişte stok miktarı yeterliliğini kontrol et', 'Siparişte stok miktarı yeterliliğini kontrol et')),
            value: _stokMiktari,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _stokMiktari = val),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.tr('Teslim Tarihi Zorunlu', 'Teslim Tarihi Zorunlu'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Sipariş oluştururken teslim tarihi girişi zorunlu olsun', 'Sipariş oluştururken teslim tarihi girişi zorunlu olsun')),
            value: _teslimTarihiZorunlu,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _teslimTarihiZorunlu = val),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.tr('Cari Sipariş Kontrolü', 'Cari Sipariş Kontrolü'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Aynı cariye açık sipariş varsa uyar', 'Aynı cariye açık sipariş varsa uyar')),
            value: _cariSiparisKontrol,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _cariSiparisKontrol = val),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.35), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(context.tr('kaydet', 'SİPARİŞ AYARLARINI KAYDET'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Stok Ayarları (Activity_StokAyarlari)
// ============================================================
class StokAyarlariView extends StatefulWidget {
  const StokAyarlariView({super.key});

  @override
  State<StokAyarlariView> createState() => _StokAyarlariViewState();
}

class _StokAyarlariViewState extends State<StokAyarlariView> {
  bool _akilliArama = true;
  bool _stokDetayi = true;
  bool _negatifStok = false;

  void _saveSettings() {
    SaveSettings.akilliArama = _akilliArama ? 'Açık' : 'Kapalı';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stok ayarları başarıyla kaydedildi.'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Stok Ayarları', 'Stok Ayarları'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          SwitchListTile(
            title: Text(context.tr('Akıllı Arama', 'Akıllı Arama'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Barkod ile birlikte stok adı/kodu araması da yap', 'Barkod ile birlikte stok adı/kodu araması da yap')),
            value: _akilliArama,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _akilliArama = val),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.tr('Stok Detayı Göster', 'Stok Detayı Göster'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Arama sonuçlarında detay bilgisini göster', 'Arama sonuçlarında detay bilgisini göster')),
            value: _stokDetayi,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _stokDetayi = val),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.tr('Negatif Stok İzni', 'Negatif Stok İzni'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(context.tr('Stok miktarı eksiye düşebilsin', 'Stok miktarı eksiye düşebilsin')),
            value: _negatifStok,
            activeTrackColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => _negatifStok = val),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.35), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(context.tr('kaydet', 'STOK AYARLARINI KAYDET'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Kullanıcı Ayarları (Activity_KullaniciAyarlari)
// ============================================================
class KullaniciAyarlariView extends StatefulWidget {
  const KullaniciAyarlariView({super.key});

  @override
  State<KullaniciAyarlariView> createState() => _KullaniciAyarlariViewState();
}

class _KullaniciAyarlariViewState extends State<KullaniciAyarlariView> {
  final TextEditingController _fisGunController = TextEditingController(text: '5');
  
  String _uyariSesi = 'Açık';
  String _kameraDurum = 'Otomatik Aç';
  String _titresim = 'Aktif';
  String _klavye = 'Otomatik Aç';
  String _faturaTuru = 'Açık Fatura';
  String _akilliArama = 'Açık';
  String _belgeListeleModu = 'Tüm Belgeler';
  
  // Bluetooth & Gerçek Yazıcı
  String _selectedPrinter = SaveSettings.seciliYaziciAdi;
  List<DiscoveredPrinter> _discoveredPrinters = [];
  bool _isScanningPrinters = false;

  // Hızlı İşlem Kısayolları
  String _hizliIslemZorunluluk = 'İsteğe Bağlı';
  List<bool> _secilenHizliIslemler = [true, true, true, true, true, true, true, true, true, true];

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
    _scanBluetoothDevices();
  }

  @override
  void dispose() {
    _fisGunController.dispose();
    super.dispose();
  }

  void _loadCurrentSettings() {
    if (SaveSettings.parametre > 0) {
      _fisGunController.text = SaveSettings.parametre.toString();
    }
    _akilliArama = SaveSettings.akilliArama != 'Kapalı' ? 'Açık' : 'Kapalı';
    _hizliIslemZorunluluk = SaveSettings.hizliIslemZorunlulugu ? 'Tüm Modüllerde Zorunlu' : 'İsteğe Bağlı';
    if (SaveSettings.secilenIslemler != null && SaveSettings.secilenIslemler!.length == 10) {
      _secilenHizliIslemler = List<bool>.from(SaveSettings.secilenIslemler!);
    }
  }

  Future<void> _scanBluetoothDevices() async {
    setState(() => _isScanningPrinters = true);
    final list = await PrinterService.getSystemAndBluetoothPrinters();
    if (mounted) {
      setState(() {
        _discoveredPrinters = list;
        _isScanningPrinters = false;
        if (list.isNotEmpty) {
          final existing = list.where((p) => p.name == SaveSettings.seciliYaziciAdi).firstOrNull;
          _selectedPrinter = existing != null ? existing.name : list.first.name;
        } else {
          _selectedPrinter = 'Kayıtlı Cihaz Yok';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(list.isEmpty
              ? 'Eşleşmiş Bluetooth cihazı bulunamadı. Lütfen Bluetooth ayarlarından eşleştiriniz.'
              : '✅ ${list.length} adet Bluetooth/Sistem yazıcısı bulundu.'),
          backgroundColor: list.isEmpty ? Colors.orange : AppTheme.primaryBlue,
        ),
      );
    }
  }

  void _showHizliIslemDialog() {
    final tempSecimler = List<bool>.from(_secilenHizliIslemler);

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
                      context.tr('hizlisecim', 'Hızlı İşlem Kısayolları'),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  context.tr('hizlisecim_sub', 'Evrak ve işlem ekranlarında gösterilecek hızlı işlem butonlarını seçiniz'),
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: SaveSettings.classHizliIslem.length,
                    itemBuilder: (context, index) {
                      return CheckboxListTile(
                        title: Text(
                          SaveSettings.classHizliIslem[index],
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        value: tempSecimler[index],
                        activeColor: AppTheme.primaryBlue,
                        onChanged: _hizliIslemZorunluluk == 'Tüm Modüllerde Zorunlu'
                            ? null
                            : (val) {
                                setModalState(() {
                                  tempSecimler[index] = val ?? false;
                                });
                              },
                      );
                    },
                  ),
                ),
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
                        _secilenHizliIslemler = tempSecimler;
                        SaveSettings.secilenIslemler = tempSecimler;
                      });
                      Navigator.pop(context);
                    },
                    child: Text(context.tr('onayla', 'Onayla ve Kaydet'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _saveAllUserSettings() {
    final fisGunStr = _fisGunController.text.trim();
    if (fisGunStr.isEmpty || (int.tryParse(fisGunStr) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fiş gün sayısı boş veya 0 olamaz!'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    final fisGun = int.parse(fisGunStr);
    SaveSettings.parametre = fisGun;
    SaveSettings.akilliArama = _akilliArama;
    SaveSettings.hizliIslemZorunlulugu = _hizliIslemZorunluluk == 'Tüm Modüllerde Zorunlu';
    SaveSettings.secilenIslemler = _secilenHizliIslemler;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kullanıcı ayarları başarıyla kaydedildi.'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int seciliHizliSayisi = _secilenHizliIslemler.where((e) => e).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('kullaniciayarlari', 'Kullanıcı Profil & Tercih Ayarları'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          _sectionTitle('Genel Evrak & Operasyon Tercihleri', isDark),
          const SizedBox(height: 10),

          // Fiş Gün Sayısı Input
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: TextField(
              controller: _fisGunController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.tr('edtfisgun', 'Evrak / Fiş Geçmiş Gün Sayısı'),
                hintText: 'Örn: 5',
                prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Uyarı Sesi
          _buildDropdownTile(
            title: 'Hata & Uyarı Sesi',
            subtitle: 'İşlem ve uyarı durumlarında sesli bildirim',
            icon: Icons.volume_up_rounded,
            value: _uyariSesi,
            items: ['Açık', 'Kapalı'],
            onChanged: (val) => setState(() => _uyariSesi = val!),
          ),

          // Kamera Durum
          _buildDropdownTile(
            title: 'Barkod Kamera Modu',
            subtitle: 'Evrak arayüzlerinde kamera okutucu durumu',
            icon: Icons.camera_alt_rounded,
            value: _kameraDurum,
            items: ['Otomatik Aç', 'Manuel Aç', 'Kapalı'],
            onChanged: (val) => setState(() => _kameraDurum = val!),
          ),

          // Titreşim
          _buildDropdownTile(
            title: 'Titreşimli Geri Bildirim',
            subtitle: 'Barkod okuma ve işlem onayında titreşim',
            icon: Icons.vibration_rounded,
            value: _titresim,
            items: ['Aktif', 'Pasif'],
            onChanged: (val) => setState(() => _titresim = val!),
          ),

          // Otomatik Klavye
          _buildDropdownTile(
            title: 'Otomatik Klavye Gösterimi',
            subtitle: 'Arama kutularına tıklanınca klavyeyi aç',
            icon: Icons.keyboard_rounded,
            value: _klavye,
            items: ['Otomatik Aç', 'Manuel Aç'],
            onChanged: (val) => setState(() => _klavye = val!),
          ),

          // Varsayılan Fatura Türü
          _buildDropdownTile(
            title: 'Varsayılan Belge Fatura Türü',
            subtitle: 'Fatura oluştururken varsayılan tür',
            icon: Icons.receipt_rounded,
            value: _faturaTuru,
            items: ['Açık Fatura', 'Kapalı Fatura', 'Muhtelif Fatura'],
            onChanged: (val) => setState(() => _faturaTuru = val!),
          ),

          // Akıllı Arama
          _buildDropdownTile(
            title: 'Akıllı Barkod & Stok Arama',
            subtitle: 'Barkod okuyucuda otomatik arama modu',
            icon: Icons.manage_search_rounded,
            value: _akilliArama,
            items: ['Açık', 'Kapalı'],
            onChanged: (val) => setState(() => _akilliArama = val!),
          ),

          // Belge Listeleme Modu
          _buildDropdownTile(
            title: 'Belge Listeleme Varsayılan Modu',
            subtitle: 'Belge listesinde varsayılan tarih filtresi',
            icon: Icons.filter_list_rounded,
            value: _belgeListeleModu,
            items: ['Tüm Belgeler', 'Bugünkü Belgeler'],
            onChanged: (val) => setState(() => _belgeListeleModu = val!),
          ),

          const SizedBox(height: 20),
          _sectionTitle('Bluetooth Yazıcı Bağlantısı', isDark),
          const SizedBox(height: 10),

          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bluetooth_rounded, color: AppTheme.primaryBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _discoveredPrinters.isEmpty
                            ? Text(_selectedPrinter, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600))
                            : DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _discoveredPrinters.any((p) => p.name == _selectedPrinter)
                                      ? _selectedPrinter
                                      : _discoveredPrinters.first.name,
                                  isExpanded: true,
                                  items: _discoveredPrinters.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name, style: GoogleFonts.inter(fontSize: 13)))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedPrinter = val);
                                      final selectedP = _discoveredPrinters.firstWhere((p) => p.name == val);
                                      SaveSettings.savePrinterSettings(
                                        tip: 'Bluetooth / Sistem Yazıcısı',
                                        ad: selectedP.name,
                                        ip: SaveSettings.seciliYaziciIp,
                                        port: SaveSettings.seciliYaziciPort,
                                        url: selectedP.url ?? '',
                                        kagiz: SaveSettings.yaziciKagizGenislik,
                                      );
                                    }
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isScanningPrinters ? null : _scanBluetoothDevices,
                      icon: _isScanningPrinters
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.bluetooth_searching_rounded, size: 18),
                      label: Text(_isScanningPrinters ? 'Cihazlar Taranıyor...' : context.tr('btntara', 'Bluetooth Cihazları Tara')),
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
          ),

          const SizedBox(height: 20),
          _sectionTitle('Hızlı İşlem Kısayolları', isDark),
          const SizedBox(height: 10),

          // Hızlı İşlem Zorunluluğu
          _buildDropdownTile(
            title: 'Hızlı İşlem Zorunluluğu',
            subtitle: 'Evrak ekranlarında kısayol zorunluluk modu',
            icon: Icons.flash_on_rounded,
            value: _hizliIslemZorunluluk,
            items: ['İsteğe Bağlı', 'Tüm Modüllerde Zorunlu'],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _hizliIslemZorunluluk = val;
                  if (val == 'Tüm Modüllerde Zorunlu') {
                    _secilenHizliIslemler = List.filled(10, true);
                  }
                });
              }
            },
          ),

          ListTile(
            title: Text(context.tr('hizlisecim', 'Hızlı İşlem Butonları'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(
              _hizliIslemZorunluluk == 'Tüm Modüllerde Zorunlu'
                  ? 'Tüm modüllerde açık (Zorunlu)'
                  : '$seciliHizliSayisi / ${_secilenHizliIslemler.length} modülde kısayol aktif',
              style: GoogleFonts.inter(fontSize: 12),
            ),
            leading: const Icon(Icons.tune_rounded, color: AppTheme.primaryBlue),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: _hizliIslemZorunluluk == 'Tüm Modüllerde Zorunlu' ? null : _showHizliIslemDialog,
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.35), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _saveAllUserSettings,
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(
                context.tr('kaydet', 'KULLANICI AYARLARINI KAYDET'),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Icon(icon, color: AppTheme.primaryBlue),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ============================================================
// Modül Anasayfa Ayarları (Activity_ModulAnasayfa)
// ============================================================
class ModulAnasayfaAyarlariView extends StatefulWidget {
  const ModulAnasayfaAyarlariView({super.key});

  @override
  State<ModulAnasayfaAyarlariView> createState() => _ModulAnasayfaAyarlariViewState();
}

class _ModulAnasayfaAyarlariViewState extends State<ModulAnasayfaAyarlariView> {
  final Map<String, bool> _modulStates = {
    'depoyonetimi': true,
    'urunyonetimi': true,
    'siparisyonetimi': true,
    'finansyonetimi': true,
    'fiyatgor': true,
    'stokislemleri': true,
    'isajandasi': true,
    'kullaniciraporu': true,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Modül Ayarları & Parametreleri', 'Modül Ayarları & Parametreleri'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          Text('Modül Parametre Ekranları', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlue)),
          const SizedBox(height: 10),

          _buildTile(
            context,
            title: context.tr('sayimayarlari', 'Sayım Ayarları'),
            subtitle: 'Sayım birim fiyatı ve miktar kontrol parametreleri',
            icon: Icons.fact_check_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SayimAyarlariView())),
          ),
          _buildTile(
            context,
            title: context.tr('depotransferayarlari', 'Depo Transfer Ayarları'),
            subtitle: 'Transfer miktar kontrolü ve fiyat ön değeri',
            icon: Icons.swap_horiz_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DepoTransferAyarlariView())),
          ),
          _buildTile(
            context,
            title: context.tr('malkabulayarlari', 'Mal Kabul Ayarları'),
            subtitle: 'Fatura, irsaliye ve fiş kabul fiyat parametreleri',
            icon: Icons.inventory_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MalKabulAyarlariView())),
          ),
          _buildTile(
            context,
            title: context.tr('satisayarlari', 'Satış Ayarları'),
            subtitle: 'Satış stok kontrolü, iskonto ve risk limiti',
            icon: Icons.receipt_long_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SatisAyarlariView())),
          ),
          _buildTile(
            context,
            title: context.tr('siparisayarlari', 'Sipariş Ayarları'),
            subtitle: 'Sipariş miktar ve teslim tarihi zorunlulukları',
            icon: Icons.shopping_bag_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SiparisAyarlariView())),
          ),
          _buildTile(
            context,
            title: context.tr('stokayarlari', 'Stok Ayarları'),
            subtitle: 'Akıllı stok arama, detay bilgisi ve negatif stok',
            icon: Icons.manage_search_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StokAyarlariView())),
          ),
          _buildTile(
            context,
            title: context.tr('sistemayarlari', 'Sistem & Arama Ayarları'),
            subtitle: 'Cari arama kriteri ve stok türü filtreleri',
            icon: Icons.tune_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SistemAyarlariView())),
          ),

          const SizedBox(height: 20),
          Text('Ana Menü Modül Görünürlüğü', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlue)),
          const SizedBox(height: 10),

          ..._modulStates.keys.map((key) => _modulSwitch(key, _getModulTitle(key))),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12)),
      leading: Icon(icon, color: AppTheme.primaryBlue),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }

  String _getModulTitle(String key) {
    switch (key) {
      case 'depoyonetimi': return 'Depo Yönetimi';
      case 'urunyonetimi': return 'Ürün Yönetimi';
      case 'siparisyonetimi': return 'Sipariş Yönetimi';
      case 'finansyonetimi': return 'Finans Yönetimi';
      case 'fiyatgor': return 'Fiyat Gör';
      case 'stokislemleri': return 'Stok İşlemleri';
      case 'isajandasi': return 'İş Ajandası';
      case 'kullaniciraporu': return 'Kullanıcı Raporu';
      default: return key;
    }
  }

  Widget _modulSwitch(String key, String defaultLabel) {
    final val = _modulStates[key] ?? true;
    return Column(
      children: [
        SwitchListTile(
          title: Text(context.tr(key, defaultLabel), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          subtitle: Text(context.tr('Ana menüde göster', 'Ana menüde göster')),
          value: val,
          activeTrackColor: AppTheme.primaryBlue,
          onChanged: (newVal) {
            setState(() {
              _modulStates[key] = newVal;
            });
          },
        ),
        const Divider(),
      ],
    );
  }
}

