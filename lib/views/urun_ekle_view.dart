import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/storage/save_settings.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/barcode_scanner_view.dart';
import '../widgets/dynamic_island_toast.dart';

class UrunEkleView extends StatefulWidget {
  final String belgeTuru;
  final String belgeNo;
  final String cariAdi;
  final int cariId;
  final int depoId;
  final int varisDepoId;
  final int? belgeId;

  const UrunEkleView({
    super.key,
    required this.belgeTuru,
    required this.belgeNo,
    required this.cariAdi,
    this.cariId = 0,
    this.depoId = 0,
    this.varisDepoId = 0,
    this.belgeId,
  });

  @override
  State<UrunEkleView> createState() => _UrunEkleViewState();
}

class _UrunEkleViewState extends State<UrunEkleView> {
  final _barcodeController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final List<GetUrunEkle> _addedProducts = [];
  bool _isSearching = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _barcodeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  int _getBelgeTuruId() {
    return ApiService.mapBelgeTuruToNumericId(widget.belgeTuru);
  }

  void _addProduct() async {
    final barcode = _barcodeController.text.trim();
    final qty = double.tryParse(_quantityController.text.trim()) ?? 1.0;

    if (barcode.isEmpty) {
      AppNotification.showWarning(
        context,
        context.tr('Lütfen bir barkod veya stok kodu giriniz.', 'Lütfen bir barkod veya stok kodu giriniz.'),
        title: context.tr('Barkod Boş', 'Barkod Boş'),
      );
      return;
    }

    setState(() => _isSearching = true);
    var results = await ApiService.getStokAra(barcode);

    if (results.isEmpty) {
      final fiyatGorList = await ApiService.getFiyatGor(barcode);
      if (fiyatGorList.isNotEmpty) {
        final fg = fiyatGorList.first;
        results = [
          GetStok(
            stokId: fg.stokId,
            stokAdi: fg.stokAdi,
            stokKodu: fg.stokKodu,
            barkod: fg.barkod.isNotEmpty ? fg.barkod : barcode,
            birim: fg.birim.isNotEmpty ? fg.birim : 'ADET',
            kdv: fg.kdv,
            satisFiyat: fg.satisFiyat,
            alisFiyat: fg.alisFiyat,
            bakiye: fg.kalan,
          ),
        ];
      }
    }
    setState(() => _isSearching = false);

    if (!mounted) return;

    if (results.isNotEmpty) {
      final stok = results.first;
      setState(() {
        final existingIndex = _addedProducts.indexWhere((p) => p.stokId == stok.stokId || p.barkod == barcode);
        if (existingIndex >= 0) {
          final existing = _addedProducts[existingIndex];
          _addedProducts[existingIndex] = GetUrunEkle(
            stokId: existing.stokId,
            stokAdi: existing.stokAdi,
            barkod: existing.barkod,
            miktar: existing.miktar + qty,
            fiyat: existing.fiyat,
          );
        } else {
          _addedProducts.add(
            GetUrunEkle(
              stokId: stok.stokId,
              stokAdi: stok.stokAdi,
              barkod: stok.barkod.isNotEmpty ? stok.barkod : barcode,
              miktar: qty,
              fiyat: stok.satisFiyat,
            ),
          );
        }
        _barcodeController.clear();
        _quantityController.text = '1';
      });
      AppNotification.showSuccess(
        context,
        '${stok.stokAdi} (${qty % 1 == 0 ? qty.toInt() : qty} adet) sepete eklendi.',
        title: 'Ürün Eklendi',
      );
    } else {
      AppNotification.showError(
        context,
        'Aranan "$barcode" kodu için ürün bulunamadı.',
        title: 'Ürün Bulunamadı',
      );
    }
  }

  double get _totalAmount {
    return _addedProducts.fold(0.0, (sum, p) => sum + (p.miktar * p.fiyat));
  }

