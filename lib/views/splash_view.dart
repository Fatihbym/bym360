import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../core/theme/app_theme.dart';
import '../core/storage/save_settings.dart';
import '../services/permission_service.dart';
import 'login_view.dart';
import 'anamenu_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await SaveSettings.initSharedPreferences();
    
    // Uygulama açılışında gerekli izinleri (Bluetooth, Kamera, Konum, Bildirim) talep et
    await PermissionService.requestAllAppPermissions();
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (SaveSettings.token.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AnamenuView()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Image.asset(
                'assets/images/bym360logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.cloud_rounded,
                  size: 100,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 36),
            const SpinKitThreeBounce(
              color: AppTheme.primaryBlue,
              size: 26.0,
            ),
          ],
        ),
      ),
    );
  }
}
