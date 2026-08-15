import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/storage/save_settings.dart';
import '../core/theme/app_theme.dart';
import '../services/printer_service.dart';
import 'dynamic_island_toast.dart';

/// Yazıcı veya POS cihazına uzun basıldığında açılan detay kartı modalı
class PrinterDetailModal extends StatefulWidget {
  final DiscoveredPrinter printer;
  final VoidCallback? onPrinterSelected;

  const PrinterDetailModal({
    super.key,
    required this.printer,
    this.onPrinterSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required DiscoveredPrinter printer,
    VoidCallback? onPrinterSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PrinterDetailModal(
        printer: printer,
        onPrinterSelected: onPrinterSelected,
      ),
    );
  }

  @override
  State<PrinterDetailModal> createState() => _PrinterDetailModalState();
}

class _PrinterDetailModalState extends State<PrinterDetailModal> {
  bool _isTesting = false;

  Future<void> _testThisPrinter() async {
    setState(() => _isTesting = true);
    final p = widget.printer;

    try {
      final isOffice = p.name.toLowerCase().contains('hp') ||
          p.name.toLowerCase().contains('smart tank') ||
          p.name.toLowerCase().contains('laserjet') ||
          p.name.toLowerCase().contains('deskjet') ||
          p.name.toLowerCase().contains('officejet') ||
          p.name.toLowerCase().contains('canon') ||
          p.name.toLowerCase().contains('brother') ||
          SaveSettings.yaziciKagizGenislik == 'A4' ||
          SaveSettings.yaziciKagizGenislik == 'A5';

      if (p.type == PrinterConnectionType.network && p.ip != null && p.ip!.isNotEmpty && !isOffice) {
        final result = await PrinterService.testNetworkPrinter(
          ip: p.ip!,
          port: p.port,
          paperWidth: SaveSettings.yaziciKagizGenislik,
        );
        if (mounted) {
          if (result.success) {
            AppNotification.showSuccess(context, 'Sınama baskısı başarıyla gönderildi.', title: 'Test Baskısı');
          } else {
            AppNotification.showError(context, result.message, title: 'Baskı Hatası');
          }
        }
      } else {
        final result = await PrinterService.testBluetoothOrSystemPrinter(
          printerName: p.name,
          printerUrl: p.url,
          paperWidth: SaveSettings.yaziciKagizGenislik,
        );
        if (mounted) {
          if (result.success) {
            AppNotification.showSuccess(context, 'Sınama baskısı yazıcıya iletildi.', title: 'Test Baskısı');
          } else {
            AppNotification.showError(context, result.message, title: 'Baskı Hatası');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, '$e', title: 'Hata');
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _setAsDefault() async {
    final p = widget.printer;
    if (p.type == PrinterConnectionType.network) {
      await SaveSettings.savePrinterSettings(
        tip: 'Ağ / IP Yazıcı',
        ad: p.name.isNotEmpty ? p.name : 'Termal Ağ Yazıcısı',
        ip: p.ip ?? '',
        port: p.port,
        kagiz: SaveSettings.yaziciKagizGenislik,
      );
    } else {
      await SaveSettings.savePrinterSettings(
        tip: 'Bluetooth / Sistem Yazıcısı',
        ad: p.name,
        ip: SaveSettings.seciliYaziciIp,
        port: SaveSettings.seciliYaziciPort,
        url: p.url ?? '',
        kagiz: SaveSettings.yaziciKagizGenislik,
      );
    }

    if (mounted) {
      AppNotification.showSuccess(context, '${p.name} varsayılan yazıcı yapıldı.', title: 'Yazıcı Kaydedildi');
      widget.onPrinterSelected?.call();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.printer;
    final isNetwork = p.type == PrinterConnectionType.network;
    final isBluetooth = p.type == PrinterConnectionType.bluetooth;

    final isCurrentDefault = (isNetwork && p.ip == SaveSettings.seciliYaziciIp) ||
        (!isNetwork && p.name == SaveSettings.seciliYaziciAdi);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Başlık ve Cihaz Kartı
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isNetwork
                      ? const Color(0xFF007AFF)
                      : (isBluetooth ? const Color(0xFF5856D6) : const Color(0xFFFF9500)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isNetwork
                      ? Icons.wifi_rounded
                      : (isBluetooth ? Icons.bluetooth_rounded : Icons.print_rounded),
                  color: Colors.white,
                  size: 28,
                ),
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
                            p.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (isCurrentDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  'Varsayılan',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isNetwork
                          ? 'Ağ / WiFi Termal & Fiş Yazıcısı'
                          : (isBluetooth ? 'Bluetooth Mobil POS / Fiş Yazıcısı' : 'Sistem Yazıcısı'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Donanım & Bağlantı Detay Tablosu
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
              ),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  context,
                  icon: Icons.hub_rounded,
                  label: 'Bağlantı Türü',
                  value: isNetwork ? 'Yerel Ağ / TCP-IP (Socket)' : (isBluetooth ? 'Bluetooth SPP / BLE' : 'Android Print Service'),
                  isDark: isDark,
                ),
                const Divider(height: 16),
                if (isNetwork && p.ip != null && p.ip!.isNotEmpty) ...[
                  _buildDetailRow(
                    context,
                    icon: Icons.wifi_tethering_rounded,
                    label: 'IP Adresi & Port',
                    value: 'IP: ${p.ip}  •  Port: ${p.port}',
                    isDark: isDark,
                    canCopy: true,
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    context,
                    icon: Icons.terminal_rounded,
                    label: 'Protokol / Komut Seti',
                    value: 'ESC/POS (Port ${p.port}) / RAW',
                    isDark: isDark,
                  ),
                  const Divider(height: 16),
                ],
                if (!isNetwork && p.url != null && p.url!.isNotEmpty) ...[
                  _buildDetailRow(
                    context,
                    icon: Icons.link_rounded,
                    label: 'Donanım Adresi (URL)',
                    value: p.url!,
                    isDark: isDark,
                    canCopy: true,
                  ),
                  const Divider(height: 16),
                ],
                _buildDetailRow(
                  context,
                  icon: Icons.receipt_long_rounded,
                  label: 'Uyumlu Kağıt Boyutları',
                  value: '80mm POS • 58mm Termal • A4/A5',
                  isDark: isDark,
                ),
                const Divider(height: 16),
                _buildDetailRow(
                  context,
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Cihaz Durumu',
                  value: p.isConnected ? 'Bağlantı Aktif (Hazır)' : 'Erişilebilir / Eşleşmiş',
                  valueColor: AppTheme.accentGreen,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Aksiyon Butonları
          Row(
            children: [
              // Test Baskısı Butonu
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTesting ? null : _testThisPrinter,
                  icon: _isTesting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.print_rounded, size: 18),
                  label: Text(
                    _isTesting ? 'Yazdırılıyor...' : 'Sınama Baskısı',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: AppTheme.primaryBlue,
                    side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Varsayılan Yap / Seç Butonu
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isCurrentDefault ? null : _setAsDefault,
                  icon: Icon(isCurrentDefault ? Icons.check_rounded : Icons.star_rounded, size: 18),
                  label: Text(
                    isCurrentDefault ? 'Seçili Yazıcı' : 'Varsayılan Yap',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: isCurrentDefault ? Colors.grey : AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required bool isDark,
    bool canCopy = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
        ),
        const Spacer(),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? (isDark ? Colors.white70 : Colors.black87),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canCopy) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    AppNotification.showSuccess(context, '$value panoya kopyalandı.', title: 'Kopyalandı');
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Icon(Icons.copy_rounded, size: 13, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
