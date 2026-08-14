import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/baski_onizleme_dialog.dart';
import '../widgets/dynamic_island_toast.dart';
import 'belge_kapat_view.dart';
import 'urun_ekle_view.dart';

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
    final items = await ApiService.getBelgeDetay(turId, widget.belgeId);
    if (mounted) {
      setState(() {
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
              final messenger = ScaffoldMessenger.of(context);
              switch (val) {
                case 'onay':
                  final res = await ApiService.belgeOnay(widget.belgeId);
                  messenger.showSnackBar(
                    SnackBar(content: Text(res ? 'Belge Onaylandı' : 'Belge onaylanamadı!')),
                  );
                  break;
                case 'iptal':
                  final res = await ApiService.belgeOnayIptal(widget.belgeId);
                  messenger.showSnackBar(
                    SnackBar(content: Text(res ? 'Belge Onay İptal Edildi' : 'İptal işlemi başarısız!')),
                  );
                  break;
                case 'yazdir':
                  _showBaskiOnizleme();
                  break;
                case 'kapat':
                  Navigator.push(
                    context,
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
              const PopupMenuItem(value: 'onay', child: Text('Belge Onay')),
              const PopupMenuItem(value: 'iptal', child: Text('Onay İptal')),
              const PopupMenuItem(value: 'yazdir', child: Text('Belge Önizle & Yazdır')),
              const PopupMenuItem(value: 'kapat', child: Text('Belge Kapat / Tahsilat')),
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
                Text('Ürün Satırları (${_urunList.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Toplam Miktar: ${_urunList.fold<double>(0, (s, e) => s + e.miktar).toStringAsFixed(0)}'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _urunList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Bu belgede henüz ürün yok.',
                                style: TextStyle(color: Colors.grey)),
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
                            direction: DismissDirection.endToStart,
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
                                onTap: () => _showSatirGuncelleDialog(item),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
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
        label: Text('ÜRÜN EKLE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Satır Silinsin mi?'),
        content: Text('$stokTitle satırı belgeden silinecektir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
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
              child: const Text('İptal'),
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
                        AppNotification.showWarning(context, 'Lütfen 0\'dan büyük bir miktar giriniz.', title: 'Geçersiz Miktar');
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
                          '${item.stokAdi} satırı başarıyla güncellendi.',
                          title: 'Satır Güncellendi',
                        );
                      } else {
                        AppNotification.showError(
                          context,
                          'Satır güncellenirken sunucudan hata alındı.',
                          title: 'Güncelleme Başarısız',
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
