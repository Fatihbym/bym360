import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/baski_onizleme_dialog.dart';
import '../widgets/dynamic_island_toast.dart';
import 'belge_kapat_view.dart';
import 'urun_ekle_view.dart';
import '../l10n/app_localizations.dart';

class BelgeDetayView extends StatefulWidget {
  final int belgeId;
  final String belgeNo;
  final String belgeTuru;
  final int belgeTurId;
  final String cariAdi;
  final String tarih;
  final double genelToplam;

  const BelgeDetayView({
    super.key,
    required this.belgeId,
    required this.belgeNo,
    required this.belgeTuru,
    required this.belgeTurId,
    required this.cariAdi,
    required this.tarih,
    required this.genelToplam,
  });

  @override
  State<BelgeDetayView> createState() => _BelgeDetayViewState();
}

class _BelgeDetayViewState extends State<BelgeDetayView> {
  final List<GetBelgeIcerik> _urunList = [];
  bool _isLoading = true;
  GetBelgeGetir? _belgeHeader;

  @override
  void initState() {
    super.initState();
    _loadDetay();
  }

  Future<void> _loadDetay() async {
    setState(() => _isLoading = true);
    final turId = widget.belgeTurId > 0
        ? widget.belgeTurId
        : ApiService.mapBelgeTuruToNumericId(widget.belgeTuru);
    
    // Fetch both document header and details
    final headerFuture = ApiService.belgeGetir(turId, widget.belgeId);
    final itemsFuture = ApiService.getBelgeDetay(turId, widget.belgeId);
    
    final results = await Future.wait([headerFuture, itemsFuture]);
    final header = results[0] as GetBelgeGetir?;
    final items = results[1] as List<GetBelgeIcerik>;

    if (mounted) {
      setState(() {
        _belgeHeader = header;
        _urunList.clear();
        _urunList.addAll(items);
        _isLoading = false;
      });
    }
  }

