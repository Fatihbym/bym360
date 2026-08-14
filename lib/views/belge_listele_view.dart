import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'belge_detay_view.dart';
import 'belge_olustur_view.dart';

class BelgeListeleView extends StatefulWidget {
  final String belgeTuru;

  const BelgeListeleView({super.key, required this.belgeTuru});

  @override
  State<BelgeListeleView> createState() => _BelgeListeleViewState();
}

class _BelgeListeleViewState extends State<BelgeListeleView> {
  List<GetBelgeListele> _belgeList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isFabMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _loadBelgeler();
  }

  Future<void> _loadBelgeler({bool allData = false}) async {
    setState(() => _isLoading = true);
    final result = await ApiService.getBelgeListele(tur: allData ? '' : widget.belgeTuru);
    if (mounted) {
      setState(() {
        _belgeList = result;
        _isLoading = false;
      });
    }
  }

  String _getBelgeBasligi(BuildContext context) {
    switch (widget.belgeTuru.toUpperCase()) {
      case 'TRANSFER':
        return context.tr('Depo Sevk Belgeleri', 'Depo Sevk Belgeleri');
      case 'SAYIM':
        return context.tr('Sayım Belgeleri', 'Sayım Belgeleri');
      case 'SEVK_ISTEK':
        return context.tr('Depo Sevk İstek Belgeleri', 'Depo Sevk İstek Belgeleri');
      case 'SEVK_IADE_ISTEK':
        return context.tr('Depo İstek İade Belgeleri', 'Depo İstek İade Belgeleri');
      case 'DEPOISTEKGONDERIM':
        return context.tr('Depo İstek Gönderim Belgeleri', 'Depo İstek Gönderim Belgeleri');
      case 'MALKABUL':
      case 'KABULISLEM':
        return context.tr('Kabul İşlemleri', 'Kabul İşlemleri');
      case 'SATIS':
      case 'SATISISLEM':
        return context.tr('Satış İşlemleri', 'Satış İşlemleri');
      case 'ALIS_IADE':
      case 'KABULIADEISLEM':
        return context.tr('Kabul İade İşlemleri', 'Kabul İade İşlemleri');
      case 'SATIS_IADE':
      case 'SATISIADEISLEM':
        return context.tr('Satış İade İşlemleri', 'Satış İade İşlemleri');
      case 'ALINAN_SIPARIS':
      case 'ALINANSIPARIS':
        return context.tr('Alınan Sipariş Belgeleri', 'Alınan Sipariş Belgeleri');
      case 'VERILEN_SIPARIS':
      case 'VERILENSIPARIS':
        return context.tr('Verilen Sipariş Belgeleri', 'Verilen Sipariş Belgeleri');
      case 'SIPARISSEVKIYAT':
      case 'SP_SEVK':
        return context.tr('Sipariş Sevkiyat Belgeleri', 'Sipariş Sevkiyat Belgeleri');
      case 'SIPARISTESLIMAL':
      case 'SP_TESLIM':
        return context.tr('Sipariş Teslim Alma Belgeleri', 'Sipariş Teslim Alma Belgeleri');
      case '':
      case 'GUNLUK_ISLEM':
      case 'TUMU':
        return context.tr('Günlük Kayıtlı Belgeler', 'Günlük Kayıtlı Belgeler');
      default:
        return '${widget.belgeTuru} Belgeleri';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredList = _belgeList.where((b) {
      final q = _searchQuery.toLowerCase();
      return b.belgeNo.toLowerCase().contains(q) || b.cariAdi.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_getBelgeBasligi(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: context.tr('Yenile', 'Yenile'),
            onPressed: () => _loadBelgeler(),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: context.tr('Belge Oluştur', 'Belge Oluştur'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BelgeOlusturView(belgeTuru: widget.belgeTuru)),
              ).then((_) => _loadBelgeler());
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isFabMenuOpen) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                  ),
                  child: Text('Belge Oluştur', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'fab_belge_olustur',
                  backgroundColor: AppTheme.accentGreen,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    setState(() => _isFabMenuOpen = false);
                    final targetTur = widget.belgeTuru.isNotEmpty ? widget.belgeTuru : 'TRANSFER';
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BelgeOlusturView(belgeTuru: targetTur)),
                    ).then((_) => _loadBelgeler());
                  },
                  child: const Icon(Icons.note_add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                  ),
                  child: Text('Tüm Verileri Göster', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'fab_tum_veriler',
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    setState(() => _isFabMenuOpen = false);
                    _loadBelgeler(allData: true);
                  },
                  child: const Icon(Icons.format_list_bulleted_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          FloatingActionButton(
            heroTag: 'fab_main_toggle',
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            onPressed: () {
              setState(() => _isFabMenuOpen = !_isFabMenuOpen);
            },
            child: Icon(_isFabMenuOpen ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded, size: 28),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: context.tr('Belge No veya Cari Adı ile ara...', 'Belge No veya Cari Adı ile ara...'),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),

          // Header columns matching bymmobil: Tarih | Saat | No | Tür | Depo | Cari | Onay
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppTheme.darkSurface : Colors.grey.shade200,
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Tarih', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('No', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Tür', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Depo', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Cari', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold))),
                SizedBox(width: 40, child: Text('Onay', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              context.tr('Belge bulunamadı.', 'Belge bulunamadı.'),
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBelgeler,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                title: Row(
                                  children: [
                                    Expanded(flex: 2, child: Text(item.tarih.isNotEmpty ? item.tarih : '-', style: GoogleFonts.inter(fontSize: 11))),
                                    Expanded(flex: 2, child: Text(item.belgeNo.isNotEmpty ? item.belgeNo : '#${item.belgeId}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold))),
                                    Expanded(flex: 2, child: Text(item.belgeTurAdi.isNotEmpty ? item.belgeTurAdi : widget.belgeTuru, style: GoogleFonts.inter(fontSize: 11), overflow: TextOverflow.ellipsis)),
                                    Expanded(flex: 3, child: Text(item.cikisDepo.isNotEmpty ? item.cikisDepo : (item.varisDepo.isNotEmpty ? item.varisDepo : '-'), style: GoogleFonts.inter(fontSize: 11), overflow: TextOverflow.ellipsis)),
                                    Expanded(flex: 3, child: Text(item.cariAdi.isNotEmpty ? item.cariAdi : '-', style: GoogleFonts.inter(fontSize: 11), overflow: TextOverflow.ellipsis)),
                                    const SizedBox(
                                      width: 40,
                                      child: Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 18,
                                        color: AppTheme.accentGreen,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BelgeDetayView(
                                        belgeId: item.belgeId,
                                        belgeNo: item.belgeNo,
                                        belgeTuru: widget.belgeTuru,
                                        belgeTurId: item.belgeTuru,
                                        cariAdi: item.cariAdi,
                                        tarih: item.tarih,
                                        genelToplam: item.genelToplam,
                                      ),
                                    ),
                                  ).then((_) => _loadBelgeler());
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
