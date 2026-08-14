import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/barcode_scanner_view.dart';
import '../widgets/baski_onizleme_dialog.dart';
import '../widgets/dynamic_island_toast.dart';

// ============================================================
// Tekli Etiket Yazdırma View (Activity_TekliEtiket.java)
// ============================================================
class TekliEtiketView extends StatefulWidget {
  final String? initialBarkod;
  const TekliEtiketView({super.key, this.initialBarkod});

  @override
  State<TekliEtiketView> createState() => _TekliEtiketViewState();
}

class _TekliEtiketViewState extends State<TekliEtiketView> {
  final _barcodeController = TextEditingController();
  final _miktarController = TextEditingController(text: '1');
  bool _hizliBasim = false;
  GetStok? _selectedStok;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialBarkod != null && widget.initialBarkod!.isNotEmpty) {
      _barcodeController.text = widget.initialBarkod!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchBarcode(widget.initialBarkod);
      });
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _miktarController.dispose();
    super.dispose();
  }

  Future<void> _searchBarcode([String? code]) async {
    final query = (code ?? _barcodeController.text).trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    final results = await ApiService.getStokAra(query);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (results.isNotEmpty) {
        _selectedStok = results.first;
        _barcodeController.text = results.first.barkod;

        if (_hizliBasim) {
          _yazdir();
        }
      } else {
        _selectedStok = null;
        AppNotification.showError(context, 'Aranan barkoda ait ürün bulunamadı.', title: 'Stok Bulunamadı');
      }
    });
  }

  void _yazdir() {
    if (_selectedStok == null) return;
    final miktarVal = int.tryParse(_miktarController.text.trim()) ?? 1;
    BaskiOnizlemeDialog.showEtiket(
      context: context,
      stoklar: [_selectedStok!],
      miktarlar: [miktarVal],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tekli Etiket Yazdırma', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Yazdır',
            onPressed: _selectedStok == null ? null : _yazdir,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Search & Quantity Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _barcodeController,
                      onSubmitted: (_) => _searchBarcode(),
                      decoration: InputDecoration(
                        labelText: 'Barkod veya Stok Kodu',
                        hintText: 'Barkod okutun veya kod yazın...',
                        prefixIcon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryBlue),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
                              onPressed: () => _searchBarcode(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.camera_alt_rounded, color: AppTheme.accentCyan),
                              onPressed: () async {
                                final code = await BarcodeScannerScreen.scan(context, title: 'Tekli Etiket Tara');
                                if (code != null && code.isNotEmpty) {
                                  _barcodeController.text = code;
                                  _searchBarcode(code);
                                }
                              },
                            ),
                          ],
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    if (!_hizliBasim) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _miktarController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Yazdırılacak Adet / Miktar',
                          prefixIcon: const Icon(Icons.copy_rounded, color: AppTheme.primaryBlue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _hizliBasim,
                      activeTrackColor: AppTheme.accentGreen,
                      title: Text('Hızlı Basım Modu', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      subtitle: Text('Barkod okutulduğu an otomatik 1 adet yazdır', style: GoogleFonts.inter(fontSize: 12)),
                      onChanged: (val) {
                        setState(() {
                          _hizliBasim = val;
                          if (val) {
                            _miktarController.text = '1';
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading) const Center(child: CircularProgressIndicator()),

            if (_selectedStok != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Ürün Bilgisi',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _infoRow('Stok Adı', _selectedStok!.stokAdi),
                    _infoRow('Stok Kodu', _selectedStok!.stokKodu),
                    _infoRow('Barkod', _selectedStok!.barkod),
                    _infoRow('Birim Fiyat', '₺${_selectedStok!.satisFiyati.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.print_rounded),
                label: Text(
                  'ETİKETİ YAZDIR',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: _selectedStok == null ? null : _yazdir,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Toplu Etiket Yazdırma View (Activity_TopluEtiket.java)
// ============================================================
class TopluEtiketView extends StatefulWidget {
  const TopluEtiketView({super.key});

  @override
  State<TopluEtiketView> createState() => _TopluEtiketViewState();
}

class _TopluEtiketViewState extends State<TopluEtiketView> {
  final _barcodeController = TextEditingController();
  final _miktarController = TextEditingController(text: '1');
  final List<GetTopluEtiket> _etiketList = [];

  @override
  void dispose() {
    _barcodeController.dispose();
    _miktarController.dispose();
    super.dispose();
  }

  Future<void> _addToList([String? code]) async {
    final query = (code ?? _barcodeController.text).trim();
    final miktarVal = int.tryParse(_miktarController.text.trim()) ?? 1;
    if (query.isEmpty) return;

    final results = await ApiService.getStokAra(query);
    if (!mounted) return;

    if (results.isNotEmpty) {
      final stok = results.first;
      setState(() {
        _etiketList.add(GetTopluEtiket(
          stokId: stok.stokId,
          stokKodu: stok.stokKodu,
          stokAdi: stok.stokAdi,
          barkod: stok.barkod,
          miktar: miktarVal,
        ));
        _barcodeController.clear();
        _miktarController.text = '1';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün bulunamadı!')),
      );
    }
  }

  Future<void> _yazdirToplu() async {
    if (_etiketList.isEmpty) return;

    final stoklar = _etiketList.map((e) => GetStok(
      stokId: e.stokId,
      stokKodu: e.stokKodu,
      stokAdi: e.stokAdi,
      barkod: e.barkod,
      birim: 'ADET',
      kdv: 20.0,
      satisFiyat: 0.0,
      alisFiyat: 0.0,
      bakiye: 0.0,
    )).toList();
    final miktarlar = _etiketList.map((e) => e.miktar).toList();

    BaskiOnizlemeDialog.showEtiket(
      context: context,
      stoklar: stoklar,
      miktarlar: miktarlar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Toplu Etiket Yazdırma', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Toplu Yazdır',
            onPressed: _etiketList.isEmpty ? null : _yazdirToplu,
          ),
        ],
      ),
      body: Column(
        children: [
          // Input Form Card
          Container(
            padding: const EdgeInsets.all(14.0),
            color: isDark ? AppTheme.darkSurface : Colors.white,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _barcodeController,
                    onSubmitted: (_) => _addToList(),
                    decoration: InputDecoration(
                      hintText: 'Barkod veya Stok Kodu',
                      prefixIcon: const Icon(Icons.qr_code, color: AppTheme.primaryBlue),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.camera_alt_rounded, color: AppTheme.accentCyan),
                        onPressed: () async {
                          final code = await BarcodeScannerScreen.scan(context, title: 'Toplu Etiket Tara');
                          if (code != null && code.isNotEmpty) {
                            _addToList(code);
                          }
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _miktarController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Adet',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  onPressed: () => _addToList(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Summary Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kuyruk: ${_etiketList.length} Kalem',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlue),
                ),
                Text(
                  'Toplam Adet: ${_etiketList.fold<int>(0, (s, e) => s + e.miktar)} Pcs',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.accentGreen),
                ),
              ],
            ),
          ),

          // Queue List
          Expanded(
            child: _etiketList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.label_off_outlined, size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'Yazdırılacak etiket kuyruğu boş.\nÜrün eklemek için barkod okutunuz.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _etiketList.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _etiketList[index];
                      return Material(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.15),
                            child: const Icon(Icons.label_rounded, color: AppTheme.accentOrange, size: 20),
                          ),
                          title: Text(
                            item.stokAdi,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Text('Barkod: ${item.barkod}  |  Kod: ${item.stokKodu}', style: GoogleFonts.inter(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('x${item.miktar}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentRed),
                                onPressed: () => setState(() => _etiketList.removeAt(index)),
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
    );
  }
}

// ============================================================
// Fiyatı Değişen Ürün Etiketi (Activity_FiyatiDegisenEtiket.java)
// ============================================================
class FiyatiDegisenEtiketView extends StatefulWidget {
  const FiyatiDegisenEtiketView({super.key});

  @override
  State<FiyatiDegisenEtiketView> createState() => _FiyatiDegisenEtiketViewState();
}

class _FiyatiDegisenEtiketViewState extends State<FiyatiDegisenEtiketView> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  List<GetTopluEtiket> _degisenUrunler = [];
  bool _isLoading = false;
  bool _selectAll = false;

  Future<void> _loadDegisenUrunler() async {
    setState(() => _isLoading = true);
    final basStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final bitStr = DateFormat('yyyy-MM-dd').format(_endDate);

    final list = await ApiService.getTopluEtiketTarih(basTarih: basStr, bitTarih: bitStr);
    if (!mounted) return;
    setState(() {
      _degisenUrunler = list;
      _isLoading = false;
    });
  }

  void _toggleSelectAll(bool? val) {
    final state = val ?? false;
    setState(() {
      _selectAll = state;
      for (var u in _degisenUrunler) {
        u.yazdir = state;
      }
    });
  }

  Future<void> _yazdirSecilenler() async {
    final secilenler = _degisenUrunler.where((u) => u.yazdir).toList();
    if (secilenler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen yazdırılacak ürünleri seçiniz.')),
      );
      return;
    }

    final stoklar = secilenler.map((e) => GetStok(
      stokId: e.stokId,
      stokKodu: e.stokKodu,
      stokAdi: e.stokAdi,
      barkod: e.barkod,
      birim: 'ADET',
      kdv: 20.0,
      satisFiyat: 0.0,
      alisFiyat: 0.0,
      bakiye: 0.0,
    )).toList();
    final miktarlar = secilenler.map((e) => e.miktar).toList();

    BaskiOnizlemeDialog.showEtiket(
      context: context,
      stoklar: stoklar,
      miktarlar: miktarlar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Çoklu Etiket Basımı', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Seçilenleri Yazdır',
            onPressed: _degisenUrunler.isEmpty ? null : _yazdirSecilenler,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Card
          Container(
            padding: const EdgeInsets.all(14),
            color: isDark ? AppTheme.darkSurface : Colors.grey.shade100,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2099),
                          );
                          if (picked != null) setState(() => _startDate = picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Başlangıç Tarihi',
                            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(DateFormat('dd.MM.yyyy').format(_startDate), style: GoogleFonts.inter(fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2099),
                          );
                          if (picked != null) setState(() => _endDate = picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Bitiş Tarihi',
                            prefixIcon: const Icon(Icons.calendar_month_rounded, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(DateFormat('dd.MM.yyyy').format(_endDate), style: GoogleFonts.inter(fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                      icon: const Icon(Icons.search_rounded),
                      onPressed: _loadDegisenUrunler,
                      tooltip: 'Listele',
                    ),
                  ],
                ),
                if (_degisenUrunler.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _selectAll,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Tümünü Seç / İptal Et (${_degisenUrunler.length} Ürün)', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    onChanged: _toggleSelectAll,
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // List Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _degisenUrunler.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.price_change_outlined, size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Seçilen tarihler arasında fiyatı değişen ürün bulunamadı.',
                              style: GoogleFonts.inter(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _degisenUrunler.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _degisenUrunler[index];
                          return Material(
                            color: isDark ? AppTheme.darkSurface : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                            ),
                            child: CheckboxListTile(
                              value: item.yazdir,
                              onChanged: (val) {
                                setState(() {
                                  item.yazdir = val ?? false;
                                });
                              },
                              title: Text(item.stokAdi, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                              subtitle: Text('Barkod: ${item.barkod}  |  Kod: ${item.stokKodu}', style: GoogleFonts.inter(fontSize: 12)),
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

// ============================================================
// Etiket Seçim View (Activity_EtiketSecim.java)
// ============================================================
class EtiketSecimView extends StatelessWidget {
  const EtiketSecimView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Etiket İşlemleri', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildOptionCard(
            context,
            title: 'Tekli Etiket Basımı',
            icon: Icons.inventory_2_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF2DD4BF), Color(0xFF0D9488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TekliEtiketView()));
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context,
            title: 'Çoklu Etiket Basımı',
            icon: Icons.inventory_2_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF2DD4BF), Color(0xFF0D9488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FiyatiDegisenEtiketView()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        gradient: gradient,
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
