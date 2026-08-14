import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';

enum CalismaModu { modBir, modIki }
enum DepoTurleri { merkezDepo, taliDepo, subeDepo, iadeDepo }

class SaveSettings {
  static final SaveSettings _instance = SaveSettings._internal();
  factory SaveSettings() => _instance;
  SaveSettings._internal();

  // ===== Temel Bağlantı =====
  static String sunucu = 'https://mobway.api.bym.gen.tr/';
  static String token = '';
  static String key = '';
  static String superUserPosta = '';
  static String superUserSifre = '';
  static String firma = '';
  static String cstring = '';
  static String macAdres = '';
  static String appVersionName = '';
  static int appVersionCode = 0;
  static String selectedLanguage = 'tr';
  static bool isDarkMode = false;
  static bool sesliUyariAktif = true;

  // ===== Reactive Notifiers =====
  static final ValueNotifier<bool> themeNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>('tr');
  static final ValueNotifier<bool> soundNotifier = ValueNotifier<bool>(true);

  // ===== Kullanıcı Bilgileri =====
  static int userId = 0;
  static int grupTur = 0;
  static String kullaniciKodu = '';
  static String kullaniciAdi = '';
  static String username = '';
  static int perID = 0;
  static int seciliPerID = 0;
  static String perAD = '';
  static int get perId => perID != 0 ? perID : userId;

  // ===== Şube =====
  static int subeId = 0;
  static String subeAdi = '';
  static String subeKodu = '';
  static String subeYetki = '';

  // ===== Depo =====
  static int depoId = 0;
  static String depoAdi = '';
  static String depoKodu = '';
  static int depoGiris = 1;
  static int depoCikis = 1;
  static String depoTip = '';
  static String depoYetki = '';

  // ===== Kontrollü Depo =====
  static int kontrolluDepoId = 0;
  static String kontrolluDepoAdi = '';
  static int kontrolluDepoGiris = 1;
  static int kontrolluDepoCikis = 1;

  // ===== Kasa =====
  static int kasaId = 0;
  static String kasaKodu = '';
  static String kasaAdi = '';
  static int kasaSube = 0;
  static String kasaYetki = '';

  // ===== Banka =====
  static int bankaId = 0;
  static String bankaKodu = '';
  static String bankaAdi = '';
  static int bankaSube = 0;
  static String bankaYetki = '';

  // ===== Yetki Alanları =====
  static String silYetki = '';
  static String belgeOnayYetki = '';
  static String belgeOnayIptalYetki = '';
  static int parametre = 0;
  static String yetkiSemaKullanim = '0';

  // ===== Fiyat Değiştirme Yetkileri =====
  static String fFiyatDegis = 'HAYIR';
  static String iFiyatDegis = 'HAYIR';
  static String vsFiyatDegis = 'EVET';
  static String asFiyatDegis = 'EVET';
  static String dipFiyat = '0';
  static int kurusHassasiyet = 0;

  // ===== Birim Fiyat Ayarları =====
  static String birimFiyatAramaTur = '33';
  static String birimFiyatEklemeTur = '@';
  static double birimFiyatUrun = 0.0;
  static String defaultBirimFiyat = '33';
  static String depoTransferBirimFiyat = '33';
  static String sayimBirimFiyat = '33';
  static String malAlimFaturaBirimFiyat = '33';
  static String malAlimIrsaliyeBirimFiyat = '33';
  static String malAlimFisBirimFiyat = '33';
  static String satisFaturaBirimFiyat = '33';
  static String satisIrsaliyeBirimFiyat = '33';
  static String satisFisBirimFiyat = '33';
  static String alinanSiparisBirimFiyat = '33';
  static String verilenSiparisBirimFiyat = '33';

  // ===== Yazıcı & Etiket =====
  static bool yaziciKontrol = false;
  static bool hizliIslemZorunlulugu = false;
  static String akilliArama = 'Kapalı';
  static int topluEtiketSayac = 0;
  static String yazdirilamayanEtiket = '';
  static String seciliYaziciAdi = 'Yazıcı Seçilmedi';
  static String seciliYaziciTipi = 'Ağ / IP Yazıcı'; // 'Ağ / IP Yazıcı' or 'Bluetooth / Sistem Yazıcısı'
  static String seciliYaziciIp = '192.168.1.100';
  static int seciliYaziciPort = 9100;
  static String seciliYaziciMac = '';
  static String seciliYaziciUrl = '';
  static String yaziciKagizGenislik = '80mm'; // '80mm', '58mm', 'A4', 'A5'
  static int yaziciKopyaSayisi = 1;

