import '../core/utils/api_utils.dart';

class PostSuperUser {
  final int durum;
  final String token;
  final List<DbModel> db;
  final String? mesaj;

  int get superUserId => db.isNotEmpty ? db.first.aKulId : 0;
  String get superUserAdi => '';
  String get email => '';
  String get firma => (db.isNotEmpty && db.first.firma.isNotEmpty) ? db.first.firma.first.unvan : '';
  String get status => durum == 1 ? 'OK' : 'FAIL';


  PostSuperUser({
    this.durum = 0,
    this.token = '',
    this.db = const [],
    this.mesaj,
  });

  factory PostSuperUser.fromJson(Map<String, dynamic> json) {
    final durum = parseInt(json['DURUM'] ?? json['durum']);
    final token = (json['TOKEN'] ?? json['token'] ?? '').toString();
    final String? mesaj = json['MESAJ'] ?? json['mesaj'];

    List<DbModel> dbList = [];
    if (json['ICERIK'] != null && json['ICERIK'] is List) {
      dbList = (json['ICERIK'] as List).map((e) => DbModel.fromJson(e)).toList();
    } else if (json['DB'] != null && json['DB'] is List) {
      dbList = (json['DB'] as List).map((e) => DbModel.fromJson(e)).toList();
    }

    return PostSuperUser(
      durum: durum,
      token: token,
      db: dbList,
      mesaj: mesaj,
    );
  }
}

class GetSube {
  final int subeId;
  final String subeAdi;
  final String subeKodu;

  GetSube({required this.subeId, required this.subeAdi, required this.subeKodu});

  int get id => subeId;
  String get ad => subeAdi;
  String get kod => subeKodu;
  String get displayTitle => subeAdi.isNotEmpty ? subeAdi : 'Şube #$subeId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetSube && runtimeType == other.runtimeType && subeId == other.subeId;

  @override
  int get hashCode => subeId.hashCode;

  factory GetSube.fromJson(Map<String, dynamic> json) {
    return GetSube(
      subeId: json['SUBEID'] ?? json['subeId'] ?? 0,
      subeAdi: json['SUBEADI'] ?? json['subeAdi'] ?? '',
      subeKodu: json['SUBEKODU'] ?? json['subeKodu'] ?? '',
    );
  }
}

class GetDepo {
  final int depoId;
  final String depoAdi;
  final String depoKodu;
  final int subeId;
  final int giris;
  final int cikis;

  GetDepo({
    required this.depoId,
    required this.depoAdi,
    required this.depoKodu,
    required this.subeId,
    this.giris = 1,
    this.cikis = 1,
  });

  int get id => depoId;
  String get ad => depoAdi;
  String get kod => depoKodu;

  String get displayTitle => depoAdi.isNotEmpty ? depoAdi : 'Depo #$depoId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetDepo && runtimeType == other.runtimeType && depoId == other.depoId;

  @override
  int get hashCode => depoId.hashCode;

  factory GetDepo.fromJson(Map<String, dynamic> json) {
    return GetDepo(
      depoId: json['DEPOID'] ?? json['depoId'] ?? 0,
      depoAdi: json['DEPOADI'] ?? json['depoAdi'] ?? '',
      depoKodu: json['DEPOKODU'] ?? json['depoKodu'] ?? '',
      subeId: json['SUBEID'] ?? json['subeId'] ?? 0,
      giris: json['GIRIS'] ?? json['giris'] ?? 1,
      cikis: json['CIKIS'] ?? json['cikis'] ?? 1,
    );
  }
}

class GetCari {
  final int cariId;
  final String cariKod;
  final String cariAd;
  final String unvan;
  final String yetkili;
  final String kullaniciAdi;
  final String bakiyeTur;
  final String adres;
  final String telefon;
  final String gsm;
  final double bakiye;

  GetCari({
    required this.cariId,
    required this.cariKod,
    required this.cariAd,
    this.unvan = '',
    this.yetkili = '',
    this.kullaniciAdi = '',
    this.bakiyeTur = '',
    required this.adres,
    required this.telefon,
    required this.gsm,
    required this.bakiye,
  });

  String get displayTitle {
    if (cariAd.isNotEmpty) return cariAd;
    if (unvan.isNotEmpty) return unvan;
    if (cariKod.isNotEmpty) return 'Cari ($cariKod)';
    return 'Cari #$cariId';
  }

  String get displayUserOrAuthor {
    if (kullaniciAdi.isNotEmpty) return kullaniciAdi;
    if (yetkili.isNotEmpty) return yetkili;
    return '';
  }

  factory GetCari.fromJson(Map<String, dynamic> json) {
    // API /mobwaycloud/Get_CariAra returns: "AD", "KOD", "ID", "BAKIYE"
    final rawAd = (json['AD'] ??
            json['CARIAD'] ??
            json['CARIADI'] ??
            json['CARIUNVAN'] ??
            json['UNVAN'] ??
            json['cariAd'] ??
            json['KULLANICIADI'] ??
            json['KULLANICI_ADI'] ??
            json['KULADI'] ??
            json['ISIM'] ??
            json['NAME'] ??
            '')
        .toString();

    final rawKod = (json['KOD'] ??
            json['CARIKOD'] ??
            json['CARIKODU'] ??
            json['cariKod'] ??
            json['CODE'] ??
            '')
        .toString();

    final rawUnvan = (json['CARIUNVAN'] ?? json['UNVAN'] ?? json['unvan'] ?? '').toString();

    final rawYetkili = (json['YETKILI'] ??
            json['YETKILI_ADI'] ??
            json['KULLANICIADI'] ??
            json['KULLANICI_ADI'] ??
            json['KULADI'] ??
            '')
        .toString();

    final rawKulAdi = (json['KULLANICIADI'] ??
            json['KULLANICI_ADI'] ??
            json['KULADI'] ??
            json['USERNAME'] ??
            '')
        .toString();

    final rawAdres = (json['CARIADRES'] ?? json['ADRES'] ?? json['adres'] ?? '').toString();
    final rawTel = (json['CARITEL'] ?? json['TELEFON'] ?? json['TEL'] ?? json['telefon'] ?? '').toString();
    final rawGsm = (json['CARIGSM'] ?? json['GSM'] ?? json['gsm'] ?? '').toString();
    final rawBakiyeTur = (json['BAKIYETUR'] ?? json['bakiyeTur'] ?? '').toString();

    final bakiyeVal = json['BAKIYE'] ?? json['bakiye'] ?? 0;
    final bakiyeDouble = (bakiyeVal is num) ? bakiyeVal.toDouble() : (double.tryParse(bakiyeVal.toString()) ?? 0.0);

    final idVal = json['ID'] ?? json['CARIID'] ?? json['CARI_ID'] ?? json['cariId'] ?? 0;
    final idInt = (idVal is int) ? idVal : (int.tryParse(idVal.toString()) ?? 0);

    return GetCari(
      cariId: idInt,
      cariKod: rawKod,
      cariAd: rawAd,
      unvan: rawUnvan,
      yetkili: rawYetkili,
      kullaniciAdi: rawKulAdi,
      bakiyeTur: rawBakiyeTur,
      adres: rawAdres,
      telefon: rawTel,
      gsm: rawGsm,
      bakiye: bakiyeDouble,
    );
  }
}

class GetStok {
  final int stokId;
  final String stokKodu;
  final String stokAdi;
  final String barkod;
  final String birim;
  final double kdv;
  final double satisFiyat;
  final double alisFiyat;
  final double bakiye;

  GetStok({
    required this.stokId,
    required this.stokKodu,
    required this.stokAdi,
    required this.barkod,
    required this.birim,
    required this.kdv,
    required this.satisFiyat,
    required this.alisFiyat,
    required this.bakiye,
  });

  double get satisFiyati => satisFiyat;

  factory GetStok.fromJson(Map<String, dynamic> json) {
    return GetStok(
      stokId: json['ID'] ?? json['STOKID'] ?? json['stokId'] ?? 0,
      stokKodu: json['STOKKOD'] ?? json['STOKKODU'] ?? json['KOD'] ?? json['stokKodu'] ?? '',
      stokAdi: json['STOKAD'] ?? json['STOKADI'] ?? json['AD'] ?? json['stokAdi'] ?? '',
      barkod: json['STOKBARKOD'] ?? json['BARKOD'] ?? json['barkod'] ?? '',
      birim: json['BIRIM'] ?? json['STOKBIRIM'] ?? json['birim'] ?? 'ADET',
      kdv: (json['KDV'] ?? json['SAKDV'] ?? 0).toDouble(),
      satisFiyat: (json['URUNFIYAT'] ?? json['SFIYAT'] ?? json['SATISFIYAT'] ?? json['ANABFIYAT'] ?? 0).toDouble(),
      alisFiyat: (json['AFIYAT'] ?? json['ALISFIYAT'] ?? 0).toDouble(),
      bakiye: (json['BAKIYE'] ?? json['STOKMIKTAR'] ?? json['KALAN'] ?? 0).toDouble(),
    );
  }
}

class GetStokLot {
  final int id;
  final String lotNo;
  final String skt;
  final double miktar;

  GetStokLot({
    required this.id,
    required this.lotNo,
    required this.skt,
    required this.miktar,
  });

  factory GetStokLot.fromJson(Map<String, dynamic> json) {
    return GetStokLot(
      id: parseInt(json['ID'] ?? json['id']),
      lotNo: (json['LOTNO'] ?? json['lotNo'] ?? json['LOT'] ?? '').toString(),
      skt: (json['SKT'] ?? json['skt'] ?? json['SONKULLANMATARIHI'] ?? '').toString(),
      miktar: parseDouble(json['MIKTAR'] ?? json['miktar']),
    );
  }
}

