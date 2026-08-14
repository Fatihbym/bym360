import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/storage/save_settings.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/barcode_scanner_view.dart';
import 'belge_listele_view.dart';
import 'belge_olustur_view.dart';
import 'kontrollu_sevk_view.dart';

// ============================================================
// İade İşlemi View (Activity_Iade)
// ============================================================
class IadeView extends StatelessWidget {
  const IadeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('İade İşlemleri', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Geçmiş İade Belgeleri',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BelgeListeleView(belgeTuru: 'IADE'),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _tile(
            context,
            'Alış İadesi Oluştur',
            'Tedarikçiye iade edilen ürünler için fiş oluşturun',
            Icons.undo_rounded,
            AppTheme.accentRed,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BelgeOlusturView(belgeTuru: 'ALIS_IADE'),
                ),
              );
            },
          ),
          _tile(
            context,
            'Satış İadesi Kabul',
            'Müşteriden iade alınan ürünler için kabul belgesi oluşturun',
            Icons.assignment_return_rounded,
            AppTheme.accentOrange,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BelgeOlusturView(belgeTuru: 'SATIS_IADE'),
                ),
              );
            },
          ),
          _tile(
            context,
            'İade Belgeleri Listesi',
            'Sistemdeki tüm alış ve satış iade belgelerini görüntüleyin',
            Icons.receipt_long_rounded,
            AppTheme.primaryBlue,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BelgeListeleView(belgeTuru: 'IADE'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext ctx, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================
// Kontrollü Ürün Ekle View (Activity_KontrolluUrunEkle)
// ============================================================
class KontrolluUrunEkleView extends StatefulWidget {
  final int? belgeId;
  const KontrolluUrunEkleView({super.key, this.belgeId});

  @override
  State<KontrolluUrunEkleView> createState() => _KontrolluUrunEkleViewState();
}

class _KontrolluUrunEkleViewState extends State<KontrolluUrunEkleView> {
  final _barcodeController = TextEditingController();
  final _miktarController = TextEditingController(text: '1');
  final List<Map<String, dynamic>> _verifiedItems = [];
  bool _isSearching = false;

  Future<void> _verifyAndAdd() async {
    final barcode = _barcodeController.text.trim();
    final miktar = double.tryParse(_miktarController.text.trim()) ?? 1.0;
    if (barcode.isEmpty) return;

    setState(() => _isSearching = true);
    String stokAdi = 'Stok ($barcode)';
    int stokId = 0;
    double fiyat = 0.0;

    try {
      final res = await ApiService.getStokAra(barcode);
      if (res.isNotEmpty) {
        stokAdi = res.first.stokAdi;
        stokId = res.first.stokId;
        fiyat = res.first.satisFiyat;
      }
    } catch (_) {}

    final index = _verifiedItems.indexWhere((k) => k['barkod'] == barcode);
    setState(() {
      _isSearching = false;
      if (index >= 0) {
        _verifiedItems[index]['miktar'] = (_verifiedItems[index]['miktar'] as double) + miktar;
      } else {
        _verifiedItems.add({
          'stokId': stokId,
          'barkod': barcode,
          'stokAdi': stokAdi,
          'miktar': miktar,
          'fiyat': fiyat,
          'dogrulanma': true,
        });
      }
      _barcodeController.clear();
      _miktarController.text = '1';
    });
  }

  Future<void> _cameraScan() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );
    if (scanned != null && scanned.isNotEmpty) {
      _barcodeController.text = scanned;
      await _verifyAndAdd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Kontrollü Ürün Ekleme', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: _cameraScan,
            tooltip: 'Barkod Tara',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: isDark ? AppTheme.darkSurface : Colors.white,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _barcodeController,
                    autofocus: true,
                    onSubmitted: (_) => _verifyAndAdd(),
                    decoration: InputDecoration(
                      hintText: 'Barkod okutun veya yazın...',
                      prefixIcon: const Icon(Icons.barcode_reader),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.camera_alt_rounded),
                        onPressed: _cameraScan,
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _miktarController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'Adet',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSearching ? null : _verifyAndAdd,
                  child: _isSearching
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.verified_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _verifiedItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'Kontrollü ürün ekleme için barkod okutun.',
                          style: GoogleFonts.inter(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _verifiedItems.length,
                    itemBuilder: (context, index) {
                      final item = _verifiedItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.verified_rounded, color: AppTheme.accentGreen, size: 24),
                          ),
                          title: Text(item['stokAdi'] ?? 'Stok', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          subtitle: Text('Barkod: ${item["barkod"]}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${item["miktar"]} Adet',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.accentRed),
                                onPressed: () => setState(() => _verifiedItems.removeAt(index)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _verifiedItems.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  border: Border(top: BorderSide(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text(
                      'DOĞRULANAN ÜRÜNLERİ AKTAR (${_verifiedItems.length})',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () async {
                      if (widget.belgeId != null && widget.belgeId! > 0) {
                        for (final item in _verifiedItems) {
                          await ApiService.urunEkle(
                            belgeTuru: '1',
                            barkod: item['barkod'] ?? '',
                            belgeId: widget.belgeId!,
                            stokId: item['stokId'] ?? 0,
                            miktar: (item['miktar'] as num).toDouble(),
                            urunFiyat: (item['fiyat'] as num).toDouble(),
                            depoId: SaveSettings.depoId,
                            subeId: SaveSettings.subeId,
                            cariId: SaveSettings.secilenCariID,
                          );
                        }
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.accentGreen,
                          content: Text('${_verifiedItems.length} ürün başarıyla işlendi ve aktarıldı.'),
                        ),
                      );
                      Navigator.pop(context, _verifiedItems);
                    },
                  ),
                ),
              ),
            ),
    );
  }
}

// ============================================================
// Kontrollü Seçim View (Activity_KontrolluSecim)
// ============================================================
class KontrolluSecimView extends StatelessWidget {
  const KontrolluSecimView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kontrollü İşlem Seçimi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _tile(
            context,
            'Kontrollü Gönderim',
            'Barkod doğrulamalı depo çıkış ve sevk fişi',
            Icons.outbox_rounded,
            AppTheme.primaryBlue,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const KontrolluSevkView(isGonderim: true),
                ),
              );
            },
          ),
          _tile(
            context,
            'Kontrollü Kabul',
            'Barkod doğrulamalı depo giriş ve mal kabul fişi',
            Icons.inbox_rounded,
            AppTheme.accentGreen,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const KontrolluSevkView(isGonderim: false),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext ctx, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}
