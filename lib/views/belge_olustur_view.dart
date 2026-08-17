import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/storage/save_settings.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/cari_secim_dialog.dart';
import '../widgets/depo_secim_dialog.dart';
import '../widgets/dynamic_island_toast.dart';
import 'urun_ekle_view.dart';

class BelgeOlusturView extends StatefulWidget {
  final String belgeTuru;

  const BelgeOlusturView({super.key, required this.belgeTuru});

  @override
  State<BelgeOlusturView> createState() => _BelgeOlusturViewState();
}

class _BelgeOlusturViewState extends State<BelgeOlusturView> {
  final _belgeNoController = TextEditingController();
  final _aciklamaController = TextEditingController();
  GetCari? _secilenCari;
  GetDepo? _cikisDepo;
  GetDepo? _varisDepo;
  bool _isLoadingNo = true;

  @override
  void initState() {
    super.initState();
    _initDepolar();
    _autoFetchBelgeNo();
  }

  void _initDepolar() {
    List<GetDepo> rawList = [];
    if (SaveSettings.tumDepolar.isNotEmpty) {
      rawList = SaveSettings.tumDepolar;
    } else if (SaveSettings.subeDepoList.isNotEmpty) {
      rawList = SaveSettings.subeDepoList.map((sd) => GetDepo(
        depoId: sd.depoId,
        depoAdi: sd.depoAdi,
        depoKodu: sd.depoKod,
        subeId: sd.subeId,
      )).toList();
    } else if (SaveSettings.depoList.isNotEmpty) {
      rawList = SaveSettings.depoList;
    }

    if (rawList.isEmpty && SaveSettings.depoId > 0) {
      rawList = [
        GetDepo(
          depoId: SaveSettings.depoId,
          depoAdi: SaveSettings.depoAdi.isNotEmpty ? SaveSettings.depoAdi : 'Varsayılan Depo',
          depoKodu: '',
          subeId: SaveSettings.subeId,
        )
      ];
    }

    final Map<int, GetDepo> map = {};
    for (final d in rawList) {
      map[d.depoId] = d;
    }
    final list = map.values.toList();

    if (list.isNotEmpty) {
      _cikisDepo = list.firstWhere(
        (d) => d.depoId == SaveSettings.depoId,
        orElse: () => list.first,
      );
      _varisDepo = list.length > 1 ? list[1] : list.first;
    }
  }

  String _getTitle() {
    switch (widget.belgeTuru) {
      case 'SAYIM':
        return 'Depo Sayım Fişi';
      case 'MALKABUL':
        return 'Mal Kabul Belgesi';
      case 'TRANSFER':
        return 'Depolar Arası Transfer';
      case 'SEVK_ISTEK':
        return 'Depo Sevk İstek';
      case 'SEVK_IADE_ISTEK':
        return 'Depo İade İstek';
      case 'ALIS_IADE':
        return 'Alış İadesi Belgesi';
      case 'SATIS_IADE':
        return 'Satış İadesi Kabul';
      case 'ALINAN_SIPARIS':
        return 'Alınan Sipariş Belgesi';
      case 'VERILEN_SIPARIS':
        return 'Verilen Sipariş Belgesi';
      case 'SATIS':
        return 'Satış Faturası';
      case 'KW_KARGO':
        return 'KW Kargo Sevk Belgesi';
      case 'AMBAR_ALIM':
        return 'Ambar Alım Belgesi';
      case 'AMBAR_GONDERIM':
        return 'Ambar Gönderim Belgesi';
      case 'SP_SEVK':
        return 'Sipariş Sevkiyat Belgesi';
      case 'SP_TESLIM':
        return 'Sipariş Teslimat Belgesi';
      default:
        return '${widget.belgeTuru} Belgesi';
    }
  }

