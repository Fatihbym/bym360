import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'atamali_siparis_view.dart';
import 'belge_listele_view.dart';
import 'belge_olustur_view.dart';
import 'siparis_sevkiyat_view.dart';

class SiparisYonetimiView extends StatelessWidget {
  const SiparisYonetimiView({super.key});

  void _showYeniSiparisModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Yeni Sipariş Oluştur',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue,
                  child: Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
                ),
                title: Text('Alınan Sipariş Belgesi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BelgeOlusturView(belgeTuru: 'ALINAN_SIPARIS')),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.accentGreen,
                  child: Icon(Icons.shopping_bag_rounded, color: Colors.white),
                ),
                title: Text('Verilen Sipariş Belgesi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BelgeOlusturView(belgeTuru: 'VERILEN_SIPARIS')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('siparisyonetimi', 'Sipariş Yönetimi'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Yeni Sipariş',
            onPressed: () => _showYeniSiparisModal(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          children: [
            Text(context.tr('Sipariş Operasyonları', 'Sipariş Operasyonları'), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            // 1. Alınan Siparişler
            _buildModernTile(
              context,
              title: context.tr('aliniansiparis', 'Alınan Siparişler'),
              icon: Icons.shopping_cart_checkout_rounded,
              color: AppTheme.primaryBlue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BelgeListeleView(belgeTuru: 'ALINAN_SIPARIS')),
              ),
            ),

            // 2. Verilen Siparişler
            _buildModernTile(
              context,
              title: context.tr('verilensiparis', 'Verilen Siparişler'),
              icon: Icons.local_mall_rounded,
              color: AppTheme.accentGreen,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BelgeListeleView(belgeTuru: 'VERILEN_SIPARIS')),
              ),
            ),

            // 3. Alınan Siparişlerin Sevkiyatı
            _buildModernTile(
              context,
              title: context.tr('Alınan Siparişlerin Sevkiyatı', 'Alınan Siparişlerin Sevkiyatı'),
              icon: Icons.local_shipping_rounded,
              color: AppTheme.accentCyan,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SiparisSevkiyatView(mod: 'sevk')),
              ),
            ),

            // 4. Verilen Siparişlerin Teslim Alınması
            _buildModernTile(
              context,
              title: context.tr('Verilen Siparişlerin Teslim Alınması', 'Verilen Siparişlerin Teslim Alınması'),
              icon: Icons.archive_rounded,
              color: AppTheme.accentPurple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SiparisSevkiyatView(mod: 'teslimal')),
              ),
            ),

            // 5. Atamalı Sipariş Teslim Alma
            _buildModernTile(
              context,
              title: context.tr('Atamalı Sipariş Teslim Alma', 'Atamalı Sipariş Teslim Alma'),
              icon: Icons.assignment_turned_in_rounded,
              color: AppTheme.accentOrange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AtamaliSiparisView()),
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
