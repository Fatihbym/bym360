int parseInt(dynamic val, [int defaultValue = 0]) {
  if (val == null) return defaultValue;
  if (val is int) return val;
  if (val is double) return val.toInt();
  if (val is String) {
    return int.tryParse(val.trim()) ?? defaultValue;
  }
  return defaultValue;
}

double parseDouble(dynamic val, [double defaultValue = 0.0]) {
  if (val == null) return defaultValue;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  if (val is String) {
    return double.tryParse(val.trim()) ?? defaultValue;
  }
  return defaultValue;
}

int parseBelgeTurId(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  if (val is double) return val.toInt();
  final String str = val.toString().trim();
  final int? parsed = int.tryParse(str);
  if (parsed != null && parsed > 0) return parsed;

  final cleanStr = str.toUpperCase()
      .replaceAll('İ', 'I')
      .replaceAll('Ş', 'S')
      .replaceAll('Ğ', 'G')
      .replaceAll('Ü', 'U')
      .replaceAll('Ö', 'O')
      .replaceAll('Ç', 'C')
      .replaceAll('_', ' ')
      .trim();

  switch (cleanStr) {
    case 'SAYIM':
    case 'SAYIM BELGELERI':
    case '4':
      return 4;
    case 'TRANSFER':
    case 'DEPO SEVK':
    case 'DEPOSEVK':
    case 'DEPO SEVK BELGELERI':
    case '49':
      return 49;
    case 'SEVK ISTEK':
    case 'DEPO ISTEK':
    case 'DEPOISTEK':
    case 'DEPO SEVK ISTEK BELGELERI':
    case '89':
      return 89;
    case 'SEVK IADE ISTEK':
    case 'DEPO ISTEK IADE BELGELERI':
      return 89;
    case 'MALKABUL':
    case 'KABULISLEM':
    case 'KABUL':
    case 'KABUL ISLEMLERI':
    case 'ALIM IRSALIYESI':
    case '43':
      return 43;
    case 'SATIS':
    case 'SATISISLEM':
    case 'SATIS ISLEMLERI':
    case 'SATIS IRSALIYESI':
    case '41':
      return 41;
    case 'ALIS IADE':
    case 'KABULIADEISLEM':
    case 'KABUL IADE ISLEMLERI':
    case 'ALIS IADESI':
    case '46':
      return 46;
    case 'SATIS IADE':
    case 'SATISIADEISLEM':
    case 'SATIS IADE ISLEMLERI':
    case 'SATIS IADESI':
    case '42':
      return 42;
    case 'ALINAN SIPARIS':
    case 'ALINANSIPARIS':
    case 'ALINAN SIPARIS BELGELERI':
    case 'SIPARIS':
    case '33':
      return 33;
    case 'VERILEN SIPARIS':
    case 'VERILENSIPARIS':
    case 'VERILEN SIPARIS BELGELERI':
    case '34':
      return 34;
    case 'SP SEVK':
    case 'SIPARISSEVKIYAT':
    case 'SIPARIS SEVK':
    case 'SIPARIS SEVKIYAT':
    case 'SIPARIS SEVKIYAT BELGELERI':
      return 41;
    case 'SP TESLIM':
    case 'SIPARISTESLIMAL':
    case 'SIPARIS TESLIM':
    case 'SIPARIS TESLIM ALMA':
    case 'SIPARIS TESLIM ALMA BELGELERI':
      return 43;
    default:
      return 0;
  }
}

