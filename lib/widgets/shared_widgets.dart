import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import 'baski_onizleme_dialog.dart';

// ============================================================
// Loading Dialog Widget (Fragment_Loading)
// ============================================================
class LoadingDialog extends StatelessWidget {
  final String message;

  const LoadingDialog({super.key, this.message = 'Yükleniyor...'});

  static void show(BuildContext context, {String message = 'Yükleniyor...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(message: message),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Error/Connection Lost Dialog (Fragment_Hatali / Fragment_BaglantiKoptu)
// ============================================================
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    this.title = 'Hata Oluştu',
    required this.message,
    this.onRetry,
  });

  static void show(BuildContext context, {
    String title = 'Hata Oluştu',
    required String message,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(title: title, message: message, onRetry: onRetry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.accentRed),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tamam'),
        ),
        if (onRetry != null)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry!();
            },
            child: const Text('Tekrar Dene'),
          ),
      ],
    );
  }
}

// ============================================================
// WebService (WS) Progress Dialog (Fragment_WSDialog)
// ============================================================
class WSProgressDialog extends StatelessWidget {
  final String title;

  const WSProgressDialog({super.key, this.title = 'Sunucuya Bağlanılıyor...'});

  static void show(BuildContext context, {String title = 'Sunucuya Bağlanılıyor...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WSProgressDialog(title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Flexible(child: Text(title)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Bluetooth & Ağ Yazıcı Seçim Dialogu (RealPrinterPickerDialog)
// ============================================================
class BluetoothYaziciDialog extends StatelessWidget {
  const BluetoothYaziciDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const RealPrinterPickerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const RealPrinterPickerDialog();
  }
}

// ============================================================
// Ürün Bilgi Alt Panel (Fragment_Urun_Bilgi)
// ============================================================
class UrunBilgiPanel extends StatelessWidget {
  final String stokAdi;
  final String stokKodu;
  final String barkod;
  final double fiyat;
  final String birim;

  const UrunBilgiPanel({
    super.key,
    required this.stokAdi,
    required this.stokKodu,
    required this.barkod,
    required this.fiyat,
    required this.birim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stokAdi, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _row('Stok Kodu', stokKodu),
          _row('Barkod', barkod),
          _row('Birim Fiyat', '₺${fiyat.toStringAsFixed(2)}'),
          _row('Birim', birim),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ============================================================
// Belge Bilgi Alt Panel (Fragment_Belge_Bilgi)
// ============================================================
class BelgeBilgiPanel extends StatelessWidget {
  final String belgeNo;
  final String cariAdi;
  final String tarih;
  final String belgeTuru;
  final double toplam;

  const BelgeBilgiPanel({
    super.key,
    required this.belgeNo,
    required this.cariAdi,
    required this.tarih,
    required this.belgeTuru,
    required this.toplam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Belge: $belgeNo', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _row('Cari', cariAdi),
          _row('Tarih', tarih),
          _row('Tür', belgeTuru),
          _row('Genel Toplam', '₺${toplam.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500), textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

// ============================================================
// Hakkında Dialogu (Fragment_Hakkinda)
// ============================================================
class HakkindaDialog extends StatelessWidget {
  const HakkindaDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (_) => const HakkindaDialog());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('BYM 360 Hakkında'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BYM 360 - Mobil ERP & Depo Yönetim Sistemi'),
          SizedBox(height: 8),
          Text('Versiyon: ${ApiConstants.appVersion} (Build ${ApiConstants.appVersionCode})'),
          Text('Paket: com.bym360'),
          SizedBox(height: 12),
          Text('© BYM Yazılım', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Tüm hakları saklıdır.'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
      ],
    );
  }
}

// ============================================================
// Versiyon Güncelleme Dialogu (Fragment_Versiyon / Fragment_Update)
// ============================================================
class VersiyonGuncelleDialog extends StatelessWidget {
  const VersiyonGuncelleDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (_) => const VersiyonGuncelleDialog());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.system_update_rounded, color: AppTheme.primaryBlue),
          SizedBox(width: 8),
          Text('Güncelleme Kontrolü'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Uygulamanız güncel.'),
          SizedBox(height: 8),
          Text('Mevcut Sürüm: v${ApiConstants.appVersion}', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam')),
      ],
    );
  }
}
