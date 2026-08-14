import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/storage/save_settings.dart';

class AppLocalizations {
  final Locale locale;
  static Map<String, String> _localizedStrings = {};
  static Map<String, String> _normalizedMap = {};

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _embeddedDefaults = {
    'tr': {
      'app_name': 'BYM 360',
      'girisyap': 'Giriş Yap',
      'kullanicikodu': 'Kullanıcı Kodu',
      'kullaniciadi': 'Kullanıcı Adı',
      'sifre': 'Şifre',
      'benihatirla': 'Beni Hatırla',
      'depoyonetimi': 'Depo Yönetimi',
      'urunyonetimi': 'Ürün Yönetimi',
      'siparisyonetimi': 'Sipariş Yönetimi',
      'finansyonetimi': 'Finans Yönetimi',
      'fiyatgor': 'Fiyat Gör',
      'stokislem': 'Stok İşlemleri',
      'isajandasi': 'İş Ajandası',
      'cariekstre': 'Cari Ekstre',
      'ambarislemleri': 'Ambar İşlemleri',
      'siparissevkiyat': 'Sipariş Sevkiyat',
      'belgekapat': 'Belge Kapatma',
      'firmasecimi': 'Firma Seçimi',
      'firmadegistir': 'Firma Değiştir',
      'sistemayarlari': 'Sistem Ayarları',
      'dilayarlari': 'Dil Ayarları',
      'sayimayarlari': 'Sayım Ayarları',
      'depotransferayarlari': 'Depo Transfer Ayarları',
      'malkabulayarlari': 'Mal Kabul Ayarları',
      'satisayarlari': 'Satış Ayarları',
      'siparisayarlari': 'Sipariş Ayarları',
      'stokayarlari': 'Stok Ayarları',
      'kullaniciayarlari': 'Kullanıcı Ayarları',
      'modulanasayfaayarlari': 'Modül Anasayfa Ayarları',
      'gecemodunuaktifestir': 'Gece modunu aktif eder',
      'uygulamadili': 'Uygulama dili',
      'sayimmodulparametreleri': 'Sayım modül parametreleri',
      'transfermodulparametreleri': 'Transfer modül parametreleri',
      'kabulmodulparametreleri': 'Kabul modül parametreleri',
      'satisiskontoparametreleri': 'Satış & iskonto parametreleri',
      'siparismodulparametreleri': 'Sipariş modül parametreleri',
      'stokaramafiltrelemeparametreleri': 'Stok arama & filtreleme parametreleri',
      'kullanicibilgilerioturum': 'Kullanıcı bilgileri & oturum',
      'anamenumodulgorunurlugu': 'Ana menü modül görünürlüğü',
      'uygulamaversiyonu': 'Uygulama Versiyonu',
      'karanliktema': 'Karanlık Tema',
      'cikis': 'Çıkış Yap',
      'iptal': 'İptal',
      'tamam': 'Tamam',
      'onayla': 'Onayla',
      'kaydet': 'Kaydet',
      'hakkinda': 'Hakkında',
      'bildirimler': 'Bildirimler',
      'moduller': 'Modüller & Hizmetler',
      'aktifmodul': 'Aktif Modül',
      'sayim': 'Sayım',
      'malkabul': 'Mal Kabul',
      'transfer': 'Transfer',
      'stoklar': 'Stoklar',
      'etiketleme': 'Etiketleme',
      'teslimat': 'Teslimat & Sevk',
      'tahsilat': 'Tahsilat & Ekstre',
      'depoistekgonderim': 'Depo İstek Gönderim',
      'ambarkontrollusevk': 'Ambar & Kontrollü Sevk',
      'kayitlibelgeler': 'Kayıtlı Belgeler',
      'yenibelgeolustur': 'Yeni Belge Oluştur',
      'baskionizleme': 'Baskı Önizleme',
      'yazdir': 'Yazdır',
      'yazici_sec': 'Yazıcı Seç',
      'sinama_yazdir': 'Sınama Yazdır',
      'kagit_formati': 'Kağıt Formatı',
      'modul': 'Hizmet / Modül',
      'yenile': 'Yenile',
    },
    'en': {
      'app_name': 'BYM 360',
      'girisyap': 'Login',
      'kullanicikodu': 'User Code',
      'kullaniciadi': 'Username',
      'sifre': 'Password',
      'benihatirla': 'Remember Me',
      'depoyonetimi': 'Warehouse Management',
      'urunyonetimi': 'Product Management',
      'siparisyonetimi': 'Order Management',
      'finansyonetimi': 'Finance Management',
      'fiyatgor': 'Price Check',
      'stokislem': 'Stock Operations',
      'isajandasi': 'Work Agenda',
      'cariekstre': 'Account Statement',
      'ambarislemleri': 'Warehouse Operations',
      'siparissevkiyat': 'Order Shipment',
      'belgekapat': 'Close Document',
      'firmasecimi': 'Company Selection',
      'firmadegistir': 'Change Company',
      'sistemayarlari': 'System Settings',
      'dilayarlari': 'Language Settings',
      'depoistekgonderim': 'Warehouse Transfer Shipment',
      'ambarkontrollusevk': 'Warehouse & Controlled Transfer',
      'kayitlibelgeler': 'Saved Documents',
      'yenibelgeolustur': 'Create New Document',
      'sayimayarlari': 'Inventory Settings',
      'depotransferayarlari': 'Transfer Settings',
      'malkabulayarlari': 'Goods Receipt Settings',
      'satisayarlari': 'Sales Settings',
      'siparisayarlari': 'Order Settings',
      'stokayarlari': 'Stock Settings',
      'kullaniciayarlari': 'User Settings',
      'modulanasayfaayarlari': 'Homepage Module Settings',
      'gecemodunuaktifestir': 'Enables dark mode',
      'uygulamadili': 'App Language',
      'sayimmodulparametreleri': 'Stock count module parameters',
      'transfermodulparametreleri': 'Warehouse transfer parameters',
      'kabulmodulparametreleri': 'Goods receipt parameters',
      'satisiskontoparametreleri': 'Sales & discount parameters',
      'siparismodulparametreleri': 'Order module parameters',
      'stokaramafiltrelemeparametreleri': 'Stock search & filter parameters',
      'kullanicibilgilerioturum': 'User details & session',
      'anamenumodulgorunurlugu': 'Home menu module visibility',
      'uygulamaversiyonu': 'Application Version',
      'karanliktema': 'Dark Mode',
      'cikis': 'Logout',
      'iptal': 'Cancel',
      'tamam': 'OK',
      'onayla': 'Confirm',
      'kaydet': 'Save',
      'hakkinda': 'About',
      'bildirimler': 'Notifications',
      'moduller': 'Modules & Services',
      'aktifmodul': 'Active Modules',
      'sayim': 'Count',
      'malkabul': 'Goods Receipt',
      'transfer': 'Transfer',
      'stoklar': 'Stocks',
      'etiketleme': 'Labeling',
      'teslimat': 'Delivery & Shipping',
      'tahsilat': 'Collection & Statement',
      'baskionizleme': 'Print Preview',
      'yazdir': 'Print',
      'yazici_sec': 'Select Printer',
      'sinama_yazdir': 'Test Print',
      'kagit_formati': 'Paper Format',
      'modul': 'Service / Module',
      'yenile': 'Refresh',
    },
    'de': {
      'app_name': 'BYM 360',
      'girisyap': 'Anmelden',
      'kullanicikodu': 'Benutzercode',
      'kullaniciadi': 'Benutzername',
      'sifre': 'Passwort',
      'benihatirla': 'Erinnere mich',
      'depoyonetimi': 'Lagerverwaltung',
      'urunyonetimi': 'Produktverwaltung',
      'siparisyonetimi': 'Auftragsverwaltung',
      'finansyonetimi': 'Finanzverwaltung',
      'fiyatgor': 'Preisabfrage',
      'stokislem': 'Artikelvorgänge',
      'isajandasi': 'Arbeitsagenda',
      'cariekstre': 'Kontoauszug',
      'ambarislemleri': 'Lagerabwicklung',
      'siparissevkiyat': 'Auftragsversand',
      'belgekapat': 'Belegabschluss',
      'firmasecimi': 'Firma-Auswahl',
      'firmadegistir': 'Firma wechseln',
      'sistemayarlari': 'Systemeinstellungen',
      'dilayarlari': 'Spracheinstellungen',
      'sayimayarlari': 'Inventureinstellungen',
      'depotransferayarlari': 'Umlagerungseinstellungen',
      'malkabulayarlari': 'Wareneingangseinstellungen',
      'satisayarlari': 'Verkaufseinstellungen',
      'siparisayarlari': 'Bestelleinstellungen',
      'stokayarlari': 'Bestandseinstellungen',
      'kullaniciayarlari': 'Benutzereinstellungen',
      'modulanasayfaayarlari': 'Startseiten-Moduleinstellungen',
      'gecemodunuaktifestir': 'Aktiviert den Nachtmodus',
      'uygulamadili': 'App-Sprache',
      'sayimmodulparametreleri': 'Parameter für Inventurmodul',
      'transfermodulparametreleri': 'Parameter für Lagertransfer',
      'kabulmodulparametreleri': 'Parameter für Wareneingang',
      'satisiskontoparametreleri': 'Parameter für Verkauf & Rabatt',
      'siparismodulparametreleri': 'Parameter für Bestellmodul',
      'stokaramafiltrelemeparametreleri': 'Such- und Filterparameter',
      'kullanicibilgilerioturum': 'Benutzerdetails & Sitzung',
      'anamenumodulgorunurlugu': 'Modulsichtbarkeit im Hauptmenü',
      'uygulamaversiyonu': 'Anwendungsversion',
      'karanliktema': 'Dunkler Modus',
      'cikis': 'Abmelden',
      'iptal': 'Abbrechen',
      'tamam': 'OK',
      'onayla': 'Bestätigen',
      'kaydet': 'Speichern',
      'hakkinda': 'Über',
      'bildirimler': 'Benachrichtigungen',
      'moduller': 'Module & Dienste',
      'aktifmodul': 'Aktive Module',
      'sayim': 'Inventur',
      'malkabul': 'Warenannahme',
      'transfer': 'Transfer',
      'stoklar': 'Bestände',
      'etiketleme': 'Etikettierung',
      'teslimat': 'Lieferung & Versand',
      'tahsilat': 'Einzug & Auszug',
      'baskionizleme': 'Druckvorschau',
      'yazdir': 'Drucken',
      'yazici_sec': 'Drucker auswählen',
      'sinama_yazdir': 'Testdruck',
      'kagit_formati': 'Papierformat',
      'modul': 'Dienst / Modul',
      'yenile': 'Aktualisieren',
    },
    'az': {
      'app_name': 'BYM 360',
      'girisyap': 'Daxil Ol',
      'kullanicikodu': 'İstifadəçi Kodu',
      'kullaniciadi': 'İstifadəçi Adı',
      'sifre': 'Şifrə',
      'benihatirla': 'Məni Xatırla',
      'depoyonetimi': 'Anbar İdarəetməsi',
      'urunyonetimi': 'Məhsul İdarəetməsi',
      'siparisyonetimi': 'Sifariş İdarəetməsi',
      'finansyonetimi': 'Maliyyə İdarəetməsi',
      'fiyatgor': 'Qiymətə Bax',
      'stokislem': 'Stok Əməliyyatları',
      'isajandasi': 'İş Qrafiki',
      'cariekstre': 'Hesab Çıxarışı',
      'ambarislemleri': 'Anbar Əməliyyatları',
      'siparissevkiyat': 'Sifariş Göndərişi',
      'belgekapat': 'Sənəd Bağlanışı',
      'firmasecimi': 'Firma Seçimi',
      'firmadegistir': 'Firma Dəyişdir',
      'sistemayarlari': 'Sistem Parametrləri',
      'dilayarlari': 'Dil Parametrləri',
      'sayimayarlari': 'Sayım Parametrləri',
      'depotransferayarlari': 'Anbar Transferi Parametrləri',
      'malkabulayarlari': 'Mal Qəbulu Parametrləri',
      'satisayarlari': 'Satış Parametrləri',
      'siparisayarlari': 'Sifariş Parametrləri',
      'stokayarlari': 'Stok Parametrləri',
      'kullaniciayarlari': 'İstifadəçi Parametrləri',
      'modulanasayfaayarlari': 'Əsas Səhifə Modul Parametrləri',
      'gecemodunuaktifestir': 'Gecə rejimini aktivləşdirir',
      'uygulamadili': 'Tətbiq dili',
      'sayimmodulparametreleri': 'Sayım modulu parametrləri',
      'transfermodulparametreleri': 'Transfer modulu parametrləri',
      'kabulmodulparametreleri': 'Qəbul modulu parametrləri',
      'satisiskontoparametreleri': 'Satış və endirim parametrləri',
      'siparismodulparametreleri': 'Sifariş modulu parametrləri',
      'stokaramafiltrelemeparametreleri': 'Axtarış və filtr parametrləri',
      'kullanicibilgilerioturum': 'İstifadəçi məlumatları və seans',
      'anamenumodulgorunurlugu': 'Əsas menyu modul görünürlüyü',
      'uygulamaversiyonu': 'Tətbiq Versiyası',
      'karanliktema': 'Qaranlıq Tema',
      'cikis': 'Çıxış',
      'iptal': 'İmtina',
      'tamam': 'Tamam',
      'onayla': 'Təsdiqlə',
      'kaydet': 'Yadda Saxla',
      'hakkinda': 'Haqqında',
      'bildirimler': 'Bildirişlər',
      'moduller': 'Modullar və Xidmətlər',
      'aktifmodul': 'Aktiv Modul',
      'sayim': 'Sayım',
      'malkabul': 'Mal Qəbulu',
      'transfer': 'Transfer',
      'stoklar': 'Stoklar',
      'etiketleme': 'Etiketləmə',
      'teslimat': 'Çatdırılma və Göndəriş',
      'tahsilat': 'Yığım və Çıxarış',
      'baskionizleme': 'Çap Önizləməsi',
      'yazdir': 'Çap Et',
      'yazici_sec': 'Yazıcı Seç',
      'sinama_yazdir': 'Sınaq Çapı',
      'kagit_formati': 'Kağız Formatı',
      'modul': 'Xidmət / Modul',
      'yenile': 'Yenilə',
    },
  };