  void _showBaskiOnizleme() {
    double total = 0.0;
    for (final item in _urunList) {
      total += item.tutar > 0 ? item.tutar : (item.birimFiyat * item.miktar);
    }
    final netTotal = total > 0 ? total : widget.genelToplam;

    BaskiOnizlemeDialog.showBelge(
      context: context,
      belgeNo: widget.belgeNo.isNotEmpty ? widget.belgeNo : '#${widget.belgeId}',
      belgeTuru: widget.belgeTuru,
      cariAdi: widget.cariAdi,
      tarih: widget.tarih,
      genelToplam: netTotal,
      urunler: _urunList,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Belge Detay ${widget.belgeNo.isNotEmpty ? '- ${widget.belgeNo}' : '#${widget.belgeId}'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Baskı Önizleme ve Yazdır',
            onPressed: _showBaskiOnizleme,
          ),
          PopupMenuButton<String>(
            onSelected: (val) async {
              switch (val) {
                case 'onay':
                  final turId = widget.belgeTurId > 0
                      ? widget.belgeTurId
                      : ApiService.mapBelgeTuruToNumericId(widget.belgeTuru);
                  final res = await ApiService.belgeOnay(tur: turId, id: widget.belgeId);
                  if (!mounted) return;
                  if (res['success'] == true) {
                    AppNotification.showSuccess(
                      this.context,
                      res['message'] ?? 'Belge onaylandı',
                      title: 'İşlem Başarılı',
                    );
                    _loadDetay();
                  } else {
                    AppNotification.showError(
                      this.context,
                      res['message'] ?? 'Belge onaylanamadı!',
                      title: 'İşlem Başarısız',
                    );
                  }
                  break;
                case 'iptal':
                  final turId = widget.belgeTurId > 0
                      ? widget.belgeTurId
                      : ApiService.mapBelgeTuruToNumericId(widget.belgeTuru);
                  final res = await ApiService.belgeOnayIptal(tur: turId, id: widget.belgeId);
                  if (!mounted) return;
                  if (res['success'] == true) {
                    AppNotification.showSuccess(
                      this.context,
                      res['message'] ?? 'Belge onay iptal edildi',
                      title: 'İşlem Başarılı',
                    );
                    _loadDetay();
                  } else {
                    AppNotification.showError(
                      this.context,
                      res['message'] ?? 'Onay iptal işlemi başarısız!',
                      title: 'İşlem Başarısız',
                    );
                  }
                  break;
                case 'yazdir':
                  _showBaskiOnizleme();
                  break;
                case 'kapat':
                  Navigator.push(
                    this.context,
                    MaterialPageRoute(
                      builder: (context) => BelgeKapatView(
                        initialBelge: GetBelgeListele(
                          belgeId: widget.belgeId,
                          belgeNo: widget.belgeNo,
                          belgeTuru: 1,
                          belgeTurAdi: widget.belgeTuru,
                          cariAdi: widget.cariAdi,
                          tarih: widget.tarih,
                          genelToplam: widget.genelToplam,
                          aciklama: '${widget.belgeTuru} - ${widget.cariAdi}',
                        ),
                      ),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'onay', child: Text(context.tr('belge_onay', 'Belge Onay'))),
              PopupMenuItem(value: 'iptal', child: Text(context.tr('onay_iptal', 'Onay İptal'))),
              PopupMenuItem(value: 'yazdir', child: Text(context.tr('belge_onizle_yazdir', 'Belge Önizle & Yazdır'))),
              PopupMenuItem(value: 'kapat', child: Text(context.tr('belge_kapat_tahsilat', 'Belge Kapat / Tahsilat'))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Belge Header Info
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryBlue.withValues(alpha: 0.06),
            child: Column(
              children: [
                if (_belgeHeader?.onay == 1) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.5), width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'ONAYLI BELGE (DÜZENLENEMEZ)',
                            style: GoogleFonts.outfit(
                              color: AppTheme.accentGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                _infoRow('Belge No', widget.belgeNo.isNotEmpty ? widget.belgeNo : '#${widget.belgeId}'),
                _infoRow('Belge Türü', widget.belgeTuru),
                _infoRow('Cari', widget.cariAdi.isNotEmpty ? widget.cariAdi : '-'),
                _infoRow('Tarih', widget.tarih.isNotEmpty ? widget.tarih : '-'),
                _infoRow('Genel Toplam', '₺${widget.genelToplam.toStringAsFixed(2)}'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Ürün Listesi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${context.tr('urun_satirlari', 'Ürün Satırları')} (${_urunList.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${context.tr('toplam_miktar', 'Toplam Miktar')}: ${_urunList.fold<double>(0, (s, e) => s + e.miktar).toStringAsFixed(0)}'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _urunList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(context.tr('belgede_urun_yok', 'Bu belgede henüz ürün yok.'),
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _urunList.length,
                        itemBuilder: (listCtx, index) {
                          final item = _urunList[index];
                          final stokTitle = item.stokAdi.isNotEmpty
                              ? item.stokAdi
                              : (item.stokKodu.isNotEmpty ? item.stokKodu : 'Ürün Satırı #${index + 1}');

                          final turId = widget.belgeTurId > 0
                              ? widget.belgeTurId
                              : ApiService.mapBelgeTuruToNumericId(widget.belgeTuru);

                          return Dismissible(
                            key: ValueKey(item.satirId != 0 ? item.satirId : index),
                            background: Container(
                              color: AppTheme.accentRed,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                            ),
                            direction: _belgeHeader?.onay == 1 ? DismissDirection.none : DismissDirection.endToStart,
                            confirmDismiss: (_) => _silSatir(item, stokTitle, turId),
                            child: Card(
                              child: ListTile(
                                title: Text(stokTitle,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${item.barkod.isNotEmpty ? item.barkod : item.stokKodu}  |  ${item.miktar % 1 == 0 ? item.miktar.toInt() : item.miktar} ${item.birim}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₺${item.birimFiyat.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 13)),
                                    Text('₺${item.tutar.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.accentGreen)),
                                  ],
                                ),
                                onTap: _belgeHeader?.onay == 1
                                    ? () {
                                        AppNotification.showWarning(
                                          this.context,
                                          'Onaylı belgelerde değişiklik yapılamaz.',
                                          title: 'Belge Onaylı',
                                        );
                                      }
                                    : () => _showSatirGuncelleDialog(item),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: _belgeHeader?.onay == 1
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  this.context,
                  MaterialPageRoute(
                    builder: (context) => UrunEkleView(
                      belgeTuru: widget.belgeTuru,
                      belgeNo: widget.belgeNo,
                      cariAdi: widget.cariAdi,
                      belgeId: widget.belgeId,
                    ),
                  ),
                );
                _loadDetay();
              },
              icon: const Icon(Icons.add),
              label: Text(context.tr('urun_ekle', 'ÜRÜN EKLE'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              backgroundColor: AppTheme.primaryBlue,
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Future<bool> _silSatir(GetBelgeIcerik item, String stokTitle, int turId) async {
    if (_belgeHeader?.onay == 1) {
      AppNotification.showWarning(
        context,
        context.tr('onayli_belge_satir_silinemez', 'Onaylı belgelerde satır silinemez.'),
        title: context.tr('belge_onayli', 'Belge Onaylı'),
      );
      return false;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('satir_silinsin_mi', 'Satır Silinsin mi?')),
        content: Text('$stokTitle ${context.tr('satir_belgeden_silinecek', 'satırı belgeden silinecektir.')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('vazgec', 'Vazgeç'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('sil', 'Sil')),
          ),
        ],
      ),
    );

    if (confirm != true) return false;

    final success = await ApiService.urunSil(
      belgeId: widget.belgeId,
      belgeTuru: turId,
      satir: item.satirId,
      stokId: item.stokId,
      miktar: item.miktar,
    );

    if (!mounted) return false;

    if (success) {
      AppNotification.showSuccess(context, '$stokTitle belgeden silindi.');
      _loadDetay();
      return true;
    } else {
      AppNotification.showError(context, '$stokTitle silinemedi!');
      return false;
    }
  }

  void _showSatirGuncelleDialog(GetBelgeIcerik item) {
    if (_belgeHeader?.onay == 1) {
      AppNotification.showWarning(
        context,
        'Onaylı belgelerde değişiklik yapılamaz.',
        title: 'Belge Onaylı',
      );
      return;
    }
    final miktarCtrl = TextEditingController(
      text: item.miktar % 1 == 0 ? item.miktar.toInt().toString() : item.miktar.toString(),
    );
    final fiyatCtrl = TextEditingController(text: item.birimFiyat.toStringAsFixed(2));
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (sbCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: AppTheme.primaryBlue, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Satır Güncelle',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.stokAdi.isNotEmpty ? item.stokAdi : item.stokKodu,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.barkod.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Barkod: ${item.barkod}',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: miktarCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Miktar (${item.birim})',
                  prefixIcon: const Icon(Icons.numbers_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fiyatCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Birim Fiyat (₺)',
                  prefixIcon: const Icon(Icons.currency_lira_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: Text(context.tr('iptal', 'İptal')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final newMiktar = double.tryParse(miktarCtrl.text.trim().replaceAll(',', '.')) ?? item.miktar;
                      final newFiyat = double.tryParse(fiyatCtrl.text.trim().replaceAll(',', '.')) ?? item.birimFiyat;

                      if (newMiktar <= 0) {
                        AppNotification.showWarning(context, context.tr('gecersiz_miktar_mesaj', 'Lütfen 0\'dan büyük bir miktar giriniz.'), title: context.tr('gecersiz_miktar', 'Geçersiz Miktar'));
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      final turId = widget.belgeTurId > 0
                          ? widget.belgeTurId
                          : ApiService.mapBelgeTuruToNumericId(widget.belgeTuru);

                      final success = await ApiService.belgeSatirGuncelle(
                        belgeId: widget.belgeId,
                        belgeTuru: turId,
                        sira: item.satirId > 0 ? item.satirId : 1,
                        stokId: item.stokId,
                        miktar: newMiktar,
                        urunFiyat: newFiyat,
                        oldMiktar: item.miktar,
                        barkod: item.barkod,
                        kdvDh: 'D',
                        bFiyatYetki: true,
                      );

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                      if (!mounted) return;

                      if (success) {
                        await _loadDetay();
                        if (!mounted) return;
                        AppNotification.showSuccess(
                          context,
                          '${item.stokAdi} ${context.tr('satir_guncellendi', 'satırı başarıyla güncellendi.')}',
                          title: context.tr('satir_guncellendi_baslik', 'Satır Güncellendi'),
                        );
                      } else {
                        AppNotification.showError(
                          context,
                          context.tr('guncelleme_hatasi', 'Satır güncellenirken sunucudan hata alındı.'),
                          title: context.tr('guncelleme_basarisiz', 'Güncelleme Başarısız'),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(context.tr('kaydet', 'Kaydet')),
            ),
          ],
        ),
      ),
    );
  }
}