class GetStokSeviyeKontrol {
  final int stokId;
  final String stokKodu;
  final String stokAdi;
  final double mevcutMiktar;
  final double minSeviye;
  final double maxSeviye;
  final String durum;

  GetStokSeviyeKontrol({
    required this.stokId,
    required this.stokKodu,
    required this.stokAdi,
    required this.mevcutMiktar,
    required this.minSeviye,
    required this.maxSeviye,
    required this.durum,
  });

  factory GetStokSeviyeKontrol.fromJson(Map<String, dynamic> json) {
    return GetStokSeviyeKontrol(
      stokId: parseInt(json['STOKID'] ?? json['stokId']),
      stokKodu: (json['STOKKODU'] ?? json['stokKodu'] ?? '').toString(),
      stokAdi: (json['STOKADI'] ?? json['stokAdi'] ?? '').toString(),
      mevcutMiktar: parseDouble(json['MEVCUTMIKTAR'] ?? json['mevcutMiktar']),
      minSeviye: parseDouble(json['MINSEVIYE'] ?? json['minSeviye']),
      maxSeviye: parseDouble(json['MAXSEVIYE'] ?? json['maxSeviye']),
      durum: (json['DURUM'] ?? json['durum'] ?? 'NORMAL').toString(),
    );
  }
}

class GetBelgeListele {
  final int belgeId;
  final String belgeNo;
  final int belgeTuru;
  final String belgeTurAdi;
  final String cariAdi;
  final String tarih;
  final double genelToplam;
  final String aciklama;
  final String cikisDepo;
  final String varisDepo;
  final int cikisDepoId;
  final int varisDepoId;

  GetBelgeListele({
    required this.belgeId,
    required this.belgeNo,
    required this.belgeTuru,
    required this.belgeTurAdi,
    required this.cariAdi,
    required this.tarih,
    required this.genelToplam,
    required this.aciklama,
    this.cikisDepo = '',
    this.varisDepo = '',
    this.cikisDepoId = 0,
    this.varisDepoId = 0,
  });

  factory GetBelgeListele.fromJson(Map<String, dynamic> json) {
    return GetBelgeListele(
      belgeId: parseInt(json['FISID'] ?? json['BELGEID'] ?? json['ID'] ?? json['belgeId']),
      belgeNo: (json['BELGENO'] ?? json['EVRAKNO'] ?? json['belgeNo'] ?? '').toString(),
      belgeTuru: parseInt(json['FISTURID'] ?? json['BELGETURU'] ?? json['belgeTuru'] ?? json['FISTUR']),
      belgeTurAdi: (json['FISTURADI'] ?? json['FISTUR'] ?? json['BELGETURADI'] ?? json['belgeTurAdi'] ?? '').toString(),
      cariAdi: (json['CARIADI'] ?? json['CARIAD'] ?? json['CARI'] ?? json['cariAdi'] ?? '').toString(),
      tarih: (json['FISTARIH'] ?? json['TARIH'] ?? json['BELGETARIH'] ?? json['tarih'] ?? '').toString(),
      genelToplam: parseDouble(json['GENELTOPLAM'] ?? json['TUTAR'] ?? json['TOPLAM'] ?? json['genelToplam']),
      aciklama: (json['ACIKLAMA'] ?? json['aciklama'] ?? '').toString(),
      cikisDepo: (json['CIKISDEPOADI'] ?? json['CIKISDEPO'] ?? json['DEPOADI'] ?? '').toString(),
      varisDepo: (json['VARISDEPOADI'] ?? json['VARISDEPO'] ?? json['GIRISDEPOADI'] ?? '').toString(),
      cikisDepoId: parseInt(json['CIKISDEPOID'] ?? json['DEPOID']),
      varisDepoId: parseInt(json['VARISDEPOID'] ?? json['GIRISDEPOID']),
    );
  }
}

class GetBelgeIcerik {
  final int satirId;
  final int belgeId;
  final int stokId;
  final String stokKodu;
  final String stokAdi;
  final String barkod;
  final double miktar;
  final String birim;
  final double birimFiyat;
  final double tutar;

  GetBelgeIcerik({
    required this.satirId,
    required this.belgeId,
    required this.stokId,
    required this.stokKodu,
    required this.stokAdi,
    required this.barkod,
    required this.miktar,
    required this.birim,
    required this.birimFiyat,
    required this.tutar,
  });

  factory GetBelgeIcerik.fromJson(Map<String, dynamic> json) {
    return GetBelgeIcerik(
      satirId: parseInt(json['URUNSIRA'] ?? json['SATIRID'] ?? json['DID'] ?? json['satirId']),
      belgeId: parseInt(json['BELGEID'] ?? json['FISID'] ?? json['belgeId']),
      stokId: parseInt(json['STOKID'] ?? json['URUNID'] ?? json['stokId']),
      stokKodu: (json['URUNKODU'] ?? json['STOKKODU'] ?? json['STOKKOD'] ?? json['KOD'] ?? json['stokKodu'] ?? '').toString(),
      stokAdi: (json['URUNADI'] ?? json['URUNAD'] ?? json['STOKADI'] ?? json['STOKAD'] ?? json['AD'] ?? json['stokAdi'] ?? '').toString(),
      barkod: (json['URUNBARKODU'] ?? json['STOKBARKOD'] ?? json['BARKOD'] ?? json['barkod'] ?? '').toString(),
      miktar: parseDouble(json['URUNMİKTARI'] ?? json['URUNMIKTARI'] ?? json['MIKTAR'] ?? json['miktar']),
      birim: (json['STOKBIRIM'] ?? json['BIRIM'] ?? json['birim'] ?? 'ADET').toString(),
      birimFiyat: parseDouble(json['BIRIMFIYAT'] ?? json['STOKBIRIMFIY'] ?? json['FIYAT'] ?? json['birimFiyat']),
      tutar: parseDouble(json['TUTARTOPLAM'] ?? json['SATIRTUTAR'] ?? json['TUTAR'] ?? json['tutar']),
    );
  }
}

class GetFiyatGor {
  final int stokId;
  final String stokKodu;
  final String stokAdi;
  final String barkod;
  final String stok1Barkod;
  final String stok2Barkod;
  final String stokLotAdi;
  final String stokGrup;
  final double satisFiyat;
  final double alisFiyat;
  final double dipFiyat;
  final String kampanyaFiyat;
  final double ozelFiyat1;
  final double ozelFiyat2;
  final double ozelFiyat3;
  final double ozelFiyat4;
  final double ozelFiyat5;
  final double ozelFiyat6;
  final double ortalamaMaliyet;
  final double sonMaliyet;
  final double kdv;
  final String birim;
  final double kalan;

  double get depoStokMiktar => kalan;

  GetFiyatGor({
    required this.stokId,
    required this.stokKodu,
    required this.stokAdi,
    required this.barkod,
    this.stok1Barkod = '',
    this.stok2Barkod = '',
    this.stokLotAdi = '',
    this.stokGrup = '',
    required this.satisFiyat,
    required this.alisFiyat,
    this.dipFiyat = 0,
    this.kampanyaFiyat = '',
    this.ozelFiyat1 = 0,
    this.ozelFiyat2 = 0,
    this.ozelFiyat3 = 0,
    this.ozelFiyat4 = 0,
    this.ozelFiyat5 = 0,
    this.ozelFiyat6 = 0,
    this.ortalamaMaliyet = 0,
    this.sonMaliyet = 0,
    required this.kdv,
    required this.birim,
    this.kalan = 0,
  });

  factory GetFiyatGor.fromJson(Map<String, dynamic> json) {
    return GetFiyatGor(
      stokId: json['STOKID'] ?? json['ID'] ?? 0,
      stokKodu: json['STOKKODU'] ?? json['KOD'] ?? '',
      stokAdi: json['STOKADI'] ?? json['AD'] ?? '',
      barkod: json['BARKOD'] ?? '',
      stok1Barkod: json['STOK1BARKOD'] ?? '',
      stok2Barkod: json['STOK2BARKOD'] ?? '',
      stokLotAdi: json['STOKLOTADI'] ?? '',
      stokGrup: json['GRUP1'] ?? json['STOKGRUP1'] ?? '',
      satisFiyat: (json['SATISFIYAT'] ?? json['SFIYAT'] ?? 0).toDouble(),
      alisFiyat: (json['ALISFIYAT'] ?? json['AFIYAT'] ?? 0).toDouble(),
      dipFiyat: (json['DIPFIYAT'] ?? 0).toDouble(),
      kampanyaFiyat: (json['KAMSFIYAT'] ?? '').toString(),
      ozelFiyat1: (json['OFIYAT1'] ?? 0).toDouble(),
      ozelFiyat2: (json['OFIYAT2'] ?? 0).toDouble(),
      ozelFiyat3: (json['OFIYAT3'] ?? 0).toDouble(),
      ozelFiyat4: (json['OFIYAT4'] ?? 0).toDouble(),
      ozelFiyat5: (json['OFIYAT5'] ?? 0).toDouble(),
      ozelFiyat6: (json['OFIYAT6'] ?? 0).toDouble(),
      ortalamaMaliyet: (json['OMALIYET'] ?? 0).toDouble(),
      sonMaliyet: (json['SMALIYET'] ?? 0).toDouble(),
      kdv: (json['KDV'] ?? 0).toDouble(),
      birim: json['BIRIM'] ?? 'ADET',
      kalan: (json['KALAN'] ?? json['DEPOSTOKMIKTAR'] ?? 0).toDouble(),
    );
  }
}

class GetKasalar {
  final int kasaId;
  final String kasaKodu;
  final String kasaAdi;

  GetKasalar({required this.kasaId, required this.kasaKodu, required this.kasaAdi});

