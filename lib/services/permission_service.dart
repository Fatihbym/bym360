import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/theme/app_theme.dart';

class PermissionService {
  /// Yazıcı ve Bluetooth cihaz bağlantısı için gerekli izinleri kontrol eder ve talep eder
  static Future<bool> requestPrinterAndBluetoothPermissions([BuildContext? context]) async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    final permissions = <Permission>[];

    if (Platform.isAndroid) {
      // Android 12+ (API 31+) Bluetooth İzinleri
      permissions.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
        Permission.nearbyWifiDevices,
      ]);
    } else if (Platform.isIOS) {
      permissions.addAll([
        Permission.bluetooth,
        Permission.locationWhenInUse,
      ]);
    }

    final statuses = await permissions.request();

    bool allGranted = true;
    for (final entry in statuses.entries) {
      if (entry.value.isPermanentlyDenied) {
        if (context != null && context.mounted) {
          _showPermissionSettingsDialog(
            context,
            title: 'Bluetooth ve Yazıcı İzni',
            message: 'Yazıcı ve POS cihazlarına bağlanabilmek için Bluetooth ve Konum izinlerini etkinleştiriniz.',
          );
        }
        allGranted = false;
        break;
      } else if (!entry.value.isGranted && entry.key == Permission.bluetoothConnect) {
        allGranted = false;
      }
    }

    return allGranted;
  }

  /// Barkod ve Karekod taraması için Kamera İznini talep eder
  static Future<bool> requestCameraPermission([BuildContext? context]) async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied && context != null && context.mounted) {
      _showPermissionSettingsDialog(
        context,
        title: 'Kamera İzni Gerekli',
        message: 'Barkod okutabilmek için kamera iznini etkinleştiriniz.',
      );
    }
    return status.isGranted;
  }

  /// Uygulama açılışında tüm temel izinleri (Kamera, Bluetooth, Bildirim, Galeri) topluca talep eder
  static Future<void> requestAllAppPermissions([BuildContext? context]) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final list = <Permission>[
      Permission.camera,
      Permission.notification,
    ];

    if (Platform.isAndroid) {
      list.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ]);
    } else if (Platform.isIOS) {
      list.addAll([
        Permission.bluetooth,
        Permission.photos,
      ]);
    }

    try {
      await list.request();
    } catch (e) {
      debugPrint('requestAllAppPermissions error: $e');
    }
  }

  static void _showPermissionSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: AppTheme.primaryBlue, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.settings_rounded, size: 18),
            label: const Text('Ayarları Aç'),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }
}