  // ===== Terazi =====
  static String gecerliBar = '';
  static String teraziDurum = '';
  static double gecerliMik = 1.0;

  // ===== Belge & Cari Seçimi =====
  static CalismaModu calismaModu = CalismaModu.modBir;
  static String toplamMiktar = '0';
  static int secilenCariID = 0;
  static String secilenCariAD = '';
  static int siparisID = 0;
  static String baslik = '';
  static String islemturu = '';
  static int kwBelgeID = 0;
  static String stokAramaTUR = '';
  static String stokYazdirmaTur = '';
  static String yaziciSecmeTur = '';

  // ===== Stok Filtre =====
  static String stokTurFiltre = '';
  static List<bool> secilenStokTur = List.filled(11, false);
  static const List<String> classStokTur = [
    'MALZEME', 'MAMUL', 'Y.MAMUL', 'HAMMADDE', 'HİZMET', 'İNDİRİM', 'MASRAF',
    'DEPOZİT', 'DEMİRBAŞ', 'ESER', 'PAKET',
  ];
  static const List<String> classHizliIslem = [
    'Depo Transfer', 'Sayım', 'Mal Alım', 'Satış', 'Mal Alım İade', 'Satış İade', 'Tekli Etiket',
    'Toplu Etiket', 'Verilen Siparişler', 'Alınan Siparişler',
  ];
  static List<bool>? secilenIslemler;

  // ===== Özel Fiyat Etiketleri =====
  static String textOFiyat1 = 'Özel Fiyat (1)';
  static String textOFiyat2 = 'Özel Fiyat (2)';
  static String textOFiyat3 = 'Özel Fiyat (3)';
  static String textOFiyat4 = 'Özel Fiyat (4)';
  static String textOFiyat5 = 'Özel Fiyat (5)';
  static String textOFiyat6 = 'Özel Fiyat (6)';
  static String textSMaliyet = 'Son Maliyet';
  static String textOMaliyet = 'Ortalama Maliyet';
  static String textStokKartFiyat = 'Stok Kart Fiyatları';
  static String textStokKartOzelFiyat = 'Stok Kart Özel Fiyatları';
  static String textMaliyetler = 'Maliyetler';
  static String textAFiyat = 'Alış Fiyatı';
  static String textSFiyat = 'Satış Fiyatı';

  // ===== Mob Yetki Değişkenleri =====
  static String yStokKartlari = '';
  static String yAlisIrsaliyesi = '';
  static String ySatisIrsaliyesi = '';
  static String yAlisFaturasi = '';
  static String ySatisFaturasi = '';
  static String yStok = '';
  static String yDepoTransferFisi = '';
  static String yStokBarkodEtiketiBasimi = '';
  static String yStokSayimDuzeltmeFisi = '';
  static String ySiparis = '';
  static String yAlinanSiparisler = '';
  static String yVerilenSiparisler = '';
  static String yKasaIslemleri = '';
  static String yBankaIslemleri = '';
  static String yBankaHesapIslemleri = '';
  static String yCariAnaMenu = '';
  static String yAsSevkiyat = '';
  static String yVsTeslimAlma = '';
  static String yFatura = '';
  static String yIrsaliye = '';

  // ===== Timeout =====
  static int timeOutSayac = 0;
  static int exceptionSayac = 0;
  static const int timeout = 3;

  // ===== Sabit Değerler =====
  static const int etiketMiktar = 100;
  static const double maksimumMiktar = 100000;
  static const double maksimumFiyat = 100000;
  static const int maxActivityTransitionTimeMs = 180000;