  Future<void> _autoFetchBelgeNo() async {
    String prefix = 'DS';
    if (widget.belgeTuru == 'MALKABUL') prefix = 'MK';
    if (widget.belgeTuru == 'TRANSFER' || widget.belgeTuru == 'SEVK_ISTEK') prefix = 'DT';
    if (widget.belgeTuru == 'SEVK_IADE_ISTEK') prefix = 'DTI';
    if (widget.belgeTuru == 'ALIS_IADE') prefix = 'AI';
    if (widget.belgeTuru == 'SATIS_IADE') prefix = 'SI';
    if (widget.belgeTuru == 'ALINAN_SIPARIS' || widget.belgeTuru == 'SIPARIS') prefix = 'AS';
    if (widget.belgeTuru == 'VERILEN_SIPARIS') prefix = 'VS';
    if (widget.belgeTuru == 'SATIS') prefix = 'ST';
    if (widget.belgeTuru == 'KW_KARGO') prefix = 'KW';
    if (widget.belgeTuru == 'AMBAR_ALIM') prefix = 'AA';
    if (widget.belgeTuru == 'AMBAR_GONDERIM') prefix = 'AG';
    if (widget.belgeTuru == 'SP_SEVK') prefix = 'SS';
    if (widget.belgeTuru == 'SP_TESLIM') prefix = 'ST';

    final no = await ApiService.getBelgeNo(prefix);
    if (!mounted) return;

    setState(() {
      if (no.isNotEmpty) {
        _belgeNoController.text = no;
      } else {
        _belgeNoController.text = '$prefix-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      }
      _isLoadingNo = false;
    });
  }

  void _cariSecDialog() async {
    final selected = await CariSecimDialog.show(context);
    if (selected != null) {
      setState(() {
        _secilenCari = selected;
        SaveSettings.secilenCariID = selected.cariId;
        SaveSettings.secilenCariAD = selected.cariAd;
      });
    }
  }

  Future<void> _devamEt() async {
    final isDepoSevk = widget.belgeTuru == 'TRANSFER' || widget.belgeTuru == 'SEVK_ISTEK' || widget.belgeTuru == 'SEVK_IADE_ISTEK';
    final needsCari = widget.belgeTuru == 'MALKABUL' ||
        widget.belgeTuru == 'SATIS' ||
        widget.belgeTuru == 'SIPARIS' ||
        widget.belgeTuru == 'ALIS_IADE' ||
        widget.belgeTuru == 'SATIS_IADE' ||
        widget.belgeTuru == 'ALINAN_SIPARIS' ||
        widget.belgeTuru == 'VERILEN_SIPARIS';
    
    if (_secilenCari == null && needsCari) {
      AppNotification.showWarning(
        context,
        'Lütfen işlem için geçerli bir Cari / Müşteri / Tedarikçi seçiniz.',
        title: 'Cari Seçilmedi',
      );
      return;
    }

    if (_cikisDepo == null) {
      AppNotification.showWarning(
        context,
        'Lütfen işlem yapılacak depoyu seçiniz.',
        title: 'Depo Seçilmedi',
      );
      return;
    }

    if (isDepoSevk && _varisDepo == null) {
      AppNotification.showWarning(
        context,
        'Lütfen varış / hedef depoyu seçiniz.',
        title: 'Varış Deposu Seçilmedi',
      );
      return;
    }

    if (isDepoSevk && _cikisDepo!.depoId == _varisDepo!.depoId) {
      AppNotification.showWarning(
        context,
        'Çıkış deposu ile Varış deposu aynı olamaz!',
        title: 'Aynı Depo Hatası',
      );
      return;
    }

    if (_belgeNoController.text.trim().isEmpty) {
      AppNotification.showWarning(
        context,
        'Lütfen bir belge numarası giriniz.',
        title: 'Belge No Boş',
      );
      return;
    }

    if (_cikisDepo != null) {
      SaveSettings.depoId = _cikisDepo!.depoId;
      SaveSettings.depoAdi = _cikisDepo!.depoAdi;
    }
    if (_varisDepo != null) {
      SaveSettings.kontrolluDepoId = _varisDepo!.depoId;
      SaveSettings.kontrolluDepoAdi = _varisDepo!.depoAdi;
    }

    final int belgeTuruId = ApiService.mapBelgeTuruToNumericId(widget.belgeTuru);
    final activeDepoId = _cikisDepo?.depoId ?? SaveSettings.depoId;
    final activeCariId = _secilenCari?.cariId ?? 0;
    final varisDepoId = _varisDepo?.depoId ?? 0;

    final res = await ApiService.belgeEkleDetailed(
      belgeTuru: belgeTuruId,
      belgeNo: _belgeNoController.text.trim(),
      aciklama: _aciklamaController.text.isNotEmpty
          ? _aciklamaController.text.trim()
          : '${widget.belgeTuru} - ${_secilenCari?.cariAd ?? (_cikisDepo != null ? "${_cikisDepo!.depoAdi} -> ${_varisDepo?.depoAdi ?? ''}" : "Genel")}',
      cariId: activeCariId,
      depoId: activeDepoId,
      subeId: SaveSettings.subeId,
      oPlan: isDepoSevk ? varisDepoId : 0,
      varisDepo: isDepoSevk ? 0 : varisDepoId,
      parametre: widget.belgeTuru == 'SEVK_IADE_ISTEK' ? 1 : (isDepoSevk ? 1 : 0),
    );

    final fisId = res['id'] as int? ?? 0;
    final isSuccess = res['success'] as bool? ?? false;

    if (!mounted) return;

    if (!isSuccess || fisId <= 0) {
      final errorMsg = res['mesaj']?.toString().isNotEmpty == true
          ? res['mesaj'].toString()
          : (res['durum'] == 2
              ? 'Bu belge numarası (${_belgeNoController.text.trim()}) başka bir evrakta kullanılmış!'
              : 'Belge oluşturulamadı. Lütfen depo seçimlerini ve bağlantınızı kontrol ediniz.');
      AppNotification.showError(
        context,
        errorMsg,
        title: 'Belge Oluşturulamadı',
      );
      return;
    }

    AppNotification.showSuccess(
      context,
      '#${_belgeNoController.text.trim()} numaralı belge başarıyla açıldı.',
      title: 'Belge Oluşturuldu',
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UrunEkleView(
          belgeTuru: widget.belgeTuru,
          belgeNo: _belgeNoController.text.trim(),
          cariAdi: _secilenCari?.cariAd ?? (_cikisDepo != null ? '${_cikisDepo!.depoAdi} -> ${_varisDepo?.depoAdi ?? ""}' : 'Genel Depo'),
          cariId: activeCariId,
          depoId: activeDepoId,
          varisDepoId: varisDepoId,
          belgeId: fisId,
        ),
      ),
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    List<GetDepo> rawDepoListesi = [];
    if (SaveSettings.tumDepolar.isNotEmpty) {
      rawDepoListesi = SaveSettings.tumDepolar;
    } else if (SaveSettings.subeDepoList.isNotEmpty) {
      rawDepoListesi = SaveSettings.subeDepoList.map((sd) => GetDepo(
        depoId: sd.depoId,
        depoAdi: sd.depoAdi,
        depoKodu: sd.depoKod,
        subeId: sd.subeId,
      )).toList();
    } else if (SaveSettings.depoList.isNotEmpty) {
      rawDepoListesi = SaveSettings.depoList;
    }

    if (rawDepoListesi.isEmpty && SaveSettings.depoId > 0) {
      rawDepoListesi = [
        GetDepo(
          depoId: SaveSettings.depoId,
          depoAdi: SaveSettings.depoAdi.isNotEmpty ? SaveSettings.depoAdi : 'Varsayılan Depo',
          depoKodu: '',
          subeId: SaveSettings.subeId,
        )
      ];
    }

    final Map<int, GetDepo> uniqueMap = {};
    for (final d in rawDepoListesi) {
      uniqueMap[d.depoId] = d;
    }
    final depoListesi = uniqueMap.values.toList();

    if (depoListesi.isNotEmpty) {
      _cikisDepo ??= depoListesi.firstWhere(
        (d) => d.depoId == SaveSettings.depoId,
        orElse: () => depoListesi.first,
      );
      _varisDepo ??= depoListesi.length > 1 ? depoListesi[1] : depoListesi.first;
    }
    final isTransfer = widget.belgeTuru == 'TRANSFER' || widget.belgeTuru == 'SEVK_ISTEK' || widget.belgeTuru == 'SEVK_IADE_ISTEK';
    final needsCari = widget.belgeTuru == 'MALKABUL' ||
        widget.belgeTuru == 'SATIS' ||
        widget.belgeTuru == 'SIPARIS' ||
        widget.belgeTuru == 'ALIS_IADE' ||
        widget.belgeTuru == 'SATIS_IADE' ||
        widget.belgeTuru == 'ALINAN_SIPARIS' ||
        widget.belgeTuru == 'VERILEN_SIPARIS';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Belge Bilgileri', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _belgeNoController,
                      decoration: InputDecoration(
                        labelText: 'Belge Numarası',
                        prefixIcon: const Icon(Icons.numbers_rounded),
                        suffixIcon: _isLoadingNo
                            ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                            : IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _autoFetchBelgeNo),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (depoListesi.isNotEmpty) ...[
                      if (isTransfer) ...[
                        InkWell(
                          onTap: () async {
                            final selected = await DepoSecimDialog.show(context, depoListesi, title: 'Çıkış Deposu');
                            if (selected != null) {
                              setState(() => _cikisDepo = selected);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.output_rounded, color: AppTheme.accentOrange),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _cikisDepo != null ? _cikisDepo!.depoAdi : 'Çıkış Deposu Seçin',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: _cikisDepo != null ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_drop_down_circle_outlined, color: AppTheme.primaryBlue),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final selected = await DepoSecimDialog.show(context, depoListesi, title: 'Varış / Hedef Depo');
                            if (selected != null) {
                              setState(() => _varisDepo = selected);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.input_rounded, color: AppTheme.accentGreen),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _varisDepo != null ? _varisDepo!.depoAdi : 'Varış / Hedef Depo Seçin',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: _varisDepo != null ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_drop_down_circle_outlined, color: AppTheme.primaryBlue),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        InkWell(
                          onTap: () async {
                            final label = widget.belgeTuru == 'SAYIM' ? 'Sayım Deposu' : 'Depo';
                            final selected = await DepoSecimDialog.show(context, depoListesi, title: label);
                            if (selected != null) {
                              setState(() => _cikisDepo = selected);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.store_rounded, color: AppTheme.primaryBlue),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _cikisDepo != null ? _cikisDepo!.depoAdi : (widget.belgeTuru == 'SAYIM' ? 'Sayım Deposu Seçin' : 'Depo Seçin'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: _cikisDepo != null ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_drop_down_circle_outlined, color: AppTheme.primaryBlue),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],

                    if (needsCari) ...[
                      InkWell(
                        onTap: _cariSecDialog,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _secilenCari != null ? _secilenCari!.cariAd : 'Cari / Müşteri / Tedarikçi Seçin',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: _secilenCari != null ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_drop_down_circle_outlined, color: AppTheme.primaryBlue),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextField(
                      controller: _aciklamaController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama / Fiş Notu',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  'ÜRÜN EKLEMEYE GEÇ',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _devamEt,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

