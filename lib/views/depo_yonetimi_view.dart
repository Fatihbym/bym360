import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'belge_listele_view.dart';
import 'urun_toplama_view.dart';

class DepoYonetimiView extends StatelessWidget {
  const DepoYonetimiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('depoyonetimi', 'Depo Yönetimi'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          children: [
            Text(context.tr('Depo Operasyonları', 'Depo Operasyonları'), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            // 1. Depo Sevk
            _buildModernTile(
              context,
              title: context.tr('Depo Sevk', 'Depo Sevk'),
              icon: Icons.swap_horizontal_circle_rounded,
              color: AppTheme.accentCyan,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BelgeListeleView(belgeTuru: 'TRANSFER')),
              ),
            ),

            // 2. Sayım İşlemleri
            _buildModernTile(
              context,
              title: context.tr('Sayım İşlemleri', 'Sayım İşlemleri'),
              icon: Icons.fact_check_rounded,
              color: AppTheme.primaryBlue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BelgeListeleView(belgeTuru: 'SAYIM')),
              ),
            ),

            // 3. Depo Sevk İstek
            _buildModernTile(
              context,
              title: context.tr('Depo Sevk İstek', 'Depo Sevk İstek'),
              icon: Icons.unarchive_rounded,
              color: const Color(0xFF3B82F6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BelgeListeleView(belgeTuru: 'SEVK_ISTEK')),
              ),
            ),

            // 4. Depo İstek İade
            _buildModernTile(
              context,
              title: context.tr('Depo İstek İade', 'Depo İstek İade'),
              icon: Icons.assignment_return_rounded,
              color: const Color(0xFFEF4444),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BelgeListeleView(belgeTuru: 'SEVK_IADE_ISTEK')),
              ),
            ),

            // 5. Ürün Toplama
            _buildModernTile(
              context,
              title: context.tr('Ürün Toplama', 'Ürün Toplama'),
              icon: Icons.grid_view_rounded,
              color: AppTheme.accentOrange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UrunToplamaView()),
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

