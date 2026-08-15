import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class PermissionItemData {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Permission permission;
  PermissionStatus status;

  PermissionItemData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.permission,
    this.status = PermissionStatus.denied,
  });
}

/// iOS ve Android için Detaylı Cihaz İzinleri Yönetim ve Bilgilendirme Modalı
class DevicePermissionsModal extends StatefulWidget {
  const DevicePermissionsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DevicePermissionsModal(),
    );
  }

  @override
  State<DevicePermissionsModal> createState() => _DevicePermissionsModalState();
}

class _DevicePermissionsModalState extends State<DevicePermissionsModal> {
  bool _isLoading = true;
  List<PermissionItemData> _items = [];

  @override
  void initState() {
    super.initState();
    _loadPermissionsStatus();
  }

  Future<void> _loadPermissionsStatus() async {
    setState(() => _isLoading = true);

    final list = <PermissionItemData>[
      PermissionItemData(
        id: 'camera',
        title: 'Kamera Erişimi',
        description: 'Barkod, karekod ve ürün stok kodlarını kamerayla anlık okutabilmek için gereklidir.',
        icon: Icons.camera_alt_rounded,
        color: const Color(0xFF00C6FF),
        permission: Permission.camera,
      ),
      PermissionItemData(
        id: 'bluetooth',
        title: 'Bluetooth & Kablosuz Cihazlar',
        description: 'Mobil termal fiş yazıcıları, etiket yazıcıları ve POS cihazlarıyla veri aktarımı için kullanılır.',
        icon: Icons.bluetooth_rounded,
        color: const Color(0xFF7F00FF),
        permission: Platform.isIOS ? Permission.bluetooth : Permission.bluetoothConnect,
      ),
      PermissionItemData(
        id: 'notification',
        title: 'Anlık Bildirimler',
        description: 'Kritik stok seviyeleri, sipariş durumları ve sistem işlemlerine dair uyarılar almanızı sağlar.',
        icon: Icons.notifications_active_rounded,
        color: const Color(0xFFFF9900),
        permission: Permission.notification,
      ),
      PermissionItemData(
        id: 'photos',
        title: 'Galeri ve Dosya Erişimi',
        description: 'Oluşturulan fatura, irsaliye, makbuz ve etiket PDF belgelerini cihazınıza kaydedebilmek için gereklidir.',
        icon: Icons.photo_library_rounded,
        color: const Color(0xFF00E676),
        permission: Permission.photos,
      ),
    ];

    if (Platform.isAndroid) {
      list.add(
        PermissionItemData(
          id: 'location',
          title: 'Yakındaki Cihazlar & Konum',
          description: 'Android donanım kuralları gereği Bluetooth ve yerel WiFi yazıcılarını tarayabilmek için kullanılır.',
          icon: Icons.location_on_rounded,
          color: const Color(0xFFFF5252),
          permission: Permission.location,
        ),
      );
    }

    for (final item in list) {
      try {
        item.status = await item.permission.status;
      } catch (_) {
        item.status = PermissionStatus.denied;
      }
    }

    if (mounted) {
      setState(() {
        _items = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestSingle(PermissionItemData item) async {
    if (item.status.isPermanentlyDenied) {
      await openAppSettings();
      await _loadPermissionsStatus();
      return;
    }

    final newStatus = await item.permission.request();
    if (mounted) {
      setState(() {
        item.status = newStatus;
      });
    }
  }

  Future<void> _requestAllMissing() async {
    for (final item in _items) {
      if (!item.status.isGranted) {
        if (item.status.isPermanentlyDenied) {
          await openAppSettings();
          break;
        } else {
          final res = await item.permission.request();
          item.status = res;
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final grantedCount = _items.where((i) => i.status.isGranted).length;
    final totalCount = _items.length;
    final allGranted = totalCount > 0 && grantedCount == totalCount;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('cihaz_izinleri', 'Cihaz İzinleri'),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: allGranted
                        ? AppTheme.accentGreen.withValues(alpha: 0.15)
                        : AppTheme.primaryBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: allGranted
                          ? AppTheme.accentGreen.withValues(alpha: 0.3)
                          : AppTheme.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '$grantedCount / $totalCount Aktif',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: allGranted ? AppTheme.accentGreen : AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Content List
          Flexible(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isGranted = item.status.isGranted;
                      final isPermanentlyDenied = item.status.isPermanentlyDenied;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? (isGranted
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.white.withValues(alpha: 0.02))
                              : (isGranted ? Colors.grey.shade50 : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isGranted
                                ? (isDark ? AppTheme.accentGreen.withValues(alpha: 0.3) : AppTheme.accentGreen.withValues(alpha: 0.25))
                                : (isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                            width: isGranted ? 1.2 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon Box
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: item.color.withValues(alpha: 0.25)),
                              ),
                              child: Icon(item.icon, color: item.color, size: 22),
                            ),
                            const SizedBox(width: 14),

                            // Text Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Action Button / Badge
                            if (isGranted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Açık',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (isPermanentlyDenied)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade800,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () => _requestSingle(item),
                                child: Text('Ayarlar', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                              )
                            else
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () => _requestSingle(item),
                                child: Text('İzin Ver', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const Divider(height: 1),

          // Bottom Action Buttons
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                    label: Text(
                      'Sistem Ayarları',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () => openAppSettings(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allGranted ? AppTheme.accentGreen : AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: Icon(allGranted ? Icons.check_rounded : Icons.lock_open_rounded, size: 18),
                    label: Text(
                      allGranted ? 'Tamam' : 'Tümünü Etkinleştir',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      if (allGranted) {
                        Navigator.pop(context);
                      } else {
                        _requestAllMissing();
                      }
                    },
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