  // ===== Bellekteki Listeler =====
  static PostSuperUser? superUser;
  static GetBelgeListele? secilenBelge;
  static List<GetBelgeListele> belgeList = [];
  static List<GetSube> subeList = [];
  static List<GetDepo> depoList = [];
  static List<GetDepo> tumDepolar = [];
  static List<GetDepo> secilenDepoList = [];
  static List<GetCari> cariList = [];
  static List<GetStok> stokAraList = [];
  static List<GetStokDetay> stokDetayList = [];
  static List<GetBelgeIcerik> belgeDetayList = [];
  static List<GetBelgeGetir> belgeGetirList = [];
  static List<GetBelgenoUret> belgeNoUretList = [];
  static List<GetGonderimKoduTeslimAl> gonderimKoduTeslimAlList = [];
  static List<GetKontrolluIrsaliyeTeslimAlma> kontrolluIrsaliyeTeslimAlList = [];
  static List<GetStokIslem> stokOlusturList = [];
  static List<GetUrunEkle> eklenenUrunList = [];
  static List<GetTopluEtiket> topluEtiketEklemeList = [];
  static List<GetTopluEtiket> topluEtiketSilmeList = [];
  static List<GetTopluEtiket> topluEtiketSatirSilmeList = [];
  static List<GetTopluEtiket> topluEtiketListeleList = [];
  static List<GetTopluEtiket> topluEtiketTarihList = [];
  static List<GetYaziciListele> yaziciList = [];
  static List<GetYazdirilcakUrun> yazdirilcakUrunList = [];
  static List<GetKullaniciAyarlari> kullaniciAyarlariList = [];
  static List<GetMobYetki> yetkiList = [];
  static List<GetFiyatGor> fiyatGorList = [];
  static List<GetKasalar> kasaList = [];
  static List<GetBankalar> bankaList = [];
  static List<GetDovizler> dovizList = [];
  static List<GetBelgeKapatListe> belgeKapatList = [];
  static List<GetMatbuTasarim> matbuTasarimList = [];
  static List<GetTahsilatListe> kasaTahsilatListe = [];
  static List<GetTahsilatListe> bankaTahsilatListe = [];
  static List<GetTahsilatListe> tahsilatListe = [];
  static List<GetCariHesapEkstre> cariEkstreList = [];
  static List<GetKullaniciList> kullaniciList = [];
  static List<GetKullaniciRaporDetay> kullaniciRaporList = [];
  static List<GetPersonel> personelList = [];
  static List<GetAjanda> ajandaList = [];
  static List<GetYazarKasaKdv> yKasaList = [];
  static List<GetKWBelgeOlustur> kwList = [];
  static List<GetBelgeIciStokAra> belgeIciStokList = [];
  static List<GetFiyatListesi> fiyatList = [];
  static List<String> fiyatTurList = [];
  static List<String> sinifKodList = [];
  static List<String> kontrolluUrun = [];
  static int kontrolluSayac = 0;

  // Sube alt listeleri
  static List<GetSubeKasa> subeKasaList = [];
  static List<GetSubeBanka> subeBankaList = [];
  static List<GetSubeDepo> subeDepoList = [];

  // Modül parametre listeleri
  static List<GetIslemMprm> depoTransferAyarList = [];
  static List<GetIslemMprm> sayimAyarList = [];
  static List<GetIslemMprm> malKabulAyarList = [];
  static List<GetIslemMprm> satisAyarList = [];
  static List<GetIslemMprm> stokIslemAyarList = [];
  static List<GetIslemMprm> siparisAyarList = [];
  static List<GetIslemMprm> sistemAyarList = [];

  // ===== Shared Preferences =====
  static Future<void> initSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    sunucu = prefs.getString('sunucu') ?? 'https://mobway.api.bym.gen.tr/';
    token = prefs.getString('token') ?? '';
    superUserPosta = prefs.getString('superUserPosta') ?? '';
    superUserSifre = prefs.getString('superUserSifre') ?? '';
    firma = prefs.getString('firma') ?? '';
    selectedLanguage = prefs.getString('language') ?? 'tr';
    isDarkMode = prefs.getBool('isDarkMode') ?? false;
    sesliUyariAktif = prefs.getBool('sesliUyariAktif') ?? true;
    userId = prefs.getInt('userId') ?? 0;
    subeId = prefs.getInt('subeId') ?? 0;
    depoId = prefs.getInt('depoId') ?? 0;

