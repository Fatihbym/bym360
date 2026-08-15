import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'finans_views.dart';
import 'kullanici_rapor_view.dart';

class FinansYonetimiView extends StatelessWidget {
  const FinansYonetimiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('finansyonetimi', 'Finans Yönetim'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          children: [
            Text(context.tr('Finans Operasyonları', 'Finans Operasyonları'), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            // 1. Kasa Tahsilat
            _buildModernTile(
              context,
              title: context.tr('Kasa Tahsilat', 'Kasa Tahsilat'),
              icon: Icons.payments_rounded,
              color: AppTheme.accentGreen,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TahsilatListeleView(initialIndex: 1)),
              ),
            ),

            // 2. Banka Tahsilat
            _buildModernTile(
              context,
              title: context.tr('Banka Tahsilat', 'Banka Tahsilat'),
              icon: Icons.account_balance_rounded,
              color: AppTheme.primaryBlue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TahsilatListeleView(initialIndex: 2)),
              ),
            ),

            // 3. Cari Hesap Ekstre
            _buildModernTile(
              context,
              title: context.tr('Cari Hesap Ekstre', 'Cari Hesap Ekstre'),
              icon: Icons.insights_rounded,
              color: AppTheme.accentCyan,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CariHareketEkstreView()),
              ),
            ),

            // 4. Gün Sonu Raporu
            _buildModernTile(
              context,
              title: context.tr('Gün Sonu Raporu', 'Gün Sonu Raporu'),
              icon: Icons.bar_chart_rounded,
              color: AppTheme.accentPurple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KullaniciRaporView()),
              ),
            ),

            // 5. Cari Ekle
            _buildModernTile(
              context,
              title: context.tr('Cari Ekle', 'Cari Ekle'),
              icon: Icons.person_add_alt_1_rounded,
              color: const Color(0xFF10B981),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CariEkleView()),
              ),
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