  static String _normalizeKey(String key) {
    return key
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<bool> load() async {
    try {
      final jsonString = await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });

      _normalizedMap = {};
      _localizedStrings.forEach((key, value) {
        final norm = _normalizeKey(key);
        _normalizedMap[norm] = value;
      });

      return true;
    } catch (e) {
      _localizedStrings = {};
      _normalizedMap = {};
      return false;
    }
  }

  static String _cleanString(String val) {
    if (val.isEmpty) return val;
    return val
        .replaceAll(RegExp(r'&#x[0-9a-fA-F]+;?'), '')
        .replaceAll(RegExp(r'&#[0-9]+;?'), '')
        .replaceAll('"', '')
        .replaceAll('\\', '')
        .replaceAll('Â', '')
        .trim();
  }

  String translate(String key, [String? defaultValue]) {
    if (key.isEmpty) return _cleanString(defaultValue ?? key);

    String? res;

    // 1. Direct match in loaded JSON
    if (_localizedStrings.containsKey(key)) {
      res = _localizedStrings[key];
    }

    // 2. Normalized match in loaded JSON
    if (res == null) {
      final normKey = _normalizeKey(key);
      if (_normalizedMap.containsKey(normKey)) {
        res = _normalizedMap[normKey];
      }
    }

    // 3. Match in embedded defaults for current language
    if (res == null) {
      final langCode = locale.languageCode;
      if (_embeddedDefaults.containsKey(langCode)) {
        final langDefaults = _embeddedDefaults[langCode]!;
        if (langDefaults.containsKey(key)) {
          res = langDefaults[key];
        } else {
          final normKey = _normalizeKey(key);
          if (langDefaults.containsKey(normKey)) {
            res = langDefaults[normKey];
          }
        }
      }
    }

    // 4. Match in embedded defaults for English if current is not English
    if (res == null) {
      final langCode = locale.languageCode;
      if (langCode != 'en' && _embeddedDefaults.containsKey('en')) {
        final enDefaults = _embeddedDefaults['en']!;
        if (enDefaults.containsKey(key)) {
          res = enDefaults[key];
        } else {
          final normKey = _normalizeKey(key);
          if (enDefaults.containsKey(normKey)) {
            res = enDefaults[normKey];
          }
        }
      }
    }

    return _cleanString(res ?? defaultValue ?? key);
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['tr', 'en', 'de', 'az'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizationExtension on BuildContext {
  String tr(String key, [String? defaultValue]) {
    final appLoc = AppLocalizations.of(this);
    if (appLoc != null) {
      return appLoc.translate(key, defaultValue);
    }
    final code = SaveSettings.selectedLanguage;
    final defaults = AppLocalizations._embeddedDefaults[code] ?? AppLocalizations._embeddedDefaults['tr']!;
    final norm = AppLocalizations._normalizeKey(key);
    final raw = defaults[key] ?? defaults[norm] ?? defaultValue ?? key;
    return AppLocalizations._cleanString(raw);
  }
}

extension StringLocalizationExtension on String {
  String tr([String? defaultValue]) {
    final code = SaveSettings.selectedLanguage;
    final defaults = AppLocalizations._embeddedDefaults[code] ?? AppLocalizations._embeddedDefaults['tr']!;
    final norm = AppLocalizations._normalizeKey(this);
    final raw = defaults[this] ?? defaults[norm] ?? defaultValue ?? this;
    return AppLocalizations._cleanString(raw);
  }
}
