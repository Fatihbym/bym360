import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/storage/save_settings.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/function_class.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/barcode_scanner_view.dart';

class StokIslemleriView extends StatefulWidget {
  const StokIslemleriView({super.key});

  @override
  State<StokIslemleriView> createState() => _StokIslemleriViewState();
}

class _StokIslemleriViewState extends State<StokIslemleriView> {
  final _searchController = TextEditingController();
  List<GetStok> _stokList = [];
  List<GetYazarKasaKdv> _yazarKasaKdvList = [];
  bool _isLoading = false;
  bool _akilliArama = SaveSettings.akilliArama.toLowerCase() == 'açık';

  @override
  void initState() {
    super.initState();
    _loadYazarKasaKdv();
  }

  Future<void> _loadYazarKasaKdv() async {
    final list = await ApiService.getYazarKasaKdv();
    if (mounted) {
      setState(() {
        _yazarKasaKdvList = list;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    final results = await ApiService.getStokAra(query);
    if (!mounted) return;
    setState(() {
      _stokList = results;
      _isLoading = false;
    });
  }

  void _toggleAkilliArama() {
    setState(() {
      _akilliArama = !_akilliArama;
      SaveSettings.akilliArama = _akilliArama ? 'Açık' : 'Kapalı';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_akilliArama ? 'Akıllı Arama Açık' : 'Akıllı Arama Kapalı'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Stok İşlemleri & Kartlar', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(
              _akilliArama ? Icons.auto_awesome : Icons.manage_search_rounded,
              color: _akilliArama ? AppTheme.accentOrange : Colors.white70,
            ),
            tooltip: _akilliArama ? 'Akıllı Arama Açık' : 'Akıllı Arama Kapalı',
            onPressed: _toggleAkilliArama,
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded),
            tooltip: 'Barkod Tara',
            onPressed: () async {
              final code = await BarcodeScannerScreen.scan(context, title: 'Stok Barkod Tara');
              if (code != null && code.isNotEmpty) {
                _searchController.text = code;
                _doSearch();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            tooltip: 'Yeni Stok Kartı Oluştur',
            onPressed: () => _showStokKartFormDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Modern Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: isDark ? AppTheme.darkSurface : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _doSearch(),
                    onChanged: (val) {
                      if (_akilliArama && val.trim().length >= 3) {
                        _doSearch();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: _akilliArama ? 'Stok Adı, Kodu veya Barkod (Akıllı Arama)...' : 'Stok Adı, Kodu veya Barkod...',
                      prefixIcon: Icon(
                        _akilliArama ? Icons.search_rounded : Icons.qr_code_scanner_rounded,
                        color: AppTheme.primaryBlue,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _stokList = []);
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                  onPressed: _doSearch,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Stok Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _stokList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Arama yapmak için en az 3 karakter giriniz',
                              style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _stokList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _stokList[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryBlue),
                              ),
                              title: Text(
                                item.stokAdi,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Wrap(
                                  spacing: 8,
                                  children: [
                                    Text('Kod: ${item.stokKodu}', style: GoogleFonts.inter(fontSize: 12)),
                                    if (item.barkod.isNotEmpty)
                                      Text('• Barkod: ${item.barkod}', style: GoogleFonts.inter(fontSize: 12)),
                                  ],
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₺${item.satisFiyat.toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppTheme.accentGreen,
                                    ),
                                  ),
                                  Text(
                                    'Stok: ${item.bakiye % 1 == 0 ? item.bakiye.toInt() : item.bakiye.toStringAsFixed(1)} ${item.birim}',
                                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              onTap: () => _showStokKartFormDialog(stokItem: item),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStokKartFormDialog(),
        icon: const Icon(Icons.add_box_rounded),
        label: Text('YENİ STOK KARTI', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showStokKartFormDialog({GetStok? stokItem}) {
    final isEditing = stokItem != null;
    final kodCtrl = TextEditingController(text: stokItem?.stokKodu ?? '');
    final adCtrl = TextEditingController(text: stokItem?.stokAdi ?? '');
    final barkodCtrl = TextEditingController(text: stokItem?.barkod ?? '');
    final alisFiyatCtrl = TextEditingController(text: stokItem?.alisFiyat.toString() ?? '0');
    final satisFiyatCtrl = TextEditingController(text: stokItem?.satisFiyat.toString() ?? '0');
    final ozelFiyat1Ctrl = TextEditingController(text: '0');
    final ozelFiyat2Ctrl = TextEditingController(text: '0');

    String selectedBirim = stokItem?.birim.isNotEmpty == true ? stokItem!.birim : 'ADET';
    String selectedKdvDh = 'Dahil';
    double selectedAlKdv = stokItem?.kdv ?? 18;
    double selectedSatKdv = stokItem?.kdv ?? 18;
    String selectedBarTur = 'EAN13';
    int? selectedYkKdvIndex = _yazarKasaKdvList.isNotEmpty ? 0 : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isEditing ? Icons.edit_note_rounded : Icons.add_box_rounded,
                          color: AppTheme.primaryBlue,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'Stok Kartını Güncelle' : 'Yeni Stok Kartı Oluştur',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // Kopyalama Hızlı Butonlar
                if (_searchController.text.trim().isNotEmpty) ...[
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                        onPressed: () {
                          setDialogState(() {
                            kodCtrl.text = _searchController.text.trim();
                          });
                        },
                        icon: const Icon(Icons.content_copy_rounded, size: 14),
                        label: Text('Aramayı Koda Kopyala', style: GoogleFonts.inter(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                        onPressed: () {
                          setDialogState(() {
                            final text = _searchController.text.trim();
                            barkodCtrl.text = text;
                            if (text.length == 8) {
                              selectedBarTur = 'EAN8';
                            } else if (text.length == 13) {
                              selectedBarTur = 'EAN13';
                            } else {
                              selectedBarTur = 'CODE128';
                            }
                          });
                        },
                        icon: const Icon(Icons.qr_code_rounded, size: 14),
                        label: Text('Aramayı Barkoda Kopyala', style: GoogleFonts.inter(fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Stok Kodu & Barkod
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: kodCtrl,
                        decoration: InputDecoration(
                          labelText: 'Stok Kodu',
                          prefixIcon: const Icon(Icons.qr_code_rounded),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: kodCtrl.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Stok kodu kopyalandı')),
                              );
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stok Adı
                TextField(
                  controller: adCtrl,
                  decoration: InputDecoration(
                    labelText: 'Stok Adı / Tanımı',
                    prefixIcon: const Icon(Icons.inventory_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Barkod & Otomatik Üret
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: barkodCtrl,
                        decoration: InputDecoration(
                          labelText: 'Barkod No',
                          prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setDialogState(() {
                          barkodCtrl.text = FunctionClass.barkodUret(selectedBarTur);
                        });
                      },
                      icon: const Icon(Icons.autorenew_rounded, size: 18),
                      label: Text('Üret ($selectedBarTur)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Birim & Barkod Türü
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedBirim,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Birim',
                          prefixIcon: const Icon(Icons.straighten_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ADET', child: Text('ADET', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'KG', child: Text('KG', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'METRE', child: Text('METRE', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'LITRE', child: Text('LİTRE', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'PAKET', child: Text('PAKET', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'KUTU', child: Text('KUTU', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'KOLI', child: Text('KOLİ', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedBirim = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedBarTur,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Barkod Türü',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'EAN13', child: Text('EAN13', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'EAN8', child: Text('EAN8', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'CODE128', child: Text('CODE128', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'TERAZİ', child: Text('TERAZİ', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedBarTur = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // KDV Dahil / Hariç & Yazar Kasa KDV
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedKdvDh,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'KDV Durumu',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Dahil', child: Text('KDV Dahil', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Hariç', child: Text('KDV Hariç', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedKdvDh = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_yazarKasaKdvList.isNotEmpty)
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: (selectedYkKdvIndex != null && selectedYkKdvIndex! >= 0 && selectedYkKdvIndex! < _yazarKasaKdvList.length)
                              ? selectedYkKdvIndex
                              : 0,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Y. Kasa KDV',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: List.generate(_yazarKasaKdvList.length, (index) {
                            final yk = _yazarKasaKdvList[index];
                            return DropdownMenuItem<int>(
                              value: index,
                              child: Text(
                                yk.adi.isNotEmpty ? yk.adi : '%${yk.oran.toStringAsFixed(0)} KDV',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedYkKdvIndex = val);
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Alış KDV Oranı & Satış KDV Oranı
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<double>(
                        initialValue: selectedAlKdv,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Alış KDV',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('%0')),
                          DropdownMenuItem(value: 1, child: Text('%1')),
                          DropdownMenuItem(value: 8, child: Text('%8')),
                          DropdownMenuItem(value: 10, child: Text('%10')),
                          DropdownMenuItem(value: 18, child: Text('%18')),
                          DropdownMenuItem(value: 20, child: Text('%20')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedAlKdv = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<double>(
                        initialValue: selectedSatKdv,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Satış KDV',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('%0')),
                          DropdownMenuItem(value: 1, child: Text('%1')),
                          DropdownMenuItem(value: 8, child: Text('%8')),
                          DropdownMenuItem(value: 10, child: Text('%10')),
                          DropdownMenuItem(value: 18, child: Text('%18')),
                          DropdownMenuItem(value: 20, child: Text('%20')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedSatKdv = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Alış Fiyatı & Satış Fiyatı
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: alisFiyatCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Alış Fiyatı (₺)',
                          prefixIcon: const Icon(Icons.shopping_cart_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: satisFiyatCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Satış Fiyatı (₺)',
                          prefixIcon: const Icon(Icons.sell_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Özel Fiyat 1 & Özel Fiyat 2
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ozelFiyat1Ctrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Özel Fiyat 1 (₺)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: ozelFiyat2Ctrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Özel Fiyat 2 (₺)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Kaydet / Güncelle Butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEditing ? AppTheme.orangeGradient.colors.first : AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(isEditing ? Icons.update_rounded : Icons.check_circle_rounded),
                    label: Text(
                      isEditing ? 'STOK KARTINI GÜNCELLE' : 'STOK KARTINI KAYDET',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () async {
                      if (kodCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lütfen stok kodunu giriniz.')),
                        );
                        return;
                      }
                      if (adCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lütfen stok adını giriniz.')),
                        );
                        return;
                      }

                      // Barkod Tipi Uzunluk Doğrulamaları
                      final barkodStr = barkodCtrl.text.trim();
                      if (selectedBarTur == 'EAN8' && barkodStr.isNotEmpty && barkodStr.length != 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('EAN8 barkodu 8 haneli olmalıdır.')),
                        );
                        return;
                      }
                      if (selectedBarTur == 'EAN13' && barkodStr.isNotEmpty && barkodStr.length != 13) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('EAN13 barkodu 13 haneli olmalıdır.')),
                        );
                        return;
                      }
                      if (selectedBarTur == 'TERAZİ' && barkodStr.isNotEmpty && (barkodStr.length < 5 || barkodStr.length > 6)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('TERAZİ barkodu 5 veya 6 haneli olmalıdır.')),
                        );
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(context);

                      final res = await ApiService.stokIslem(
                        komut: isEditing ? 1 : 2,
                        stokId: stokItem?.stokId ?? 0,
                        stokKodu: kodCtrl.text.trim(),
                        stokAdi: adCtrl.text.trim(),
                        barkod: barkodStr,
                        birim: selectedBirim,
                        kdv: selectedKdvDh,
                        alKdvOran: selectedAlKdv,
                        satKdvOran: selectedSatKdv,
                        alisFiyat: double.tryParse(alisFiyatCtrl.text.trim()) ?? 0,
                        satisFiyat: double.tryParse(satisFiyatCtrl.text.trim()) ?? 0,
                        oFiyat1: double.tryParse(ozelFiyat1Ctrl.text.trim()) ?? 0,
                        oFiyat2: double.tryParse(ozelFiyat2Ctrl.text.trim()) ?? 0,
                        barTur: selectedBarTur,
                        ykKod: (selectedYkKdvIndex != null && selectedYkKdvIndex! >= 0 && selectedYkKdvIndex! < _yazarKasaKdvList.length)
                            ? _yazarKasaKdvList[selectedYkKdvIndex!].kod
                            : '0',
                      );
                      nav.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(res.isNotEmpty ? 'İşlem Başarıyla Gerçekleştirildi' : 'Stok Kaydedildi'),
                          backgroundColor: AppTheme.accentGreen,
                        ),
                      );
                      _doSearch();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
