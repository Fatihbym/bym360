import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'belge_detay_view.dart';
import 'belge_olustur_view.dart';

class AmbarIslemleriView extends StatefulWidget {
  const AmbarIslemleriView({super.key});

  @override
  State<AmbarIslemleriView> createState() => _AmbarIslemleriViewState();
}

class _AmbarIslemleriViewState extends State<AmbarIslemleriView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<GetBelgeListele> _alimList = [];
  List<GetBelgeListele> _gonderimList = [];
  List<GetBelgeListele> _filteredAlimList = [];
  List<GetBelgeListele> _filteredGonderimList = [];

  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadAmbarBelgeleri();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAmbarBelgeleri() async {
    setState(() => _isLoading = true);
    final alim = await ApiService.getBelgeListele(tur: 'AMBAR_ALIM');
    final gonderim = await ApiService.getBelgeListele(tur: 'AMBAR_GONDERIM');
    if (!mounted) return;
    setState(() {
      _alimList = alim;
      _gonderimList = gonderim;
      _filterList(_searchController.text);
      _isLoading = false;
    });
  }

  void _filterList(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) {
      _filteredAlimList = List.from(_alimList);
      _filteredGonderimList = List.from(_gonderimList);
    } else {
      _filteredAlimList = _alimList.where((b) {
        return b.belgeNo.toLowerCase().contains(q) ||
            b.cariAdi.toLowerCase().contains(q) ||
            b.cikisDepo.toLowerCase().contains(q) ||
            b.varisDepo.toLowerCase().contains(q);
      }).toList();
      _filteredGonderimList = _gonderimList.where((b) {
        return b.belgeNo.toLowerCase().contains(q) ||
            b.cariAdi.toLowerCase().contains(q) ||
            b.cikisDepo.toLowerCase().contains(q) ||
            b.varisDepo.toLowerCase().contains(q);
      }).toList();
    }
  }

  void _createAmbarDocument() async {
    final isAlimTab = _tabController.index == 0;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BelgeOlusturView(
          belgeTuru: isAlimTab ? 'AMBAR_ALIM' : 'AMBAR_GONDERIM',
        ),
      ),
    );
    _loadAmbarBelgeleri();
  }

  @override
  Widget build(BuildContext context) {
    final isAlimTab = _tabController.index == 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ambar İşlemleri', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.download_rounded), text: 'Ambar Alım Belgeleri'),
            Tab(icon: Icon(Icons.upload_rounded), text: 'Ambar Gönderim Belgeleri'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAmbarBelgeleri,
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAmbarDocument,
        backgroundColor: isAlimTab ? AppTheme.accentGreen : AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        icon: Icon(isAlimTab ? Icons.add_to_photos_rounded : Icons.outbox_rounded),
        label: Text(
          isAlimTab ? 'YENİ AMBAR ALIM BELGESİ' : 'YENİ AMBAR GÖNDERİM BELGESİ',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? AppTheme.darkSurface : Colors.grey.shade100,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _filterList(val)),
              decoration: InputDecoration(
                hintText: 'Belge No, Cari veya Depo Adı ile Ara...',
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
          const Divider(height: 1),

          // Tab Bar Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBelgeListView(_filteredAlimList, 'Ambar Alım', isAlim: true),
                _buildBelgeListView(_filteredGonderimList, 'Ambar Gönderim', isAlim: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBelgeListView(List<GetBelgeListele> list, String turAdi, {required bool isAlim}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAlim ? Icons.move_to_inbox_outlined : Icons.outbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Kayıtlı $turAdi belgesi bulunamadı.',
              style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 15),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createAmbarDocument,
              icon: const Icon(Icons.add_rounded),
              label: Text('$turAdi Belgesi Oluştur'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (c, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = list[index];

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
              backgroundColor: isAlim ? AppTheme.accentGreen.withValues(alpha: 0.15) : AppTheme.primaryBlue.withValues(alpha: 0.15),
              child: Icon(
                isAlim ? Icons.download_rounded : Icons.upload_rounded,
                color: isAlim ? AppTheme.accentGreen : AppTheme.primaryBlue,
                size: 22,
              ),
            ),
            title: Text(
              item.belgeNo.isNotEmpty ? item.belgeNo : 'Ambar Belgesi #${item.belgeId}',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.cikisDepo.isNotEmpty || item.varisDepo.isNotEmpty)
                    Text(
                      'Çıkış: ${item.cikisDepo} ➔ Varış: ${item.varisDepo}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                  Text(
                    'Cari: ${item.cariAdi.isNotEmpty ? item.cariAdi : "Firma İçi Transfer"}',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  Text(
                    'Tarih: ${item.tarih} | Tutar: ₺${item.genelToplam.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            isThreeLine: true,
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isAlim ? AppTheme.accentGreen : AppTheme.primaryBlue,
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
                ).then((_) => _loadAmbarBelgeleri());
              },
              child: Text('Detay', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        );
      },
    );
  }
}
