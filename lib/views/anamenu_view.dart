import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../core/theme/app_theme.dart';
import '../core/storage/save_settings.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import 'depo_yonetimi_view.dart';
import 'urun_yonetimi_view.dart';
import 'siparis_yonetimi_view.dart';
import 'finans_yonetimi_view.dart';
import 'belge_listele_view.dart';
import 'bildirimler_view.dart';

import 'ayarlar/sistem_ayarlari_view.dart';
import 'login_view.dart';
import '../widgets/app_dialogs.dart';

class ModuleItem {
  final String titleKey;
  final String titleDefault;
  final String subtitleKey;
  final String subtitleDefault;
  final IconData icon;
  final Color color;
  final List<String> keywords;
  final Widget Function(BuildContext) targetBuilder;

  ModuleItem({
    required this.titleKey,
    required this.titleDefault,
    required this.subtitleKey,
    required this.subtitleDefault,
    required this.icon,
    required this.color,
    required this.keywords,
    required this.targetBuilder,
  });
}

class AnamenuView extends StatefulWidget {
  const AnamenuView({super.key});

  @override
  State<AnamenuView> createState() => _AnamenuViewState();
}

class _AnamenuViewState extends State<AnamenuView> with SingleTickerProviderStateMixin {
  int _gunlukIslemSayisi = 0;
  bool _isLoadingMetrics = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final List<ModuleItem> _allModules;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _initModules();
    _loadRealMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppDialogs.checkAndRequestPermissions(context);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initModules() {
    _allModules = [
      ModuleItem(
        titleKey: 'depoyonetimi',
        titleDefault: 'Depo Yönetimi',
        subtitleKey: 'depo_sub',
        subtitleDefault: 'Sayım, Mal Kabul, Transfer',
        icon: Icons.warehouse_rounded,
        color: AppTheme.primaryBlue,
        keywords: ['depo', 'sayım', 'malkabul', 'transfer', 'stok', 'ambarı', 'kabul'],
        targetBuilder: (_) => const DepoYonetimiView(),
      ),
      ModuleItem(
        titleKey: 'urunyonetimi',
        titleDefault: 'Ürün Yönetim',
        subtitleKey: 'urun_sub',
        subtitleDefault: 'Kabul, Satış, İade, Stok, Etiket & Fiyat Gör',
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFF3B82F6),
        keywords: ['ürün', 'urun', 'fiyat', 'stok', 'etiket', 'barkod', 'mal'],
        targetBuilder: (_) => const UrunYonetimiView(),
      ),
      ModuleItem(
        titleKey: 'siparisyonetimi',
        titleDefault: 'Sipariş Yönetimi',
        subtitleKey: 'siparis_sub',
        subtitleDefault: 'Alınan/Verilen Sipariş, Sevkiyat & Teslim Alma',
        icon: Icons.shopping_bag_rounded,
        color: const Color(0xFF8B5CF6),
        keywords: ['sipariş', 'siparis', 'sevk', 'teslimat', 'alınan', 'verilen'],
        targetBuilder: (_) => const SiparisYonetimiView(),
      ),
      ModuleItem(
        titleKey: 'finansyonetimi',
        titleDefault: 'Finans Yönetim',
        subtitleKey: 'finans_sub',
        subtitleDefault: 'Kasa, Banka Tahsilat, Ekstre, Rapor & Cari Ekle',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF10B981),
        keywords: ['finans', 'kasa', 'banka', 'tahsilat', 'ekstre', 'bakiye', 'nakit', 'pos', 'kredi kartı'],
        targetBuilder: (_) => const FinansYonetimiView(),
      ),
    ];
  }

  List<ModuleItem> get _filteredModules {
    if (_searchQuery.trim().isEmpty) {
      return _allModules;
    }
    final q = _searchQuery.toLowerCase().trim();
    return _allModules.where((item) {
      final title = item.titleDefault.toLowerCase();
      final subtitle = item.subtitleDefault.toLowerCase();
      final matchTitleOrSub = title.contains(q) || subtitle.contains(q);
      final matchKw = item.keywords.any((k) => k.toLowerCase().contains(q));
      return matchTitleOrSub || matchKw;
    }).toList();
  }

  Future<void> _loadRealMetrics() async {
    try {
      final list = await ApiService.getBelgeListele();
      if (mounted) {
        setState(() {
          _gunlukIslemSayisi = list.length;
          _isLoadingMetrics = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _gunlukIslemSayisi = SaveSettings.belgeList.length;
          _isLoadingMetrics = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modules = _filteredModules;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: context.tr('bildirimler', 'Bildirimler'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BildirimlerView()),
              ).then((_) => _loadRealMetrics());
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.tr('sistemayarlari', 'Sistem Ayarları'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SistemAyarlariView()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: AppTheme.accentRed),
            tooltip: context.tr('cikis', 'Çıkış Yap'),
            onPressed: () => _showLogoutConfirmation(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // bymcloud login sayfasından alıntılanan animasyonlu çizgi ve odak halkaları motoru
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundLinesPainter(animation: _animController, isDark: isDark),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Banner Card
                  _buildUserProfileBanner(context, isDark),
                  const SizedBox(height: 20),

                  // Daily Transaction Real Metrics Card
                  _buildRealMetricsCard(context, isDark),
                  const SizedBox(height: 24),

                  // Search Bar for Modules & Services
                  _buildSearchBar(context, isDark),
                  const SizedBox(height: 20),

                  // Section Title & Counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('moduller', 'Modüller & Hizmetler'),
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${modules.length} ${context.tr("modul", "Hizmet / Modül")}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Modern Module Grid or Empty Search Result
                  if (modules.isEmpty)
                    _buildEmptySearchResults(context, isDark)
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        final item = modules[index];
                        return _buildModuleCard(
                          context,
                          title: context.tr(item.titleKey, item.titleDefault),
                          icon: item.icon,
                          color: item.color,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: item.targetBuilder),
                          ).then((_) => _loadRealMetrics()),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? AppTheme.primaryBlue
              : (isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
          width: _searchQuery.isNotEmpty ? 1.5 : 1.0,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: context.tr('Modül veya hizmet ara... (Örn: Tahsilat, Stok, Depo, Fiyat)', 'Modül veya hizmet ara... (Örn: Tahsilat, Stok, Depo, Fiyat)'),
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildEmptySearchResults(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            context.tr('Aramanızla eşleşen modül bulunamadı.', 'Aramanızla eşleşen modül veya hizmet bulunamadı.'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(context.tr('Tümünü Göster', 'Tüm Modülleri Göster')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileBanner(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(Icons.person_rounded, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SaveSettings.superUserPosta.isNotEmpty
                      ? SaveSettings.superUserPosta
                      : (SaveSettings.kullaniciAdi.isNotEmpty ? SaveSettings.kullaniciAdi : 'demo@demo'),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.store_rounded, size: 14, color: AppTheme.accentCyan),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            SaveSettings.subeAdi.isNotEmpty ? SaveSettings.subeAdi : 'Ürün Merkez Şubesi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white54, shape: BoxShape.circle)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warehouse_rounded, size: 14, color: AppTheme.accentCyan),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            SaveSettings.depoAdi.isNotEmpty ? SaveSettings.depoAdi : 'Merkez Depo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealMetricsCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BelgeListeleView(belgeTuru: '')),
            ).then((_) => _loadRealMetrics());
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, size: 26, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Günlük İşlem Özet', 'Günlük İşlem'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isLoadingMetrics
                            ? '...'
                            : '$_gunlukIslemSayisi ${context.tr("Evrak Kayıtlı", "Evrak Kayıtlı")}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryBlue, size: 22),
                  tooltip: context.tr('Yenile', 'Yenile'),
                  onPressed: () => _loadRealMetrics(),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, size: 30, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('cikis', 'Çıkış Yap'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          context.tr('Oturumunuz kapatılacaktır. Devam etmek istiyor musunuz?', 'Oturumunuz kapatılacaktır. Devam etmek istiyor musunuz?'),
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('iptal', 'İptal'), style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () {
              SaveSettings.clearSession();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginView()),
                (route) => false,
              );
            },
            child: Text(context.tr('cikis', 'Çıkış Yap'), style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class BackgroundLinesPainter extends CustomPainter {
  final Animation<double>? animation;
  final bool isDark;

  BackgroundLinesPainter({this.animation, this.isDark = false}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final double t = animation?.value ?? 0.0;
    
    // Draw background base gradient first for seamless visual blending
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final baseGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [const Color(0xFF0F172A), const Color(0xFF020617)] // Premium deep slate/navy
          : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)], // Soft slate white
    );
    canvas.drawRect(rect, Paint()..shader = baseGradient.createShader(rect));

    // Dynamic Morphing Glowing Orbs (Aura effect using Gaussian Blur)
    // Orb 1: Moves in a smooth sine wave orbit on the top right
    final orb1Center = Offset(
      size.width * 0.8 + 40 * math.cos(t * 2 * math.pi),
      size.height * 0.2 + 50 * math.sin(t * 2 * math.pi),
    );
    final orb1Paint = Paint()
      ..color = (isDark ? const Color(0xFF6366F1) : const Color(0xFFC7D2FE)).withValues(alpha: isDark ? 0.12 : 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);
    canvas.drawCircle(orb1Center, size.width * 0.45, orb1Paint);

    // Orb 2: Moves in opposite orbit on the bottom left
    final orb2Center = Offset(
      size.width * 0.2 + 50 * math.sin(t * 2 * math.pi),
      size.height * 0.8 + 40 * math.cos(t * 2 * math.pi),
    );
    final orb2Paint = Paint()
      ..color = (isDark ? const Color(0xFF06B6D4) : const Color(0xFFCFFAFE)).withValues(alpha: isDark ? 0.08 : 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(orb2Center, size.width * 0.4, orb2Paint);

    // Draw premium subtle grid structure
    final gridPaint = Paint()
      ..color = (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)).withValues(alpha: isDark ? 0.20 : 0.30)
      ..strokeWidth = 0.8;

    const double gridSpacing = 45.0;
    // We add slow horizontal drift to the grid lines
    final double gridShiftX = t * gridSpacing;

    for (double x = gridShiftX % gridSpacing; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw tech constellation: glowing micro-dots at grid intersections that gently fade in and out
    final dotPaint = Paint()
      ..color = (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0075FF)).withValues(alpha: isDark ? 0.15 : 0.2)
      ..style = PaintingStyle.fill;

    // Subtly render dots at every 3rd grid intersection with breathing pulse
    int colIndex = 0;
    for (double x = gridShiftX % (gridSpacing * 3); x < size.width; x += gridSpacing * 3) {
      int rowIndex = 0;
      for (double y = gridSpacing * 2; y < size.height; y += gridSpacing * 3) {
        final double pulseVal = 1.0 + 0.6 * math.sin(t * 2 * math.pi + (colIndex + rowIndex));
        canvas.drawCircle(Offset(x, y), pulseVal, dotPaint);
        rowIndex++;
      }
      colIndex++;
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundLinesPainter oldDelegate) => true;
}
