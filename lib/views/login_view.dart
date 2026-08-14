import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/storage/save_settings.dart';
import '../core/utils/app_logger.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/dynamic_island_toast.dart';
import 'ayarlar/ayarlar_views.dart';
import 'anamenu_view.dart';
import 'db_listele_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firmaController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  List<Firma> _firmalar = [];
  Firma? _selectedFirma;

  @override
  void initState() {
    super.initState();
    _emailController.text = SaveSettings.superUserPosta;
    _passwordController.text = SaveSettings.superUserSifre;
    _firmaController.text = SaveSettings.firma;
    _loadFirmalar();
  }

  Future<void> _loadFirmalar() async {
    final list = await ApiService.getFirmaListele();
    if (mounted && list.isNotEmpty) {
      setState(() {
        _firmalar = list;
        _selectedFirma = list.first;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firmaController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    // 0. Log Initial State
    AppLogger.loginStart(
      email: email,
      server: SaveSettings.sunucu,
      passwordLength: password.length,
      rememberMe: _rememberMe,
    );

    if (_rememberMe) {
      await SaveSettings.saveLoginCredentials(email, password, SaveSettings.sunucu);
    }

    try {
      // Step 1: Kullanıcı Doğrulama
      AppLogger.apiStep(1, 3, 'Kullanıcı Doğrulama Başlatılıyor',
          url: '${SaveSettings.sunucu}${ApiConstants.endpointGirisYap}',
          params: {'eposta': email, 'projeId': ApiConstants.uygulamaId, 'versiyon': ApiConstants.fullVersion});

      final result = await ApiService.girisYap(email, password);

      if (!mounted) return;

      if (result['success'] == true) {
        final PostSuperUser user = result['user'];

        if (user.db.isEmpty) {
          setState(() => _isLoading = false);
          final msg = context.tr('Kullanıcıya ait firma bulunamadı.', 'Kullanıcıya ait firma bulunamadı.');
          AppLogger.loginFailed(msg);
          _showSnackBar(msg, isError: true);
          return;
        }

        if (user.db.length == 1 && user.db.first.firma.length <= 1) {
          final db = user.db.first;
          final firma = db.firma.isNotEmpty ? db.firma.first : Firma(aId: 1, aAdi: db.aDbAdi);

          // Step 2: Token Üretimi
          AppLogger.apiStep(2, 3, 'Token Üretimi Başlatılıyor',
              url: '${SaveSettings.sunucu}${ApiConstants.endpointTokenUret}',
              params: {'eposta': email, 'dbId': db.aId, 'firmaId': firma.aId, 'dbKulId': db.aKulId});

          final tokenResult = await ApiService.tokenUret(
            email: email,
            password: password,
            dbId: db.aId,
            firmaId: firma.aId,
            dbKulId: db.aKulId,
            apiUrl: db.apiUrl,
          );

          if (!mounted) return;

          if (tokenResult['success'] == true) {
            final token = tokenResult['token'] as String;

            // Step 3: Oturum ve Parametreleri Getir
            AppLogger.apiStep(3, 3, 'Oturum ve Kullanıcı Parametreleri Alınıyor',
                url: '${SaveSettings.sunucu}${ApiConstants.endpointGetGiris}',
                params: {'token': '${token.substring(0, token.length > 20 ? 20 : token.length)}...', 'email': email, 'dbKulId': db.aKulId});

            final girisResult = await ApiService.getGiris(
              token: token,
              email: email,
              dbKulId: db.aKulId,
            );

            if (!mounted) return;
            setState(() => _isLoading = false);

            if (girisResult['success'] == true) {
              await SaveSettings.saveUserSession(
                userToken: token,
                uId: SaveSettings.userId,
                sId: SaveSettings.subeId,
                dId: SaveSettings.depoId,
                uName: SaveSettings.kullaniciAdi.isNotEmpty ? SaveSettings.kullaniciAdi : email,
              );

              AppLogger.loginSuccess(
                username: SaveSettings.kullaniciAdi.isNotEmpty ? SaveSettings.kullaniciAdi : email,
                dbName: db.aDbAdi,
                companyName: firma.unvan,
                token: token,
              );

              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AnamenuView()),
                (route) => false,
              );
              return;
            } else {
              final errMsg = girisResult['message'] ?? context.tr('Giriş başarısız!', 'Giriş başarısız!');
              AppLogger.loginFailed(errMsg);
              _showSnackBar(errMsg, isError: true);
              return;
            }
          } else {
            setState(() => _isLoading = false);
            final errMsg = tokenResult['message'] ?? context.tr('Token üretilemedi!', 'Token üretilemedi!');
            AppLogger.loginFailed(errMsg);
            _showSnackBar(errMsg, isError: true);
            return;
          }
        } else {
          // Birden fazla DB veya firma var, DbListeleView ekranına yönlendir
          setState(() => _isLoading = false);
          AppLogger.log('LOGIN_NAV', 'Kullanıcı veritabanı seçim ekranına yönlendiriliyor (Db Sayısı: ${user.db.length})', level: LogLevel.info);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DbListeleView(
                superUser: user,
                email: email,
                password: password,
              ),
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        final errMsg = result['message'] ?? context.tr('Giriş başarısız!', 'Giriş başarısız!');
        AppLogger.loginFailed(errMsg);
        _showSnackBar(errMsg, isError: true);
      }
    } catch (e, stack) {
      setState(() => _isLoading = false);
      AppLogger.loginFailed('Beklenmedik bir hata oluştu: $e', error: stack);
      _showSnackBar('Giriş hatası: $e', isError: true);
    }
  }


  void _showSnackBar(String message, {required bool isError}) {
    if (isError) {
      AppNotification.showError(context, message, title: 'Giriş Başarısız');
    } else {
      AppNotification.showSuccess(context, message, title: 'Giriş Başarılı');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language_rounded, color: AppTheme.primaryBlue),
            tooltip: context.tr('dilayarlari', 'Dil Seçimi'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DilAyarlariView()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 12.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Image.asset(
                          'assets/images/bym360logo.png',
                          width: 340,
                          height: 220,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: const Icon(
                              Icons.cloud_rounded,
                              size: 72,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('Kurumsal ERP & Depo Yönetimi', 'Kurumsal ERP & Depo Yönetimi'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),

                    const SizedBox(height: 28),

                    if (_firmalar.isNotEmpty) ...[
                      DropdownButtonFormField<Firma>(
                        initialValue: _selectedFirma,
                        isExpanded: true,
                        items: _firmalar.map((f) => DropdownMenuItem(value: f, child: Text(f.unvan, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setState(() => _selectedFirma = val),
                        decoration: InputDecoration(
                          labelText: context.tr('Firma Seçin', 'Firma Seçin'),
                          prefixIcon: const Icon(Icons.business_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) => val == null || val.trim().isEmpty ? context.tr('Kullanıcı adı giriniz', 'Kullanıcı adı giriniz') : null,
                      decoration: InputDecoration(
                        labelText: context.tr('kullaniciadi', 'Kullanıcı Adı / E-Posta'),
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: (val) => val == null || val.trim().isEmpty ? context.tr('Şifre giriniz', 'Şifre giriniz') : null,
                      decoration: InputDecoration(
                        labelText: context.tr('sifre', 'Şifre'),
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: AppTheme.primaryBlue,
                            onChanged: (val) => setState(() => _rememberMe = val ?? true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('benihatirla', 'Beni Hatırla'),
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                context.tr('girisyap', 'Giriş Yap'),
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'v${ApiConstants.appVersion}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