  factory GetKasalar.fromJson(Map<String, dynamic> json) {
    return GetKasalar(
      kasaId: json['KASAID'] ?? 0,
      kasaKodu: json['KASAKODU'] ?? '',
      kasaAdi: json['KASAADI'] ?? '',
    );
  }
}

class GetBankalar {
  final int bankaId;
  final String bankaKodu;
  final String bankaAdi;

  GetBankalar({required this.bankaId, required this.bankaKodu, required this.bankaAdi});

  factory GetBankalar.fromJson(Map<String, dynamic> json) {
    return GetBankalar(
      bankaId: json['BANKAID'] ?? 0,
      bankaKodu: json['BANKAKODU'] ?? '',
      bankaAdi: json['BANKAADI'] ?? '',
    );
  }
}

class GetDovizler {
  final int dovizId;
  final String dovizKodu;
  final String dovizAdi;
  final double kur;
  final String aBirim;
  final int bSay;
  final String simge;
  final int durum;

  GetDovizler({
    required this.dovizId,
    required this.dovizKodu,
    required this.dovizAdi,
    this.kur = 1.0,
    this.aBirim = '',
    this.bSay = 0,
    this.simge = '',
    this.durum = 1,
  });

  factory GetDovizler.fromJson(Map<String, dynamic> json) {
    return GetDovizler(
      dovizId: json['ID'] ?? json['DOVIZID'] ?? 0,
      dovizKodu: json['KOD'] ?? json['DOVIZKODU'] ?? '',
      dovizAdi: json['ADI'] ?? json['DOVIZADI'] ?? '',
      kur: (json['KUR'] ?? 1.0).toDouble(),
      aBirim: json['ABIRIM'] ?? '',
      bSay: json['BSAY'] ?? 0,
      simge: json['SIMGE'] ?? '',
      durum: json['DURUM'] ?? 1,
    );
  }
}


class GetTahsilatListe {
  final int tahsilatId;
  final String tarih;
  final String cariAdi;
  final double tutar;
  final String aciklama;
  final String tur; // KASA or BANKA

  GetTahsilatListe({
    required this.tahsilatId,
    required this.tarih,
    required this.cariAdi,
    required this.tutar,
    required this.aciklama,
    required this.tur,
  });

  factory GetTahsilatListe.fromJson(Map<String, dynamic> json) {
    return GetTahsilatListe(
      tahsilatId: json['TAHSILATID'] ?? 0,
      tarih: json['TARIH'] ?? '',
      cariAdi: json['CARIADI'] ?? '',
      tutar: (json['TUTAR'] ?? 0).toDouble(),
      aciklama: json['ACIKLAMA'] ?? '',
      tur: json['TUR'] ?? 'KASA',
    );
  }
}

class GetAjanda {
  final int perId;
  final String perAd;
  final int sira;
  final String tarih;
  final int saat;
  final String yer;
  final String notlar;
  final String durum;
  final String sonuc;
  final int kPerId;
  final String kTarih;
  final int kSaat;

  GetAjanda({
    this.perId = 0,
    this.perAd = '',
    this.sira = 0,
    this.tarih = '',
    this.saat = 8,
    this.yer = 'AJANDA',
    this.notlar = '',
    this.durum = 'Beklemede',
    this.sonuc = '',
    this.kPerId = 0,
    this.kTarih = '',
    this.kSaat = 0,
  });

  bool get tamamlandi => durum == 'Tamamlandı';
  String get baslik => notlar.isNotEmpty ? notlar : 'Görev #$sira';
  String get aciklama => sonuc.isNotEmpty ? sonuc : yer;

  DateTime? get dateTime {
    try {
      if (tarih.isEmpty) return null;
      final parts = tarih.split('-');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
      final partsDot = tarih.split('.');
      if (partsDot.length == 3) {
        return DateTime(int.parse(partsDot[2]), int.parse(partsDot[1]), int.parse(partsDot[0]));
      }
    } catch (_) {}
    return null;
  }

  factory GetAjanda.fromJson(Map<String, dynamic> json) {
    return GetAjanda(
      perId: json['PERID'] ?? json['perId'] ?? 0,
      perAd: json['PERAD'] ?? json['perAd'] ?? '',
      sira: json['SIRA'] ?? json['sira'] ?? 0,
      tarih: (json['TARIH'] ?? json['tarih'] ?? '').toString(),
      saat: json['SAAT'] ?? json['saat'] ?? 8,
      yer: json['YER'] ?? json['yer'] ?? 'AJANDA',
      notlar: (json['NOTLAR'] ?? json['notlar'] ?? json['BASLIK'] ?? '').toString(),
      durum: (json['STATUS'] ?? json['DURUM'] ?? json['durum'] ?? 'Beklemede').toString(),
      sonuc: (json['SONUC'] ?? json['sonuc'] ?? json['ACIKLAMA'] ?? '').toString(),
      kPerId: json['KPERID'] ?? json['kPerId'] ?? 0,
      kTarih: (json['KTARIH'] ?? json['kTarih'] ?? '').toString(),
      kSaat: json['KSAAT'] ?? json['kSaat'] ?? 0,
    );
  }
}

class GetTopluEtiket {
  final int stokId;
  final String stokKodu;
  final String stokAdi;
  final String barkod;
  int miktar;
  bool yazdir;

  GetTopluEtiket({
    required this.stokId,
    required this.stokKodu,
    required this.stokAdi,
    required this.barkod,
    this.miktar = 1,
    this.yazdir = false,
  });

  factory GetTopluEtiket.fromJson(Map<String, dynamic> json) {
    return GetTopluEtiket(
      stokId: parseInt(json['STOKID'] ?? json['ID'] ?? json['stokId']),
      stokKodu: (json['STOKKODU'] ?? json['STOKKOD'] ?? json['stokKodu'] ?? '').toString(),
      stokAdi: (json['STOKADI'] ?? json['STOKAD'] ?? json['stokAdi'] ?? '').toString(),
      barkod: (json['STOKBARKODU'] ?? json['BARKOD'] ?? json['barkod'] ?? '').toString(),
      miktar: parseInt(json['MIKTAR'] ?? json['miktar'] ?? 1),
      yazdir: json['YAZDIR'] == true || json['YAZDIR'] == 1,
    );
  }
}

class GetStokDetay {
  final int stokId;
  final String stokKodu;
  final String stokAdi;
  final String barkod;
  final double satisFiyat;
  final double alisFiyat;

  GetStokDetay({
    required this.stokId,
    required this.stokKodu,
    required this.stokAdi,
    required this.barkod,
    required this.satisFiyat,
    required this.alisFiyat,
  });

  factory GetStokDetay.fromJson(Map<String, dynamic> json) {
    return GetStokDetay(
      stokId: json['STOKID'] ?? 0,
      stokKodu: json['STOKKODU'] ?? '',
      stokAdi: json['STOKADI'] ?? '',
      barkod: json['BARKOD'] ?? '',
      satisFiyat: (json['SATISFIYAT'] ?? 0).toDouble(),
      alisFiyat: (json['ALISFIYAT'] ?? 0).toDouble(),
    );
  }
}

class GetUrunEkle {
  final int stokId;
  final String stokAdi;
  final String barkod;
  final double miktar;
  final double fiyat;

  GetUrunEkle({
    required this.stokId,
    required this.stokAdi,
    required this.barkod,
    required this.miktar,
    required this.fiyat,
  });

  factory GetUrunEkle.fromJson(Map<String, dynamic> json) {
    return GetUrunEkle(
      stokId: json['STOKID'] ?? 0,
      stokAdi: json['STOKADI'] ?? '',
      barkod: json['BARKOD'] ?? '',
      miktar: (json['MIKTAR'] ?? 0).toDouble(),
      fiyat: (json['FIYAT'] ?? 0).toDouble(),
    );
  }
}



class GetMatbuTasarim {
  final int tasarimId;
  final String tasarimAdi;
  final String matbuTuru;

  GetMatbuTasarim({
    required this.tasarimId,
    required this.tasarimAdi,
    required this.matbuTuru,
  });

  int get id => tasarimId;
  String get adi => tasarimAdi;

  factory GetMatbuTasarim.fromJson(Map<String, dynamic> json) {
    return GetMatbuTasarim(
      tasarimId: json['TASARIMID'] ?? json['ID'] ?? 0,
      tasarimAdi: json['TASARIMADI'] ?? json['ADI'] ?? '',
      matbuTuru: json['MATBUTURU'] ?? '',
    );
  }
}

class GetKisayollar {
  final int kisayolId;
  final String baslik;
  final String modul;
  final String ikon;

  GetKisayollar({
    required this.kisayolId,
    required this.baslik,
    required this.modul,
    required this.ikon,
  });

  factory GetKisayollar.fromJson(Map<String, dynamic> json) {
    return GetKisayollar(
      kisayolId: json['KISAYOLID'] ?? 0,
      baslik: json['BASLIK'] ?? '',
      modul: json['MODUL'] ?? '',
      ikon: json['IKON'] ?? '',
    );
  }
}

class GetBluetoothDevice {
  final String name;
  final String address;
  final bool connected;

  GetBluetoothDevice({
    required this.name,
    required this.address,
    this.connected = false,
  });

  factory GetBluetoothDevice.fromJson(Map<String, dynamic> json) {
    return GetBluetoothDevice(
      name: json['NAME'] ?? json['name'] ?? 'Bilinmeyen Cihaz',
      address: json['ADDRESS'] ?? json['address'] ?? '',
      connected: json['CONNECTED'] ?? json['connected'] ?? false,
    );
  }
}

class GetPersonel {
  final int personelId;
  final String personelAdi;
  final String unvan;