  Future<void> _saveDocument() async {
    if (_addedProducts.isEmpty) return;

    setState(() => _isSaving = true);

    final int belgeTuruId = _getBelgeTuruId();
    final int activeDepoId = widget.depoId > 0 ? widget.depoId : SaveSettings.depoId;
    final int activeCariId = widget.cariId > 0 ? widget.cariId : SaveSettings.secilenCariID;

    int fisId = widget.belgeId ?? 0;
    if (fisId == 0) {
      final isDepoSevk = widget.belgeTuru == 'TRANSFER' || widget.belgeTuru == 'SEVK_ISTEK' || widget.belgeTuru == 'SEVK_IADE_ISTEK';
      fisId = await ApiService.belgeEkle(
        belgeTuru: belgeTuruId,
        belgeNo: widget.belgeNo,
        aciklama: '${widget.belgeTuru} - ${widget.cariAdi}',
        cariId: activeCariId,
        depoId: activeDepoId,
        subeId: SaveSettings.subeId,
        oPlan: isDepoSevk ? widget.varisDepoId : 0,
        varisDepo: isDepoSevk ? 0 : widget.varisDepoId,
        parametre: isDepoSevk ? 1 : 0,
      );
    }

    int savedItems = 0;
    for (final product in _addedProducts) {
      final success = await ApiService.urunEkle(
        belgeTuru: belgeTuruId.toString(),
        barkod: product.barkod,
        belgeId: fisId > 0 ? fisId : 0,
        stokId: product.stokId,
        miktar: product.miktar,
        urunFiyat: product.fiyat,
        depoId: activeDepoId,
        subeId: SaveSettings.subeId,
        cariId: activeCariId,
      );
      if (success) savedItems++;
    }

    setState(() => _isSaving = false);

    if (!mounted) return;

    AppNotification.showSuccess(
      context,
      '${context.tr("Belge Başarıyla Kaydedildi!", "Belge Başarıyla Kaydedildi!")} ($savedItems/${_addedProducts.length} ürün eklendi)',
      title: 'İşlem Başarılı',
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.belgeNo} - ${context.tr("Ürün Ekle", "Ürün Ekle")}'),
      ),
      body: Column(
        children: [
          // Barcode Scan Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? AppTheme.darkSurface : Colors.white,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _barcodeController,
                    onSubmitted: (_) => _addProduct(),
                    decoration: InputDecoration(
                      hintText: context.tr('Barkod Okutun...', 'Barkod Okutun...'),
                      prefixIcon: const Icon(Icons.qr_code_scanner),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.camera_alt_rounded, color: AppTheme.accentCyan),
                        onPressed: () async {
                          final code = await BarcodeScannerScreen.scan(context, title: context.tr('Ürün Barkod Tara', 'Ürün Barkod Tara'));
                          if (code != null && code.isNotEmpty) {
                            _barcodeController.text = code;
                            _addProduct();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(hintText: context.tr('Miktar', 'Miktar')),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSearching
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_circle, color: AppTheme.primaryBlue, size: 36),
                  onPressed: _isSearching ? null : _addProduct,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items List
          Expanded(
            child: _addedProducts.isEmpty
                ? Center(
                    child: Text(
                      context.tr('Henüz sepete ürün eklenmedi.', 'Henüz sepete ürün eklenmedi.'),
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _addedProducts.length,
                    itemBuilder: (context, index) {
                      final item = _addedProducts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(item.stokAdi, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Barkod: ${item.barkod} | Miktar: ${item.miktar}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₺${(item.miktar * item.fiyat).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGreen),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.accentRed),
                                onPressed: () => setState(() => _addedProducts.removeAt(index)),
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
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            border: Border(top: BorderSide(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${context.tr("Toplam Ürün", "Toplam Ürün")}: ${_addedProducts.length}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${context.tr("Tutar", "Tutar")}: ₺${_totalAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          color: AppTheme.accentGreen,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[300],
                  disabledForegroundColor: isDark ? Colors.white38 : Colors.grey[600],
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(
                  _isSaving ? context.tr('KAYDEDİLİYOR...', 'KAYDEDİLİYOR...') : context.tr('BELGEYİ KAYDET', 'BELGEYİ KAYDET'),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: (_addedProducts.isEmpty || _isSaving) ? null : _saveDocument,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

