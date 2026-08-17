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
      // Bildirimler & Belge Detay
      'tumu': 'Tümü',
      'okunmamis': 'Okunmamış',
      'sistem': 'Sistem',
      'bildirim_bulunamadi': 'Herhangi bir bildirim bulunamadı.',
      'tum_bildirimler_okundu': 'Tüm bildirimler okundu olarak işaretlendi.',
      'basarili': 'Başarılı',
      'tumunu_okundu_isaretle': 'Tümünü Okundu İşaretle',
      'tarih': 'Tarih',
      'kapat': 'Kapat',
      'belge_onay': 'Belge Onay',
      'onay_iptal': 'Onay İptal',
      'belge_onizle_yazdir': 'Belge Önizle & Yazdır',
      'belge_kapat_tahsilat': 'Belge Kapat / Tahsilat',
      'urun_satirlari': 'Ürün Satırları',
      'toplam_miktar': 'Toplam Miktar',
      'belgede_urun_yok': 'Bu belgede henüz ürün yok.',
      'urun_ekle': 'ÜRÜN EKLE',
      'onayli_belge_satir_silinemez': 'Onaylı belgelerde satır silinemez.',
      'belge_onayli': 'Belge Onaylı',
      'satir_silinsin_mi': 'Satır Silinsin mi?',
      'satir_belgeden_silinecek': 'satırı belgeden silinecektir.',
      'vazgec': 'Vazgeç',
      'sil': 'Sil',
      'gecersiz_miktar': 'Geçersiz Miktar',
      'gecersiz_miktar_mesaj': 'Lütfen 0\'dan büyük bir miktar giriniz.',
      'satir_guncellendi': 'satırı başarıyla güncellendi.',
      'satir_guncellendi_baslik': 'Satır Güncellendi',
      'guncelleme_hatasi': 'Satır güncellenirken sunucudan hata alındı.',
      'guncelleme_basarisiz': 'Güncelleme Başarısız',
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
      // Notifications & Document Detail
      'tumu': 'All',
      'okunmamis': 'Unread',
      'sistem': 'System',
      'bildirim_bulunamadi': 'No notifications found.',
      'tum_bildirimler_okundu': 'All notifications marked as read.',
      'basarili': 'Success',
      'tumunu_okundu_isaretle': 'Mark All as Read',
      'tarih': 'Date',
      'kapat': 'Close',
      'belge_onay': 'Approve Document',
      'onay_iptal': 'Cancel Approval',
      'belge_onizle_yazdir': 'Preview & Print Document',
      'belge_kapat_tahsilat': 'Close Document / Collection',
      'urun_satirlari': 'Product Lines',
      'toplam_miktar': 'Total Quantity',
      'belgede_urun_yok': 'No products in this document yet.',
      'urun_ekle': 'ADD PRODUCT',
      'onayli_belge_satir_silinemez': 'Lines cannot be deleted from approved documents.',
      'belge_onayli': 'Document Approved',
      'satir_silinsin_mi': 'Delete Line?',
      'satir_belgeden_silinecek': 'line will be removed from the document.',
      'vazgec': 'Cancel',
      'sil': 'Delete',
      'gecersiz_miktar': 'Invalid Quantity',
      'gecersiz_miktar_mesaj': 'Please enter a quantity greater than 0.',
      'satir_guncellendi': 'line updated successfully.',
      'satir_guncellendi_baslik': 'Line Updated',
      'guncelleme_hatasi': 'Error received from server while updating line.',
      'guncelleme_basarisiz': 'Update Failed',
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
      // Benachrichtigungen & Dokumentdetail
      'tumu': 'Alle',
      'okunmamis': 'Ungelesen',
      'sistem': 'System',
      'bildirim_bulunamadi': 'Keine Benachrichtigungen gefunden.',
      'tum_bildirimler_okundu': 'Alle Benachrichtigungen als gelesen markiert.',
      'basarili': 'Erfolgreich',
      'tumunu_okundu_isaretle': 'Alle als gelesen markieren',
      'tarih': 'Datum',
      'kapat': 'Schließen',
      'belge_onay': 'Beleg genehmigen',
      'onay_iptal': 'Genehmigung widerrufen',
      'belge_onizle_yazdir': 'Beleg anzeigen & drucken',
      'belge_kapat_tahsilat': 'Beleg schließen / Einzug',
      'urun_satirlari': 'Produktzeilen',
      'toplam_miktar': 'Gesamtmenge',
      'belgede_urun_yok': 'Noch keine Produkte in diesem Beleg.',
      'urun_ekle': 'PRODUKT HINZUFÜGEN',
      'onayli_belge_satir_silinemez': 'Zeilen aus genehmigten Belegen können nicht gelöscht werden.',
      'belge_onayli': 'Beleg genehmigt',
      'satir_silinsin_mi': 'Zeile löschen?',
      'satir_belgeden_silinecek': 'Zeile wird aus dem Beleg entfernt.',
      'vazgec': 'Abbrechen',
      'sil': 'Löschen',
      'gecersiz_miktar': 'Ungültige Menge',
      'gecersiz_miktar_mesaj': 'Bitte geben Sie eine Menge größer als 0 ein.',
      'satir_guncellendi': 'Zeile wurde erfolgreich aktualisiert.',
      'satir_guncellendi_baslik': 'Zeile aktualisiert',
      'guncelleme_hatasi': 'Serverfehler beim Aktualisieren der Zeile.',
      'guncelleme_basarisiz': 'Aktualisierung fehlgeschlagen',
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
      // Bildirişlər & Sənəd Detalları
      'tumu': 'Hamısı',
      'okunmamis': 'Oxunmamış',
      'sistem': 'Sistem',
      'bildirim_bulunamadi': 'Heç bir bildiriş tapılmadı.',
      'tum_bildirimler_okundu': 'Bütün bildirişlər oxunmuş olaraq işarələndi.',
      'basarili': 'Uğurlu',
      'tumunu_okundu_isaretle': 'Hamısını oxunmuş işarələ',
      'tarih': 'Tarix',
      'kapat': 'Bağla',
      'belge_onay': 'Sənəd Təsdiqi',
      'onay_iptal': 'Təsdiq Ləğvi',
      'belge_onizle_yazdir': 'Sənədi önizlə və çap et',
      'belge_kapat_tahsilat': 'Sənədi bağla / Yığım',
      'urun_satirlari': 'Məhsul Sətirləri',
      'toplam_miktar': 'Ümumi Say',
      'belgede_urun_yok': 'Bu sənəddə hələ məhsul yoxdur.',
      'urun_ekle': 'MƏHSUL ƏLAVƏ ET',
      'onayli_belge_satir_silinemez': 'Təsdiqlənmiş sənədlərdən sətir silinə bilməz.',
      'belge_onayli': 'Sənəd Təsdiqlənib',
      'satir_silinsin_mi': 'Sətir silinsin?',
      'satir_belgeden_silinecek': 'sətri sənəddən silinəcəkdir.',
      'vazgec': 'İmtina',
      'sil': 'Sil',
      'gecersiz_miktar': 'Yanlış Say',
      'gecersiz_miktar_mesaj': 'Zəhmət olmasa 0-dan böyük say daxil edin.',
      'satir_guncellendi': 'sətri uğurla yeniləndi.',
      'satir_guncellendi_baslik': 'Sətir Yeniləndi',
      'guncelleme_hatasi': 'Sətri yeniləyərkən serverdən xəta alındı.',
      'guncelleme_basarisiz': 'Yeniləmə Uğursuz',
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
