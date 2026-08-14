import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/storage/save_settings.dart';
import '../core/utils/api_utils.dart';
import '../core/utils/app_logger.dart';
import '../models/models.dart';

class ApiService {
  static Future<Map<String, dynamic>> girisYap(String email, String password) async {
    final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointGirisYap}';
    final requestBody = {
      'eposta': email,
      'sifre': password,
      'versiyon': ApiConstants.fullVersion,
      'projeId': ApiConstants.uygulamaId,
    };

    AppLogger.log('API_REQ', 'POST $endpoint isteği hazırlanıyor...', level: LogLevel.api, details: {
      'Endpoint': endpoint,
      'E-Posta': email,
      'Proje ID': ApiConstants.uygulamaId,
      'Versiyon': ApiConstants.webServiceVersion,
    });

    try {
      final url = Uri.parse(endpoint);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      AppLogger.log('API_RESP', 'POST $endpoint Yanıt Kodu: ${response.statusCode}',
          level: response.statusCode == 200 ? LogLevel.api : LogLevel.error,
          details: {
            'Status': response.statusCode,
            'Body Preview': response.body.length > 250 ? '${response.body.substring(0, 250)}...' : response.body,
          });

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list = (decoded is List) ? decoded : [decoded];
        if (list.isNotEmpty) {
          final firstItem = list.first as Map<String, dynamic>;
          final durum = parseInt(firstItem['DURUM'] ?? firstItem['durum']);

          if (durum == Numarator.basarili) {
            final user = PostSuperUser.fromJson(firstItem);
            SaveSettings.superUser = user;
            SaveSettings.superUserPosta = email;
            SaveSettings.superUserSifre = password;

            AppLogger.log('API_SUCCESS', 'Kullanıcı doğrulandı (ID: ${user.superUserId}, Db Adet: ${user.db.length})',
                level: LogLevel.success,
                details: {
                  'SuperUser ID': user.superUserId,
                  'E-Posta': email,
                  'Veritabanı Sayısı': user.db.length,
                  'Veritabanları': user.db.map((d) => '${d.aDbAdi} (Firma: ${d.firma.length})').toList(),
                });

            return {'success': true, 'durum': durum, 'user': user};
          } else if (durum == Numarator.uyari) {
            AppLogger.log('API_WARN', 'Kullanıcı adı veya şifre yanlış (Durum: $durum)', level: LogLevel.warning);
            return {'success': false, 'durum': durum, 'message': 'Kullanıcı adı veya şifre yanlış.'};
          } else if (durum == Numarator.hata) {
            AppLogger.log('API_WARN', 'Kullanıcıya ait şirket yetkisi bulunamadı (Durum: $durum)', level: LogLevel.warning);
            return {'success': false, 'durum': durum, 'message': 'Kullanıcıya ait şirket yetkisi bulunamadı.'};
          } else if (durum == Numarator.projeYetkisiBulunmamakta) {
            AppLogger.log('API_WARN', 'Proje yetkisi yok (Durum: $durum)', level: LogLevel.warning);
            return {'success': false, 'durum': durum, 'message': 'Proje yetkiniz bulunmamaktadır.'};
          } else if (durum == Numarator.apkVersiyonEski) {
            AppLogger.log('API_WARN', 'Uygulama versiyonu eski (Durum: $durum)', level: LogLevel.warning);
            return {'success': false, 'durum': durum, 'message': 'Uygulama versiyonu eski. Lütfen güncelleyiniz.'};
          } else if (durum == Numarator.wsVersiyonEski) {
            AppLogger.log('API_WARN', 'Web servis versiyonu eski (Durum: $durum)', level: LogLevel.warning);
            return {'success': false, 'durum': durum, 'message': 'Web servis versiyonu eski.'};
          } else {
            final msg = firstItem['MESAJ'] ?? 'Giriş başarısız (Durum: $durum).';
            AppLogger.log('API_WARN', 'Giriş reddedildi: $msg (Durum: $durum)', level: LogLevel.warning);
            return {
              'success': false,
              'durum': durum,
              'message': msg,
            };
          }
        }
      }
      final errMsg = 'Sunucu hatası: HTTP ${response.statusCode}';
      AppLogger.log('API_ERR', errMsg, level: LogLevel.error);
      return {'success': false, 'message': errMsg};
    } catch (e) {
      final connErr = 'Bağlantı hatası: $e';
      AppLogger.log('API_ERR', connErr, level: LogLevel.error);
      return {'success': false, 'message': connErr};
    }
  }

  static Future<Map<String, dynamic>> tokenUret({
    required String email,
    required String password,
    required int dbId,
    required int firmaId,
    required int dbKulId,
    String? apiUrl,
  }) async {
    try {
      if (apiUrl != null && apiUrl.trim().isNotEmpty) {
        SaveSettings.sunucu = apiUrl.endsWith('/') ? apiUrl : '$apiUrl/';
      }
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointTokenUret}';
      final payload = {
        'eposta': email,
        'sifre': password,
        'dbId': dbId,
        'firmaId': firmaId,
        'versiyon': ApiConstants.fullVersion,
        'projeId': ApiConstants.uygulamaId,
      };

      AppLogger.log('API_REQ', 'POST $endpoint Token Üretim İsteği...', level: LogLevel.api, details: {
        'Endpoint': endpoint,
        'E-Posta': email,
        'DbId': dbId,
        'FirmaId': firmaId,
        'DbKulId': dbKulId,
      });

      final url = Uri.parse(endpoint);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      AppLogger.log('API_RESP', 'POST $endpoint Yanıt Kodu: ${response.statusCode}',
          level: response.statusCode == 200 ? LogLevel.api : LogLevel.error,
          details: {
            'Status': response.statusCode,
            'Body Preview': response.body.length > 250 ? '${response.body.substring(0, 250)}...' : response.body,
          });

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list = (decoded is List) ? decoded : [decoded];
        if (list.isNotEmpty) {
          final firstItem = list.first as Map<String, dynamic>;
          final durum = parseInt(firstItem['DURUM'] ?? firstItem['durum']);

          if (durum == Numarator.basarili) {
            String token = '';
            if (firstItem['ICERIK'] != null && firstItem['ICERIK'] is List && (firstItem['ICERIK'] as List).isNotEmpty) {
              token = (firstItem['ICERIK'][0]['TOKEN'] ?? '').toString();
            } else if (firstItem['TOKEN'] != null) {
              token = firstItem['TOKEN'].toString();
            }

            if (token.isNotEmpty) {
              SaveSettings.token = token;
              AppLogger.log('TOKEN_SUCCESS', 'Token başarıyla alındı ve kaydedildi.',
                  level: LogLevel.success,
                  details: {
                    'Token': token.length > 25 ? '${token.substring(0, 25)}...' : token,
                  });
              return {'success': true, 'token': token};
            }
          }
        }
      }
      const tokenErrMsg = 'Token üretilemedi. Lütfen tekrar deneyiniz.';
      AppLogger.log('TOKEN_ERR', tokenErrMsg, level: LogLevel.error);
      return {'success': false, 'message': tokenErrMsg};
    } catch (e) {
      final err = 'Token bağlantı hatası: $e';
      AppLogger.log('TOKEN_ERR', err, level: LogLevel.error);
      return {'success': false, 'message': err};
    }
  }

  static Future<Map<String, dynamic>> getGiris({
    required String token,
    required String email,
    required int dbKulId,
  }) async {
    final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointGetGiris}';
    AppLogger.log('API_REQ', 'GET $endpoint Parametre İsteği...', level: LogLevel.api, details: {
      'Endpoint': endpoint,
      'Email': email,
      'DbKulId': dbKulId,
      'Token Preview': token.length > 20 ? '${token.substring(0, 20)}...' : token,
    });

    try {
      final uri = Uri.parse(endpoint).replace(
        queryParameters: {
          'TOKEN': token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': email,
          'KULID': dbKulId.toString(),
          'USERNOTIFICATIONID': '',
        },
      );

      final response = await http.get(uri);
      AppLogger.log('API_RESP', 'GET $endpoint Yanıt Kodu: ${response.statusCode}',
          level: response.statusCode == 200 ? LogLevel.api : LogLevel.error,
          details: {
            'Status': response.statusCode,
            'Body Preview': response.body.length > 250 ? '${response.body.substring(0, 250)}...' : response.body,
          });

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          final objDurum = decoded[0] as Map<String, dynamic>;
          final durum = parseInt(objDurum['DURUM'] ?? objDurum['durum']);

          if (durum == Numarator.basarili) {
            // 1. Öndeğerler
            if (decoded.length > 1 && decoded[1] is Map<String, dynamic>) {
              final o = decoded[1] as Map<String, dynamic>;
              SaveSettings.kullaniciKodu = (o['KULKOD'] ?? '').toString();
              SaveSettings.kullaniciAdi = (o['KULAD'] ?? '').toString();
              SaveSettings.depoId = parseInt(o['DEPOID']);
              SaveSettings.depoAdi = (o['DEPOADI'] ?? '').toString();
              SaveSettings.depoGiris = parseInt(o['GIRIS'], 1);
              SaveSettings.depoCikis = parseInt(o['CIKIS'], 1);
              SaveSettings.kasaId = parseInt(o['KASAID']);
              SaveSettings.kasaKodu = (o['KASAKOD'] ?? '').toString();
              SaveSettings.kasaAdi = (o['KASAADI'] ?? '').toString();
              SaveSettings.kasaSube = parseInt(o['KASASUBE']);
              SaveSettings.bankaId = parseInt(o['BANKAID']);
              SaveSettings.bankaKodu = (o['BANKAKOD'] ?? '').toString();
              SaveSettings.bankaAdi = (o['BANKAADI'] ?? '').toString();
              SaveSettings.bankaSube = parseInt(o['BANKASUBE']);
              SaveSettings.subeId = parseInt(o['SUBEID']);
              SaveSettings.subeAdi = (o['SUBEADI'] ?? '').toString();
              SaveSettings.subeKodu = (o['SUBEKODU'] ?? '').toString();
              SaveSettings.userId = parseInt(o['USERID']);
              SaveSettings.grupTur = parseInt(o['GRUPTUR']);
              SaveSettings.depoYetki = (o['DEPOYETKI'] ?? '').toString();
              SaveSettings.kasaYetki = (o['KASAYETKI'] ?? '').toString();
              SaveSettings.silYetki = (o['SILYETKI'] ?? '').toString();
              SaveSettings.bankaYetki = (o['BANKAYETKI'] ?? '').toString();
              SaveSettings.subeYetki = (o['SUBEYETKI'] ?? '').toString();
              SaveSettings.belgeOnayYetki = (o['ONAYYETKI'] ?? '').toString();
              SaveSettings.belgeOnayIptalYetki = (o['ONAYIPTALYETKI'] ?? '').toString();
              SaveSettings.parametre = parseInt(o['PARAMETRE']);
              SaveSettings.kontrolluDepoId = parseInt(o['KONTROLLUDEPOID']);
              SaveSettings.kontrolluDepoAdi = (o['KONTROLLUDEPOADI'] ?? '').toString();
              SaveSettings.kontrolluDepoGiris = parseInt(o['KONTROLLUDEPOGIRIS'], 1);
              SaveSettings.kontrolluDepoCikis = parseInt(o['KONTROLLUDEPOCIKIS'], 1);
              SaveSettings.fFiyatDegis = (o['FFIYATDEGIS'] ?? 'HAYIR').toString();
              SaveSettings.iFiyatDegis = (o['IFIYATDEGIS'] ?? 'HAYIR').toString();
              SaveSettings.yetkiSemaKullanim = (o['YETKISEMAKULLANIM'] ?? '0').toString();
              SaveSettings.kurusHassasiyet = parseInt(o['KURUSHASSASIYET']);
              SaveSettings.textOFiyat1 = (o['TEXT_OFIYAT1'] ?? 'Özel Fiyat 1').toString();
              SaveSettings.textOFiyat2 = (o['TEXT_OFIYAT2'] ?? 'Özel Fiyat 2').toString();
              SaveSettings.textOFiyat3 = (o['TEXT_OFIYAT3'] ?? 'Özel Fiyat 3').toString();
              SaveSettings.textOFiyat4 = (o['TEXT_OFIYAT4'] ?? 'Özel Fiyat 4').toString();
              SaveSettings.textOFiyat5 = (o['TEXT_OFIYAT5'] ?? 'Özel Fiyat 5').toString();
              SaveSettings.textOFiyat6 = (o['TEXT_OFIYAT6'] ?? 'Özel Fiyat 6').toString();
              SaveSettings.textSMaliyet = (o['TEXT_SMALIYET'] ?? 'Son Maliyet').toString();
              SaveSettings.textOMaliyet = (o['TEXT_OMALIYET'] ?? 'Ortalama Maliyet').toString();
              SaveSettings.textStokKartFiyat = (o['TEXT_STOKKARTFIYAT'] ?? 'Stok Kart Fiyatları').toString();
              SaveSettings.textStokKartOzelFiyat = (o['TEXT_STOKKARTOZELFIYAT'] ?? 'Stok Kart Özel Fiyatları').toString();
              SaveSettings.textMaliyetler = (o['TEXT_MALIYETLER'] ?? 'Maliyetler').toString();
              SaveSettings.textAFiyat = (o['TEXT_AFIYAT'] ?? 'Alış Fiyatı').toString();
              SaveSettings.textSFiyat = (o['TEXT_SFIYAT'] ?? 'Satış Fiyatı').toString();
              SaveSettings.dipFiyat = (o['DIPFIYAT'] ?? '0').toString();
              SaveSettings.perAD = (o['PERAD'] ?? '').toString();
              SaveSettings.perID = parseInt(o['PERID']);
            }

            // 2. Dövizler
            if (decoded.length > 2 && decoded[2] is List) {
              SaveSettings.dovizList = (decoded[2] as List)
                  .map((e) => GetDovizler.fromJson(e as Map<String, dynamic>))
                  .where((d) => d.durum == 1)
                  .toList();
            }

            // 3. Yazıcılar
            if (decoded.length > 3 && decoded[3] is List) {
              final yazList = (decoded[3] as List)
                  .map((e) => GetYaziciListele.fromJson(e as Map<String, dynamic>))
                  .toList();
              SaveSettings.yaziciList = yazList;
              SaveSettings.yaziciKontrol = yazList.isNotEmpty;
            }

            // 4. Yetkiler
            if (decoded.length > 4 && decoded[4] is List) {
              SaveSettings.yetkiList = (decoded[4] as List)
                  .map((e) => GetMobYetki.fromJson(e as Map<String, dynamic>))
                  .toList();
              
              SaveSettings.yStokKartlari = SaveSettings.getKullaniciYetki('00.00');
              SaveSettings.yAlisIrsaliyesi = SaveSettings.getKullaniciYetki('01.02.00');
              SaveSettings.ySatisIrsaliyesi = SaveSettings.getKullaniciYetki('01.02.01');
              SaveSettings.yAlisFaturasi = SaveSettings.getKullaniciYetki('01.03.00');
              SaveSettings.ySatisFaturasi = SaveSettings.getKullaniciYetki('01.03.01');
              SaveSettings.yStok = SaveSettings.getKullaniciYetki('01.04');
              SaveSettings.yDepoTransferFisi = SaveSettings.getKullaniciYetki('01.04.02');
              SaveSettings.yStokBarkodEtiketiBasimi = SaveSettings.getKullaniciYetki('01.04.09');
              SaveSettings.yStokSayimDuzeltmeFisi = SaveSettings.getKullaniciYetki('01.04.12');
              SaveSettings.ySiparis = SaveSettings.getKullaniciYetki('01.01');
              SaveSettings.yAlinanSiparisler = SaveSettings.getKullaniciYetki('01.01.00');
              SaveSettings.yVerilenSiparisler = SaveSettings.getKullaniciYetki('01.01.01');
              SaveSettings.yKasaIslemleri = SaveSettings.getKullaniciYetki('01.12');
              SaveSettings.yBankaIslemleri = SaveSettings.getKullaniciYetki('01.11');
              SaveSettings.yBankaHesapIslemleri = SaveSettings.getKullaniciYetki('01.11.00');
              SaveSettings.yCariAnaMenu = SaveSettings.getKullaniciYetki('02.03');
              SaveSettings.yAsSevkiyat = SaveSettings.getKullaniciYetki('01.01.10');
              SaveSettings.yVsTeslimAlma = SaveSettings.getKullaniciYetki('01.01.11');
              SaveSettings.yFatura = SaveSettings.getKullaniciYetki('01.03');
              SaveSettings.yIrsaliye = SaveSettings.getKullaniciYetki('01.02');
            }

            // 5. İşlem Mprm
            if (decoded.length > 5 && decoded[5] is List) {
              SaveSettings.depoTransferAyarList.clear();
              SaveSettings.sayimAyarList.clear();
              SaveSettings.malKabulAyarList.clear();
              SaveSettings.satisAyarList.clear();
              SaveSettings.stokIslemAyarList.clear();
              SaveSettings.siparisAyarList.clear();
              SaveSettings.sistemAyarList.clear();

              for (final item in decoded[5]) {
                final mprm = GetIslemMprm.fromJson(item as Map<String, dynamic>);
                if (mprm.mId == 1) {
                  SaveSettings.depoTransferAyarList.add(mprm);
                } else if (mprm.mId == 2) {
                  SaveSettings.sayimAyarList.add(mprm);
                } else if (mprm.mId == 3) {
                  SaveSettings.malKabulAyarList.add(mprm);
                } else if (mprm.mId == 4) {
                  SaveSettings.satisAyarList.add(mprm);
                } else if (mprm.mId == 5) {
                  SaveSettings.stokIslemAyarList.add(mprm);
                } else if (mprm.mId == 6) {
                  SaveSettings.siparisAyarList.add(mprm);
                } else if (mprm.mId == 7) {
                  SaveSettings.sistemAyarList.add(mprm);
                }
              }

              SaveSettings.depoTransferBirimFiyat = SaveSettings.getFiyatTur(SaveSettings.depoTransferAyarList, 'fiyatod');
              SaveSettings.sayimBirimFiyat = SaveSettings.getFiyatTur(SaveSettings.sayimAyarList, 'fiyatod');
              SaveSettings.malAlimFaturaBirimFiyat = SaveSettings.getFiyatTur(SaveSettings.malKabulAyarList, 'faturaod');
              SaveSettings.malAlimFisBirimFiyat = SaveSettings.getFiyatTur(SaveSettings.malKabulAyarList, 'fisod');
              SaveSettings.malAlimIrsaliyeBirimFiyat = SaveSettings.getFiyatTur(SaveSettings.malKabulAyarList, 'irsaliyeod');
              SaveSettings.satisFaturaBirimFiyat = SaveSettings.getFiyatTur(SaveSettings.satisAyarList, 'faturaod');
              SaveSettings.satisFisBirimFiyat = SaveSettings.getFiyatTur(SaveSettings.satisAyarList, 'fisod');
              SaveSettings.satisIrsaliyeBirimFiyat = SaveSettings.getFiyatTur(SaveSettings.satisAyarList, 'irsaliyeod');
              SaveSettings.alinanSiparisBirimFiyat = SaveSettings.getFiyatTur(SaveSettings.siparisAyarList, 'asfiyatod');
              SaveSettings.verilenSiparisBirimFiyat = SaveSettings.getFiyatTur(SaveSettings.siparisAyarList, 'vsfiyatod');

              SaveSettings.stokTurFiltre = SaveSettings.getModulAyar(SaveSettings.sistemAyarList, 'stokfiltre');
            }

            // 6. İşlem Kprm (Kullanıcı Ayarları)
            if (decoded.length > 6 && decoded[6] is List) {
              SaveSettings.kullaniciAyarlariList = (decoded[6] as List)
                  .map((e) => GetKullaniciAyarlari.fromJson(e as Map<String, dynamic>))
                  .toList();
            }

            // 7. Şube Kasa
            if (decoded.length > 7 && decoded[7] is List) {
              SaveSettings.subeKasaList = (decoded[7] as List)
                  .map((e) => GetSubeKasa.fromJson(e as Map<String, dynamic>))
                  .where((k) => k.durum == 1)
                  .toList();
            }

            // 8. Şube Banka
            if (decoded.length > 8 && decoded[8] is List) {
              SaveSettings.subeBankaList = (decoded[8] as List)
                  .map((e) => GetSubeBanka.fromJson(e as Map<String, dynamic>))
                  .where((b) => b.durum == 1)
                  .toList();
            }

            // 9. Şube Depo
            if (decoded.length > 9 && decoded[9] is List) {
              SaveSettings.subeDepoList = (decoded[9] as List)
                  .map((e) => GetSubeDepo.fromJson(e as Map<String, dynamic>))
                  .where((d) => d.durum == 1)
                  .toList();
            }

            // 10. Tüm Depolar
            if (decoded.length > 10 && decoded[10] is List) {
              SaveSettings.tumDepolar = (decoded[10] as List)
                  .map((e) => GetDepo.fromJson(e as Map<String, dynamic>))
                  .toList();
            }

            // 11. Personel
            if (decoded.length > 11 && decoded[11] is List) {
              SaveSettings.personelList = (decoded[11] as List)
                  .map((e) => GetPersonel.fromJson(e as Map<String, dynamic>))
                  .toList();
            }

            // MobLog kaydı
            getMobLog('GİRİŞ');

            AppLogger.log('GET_GIRIS_SUCCESS', 'Kullanıcı parametreleri başarıyla yüklendi.',
                level: LogLevel.success,
                details: {
                  'Kullanıcı Adı': SaveSettings.kullaniciAdi,
                  'Kullanıcı Kodu': SaveSettings.kullaniciKodu,
                  'Şube ID/Adı': '${SaveSettings.subeId} - ${SaveSettings.subeAdi}',
                  'Depo ID/Adı': '${SaveSettings.depoId} - ${SaveSettings.depoAdi}',
                  'Kasa ID/Adı': '${SaveSettings.kasaId} - ${SaveSettings.kasaAdi}',
                  'Banka ID/Adı': '${SaveSettings.bankaId} - ${SaveSettings.bankaAdi}',
                  'Döviz Adet': SaveSettings.dovizList.length,
                  'Yetki Adet': SaveSettings.yetkiList.length,
                });

            return {'success': true, 'durum': durum};
          } else if (durum == Numarator.apkVersiyonEski) {
            AppLogger.log('API_WARN', 'Uygulama versiyonu eski (Durum: $durum)', level: LogLevel.warning);
            return {'success': false, 'durum': durum, 'message': 'Uygulama versiyonu eski.'};
          } else if (durum == Numarator.wsVersiyonEski) {
            AppLogger.log('API_WARN', 'Web servis versiyonu eski (Durum: $durum)', level: LogLevel.warning);
            return {'success': false, 'durum': durum, 'message': 'Web servis versiyonu eski.'};
          } else {
            final errMsg = 'Giriş yapılamadı (Hata: $durum)';
            AppLogger.log('API_WARN', errMsg, level: LogLevel.warning);
            return {'success': false, 'durum': durum, 'message': errMsg};
          }
        }
      }
      final errMsg = 'Sunucu hatası: HTTP ${response.statusCode}';
      AppLogger.log('API_ERR', errMsg, level: LogLevel.error);
      return {'success': false, 'message': errMsg};
    } catch (e) {
      final errMsg = 'Giriş parametreleri yüklenirken hata: $e';
      AppLogger.log('API_ERR', errMsg, level: LogLevel.error);
      return {'success': false, 'message': errMsg};
    }
  }

  static Future<void> getMobLog(String durum) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetMobLog}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': SaveSettings.userId.toString(),
          'MACADRES': SaveSettings.macAdres,
          'CIHAZAD': 'Flutter_BYM360',
          'CIHAZVERSIYON': ApiConstants.appVersion,
          'DURUM': durum,
        },
      );
      await http.get(uri);
    } catch (e) {
      debugPrint('getMobLog error: $e');
    }
  }


  static String mapBelgeTuruToApi(String tur) {
    switch (tur.toUpperCase()) {
      case 'TRANSFER':
      case 'DEPO_SEVK':
      case 'DEPOSEVK':
        return 'depoSevk';
      case 'SAYIM':
        return 'sayim';
      case 'SIPARIS':
      case 'ATAMALITESLIMALMA':
        return 'atamaliteslimalma';
      case 'SEVK_ISTEK':
        return 'depoistek';
      case 'SEVK_IADE_ISTEK':
        return 'depoistekiade';
      case 'DEPOISTEKGONDERIM':
        return 'depoistekgonderim';
      case 'MALKABUL':
      case 'KABULISLEM':
        return 'kabul';
      case 'SATIS':
      case 'SATISISLEM':
        return 'satis';
      case 'ALIS_IADE':
      case 'KABULIADEISLEM':
        return 'kabulIade';
      case 'SATIS_IADE':
      case 'SATISIADEISLEM':
        return 'satisIade';
      case 'ALINAN_SIPARIS':
      case 'ALINANSIPARIS':
        return 'alinansiparis';
      case 'VERILEN_SIPARIS':
      case 'VERILENSIPARIS':
        return 'verilensiparis';
      case 'SIPARISTESLIMAL':
      case 'SP_TESLIM':
        return 'teslimalma';
      case 'SIPARISSEVKIYAT':
      case 'SP_SEVK':
        return 'sevkiyat';
      default:
        return tur;
    }
  }

  static int mapBelgeTuruToNumericId(String tur) {
    switch (tur.toUpperCase()) {
      case 'SAYIM':
      case '4':
        return 4;
      case 'TRANSFER':
      case 'DEPO_SEVK':
      case 'DEPOSEVK':
      case '49':
        return 49;
      case 'SEVK_ISTEK':
      case 'SEVK_IADE_ISTEK':
      case 'DEPO_ISTEK':
      case '89':
        return 89;
      case 'MALKABUL':
      case 'KABULISLEM':
      case '43':
        return 43; // Alım İrsaliyesi
      case 'SATIS':
      case 'SATISISLEM':
      case '41':
        return 41; // Satış İrsaliyesi
      case 'ALIS_IADE':
      case 'KABULIADEISLEM':
      case '46':
        return 46;
      case 'SATIS_IADE':
      case 'SATISIADEISLEM':
      case '42':
        return 42;
      case 'ALINAN_SIPARIS':
      case 'ALINANSIPARIS':
      case 'SIPARIS':
      case '33':
        return 33;
      case 'VERILEN_SIPARIS':
      case 'VERILENSIPARIS':
      case '34':
        return 34;
      case 'SP_SEVK':
      case 'SIPARISSEVKIYAT':
        return 41;
      case 'SP_TESLIM':
      case 'SIPARISTESLIMAL':
        return 43;
      default:
        return int.tryParse(tur) ?? 4;
    }
  }

  static String mapBelgeTuruFromNumericId(int turId) {
    switch (turId) {
      case 49:
        return 'depoSevk';
      case 89:
        return 'depoIstek';
      case 4:
        return 'sayim';
      case 43:
        return 'malKabul';
      case 41:
        return 'satis';
      case 46:
        return 'alisIade';
      case 42:
        return 'satisIade';
      case 33:
        return 'alinanSiparis';
      case 34:
        return 'verilenSiparis';
      default:
        return 'depoSevk';
    }
  }

  static Future<List<GetBelgeListele>> getBelgeListele({
    String tur = '',
    int gunLimit = 30,
    int limit = 100,
    int cariId = 0,
    int belgeId = 0,
    String listelemeTur = 'Hepsi',
  }) async {
    try {
      final isAll = tur.isEmpty || tur == 'GUNLUK_ISLEM' || tur == 'TUMU';
      final apiTur = isAll ? '' : mapBelgeTuruToApi(tur);
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeListele}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'TUR': apiTur,
          'GUNLIMIT': gunLimit.toString(),
          'LIMIT': limit.toString(),
          'KULLANICIGRUPTUR': SaveSettings.grupTur.toString(),
          'USERID': SaveSettings.userId.toString(),
          'LISTELEMETUR': listelemeTur,
          'CARIID': cariId.toString(),
          'BELGEID': belgeId.toString(),
        },
      );

      debugPrint('getBelgeListele URI: $uri');
      final response = await http.get(uri);
      debugPrint('getBelgeListele response (${response.statusCode}): ${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded is List ? decoded : [decoded];
        if (list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          final durum = parseInt(first['DURUM'] ?? first['durum']);
          if (durum != 1 && durum != Numarator.basarili) {
            return [];
          }
        }
        final resultList = list.map((item) => GetBelgeListele.fromJson(item as Map<String, dynamic>)).toList();
        SaveSettings.belgeList = resultList;
        return resultList;
      }
    } catch (e) {
      debugPrint('getBelgeListele error: $e');
    }
    return [];
  }

  static Future<List<GetStok>> getStokAra(String query) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetStokAra}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.appVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'BARKOD': query,
          'FIYATTUR': '0',
          'CARIID': SaveSettings.secilenCariID.toString(),
          'AKILLIARAMA': '1',
          'STOKFILTRE': '',
          'KULLANICIGRUPTUR': '0',
          'SUBEID': SaveSettings.subeId.toString(),
        },
      );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => GetStok.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getStokAra error: $e');
    }
    return [];
  }

  static Future<List<GetCari>> getCariAra(String query, {String filtre = 'Hepsi'}) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointGetCariAra}';
      AppLogger.log('API_REQ', 'GET $endpoint', level: LogLevel.api, details: {'query': query, 'filtre': filtre});

      final uri = Uri.parse(endpoint).replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'CARI': query,
          'FILTRE': filtre.isEmpty ? 'Hepsi' : filtre,
          'USERID': SaveSettings.userId.toString(),
          'KULLANICIGRUPTUR': SaveSettings.grupTur.toString(),
        },
      );

      final response = await http.get(uri);
      AppLogger.log('API_RESP', 'GET $endpoint Kodu: ${response.statusCode}',
          level: response.statusCode == 200 ? LogLevel.api : LogLevel.error);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final resultList = list.map((item) => GetCari.fromJson(item)).toList();
        AppLogger.log('API_SUCCESS', 'Cari Ara Başarılı: ${resultList.length} cari bulundu', level: LogLevel.info);
        return resultList;
      }
    } catch (e) {
      AppLogger.log('API_ERR', 'getCariAra Hatası: $e', level: LogLevel.error);
    }
    return [];
  }

  static Future<List<GetFiyatGor>> getFiyatGor(String barcode) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetFiyatGor}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.appVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'BARKOD': barcode,
          'AKILLIARAMA': '1',
          'STOKFILTRE': '',
          'KULLANICIGRUPTUR': '0',
          'SUBEID': SaveSettings.subeId.toString(),
          'DEPOID': SaveSettings.depoId.toString(),
        },
      );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => GetFiyatGor.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getFiyatGor error: $e');
    }
    return [];
  }

  static Future<List<GetAjanda>> getAjanda([int? perId]) async {
    try {
      final targetPerId = perId ?? SaveSettings.perId;
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetAjanda}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'PERID': targetPerId.toString(),
        },
      );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => GetAjanda.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getAjanda error: $e');
    }
    return [];
  }

  static Future<bool> addAjanda({
    required int perId,
    required String tarih,
    required int saat,
    required String yer,
    required String notlar,
    required String durum,
    required String sonuc,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointAddAjanda}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'PERID': perId.toString(),
          'TARIH': tarih,
          'SAAT': saat.toString(),
          'YER': yer,
          'NOTLAR': notlar,
          'DURUM': durum,
          'KPERID': SaveSettings.perId.toString(),
          'SONUC': sonuc,
        },
      );

      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('addAjanda error: $e');
    }
    return false;
  }

  static Future<List<GetDovizler>> getDovizler() async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}/api/dovizler').replace(
        queryParameters: {'TOKEN': SaveSettings.token},
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => GetDovizler.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getDovizler error: $e');
    }
    return [];
  }

  static Future<List<GetMatbuTasarim>> getMatbuTasarimlar(String matbuTuru) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}/api/matbu_tasarimlar').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'MATBUTURU': matbuTuru,
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => GetMatbuTasarim.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getMatbuTasarimlar error: $e');
    }
    return [];
  }

  // Belge Onay & Onay İptal
  static Future<bool> belgeOnay(int belgeId) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeOnay}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'BELGEID': belgeId.toString(),
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('belgeOnay error: $e');
      return false;
    }
  }

  static Future<bool> belgeOnayIptal(int belgeId) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeOnayIptal}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'BELGEID': belgeId.toString(),
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('belgeOnayIptal error: $e');
      return false;
    }
  }

  // Satır Güncelleme (Mobway Cloud Get_BelgeSatirGuncelle + Depo Sevk / Sayım Fallback)
  static Future<bool> belgeSatirGuncelle({
    required int belgeId,
    required int belgeTuru,
    required int sira,
    required int stokId,
    required double miktar,
    required double urunFiyat,
    double oldMiktar = 0.0,
    String barkod = '',
    int depoId = 0,
    int subeId = 0,
    int cariId = 0,
    String kdvDh = 'D',
    bool bFiyatYetki = true,
  }) async {
    // 1. Depo Sevk (49) ve Sayım (4, 89) için doğrudan urunSil + urunEkle çalıştır
    if (belgeTuru == 49 || belgeTuru == 89 || belgeTuru == 4) {
      if (oldMiktar > 0 || sira > 0) {
        await urunSil(
          belgeId: belgeId,
          belgeTuru: belgeTuru,
          satir: sira,
          stokId: stokId,
          miktar: oldMiktar > 0 ? oldMiktar : miktar,
        );
      }
      return await urunEkle(
        belgeTuru: mapBelgeTuruFromNumericId(belgeTuru),
        barkod: barkod,
        belgeId: belgeId,
        stokId: stokId,
        miktar: miktar,
        depoId: depoId > 0 ? depoId : SaveSettings.depoId,
        subeId: subeId > 0 ? subeId : SaveSettings.subeId,
        cariId: cariId,
        urunFiyat: urunFiyat,
      );
    }

    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeSatirGuncelle}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'BELGEID': belgeId.toString(),
          'BELGETURU': belgeTuru.toString(),
          'SIRA': sira.toString(),
          'STOKID': stokId.toString(),
          'MIKTAR': miktar.toString(),
          'URUNFIYAT': urunFiyat.toString(),
          'KDVDH': kdvDh,
          'BFIYATYETKI': bFiyatYetki.toString(),
        },
      );
      debugPrint('belgeSatirGuncelle URI: $uri');
      final response = await http.get(uri);
      debugPrint('belgeSatirGuncelle response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded is List ? decoded : [decoded];
        if (list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          final durum = parseInt(first['DURUM'] ?? first['durum']);
          if (durum == 1 || durum == Numarator.basarili) {
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('belgeSatirGuncelle error: $e');
    }

    // 2. Fallback: Diğer belge türlerinde sunucu DURUM 9/hata döndürürse urunSil + urunEkle ile güncelle
    try {
      if (oldMiktar > 0 || sira > 0) {
        await urunSil(
          belgeId: belgeId,
          belgeTuru: belgeTuru,
          satir: sira,
          stokId: stokId,
          miktar: oldMiktar > 0 ? oldMiktar : miktar,
        );
      }
      return await urunEkle(
        belgeTuru: mapBelgeTuruFromNumericId(belgeTuru),
        barkod: barkod,
        belgeId: belgeId,
        stokId: stokId,
        miktar: miktar,
        depoId: depoId > 0 ? depoId : SaveSettings.depoId,
        subeId: subeId > 0 ? subeId : SaveSettings.subeId,
        cariId: cariId,
        urunFiyat: urunFiyat,
      );
    } catch (e) {
      debugPrint('belgeSatirGuncelle fallback error: $e');
      return false;
    }
  }

  static Future<bool> postSatirIskonto({
    required int satirId,
    required double iskontoOrani,
  }) async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointPostSatirIskonto}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'TOKEN': SaveSettings.token,
          'SATIRID': satirId,
          'ISKONTOORANI': iskontoOrani,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('postSatirIskonto error: $e');
      return false;
    }
  }

  // Cari Bakiye & Ekstre Servisleri
  static Future<double> getCariBakiye(int cariId) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetCariBakiye}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'CARIID': cariId.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return (data['BAKIYE'] ?? 0).toDouble();
      }
    } catch (e) {
      debugPrint('getCariBakiye error: $e');
    }
    return 0.0;
  }

  static Future<List<GetCariHesapEkstre>> getCariHesapEkstre({
    required int cariId,
    String? tarih1,
    String? tarih2,
  }) async {
    try {
      final t1 = tarih1 ?? '1900-01-01';
      final t2 = tarih2 ?? '2050-01-01';
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetCariHesapEkstre}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'CARIID': cariId.toString(),
          'TARIH1': t1,
          'TARIH2': t2,
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => GetCariHesapEkstre.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getCariHesapEkstre error: $e');
    }
    return [];
  }

  // Modül Parametreleri ve Yetkiler
  static Future<List<GetIslemMprm>> getIslemMprm() async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetIslemMprm}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => GetIslemMprm.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getIslemMprm error: $e');
    }
    return [];
  }

  static Future<List<GetMobYetki>> getMobYetki() async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetMobYetki}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => GetMobYetki.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getMobYetki error: $e');
    }
    return [];
  }

  static Future<List<GetBelgeKapatListe>> getBelgeKapatListe() async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeKapatListe}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => GetBelgeKapatListe.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getBelgeKapatListe error: $e');
    }
    return [];
  }

  static Future<bool> belgeKapat(int belgeId) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointPostBelgeKapat}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'BELGEID': belgeId.toString(),
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('belgeKapat error: $e');
      return false;
    }
  }

  static Future<bool> belgeTahsilKasa({
    required int fatTur,
    required int fisId,
    required int subeId,
    required int kasaId,
    required double tutar,
    required int cariId,
    required String fisAciklama,
    required String tarih,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeTahsilKasa}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'FATTUR': fatTur.toString(),
          'FISID': fisId.toString(),
          'SUBEID': subeId.toString(),
          'KASAID': kasaId.toString(),
          'TUTAR': tutar.toString(),
          'CARIID': cariId.toString(),
          'FISACIKLAMA': fisAciklama,
          'TARIH': tarih,
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('belgeTahsilKasa error: $e');
      return false;
    }
  }

  static Future<bool> belgeTahsilBanka({
    required int fatTur,
    required int fisId,
    required int subeId,
    required int bankaId,
    required double tutar,
    required int cariId,
    required String fisAciklama,
    required String tarih,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeTahsilBanka}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'FATTUR': fatTur.toString(),
          'FISID': fisId.toString(),
          'SUBEID': subeId.toString(),
          'BANKAID': bankaId.toString(),
          'TUTAR': tutar.toString(),
          'CARIID': cariId.toString(),
          'FISACIKLAMA': fisAciklama,
          'TARIH': tarih,
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('belgeTahsilBanka error: $e');
      return false;
    }
  }

  static Future<String> getBelgeNo(String tur) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeNo}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'TUR': tur,
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data.first['BELGENO']?.toString() ?? '';
        }
      }
    } catch (e) {
      debugPrint('getBelgeNo error: $e');
    }
    return '';
  }

  static Future<bool> postUrunToplamaKayit(int belgeId, List<Map<String, dynamic>> items) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointPostUrunToplamaKayit}');
      final formattedItems = items.map((item) {
        final stokId = item['stokId'] ?? item['STOKID'] ?? 0;
        final barkod = item['barkod'] ?? item['BARKOD'] ?? item['STOKBARKOD'] ?? '';
        final stokAdi = item['stokAdi'] ?? item['STOKAD'] ?? item['STOKADI'] ?? '';
        final miktar = (item['miktar'] ?? item['MIKTAR'] ?? 1.0).toDouble();
        return {
          'BELGEID': belgeId,
          'STOKID': stokId,
          'stokId': stokId,
          'BARKOD': barkod,
          'STOKBARKOD': barkod,
          'barkod': barkod,
          'STOKAD': stokAdi,
          'STOKADI': stokAdi,
          'stokAdi': stokAdi,
          'MIKTAR': miktar,
          'miktar': miktar,
        };
      }).toList();

      final bodyData = {
        'kullaniciBilgileri': {
          'token': SaveSettings.token,
          'kulKod': SaveSettings.superUserPosta,
          'version': ApiConstants.fullVersion,
          'userId': SaveSettings.userId,
        },
        'Data': {
          'islemKodu': '001',
          'list': formattedItems,
        },
        'TOKEN': SaveSettings.token,
        'BELGEID': belgeId,
        'USERID': SaveSettings.userId,
        'ITEMS': formattedItems,
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        try {
          final resJson = jsonDecode(response.body);
          if (resJson is List && resJson.isNotEmpty) {
            final firstObj = resJson.first;
            if (firstObj is Map && (firstObj['DURUM'] == 0 || firstObj['durum'] == 0)) {
              // Mobway API returns DURUM == 0 for success
              return true;
            }
          } else if (resJson is Map) {
            if (resJson['DURUM'] == 0 || resJson['durum'] == 0 || resJson['success'] == true || resJson['STATUS'] == 'OK') {
              return true;
            }
          }
        } catch (_) {}
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('postUrunToplamaKayit error: $e');
      return false;
    }
  }

  static Future<bool> postAtamaliTeslimAlma(int siparisId, List<Map<String, dynamic>> items) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointPostAtamaliTeslimAlma}');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'TOKEN': SaveSettings.token,
          'SIPARISID': siparisId,
          'USERID': SaveSettings.userId,
          'ITEMS': items,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('postAtamaliTeslimAlma error: $e');
      return false;
    }
  }

  static Future<List<Firma>> getFirmaListele() async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetFirmaListele}').replace(
        queryParameters: {'TOKEN': SaveSettings.token},
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => Firma.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('getFirmaListele error: $e');
    }
    return [];
  }


  // Belge Ekleme (Detaylı Sonuç ile)
  static Future<Map<String, dynamic>> belgeEkleDetailed({
    required int belgeTuru,
    required String belgeNo,
    required String aciklama,
    required int cariId,
    required int depoId,
    required int subeId,
    int oPlan = 0,
    int varisDepo = 0,
    int gonderenFisId = 0,
    int parametre = 0,
    String cYansit = '',
    String teslimTarih = '',
    String belgeTarihi = '',
  }) async {
    try {
      final now = DateTime.now();
      final nowStr = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
      final bTarih = belgeTarihi.isNotEmpty ? belgeTarihi : nowStr;
      final tTarih = teslimTarih.isNotEmpty ? teslimTarih : nowStr;

      // Belge Türüne Göre bymmobil Parametre Uyarlamaları
      int finalBelgeTuru = belgeTuru;
      int finalCariId = cariId;
      int finalOPlan = oPlan;
      int finalVarisDepo = varisDepo;
      int finalGonderenFisId = gonderenFisId;
      int finalParametre = parametre;

      if (belgeTuru == 49) {
        // Depo Sevk / Transfer:
        // bymmobil: BELGETURU=49, CARIID=0, DEPOID=CikisDepoID, OPLAN=GirisDepoID, PARAMETRE=1, VARISDEPO=0, GONDERENFISID=0
        finalCariId = 0;
        if (finalOPlan == 0 && varisDepo > 0) {
          finalOPlan = varisDepo;
        }
        finalParametre = 1;
        finalVarisDepo = 0;
        finalGonderenFisId = 0;
      } else if (belgeTuru == 89) {
        // Depo Sevk İstek / İade İstek:
        finalCariId = 0;
        if (finalOPlan == 0 && varisDepo > 0) {
          finalOPlan = varisDepo;
        }
        finalVarisDepo = 0;
        finalGonderenFisId = 0;
      } else if (belgeTuru == 4) {
        // Sayım:
        finalCariId = 0;
        finalVarisDepo = 1;
        finalGonderenFisId = 1;
        finalParametre = 0;
      } else if (belgeTuru == 43 || belgeTuru == 41 || belgeTuru == 46 || belgeTuru == 42) {
        // Alım, Satış, Alış İade, Satış İade:
        finalVarisDepo = 1;
        finalGonderenFisId = 0;
      }

      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeEkle}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'BELGETURU': finalBelgeTuru.toString(),
          'BELGENO': belgeNo,
          'ACIKLAMA': aciklama,
          'CARIID': finalCariId.toString(),
          'DEPOID': (depoId > 0 ? depoId : SaveSettings.depoId).toString(),
          'SUBEID': (subeId > 0 ? subeId : SaveSettings.subeId).toString(),
          'OPLAN': finalOPlan.toString(),
          'USERID': SaveSettings.userId.toString(),
          'VARISDEPO': finalVarisDepo.toString(),
          'GONDERENFISID': finalGonderenFisId.toString(),
          'PARAMETRE': finalParametre.toString(),
          'CYANSIT': cYansit,
          'TESLIMTARIH': tTarih,
          'BELGETARIHI': bTarih,
        },
      );

      debugPrint('belgeEkle URI: $uri');
      final response = await http.get(uri);
      debugPrint('belgeEkle response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> data = (decoded is List && decoded.isNotEmpty)
            ? decoded.first as Map<String, dynamic>
            : (decoded is Map<String, dynamic> ? decoded : {});
        final durum = parseInt(data['DURUM'] ?? data['durum']);
        final id = parseInt(data['ID'] ?? data['FISID'] ?? data['id'] ?? data['fisId'] ?? data['BELGEID']);
        final mesaj = data['MESAJ']?.toString() ?? data['mesaj']?.toString() ?? '';
        final success = durum == 1 || durum == Numarator.basarili;

        return {
          'success': success,
          'id': id,
          'durum': durum,
          'mesaj': mesaj,
          'raw': data,
        };
      }
    } catch (e) {
      debugPrint('belgeEkle error: $e');
    }
    return {'success': false, 'id': 0, 'durum': 3, 'mesaj': 'Sunucu ile iletişim kurulamadı'};
  }

  // Belge Ekleme (Basit ID döndürür)
  static Future<int> belgeEkle({
    required int belgeTuru,
    required String belgeNo,
    required String aciklama,
    required int cariId,
    required int depoId,
    required int subeId,
    int oPlan = 0,
    int varisDepo = 0,
    int gonderenFisId = 0,
    int parametre = 0,
    String cYansit = '',
    String teslimTarih = '',
    String belgeTarihi = '',
  }) async {
    final res = await belgeEkleDetailed(
      belgeTuru: belgeTuru,
      belgeNo: belgeNo,
      aciklama: aciklama,
      cariId: cariId,
      depoId: depoId,
      subeId: subeId,
      oPlan: oPlan,
      varisDepo: varisDepo,
      gonderenFisId: gonderenFisId,
      parametre: parametre,
      cYansit: cYansit,
      teslimTarih: teslimTarih,
      belgeTarihi: belgeTarihi,
    );
    return res['id'] as int? ?? 0;
  }

  static Future<bool> etiketYazdir({
    required String barkod,
    int etiketId = 1,
    int yaziciId = 1,
    int miktar = 1,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetEtiketYazdir}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'BARKOD': barkod,
          'ETIKETID': etiketId.toString(),
          'YAZICIID': yaziciId.toString(),
          'MIKTAR': miktar.toString(),
          'USERID': SaveSettings.userId.toString(),
          'SUBEID': SaveSettings.subeId.toString(),
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('etiketYazdir error: $e');
      return false;
    }
  }

  static Future<List<GetTopluEtiket>> getTopluEtiketTarih({
    required String basTarih,
    required String bitTarih,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetTopluEtiketYazdir}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'BASTARIH': basTarih,
          'BITTARIH': bitTarih,
          'USERID': SaveSettings.userId.toString(),
          'SUBEID': SaveSettings.subeId.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => GetTopluEtiket.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('getTopluEtiketTarih error: $e');
    }
    return [];
  }

  static Future<bool> topluEtiketYazdir({
    required String yazdirKomut,
    int yaziciId = 0,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetTopluEtiketYazdir}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': SaveSettings.userId.toString(),
          'SUBEID': SaveSettings.subeId.toString(),
          'KOMUT': yazdirKomut,
          'YAZICIID': yaziciId.toString(),
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('topluEtiketYazdir error: $e');
      return false;
    }
  }

  // Single Belge Header Getir
  static Future<GetBelgeGetir?> belgeGetir(int tur, int id) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeGetir}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'TUR': tur.toString(),
          'ID': id.toString(),
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return GetBelgeGetir.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('belgeGetir error: $e');
    }
    return null;
  }

  // Belge Detay Satırları
  static Future<List<GetBelgeIcerik>> getBelgeDetay(int tur, int id) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeDetay}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'TUR': tur.toString(),
          'ID': id.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded is List ? decoded : [decoded];
        if (list.isEmpty) return [];
        final first = list.first as Map<String, dynamic>;
        final durum = parseInt(first['DURUM'] ?? first['durum']);
        // If durum is not 1 (e.g. 8 BOSBELGE or 3 HATA), return empty list
        if (durum != 1 && durum != Numarator.basarili) {
          return [];
        }
        return list.map((item) => GetBelgeIcerik.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('getBelgeDetay error: $e');
    }
    return [];
  }

  // Ürün Ekleme (Belgeye)
  static Future<bool> urunEkle({
    required String belgeTuru,
    required String barkod,
    required int belgeId,
    required int stokId,
    required double miktar,
    required double urunFiyat,
    int depoId = 0,
    int subeId = 0,
    int cariId = 0,
    String okunanBirim = 'ADET',
    double okunanCarpan = 1.0,
  }) async {
    try {
      final numericBelgeTurId = mapBelgeTuruToNumericId(belgeTuru);
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetUrunEkle}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'BELGETURU': numericBelgeTurId.toString(),
          'BARKOD': barkod,
          'BELGEID': belgeId.toString(),
          'STOKID': stokId.toString(),
          'MIKTAR': miktar.toString(),
          'REFTIPI': '0',
          'DEPOID': (depoId > 0 ? depoId : SaveSettings.depoId).toString(),
          'OPLANID': '0',
          'SUBEID': (subeId > 0 ? subeId : SaveSettings.subeId).toString(),
          'CARIID': cariId.toString(),
          'MIKTARKONTROL': '0',
          'URUNFIYAT': urunFiyat.toString(),
          'USERID': SaveSettings.userId.toString(),
          'URUNFIYATTUR': '0',
          'OKUNANBIRIM': okunanBirim,
          'OKUNANCARPAN': okunanCarpan.toString(),
          'ANABFIYAT': urunFiyat.toString(),
          'NEREDEBULDUN': '',
          'DOVIZID': '0',
          'DOVIZKUR': '1',
          'ASORTIID': '0',
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> data = (decoded is List && decoded.isNotEmpty)
            ? decoded.first as Map<String, dynamic>
            : (decoded is Map<String, dynamic> ? decoded : {});
        final durum = parseInt(data['DURUM'] ?? data['durum']);
        return durum == 1 || durum == Numarator.basarili;
      }
    } catch (e) {
      debugPrint('urunEkle error: $e');
    }
    return false;
  }

  // Ürün Silme
  static Future<bool> urunSil({
    required int belgeId,
    required int belgeTuru,
    required int satir,
    required int stokId,
    required double miktar,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetUrunSil}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.appVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'BELGEID': belgeId.toString(),
          'BELGETURU': belgeTuru.toString(),
          'SATIR': satir.toString(),
          'STOKID': stokId.toString(),
          'DEPOID': SaveSettings.depoId.toString(),
          'OPLANID': '0',
          'MIKTAR': miktar.toString(),
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('urunSil error: $e');
      return false;
    }
  }

  // Stok Detay
  static Future<GetStokDetay?> getStokDetay(int stokId) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetStokDetay}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.appVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'STOKID': stokId.toString(),
          'DEPOID': SaveSettings.depoId.toString(),
          'FISTARIH': '',
          'SUBEID': SaveSettings.subeId.toString(),
          'CARIID': '0',
          'BELGETURU': '0',
          'FIYATTUR': '0',
          'STOKBARKOD': '',
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return GetStokDetay.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('getStokDetay error: $e');
    }
    return null;
  }

  // Stok Kart İşlemleri (Ekleme/Güncelleme/Arama)
  static Future<List<GetStokIslem>> stokIslem({
    required int komut,
    int stokId = 0,
    String stokKodu = '',
    String barkod = '',
    String stokAdi = '',
    String birim = 'ADET',
    String kdv = 'Dahil',
    double alKdvOran = 18,
    double satKdvOran = 18,
    double alisFiyat = 0,
    double satisFiyat = 0,
    double oFiyat1 = 0,
    double oFiyat2 = 0,
    String barTur = 'EAN13',
    String ykKod = '',
    int akilliArama = 0,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetStokIslem}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.appVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'STOKID': stokId.toString(),
          'STOKKODU': stokKodu,
          'BARKOD': barkod,
          'STOKADI': stokAdi,
          'BIRIM': birim,
          'KDV': kdv,
          'ALKDVORAN': alKdvOran.toString(),
          'SATKDVORAN': satKdvOran.toString(),
          'ALISFIYAT': alisFiyat.toString(),
          'SATISFIYAT': satisFiyat.toString(),
          'OFIYAT1': oFiyat1.toString(),
          'OFIYAT2': oFiyat2.toString(),
          'OFIYAT3': '0',
          'OFIYAT4': '0',
          'OFIYAT5': '0',
          'OFIYAT6': '0',
          'KOMUT': komut.toString(),
          'USERID': SaveSettings.userId.toString(),
          'BARTUR': barTur,
          'AKILLIARAMA': akilliArama.toString(),
          'STOKFILTRE': '',
          'KULLANICIGRUPTUR': SaveSettings.grupTur.toString(),
          'ykKod': ykKod,
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => GetStokIslem.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('stokIslem error: $e');
    }
    return [];
  }

  static Future<List<GetStokLot>> getStokLot(String query) async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointStokLot}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kullaniciBilgileri': {
            'token': SaveSettings.token,
            'superUserAdi': SaveSettings.superUserPosta,
          },
          'data': query,
        }),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => GetStokLot.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('getStokLot error: $e');
    }
    return [];
  }

  static Future<String?> getStokFotoUrl(int stokId) async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointStokFotoUrl}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kullaniciBilgileri': {
            'token': SaveSettings.token,
            'superUserAdi': SaveSettings.superUserPosta,
          },
          'data': stokId,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is String) return data;
        if (data is Map && data.containsKey('url')) return data['url'].toString();
      }
    } catch (e) {
      debugPrint('getStokFotoUrl error: $e');
    }
    return null;
  }

  static Future<List<GetStokSeviyeKontrol>> getStokSeviyeKontrol() async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointStokSeviyeKontrol}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kullaniciBilgileri': {
            'token': SaveSettings.token,
            'superUserAdi': SaveSettings.superUserPosta,
          },
          'data': {
            'subeId': SaveSettings.subeId,
            'depoId': SaveSettings.depoId,
          },
        }),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => GetStokSeviyeKontrol.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('getStokSeviyeKontrol error: $e');
    }
    return [];
  }

  // Depocu & Kurye Entegrasyon Metodları
  static Future<List<dynamic>> depocuGetSiparis({String durum = 'ACIK'}) async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${durum == "TAMAM" ? ApiConstants.endpointDepocuGetSiparisTamamlanan : ApiConstants.endpointDepocuGetSiparisAcik}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kullaniciBilgileri': {
            'token': SaveSettings.token,
            'superUserAdi': SaveSettings.superUserPosta,
          },
        }),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list;
      }
    } catch (e) {
      debugPrint('depocuGetSiparis error: $e');
    }
    return [];
  }

  static Future<bool> depocuKuryeAta({required int siparisId, required int kuryeId}) async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointDepocuKuryeAta}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kullaniciBilgileri': {
            'token': SaveSettings.token,
            'superUserAdi': SaveSettings.superUserPosta,
          },
          'data': {
            'siparisId': siparisId,
            'kuryeId': kuryeId,
          },
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('depocuKuryeAta error: $e');
      return false;
    }
  }

  static Future<List<dynamic>> kuryeGetSip({bool tamamlanan = false}) async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${tamamlanan ? ApiConstants.endpointKuryeGetSipTamamlanan : ApiConstants.endpointKuryeGetSip}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kullaniciBilgileri': {
            'token': SaveSettings.token,
            'superUserAdi': SaveSettings.superUserPosta,
          },
          'data': {
            'kuryeId': SaveSettings.userId,
          },
        }),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list;
      }
    } catch (e) {
      debugPrint('kuryeGetSip error: $e');
    }
    return [];
  }

  static Future<bool> kuryeSipTamamla({required int siparisId, String aciklama = ''}) async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointKuryeSipTamamla}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kullaniciBilgileri': {
            'token': SaveSettings.token,
            'superUserAdi': SaveSettings.superUserPosta,
          },
          'data': {
            'siparisId': siparisId,
            'kuryeId': SaveSettings.userId,
            'aciklama': aciklama,
          },
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('kuryeSipTamamla error: $e');
      return false;
    }
  }

  // Ödeme & Banka Entegrasyon Servisleri
  static Future<List<dynamic>> getFinmaksBankAccounts() async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointFinmaksBankAccount}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('getFinmaksBankAccounts error: $e');
    }
    return [];
  }

  static Future<List<dynamic>> getOduyoBankaListesi() async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointOduyoBankaListesi}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('getOduyoBankaListesi error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> pavoCreatePaymentLink({required double tutar, required String aciklama}) async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointPavoCreatePaymentLink}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tutar': tutar,
          'aciklama': aciklama,
          'kullaniciId': SaveSettings.userId,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('pavoCreatePaymentLink error: $e');
    }
    return null;
  }

  static Future<bool> smsGonder({required String gsm, required String mesaj}) async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointSmsGonder}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'gsm': gsm,
          'mesaj': mesaj,
          'kullaniciId': SaveSettings.userId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('smsGonder error: $e');
      return false;
    }
  }

  // E-Posta Gönderim Servisi
  static Future<bool> mailGonder({required String to, required String konu, required String icerik}) async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointMailGonder}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': to,
          'konu': konu,
          'icerik': icerik,
          'kullaniciId': SaveSettings.userId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('mailGonder error: $e');
      return false;
    }
  }

  // E-Fatura & Kontür Servisi
  static Future<int> getBymKolayKalanKontur() async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointBymKolayKalanKontur}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is int) return data;
        if (data is Map && data.containsKey('kontur')) return parseInt(data['kontur']);
      }
    } catch (e) {
      debugPrint('getBymKolayKalanKontur error: $e');
    }
    return 0;
  }

  // Yazıcı Listesi
  static Future<List<GetYaziciListele>> getYazicilar() async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetYazicilar}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.appVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': SaveSettings.userId.toString(),
          'KULLANICIGRUPTUR': '0',
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => GetYaziciListele.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getYazicilar error: $e');
    }
    return [];
  }

  // Kasa Tahsilat Kaydetme
  static Future<bool> kasaTahsil({
    required int subeId,
    required int cariId,
    required int kasaId,
    required double tutar,
    required String tarih,
    required String aciklama,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetKasaTahsil}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.appVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'SUBEID': subeId.toString(),
          'CARIID': cariId.toString(),
          'KASAID': kasaId.toString(),
          'TUTAR': tutar.toString(),
          'TARIH': tarih,
          'ACIKLAMA': aciklama,
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('kasaTahsil error: $e');
      return false;
    }
  }

  // Banka Tahsilat Kaydetme
  static Future<bool> bankaTahsil({
    required int subeId,
    required int cariId,
    required int bankaId,
    required double tutar,
    required String tarih,
    required String aciklama,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBankaTahsil}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.appVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'SUBEID': subeId.toString(),
          'CARIID': cariId.toString(),
          'BANKAID': bankaId.toString(),
          'TUTAR': tutar.toString(),
          'TARIH': tarih,
          'ACIKLAMA': aciklama,
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('bankaTahsil error: $e');
      return false;
    }
  }

  // Kasa Tahsilat Listesi
  static Future<List<GetTahsilatListe>> getKasaTahsilListe({int gunLimit = 30}) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetKasaTahsilListe}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.appVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': SaveSettings.userId.toString(),
          'KULLANICIGRUPTUR': '0',
          'GUNLIMIT': gunLimit.toString(),
          'TAHSILATLIMIT': '100',
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => GetTahsilatListe.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getKasaTahsilListe error: $e');
    }
    return [];
  }

  // Banka Tahsilat Listesi
  static Future<List<GetTahsilatListe>> getBankaTahsilListe({int gunLimit = 30}) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBankaTahsilListe}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.appVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': SaveSettings.userId.toString(),
          'KULLANICIGRUPTUR': '0',
          'GUNLIMIT': gunLimit.toString(),
          'TAHSILATLIMIT': '100',
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => GetTahsilatListe.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getBankaTahsilListe error: $e');
    }
    return [];
  }

  // Tahsilat Silme
  static Future<bool> tahsilatSil(int odemeTur, int evrakId) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetTahsilatSil}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.appVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'ODEMETUR': odemeTur.toString(),
          'EVRAKID': evrakId.toString(),
          'USERID': SaveSettings.userId.toString(),
          'KULLANICIGRUPTUR': '0',
          'GUNLIMIT': '30',
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('tahsilatSil error: $e');
      return false;
    }
  }

  // Cari Ekleme
  static Future<bool> cariEkle({
    required String cariKod,
    required String cariAd,
    required String cariAdres,
    required String cariTel,
    required String cariGsm,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetCariEkle}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.appVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'CARIKOD': cariKod,
          'CARIAD': cariAd,
          'CARIADRES': cariAdres,
          'CARITEL': cariTel,
          'CARIGSM': cariGsm,
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('cariEkle error: $e');
      return false;
    }
  }

  // Kullanıcı Listesi
  static Future<List<GetKullaniciList>> getKullaniciList() async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetKullaniciList}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.appVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'KULLANICIGRUPTUR': '0',
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => GetKullaniciList.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('getKullaniciList error: $e');
    }
    return [];
  }

  // Ajanda Silme
  static Future<bool> deleteAjanda(int perId, int sira) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointDeleteAjanda}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.appVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'PERID': perId.toString(),
          'SIRA': sira.toString(),
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('deleteAjanda error: $e');
      return false;
    }
  }

  // Ajanda Güncelleme
  static Future<bool> updateAjanda({
    required int perId,
    required int sira,
    required String tarih,
    required int saat,
    required String yer,
    required String notlar,
    required String durum,
    required String sonuc,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointUpdateAjanda}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.appVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'PERID': perId.toString(),
          'SIRA': sira.toString(),
          'TARIH': tarih,
          'SAAT': saat.toString(),
          'YER': yer,
          'NOTLAR': notlar,
          'DURUM': durum,
          'SONUC': sonuc,
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('updateAjanda error: $e');
      return false;
    }
  }

  // Hata Mesajı Gönderme
  static Future<bool> postHataMesaji(String hataMetni, String sinif, String fonksiyon) async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointPostHataMesaji}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'a_firma': SaveSettings.firma,
          'a_cstring': SaveSettings.cstring,
          'a_uid': SaveSettings.userId.toString(),
          'a_subeid': SaveSettings.subeId.toString(),
          'a_sinif': sinif,
          'a_fonksiyon': fonksiyon,
          'a_hatametni': hataMetni,
          'a_arguments': '',
          'a_cdate': DateTime.now().toIso8601String(),
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('postHataMesaji error: $e');
      return false;
    }
  }

  // --- Swagger: /mobwaycloud/Get_MobLog (Detaylı) ---
  static Future<bool> getMobLogDetail({
    required String macAdres,
    required String cihazAd,
    required String cihazVersiyon,
    required int durum,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetMobLog}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': SaveSettings.userId.toString(),
          'MACADRES': macAdres,
          'CIHAZAD': cihazAd,
          'CIHAZVERSIYON': cihazVersiyon,
          'DURUM': durum.toString(),
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('getMobLogDetail error: $e');
      return false;
    }
  }

  // --- Swagger: /mobwaycloud/Post_UrunToplamaKayitEt ---
  static Future<Map<String, dynamic>> postUrunToplamaKayitEt(UrunToplamaKayitModel model) async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointPostUrunToplamaKayit}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kullaniciBilgileri': {
            'token': SaveSettings.token,
            'userId': SaveSettings.userId,
            'version': ApiConstants.fullVersion,
            'eposta': SaveSettings.superUserPosta,
          },
          'data': model.toJson(),
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Ürün toplama kaydedilemedi (HTTP ${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'message': 'Hata: $e'};
    }
  }

  // --- Swagger: /mobwaycloud/Post_AtamaliTeslimAlma (Model) ---
  static Future<Map<String, dynamic>> postAtamaliTeslimAlmaModel(AtamaliTeslimModel model) async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointPostAtamaliTeslimAlma}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kullaniciBilgileri': {
            'token': SaveSettings.token,
            'userId': SaveSettings.userId,
            'version': ApiConstants.fullVersion,
            'eposta': SaveSettings.superUserPosta,
          },
          'data': model.toJson(),
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Atamalı teslim kaydedilemedi (HTTP ${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'message': 'Hata: $e'};
    }
  }

  // --- Swagger: /mobwaycloud/Get_AtamaliSipDetGetir ---
  static Future<List<GetAtamaliSipDetGetir>> getAtamaliSipDetGetir({
    required int tur,
    required int id,
    required String islemKodu,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetAtamaliSipDetGetir}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'TUR': tur.toString(),
          'ID': id.toString(),
          'ISLEMKODU': islemKodu,
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => GetAtamaliSipDetGetir.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('getAtamaliSipDetGetir error: $e');
    }
    return [];
  }

  // --- Swagger: /mobwaycloud/X_Belge_No_Duzelt ---
  static Future<bool> xBelgeNoDuzelt({
    required String baglanti,
    required int tur,
    required int subeId,
    required int userId,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeNoDuzelt}').replace(
        queryParameters: {
          'baglanti': baglanti,
          'Tur': tur.toString(),
          'SUBEID': subeId.toString(),
          'USERID': userId.toString(),
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('xBelgeNoDuzelt error: $e');
      return false;
    }
  }


  // --- Swagger: /mobwaycloud/Get_CariRiskLimitKontrol ---
  static Future<Map<String, dynamic>> getCariRiskLimitKontrol({
    required int cariId,
    required int tur,
    required int belgeId,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetCariRiskLimitKontrol}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'CARIID': cariId.toString(),
          'TUR': tur.toString(),
          'BELGEID': belgeId.toString(),
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded[0] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('getCariRiskLimitKontrol error: $e');
    }
    return {'durum': 1};
  }

  // --- Swagger: /mobwaycloud/Get_CariSiparisKontrol ---
  static Future<List<dynamic>> getCariSiparisKontrol({
    required int sipTur,
    required int cariId,
    required int subeId,
    required int depoId,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetCariSiparisKontrol}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'SIPTUR': sipTur.toString(),
          'USERID': SaveSettings.userId.toString(),
          'KULLANICIGRUPTUR': SaveSettings.grupTur.toString(),
          'CARIID': cariId.toString(),
          'SUBEID': subeId.toString(),
          'DEPOID': depoId.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('getCariSiparisKontrol error: $e');
    }
    return [];
  }

  // --- Swagger: /mobwaycloud/Get_BelgeSatirGuncelle ---
  static Future<Map<String, dynamic>> getBelgeSatirGuncelle({
    required int belgeId,
    required int belgeTuru,
    required int sira,
    required int stokId,
    required double miktar,
    required double urunFiyat,
    required int kdvDh,
    required int bFiyatYetki,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeSatirGuncelle}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'BELGEID': belgeId.toString(),
          'BELGETURU': belgeTuru.toString(),
          'SIRA': sira.toString(),
          'STOKID': stokId.toString(),
          'MIKTAR': miktar.toString(),
          'URUNFIYAT': urunFiyat.toString(),
          'KDVDH': kdvDh.toString(),
          'BFIYATYETKI': bFiyatYetki.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded[0] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('getBelgeSatirGuncelle error: $e');
    }
    return {'durum': 0, 'mesaj': 'Güncelleme yapılamadı.'};
  }

  // --- Swagger: /mobwaycloud/Get_BelgeTahsilatSil ---
  static Future<bool> getBelgeTahsilatSil({
    required int odemeTur,
    required int evrakId,
    required int fatTur,
    required int belgeId,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeTahsilatSil}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'ODEMETUR': odemeTur.toString(),
          'EVRAKID': evrakId.toString(),
          'FATTUR': fatTur.toString(),
          'BELGEID': belgeId.toString(),
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('getBelgeTahsilatSil error: $e');
      return false;
    }
  }

  // --- Swagger: /mobwaycloud/Get_FisDizMasList ---
  static Future<List<GetFisDizMasList>> getFisDizMasList({
    required int tur,
    required int belgeId,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetFisDizMasList}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'TUR': tur.toString(),
          'BELGEID': belgeId.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => GetFisDizMasList.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('getFisDizMasList error: $e');
    }
    return [];
  }

  // --- Swagger: /mobwaycloud/Get_FisYazText ---
  static Future<String> getFisYazText({
    required int tur,
    required int belgeId,
    required int kId,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetFisYazText}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'TUR': tur.toString(),
          'BELGEID': belgeId.toString(),
          'KID': kId.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      debugPrint('getFisYazText error: $e');
    }
    return '';
  }

  // --- Swagger: /mobwaycloud/Get_YazsayUpdate ---
  static Future<bool> getYazsayUpdate({
    required int tur,
    required int belgeId,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetYazsayUpdate}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'TUR': tur.toString(),
          'BELGEID': belgeId.toString(),
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('getYazsayUpdate error: $e');
      return false;
    }
  }

  // --- Swagger: /mobwaycloud/Get_BelgeOnay ---
  static Future<Map<String, dynamic>> getBelgeOnay({
    required int tur,
    required int id,
    int? userId,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeOnay}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'TUR': tur.toString(),
          'ID': id.toString(),
          'USERID': (userId ?? SaveSettings.userId).toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded[0] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('getBelgeOnay error: $e');
    }
    return {'durum': 0, 'mesaj': 'Belge onaylanamadı.'};
  }

  // --- Swagger: /mobwaycloud/Get_BelgeOnayIptal ---
  static Future<Map<String, dynamic>> getBelgeOnayIptal({
    required int tur,
    required int id,
    int? userId,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeOnayIptal}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'TUR': tur.toString(),
          'ID': id.toString(),
          'USERID': (userId ?? SaveSettings.userId).toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded[0] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('getBelgeOnayIptal error: $e');
    }
    return {'durum': 0, 'mesaj': 'Belge onay iptal edilemedi.'};
  }

  // --- Swagger: Modül Güncelleme Servisleri ---
  static Future<bool> getDtModulGuncelle({
    required int userId,
    required String fiyatOndeger,
    required String miktarKontrol,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetDTModulGuncelle}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': userId.toString(),
          'FIYATONDEGER': fiyatOndeger,
          'MIKTARKONTROL': miktarKontrol,
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('getDtModulGuncelle error: $e');
      return false;
    }
  }

  static Future<bool> getSModulGuncelle({
    required int userId,
    required String fiyatOndeger,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetSModulGuncelle}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': userId.toString(),
          'FIYATONDEGER': fiyatOndeger,
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('getSModulGuncelle error: $e');
      return false;
    }
  }

  static Future<bool> getKblModulGuncelle({
    required int userId,
    required String faturaOndeger,
    required String fisOndeger,
    required String irsaliyeOndeger,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetKBLModulGuncelle}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': userId.toString(),
          'FATURAONDEGER': faturaOndeger,
          'FISONDEGER': fisOndeger,
          'IRSALIYEONDEGER': irsaliyeOndeger,
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('getKblModulGuncelle error: $e');
      return false;
    }
  }

  static Future<bool> getStsModulGuncelle({
    required int userId,
    required String faturaOndeger,
    required String fisOndeger,
    required String irsaliyeOndeger,
    required String negatifSatis,
    required String dipFiyat,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetSTSModulGuncelle}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': userId.toString(),
          'FATURAONDEGER': faturaOndeger,
          'FISONDEGER': fisOndeger,
          'IRSALIYEONDEGER': irsaliyeOndeger,
          'NEGATIFSATIS': negatifSatis,
          'DIPFIYAT': dipFiyat,
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('getStsModulGuncelle error: $e');
      return false;
    }
  }

  static Future<bool> getStkModulGuncelle({
    required int userId,
    required String akdvOran,
    required String kdv,
    required String skdvOran,
    required String varsayBrm,
    required String ozelFiyat,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetSTKModulGuncelle}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': userId.toString(),
          'AKDVORN': akdvOran,
          'KDV': kdv,
          'SKDVORN': skdvOran,
          'VARSAYBRM': varsayBrm,
          'OZELFIYAT': ozelFiyat,
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('getStkModulGuncelle error: $e');
      return false;
    }
  }

  static Future<bool> getSpModulGuncelle({
    required int userId,
    required String miktarKontrol,
    required String asFiyatOndeger,
    required String vsFiyatOndeger,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetSPModulGuncelle}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': userId.toString(),
          'MIKTARKONTROL': miktarKontrol,
          'ASFIYATONDEGER': asFiyatOndeger,
          'VSFIYATONDEGER': vsFiyatOndeger,
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('getSpModulGuncelle error: $e');
      return false;
    }
  }

  static Future<bool> getSprmModulGuncelle({
    required int userId,
    required String cariFiltre,
    required String stokFiltre,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetSPRMModulGuncelle}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': userId.toString(),
          'CARIFILTRE': cariFiltre,
          'STOKFILTRE': stokFiltre,
        },
      );
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('getSprmModulGuncelle error: $e');
      return false;
    }
  }

  // --- Swagger: /mobwaycloud/Get_KullaniciRapor ---
  static Future<List<GetKullaniciRapor>> getKullaniciRapor({
    required int id,
    required String tarih,
    required String islemKodu,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetKullaniciRapor}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'ID': id.toString(),
          'TARIH': tarih,
          'ISLEMKODU': islemKodu,
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => GetKullaniciRapor.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('getKullaniciRapor error: $e');
    }
    return [];
  }

  // --- Swagger: /mobwaycloud/Get_RaporYazdir ---
  static Future<String> getRaporYazdir({
    required int userId,
    required String tarih,
    required String islemKodu,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetRaporYazdir}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': userId.toString(),
          'TARIH': tarih,
          'ISLEMKODU': islemKodu,
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      debugPrint('getRaporYazdir error: $e');
    }
    return '';
  }

  // --- Swagger: /mobwaycloud/Get_TeslimAlmaUrunEkle ---
  static Future<Map<String, dynamic>> getTeslimAlmaUrunEkle({
    required int userId,
    required int depoId,
    required int cariId,
    required int sipBelgeId,
    required int belgeTur,
    required int belgeId,
    required int stokId,
    required double miktar,
    required String okunanBirim,
    required double okunanCarpan,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetTeslimAlmaUrunEkle}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': userId.toString(),
          'DEPOID': depoId.toString(),
          'CARIID': cariId.toString(),
          'SIPBELGEID': sipBelgeId.toString(),
          'BELGETUR': belgeTur.toString(),
          'BELGEID': belgeId.toString(),
          'STOKID': stokId.toString(),
          'MIKTAR': miktar.toString(),
          'OKUNANBIRIM': okunanBirim,
          'OKUNANCARPAN': okunanCarpan.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded[0] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('getTeslimAlmaUrunEkle error: $e');
    }
    return {'durum': 0, 'mesaj': 'Ürün teslim alma işleminde hata oluştu.'};
  }

  // --- Swagger: /mobwaycloud/Get_SevkiyatUrunEkle ---
  static Future<Map<String, dynamic>> getSevkiyatUrunEkle({
    required int userId,
    required int depoId,
    required int cariId,
    required int sipBelgeId,
    required int belgeTur,
    required int belgeId,
    required int stokId,
    required double miktar,
    required String okunanBirim,
    required double okunanCarpan,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetSevkiyatUrunEkle}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': userId.toString(),
          'DEPOID': depoId.toString(),
          'CARIID': cariId.toString(),
          'SIPBELGEID': sipBelgeId.toString(),
          'BELGETUR': belgeTur.toString(),
          'BELGEID': belgeId.toString(),
          'STOKID': stokId.toString(),
          'MIKTAR': miktar.toString(),
          'OKUNANBIRIM': okunanBirim,
          'OKUNANCARPAN': okunanCarpan.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded[0] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('getSevkiyatUrunEkle error: $e');
    }
    return {'durum': 0, 'mesaj': 'Ürün sevk işleminde hata oluştu.'};
  }

  // --- Swagger: /mobwaycloud/Get_SIPTeslimAl ---
  static Future<Map<String, dynamic>> getSIPTeslimAl({
    required int userId,
    required int belgeTur,
    required int belgeId,
    required int cariId,
    required int stokId,
    required double eklenecekMiktar,
    required String okunanBirim,
    required double okunanCarpan,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetSIPTeslimAl}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': userId.toString(),
          'BELGETUR': belgeTur.toString(),
          'BELGEID': belgeId.toString(),
          'CARIID': cariId.toString(),
          'STOKID': stokId.toString(),
          'EKLENECEKMIKTAR': eklenecekMiktar.toString(),
          'OKUNANBIRIM': okunanBirim,
          'OKUNANCARPAN': okunanCarpan.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded[0] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('getSIPTeslimAl error: $e');
    }
    return {'durum': 0, 'mesaj': 'Sipariş teslim alma hatası.'};
  }

  // --- Swagger: /mobwaycloud/Get_SIPSevkiyat ---
  static Future<Map<String, dynamic>> getSIPSevkiyat({
    required int userId,
    required int belgeTur,
    required int belgeId,
    required int cariId,
    required int stokId,
    required double eklenecekMiktar,
    required String okunanBirim,
    required double okunanCarpan,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetSIPSevkiyat}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'USERID': userId.toString(),
          'BELGETUR': belgeTur.toString(),
          'BELGEID': belgeId.toString(),
          'CARIID': cariId.toString(),
          'STOKID': stokId.toString(),
          'EKLENECEKMIKTAR': eklenecekMiktar.toString(),
          'OKUNANBIRIM': okunanBirim,
          'OKUNANCARPAN': okunanCarpan.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded[0] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('getSIPSevkiyat error: $e');
    }
    return {'durum': 0, 'mesaj': 'Sipariş sevk hatası.'};
  }

  // --- Swagger: /mobwaycloud/Get_UrlVersiyon ---
  static Future<String> getUrlVersiyon() async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetUrlVersiyon}');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      debugPrint('getUrlVersiyon error: $e');
    }
    return '';
  }

  // --- Swagger: /mobwaycloud/Get_KeySifirla ---
  static Future<bool> getKeySifirla() async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetKeySifirla}');
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('getKeySifirla error: $e');
      return false;
    }
  }

  // --- Swagger: /mobwaycloud/KW_BelgeOlustur ---
  static Future<Map<String, dynamic>> kwBelgeOlustur({
    required String barkod,
    required double miktar,
    required int cariId,
    required String boxNo,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetKwBelgeOlustur}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'BARKOD': barkod,
          'MIKTAR': miktar.toString(),
          'CARID': cariId.toString(),
          'BOXNO': boxNo,
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded[0] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('kwBelgeOlustur error: $e');
    }
    return {'durum': 0, 'mesaj': 'KW belge oluşturulamadı.'};
  }

  // --- Swagger: /mobwaycloud/satiriskonto ---
  static Future<Map<String, dynamic>> satirIskonto({
    required int fatId,
    required int fatTur,
    required List<MobwaySatirIskontoData> satirlar,
  }) async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointPostSatirIskonto}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kullaniciBilgileri': {
            'token': SaveSettings.token,
            'userId': SaveSettings.userId,
            'version': ApiConstants.fullVersion,
            'eposta': SaveSettings.superUserPosta,
          },
          'data': {
            'fatid': fatId,
            'fattur': fatTur,
            'satirlar': satirlar.map((s) => s.toJson()).toList(),
          },
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'İskonto uygulanamadı (HTTP ${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'message': 'Hata: $e'};
    }
  }

  // --- Swagger: /login/depoKurye ---
  static Future<Map<String, dynamic>> loginDepoKurye({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}login/depoKurye');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eposta': email,
          'kulKod': password,
          'version': ApiConstants.fullVersion,
          'project': ApiConstants.uygulamaId,
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Giriş başarısız (HTTP ${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'message': 'Hata: $e'};
    }
  }

  // --- Swagger: /login/GirisYapFast ---
  static Future<Map<String, dynamic>> girisYapFast(String email, String password) async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGirisYapFast}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eposta': email,
          'sifre': password,
          'versiyon': ApiConstants.fullVersion,
          'projeId': ApiConstants.uygulamaId,
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Hızlı giriş yapılamadı (HTTP ${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'message': 'Hata: $e'};
    }
  }

  // --- Swagger: /login/GirisYapP ---
  static Future<Map<String, dynamic>> girisYapP(String email, String password) async {
    try {
      final url = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGirisYapP}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eposta': email,
          'sifre': password,
          'versiyon': ApiConstants.fullVersion,
          'projeId': ApiConstants.uygulamaId,
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Giriş yapılamadı (HTTP ${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'message': 'Hata: $e'};
    }
  }

  // --- Swagger: /mobwaycloud/Get_IslemKprm ---
  static Future<List<GetIslemKprm>> getIslemKprm({
    required String islem,
    required String aNesne,
    required String aDeger,
    required String aVeri,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetIslemKprm}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'ISLEM': islem,
          'USERID': SaveSettings.userId.toString(),
          'A_NESNE': aNesne,
          'A_DEGER': aDeger,
          'A_VERI': aVeri,
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => GetIslemKprm.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('getIslemKprm error: $e');
    }
    return [];
  }

  // --- Swagger: /mobwaycloud/MB_BelgenoUret ---
  static Future<String> mbBelgenoUret({
    required String baglanti,
    required int tur,
    required int userId,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgenoUret}').replace(
        queryParameters: {
          'baglanti': baglanti,
          'TUR': tur.toString(),
          'userid': userId.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return (decoded[0]['BELGENO'] ?? '').toString();
        }
      }
    } catch (e) {
      debugPrint('mbBelgenoUret error: $e');
    }
    return '';
  }

  // --- Swagger: /mobwaycloud/Get_BelgeIciStokAra ---
  static Future<List<GetBelgeIciStokAra>> getBelgeIciStokAra({
    required String barkod,
    required int belgeId,
    required int belgeTur,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeIciStokAra}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'BARKOD': barkod,
          'BELGEID': belgeId.toString(),
          'BELGETUR': belgeTur.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => GetBelgeIciStokAra.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('getBelgeIciStokAra error: $e');
    }
    return [];
  }

  // --- Swagger: /mobwaycloud/Get_BelgeTahsilKasa ---
  static Future<Map<String, dynamic>> getBelgeTahsilKasa({
    required int fatTur,
    required int fisId,
    required int subeId,
    required int kasaId,
    required double tutar,
    required int cariId,
    required String fisAciklama,
    required String tarih,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeTahsilKasa}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'FATTUR': fatTur.toString(),
          'FISID': fisId.toString(),
          'SUBEID': subeId.toString(),
          'KASAID': kasaId.toString(),
          'TUTAR': tutar.toString(),
          'CARIID': cariId.toString(),
          'FISACIKLAMA': fisAciklama,
          'TARIH': tarih,
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded[0] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('getBelgeTahsilKasa error: $e');
    }
    return {'durum': 0, 'mesaj': 'Belge kasa tahsilat hatası.'};
  }

  // --- Swagger: /mobwaycloud/Get_BelgeTahsilBanka ---
  static Future<Map<String, dynamic>> getBelgeTahsilBanka({
    required int fatTur,
    required int fisId,
    required int subeId,
    required int bankaId,
    required double tutar,
    required int cariId,
    required String fisAciklama,
    required String tarih,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeTahsilBanka}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'FATTUR': fatTur.toString(),
          'FISID': fisId.toString(),
          'SUBEID': subeId.toString(),
          'BANKAID': bankaId.toString(),
          'TUTAR': tutar.toString(),
          'CARIID': cariId.toString(),
          'FISACIKLAMA': fisAciklama,
          'TARIH': tarih,
          'USERID': SaveSettings.userId.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded[0] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('getBelgeTahsilBanka error: $e');
    }
    return {'durum': 0, 'mesaj': 'Belge banka tahsilat hatası.'};
  }

  // --- Swagger: /mobwaycloud/Get_BelgeTahsilListe ---
  static Future<List<dynamic>> getBelgeTahsilListe({
    required int fatTur,
    required int fisId,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetBelgeTahsilListe}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'FATTUR': fatTur.toString(),
          'FISID': fisId.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('getBelgeTahsilListe error: $e');
    }
    return [];
  }

  // --- Swagger: /mobwaycloud/Get_DovizKur ---
  static Future<double> getDovizKur(int dovizId) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetDovizKur}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'DOVIZID': dovizId.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return (decoded[0]['KUR'] ?? 1.0).toDouble();
        }
      }
    } catch (e) {
      debugPrint('getDovizKur error: $e');
    }
    return 1.0;
  }

  // --- Swagger: /mobwaycloud/Get_YazarKasaKdv ---
  static Future<List<GetYazarKasaKdv>> getYazarKasaKdv() async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetYazarKasaKdv}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'SUPERUSERADI': SaveSettings.superUserPosta,
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => GetYazarKasaKdv.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('getYazarKasaKdv error: $e');
    }
    return [];
  }

  // --- Swagger: /mobwaycloud/Get_KullaniciRaporDetey ---
  static Future<List<GetKullaniciRaporDetay>> getKullaniciRaporDetay({
    required int id,
    required String tarih,
    required String islemKodu,
  }) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointGetKullaniciRaporDetay}').replace(
        queryParameters: {
          'TOKEN': SaveSettings.token,
          'VERSION': ApiConstants.fullVersion,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'ID': id.toString(),
          'TARIH': tarih,
          'ISLEMKODU': islemKodu,
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => GetKullaniciRaporDetay.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('getKullaniciRaporDetay error: $e');
    }
    return [];
  }

  // ============================================================
  // Depo & Kurye Login (Swagger: /login/depoKurye)
  // ============================================================

  static Future<Map<String, dynamic>> depoKuryeGiris({
    required String email,
    required String password,
  }) async {
    final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointLoginDepoKurye}';
    final requestBody = {
      'eposta': email,
      'sifre': password,
      'versiyon': ApiConstants.fullVersion,
      'projeId': ApiConstants.uygulamaId,
    };
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list = (decoded is List) ? decoded : [decoded];
        if (list.isNotEmpty) {
          final firstItem = list.first as Map<String, dynamic>;
          final durum = parseInt(firstItem['DURUM'] ?? firstItem['durum']);
          return {
            'success': durum == Numarator.basarili,
            'durum': durum,
            'data': firstItem,
            'message': firstItem['MESAJ'] ?? (durum == Numarator.basarili ? 'Giriş başarılı' : 'Giriş başarısız'),
          };
        }
      }
      return {'success': false, 'message': 'Sunucu hatası: HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası: $e'};
    }
  }

  // ============================================================
  // Mobil Sipariş Servisleri (Swagger: /mobilSiparis/*)
  // ============================================================

  static Future<Map<String, dynamic>> mobilSiparisVersiyonKontrol() async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointMobilSiparisVersiyonKontrol}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'versiyon': ApiConstants.fullVersion}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('mobilSiparisVersiyonKontrol error: $e');
    }
    return {'durum': 0, 'mesaj': 'Versiyon kontrolü başarısız.'};
  }

  static Future<List<dynamic>> mobilSiparisAnaMenu(Map<String, dynamic> body) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointMobilSiparisAnaMenu}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return (decoded is List) ? decoded : [decoded];
      }
    } catch (e) {
      debugPrint('mobilSiparisAnaMenu error: $e');
    }
    return [];
  }

  static Future<List<MobilSiparisModel>> mobilSiparisListe(Map<String, dynamic> body) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointMobilSiparisSiparisListe}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => MobilSiparisModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('mobilSiparisListe error: $e');
    }
    return [];
  }

  static Future<List<MobilSiparisDetay>> mobilSiparisDetay(Map<String, dynamic> body) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointMobilSiparisSiparisDetay}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => MobilSiparisDetay.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('mobilSiparisDetay error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> mobilSiparisEkle(Map<String, dynamic> body) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointMobilSiparisSiparisEkle}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('mobilSiparisEkle error: $e');
    }
    return {'durum': 0, 'mesaj': 'Sipariş eklenemedi.'};
  }

  static Future<Map<String, dynamic>> mobilSiparisIptal(Map<String, dynamic> body) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointMobilSiparisSiparisIptal}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('mobilSiparisIptal error: $e');
    }
    return {'durum': 0, 'mesaj': 'Sipariş iptal edilemedi.'};
  }

  static Future<List<dynamic>> mobilSiparisAramaYap(Map<String, dynamic> body) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointMobilSiparisAramaYap}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return (decoded is List) ? decoded : [decoded];
      }
    } catch (e) {
      debugPrint('mobilSiparisAramaYap error: $e');
    }
    return [];
  }

  static Future<List<MobilSubeBilgi>> mobilSiparisSubeGetir(Map<String, dynamic> body) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointMobilSiparisSubeGetir}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => MobilSubeBilgi.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('mobilSiparisSubeGetir error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> mobilSiparisGsmKodGonder(Map<String, dynamic> body) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointMobilSiparisGsmKodGonder}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('mobilSiparisGsmKodGonder error: $e');
    }
    return {'durum': 0, 'mesaj': 'SMS kodu gönderilemedi.'};
  }

  // ============================================================
  // Rapor Tasarım Servisleri (Swagger: /RaporTasarim/*)
  // ============================================================

  static Future<List<RaporTasarimModel>> raporTasarimGetirSube(int subeId) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointRaporTasarimSube}').replace(
        queryParameters: {'subeId': subeId.toString()},
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => RaporTasarimModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('raporTasarimGetirSube error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> raporTasarimEkle(Map<String, dynamic> tasarim) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointRaporTasarimEkle}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(tasarim),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('raporTasarimEkle error: $e');
    }
    return {'durum': 0, 'mesaj': 'Tasarım kaydedilemedi.'};
  }

  static Future<Map<String, dynamic>> raporTasarimGuncelle(Map<String, dynamic> tasarim) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointRaporTasarimGuncelle}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(tasarim),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('raporTasarimGuncelle error: $e');
    }
    return {'durum': 0, 'mesaj': 'Tasarım güncellenemedi.'};
  }

  static Future<Map<String, dynamic>> raporTasarimSil(int id) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointRaporTasarimSil}').replace(
        queryParameters: {'id': id.toString()},
      );
      final response = await http.delete(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('raporTasarimSil error: $e');
    }
    return {'durum': 0, 'mesaj': 'Tasarım silinemedi.'};
  }

  // ============================================================
  // Stok & Borç Raporları (Swagger: /stokRapor/*)
  // ============================================================

  static Future<List<StokBorcYRapor>> stokBorcYRapor(Map<String, dynamic> filtre) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointStokRaporBorcY}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(filtre),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => StokBorcYRapor.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('stokBorcYRapor error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> stokRaporTalep(Map<String, dynamic> talep) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointStokRaporTalep}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(talep),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('stokRaporTalep error: $e');
    }
    return {'durum': 0, 'mesaj': 'Rapor talebi oluşturulamadı.'};
  }

  static Future<Map<String, dynamic>> stokRaporSorgula(String raporId) async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointStokRaporSorgula}').replace(
        queryParameters: {'raporId': raporId},
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('stokRaporSorgula error: $e');
    }
    return {'durum': 0, 'mesaj': 'Rapor durumu sorgulanamadı.'};
  }

  // ============================================================
  // AlternatifPay Ödeme Entegrasyonu (Swagger: /apay/*)
  // ============================================================

  static Future<ApayOdemeResponse> apayOdemeTalep(Map<String, dynamic> odemeBilgi) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointApayOdemeTalep}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(odemeBilgi),
      );
      if (response.statusCode == 200) {
        return ApayOdemeResponse.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('apayOdemeTalep error: $e');
    }
    return ApayOdemeResponse(basarili: false, mesaj: 'Ödeme talebi başarısız.', odemeKodu: '', link: '', tutar: 0);
  }

  static Future<Map<String, dynamic>> apayOdemeKontrol(String odemeKodu) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointApayOdemeKontrol}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'odemeKodu': odemeKodu}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('apayOdemeKontrol error: $e');
    }
    return {'durum': 0, 'mesaj': 'Ödeme kontrol edilemedi.'};
  }

  static Future<Map<String, dynamic>> apayOdemeTamamla(Map<String, dynamic> odemeData) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointApayOdemeTamamla}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(odemeData),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('apayOdemeTamamla error: $e');
    }
    return {'durum': 0, 'mesaj': 'Ödeme tamamlama hatası.'};
  }

  // ============================================================
  // Pavo POS & PavoCloud (Swagger: /Pavo/* & /PavoCloud/*)
  // ============================================================

  static Future<PavoSaleResponse> pavoCurrentSale(Map<String, dynamic> saleData) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointPavoCurrentSale}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(saleData),
      );
      if (response.statusCode == 200) {
        return PavoSaleResponse.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('pavoCurrentSale error: $e');
    }
    return PavoSaleResponse(basarili: false, referansNo: '', mesaj: 'POS satışı başarısız.', tutar: 0, kartSonDort: '', authCode: '');
  }

  static Future<Map<String, dynamic>> pavoPairing(Map<String, dynamic> pairData) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointPavoPairing}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(pairData),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('pavoPairing error: $e');
    }
    return {'success': false, 'message': 'POS eşleştirme başarısız.'};
  }

  static Future<Map<String, dynamic>> pavoCloudCreatePaymentLink(Map<String, dynamic> linkData) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointPavoCloudCreatePaymentLink}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(linkData),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('pavoCloudCreatePaymentLink error: $e');
    }
    return {'success': false, 'message': 'Ödeme linki oluşturulamadı.'};
  }

  // ============================================================
  // Push Notifications, WSQL & Oduyo Ek Servisler
  // ============================================================

  static Future<Map<String, dynamic>> pushNotificationSend({
    required String title,
    required String body,
    required String targetId,
  }) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointPushNotificationSend}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title, 'body': body, 'targetId': targetId}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('pushNotificationSend error: $e');
    }
    return {'success': false, 'message': 'Bildirim gönderilemedi.'};
  }

  static Future<List<dynamic>> oduyoCariListele() async {
    try {
      final uri = Uri.parse('${SaveSettings.sunucu}${ApiConstants.endpointOduyoCariListele}');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('oduyoCariListele error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> wsqlSorgu(String sql) async {
    try {
      final endpoint = '${SaveSettings.sunucu}${ApiConstants.endpointWsql}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'TOKEN': SaveSettings.token,
          'SUPERUSERADI': SaveSettings.superUserPosta,
          'SQL': sql,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('wsqlSorgu error: $e');
    }
    return {'durum': 0, 'mesaj': 'SQL sorgusu çalıştırılamadı.'};
  }

  static Future<String> getEconnectPdf(int belgeId) async {
    try {
      final endpoint = '${SaveSettings.sunucu}/econnect/fatura/pdf';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'TOKEN': SaveSettings.token, 'BELGEID': belgeId}),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['url'] ?? decoded['URL'] ?? decoded['pdfUrl'] ?? '';
      }
    } catch (e) {
      debugPrint('getEconnectPdf error: $e');
    }
    return '';
  }

  static Future<bool> postEconnectGonder(int belgeId) async {
    try {
      final endpoint = '${SaveSettings.sunucu}/econnect/fatura/gonder';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'TOKEN': SaveSettings.token, 'BELGEID': belgeId}),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['durum'] == 1 || decoded['success'] == true;
      }
    } catch (e) {
      debugPrint('postEconnectGonder error: $e');
    }
    return false;
  }

  static Future<List<Map<String, dynamic>>> getTrendyolSiparisler() async {
    try {
      final endpoint = '${SaveSettings.sunucu}/TrendyolSiparis/SiparisGetir';
      final response = await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded.map((e) => Map<String, dynamic>.from(e)));
        }
      }
    } catch (e) {
      debugPrint('getTrendyolSiparisler error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> postPavoCurrentSale({
    required double tutar,
    required int cariId,
    required String aciklama,
  }) async {
    try {
      final endpoint = '${SaveSettings.sunucu}/Pavo/CurrentSale';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'TOKEN': SaveSettings.token,
          'TUTAR': tutar,
          'CARIID': cariId,
          'ACIKLAMA': aciklama,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('postPavoCurrentSale error: $e');
    }
    return {'success': false, 'message': 'POS işlemi başlatılamadı.'};
  }

  static Future<Map<String, dynamic>> postPavoCloudCreatePaymentLink({
    required double tutar,
    required String telefon,
    required String aciklama,
  }) async {
    try {
      final endpoint = '${SaveSettings.sunucu}/PavoCloud/CreatePaymentLink';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'TOKEN': SaveSettings.token,
          'TUTAR': tutar,
          'TELEFON': telefon,
          'ACIKLAMA': aciklama,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('postPavoCloudCreatePaymentLink error: $e');
    }
    return {'success': false, 'message': 'Ödeme linki oluşturulamadı.'};
  }

  static Future<Map<String, dynamic>> postAlternatifPayOdeme({
    required double tutar,
    required int cariId,
    required String aciklama,
  }) async {
    try {
      final endpoint = '${SaveSettings.sunucu}/apay/iptal/odemebilgisi';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'TOKEN': SaveSettings.token,
          'TUTAR': tutar,
          'CARIID': cariId,
          'ACIKLAMA': aciklama,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('postAlternatifPayOdeme error: $e');
    }
    return {'success': false, 'message': 'AlternatifPay ödeme işlemi başlatılamadı.'};
  }
}





