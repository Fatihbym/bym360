import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'belge_detay_view.dart';
import 'belge_olustur_view.dart';

class SiparisSevkiyatView extends StatefulWidget {
  final String mod; // 'sevk' or 'teslimal'
  const SiparisSevkiyatView({super.key, required this.mod});

  @override
  State<SiparisSevkiyatView> createState() => _SiparisSevkiyatViewState();
}

class _SiparisSevkiyatViewState extends State<SiparisSevkiyatView> {
  List<GetBelgeListele> _belgeList = [];
  List<GetBelgeListele> _filteredList = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBelgeler();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBelgeler() async {
    setState(() => _isLoading = true);
    final isSevk = widget.mod == 'sevk';
    final primaryTur = isSevk ? 'siparissevkiyat' : 'siparisteslimal';
    final fallbackTur = isSevk ? 'SP_SEVK' : 'SP_TESLIM';

    var res = await ApiService.getBelgeListele(tur: primaryTur);
    if (res.isEmpty) {
      res = await ApiService.getBelgeListele(tur: fallbackTur);
    }

    if (!mounted) return;
    setState(() {
      _belgeList = res;
      _filterList(_searchController.text);
      _isLoading = false;
    });
  }

  void _filterList(String query) {
    if (query.trim().isEmpty) {
      _filteredList = List.from(_belgeList);
    } else {
      final q = query.toLowerCase().trim();
      _filteredList = _belgeList.where((b) {
        return b.belgeNo.toLowerCase().contains(q) ||
            b.cariAdi.toLowerCase().contains(q) ||
            b.belgeId.toString().contains(q);
      }).toList();
    }
  }

  void _createNewShipmentDocument() {
    final isSevk = widget.mod == 'sevk';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BelgeOlusturView(
          belgeTuru: isSevk ? 'SP_SEVK' : 'SP_TESLIM',
        ),
      ),
    ).then((_) => _loadBelgeler());
  }

  @override
  Widget build(BuildContext context) {
    final isSevk = widget.mod == 'sevk';
    final title = isSevk ? 'Alınan Sipariş Sevkiyatı' : 'Verilen Sipariş Teslim Alma';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadBelgeler,
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewShipmentDocument,
        backgroundColor: isSevk ? AppTheme.primaryBlue : AppTheme.purpleGradient.colors.first,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: Text(
          isSevk ? 'YENİ SEVKİYAT BELGESİ' : 'YENİ TESLİMAT BELGESİ',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? AppTheme.darkSurface : Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _filterList(val)),
                    decoration: InputDecoration(
                      hintText: 'Belge No veya Cari Adı Ara...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _filterList(''));
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? AppTheme.darkCardBorder : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Documents List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSevk ? Icons.local_shipping_outlined : Icons.move_to_inbox_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Bekleyen ${isSevk ? 'sevkiyat' : 'teslimat'} belgesi bulunamadı.',
                              style: GoogleFonts.inter(fontSize: 15, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _createNewShipmentDocument,
                              icon: const Icon(Icons.add_rounded),
                              label: Text(isSevk ? 'Sevkiyat Belgesi Oluştur' : 'Teslimat Belgesi Oluştur'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredList.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _filteredList[index];

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: isSevk
                                    ? AppTheme.accentCyan.withValues(alpha: 0.15)
                                    : AppTheme.purpleGradient.colors.first.withValues(alpha: 0.15),
                                child: Icon(
                                  isSevk ? Icons.local_shipping_rounded : Icons.move_to_inbox_rounded,
                                  color: isSevk ? AppTheme.accentCyan : AppTheme.purpleGradient.colors.first,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                item.belgeNo.isNotEmpty ? item.belgeNo : 'Sipariş #${item.belgeId}',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cari: ${item.cariAdi.isNotEmpty ? item.cariAdi : "Cari Belirtilmemiş"}',
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tarih: ${item.tarih} | Toplam: ₺${item.genelToplam.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              isThreeLine: true,
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSevk ? AppTheme.primaryBlue : AppTheme.purpleGradient.colors.first,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BelgeDetayView(
                                        belgeId: item.belgeId,
                                        belgeNo: item.belgeNo,
                                        belgeTuru: item.belgeTurAdi,
                                        belgeTurId: item.belgeTuru,
                                        cariAdi: item.cariAdi,
                                        tarih: item.tarih,
                                        genelToplam: item.genelToplam,
                                      ),
                                    ),
                                  ).then((_) => _loadBelgeler());
                                },
                                child: Text(
                                  isSevk ? 'Sevk Et' : 'Teslim Al',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