    // Printer settings
    seciliYaziciTipi = prefs.getString('seciliYaziciTipi') ?? 'Ağ / IP Yazıcı';
    seciliYaziciAdi = prefs.getString('seciliYaziciAdi') ?? 'Yazıcı Seçilmedi';
    seciliYaziciIp = prefs.getString('seciliYaziciIp') ?? '192.168.1.100';
    seciliYaziciPort = prefs.getInt('seciliYaziciPort') ?? 9100;
    seciliYaziciUrl = prefs.getString('seciliYaziciUrl') ?? '';
    seciliYaziciMac = prefs.getString('seciliYaziciMac') ?? '';
    yaziciKagizGenislik = prefs.getString('yaziciKagizGenislik') ?? '80mm';
    yaziciKopyaSayisi = prefs.getInt('yaziciKopyaSayisi') ?? 1;

    themeNotifier.value = isDarkMode;
    languageNotifier.value = selectedLanguage;
    soundNotifier.value = sesliUyariAktif;
  }

  static Future<void> saveSoundSettings(bool aktif) async {
    final prefs = await SharedPreferences.getInstance();
    sesliUyariAktif = aktif;
    soundNotifier.value = aktif;
    await prefs.setBool('sesliUyariAktif', aktif);
  }

  static Future<void> savePrinterSettings({
    required String tip,
    required String ad,
    required String ip,
    required int port,
    String url = '',
    String mac = '',
    String kagiz = '80mm',
    int kopya = 1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    seciliYaziciTipi = tip;
    seciliYaziciAdi = ad;
    seciliYaziciIp = ip;
    seciliYaziciPort = port;
    seciliYaziciUrl = url;
    seciliYaziciMac = mac;
    yaziciKagizGenislik = kagiz;
    yaziciKopyaSayisi = kopya;

    await prefs.setString('seciliYaziciTipi', tip);
    await prefs.setString('seciliYaziciAdi', ad);
    await prefs.setString('seciliYaziciIp', ip);
    await prefs.setInt('seciliYaziciPort', port);
    await prefs.setString('seciliYaziciUrl', url);
    await prefs.setString('seciliYaziciMac', mac);
    await prefs.setString('yaziciKagizGenislik', kagiz);
    await prefs.setInt('yaziciKopyaSayisi', kopya);
  }

  static Future<void> saveLoginCredentials(String posta, String sifre, String serverUrl) async {
    final prefs = await SharedPreferences.getInstance();
    superUserPosta = posta;
    superUserSifre = sifre;
    sunucu = serverUrl;

    await prefs.setString('superUserPosta', posta);
    await prefs.setString('superUserSifre', sifre);
    await prefs.setString('sunucu', serverUrl);
  }

  static Future<void> saveUserSession({
    required String userToken,
    required int uId,
    required int sId,
    required int dId,
    required String uName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    token = userToken;
    userId = uId;
    subeId = sId;
    depoId = dId;
    username = uName;

    await prefs.setString('token', userToken);
    await prefs.setInt('userId', uId);
    await prefs.setInt('subeId', sId);
    await prefs.setInt('depoId', dId);
    await prefs.setString('username', uName);
  }

  static Future<void> setLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    selectedLanguage = langCode;
    languageNotifier.value = langCode;
    await prefs.setString('language', langCode);
  }

  static Future<void> toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = value;
    themeNotifier.value = value;
    await prefs.setBool('isDarkMode', value);
  }

  static void clearSession() {
    token = '';
    userId = 0;
    username = '';
    grupTur = 0;
    kullaniciKodu = '';
    kullaniciAdi = '';
    perID = 0;
    belgeList.clear();
    belgeDetayList.clear();
    eklenenUrunList.clear();
    yetkiList.clear();
    kullaniciAyarlariList.clear();
    dovizList.clear();
    yaziciList.clear();
    subeKasaList.clear();
    subeBankaList.clear();
    subeDepoList.clear();
    tumDepolar.clear();
    personelList.clear();
  }

  static String getKullaniciYetki(String menuKod) {
    for (final yetki in yetkiList) {
      if (yetki.menuKod == menuKod) {
        return yetki.yetki;
      }
    }
    return '';
  }

  static String getFiyatTur(List<GetIslemMprm> list, String nesne, {String defaultValue = '33'}) {
    for (final item in list) {
      if (item.nesne.toLowerCase() == nesne.toLowerCase()) {
        return item.deger;
      }
    }
    return defaultValue;
  }

  static String getModulAyar(List<GetIslemMprm> list, String nesne, {String defaultValue = ''}) {
    for (final item in list) {
      if (item.nesne.toLowerCase() == nesne.toLowerCase()) {
        return item.deger;
      }
    }
    return defaultValue;
  }
}