  GetPersonel({
    required this.personelId,
    required this.personelAdi,
    required this.unvan,
  });

  int get perId => personelId;
  String get perAd => personelAdi;
  String get displayTitle => personelAdi.isNotEmpty ? personelAdi : 'Personel #$personelId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetPersonel && runtimeType == other.runtimeType && personelId == other.personelId;

  @override
  int get hashCode => personelId.hashCode;

  factory GetPersonel.fromJson(Map<String, dynamic> json) {
    return GetPersonel(
      personelId: json['PERSONELID'] ?? 0,
      personelAdi: json['PERSONELADI'] ?? '',
      unvan: json['UNVAN'] ?? '',
    );
  }
}

// Additional Mobway Models
class BelgeTurleri {
  final String belge;
  final String belgeId;

  BelgeTurleri({required this.belge, required this.belgeId});
}

class GetIslemKprm {
  final int durum;
  final int userId;
  final String nesne;
  final String deger;

  GetIslemKprm({
    required this.durum,
    required this.userId,
    required this.nesne,
    required this.deger,
  });

  factory GetIslemKprm.fromJson(Map<String, dynamic> json) {
    return GetIslemKprm(
      durum: json['DURUM'] ?? 0,
      userId: json['USERID'] ?? 0,
      nesne: json['NESNE'] ?? '',
      deger: json['DEGER'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'DURUM': durum,
    'USERID': userId,
    'NESNE': nesne,
    'DEGER': deger,
  };
}

class GetIslemMprm {
  final int durum;
  final int mId;
  final String nesne;
  final String deger;
  final int aDurum;

  GetIslemMprm({
    required this.durum,
    required this.mId,
    required this.nesne,
    required this.deger,
    required this.aDurum,
  });

  factory GetIslemMprm.fromJson(Map<String, dynamic> json) {
    return GetIslemMprm(
      durum: json['DURUM'] ?? 0,
      mId: json['MID'] ?? 0,
      nesne: json['NESNE'] ?? '',
      deger: json['DEGER'] ?? '',
      aDurum: json['ADURUM'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'DURUM': durum,
    'MID': mId,
    'NESNE': nesne,
    'DEGER': deger,
    'ADURUM': aDurum,
  };
}

class GetMobYetki {
  final int id;
  final int userId;
  final String yetkiAdi;
  final bool izin;

  GetMobYetki({
    required this.id,
    required this.userId,
    required this.yetkiAdi,
    required this.izin,
  });

  String get menuKod => yetkiAdi;
  String get yetki => izin ? 'E' : 'H';

  factory GetMobYetki.fromJson(Map<String, dynamic> json) {
    return GetMobYetki(
      id: json['ID'] ?? 0,
      userId: json['USERID'] ?? 0,
      yetkiAdi: json['YETKIADI'] ?? json['MENUKOD'] ?? '',
      izin: (json['IZIN'] ?? 0) == 1 || (json['YETKI'] ?? '') == 'E',
    );
  }
}

class GetCariHesapEkstre {
  final int hareketId;
  final String tarih;
  final String evrakNo;
  final String islemTuru;
  final double tutar;
  final double borc;
  final double alacak;
  final double bakiye;
  final String bakiyeTur;
  final String aciklama;
  final String yerAdi;

  GetCariHesapEkstre({
    required this.hareketId,
    required this.tarih,
    required this.evrakNo,
    required this.islemTuru,
    required this.tutar,
    required this.borc,
    required this.alacak,
    required this.bakiye,
    this.bakiyeTur = '',
    required this.aciklama,
    this.yerAdi = '',
  });

  String get displayTitle {
    String title = islemTuru.trim();
    if (title.isEmpty || title == '0') title = yerAdi.trim();
    if (title.isEmpty || title == '0') title = aciklama.trim();
    if (title.isEmpty || title == '0') title = 'Devir / Cari Hareket';

    final evrak = evrakNo.trim().replaceAll('(', '').replaceAll(')', '').trim();
    if (evrak.isNotEmpty && evrak != '0') {
      return '$title ($evrak)';
    }
    return title;
  }

  factory GetCariHesapEkstre.fromJson(Map<String, dynamic> json) {
    final rawEvrakNo = (json['BELGENO'] ?? json['EVRAKNO'] ?? json['belgeNo'] ?? json['evrakNo'] ?? '').toString();
    final rawIslemTuru = (json['ISLEMTURU'] ?? json['FISTUR'] ?? json['islemTuru'] ?? json['TUR'] ?? '').toString();
    final rawTarih = (json['TARIH'] ?? json['BTARIH'] ?? json['tarih'] ?? '').toString();
    final rawAciklama = (json['ACIKLAMA'] ?? json['aciklama'] ?? '').toString();
    final rawYerAdi = (json['YERADI'] ?? json['yerAdi'] ?? '').toString();
    final rawBakiyeTur = (json['BAKIYETUR'] ?? json['bakiyeTur'] ?? '').toString();

    return GetCariHesapEkstre(
      hareketId: parseInt(json['NGCID'] ?? json['HAREKETID'] ?? json['ID']),
      tarih: rawTarih,
      evrakNo: rawEvrakNo,
      islemTuru: rawIslemTuru,
      tutar: parseDouble(json['TUTAR'] ?? json['tutar']),
      borc: parseDouble(json['BORC'] ?? json['borc']),
      alacak: parseDouble(json['ALACAK'] ?? json['alacak']),
      bakiye: parseDouble(json['BAKIYE'] ?? json['bakiye']),
      bakiyeTur: rawBakiyeTur,
      aciklama: rawAciklama,
      yerAdi: rawYerAdi,
    );
  }
}

class GetTeraziBarkod {
  final int durum;
  final String teraziBarkod;
  final int barkodMik;
  final int miktarMik;

  GetTeraziBarkod({
    this.durum = 1,
    required this.teraziBarkod,
    this.barkodMik = 0,
    this.miktarMik = 0,
  });

  factory GetTeraziBarkod.fromJson(Map<String, dynamic> json) {
    return GetTeraziBarkod(
      durum: json['DURUM'] ?? 1,
      teraziBarkod: json['TERAZIBARKOD'] ?? '',
      barkodMik: json['BARKODMIK'] ?? 0,
      miktarMik: json['MIKTARMIK'] ?? 0,
    );
  }
}


class GetYaziciListele {
  final int yaziciId;
  final String yaziciAdi;
  final String macAdresi;
  final String baglantiTuru;

  GetYaziciListele({
    required this.yaziciId,
    required this.yaziciAdi,
    required this.macAdresi,
    required this.baglantiTuru,
  });

  int get id => yaziciId;
  String get adi => yaziciAdi;
  String get tur => baglantiTuru;

  factory GetYaziciListele.fromJson(Map<String, dynamic> json) {
    return GetYaziciListele(
      yaziciId: json['YAZICIID'] ?? json['ID'] ?? 0,
      yaziciAdi: json['YAZICIADI'] ?? json['ADI'] ?? '',
      macAdresi: json['MACADRESI'] ?? '',
      baglantiTuru: json['BAGLANTITURU'] ?? json['TUR'] ?? 'Bluetooth',
    );
  }
}

class GetBelgeKapatListe {
  final int belgeId;
  final String belgeNo;
  final int belgeTuru;
  final String belgeTurAdi;
  final String cariAdi;
  final int cariId;
  final String tarih;
  final double genelToplam;
  final String durum;

  GetBelgeKapatListe({
    required this.belgeId,
    required this.belgeNo,
    this.belgeTuru = 0,
    this.belgeTurAdi = '',
    required this.cariAdi,
    this.cariId = 0,
    required this.tarih,
    required this.genelToplam,
    required this.durum,
  });

  factory GetBelgeKapatListe.fromJson(Map<String, dynamic> json) {
    return GetBelgeKapatListe(
      belgeId: parseInt(json['FISID'] ?? json['BELGEID'] ?? json['ID'] ?? json['belgeId']),
      belgeNo: (json['BELGENO'] ?? json['EVRAKNO'] ?? json['belgeNo'] ?? '').toString(),
      belgeTuru: parseInt(json['FISTURID'] ?? json['BELGETURU'] ?? json['FISTUR'] ?? json['belgeTuru']),
      belgeTurAdi: (json['FISTURADI'] ?? json['FISTUR'] ?? json['BELGETURADI'] ?? json['belgeTurAdi'] ?? '').toString(),
      cariAdi: (json['CARIADI'] ?? json['CARIAD'] ?? json['CARI'] ?? json['cariAdi'] ?? '').toString(),
      cariId: parseInt(json['CARIID'] ?? json['cariId']),
      tarih: (json['FISTARIH'] ?? json['TARIH'] ?? json['BELGETARIH'] ?? json['tarih'] ?? '').toString(),
      genelToplam: parseDouble(json['GENELTOPLAM'] ?? json['TUTAR'] ?? json['TOPLAM'] ?? json['genelToplam']),
      durum: (json['DURUM'] ?? 'ACIK').toString(),
    );
  }
}

class GetBelgeIciStokAra {
  final int stokId;
  final String stokKodu;
  final String stokAdi;
  final String barkod;
  final double miktar;

  GetBelgeIciStokAra({
    required this.stokId,
    required this.stokKodu,
    required this.stokAdi,
    required this.barkod,
    required this.miktar,
  });

  factory GetBelgeIciStokAra.fromJson(Map<String, dynamic> json) {
    return GetBelgeIciStokAra(
      stokId: json['STOKID'] ?? 0,
      stokKodu: json['STOKKODU'] ?? '',
      stokAdi: json['STOKADI'] ?? '',
      barkod: json['BARKOD'] ?? '',
      miktar: (json['MIKTAR'] ?? 0).toDouble(),
    );
  }
}

class GetBelgenoUret {
  final String belgeNo;

  GetBelgenoUret({required this.belgeNo});

  factory GetBelgenoUret.fromJson(Map<String, dynamic> json) {
    return GetBelgenoUret(
      belgeNo: json['BELGENO'] ?? '',
    );
  }
}

class GetFiyatListesi {
  final int fiyatId;
  final String fiyatAdi;
  final double fiyat;

  GetFiyatListesi({required this.fiyatId, required this.fiyatAdi, required this.fiyat});

  factory GetFiyatListesi.fromJson(Map<String, dynamic> json) {
    return GetFiyatListesi(
      fiyatId: json['FIYATID'] ?? 0,
      fiyatAdi: json['FIYATADI'] ?? '',
      fiyat: (json['FIYAT'] ?? 0).toDouble(),
    );
  }
}

class GetGonderimKoduTeslimAl {
  final int id;
  final String gonderimKodu;
  final String aciklama;
  final String tarih;

  GetGonderimKoduTeslimAl({
    required this.id,
    required this.gonderimKodu,
    required this.aciklama,
    required this.tarih,
  });

  factory GetGonderimKoduTeslimAl.fromJson(Map<String, dynamic> json) {
    return GetGonderimKoduTeslimAl(
      id: json['ID'] ?? 0,
      gonderimKodu: json['GONDERIMKODU'] ?? '',
      aciklama: json['ACIKLAMA'] ?? '',
      tarih: json['TARIH'] ?? '',
    );
  }
}

class GetHizliStok {
  final int stokId;
  final String stokAdi;
  final String barkod;
  final double fiyat;

  GetHizliStok({
    required this.stokId,
    required this.stokAdi,
    required this.barkod,
    required this.fiyat,
  });

  factory GetHizliStok.fromJson(Map<String, dynamic> json) {
    return GetHizliStok(
      stokId: json['STOKID'] ?? 0,
      stokAdi: json['STOKADI'] ?? '',
      barkod: json['BARKOD'] ?? '',
      fiyat: (json['FIYAT'] ?? 0).toDouble(),
    );
  }
}

class GetKWBelgeOlustur {
  final int belgeId;
  final String belgeNo;
  final String status;

  GetKWBelgeOlustur({
    required this.belgeId,
    required this.belgeNo,
    required this.status,
  });

  factory GetKWBelgeOlustur.fromJson(Map<String, dynamic> json) {
    return GetKWBelgeOlustur(
      belgeId: json['BELGEID'] ?? 0,
      belgeNo: json['BELGENO'] ?? '',
      status: json['STATUS'] ?? 'OK',
    );
  }
}

class GetKontrolluIrsaliyeTeslimAlma {
  final int irsaliyeId;
  final String irsaliyeNo;
  final String cariAdi;
  final String tarih;

  GetKontrolluIrsaliyeTeslimAlma({
    required this.irsaliyeId,
    required this.irsaliyeNo,
    required this.cariAdi,
    required this.tarih,
  });

  factory GetKontrolluIrsaliyeTeslimAlma.fromJson(Map<String, dynamic> json) {
    return GetKontrolluIrsaliyeTeslimAlma(
      irsaliyeId: json['IRSALIYEID'] ?? 0,
      irsaliyeNo: json['IRSALIYENO'] ?? '',
      cariAdi: json['CARIADI'] ?? '',
      tarih: json['TARIH'] ?? '',
    );
  }
}

class GetKullaniciAyarlari {
  final int durum;
  final int userId;
  final String nesne;
  final String deger;

  GetKullaniciAyarlari({
    this.durum = 1,
    required this.userId,
    required this.nesne,
    required this.deger,
  });

  factory GetKullaniciAyarlari.fromJson(Map<String, dynamic> json) {
    return GetKullaniciAyarlari(
      durum: json['DURUM'] ?? 1,
      userId: json['USERID'] ?? 0,
      nesne: json['NESNE'] ?? '',
      deger: (json['DEGER'] ?? '').toString(),
    );
  }
}


class GetKullaniciList {
  final int userId;
  final String kullaniciAd;
  final String tamAd;

  GetKullaniciList({
    required this.userId,
    required this.kullaniciAd,
    required this.tamAd,
  });

  factory GetKullaniciList.fromJson(Map<String, dynamic> json) {
    return GetKullaniciList(
      userId: json['USERID'] ?? 0,
      kullaniciAd: json['KULLANICIAD'] ?? '',
      tamAd: json['TAMAD'] ?? '',
    );
  }
}

class GetKullaniciRaporDetay {
  final double satis;
  final double satisIade;
  final double satisNet;
  final double kasaTahsilat;
  final double kasaTediye;
  final double kasaNet;
  final double kartSatis;
  final double kartAlis;
  final double kartNet;
  final double satisToplam;
  final double nakitToplam;

  GetKullaniciRaporDetay({
    this.satis = 0.0,
    this.satisIade = 0.0,
    this.satisNet = 0.0,
    this.kasaTahsilat = 0.0,
    this.kasaTediye = 0.0,
    this.kasaNet = 0.0,
    this.kartSatis = 0.0,
    this.kartAlis = 0.0,
    this.kartNet = 0.0,
    this.satisToplam = 0.0,
    this.nakitToplam = 0.0,
  });

  factory GetKullaniciRaporDetay.fromJson(Map<String, dynamic> json) {
    return GetKullaniciRaporDetay(
      satis: parseDouble(json['SATIS'] ?? json['satis']),
      satisIade: parseDouble(json['SATISIADE'] ?? json['satisIade']),
      satisNet: parseDouble(json['SATISNET'] ?? json['satisNet']),
      kasaTahsilat: parseDouble(json['KASATAHSILAT'] ?? json['kasaTahsilat']),
      kasaTediye: parseDouble(json['KASATEDIYE'] ?? json['kasaTediye']),
      kasaNet: parseDouble(json['KASANET'] ?? json['kasaNet']),
      kartSatis: parseDouble(json['KARTSATIS'] ?? json['kartSatis']),
      kartAlis: parseDouble(json['KARTALIS'] ?? json['kartAlis']),
      kartNet: parseDouble(json['KARTNET'] ?? json['kartNet']),
      satisToplam: parseDouble(json['SATISTOPLAM'] ?? json['satisToplam']),
      nakitToplam: parseDouble(json['NAKITTOPLAM'] ?? json['nakitToplam']),
    );
  }
}

class GetMDepoTransfer {
  final int id;
  final String cikisDepo;
  final String varisDepo;

  GetMDepoTransfer({required this.id, required this.cikisDepo, required this.varisDepo});

  factory GetMDepoTransfer.fromJson(Map<String, dynamic> json) {
    return GetMDepoTransfer(
      id: json['ID'] ?? 0,
      cikisDepo: json['CIKISDEPO'] ?? '',
      varisDepo: json['VARISDEPO'] ?? '',
    );
  }
}

class GetMMalKabul {
  final int id;
  final String irsaliyeNo;
  final String cariAdi;

  GetMMalKabul({required this.id, required this.irsaliyeNo, required this.cariAdi});

  factory GetMMalKabul.fromJson(Map<String, dynamic> json) {
    return GetMMalKabul(
      id: json['ID'] ?? 0,
      irsaliyeNo: json['IRSALIYENO'] ?? '',
      cariAdi: json['CARIADI'] ?? '',
    );
  }
}

class GetMSatis {
  final int id;
  final String cariAdi;
  final double tutar;

  GetMSatis({required this.id, required this.cariAdi, required this.tutar});

  factory GetMSatis.fromJson(Map<String, dynamic> json) {
    return GetMSatis(
      id: json['ID'] ?? 0,
      cariAdi: json['CARIADI'] ?? '',
      tutar: (json['TUTAR'] ?? 0).toDouble(),
    );
  }
}

class GetMSayim {
  final int id;
  final String depoAdi;
  final String tarih;

  GetMSayim({required this.id, required this.depoAdi, required this.tarih});

  factory GetMSayim.fromJson(Map<String, dynamic> json) {
    return GetMSayim(
      id: json['ID'] ?? 0,
      depoAdi: json['DEPOADI'] ?? '',
      tarih: json['TARIH'] ?? '',
    );
  }
}

class GetMSiparis {
  final int id;
  final String siparisNo;
  final String cariAdi;

  GetMSiparis({required this.id, required this.siparisNo, required this.cariAdi});

  factory GetMSiparis.fromJson(Map<String, dynamic> json) {
    return GetMSiparis(
      id: json['ID'] ?? 0,
      siparisNo: json['SIPARISNO'] ?? '',
      cariAdi: json['CARIADI'] ?? '',
    );
  }
}

class GetMStokIslemleri {
  final int id;
  final String stokAdi;

  GetMStokIslemleri({required this.id, required this.stokAdi});

  factory GetMStokIslemleri.fromJson(Map<String, dynamic> json) {
    return GetMStokIslemleri(
      id: json['ID'] ?? 0,
      stokAdi: json['STOKADI'] ?? '',
    );
  }
}

class GetSubeBanka {
  final int durum;
  final int subeId;
  final String subeAdi;
  final String subeKod;
  final int bankaId;
  final String bankaAdi;
  final String bankaKod;

  GetSubeBanka({
    this.durum = 1,
    required this.subeId,
    required this.subeAdi,
    this.subeKod = '',
    required this.bankaId,
    required this.bankaAdi,
    this.bankaKod = '',
  });

  String get displayTitle => bankaAdi.isNotEmpty ? bankaAdi : 'Banka #$bankaId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetSubeBanka && runtimeType == other.runtimeType && bankaId == other.bankaId && subeId == other.subeId;

  @override
  int get hashCode => Object.hash(subeId, bankaId);

  factory GetSubeBanka.fromJson(Map<String, dynamic> json) {
    return GetSubeBanka(
      durum: json['DURUM'] ?? 1,
      subeId: json['SUBEID'] ?? 0,
      subeAdi: json['SUBEADI'] ?? '',
      subeKod: json['SUBEKOD'] ?? '',
      bankaId: json['BANKAID'] ?? 0,
      bankaAdi: json['BANKAADI'] ?? '',
      bankaKod: json['BANKAKOD'] ?? '',
    );
  }
}

class GetSubeDepo {
  final int durum;
  final int subeId;
  final String subeAdi;
  final String subeKod;
  final int depoId;
  final String depoAdi;
  final String depoKod;
  final String depoTip;
  final int depoGiris;
  final int depoCikis;
  final int depoTur;

  GetSubeDepo({
    this.durum = 1,
    required this.subeId,
    required this.subeAdi,
    this.subeKod = '',
    required this.depoId,
    required this.depoAdi,
    this.depoKod = '',
    this.depoTip = '',
    this.depoGiris = 1,
    this.depoCikis = 1,
    this.depoTur = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetSubeDepo && runtimeType == other.runtimeType && depoId == other.depoId && subeId == other.subeId;

  @override
  int get hashCode => Object.hash(subeId, depoId);

  factory GetSubeDepo.fromJson(Map<String, dynamic> json) {
    return GetSubeDepo(
      durum: json['DURUM'] ?? 1,
      subeId: json['SUBEID'] ?? 0,
      subeAdi: json['SUBEADI'] ?? '',
      subeKod: json['SUBEKOD'] ?? '',
      depoId: json['DEPOID'] ?? 0,
      depoAdi: json['DEPOADI'] ?? '',
      depoKod: json['DEPOKOD'] ?? '',
      depoTip: json['DEPOTIP'] ?? '',
      depoGiris: json['DEPOGIRIS'] ?? 1,
      depoCikis: json['DEPOCIKIS'] ?? 1,
      depoTur: json['TUR'] ?? json['DEPOTUR'] ?? 0,
    );
  }
}

class GetSubeKasa {
  final int durum;
  final int subeId;
  final String subeAdi;
  final String subeKod;
  final int kasaId;
  final String kasaAdi;
  final String kasaKod;

  GetSubeKasa({
    this.durum = 1,
    required this.subeId,
    required this.subeAdi,
    this.subeKod = '',
    required this.kasaId,
    required this.kasaAdi,
    this.kasaKod = '',
  });

  String get displayTitle => kasaAdi.isNotEmpty ? kasaAdi : 'Kasa #$kasaId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetSubeKasa && runtimeType == other.runtimeType && kasaId == other.kasaId && subeId == other.subeId;

  @override
  int get hashCode => Object.hash(subeId, kasaId);

  factory GetSubeKasa.fromJson(Map<String, dynamic> json) {
    return GetSubeKasa(
      durum: json['DURUM'] ?? 1,
      subeId: json['SUBEID'] ?? 0,
      subeAdi: json['SUBEADI'] ?? '',
      subeKod: json['SUBEKOD'] ?? '',
      kasaId: json['KASAID'] ?? 0,
      kasaAdi: json['KASAADI'] ?? '',
      kasaKod: json['KASAKOD'] ?? '',
    );
  }
}


class GetUrunBilgileri {
  final int stokId;
  final String stokAdi;
  final String aciklama;

  GetUrunBilgileri({required this.stokId, required this.stokAdi, required this.aciklama});

  factory GetUrunBilgileri.fromJson(Map<String, dynamic> json) {
    return GetUrunBilgileri(
      stokId: json['STOKID'] ?? 0,
      stokAdi: json['STOKADI'] ?? '',
      aciklama: json['ACIKLAMA'] ?? '',
    );
  }
}

class GetYazarKasaKdv {
  final int kdvId;
  final double oran;
  final String kod;
  final String adi;

  GetYazarKasaKdv({
    this.kdvId = 0,
    this.oran = 0.0,
    this.kod = '',
    this.adi = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetYazarKasaKdv && runtimeType == other.runtimeType && kdvId == other.kdvId && oran == other.oran;

  @override
  int get hashCode => Object.hash(kdvId, oran);

  factory GetYazarKasaKdv.fromJson(Map<String, dynamic> json) {
    return GetYazarKasaKdv(
      kdvId: json['KDVID'] ?? json['kdvId'] ?? 0,
      oran: (json['ORAN'] ?? json['oran'] ?? 0).toDouble(),
      kod: (json['a_kod'] ?? json['KOD'] ?? json['kod'] ?? '').toString(),
      adi: (json['a_adi'] ?? json['ADI'] ?? json['adi'] ?? '').toString(),
    );
  }
}

class GetYazdirilcakUrun {
  final String stokAdi;
  final String barkod;
  final double fiyat;
  final int miktar;

  GetYazdirilcakUrun({
    required this.stokAdi,
    required this.barkod,
    required this.fiyat,
    required this.miktar,
  });

  factory GetYazdirilcakUrun.fromJson(Map<String, dynamic> json) {
    return GetYazdirilcakUrun(
      stokAdi: json['STOKADI'] ?? '',
      barkod: json['BARKOD'] ?? '',
      fiyat: (json['FIYAT'] ?? 0).toDouble(),
      miktar: json['MIKTAR'] ?? 1,
    );
  }
}

class GetYetki {
  final String yetkiKodu;
  final String yetkiAdi;
  final bool durum;

  GetYetki({required this.yetkiKodu, required this.yetkiAdi, required this.durum});

  factory GetYetki.fromJson(Map<String, dynamic> json) {
    return GetYetki(
      yetkiKodu: json['YETKIKODU'] ?? '',
      yetkiAdi: json['YETKIADI'] ?? '',
      durum: (json['DURUM'] ?? 0) == 1,
    );
  }
}

// ============================================================
// GetStokIslem – Stok kartı CRUD işlemi (Get_StokIslem.java)
// ============================================================
class GetStokIslem {
  final int durum;
  final double urunFiyat;
  final int stokId;
  final String stokKod;
  final String stokAd;
  final String stokBarkod;
  final String birim;
  final String kdvDh;
  final double alKdv;
  final double saKdv;
  final double aFiyat;
  final double sFiyat;
  final double oFiyat1;
  final double oFiyat2;
  final double oFiyat3;
  final double oFiyat4;
  final double oFiyat5;
  final double oFiyat6;
  final int userId;
  final String barTur;
  final String stok1Barkod;
  final String stok2Barkod;
  final String stokLotAdi;
  final String yazarKasaKdv;

  GetStokIslem({
    required this.durum,
    required this.urunFiyat,
    required this.stokId,
    required this.stokKod,
    required this.stokAd,
    required this.stokBarkod,
    required this.birim,
    required this.kdvDh,
    required this.alKdv,
    required this.saKdv,
    required this.aFiyat,
    required this.sFiyat,
    required this.oFiyat1,
    required this.oFiyat2,
    required this.oFiyat3,
    required this.oFiyat4,
    required this.oFiyat5,
    required this.oFiyat6,
    required this.userId,
    required this.barTur,
    required this.stok1Barkod,
    required this.stok2Barkod,
    required this.stokLotAdi,
    required this.yazarKasaKdv,
  });

  factory GetStokIslem.fromJson(Map<String, dynamic> json) {
    return GetStokIslem(
      durum: (json['DURUM'] ?? 0) as int,
      urunFiyat: (json['URUNFIYAT'] ?? 0).toDouble(),
      stokId: (json['STOKID'] ?? 0) as int,
      stokKod: json['STOKKOD'] ?? '',
      stokAd: json['STOKAD'] ?? '',
      stokBarkod: json['STOKBARKOD'] ?? '',
      birim: json['BIRIM'] ?? '',
      kdvDh: json['KDVDH'] ?? '',
      alKdv: (json['ALKDV'] ?? 0).toDouble(),
      saKdv: (json['SAKDV'] ?? 0).toDouble(),
      aFiyat: (json['AFIYAT'] ?? 0).toDouble(),
      sFiyat: (json['SFIYAT'] ?? 0).toDouble(),
      oFiyat1: (json['OFIYAT1'] ?? 0).toDouble(),
      oFiyat2: (json['OFIYAT2'] ?? 0).toDouble(),
      oFiyat3: (json['OFIYAT3'] ?? 0).toDouble(),
      oFiyat4: (json['OFIYAT4'] ?? 0).toDouble(),
      oFiyat5: (json['OFIYAT5'] ?? 0).toDouble(),
      oFiyat6: (json['OFIYAT6'] ?? 0).toDouble(),
      userId: (json['USERID'] ?? 0) as int,
      barTur: json['BARTUR'] ?? '',
      stok1Barkod: json['STOK1BARKOD'] ?? '',
      stok2Barkod: json['STOK2BARKOD'] ?? '',
      stokLotAdi: json['STOKLOTADI'] ?? '',
      yazarKasaKdv: json['YAZARKASAKDV'] ?? '',
    );
  }
}

// ============================================================
// GetBelgeGetir – Tek belge header bilgisi (Get_BelgeGetir.java)
// ============================================================
class GetBelgeGetir {
  final int durum;
  final int fisTur;
  final String fisTarih;
  final String depoAdi;
  final String cariAdi;
  final String subeAdi;
  final String oPlanAdi;
  final int fisId;
  final String belgeNo;
  final int depoId;
  final int cariId;
  final int oPlanId;
  final int subeId;
  final String aciklama;
  final double tutar;
  final String ad;
  final String barkod;
  final String kod;
  final double miktar;
  final double mevcutMiktar;
  final String fisTurAdi;
  final int onay;
  final double toplamMiktar;
  final String stokGrup1;

  GetBelgeGetir({
    required this.durum,
    required this.fisTur,
    required this.fisTarih,
    required this.depoAdi,
    required this.cariAdi,
    required this.subeAdi,
    required this.oPlanAdi,
    required this.fisId,
    required this.belgeNo,
    required this.depoId,
    required this.cariId,
    required this.oPlanId,
    required this.subeId,
    required this.aciklama,
    required this.tutar,
    required this.ad,
    required this.barkod,
    required this.kod,
    required this.miktar,
    required this.mevcutMiktar,
    required this.fisTurAdi,
    required this.onay,
    required this.toplamMiktar,
    required this.stokGrup1,
  });

  factory GetBelgeGetir.fromJson(Map<String, dynamic> json) {
    return GetBelgeGetir(
      durum: parseInt(json['DURUM']),
      fisTur: parseInt(json['FISTUR']),
      fisTarih: (json['FISTARIH'] ?? '').toString(),
      depoAdi: (json['DEPOADI'] ?? '').toString(),
      cariAdi: (json['CARIADI'] ?? '').toString(),
      subeAdi: (json['SUBEADI'] ?? '').toString(),
      oPlanAdi: (json['OPLANADI'] ?? '').toString(),
      fisId: parseInt(json['FISID'] ?? json['ID']),
      belgeNo: (json['BELGENO'] ?? '').toString(),
      depoId: parseInt(json['DEPOID']),
      cariId: parseInt(json['CARIID']),
      oPlanId: parseInt(json['OPLANID']),
      subeId: parseInt(json['SUBEID']),
      aciklama: (json['ACIKLAMA'] ?? '').toString(),
      tutar: parseDouble(json['TUTAR'] ?? json['tutar']),
      ad: (json['AD'] ?? '').toString(),
      barkod: (json['BARKOD'] ?? '').toString(),
      kod: (json['KOD'] ?? '').toString(),
      miktar: parseDouble(json['MIKTAR'] ?? json['miktar']),
      mevcutMiktar: parseDouble(json['MEVCUTMIKTAR'] ?? json['mevcutMiktar']),
      fisTurAdi: (json['FISTURADI'] ?? '').toString(),
      onay: parseInt(json['ONAY']),
      toplamMiktar: parseDouble(json['TOPLAM_MIKTAR'] ?? json['toplamMiktar']),
      stokGrup1: (json['StokGrup1'] ?? '').toString(),
    );
  }
}

// ============================================================
// Firma – Firma modeli (Firma.java)
// ============================================================
class Firma {
  final int aId;
  final String aAdi;

  Firma({required this.aId, required this.aAdi});

  String get unvan => aAdi;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Firma && runtimeType == other.runtimeType && aId == other.aId;

  @override
  int get hashCode => aId.hashCode;

  factory Firma.fromJson(Map<String, dynamic> json) {
    return Firma(
      aId: parseInt(json['a_id'] ?? json['A_ID']),
      aAdi: (json['a_adi'] ?? json['A_ADI'] ?? '').toString(),
    );
  }
}

// ============================================================
// DbModel – Veritabanı/Bağlantı modeli (DB.java)
// ============================================================
class DbModel {
  final int aId;
  final String aAdi;
  final String aConnection;
  final int aKulId;
  final List<Firma> firma;
  final String apiUrl;

  String get aDbAdi => aAdi;

  DbModel({
    required this.aId,
    required this.aAdi,
    required this.aConnection,
    required this.aKulId,
    required this.firma,
    required this.apiUrl,
  });

  factory DbModel.fromJson(Map<String, dynamic> json) {
    List<Firma> firmaList = [];
    if (json['firma'] != null && json['firma'] is List) {
      firmaList = (json['firma'] as List).map((e) => Firma.fromJson(e)).toList();
    }
    return DbModel(
      aId: parseInt(json['a_id'] ?? json['A_ID']),
      aAdi: (json['a_adi'] ?? json['A_ADI'] ?? '').toString(),
      aConnection: (json['a_connection'] ?? json['A_CONNECTION'] ?? '').toString(),
      aKulId: parseInt(json['a_kulid'] ?? json['A_KULID'] ?? json['a_userid'] ?? json['A_USERID']),
      firma: firmaList,
      apiUrl: (json['apiUrl'] ?? json['APIURL'] ?? '').toString(),
    );
  }
}

class GetKullaniciRapor {
  final int id;
  final String baslik;
  final String tarih;
  final String aciklama;
  final double toplam;
  final String islemKodu;

  GetKullaniciRapor({
    required this.id,
    required this.baslik,
    required this.tarih,
    required this.aciklama,
    required this.toplam,
    required this.islemKodu,
  });

  String get evrakTuru => baslik;
  int get evrakId => id;
  int get adet => 1;
  String get kullaniciAdi => aciklama;
  double get tutar => toplam;

  factory GetKullaniciRapor.fromJson(Map<String, dynamic> json) {
    return GetKullaniciRapor(
      id: json['ID'] ?? json['id'] ?? 0,
      baslik: json['BASLIK'] ?? json['baslik'] ?? '',
      tarih: json['TARIH'] ?? json['tarih'] ?? '',
      aciklama: json['ACIKLAMA'] ?? json['aciklama'] ?? '',
      toplam: (json['TOPLAM'] ?? json['toplam'] ?? 0).toDouble(),
      islemKodu: json['ISLEMKODU'] ?? json['islemKodu'] ?? '',
    );
  }
}

class GetAtamaliSipDetGetir {
  final int id;
  final String islemKodu;
  final int stokId;
  final String stokKodu;
  final String stokAdi;
  final String barkod;
  final double miktar;
  final double teslimMiktar;
  final String birim;

  GetAtamaliSipDetGetir({
    required this.id,
    required this.islemKodu,
    required this.stokId,
    required this.stokKodu,
    required this.stokAdi,
    required this.barkod,
    required this.miktar,
    required this.teslimMiktar,
    required this.birim,
  });

  factory GetAtamaliSipDetGetir.fromJson(Map<String, dynamic> json) {
    return GetAtamaliSipDetGetir(
      id: json['ID'] ?? json['id'] ?? 0,
      islemKodu: json['ISLEMKODU'] ?? json['islemKodu'] ?? '',
      stokId: json['STOKID'] ?? json['stokId'] ?? 0,
      stokKodu: json['STOKKODU'] ?? json['stokKodu'] ?? '',
      stokAdi: json['STOKADI'] ?? json['stokAdi'] ?? '',
      barkod: json['BARKOD'] ?? json['barkod'] ?? '',
      miktar: (json['MIKTAR'] ?? json['miktar'] ?? 0).toDouble(),
      teslimMiktar: (json['TESLIMMIKTAR'] ?? json['teslimMiktar'] ?? 0).toDouble(),
      birim: json['BIRIM'] ?? json['birim'] ?? 'ADET',
    );
  }
}

class GetFisDizMasList {
  final int id;
  final int tur;
  final String tasarimAdi;
  final String aciklama;

  GetFisDizMasList({
    required this.id,
    required this.tur,
    required this.tasarimAdi,
    required this.aciklama,
  });

  factory GetFisDizMasList.fromJson(Map<String, dynamic> json) {
    return GetFisDizMasList(
      id: json['ID'] ?? json['id'] ?? 0,
      tur: json['TUR'] ?? json['tur'] ?? 0,
      tasarimAdi: json['TASARIMADI'] ?? json['tasarimAdi'] ?? '',
      aciklama: json['ACIKLAMA'] ?? json['aciklama'] ?? '',
    );
  }
}

class GetMobLog {
  final int durum;
  final String mesaj;

  GetMobLog({required this.durum, required this.mesaj});

  factory GetMobLog.fromJson(Map<String, dynamic> json) {
    return GetMobLog(
      durum: json['DURUM'] ?? json['durum'] ?? 0,
      mesaj: json['MESAJ'] ?? json['mesaj'] ?? '',
    );
  }
}

class MobwaySatirIskontoData {
  final int satirNo;
  final double iskonto1;
  final double iskonto2;
  final double iskonto3;
  final double iskontoTutar;

  MobwaySatirIskontoData({
    required this.satirNo,
    this.iskonto1 = 0,
    this.iskonto2 = 0,
    this.iskonto3 = 0,
    this.iskontoTutar = 0,
  });

  Map<String, dynamic> toJson() => {
    'satirNo': satirNo,
    'iskonto1': iskonto1,
    'iskonto2': iskonto2,
    'iskonto3': iskonto3,
    'iskontoTutar': iskontoTutar,
  };
}

class UrunToplamaKayitModel {
  final String islemKodu;
  final List<Map<String, dynamic>> list;

  UrunToplamaKayitModel({required this.islemKodu, required this.list});

  Map<String, dynamic> toJson() => {
    'islemKodu': islemKodu,
    'list': list,
  };
}

class AtamaliTeslimModel {
  final String islemKodu;
  final int cariId;
  final int depoId;
  final int subeId;
  final int belgeTuru;
  final List<Map<String, dynamic>> list;

  AtamaliTeslimModel({
    required this.islemKodu,
    required this.cariId,
    required this.depoId,
    required this.subeId,
    required this.belgeTuru,
    required this.list,
  });

  Map<String, dynamic> toJson() => {
    'islemkodu': islemKodu,
    'cariid': cariId,
    'depoid': depoId,
    'subeid': subeId,
    'belgeturu': belgeTuru,
    'list': list,
  };
}

// ============================================================
// Mobil Sipariş Modelleri (Swagger: /mobilSiparis/*)
// ============================================================

class MobilSiparisModel {
  final int siparisId;
  final String siparisNo;
  final String tarih;
  final String musteriAdi;
  final double toplamTutar;
  final String durum;
  final String adres;
  final String telefon;
  final String odemeTuru;

  MobilSiparisModel({
    required this.siparisId,
    required this.siparisNo,
    required this.tarih,
    required this.musteriAdi,
    required this.toplamTutar,
    required this.durum,
    required this.adres,
    required this.telefon,
    required this.odemeTuru,
  });

  factory MobilSiparisModel.fromJson(Map<String, dynamic> json) {
    return MobilSiparisModel(
      siparisId: json['SIPARISID'] ?? json['id'] ?? json['Id'] ?? 0,
      siparisNo: json['SIPARISNO'] ?? json['siparisNo'] ?? json['SiparisNo'] ?? '',
      tarih: json['TARIH'] ?? json['tarih'] ?? json['Tarih'] ?? '',
      musteriAdi: json['MUSTERIADI'] ?? json['musteriAdi'] ?? json['MusteriAdi'] ?? '',
      toplamTutar: (json['TOPLAMTUTAR'] ?? json['toplamTutar'] ?? json['ToplamTutar'] ?? 0).toDouble(),
      durum: json['DURUM'] ?? json['durum'] ?? json['Durum']?.toString() ?? '',
      adres: json['ADRES'] ?? json['adres'] ?? json['Adres'] ?? '',
      telefon: json['TELEFON'] ?? json['telefon'] ?? json['Telefon'] ?? '',
      odemeTuru: json['ODEMETURU'] ?? json['odemeTuru'] ?? json['OdemeTuru'] ?? '',
    );
  }
}

class MobilSiparisDetay {
  final int id;
  final int siparisId;
  final int stokId;
  final String stokAdi;
  final String barkod;
  final double miktar;
  final double birimFiyat;
  final double toplamTutar;
  final double kdvOrani;

  MobilSiparisDetay({
    required this.id,
    required this.siparisId,
    required this.stokId,
    required this.stokAdi,
    required this.barkod,
    required this.miktar,
    required this.birimFiyat,
    required this.toplamTutar,
    required this.kdvOrani,
  });

  factory MobilSiparisDetay.fromJson(Map<String, dynamic> json) {
    return MobilSiparisDetay(
      id: json['ID'] ?? json['id'] ?? 0,
      siparisId: json['SIPARISID'] ?? json['siparisId'] ?? 0,
      stokId: json['STOKID'] ?? json['stokId'] ?? 0,
      stokAdi: json['STOKADI'] ?? json['stokAdi'] ?? '',
      barkod: json['BARKOD'] ?? json['barkod'] ?? '',
      miktar: (json['MIKTAR'] ?? json['miktar'] ?? 0).toDouble(),
      birimFiyat: (json['BIRIMFIYAT'] ?? json['birimFiyat'] ?? json['FIYAT'] ?? 0).toDouble(),
      toplamTutar: (json['TOPLAMTUTAR'] ?? json['toplamTutar'] ?? json['TUTAR'] ?? 0).toDouble(),
      kdvOrani: (json['KDVORANI'] ?? json['kdvOrani'] ?? json['KDV'] ?? 0).toDouble(),
    );
  }
}

class MobilUyeModel {
  final int uyeId;
  final String adSoyad;
  final String eposta;
  final String telefon;
  final String adres;
  final bool aktif;

  MobilUyeModel({
    required this.uyeId,
    required this.adSoyad,
    required this.eposta,
    required this.telefon,
    required this.adres,
    required this.aktif,
  });

  factory MobilUyeModel.fromJson(Map<String, dynamic> json) {
    return MobilUyeModel(
      uyeId: json['UYEID'] ?? json['uyeId'] ?? json['Id'] ?? 0,
      adSoyad: json['ADSOYAD'] ?? json['adSoyad'] ?? json['AdSoyad'] ?? '',
      eposta: json['EPOSTA'] ?? json['eposta'] ?? json['Eposta'] ?? '',
      telefon: json['TELEFON'] ?? json['telefon'] ?? json['Telefon'] ?? '',
      adres: json['ADRES'] ?? json['adres'] ?? json['Adres'] ?? '',
      aktif: json['AKTIF'] ?? json['aktif'] ?? true,
    );
  }
}

class MobilSubeBilgi {
  final int subeId;
  final String subeAdi;
  final String telefon;
  final String adres;
  final String acilisSaati;
  final String kapanisSaati;

  MobilSubeBilgi({
    required this.subeId,
    required this.subeAdi,
    required this.telefon,
    required this.adres,
    required this.acilisSaati,
    required this.kapanisSaati,
  });

  factory MobilSubeBilgi.fromJson(Map<String, dynamic> json) {
    return MobilSubeBilgi(
      subeId: json['SUBEID'] ?? json['subeId'] ?? json['Id'] ?? 0,
      subeAdi: json['SUBEADI'] ?? json['subeAdi'] ?? json['SubeAdi'] ?? '',
      telefon: json['TELEFON'] ?? json['telefon'] ?? '',
      adres: json['ADRES'] ?? json['adres'] ?? '',
      acilisSaati: json['ACILIS'] ?? json['acilisSaati'] ?? '',
      kapanisSaati: json['KAPANIS'] ?? json['kapanisSaati'] ?? '',
    );
  }
}

// ============================================================
// Rapor Tasarım Modelleri (Swagger: /RaporTasarim/*)
// ============================================================

class RaporTasarimModel {
  final int id;
  final String tasarimAdi;
  final String modId;
  final int subeId;
  final String jsonIcerik;
  final bool ozel;

  RaporTasarimModel({
    required this.id,
    required this.tasarimAdi,
    required this.modId,
    required this.subeId,
    required this.jsonIcerik,
    required this.ozel,
  });

  factory RaporTasarimModel.fromJson(Map<String, dynamic> json) {
    return RaporTasarimModel(
      id: json['ID'] ?? json['id'] ?? 0,
      tasarimAdi: json['TASARIMADI'] ?? json['tasarimAdi'] ?? '',
      modId: json['MODID'] ?? json['modId']?.toString() ?? '',
      subeId: json['SUBEID'] ?? json['subeId'] ?? 0,
      jsonIcerik: json['JSONICERIK'] ?? json['jsonIcerik'] ?? json['ICERIK'] ?? '',
      ozel: json['OZEL'] ?? json['ozel'] ?? false,
    );
  }
}

class StokBorcYRapor {
  final int cariId;
  final String cariKodu;
  final String cariUnvan;
  final double toplamBorc;
  final double vadesiGecen;
  final double gun030;
  final double gun3060;
  final double gun6090;
  final double gun90Art;

  StokBorcYRapor({
    required this.cariId,
    required this.cariKodu,
    required this.cariUnvan,
    required this.toplamBorc,
    required this.vadesiGecen,
    required this.gun030,
    required this.gun3060,
    required this.gun6090,
    required this.gun90Art,
  });

  factory StokBorcYRapor.fromJson(Map<String, dynamic> json) {
    return StokBorcYRapor(
      cariId: json['CARIID'] ?? json['cariId'] ?? 0,
      cariKodu: json['CARIKODU'] ?? json['cariKodu'] ?? '',
      cariUnvan: json['UNVAN'] ?? json['cariUnvan'] ?? '',
      toplamBorc: (json['TOPLAMBORC'] ?? json['toplamBorc'] ?? 0).toDouble(),
      vadesiGecen: (json['VADESIGECEN'] ?? json['vadesiGecen'] ?? 0).toDouble(),
      gun030: (json['GUN0_30'] ?? json['gun0_30'] ?? 0).toDouble(),
      gun3060: (json['GUN30_60'] ?? json['gun30_60'] ?? 0).toDouble(),
      gun6090: (json['GUN60_90'] ?? json['gun60_90'] ?? 0).toDouble(),
      gun90Art: (json['GUN90_ARTI'] ?? json['gun90_arti'] ?? 0).toDouble(),
    );
  }
}

// ============================================================
// AlternatifPay & Pavo Modelleri (Swagger: /apay/*, /Pavo/*)
// ============================================================

class ApayOdemeResponse {
  final bool basarili;
  final String mesaj;
  final String odemeKodu;
  final String link;
  final double tutar;

  ApayOdemeResponse({
    required this.basarili,
    required this.mesaj,
    required this.odemeKodu,
    required this.link,
    required this.tutar,
  });

  factory ApayOdemeResponse.fromJson(Map<String, dynamic> json) {
    return ApayOdemeResponse(
      basarili: json['basarili'] ?? json['Success'] ?? (json['durum'] == 1),
      mesaj: json['mesaj'] ?? json['Message'] ?? '',
      odemeKodu: json['odemeKodu'] ?? json['PaymentCode'] ?? '',
      link: json['link'] ?? json['PaymentUrl'] ?? '',
      tutar: (json['tutar'] ?? json['Amount'] ?? 0).toDouble(),
    );
  }
}

class PavoSaleResponse {
  final bool basarili;
  final String referansNo;
  final String mesaj;
  final double tutar;
  final String kartSonDort;
  final String authCode;

  PavoSaleResponse({
    required this.basarili,
    required this.referansNo,
    required this.mesaj,
    required this.tutar,
    required this.kartSonDort,
    required this.authCode,
  });

  factory PavoSaleResponse.fromJson(Map<String, dynamic> json) {
    return PavoSaleResponse(
      basarili: json['success'] ?? json['basarili'] ?? (json['status'] == 'APPROVED'),
      referansNo: json['referenceNo'] ?? json['referansNo'] ?? '',
      mesaj: json['message'] ?? json['mesaj'] ?? '',
      tutar: (json['amount'] ?? json['tutar'] ?? 0).toDouble(),
      kartSonDort: json['cardNumber'] ?? json['pan'] ?? '',
      authCode: json['authCode'] ?? '',
    );
  }
}



