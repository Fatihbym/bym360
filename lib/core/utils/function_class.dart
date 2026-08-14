import 'package:intl/intl.dart';
import '../storage/save_settings.dart';
import '../../models/models.dart';

class FunctionClass {
  // Null-Safe Dönüştürücüler
  static double nuld(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) {
      if (val.trim().isEmpty) return 0.0;
      return double.tryParse(val.trim()) ?? 0.0;
    }
    return 0.0;
  }

  static int nult(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) {
      if (val.trim().isEmpty) return 0;
      return int.tryParse(val.trim()) ?? 0;
    }
    return 0;
  }

  static String nula(dynamic val) {
    if (val == null) return '';
    return val.toString();
  }

  // Kuruş Hassasiyeti Formatlayıcı
  static String kurusHassasiyeti(double sayi, [int hassasiyet = 2]) {
    return sayi.toStringAsFixed(hassasiyet);
  }

  // Sıfırları Temizleme (Tam Sayı ise Ondalığı Gösterme)
  static String sifiriAt(double d) {
    if (d == d.truncateToDouble()) {
      return d.toInt().toString();
    }
    return d.toString();
  }

  // Otomatik Barkod Üretici (EAN8 ve EAN13)
  static String barkodUret(String tip) {
    final now = DateFormat("dd.MM.yyyy HH:mm:ss").format(DateTime.now());
    String s = "${now.substring(6, 7)}${now.substring(8, 10)}${now.substring(3, 5)}${now.substring(0, 2)}${now.substring(11, 13)}${now.substring(14, 16)}${now.substring(18, 19)}${now.substring(17, 18)}";

    if (tip == "EAN8") {
      s = "${now.substring(9, 10)}${now.substring(4, 5)}${now.substring(1, 2)}${now.substring(12, 13)}${now.substring(15, 16)}${now.substring(17, 19)}";
      int toplam = 0;
      for (int x = 1; x < 8; x++) {
        int val = int.parse(s.substring(x - 1, x));
        toplam += (x % 2 == 0) ? val * 1 : val * 3;
      }
      int prefix = int.parse(toplam.toString().substring(0, toplam.toString().length - 1)) + 1;
      int kb = (prefix * 10) - toplam;
      return s.substring(0, 7) + kb.toString();
    } else if (tip == "EAN13") {
      int toplam = 0;
      for (int x = 1; x < 13; x++) {
        int val = int.parse(s.substring(x - 1, x));
        toplam += (x % 2 == 0) ? val * 3 : val * 1;
      }
      int prefix = int.parse(toplam.toString().substring(0, toplam.toString().length - 1)) + 1;
      int kb = (prefix * 10) - toplam;
      return s.substring(0, 12) + kb.toString();
    }
    return "";
  }

  // Kullanıcı Yetkisi Alma
  static String getKullaniciYetki(String kod) {
    for (var yetki in SaveSettings.yetkiList) {
      if (yetki.menuKod.toLowerCase() == kod.toLowerCase()) {
        return yetki.yetki;
      }
    }
    return 'H';
  }

  // Modül Ayarı ve Durumu
  static String getModulAyar(List<GetIslemMprm> mprmList, String nesne) {
    for (var item in mprmList) {
      if (item.nesne.toLowerCase() == nesne.toLowerCase()) {
        return item.deger;
      }
    }
    return '';
  }

  static int getModulDurum(List<GetIslemMprm> mprmList, String nesne) {
    for (var item in mprmList) {
      if (item.nesne.toLowerCase() == nesne.toLowerCase()) {
        return item.aDurum;
      }
    }
    return 0;
  }

  // Depo Giriş / Çıkış Yetki Kontrolü (1 = Giriş, 2 = Çıkış)
  static bool getDepoGirisCikis(String depoAdi, int tur) {
    for (var depo in SaveSettings.depoList) {
      if (depo.ad.toLowerCase() == depoAdi.toLowerCase()) {
        if (tur == 1) return depo.giris == 1;
        if (tur == 2) return depo.cikis == 1;
      }
    }
    return true;
  }

  // Şube & Depo ID Arama
  static int getSubeId(String subeAdi) {
    for (var sube in SaveSettings.subeList) {
      if (sube.ad.toLowerCase() == subeAdi.toLowerCase()) {
        return sube.id;
      }
    }
    return 0;
  }

  static int getDepoId(String depoAdi) {
    for (var depo in SaveSettings.tumDepolar) {
      String full = "${depo.ad} - ${depo.kod}";
      if (full.toLowerCase() == depoAdi.toLowerCase() || depo.ad.toLowerCase() == depoAdi.toLowerCase()) {
        return depo.id;
      }
    }
    return 0;
  }

  // Terazi Barkod Çözümleyici (Ağırlıklı / Fiyatlı Barkodlar 27xxxxx...)
  static Map<String, dynamic> teraziBarkodAyir(String barkod) {
    if (barkod.length == 13 && (barkod.startsWith("27") || barkod.startsWith("28") || barkod.startsWith("29"))) {
      String stokKodu = barkod.substring(2, 7);
      double miktarOrTutar = (double.tryParse(barkod.substring(7, 12)) ?? 0) / 1000.0;
      return {
        'isTerazi': true,
        'stokKodu': stokKodu,
        'deger': miktarOrTutar,
        'tur': barkod.startsWith("27") ? 'MIKTAR' : 'TUTAR',
      };
    }
    return {'isTerazi': false, 'stokKodu': '', 'deger': 1.0, 'tur': 'ADET'};
  }
}
