import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/storage/save_settings.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/barcode_scanner_view.dart';
import '../widgets/dynamic_island_toast.dart';

class KontrolluSevkView extends StatefulWidget {
  final bool isGonderim;
  const KontrolluSevkView({super.key, this.isGonderim = true});

  @override
  State<KontrolluSevkView> createState() => _KontrolluSevkViewState();
}

class _KontrolluSevkViewState extends State<KontrolluSevkView> {
  GetDepo? _cikisDepo;
  GetDepo? _varisDepo;
  final TextEditingController _barkodController = TextEditingController();
  final TextEditingController _miktarController = TextEditingController(text: '1');
  final List<Map<String, dynamic>> _sevkKalemleri = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initDepolar();
  }

  void _initDepolar() {
    final list = SaveSettings.tumDepolar.isNotEmpty ? SaveSettings.tumDepolar : SaveSettings.depoList;
    if (list.isNotEmpty) {
      _cikisDepo = list.firstWhere(
        (d) => d.depoId == SaveSettings.depoId,
        orElse: () => list.first,
      );
      _varisDepo = list.length > 1 ? list[1] : list.first;
    }
  }

  Future<void> _urunEkle() async {
    final barkod = _barkodController.text.trim();
    final miktar = double.tryParse(_miktarController.text.trim()) ?? 1.0;
    if (barkod.isEmpty) return;

    String stokAdi = '';
    int stokId = 0;
    double fiyat = 0.0;
    try {
      final res = await ApiService.getStokAra(barkod);
      final valid = res.where((s) => s.stokId > 0 && s.stokAdi.isNotEmpty).toList();
      if (valid.isNotEmpty) {
        stokAdi = valid.first.stokAdi;
        stokId = valid.first.stokId;
        fiyat = valid.first.satisFiyat;
      }
    } catch (_) {}

    if (stokId <= 0) {
      if (mounted) {
        AppNotification.showError(
          context,
          'Girilen "$barkod" kodlu ürün veritabanında bulunamadı.',
          title: 'Ürün Bulunamadı',
        );
      }
      return;
    }

    final index = _sevkKalemleri.indexWhere((k) => k['barkod'] == barkod);
    setState(() {
      if (index >= 0) {
        _sevkKalemleri[index]['miktar'] = (_sevkKalemleri[index]['miktar'] as double) + miktar;
      } else {
        _sevkKalemleri.add({
          'stokId': stokId,
          'barkod': barkod,
          'stokAdi': stokAdi,
          'miktar': miktar,
          'fiyat': fiyat,
        });
      }
      _barkodController.clear();
      _miktarController.text = '1';
    });
  }

  Future<void> _cameraScan() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (scanned != null && scanned.isNotEmpty) {
      _barkodController.text = scanned;
      await _urunEkle();
    }
  }

  Future<void> _tamamla() async {
    if (_sevkKalemleri.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sevk kalemi eklenmedi!')),
      );
      return;
    }

    if (_cikisDepo != null && _varisDepo != null && _cikisDepo!.depoId == _varisDepo!.depoId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Çıkış deposu ile Varış deposu aynı olamaz!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final int belgeTuruId = widget.isGonderim ? 11 : 12;
    final String islemAdi = widget.isGonderim ? 'Kontrollü Sevk Gönderim' : 'Kontrollü Sevk Kabul';

    final belgeId = await ApiService.belgeEkle(
      belgeTuru: belgeTuruId,
      belgeNo: '',
      aciklama: '$islemAdi: ${_cikisDepo?.depoAdi ?? "Depo"} -> ${_varisDepo?.depoAdi ?? "Depo"}',
      cariId: 0,
      depoId: _cikisDepo?.depoId ?? SaveSettings.depoId,
      subeId: SaveSettings.subeId,
    );

    int successCount = 0;
    for (final item in _sevkKalemleri) {
      final res = await ApiService.urunEkle(
        belgeTuru: belgeTuruId.toString(),
        barkod: item['barkod'].toString(),
        belgeId: belgeId > 0 ? belgeId : 0,
        stokId: item['stokId'] ?? 0,
        miktar: (item['miktar'] as num).toDouble(),
        urunFiyat: (item['fiyat'] as num?)?.toDouble() ?? 0.0,
      );
      if (res) {
        successCount++;
      }
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.accentGreen,
          content: Text('$islemAdi başarıyla kaydedildi ($successCount/${_sevkKalemleri.length} kalem).'),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rawDepos = SaveSettings.tumDepolar.isNotEmpty ? SaveSettings.tumDepolar : SaveSettings.depoList;
    final Map<int, GetDepo> uniqueMap = {};
    for (final d in rawDepos) {
      uniqueMap[d.depoId] = d;
    }
    final depos = uniqueMap.values.toList();

    if (depos.isNotEmpty) {
      if (_cikisDepo == null || !depos.contains(_cikisDepo)) {
        _cikisDepo = depos.firstWhere(
          (d) => d.depoId == SaveSettings.depoId,
          orElse: () => depos.first,
        );
      }
      if (_varisDepo == null || !depos.contains(_varisDepo)) {
        _varisDepo = depos.length > 1 ? depos[1] : depos.first;
      }
    }
    final title = widget.isGonderim ? 'Kontrollü Depo Gönderim' : 'Kontrollü Depo Kabul';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: _cameraScan,
            tooltip: 'Kamera ile Tara',
          ),
        ],
      ),
      body: Column(
        children: [
          // Depo Seçimleri Card
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppTheme.darkSurface : Colors.white,
            child: Column(
              children: [
                if (depos.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<GetDepo>(
                          initialValue: _cikisDepo,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: widget.isGonderim ? 'Çıkış Deposu' : 'Kaynak Depo',
                            prefixIcon: const Icon(Icons.output_rounded, color: AppTheme.accentOrange),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          items: depos.map((d) {
                            return DropdownMenuItem<GetDepo>(
                              value: d,
                              child: Text(d.depoAdi, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _cikisDepo = val),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.0),
                        child: Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryBlue, size: 20),
                      ),
                      Expanded(
                        child: DropdownButtonFormField<GetDepo>(
                          initialValue: _varisDepo,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: widget.isGonderim ? 'Hedef Depo' : 'Varış Deposu',
                            prefixIcon: const Icon(Icons.input_rounded, color: AppTheme.accentGreen),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          items: depos.map((d) {
                            return DropdownMenuItem<GetDepo>(
                              value: d,
                              child: Text(d.depoAdi, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _varisDepo = val),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _barkodController,
                        onSubmitted: (_) => _urunEkle(),
                        decoration: InputDecoration(
                          hintText: 'Barkod Okutun veya Yazın...',
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
                      onPressed: _urunEkle,
                      child: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Sevk Kalemleri Listesi
          Expanded(
            child: _sevkKalemleri.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isGonderim ? Icons.outbox_rounded : Icons.inbox_rounded,
                          size: 64,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.isGonderim ? 'Sevk edilecek ürünleri barkod ile ekleyin.' : 'Teslim alınacak ürünleri barkod ile ekleyin.',
                          style: GoogleFonts.inter(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _sevkKalemleri.length,
                    itemBuilder: (context, index) {
                      final item = _sevkKalemleri[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: widget.isGonderim ? AppTheme.primaryBlue : AppTheme.accentGreen,
                            child: Icon(
                              widget.isGonderim ? Icons.inventory_2_rounded : Icons.move_to_inbox_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(item['stokAdi'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          subtitle: Text('Barkod: ${item["barkod"]}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.orange, size: 20),
                                onPressed: () {
                                  setState(() {
                                    if ((item['miktar'] as num) > 1) {
                                      item['miktar'] = (item['miktar'] as num) - 1;
                                    } else {
                                      _sevkKalemleri.removeAt(index);
                                    }
                                  });
                                },
                              ),
                              Text(
                                '${item["miktar"]}',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppTheme.accentGreen, size: 20),
                                onPressed: () {
                                  setState(() {
                                    item['miktar'] = (item['miktar'] as num) + 1;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.accentRed, size: 20),
                                onPressed: () => setState(() => _sevkKalemleri.removeAt(index)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppTheme.darkSurface : Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isGonderim ? AppTheme.primaryBlue : AppTheme.accentGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSaving ? null : _tamamla,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                label: Text(
                  _isSaving ? 'Kaydediliyor...' : (widget.isGonderim ? 'Sevkiyatı Tamamla' : 'Kabulü Tamamla'),
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
