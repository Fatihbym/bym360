class ApiConstants {
  static const String appTitle = 'BYM 360';
  static const String appVersion = '1.1.8';
  static const int appVersionCode = 171;
  static const int webServiceVersion = 29;
  static String get fullVersion => '$appVersion.$webServiceVersion';
  static const int uygulamaId = 4;

  // Default API Endpoints
  static const String loginUrlDefault = 'https://mobway.api.bym.gen.tr/';
  static String baseUrl = loginUrlDefault;

  // ============================================================
  // Login Endpoints (Swagger: /login/*)
  // ============================================================
  static const String endpointGirisYap = 'login/GirisYap';
  static const String endpointGirisYapFast = 'login/GirisYapFast';
  static const String endpointGirisYapP = 'login/GirisYapP';
  static const String endpointTokenUret = 'login/TokenUret';
  static const String endpointLoginDepoKurye = 'login/depoKurye';

  // ============================================================
  // Mobwaycloud Endpoints (Swagger: /mobwaycloud/*)
  // ============================================================

  // --- Giriş & Ayarlar ---
  static const String endpointGetGiris = 'mobwaycloud/Get_Giris';
  static const String endpointGetIslemKprm = 'mobwaycloud/Get_IslemKprm';
  static const String endpointGetUrlVersiyon = 'mobwaycloud/Get_UrlVersiyon';
  static const String endpointGetKeySifirla = 'mobwaycloud/Get_KeySifirla';
  static const String endpointPostHataMesaji = 'mobwaycloud/Post_HataMesaji';
  static const String endpointGetMobLog = 'mobwaycloud/Get_MobLog';

  // --- Ajanda ---
  static const String endpointGetAjanda = 'mobwaycloud/Get_Ajanda';
  static const String endpointAddAjanda = 'mobwaycloud/Get_AddAjanda';
  static const String endpointDeleteAjanda = 'mobwaycloud/Get_DeleteAjanda';
  static const String endpointUpdateAjanda = 'mobwaycloud/Get_UpdateAjanda';

  // --- Belge İşlemleri ---
  static const String endpointGetBelgeNo = 'mobwaycloud/Get_BelgeNo';
  static const String endpointGetBelgenoUret = 'mobwaycloud/MB_BelgenoUret';
  static const String endpointGetBelgeListele = 'mobwaycloud/Get_BelgeListele';
  static const String endpointGetBelgeEkle = 'mobwaycloud/Get_BelgeEkle';
  static const String endpointGetBelgeGetir = 'mobwaycloud/Get_BelgeGetir';
  static const String endpointGetBelgeDetay = 'mobwaycloud/Get_BelgeDetay';
  static const String endpointGetBelgeOnay = 'mobwaycloud/Get_BelgeOnay';
  static const String endpointGetBelgeOnayIptal = 'mobwaycloud/Get_BelgeOnayIptal';
  static const String endpointGetBelgeSatirGuncelle = 'mobwaycloud/Get_BelgeSatirGuncelle';
  static const String endpointGetBelgeIciStokAra = 'mobwaycloud/Get_BelgeIciStokAra';
  static const String endpointGetBelgeNoDuzelt = 'mobwaycloud/X_Belge_No_Duzelt';

  // --- Ürün İşlemleri ---
  static const String endpointGetUrunEkle = 'mobwaycloud/Get_UrunEkle';
  static const String endpointGetUrunSil = 'mobwaycloud/Get_UrunSil';
  static const String endpointPostUrunToplamaKayit = 'mobwaycloud/Post_UrunToplamaKayitEt';
  static const String endpointPostAtamaliTeslimAlma = 'mobwaycloud/Post_AtamaliTeslimAlma';
  static const String endpointGetAtamaliSipDetGetir = 'mobwaycloud/Get_AtamaliSipDetGetir';

  // --- Stok İşlemleri ---
  static const String endpointGetStokAra = 'mobwaycloud/Get_StokAra';
  static const String endpointGetStokDetay = 'mobwaycloud/Get_StokDetay';
  static const String endpointGetStokIslem = 'mobwaycloud/Get_StokIslem';
  static const String endpointGetFiyatGor = 'mobwaycloud/Get_FiyatGor';
  static const String endpointStokLot = 'stok/stokLot';
  static const String endpointStokFotoUrl = 'stok/getfotourl';
  static const String endpointStokSeviyeKontrol = 'stok/stokSeviyeKontrol';
  static const String endpointStokGetStok = 'stok/getstok';
  static const String endpointStokStok = 'stok/stok';
  static const String endpointStokStokAra = 'stok/stokAra';
  static const String endpointStokStokGuncelle = 'stok/stokGuncelle';
  static const String endpointStokStokSil = 'stok/stokSil';
  static const String endpointStokRaporGetir = 'stokRapor/stokRaporGetir';
  static const String endpointStokRaporBorcY = 'stokRapor/borcYRapor';
  static const String endpointStokRaporSorgula = 'stokRapor/raporSorgula';
  static const String endpointStokRaporTalep = 'stokRapor/stokRaporTalep';

  // --- Cari İşlemleri ---
  static const String endpointGetCariAra = 'mobwaycloud/Get_CariAra';
  static const String endpointGetCariEkle = 'mobwaycloud/Get_CariEkle';
  static const String endpointGetCariHesapEkstre = 'mobwaycloud/Get_CariHesapEkstre';
  static const String endpointGetCariBakiye = 'mobwaycloud/Get_CariBakiye';
  static const String endpointGetCariRiskLimitKontrol = 'mobwaycloud/Get_CariRiskLimitKontrol';
  static const String endpointGetCariSiparisKontrol = 'mobwaycloud/Get_CariSiparisKontrol';

  // --- Tahsilat & Banka İşlemleri ---
  static const String endpointGetBelgeTahsilKasa = 'mobwaycloud/Get_BelgeTahsilKasa';
  static const String endpointGetBelgeTahsilBanka = 'mobwaycloud/Get_BelgeTahsilBanka';
  static const String endpointGetBelgeTahsilListe = 'mobwaycloud/Get_BelgeTahsilListe';
  static const String endpointGetBelgeTahsilatSil = 'mobwaycloud/Get_BelgeTahsilatSil';
  static const String endpointGetKasaTahsil = 'mobwaycloud/Get_KasaTahsil';
  static const String endpointGetKasaTahsilListe = 'mobwaycloud/Get_KasaTahsilListe';
  static const String endpointGetBankaTahsil = 'mobwaycloud/Get_BankaTahsil';
  static const String endpointGetBankaTahsilListe = 'mobwaycloud/Get_BankaTahsilListe';
  static const String endpointGetTahsilatSil = 'mobwaycloud/Get_TahsilatSil';
  static const String endpointGetDovizKur = 'mobwaycloud/Get_DovizKur';
  static const String endpointOduyoBankaListesi = 'Oduyo/BankaListesi';
  static const String endpointOduyoBankaHareketleri = 'Oduyo/BankaHareketleri';
  static const String endpointOduyoCariListele = 'Oduyo/CariListele';
  static const String endpointOduyoGetToken = 'Oduyo/GetToken';
  static const String endpointFinmaksBankAccount = 'Finmaks/BankAccount';
  static const String endpointFinmaksTransactions = 'Finmaks/Transactions';

  // --- AlternatifPay (Swagger: /apay/*) ---
  static const String endpointApayOdemeTalep = 'apay/odemetalep';
  static const String endpointApayOdemeKontrol = 'apay/odemekontrol';
  static const String endpointApayOdemeTamamla = 'apay/odemeTamamla';
  static const String endpointApayIptalOdemeBilgisi = 'apay/iptal/odemebilgisi';
  static const String endpointApayIptalOnayla = 'apay/iptal/onayla';
  static const String endpointApayIptalRet = 'apay/iptal/ret';

  // --- Pavo POS & PavoCloud (Swagger: /Pavo/* & /PavoCloud/*) ---
  static const String endpointPavoPairing = 'Pavo/Pairing';
  static const String endpointPavoCurrentSale = 'Pavo/CurrentSale';
  static const String endpointPavoLastProcessedSale = 'Pavo/LastProcessedSale';
  static const String endpointPavoCompleteSale = 'Pavo/CompleteSale';
  static const String endpointPavoCancelSale = 'Pavo/CancelSale';
  static const String endpointPavoCreateReport = 'Pavo/CreateReport';
  static const String endpointPavoCloudGetToken = 'PavoCloud/GetToken';
  static const String endpointPavoCloudPairingRequest = 'PavoCloud/PairingRequest';
  static const String endpointPavoCloudCheckPairing = 'PavoCloud/CheckPairing';
  static const String endpointPavoCloudCreatePaymentLink = 'PavoCloud/CreatePaymentLink';
  static const String endpointPavoCreatePaymentLink = 'PavoCloud/CreatePaymentLink';
  static const String endpointPavoCloudCheckPaymentLink = 'PavoCloud/CheckPaymentLink';
  static const String endpointPavoCheckPaymentLink = 'PavoCloud/CheckPaymentLink';
  static const String endpointPavoCloudCancelPaymentLink = 'PavoCloud/CancelPaymentLink';
  static const String endpointPavoCloudUpdatePaymentLink = 'PavoCloud/UpdatePaymentLink';

  // --- Etiket & Yazıcı ---
  static const String endpointGetEtiketYazdir = 'mobwaycloud/Get_EtiketYazdir';
  static const String endpointGetTopluEtiketYazdir = 'mobwaycloud/Get_TopluEtiketYazdir';
  static const String endpointGetYazicilar = 'mobwaycloud/Get_Yazicilar';

  // --- Fiş & Rapor & Tasarım ---
  static const String endpointGetFisDizMasList = 'mobwaycloud/Get_FisDizMasList';
  static const String endpointGetFisYazText = 'mobwaycloud/Get_FisYazText';
  static const String endpointGetYazsayUpdate = 'mobwaycloud/Get_YazsayUpdate';
  static const String endpointGetYazarKasaKdv = 'mobwaycloud/Get_YazarKasaKdv';
  static const String endpointGetRaporYazdir = 'mobwaycloud/Get_RaporYazdir';
  static const String endpointRaporTasarimEkle = 'RaporTasarim/ekleTasarim';
  static const String endpointRaporTasarimGuncelle = 'RaporTasarim/guncelleTasarim';
  static const String endpointRaporTasarimOzel = 'RaporTasarim/ozelTasarim';
  static const String endpointRaporTasarimSil = 'RaporTasarim/silTasarim';
  static const String endpointRaporTasarimGetir = 'RaporTasarim/tasarimGetir';
  static const String endpointRaporTasarimSube = 'RaporTasarim/tasarimGetirSube';
  static const String endpointRaporTasarimSorgula = 'RaporTasarim/tasarimSorgula';

  // --- Sipariş & Sevkiyat ---
  static const String endpointGetSIPSevkiyat = 'mobwaycloud/Get_SIPSevkiyat';
  static const String endpointGetSIPTeslimAl = 'mobwaycloud/Get_SIPTeslimAl';
  static const String endpointGetSevkiyatUrunEkle = 'mobwaycloud/Get_SevkiyatUrunEkle';
  static const String endpointGetTeslimAlmaUrunEkle = 'mobwaycloud/Get_TeslimAlmaUrunEkle';
  static const String endpointGetKwBelgeOlustur = 'mobwaycloud/KW_BelgeOlustur';
  static const String endpointDepocuGetSiparis = 'depocu/getSiparis';
  static const String endpointDepocuGetSiparisTamamlanan = 'depocu/getSiparisTamamlanan';
  static const String endpointDepocuGetSiparisAcik = 'depocu/getSiparisAcik';
  static const String endpointDepocuGetSiparisDetay = 'depocu/getSiparisDetay';
  static const String endpointDepocuUrunArtir = 'depocu/urunArtir';
  static const String endpointDepocuUrunAzalt = 'depocu/urunAzalt';
  static const String endpointDepocuUrunSil = 'depocu/urunSil';
  static const String endpointDepocuKuryeAta = 'depocu/kuryeAta';
  static const String endpointDepocuKuryeIptal = 'depocu/kuryeIptal';
  static const String endpointDepocuSiparisTopla = 'depocu/siparisTopla';
  static const String endpointDepocuAtamaKontrol = 'depocu/atamaKontrol';
  static const String endpointDepocuGetKurye = 'depocu/getKurye';
  static const String endpointDepocuGetTanim = 'depocu/getTanim';
  static const String endpointDepocuGetStok = 'depocu/getStok';
  static const String endpointKuryeGetSip = 'kurye/getSip';
  static const String endpointKuryeGetSipDetay = 'kurye/getSipDetay';
  static const String endpointKuryeGetSipTamamlanan = 'kurye/getSipTamamlanan';
  static const String endpointKuryeSipTamamla = 'kurye/sipTamamla';

  // --- Mobil Sipariş (Swagger: /mobilSiparis/*) ---
  static const String endpointMobilSiparisVersiyonKontrol = 'mobilSiparis/VersiyonKontrol';
  static const String endpointMobilSiparisUye = 'mobilSiparis/Uye';
  static const String endpointMobilSiparisAnaMenu = 'mobilSiparis/AnaMenu';
  static const String endpointMobilSiparisAdresGetir = 'mobilSiparis/AdresGetir';
  static const String endpointMobilSiparisSepetKontrolEt = 'mobilSiparis/sepetKontrolEt';
  static const String endpointMobilSiparisTanimGetir = 'mobilSiparis/TanimGetir';
  static const String endpointMobilSiparisTanimKontrol = 'mobilSiparis/TanimKontrol';
  static const String endpointMobilSiparisSiparisEkle = 'mobilSiparis/SiparisEkle';
  static const String endpointMobilSiparisSiparisIlkSayfa = 'mobilSiparis/SiparisIlkSayfa';
  static const String endpointMobilSiparisStokDetay = 'mobilSiparis/StokDetay';
  static const String endpointMobilSiparisSiparisDetay = 'mobilSiparis/SiparisDetay';
  static const String endpointMobilSiparisSiparisIptal = 'mobilSiparis/SiparisIptal';
  static const String endpointMobilSiparisSiparisListe = 'mobilSiparis/SiparisListe';
  static const String endpointMobilSiparisOdemeTur = 'mobilSiparis/OdemeTur';
  static const String endpointMobilSiparisCalismaSaatleri = 'mobilSiparis/CalismaSaatleri';
  static const String endpointMobilSiparisSubeBilgileriGetir = 'mobilSiparis/SubeBilgileriGetir';
  static const String endpointMobilSiparisSubeGetir = 'mobilSiparis/SubeGetir';
  static const String endpointMobilSiparisAramaYap = 'mobilSiparis/AramaYap';
  static const String endpointMobilSiparisGsmKodGonder = 'mobilSiparis/GsmKodGonder';

  // --- Aktarım & Hızlı Satış (Swagger: /aktarim/*) ---
  static const String endpointAktarimSatisYap = 'aktarim/SatisYap';
  static const String endpointAktarimFiyatDegisim = 'aktarim/fiyatdegisim';
  static const String endpointAktarimBhsfSatirKaydet = 'aktarim/Bhsf_Satir_Kaydet';

  // --- E-Fatura & E-İrsaliye Entegrasyonu (Swagger: /bymkolay/* & /econnect/*) ---
  static const String endpointBymKolayGibUser = 'bymkolay/gibuser';
  static const String endpointBymKolayFaturaGonder = 'bymkolay/faturagonder';
  static const String endpointBymKolayIrsaliyeGonder = 'bymkolay/irsaliyegonder';
  static const String endpointBymKolayKalanKontur = 'bymkolay/kalankontur';
  static const String endpointBymKolayBakiyeSorgula = 'bymkolay/bakiyesorgula';

  // --- Bildirim, SMS & Mail (Swagger: /PushNotifications/*, /SmsGonder, /MailGonder) ---
  static const String endpointPushNotificationSend = 'PushNotifications/SenPushToId';
  static const String endpointSmsGonder = 'SmsGonder';
  static const String endpointMailGonder = 'MailGonder';

  // --- SQL & Sistem & Versiyon (Swagger: /wsql/*, /User/*, /Versiyon/*) ---
  static const String endpointWsqlTablo = 'wsql/sqltablo';
  static const String endpointWsql = 'wsql/Wsql';
  static const String endpointUserFotoUrl = 'User/getfotourl';
  static const String endpointVersiyonGet = 'Versiyon/getVersiyon';

  // --- İskonto ---
  static const String endpointPostSatirIskonto = 'mobwaycloud/satiriskonto';

  // --- Modül Güncelleme ---
  static const String endpointGetDTModulGuncelle = 'mobwaycloud/Get_DTModulGuncelle';
  static const String endpointGetSModulGuncelle = 'mobwaycloud/Get_SModulGuncelle';
  static const String endpointGetKBLModulGuncelle = 'mobwaycloud/Get_KBLModulGuncelle';
  static const String endpointGetSTSModulGuncelle = 'mobwaycloud/Get_STSModulGuncelle';
  static const String endpointGetSTKModulGuncelle = 'mobwaycloud/Get_STKModulGuncelle';
  static const String endpointGetSPModulGuncelle = 'mobwaycloud/Get_SPModulGuncelle';
  static const String endpointGetSPRMModulGuncelle = 'mobwaycloud/Get_SPRMModulGuncelle';

  // --- Kullanıcı ---
  static const String endpointGetKullaniciList = 'mobwaycloud/Get_KullaniciList';
  static const String endpointGetKullaniciRapor = 'mobwaycloud/Get_KullaniciRapor';
  static const String endpointGetKullaniciRaporDetay = 'mobwaycloud/Get_KullaniciRaporDetey';

  // --- Firma ---
  static const String endpointGetFirmaListele = 'mobwaycloud/Get_FirmaListele';

  // --- Eski/Uyumluluk (mevcut kullanımlar için korunan yollar) ---
  static const String endpointGetIslemMprm = 'mobwaycloud/Get_IslemKprm';
  static const String endpointGetMobYetki = 'mobwaycloud/Get_IslemKprm';
  static const String endpointGetBelgeKapatListe = 'mobwaycloud/Get_BelgeListele';
  static const String endpointPostBelgeKapat = 'mobwaycloud/Get_BelgeOnay';

  // --- TEST (Swagger: /test/*) ---
  static const String endpointTestEcon = 'test/econ';

  // --- AKTARIM (Swagger: /aktarim/*) ---
  static const String endpointAktarimAdisyonVeriAl = 'aktarim/adisyonVeriAl';
  static const String endpointAktarimAdisyonVeriAlP = 'aktarim/adisyonVeriAlP';
  static const String endpointAktarimAdisyonVeriSize = 'aktarim/AdisyonVeriSize';

  // --- APIKEY (Swagger: /apikey/*) ---
  static const String endpointApikeyCreate = 'apikey/create';

  // --- B2C (Swagger: /b2c/*) ---
  static const String endpointB2cInit = 'b2c/Init';
  static const String endpointB2cSubeHizmetAlaniGetir = 'b2c/SubeHizmetAlaniGetir';
  static const String endpointB2cUye = 'b2c/Uye';
  static const String endpointB2cAnaMenuGetir = 'b2c/AnaMenuGetir';
  static const String endpointB2cStokGetir = 'b2c/StokGetir';
  static const String endpointB2cGrupGetir = 'b2c/GrupGetir';
  static const String endpointB2cGrupUrunListGetir = 'b2c/GrupUrunListGetir';
  static const String endpointB2cAdres = 'b2c/Adres';
  static const String endpointB2cAdresGetir = 'b2c/AdresGetir';
  static const String endpointB2cAdresEkle = 'b2c/AdresEkle';
  static const String endpointB2cAdresGuncelle = 'b2c/AdresGuncelle';
  static const String endpointB2cSepetKontrolEt = 'b2c/sepetKontrolEt';
  static const String endpointB2cSiparisEkle = 'b2c/SiparisEkle';
  static const String endpointB2cSiparisIlkSayfa = 'b2c/SiparisIlkSayfa';
  static const String endpointB2cStokDetay = 'b2c/StokDetay';
  static const String endpointB2cSiparisDetay = 'b2c/SiparisDetay';
  static const String endpointB2cSiparisDeneyimlendir = 'b2c/SiparisDeneyimlendir';
  static const String endpointB2cSiparisIptal = 'b2c/SiparisIptal';
  static const String endpointB2cSiparisListe = 'b2c/SiparisListe';
  static const String endpointB2cSepetTamamlaInit = 'b2c/SepetTamamlaInit';
  static const String endpointB2cCalismaSaatleri = 'b2c/CalismaSaatleri';
  static const String endpointB2cSubeBilgileriGetir = 'b2c/SubeBilgileriGetir';
  static const String endpointB2cAramaYap = 'b2c/AramaYap';
  static const String endpointB2cSepetGetir = 'b2c/SepetGetir';
  static const String endpointB2cSepetEkle = 'b2c/SepetEkle';
  static const String endpointB2cSepetSil = 'b2c/SepetSil';
  static const String endpointB2cSepetDurumGetir = 'b2c/SepetDurumGetir';
  static const String endpointB2cSepetGuncelle = 'b2c/SepetGuncelle';
  static const String endpointB2cGsmKodGonder = 'b2c/GsmKodGonder';
  static const String endpointB2cGirisYap = 'b2c/GirisYap';
  static const String endpointB2cGirisYapW = 'b2c/GirisYap_W';
  static const String endpointB2cUyeOl = 'b2c/UyeOl';
  static const String endpointB2cUyeOlW = 'b2c/UyeOl_W';
  static const String endpointB2cUyeGuncelleW = 'b2c/UyeGuncelle_W';
  static const String endpointB2cAktivasyonKodGonder = 'b2c/AktivasyonKodGonder';
  static const String endpointB2cSifreYenile = 'b2c/SifreYenile';
  static const String endpointB2cSubeKoordinatGetir = 'b2c/SubeKoordinatGetir';
  static const String endpointB2cAktivasyonKodDogrula = 'b2c/AktivasyonKodDogrula';
  static const String endpointB2cUyeEkstre = 'b2c/UyeEkstre';
  static const String endpointB2cUyeEkstreDetay = 'b2c/UyeEkstreDetay';

  // --- BAYI (Swagger: /bayi/*) ---
  static const String endpointBayiGirisYap = 'bayi/GirisYap';

  // --- BILDIRIM (Swagger: /bildirim/*) ---
  static const String endpointBildirimMesajGoster = 'bildirim/MesajGoster';

  // --- BYMKOLAY (Swagger: /bymkolay/*) ---
  static const String endpointBymkolayMustahsilyolla = 'bymkolay/mustahsilyolla';
  static const String endpointBymkolayFlagyolla = 'bymkolay/flagyolla';
  static const String endpointBymkolayGetfatls = 'bymkolay/getfatls';
  static const String endpointBymkolayGetfatlsuid = 'bymkolay/getfatlsuid';
  static const String endpointBymkolayFaturacevap = 'bymkolay/faturacevap';
  static const String endpointBymkolayFaturagoruntu = 'bymkolay/faturagoruntu';
  static const String endpointBymkolayFaturaiptal = 'bymkolay/faturaiptal';
  static const String endpointBymkolayEntegratorkayit = 'bymkolay/entegratorkayit';
  static const String endpointBymkolayKonturyukle = 'bymkolay/konturyukle';
  static const String endpointBymkolayBirimlerial = 'bymkolay/birimlerial';
  static const String endpointBymkolayGibuserQuery = 'bymkolay/gibuserQuery';
  static const String endpointBymkolayXsltliste = 'bymkolay/xsltliste';
  static const String endpointBymkolaySonbelgeno = 'bymkolay/sonbelgeno';
  static const String endpointBymkolayIrsaliyecevap = 'bymkolay/irsaliyecevap';
  static const String endpointBymkolayIrsaliyecevapmodel = 'bymkolay/irsaliyecevapmodel';
  static const String endpointBymkolayPrefixliste = 'bymkolay/prefixliste';
  static const String endpointBymkolayRaporgetir = 'bymkolay/raporgetir';
  static const String endpointBymkolayTurmobsorgu = 'bymkolay/turmobsorgu';
  static const String endpointBymkolayEloginkontrol = 'bymkolay/eloginkontrol';
  static const String endpointBymkolayTekrargonder = 'bymkolay/tekrargonder';

  // --- CARI (Swagger: /cari/*) ---
  static const String endpointCariGet = 'cari/get';
  static const String endpointCariGetcariInfo = 'cari/getcariInfo';
  static const String endpointCariGetdevir = 'cari/getdevir';
  static const String endpointCariGethareket = 'cari/gethareket';

  // --- DATABASE (Swagger: /database/*) ---
  static const String endpointDatabaseDbOlustur = 'database/DbOlustur';
  static const String endpointDatabaseTabloOlustur = 'database/TabloOlustur';
  static const String endpointDatabaseAlterOlustur = 'database/AlterOlustur';
  static const String endpointDatabaseCreateMusteri = 'database/create/{musteri}';
  static const String endpointDatabaseUpdate = 'database/update';

  // --- DATABASES (Swagger: /Databases/*) ---
  static const String endpointDatabasesInformation = 'Databases/information';
  static const String endpointDatabasesTest = 'Databases/test';

  // --- DEPOKURYE (Swagger: /depoKurye/*) ---
  static const String endpointDepoKuryeDepoKuryeLogin = 'depoKurye/depoKuryeLogin';

  // --- ECONNECT (Swagger: /econnect/*) ---
  static const String endpointEconnectGibuser = 'econnect/gibuser';
  static const String endpointEconnectFaturagonder = 'econnect/faturagonder';
  static const String endpointEconnectMustahsilyolla = 'econnect/mustahsilyolla';
  static const String endpointEconnectIrsaliyegonder = 'econnect/irsaliyegonder';
  static const String endpointEconnectFlagyolla = 'econnect/flagyolla';
  static const String endpointEconnectGetfatls = 'econnect/getfatls';
  static const String endpointEconnectGetfatlsuid = 'econnect/getfatlsuid';
  static const String endpointEconnectFaturacevap = 'econnect/faturacevap';
  static const String endpointEconnectFaturagoruntu = 'econnect/faturagoruntu';
  static const String endpointEconnectFaturaiptal = 'econnect/faturaiptal';
  static const String endpointEconnectEntegratorkayit = 'econnect/entegratorkayit';
  static const String endpointEconnectKalankontur = 'econnect/kalankontur';
  static const String endpointEconnectKonturyukle = 'econnect/konturyukle';
  static const String endpointEconnectBakiyesorgula = 'econnect/bakiyesorgula';
  static const String endpointEconnectBirimlerial = 'econnect/birimlerial';
  static const String endpointEconnectGibuserQuery = 'econnect/gibuserQuery';

  // --- EFIRMA (Swagger: /efirma/*) ---
  static const String endpointEfirmaGetefirma = 'efirma/getefirma';
  static const String endpointEfirmaGetfattur = 'efirma/getfattur';
  static const String endpointEfirmaGetlokasyon = 'efirma/getlokasyon';

  // --- EMIR (Swagger: /emir/*) ---
  static const String endpointEmirKaydet = 'emir/kaydet';
  static const String endpointEmirGetir = 'emir/getir';
  static const String endpointEmirSil = 'emir/sil';
  static const String endpointEmirGuncelle = 'emir/guncelle';

  // --- FOTOGRAF (Swagger: /fotograf/*) ---
  static const String endpointFotografKopyalaId = 'fotograf/kopyala/{id}';
  static const String endpointFotografOnizleboyutId = 'fotograf/onizleboyut/{id}';
  static const String endpointFotografVarlikkontrol = 'fotograf/varlikkontrol';
  static const String endpointFotografFotoekle = 'fotograf/fotoekle';
  static const String endpointFotografFotosil = 'fotograf/fotosil';

  // --- ICE (Swagger: /ice/*) ---
  static const String endpointIceLogin = 'ice/login';
  static const String endpointIceLogout = 'ice/logout';
  static const String endpointIceEfaturauser = 'ice/efaturauser';
  static const String endpointIceEfaturagetir = 'ice/efaturagetir';
  static const String endpointIceEfaturasatirgetir = 'ice/efaturasatirgetir';
  static const String endpointIceEirsaliyegetir = 'ice/eirsaliyegetir';
  static const String endpointIceEarsivgetir = 'ice/earsivgetir';
  static const String endpointIceFaturagoruntu = 'ice/faturagoruntu';
  static const String endpointIceIrsaliyegoruntu = 'ice/irsaliyegoruntu';
  static const String endpointIceEarsivgoruntu = 'ice/earsivgoruntu';
  static const String endpointIceEfaturaflag = 'ice/efaturaflag';
  static const String endpointIceEirsaliyeflag = 'ice/eirsaliyeflag';
  static const String endpointIceEarsivflag = 'ice/earsivflag';

  // --- KODMATIK (Swagger: /kodmatik/*) ---
  static const String endpointKodmatikKodUret = 'kodmatik/KodUret';
  static const String endpointKodmatikKodListele = 'kodmatik/KodListele';
  static const String endpointKodmatikInit = 'kodmatik/Init';
  static const String endpointKodmatikKodSorgula = 'kodmatik/KodSorgula';

  // --- LISAN (Swagger: /Lisan/*) ---
  static const String endpointLisanGetAllLisanProje = 'Lisan/GetAllLisan/{proje}';
  static const String endpointLisanLisanKaydet = 'Lisan/LisanKaydet';
  static const String endpointLisanLisanverData = 'Lisan/Lisanver/{data}';

  // --- MIGRASYON (Swagger: /Migrasyon/*) ---
  static const String endpointMigrasyonMigrateID = 'Migrasyon/migrateID';
  static const String endpointMigrasyonMigrate = 'Migrasyon/migrate';

  // --- NAV (Swagger: /nav/*) ---
  static const String endpointNavNavStokAktar = 'nav/navStokAktar';
  static const String endpointNavNavTableCreateName = 'nav/navTableCreate/{name}';
  static const String endpointNavCustomerAktar = 'nav/customerAktar';
  static const String endpointNavDepartmentsAktar = 'nav/departmentsAktar';
  static const String endpointNavLocationsAktar = 'nav/locationsAktar';
  static const String endpointNavSalesPersonelAktar = 'nav/salesPersonelAktar';

  // --- PAZARYERI (Swagger: /pazaryeri/*) ---
  static const String endpointPazaryeriKategori = 'pazaryeri/kategori';

  // --- DIREKSMSGONDER (Swagger: /DirekSmsGonder/*) ---
  static const String endpointDirekSmsGonder = 'DirekSmsGonder';

  // --- VERI (Swagger: /veri/*) ---
  static const String endpointVeriTable = 'veri/table';

  // --- STOK (Swagger: /stok/*) ---
  static const String endpointStokGetStokDurumKeyStokDepo = 'stok/GetStokDurum/{key}/{stok}/{depo}';

  // --- TSOFT (Swagger: /tsoft/*) ---
  static const String endpointTsoftLoginLogin = 'tsoft/login/login';

  // --- TRENDYOL (Swagger: /trendyol/*) ---
  static const String endpointTrendyolGetShipmentPackages = 'trendyol/getShipmentPackages';
  static const String endpointTrendyolCancelledPackages = 'trendyol/cancelledPackages';
  static const String endpointTrendyolUpdateTrackingNumberShipmentPackageId = 'trendyol/updateTrackingNumber/{shipmentPackageId}';
  static const String endpointTrendyolUpdatePackageUnsuppliedShipmentPackageId = 'trendyol/updatePackage/unsupplied/{shipmentPackageId}';
  static const String endpointTrendyolSendInvoiceLinkShipmentPackageId = 'trendyol/sendInvoiceLink/{shipmentPackageId}';
  static const String endpointTrendyolSplitMultiPackageByQuantityShipmentPackageId = 'trendyol/splitMultiPackageByQuantity/{shipmentPackageId}';
  static const String endpointTrendyolProcessAlternativeDeliveryShipmentPackageId = 'trendyol/processAlternativeDelivery/{shipmentPackageId}';
  static const String endpointTrendyolChangeCargoProviderShipmentPackageId = 'trendyol/changeCargoProvider /{shipmentPackageId}';
  static const String endpointTrendyolSetproduct = 'trendyol/setproduct';
  static const String endpointTrendyolUpdateproduct = 'trendyol/updateproduct';
  static const String endpointTrendyolGetproduct = 'trendyol/getproduct';
  static const String endpointTrendyolUpdateproductPriceAndInventory = 'trendyol/updateproduct/price-and-inventory';
  static const String endpointTrendyolGetbrand = 'trendyol/getbrand';
  static const String endpointTrendyolGetcategory = 'trendyol/getcategory';
  static const String endpointTrendyolGetbatch = 'trendyol/getbatch';
  static const String endpointTrendyolGetatribute = 'trendyol/getatribute';
  static const String endpointTrendyolFotografyukle = 'trendyol/fotografyukle';

  // --- TICIMAX (Swagger: /ticimax/*) ---
  static const String endpointTicimaxCustomAddFavoriUrun = 'ticimax/custom/addFavoriUrun';
  static const String endpointTicimaxCustomAddFiyatAlarmUrun = 'ticimax/custom/addFiyatAlarmUrun';
  static const String endpointTicimaxCustomAddStokAlarmUrun = 'ticimax/custom/addStokAlarmUrun';
  static const String endpointTicimaxCustomDeleteEntegrasyonId = 'ticimax/custom/deleteEntegrasyonId';
  static const String endpointTicimaxCustomDeleteMenu = 'ticimax/custom/deleteMenu';
  static const String endpointTicimaxCustomGetFavoriUrunler = 'ticimax/custom/getFavoriUrunler';
  static const String endpointTicimaxCustomGetFiyatAlarmUrunler = 'ticimax/custom/getFiyatAlarmUrunler';
  static const String endpointTicimaxCustomGetMenu = 'ticimax/custom/getMenu';
  static const String endpointTicimaxCustomGetStokAlarmUrunler = 'ticimax/custom/getStokAlarmUrunler';
  static const String endpointTicimaxCustomGetTaksitSecenek = 'ticimax/custom/getTaksitSecenek';
  static const String endpointTicimaxCustomGuncelleKargoDesiFiyat = 'ticimax/custom/guncelleKargoDesiFiyat';
  static const String endpointTicimaxCustomRemoveFavoriUrun = 'ticimax/custom/removeFavoriUrun';
  static const String endpointTicimaxCustomRemoveFiyatAlarmUrun = 'ticimax/custom/removeFiyatAlarmUrun';
  static const String endpointTicimaxCustomRemoveStokAlarmUrun = 'ticimax/custom/removeStokAlarmUrun';
  static const String endpointTicimaxCustomSaveEntegrasyonId = 'ticimax/custom/saveEntegrasyonId';
  static const String endpointTicimaxCustomSaveMenu = 'ticimax/custom/saveMenu';
  static const String endpointTicimaxCustomSelectEntegrasyon = 'ticimax/custom/selectEntegrasyon';
  static const String endpointTicimaxCustomSelectEntegrasyonId = 'ticimax/custom/selectEntegrasyonId';
  static const String endpointTicimaxCustomSelectIadeOdemeListesi = 'ticimax/custom/selectIadeOdemeListesi';
  static const String endpointTicimaxCustomSelectIadeTalebi = 'ticimax/custom/selectIadeTalebi';
  static const String endpointTicimaxCustomSelectIlceler = 'ticimax/custom/selectIlceler';
  static const String endpointTicimaxCustomSelectIller = 'ticimax/custom/selectIller';
  static const String endpointTicimaxCustomSelectUlkeler = 'ticimax/custom/selectUlkeler';
  static const String endpointTicimaxCustomUpdateIadeTalebi = 'ticimax/custom/updateIadeTalebi';
  static const String endpointTicimaxSiparisGetKargoSecenek = 'ticimax/siparis/getKargoSecenek';
  static const String endpointTicimaxSiparisGetSepet = 'ticimax/siparis/getSepet';
  static const String endpointTicimaxSiparisGetOdemeTipleri = 'ticimax/siparis/getOdemeTipleri';
  static const String endpointTicimaxSiparisSaveKargoTakipNo = 'ticimax/siparis/saveKargoTakipNo';
  static const String endpointTicimaxSiparisSaveSiparis = 'ticimax/siparis/saveSiparis';
  static const String endpointTicimaxSiparisSaveSiparisKargoPaket = 'ticimax/siparis/saveSiparisKargoPaket';
  static const String endpointTicimaxSiparisSaveSiparisKargoPaketKargoTakipNo = 'ticimax/siparis/saveSiparisKargoPaketKargoTakipNo';
  static const String endpointTicimaxSiparisSelectCariOdeme = 'ticimax/siparis/selectCariOdeme';
  static const String endpointTicimaxSiparisSelectSepet = 'ticimax/siparis/selectSepet';
  static const String endpointTicimaxSiparisSelectSiparis = 'ticimax/siparis/selectSiparis';
  static const String endpointTicimaxSiparisSelectSiparisKargoPaket = 'ticimax/siparis/selectSiparisKargoPaket';
  static const String endpointTicimaxSiparisSelectSiparisOdeme = 'ticimax/siparis/selectSiparisOdeme';
  static const String endpointTicimaxSiparisSelectSiparisUrun = 'ticimax/siparis/selectSiparisUrun';
  static const String endpointTicimaxSiparisSelectSiparisUrunDurumlari = 'ticimax/siparis/selectSiparisUrunDurumlari';
  static const String endpointTicimaxSiparisSelectWebSepet = 'ticimax/siparis/selectWebSepet';
  static const String endpointTicimaxSiparisSetFaturaNo = 'ticimax/siparis/setFaturaNo';
  static const String endpointTicimaxSiparisSetSiparisAktarildi = 'ticimax/siparis/setSiparisAktarildi';
  static const String endpointTicimaxSiparisSetSiparisAktarildiIptal = 'ticimax/siparis/setSiparisAktarildiIptal';
  static const String endpointTicimaxSiparisSetSiparisDurum = 'ticimax/siparis/setSiparisDurum';
  static const String endpointTicimaxSiparisSetSiparisKargoyaVerildi = 'ticimax/siparis/setSiparisKargoyaVerildi';
  static const String endpointTicimaxSiparisSetSiparisTeslimEdildi = 'ticimax/siparis/setSiparisTeslimEdildi';
  static const String endpointTicimaxSiparisSetSiparisUrunDurum = 'ticimax/siparis/setSiparisUrunDurum';
  static const String endpointTicimaxUrunSaveKategori = 'ticimax/urun/saveKategori';
  static const String endpointTicimaxUrunDeleteKategori = 'ticimax/urun/deleteKategori';
  static const String endpointTicimaxUrunSaveKategoriParent = 'ticimax/urun/saveKategoriParent';
  static const String endpointTicimaxUrunSelectKategori = 'ticimax/urun/selectKategori';
  static const String endpointTicimaxUrunUpdateKategoriDil = 'ticimax/urun/updateKategoriDil';
  static const String endpointTicimaxUrunDeleteMarka = 'ticimax/urun/deleteMarka';
  static const String endpointTicimaxUrunSaveMarka = 'ticimax/urun/saveMarka';
  static const String endpointTicimaxUrunSelectMarka = 'ticimax/urun/selectMarka';
  static const String endpointTicimaxUrunDeleteTedarikci = 'ticimax/urun/deleteTedarikci';
  static const String endpointTicimaxUrunSaveTedarikci = 'ticimax/urun/saveTedarikci';
  static const String endpointTicimaxUrunSelectTedarikci = 'ticimax/urun/selectTedarikci';
  static const String endpointTicimaxUrunSaveUrun = 'ticimax/urun/saveUrun';
  static const String endpointTicimaxUrunSelectUrun = 'ticimax/urun/selectUrun';
  static const String endpointTicimaxUrunSelectUrunCount = 'ticimax/urun/selectUrunCount';
  static const String endpointTicimaxUrunSelectUrunOdemeSecenek = 'ticimax/urun/selectUrunOdemeSecenek';
  static const String endpointTicimaxUrunSelectUrunYorum = 'ticimax/urun/selectUrunYorum';
  static const String endpointTicimaxUrunSelectUrunKategori = 'ticimax/urun/selectUrunKategori';
  static const String endpointTicimaxUrunSaveResim = 'ticimax/urun/saveResim';
  static const String endpointTicimaxUrunSaveMagazaStok = 'ticimax/urun/saveMagazaStok';
  static const String endpointTicimaxUrunUpdateUrunDil = 'ticimax/urun/UpdateUrunDil';
  static const String endpointTicimaxUrunSaveIlgiliUrun = 'ticimax/urun/saveIlgiliUrun';
  static const String endpointTicimaxUrunSaveTeknikDetayDeger = 'ticimax/urun/saveTeknikDetayDeger';
  static const String endpointTicimaxUrunSaveTeknikDetayGrup = 'ticimax/urun/saveTeknikDetayGrup';
  static const String endpointTicimaxUrunSaveTeknikDetayOzellik = 'ticimax/urun/saveTeknikDetayOzellik';
  static const String endpointTicimaxUrunSelectTeknikDetayDeger = 'ticimax/urun/selectTeknikDetayDeger';
  static const String endpointTicimaxUrunSelectTeknikDetayGrup = 'ticimax/urun/selectTeknikDetayGrup';
  static const String endpointTicimaxUrunSelectTeknikDetayOzellik = 'ticimax/urun/selectTeknikDetayOzellik';
  static const String endpointTicimaxUrunUpdateTeknikDetayDegerDil = 'ticimax/urun/updateTeknikDetayDegerDil';
  static const String endpointTicimaxUrunUpdateTeknikDetayGrupDil = 'ticimax/urun/updateTeknikDetayGrupDil';
  static const String endpointTicimaxUrunUpdateTeknikDetayOzellikDil = 'ticimax/urun/updateTeknikDetayOzellikDil';
  static const String endpointTicimaxUrunSaveEtiket = 'ticimax/urun/saveEtiket';
  static const String endpointTicimaxUrunSelectEtiket = 'ticimax/urun/selectEtiket';
  static const String endpointTicimaxUrunSelectVaryasyon = 'ticimax/urun/selectVaryasyon';
  static const String endpointTicimaxUrunSelectVaryasyonCount = 'ticimax/urun/selectVaryasyonCount';
  static const String endpointTicimaxUrunVaryasyonGuncelle = 'ticimax/urun/varyasyonGuncelle';
  static const String endpointTicimaxUrunSaveVaryasyon = 'ticimax/urun/saveVaryasyon';
  static const String endpointTicimaxUrunSaveAsortiGrup = 'ticimax/urun/SaveAsortiGrup';
  static const String endpointTicimaxUrunSaveAsortiMiktar = 'ticimax/urun/saveAsortiMiktar';
  static const String endpointTicimaxUrunSelectAsortiGrup = 'ticimax/urun/selectAsortiGrup';
  static const String endpointTicimaxUrunSelectAsortiMiktar = 'ticimax/urun/selectAsortiMiktar';
  static const String endpointTicimaxUrunSelectEkSecenekDeger = 'ticimax/urun/selectEkSecenekDeger';
  static const String endpointTicimaxUrunSelectEkSecenekGrup = 'ticimax/urun/selectEkSecenekGrup';
  static const String endpointTicimaxUrunUpdateEkSecenekDegerDil = 'ticimax/urun/updateEkSecenekDegerDil';
  static const String endpointTicimaxUrunUpdateEkSecenekGrupDil = 'ticimax/urun/updateEkSecenekGrupDil';
  static const String endpointTicimaxUrunSaveParaBirimi = 'ticimax/urun/saveParaBirimi';
  static const String endpointTicimaxUrunSelectParaBirimi = 'ticimax/urun/selectParaBirimi';
  static const String endpointTicimaxUrunGetProductStatus = 'ticimax/urun/getProductStatus';
  static const String endpointTicimaxUrunUpdateUrl = 'ticimax/urun/UpdateUrl';
  static const String endpointTicimaxUrunGetTaksitSecenekleri = 'ticimax/urun/getTaksitSecenekleri';
  static const String endpointTicimaxUrunSelectMagazaStok = 'ticimax/urun/selectMagazaStok';
  static const String endpointTicimaxUrunStokAdediGuncelle = 'ticimax/urun/stokAdediGuncelle';
  static const String endpointTicimaxUyeLogin = 'ticimax/uye/login';
  static const String endpointTicimaxUyeSaveUye = 'ticimax/uye/saveUye';
  static const String endpointTicimaxUyeSaveUyeAdres = 'ticimax/uye/saveUyeAdres';
  static const String endpointTicimaxUyeSaveUyeTuru = 'ticimax/uye/saveUyeTuru';
  static const String endpointTicimaxUyeSelectUyeAdres = 'ticimax/uye/selectUyeAdres';
  static const String endpointTicimaxUyeSelectUyeler = 'ticimax/uye/selectUyeler';
  static const String endpointTicimaxUyeSelectUyeTuru = 'ticimax/uye/selectUyeTuru';

  // --- HUGINZ (Swagger: /HuginZ/*) ---
  static const String endpointHuginZGetz = 'HuginZ/getz';

  // --- FINMAKS (Swagger: /Finmaks/*) ---
  static const String endpointFinmaksBankList = 'Finmaks/BankList';
  static const String endpointFinmaksInstitutionBanksList = 'Finmaks/InstitutionBanksList';
  static const String endpointFinmaksAddInstitutionBankIntegration = 'Finmaks/AddInstitutionBankIntegration';

  // --- PROMOSYON (Swagger: /promosyon/*) ---
  static const String endpointPromosyonListValidPm = 'promosyon/ListValidPm';
  static const String endpointPromosyonAddProdStage = 'promosyon/AddProdStage';
  static const String endpointPromosyonPaymentStage = 'promosyon/PaymentStage';
  static const String endpointPromosyonUsePm = 'promosyon/UsePm';

  // --- IDESOFT (Swagger: /idesoft/*) ---
  static const String endpointIdesoftBolgelerGetBolgeler = 'idesoft/bolgeler/getBolgeler';

  // --- IDEASOFT (Swagger: /ideasoft/*) ---
  static const String endpointIdeasoftCariGetCariList = 'ideasoft/cari/getCariList';
  static const String endpointIdeasoftCariSetCari = 'ideasoft/cari/setCari';
  static const String endpointIdeasoftCariUpdateCari = 'ideasoft/cari/updateCari';
  static const String endpointIdeasoftCariDeleteCari = 'ideasoft/cari/deleteCari';
  static const String endpointIdeasoftDistributorGetDistributor = 'ideasoft/Distributor/getDistributor';
  static const String endpointIdeasoftDistributorSetDistributor = 'ideasoft/Distributor/setDistributor';
  static const String endpointIdeasoftDistributorUpdateDistributor = 'ideasoft/Distributor/updateDistributor';
  static const String endpointIdeasoftDistributorDeleteDistributor = 'ideasoft/Distributor/deleteDistributor';
  static const String endpointIdeasoftDistributorUrunGetDistributorUrun = 'ideasoft/distributorUrun/GetDistributorUrun';
  static const String endpointIdeasoftDistributorUrunSetDistributorUrun = 'ideasoft/distributorUrun/setDistributorUrun';
  static const String endpointIdeasoftDistributorUrunUpdateDistributorUrunId = 'ideasoft/distributorUrun/updateDistributorUrun/{id}';
  static const String endpointIdeasoftDistributorUrunDeleteDistributorUrun = 'ideasoft/distributorUrun/deleteDistributorUrun';
  static const String endpointIdeasoftEkBilgiGetEkBilgi = 'ideasoft/ekBilgi/getEkBilgi';
  static const String endpointIdeasoftEkBilgiSetEkBilgi = 'ideasoft/ekBilgi/setEkBilgi';
  static const String endpointIdeasoftEkBilgiUpdateEkbilgi = 'ideasoft/ekBilgi/updateEkbilgi';
  static const String endpointIdeasoftEkBilgiDeleteEkBilgi = 'ideasoft/ekBilgi/deleteEkBilgi';
  static const String endpointIdeasoftEkBilgiUrunGetEkBilgiUrun = 'ideasoft/ekBilgiUrun/getEkBilgiUrun';
  static const String endpointIdeasoftEkBilgiUrunSetEkBilgiUrun = 'ideasoft/ekBilgiUrun/setEkBilgiUrun';
  static const String endpointIdeasoftEkBilgiUrunUpdateEkbilgiUrun = 'ideasoft/ekBilgiUrun/updateEkbilgiUrun';
  static const String endpointIdeasoftEkBilgiUrunDeleteEkBilgiUrun = 'ideasoft/ekBilgiUrun/deleteEkBilgiUrun';
  static const String endpointIdeasoftEkOzellikGetEkEkOzellik = 'ideasoft/ekOzellik/getEkEkOzellik';
  static const String endpointIdeasoftEkOzellikSetEkOzellik = 'ideasoft/ekOzellik/setEkOzellik';
  static const String endpointIdeasoftEkOzellikUpdateEkOzellik = 'ideasoft/ekOzellik/updateEkOzellik';
  static const String endpointIdeasoftEkOzellikDeleteEkOzellik = 'ideasoft/ekOzellik/deleteEkOzellik';
  static const String endpointIdeasoftEkOzellikGrupGetEkOzellikGrup = 'ideasoft/ekOzellikGrup/getEkOzellikGrup';
  static const String endpointIdeasoftEkOzellikGrupSetEkOzellikGrup = 'ideasoft/ekOzellikGrup/setEkOzellikGrup';
  static const String endpointIdeasoftEkOzellikGrupUpdateEkOzellikGrup = 'ideasoft/ekOzellikGrup/updateEkOzellikGrup';
  static const String endpointIdeasoftEkOzellikGrupDeleteEkOzellikGrup = 'ideasoft/ekOzellikGrup/deleteEkOzellikGrup';
  static const String endpointIdeasoftEkOzellikUrunGetOzellikUrun = 'ideasoft/EkOzellikUrun/getOzellikUrun';
  static const String endpointIdeasoftEkOzellikUrunSetOzellikUrun = 'ideasoft/EkOzellikUrun/setOzellikUrun';
  static const String endpointIdeasoftEkOzellikUrunUpdateOzellikUrun = 'ideasoft/EkOzellikUrun/updateOzellikUrun';
  static const String endpointIdeasoftEkOzellikUrunDeleteOzellikUrun = 'ideasoft/EkOzellikUrun/deleteOzellikUrun';
  static const String endpointIdeasoftEntegrasyonSecenekGetEntegrasyonSecenek = 'ideasoft/entegrasyonSecenek/getEntegrasyonSecenek';
  static const String endpointIdeasoftEntegrasyonSecenekSetEntegrasyonSecenek = 'ideasoft/entegrasyonSecenek/setEntegrasyonSecenek';
  static const String endpointIdeasoftEntegrasyonSecenekUpdateEntegrasyonSecenek = 'ideasoft/entegrasyonSecenek/updateEntegrasyonSecenek';
  static const String endpointIdeasoftEntegrasyonSecenekDeleteEntegrasyonSecenek = 'ideasoft/entegrasyonSecenek/deleteEntegrasyonSecenek';
  static const String endpointIdeasoftFaturaAdressGetEntegrasyonSecenek = 'ideasoft/faturaAdress/getEntegrasyonSecenek';
  static const String endpointIdeasoftFaturaAdressSetEntegrasyonSecenek = 'ideasoft/faturaAdress/setEntegrasyonSecenek';
  static const String endpointIdeasoftFaturaAdressUpdateEntegrasyonSecenek = 'ideasoft/faturaAdress/updateEntegrasyonSecenek';
  static const String endpointIdeasoftFaturaAdressDeleteEntegrasyonSecenek = 'ideasoft/faturaAdress/deleteEntegrasyonSecenek';
  static const String endpointIdeasoftFavoriUrunGet = 'ideasoft/favoriUrun/get';
  static const String endpointIdeasoftFavoriUrunSet = 'ideasoft/favoriUrun/set';
  static const String endpointIdeasoftFavoriUrunUpdate = 'ideasoft/favoriUrun/update';
  static const String endpointIdeasoftFavoriUrunDelete = 'ideasoft/favoriUrun/delete';
  static const String endpointIdeasoftHizliSatinAlBaglantiGet = 'ideasoft/hizliSatinAlBaglanti/get';
  static const String endpointIdeasoftHizliSatinAlBaglantiSet = 'ideasoft/hizliSatinAlBaglanti/set';
  static const String endpointIdeasoftHizliSatinAlBaglantiUpdate = 'ideasoft/hizliSatinAlBaglanti/update';
  static const String endpointIdeasoftHizliSatinAlBaglantiDelete = 'ideasoft/hizliSatinAlBaglanti/delete';
  static const String endpointIdeasoftIlcelerGet = 'ideasoft/ilceler/get';
  static const String endpointIdeasoftIlcelerSet = 'ideasoft/ilceler/set';
  static const String endpointIdeasoftIlcelerUpdate = 'ideasoft/ilceler/update';
  static const String endpointIdeasoftIlcelerDelete = 'ideasoft/ilceler/delete';
  static const String endpointIdeasoftKargoFirmalariGet = 'ideasoft/kargoFirmalari/get';
  static const String endpointIdeasoftKargoFirmalariSet = 'ideasoft/kargoFirmalari/set';
  static const String endpointIdeasoftKargoFirmalariUpdate = 'ideasoft/kargoFirmalari/update';
  static const String endpointIdeasoftKargoFirmalariDelete = 'ideasoft/kargoFirmalari/delete';
  static const String endpointIdeasoftKargoOranlari = 'ideasoft/kargoOranlari';
  static const String endpointIdeasoftKargoOranlariSet = 'ideasoft/kargoOranlari/set';
  static const String endpointIdeasoftKargoOranlariUpdate = 'ideasoft/kargoOranlari/update';
  static const String endpointIdeasoftKargoOranlariDelete = 'ideasoft/kargoOranlari/delete';
  static const String endpointIdeasoftLoginGirisyap = 'ideasoft/login/girisyap';
  static const String endpointIdeasoftLoginTokenyenile = 'ideasoft/login/tokenyenile';


}

// Numarator Web Servis Durum Kodları (Numarator.java)
class Numarator {
  static const int basarili = 1;
  static const int uyari = 2;
  static const int hata = 3;
  static const int onaysizBelge = 4;
  static const int bosTahsilat = 5;
  static const int onayliBelge = 6;
  static const int satirGuncellenemedi = 7;
  static const int bosBelge = 8;
  static const int belgeBulunamadi = 9;
  static const int eklenemeyenUrunVar = 10;
  static const int silinemeyenUrunVar = 11;
  static const int siparisBulunamadi = 12;
  static const int degerDonmedi = 13;
  static const int bulunamayanBarkod = 14;
  static const int apkVersiyonEski = 15;
  static const int wsVersiyonEski = 16;
  static const int miktarYanlis = 17;
  static const int bagliSiparis = 18;
  static const int cikisYap = 19;
  static const int tabloOlusturuldu = 20;
  static const int yetkiYok = 21;
  static const int tekrar = 22;
  static const int barkodKullaniliyor = 23;
  static const int baskaKullaniciTarafindanSilinis = 24;
  static const int projeYetkisiBulunmamakta = 25;
  static const int yoneticiOnayli = 26;
  static const int sahibiDegil = 27;
  static const int kodTekrari = 28;
}


