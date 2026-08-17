import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/storage/save_settings.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/baski_onizleme_dialog.dart';
import '../widgets/dynamic_island_toast.dart';

class BelgeKapatView extends StatefulWidget {
  final GetBelgeListele? initialBelge;
  const BelgeKapatView({super.key, this.initialBelge});

  @override
  State<BelgeKapatView> createState() => _BelgeKapatViewState();
}

class _BelgeKapatViewState extends State<BelgeKapatView> {
  List<GetBelgeKapatListe> _belgeler = [];
  List<GetBelgeKapatListe> _filteredBelgeler = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'satis', 'alis'
  bool _initialModalShown = false;

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
    final list = await ApiService.getBelgeKapatListe();
    
    // If opened with a specific initial document, ensure it is in the list
    if (widget.initialBelge != null) {
      final exists = list.any((b) => b.belgeId == widget.initialBelge!.belgeId);
      if (!exists) {
        list.insert(
          0,
          GetBelgeKapatListe(
            belgeId: widget.initialBelge!.belgeId,
            belgeNo: widget.initialBelge!.belgeNo,
            belgeTuru: widget.initialBelge!.belgeTuru,
            belgeTurAdi: widget.initialBelge!.belgeTurAdi,
            cariAdi: widget.initialBelge!.cariAdi,
            cariId: 0,
            tarih: widget.initialBelge!.tarih,
            genelToplam: widget.initialBelge!.genelToplam,
            durum: 'ACIK',
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _belgeler = list;
      _applyFilter();
      _isLoading = false;
    });

    // Auto-open modal if initialBelge was provided and not shown yet
    if (widget.initialBelge != null && !_initialModalShown && _belgeler.isNotEmpty) {
      _initialModalShown = true;
      final target = _belgeler.firstWhere(
        (b) => b.belgeId == widget.initialBelge!.belgeId,
        orElse: () => _belgeler.first,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showBelgeKapatModal(target);
        }
      });
    }
  }

  bool _checkIsAlis(GetBelgeKapatListe belge) {
    final t = belge.belgeTuru;
    if (t == 43 || t == 46 || t == 17 || t == 71 || t == 13 || t == 12 || t == 34) {
      return true;
    }
    final name = belge.belgeTurAdi.toLowerCase();
    return name.contains('alım') || name.contains('alis') || name.contains('kabul') || name.contains('tediye');
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredBelgeler = _belgeler.where((b) {
        final matchesQuery = query.isEmpty ||
            b.belgeNo.toLowerCase().contains(query) ||
            b.cariAdi.toLowerCase().contains(query) ||
            b.belgeTurAdi.toLowerCase().contains(query) ||
            b.belgeId.toString().contains(query);

        if (!matchesQuery) return false;

        final isAlis = _checkIsAlis(b);
        if (_selectedFilter == 'satis') return !isAlis;
        if (_selectedFilter == 'alis') return isAlis;
        return true;
      }).toList();
    });
  }

  void _showBelgeKapatModal(GetBelgeKapatListe belge) {
    final isAlis = _checkIsAlis(belge);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String selectedOdemeTuru = isAlis ? 'Kasa Tediye Fişi' : 'Kasa Tahsilat Fişi';
    DateTime selectedDate = DateTime.now();
    GetSube? selectedSube;
    GetSubeKasa? selectedKasa;
    GetSubeBanka? selectedBanka;

    if (SaveSettings.subeList.isNotEmpty) {
      selectedSube = SaveSettings.subeList.firstWhere(
        (s) => s.subeId == SaveSettings.subeId,
        orElse: () => SaveSettings.subeList.first,
      );
    }

    if (selectedSube != null) {
      final subeKasaList = SaveSettings.subeKasaList.where((k) => k.subeId == selectedSube!.subeId).toList();
      selectedKasa = subeKasaList.isNotEmpty ? subeKasaList.first : null;

      final subeBankaList = SaveSettings.subeBankaList.where((b) => b.subeId == selectedSube!.subeId).toList();
      selectedBanka = subeBankaList.isNotEmpty ? subeBankaList.first : null;
    }

    final tlController = TextEditingController(text: belge.genelToplam.toStringAsFixed(2));
    final aciklamaController = TextEditingController(
      text: 'No: ${belge.belgeNo} ${belge.belgeTurAdi} ${belge.cariAdi} Kapatma',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isKasa = selectedOdemeTuru.contains('Kasa');
          final filteredKasalar = SaveSettings.subeKasaList.where((k) => k.subeId == selectedSube?.subeId).toList();
          final filteredBankalar = SaveSettings.subeBankaList.where((b) => b.subeId == selectedSube?.subeId).toList();

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
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
                            isAlis ? Icons.outbox_rounded : Icons.payments_rounded,
                            color: isAlis ? AppTheme.accentOrange : AppTheme.accentGreen,
                            size: 26,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isAlis ? 'Belge Kapatma / Tediye' : 'Belge Kapatma / Tahsilat',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Belge & Cari Özet Bilgisi (Finansal Kart)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCardBorder.withValues(alpha: 0.5) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppTheme.darkCardBorder : Colors.grey.shade200,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 6,
                              color: isAlis ? AppTheme.accentOrange : AppTheme.accentGreen,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            belge.belgeNo.isNotEmpty ? belge.belgeNo : 'Belge #${belge.belgeId}',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              letterSpacing: 0.1,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: (isAlis ? AppTheme.accentOrange : AppTheme.accentGreen).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            belge.belgeTurAdi.isNotEmpty ? belge.belgeTurAdi : (isAlis ? 'Alış / Tediye' : 'Satış / Tahsilat'),
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isAlis ? AppTheme.accentOrange : AppTheme.accentGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    
                                    // Cari Satırı
                                    Row(
                                      children: [
                                        Icon(Icons.person_rounded, size: 15, color: Colors.grey.shade500),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            belge.cariAdi.isNotEmpty ? belge.cariAdi : "Tanımsız Cari",
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    
                                    // Tarih Satırı
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey.shade500),
                                        const SizedBox(width: 8),
                                        Text(
                                          belge.tarih.isNotEmpty ? belge.tarih : '-',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),
                                    
                                    // Kapatılacak Tutar
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Kapatılacak Tutar:',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          '₺${belge.genelToplam.toStringAsFixed(2)}',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: isAlis ? AppTheme.accentOrange : AppTheme.accentGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Tarih Seçimi
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'İşlem Tarihi',
                        prefixIcon: const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        DateFormat('dd.MM.yyyy').format(selectedDate),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Ödeme Türü Seçici
                  DropdownButtonFormField<String>(
                    initialValue: selectedOdemeTuru,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Ödeme / Kapatma Türü',
                      prefixIcon: const Icon(Icons.payment_rounded, color: AppTheme.primaryBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: isAlis
                        ? const [
                            DropdownMenuItem(value: 'Kasa Tediye Fişi', child: Text('Kasa Tediye Fişi (Nakit Çıkış)', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Kredi Kartı Alış', child: Text('Kredi Kartı Alış (Banka Çıkış)', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Banka Havale / EFT', child: Text('Banka Havale / EFT (Banka Çıkış)', overflow: TextOverflow.ellipsis)),
                          ]
                        : const [
                            DropdownMenuItem(value: 'Kasa Tahsilat Fişi', child: Text('Kasa Tahsilat Fişi (Nakit Giriş)', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Kredi Kartı Satış', child: Text('Kredi Kartı Satış (Banka POS)', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Banka Havale / EFT', child: Text('Banka Havale / EFT (Banka Giriş)', overflow: TextOverflow.ellipsis)),
                          ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedOdemeTuru = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // İşlem Şubesi Dropdown
                  if (SaveSettings.subeList.isNotEmpty) ...[
                    DropdownButtonFormField<GetSube>(
                      initialValue: selectedSube,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'İşlem Şubesi',
                        prefixIcon: const Icon(Icons.store_rounded, color: AppTheme.primaryBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: SaveSettings.subeList.map((s) {
                        return DropdownMenuItem<GetSube>(
                          value: s,
                          child: Text(s.displayTitle, style: GoogleFonts.inter(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedSube = val;
                            final subeKasaList = SaveSettings.subeKasaList.where((k) => k.subeId == val.subeId).toList();
                            selectedKasa = subeKasaList.isNotEmpty ? subeKasaList.first : null;

                            final subeBankaList = SaveSettings.subeBankaList.where((b) => b.subeId == val.subeId).toList();
                            selectedBanka = subeBankaList.isNotEmpty ? subeBankaList.first : null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Kasa veya Banka Seçimi
                  if (isKasa) ...[
                    if (filteredKasalar.isNotEmpty) ...[
                      DropdownButtonFormField<GetSubeKasa>(
                        initialValue: selectedKasa,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: isAlis ? 'Ödeme Kasası' : 'Tahsilat Kasası',
                          prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryBlue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: filteredKasalar.map((k) {
                          return DropdownMenuItem<GetSubeKasa>(
                            value: k,
                            child: Text(k.displayTitle, style: GoogleFonts.inter(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedKasa = val);
                        },
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          'Seçili şubeye ait kayıtlı kasa bulunamadı!',
                          style: GoogleFonts.inter(color: Colors.red.shade900, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ] else ...[
                    if (filteredBankalar.isNotEmpty) ...[
                      DropdownButtonFormField<GetSubeBanka>(
                        initialValue: selectedBanka,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Hesap / POS Bankası',
                          prefixIcon: const Icon(Icons.account_balance_rounded, color: AppTheme.primaryBlue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: filteredBankalar.map((b) {
                          return DropdownMenuItem<GetSubeBanka>(
                            value: b,
                            child: Text(b.displayTitle, style: GoogleFonts.inter(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedBanka = val);
                        },
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          'Seçili şubeye ait kayıtlı banka hesabı bulunamadı!',
                          style: GoogleFonts.inter(color: Colors.red.shade900, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],

                  // Kapatılacak Tutar (TL)
                  TextField(
                    controller: tlController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Kapatılacak Tutar (₺)',
                      prefixIcon: const Icon(Icons.currency_lira_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fiş Açıklaması & Otomatik Oluştur Butonu
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: aciklamaController,
                          decoration: InputDecoration(
                            labelText: 'Fiş Açıklaması',
                            prefixIcon: const Icon(Icons.notes_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () {
                          final seciliYer = isKasa ? (selectedKasa?.kasaAdi ?? '') : (selectedBanka?.bankaAdi ?? '');
                          aciklamaController.text = 'No: ${belge.belgeNo} ${belge.belgeTurAdi} ${belge.cariAdi} $seciliYer $selectedOdemeTuru';
                        },
                        icon: const Icon(Icons.autorenew_rounded),
                        tooltip: 'Otomatik Açıklama Oluştur',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Belgeyi Kapat / Tahsil Et Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAlis ? AppTheme.accentOrange : AppTheme.accentGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: Text(
                        isAlis ? 'BELGEYİ KAPAT / TEDİYE YAP' : 'BELGEYİ KAPAT / TAHSİL ET',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: () async {
                        final tutarVal = double.tryParse(tlController.text.trim().replaceAll(',', '.')) ?? 0.0;
                        if (tutarVal <= 0) {
                          AppNotification.showWarning(context, 'Lütfen geçerli bir tutar giriniz.', title: 'Geçersiz Tutar');
                          return;
                        }

                        if (isKasa) {
                          final kasaIdVal = selectedKasa?.kasaId ?? 0;
                          if (kasaIdVal <= 0) {
                            AppNotification.showWarning(context, 'Lütfen bir kasa seçiniz.', title: 'Kasa Seçilmedi');
                            return;
                          }
                        } else {
                          final bankaIdVal = selectedBanka?.bankaId ?? 0;
                          if (bankaIdVal <= 0) {
                            AppNotification.showWarning(context, 'Lütfen bir banka hesabı seçiniz.', title: 'Banka Seçilmedi');
                            return;
                          }
                        }

                        final nav = Navigator.of(modalCtx);
                        final tarihStr = DateFormat('yyyy-MM-dd').format(selectedDate);
                        final subeIdVal = selectedSube?.subeId ?? SaveSettings.subeId;

                        bool success = false;
                        if (isKasa) {
                          final kasaIdVal = selectedKasa?.kasaId ?? 0;
                          success = await ApiService.belgeTahsilKasa(
                            fatTur: belge.belgeTuru > 0 ? belge.belgeTuru : (isAlis ? 43 : 41),
                            fisId: belge.belgeId,
                            subeId: subeIdVal,
                            kasaId: kasaIdVal,
                            tutar: tutarVal,
                            cariId: belge.cariId,
                            fisAciklama: aciklamaController.text.trim(),
                            tarih: tarihStr,
                          );
                        } else {
                          final bankaIdVal = selectedBanka?.bankaId ?? 0;
                          success = await ApiService.belgeTahsilBanka(
                            fatTur: belge.belgeTuru > 0 ? belge.belgeTuru : (isAlis ? 43 : 41),
                            fisId: belge.belgeId,
                            subeId: subeIdVal,
                            bankaId: bankaIdVal,
                            tutar: tutarVal,
                            cariId: belge.cariId,
                            fisAciklama: aciklamaController.text.trim(),
                            tarih: tarihStr,
                          );
                        }

                        if (!success) {
                          success = await ApiService.belgeKapat(belge.belgeId);
                        }

                        if (!mounted) return;
                        nav.pop();

                        if (success) {
                          AppNotification.showSuccess(
                            context,
                            '${belge.belgeNo} Başarıyla Kapatıldı',
                            title: 'İşlem Başarılı',
                          );

                          // Ask to print makbuz
                          showDialog(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Makbuz Yazdır'),
                              content: const Text('Kapatma işlemi tamamlandı. Fiş/Makbuz yazdırmak ister misiniz?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  child: const Text('KAPAT'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentPurple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(dialogCtx);
                                    BaskiOnizlemeDialog.showTahsilat(
                                      context: context,
                                      makbuzNo: belge.belgeNo,
                                      cariAdi: belge.cariAdi,
                                      islemTuru: selectedOdemeTuru,
                                      tutar: tutarVal,
                                      kasaBankaAdi: isKasa ? (selectedKasa?.displayTitle ?? 'Kasa') : (selectedBanka?.displayTitle ?? 'Banka'),
                                      aciklama: aciklamaController.text.trim(),
                                      tarih: tarihStr,
                                    );
                                  },
                                  child: const Text('YAZDIR'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          AppNotification.showError(
                            context,
                            'Belge kapatılamadı!',
                            title: 'İşlem Başarısız',
                          );
                        }
                        _loadBelgeler();
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalAmount = _filteredBelgeler.fold<double>(0.0, (s, b) => s + b.genelToplam);

    return Scaffold(
      appBar: AppBar(
        title: Text('Belge Kapatma İşlemleri', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadBelgeler,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: isDark ? AppTheme.darkSurface : Colors.grey.shade100,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilter(),
                  decoration: InputDecoration(
                    hintText: 'Belge No veya Cari Adı ile ara...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilter();
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
                const SizedBox(height: 10),
                // Category Filter Chips
                Row(
                  children: [
                    _buildFilterChip('Tümü', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Satış / Tahsilat', 'satis'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Alış / Tediye', 'alis'),
                  ],
                ),
              ],
            ),
          ),
          
          // Stats Row
          if (!_isLoading && _filteredBelgeler.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredBelgeler.length} Açık Belge',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                  Text(
                    'Toplam: ₺${totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),

          // List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBelgeler.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_turned_in_outlined,
                                size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Kapatılacak açık belge bulunamadı.',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBelgeler,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredBelgeler.length,
                          separatorBuilder: (c, i) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final belge = _filteredBelgeler[index];
                            final isAlis = _checkIsAlis(belge);

                            return Container(
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkSurface : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                  color: isDark ? AppTheme.darkCardBorder : Colors.grey.shade100,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: () => _showBelgeKapatModal(belge),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Left color indicator representing transaction type
                                        Container(
                                          width: 6,
                                          color: isAlis ? AppTheme.accentOrange : AppTheme.accentGreen,
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(14.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    // Document No
                                                    Expanded(
                                                      child: Text(
                                                        belge.belgeNo.isNotEmpty ? belge.belgeNo : 'Belge #${belge.belgeId}',
                                                        style: GoogleFonts.outfit(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                          letterSpacing: 0.1,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // Document Type badge
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: (isAlis ? AppTheme.accentOrange : AppTheme.accentGreen).withValues(alpha: 0.12),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        belge.belgeTurAdi.isNotEmpty ? belge.belgeTurAdi : (isAlis ? 'Alış / Tediye' : 'Satış / Tahsilat'),
                                                        style: GoogleFonts.inter(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: isAlis ? AppTheme.accentOrange : AppTheme.accentGreen,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                // Client details
                                                Row(
                                                  children: [
                                                    Icon(Icons.person_rounded, size: 14, color: Colors.grey.shade500),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        belge.cariAdi.isNotEmpty ? belge.cariAdi : "Tanımsız Cari",
                                                        style: GoogleFonts.inter(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w500,
                                                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                const Divider(height: 1),
                                                const SizedBox(height: 10),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    // Date
                                                    Row(
                                                      children: [
                                                        Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade500),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          belge.tarih.isNotEmpty ? belge.tarih : '-',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 11,
                                                            color: Colors.grey.shade500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    // Balance and closing button
                                                    Row(
                                                      children: [
                                                        Text(
                                                          '₺${belge.genelToplam.toStringAsFixed(2)}',
                                                          style: GoogleFonts.outfit(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                            color: isAlis ? AppTheme.accentOrange : AppTheme.accentGreen,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            elevation: 0,
                                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                                            minimumSize: const Size(50, 30),
                                                            backgroundColor: isAlis ? AppTheme.accentOrange : AppTheme.accentGreen,
                                                            foregroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                          ),
                                                          onPressed: () => _showBelgeKapatModal(belge),
                                                          child: Text(
                                                            isAlis ? 'Tediye' : 'Kapat',
                                                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryBlue,
      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
          _applyFilter();
        });
      },
    );
  }
}
