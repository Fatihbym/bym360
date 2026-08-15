import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'belge_listele_view.dart';
import 'fiyat_gor_view.dart';
import 'stok_islemleri_view.dart';
import 'etiket_views.dart';

class UrunYonetimiView extends StatelessWidget {
  const UrunYonetimiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('urunyonetimi', 'Ürün Yönetim'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          children: [
            Text(context.tr('Ürün & Barkod Operasyonları', 'Ürün & Barkod Operasyonları'), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            // 1. Kabul İşlemleri
            _buildModernTile(
              context,
              title: context.tr('kabulislem', 'Kabul İşlemleri'),
              icon: Icons.move_to_inbox_rounded,
              color: AppTheme.accentGreen,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BelgeListeleView(belgeTuru: 'MALKABUL'))),
            ),

            // 2. Satış İşlemleri
            _buildModernTile(
              context,
              title: context.tr('satisislem', 'Satış İşlemleri'),
              icon: Icons.receipt_long_rounded,
              color: AppTheme.accentCyan,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BelgeListeleView(belgeTuru: 'SATIS'))),
            ),

            // 3. İade İşlemleri
            _buildModernTile(
              context,
              title: context.tr('iadeislem', 'İade İşlemleri'),
              icon: Icons.assignment_return_rounded,
              color: const Color(0xFFEF4444),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IadeIslemleriView())),
            ),

            // 4. Stok İşlemleri
            _buildModernTile(
              context,
              title: context.tr('stokislem', 'Stok İşlemleri'),
              icon: Icons.manage_search_rounded,
              color: AppTheme.accentOrange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StokIslemleriView())),
            ),

            // 5. Etiket İşlemleri
            _buildModernTile(
              context,
              title: context.tr('Etiket İşlemleri', 'Etiket İşlemleri'),
              icon: Icons.qr_code_2_rounded,
              color: const Color(0xFF8D6E63),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EtiketSecimView())),
            ),

            // 6. Fiyat Gör
            _buildModernTile(
              context,
              title: context.tr('fiyatgor', 'Fiyat Gör'),
              icon: Icons.center_focus_strong_rounded,
              color: AppTheme.primaryBlue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FiyatGorView())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
}

class IadeIslemleriView extends StatelessWidget {
  const IadeIslemleriView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('İade İşlemleri', 'İade İşlemleri'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildOptionCard(
              context,
              title: context.tr('Kabul İade İşlemleri', 'Kabul İade İşlemleri'),
              icon: Icons.assignment_return_rounded,
              color: const Color(0xFF0D9488),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BelgeListeleView(belgeTuru: 'ALIS_IADE')),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              title: context.tr('Satış İade İşlemleri', 'Satış İade İşlemleri'),
              icon: Icons.monetization_on_rounded,
              color: const Color(0xFF0284C7),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BelgeListeleView(belgeTuru: 'SATIS_IADE')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 36, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
