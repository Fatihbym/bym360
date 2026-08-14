import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import 'baski_onizleme_dialog.dart';

class AppDialogs {
  // Hakkında / Versiyon Bilgisi Dialog (Fragment_Hakkinda & Fragment_Versiyon)
  static void showHakkindaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryBlue),
            ),
            const SizedBox(width: 10),
            Text(
              'BYM 360 Hakkında',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BYM 360',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'Versiyon: ${ApiConstants.appVersion} (Build ${ApiConstants.appVersionCode})',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            SizedBox(height: 12),
            Divider(),
            Text(
              '© 2026 BYM Yazılım Teknolojileri',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  // Yazıcı Seçim Dialog (Fragment_YaziciListe & Fragment_yazici_turu)
  static void showYaziciSecimDialog({
    required BuildContext context,
    required List<GetYaziciListele> yazicilar,
    required Function(GetYaziciListele) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.print_rounded, color: AppTheme.primaryBlue),
                    SizedBox(width: 8),
                    Text('Yazıcı Seçin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('Donanım / Bluetooth', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => const RealPrinterPickerDialog(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            yazicilar.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Column(
                        children: [
                          Text('Sunucuda kayıtlı yazıcı şablonu bulunamadı.', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                            icon: const Icon(Icons.bluetooth_searching_rounded, size: 18),
                            label: const Text('Cihazdaki Bluetooth/Ağ Yazıcısını Seç'),
                            onPressed: () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (_) => const RealPrinterPickerDialog(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: yazicilar.length,
                      itemBuilder: (context, index) {
                        final y = yazicilar[index];
                        return ListTile(
                          leading: const Icon(Icons.print_outlined),
                          title: Text(y.adi, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('ID: ${y.id}  |  Tip: ${y.tur}'),
                          onTap: () {
                            Navigator.pop(context);
                            onSelected(y);
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // Matbu Tasarım Seçim Dialog (Fragment_MatbuList)
  static void showMatbuTasarimDialog({
    required BuildContext context,
    required List<GetMatbuTasarim> tasarimlar,
    required Function(GetMatbuTasarim) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description_rounded, color: AppTheme.primaryBlue),
                SizedBox(width: 8),
                Text('Matbu Tasarım Seçin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 12),
            tasarimlar.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Tasarım bulunamadı.')),
                  )
                : Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: tasarimlar.length,
                      itemBuilder: (context, index) {
                        final t = tasarimlar[index];
                        return ListTile(
                          leading: const Icon(Icons.article_outlined),
                          title: Text(t.adi, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Tasarım ID: ${t.id}'),
                          onTap: () {
                            Navigator.pop(context);
                            onSelected(t);
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // Bluetooth ve Gerekli Uygulama İzinleri Açılır Kart Dialogu
  static Future<bool> checkAndRequestPermissions(BuildContext context, {bool forceShow = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final bool permissionsHandled = prefs.getBool('app_permissions_handled') ?? false;

    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;
    final btConnectStatus = await Permission.bluetoothConnect.status;
    final btScanStatus = await Permission.bluetoothScan.status;

    final bool isCameraOk = cameraStatus.isGranted || cameraStatus.isLimited;
    final bool isLocationOk = locationStatus.isGranted || locationStatus.isLimited;
    final bool isBtOk = btConnectStatus.isGranted || btScanStatus.isGranted;

    // Eğer zorunlu gösterim değilse ve izinler zaten işlem gördüyse veya ana izinler verilmişse dialog göstermiyoruz
    if (!forceShow) {
      if (permissionsHandled || (isCameraOk && (isLocationOk || isBtOk))) {
        return true;
      }
    }

    if (!context.mounted) return false;

    bool grantedAll = false;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        bool isRequesting = false;

        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 25,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Top Hero Banner Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        alignment: Alignment.bottomLeft,
                        children: [
                          Image.asset(
                            'assets/images/permissions_banner.jpg',
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 130,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                              ),
                              child: const Icon(Icons.security_rounded, size: 56, color: Colors.white),
                            ),
                          ),
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.85),
                                  Colors.transparent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'CİHAZ ERİŞİM SİSTEMİ',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title & Description
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cihaz İzinleri & Erişim',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Yazıcı bağlantısı, konum servisi ve barkod okuyucu için gereklidir.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          onPressed: () async {
                            await prefs.setBool('app_permissions_handled', true);
                            if (ctx.mounted) Navigator.pop(ctx, false);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 1),
                    const SizedBox(height: 16),

                    // Items
                    _buildPermissionItem(
                      icon: Icons.print_rounded,
                      color: AppTheme.primaryBlue,
                      title: 'Bluetooth & Yazıcı Bağlantısı',
                      subtitle: 'Termal etiket ve fiş yazıcılarına anında bağlanıp çıktı almak için zorunludur.',
                      isGranted: isBtOk,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionItem(
                      icon: Icons.location_on_rounded,
                      color: AppTheme.accentOrange,
                      title: 'Konum İzni (Cihaz Taraması)',
                      subtitle: 'Android altyapısında etraftaki bluetooth cihazlarını taramak için gereklidir.',
                      isGranted: isLocationOk,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionItem(
                      icon: Icons.camera_alt_rounded,
                      color: AppTheme.accentGreen,
                      title: 'Kamera İzni (Barkod Okuyucu)',
                      subtitle: 'Kamera ile hızlı ürün ve stok barkod taraması yapmak için kullanılır.',
                      isGranted: isCameraOk,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 24),

                    // Primary Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: isRequesting
                            ? null
                            : () async {
                                setStateModal(() => isRequesting = true);
                                await prefs.setBool('app_permissions_handled', true);

                                try {
                                  Map<Permission, PermissionStatus> statuses = await [
                                    Permission.camera,
                                    Permission.location,
                                    Permission.bluetoothConnect,
                                    Permission.bluetoothScan,
                                  ].request();

                                  bool cam = (statuses[Permission.camera]?.isGranted ?? false) ||
                                      (statuses[Permission.camera]?.isLimited ?? false);
                                  bool loc = (statuses[Permission.location]?.isGranted ?? false) ||
                                      (statuses[Permission.location]?.isLimited ?? false);
                                  bool bt = (statuses[Permission.bluetoothConnect]?.isGranted ?? false) ||
                                      (statuses[Permission.bluetoothScan]?.isGranted ?? false);

                                  grantedAll = cam || loc || bt;

                                  if (!cam && !loc) {
                                    await openAppSettings();
                                  }
                                } catch (_) {
                                  grantedAll = true;
                                }

                                if (ctx.mounted) {
                                  Navigator.pop(ctx, grantedAll);
                                }
                              },
                        child: isRequesting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.verified_user_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'İZİNLERİ ONAYLA VE İZİN VER',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        await prefs.setBool('app_permissions_handled', true);
                        if (ctx.mounted) Navigator.pop(ctx, false);
                      },
                      child: Text(
                        'Daha Sonra Anlat',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    return grantedAll;
  }

  static Widget _buildPermissionItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isGranted,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? AppTheme.accentGreen.withValues(alpha: 0.4)
              : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
          width: isGranted ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isGranted
                            ? AppTheme.accentGreen.withValues(alpha: 0.15)
                            : AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGranted ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                            size: 12,
                            color: isGranted ? AppTheme.accentGreen : AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isGranted ? 'Aktif' : 'Gerekli',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isGranted ? AppTheme.accentGreen : AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

