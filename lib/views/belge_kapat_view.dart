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
    if (!mounted) return;
    setState(() {
      _belgeler = list;
      _filteredBelgeler = list;
      _isLoading = false;
    });
  }

  void _filter(String query) {
    if (query.isEmpty) {
      setState(() => _filteredBelgeler = _belgeler);
    } else {
      final q = query.toLowerCase().trim();
      setState(() {
        _filteredBelgeler = _belgeler.where((b) {
          return b.belgeNo.toLowerCase().contains(q) ||
              b.cariAdi.toLowerCase().contains(q) ||
              b.belgeId.toString().contains(q);
        }).toList();
      });
    }
  }

  void _showBelgeKapatModal(GetBelgeKapatListe belge) {
    final isAlis = belge.belgeTuru == 17 || belge.belgeTuru == 43 || belge.belgeTuru == 71 || belge.belgeTuru == 13 || belge.belgeTuru == 12;
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
                          const Icon(Icons.assignment_turned_in_rounded, color: AppTheme.primaryBlue, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            'Belge Kapatma / Tahsilat',
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
                                            belge.belgeTurAdi.isNotEmpty ? belge.belgeTurAdi : (isAlis ? 'Alış/Tediye' : 'Satış/Tahsilat'),
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isAlis ? AppTheme.accentOrange : AppTheme.accentGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Client Row
                                    Row(
                                      children: [
                                        Icon(Icons.person_rounded, size: 14, color: Colors.grey.shade500),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            belge.cariAdi.isNotEmpty ? belge.cariAdi : "Tanımsız Cari",
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    
                                    // Date Row
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey.shade500),
                                        const SizedBox(width: 8),
                                        Text(
                                          belge.tarih,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),
                                    
                                    // Total amount
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
                            DropdownMenuItem(value: 'Kasa Tediye Fişi', child: Text('Kasa Tediye Fişi (Nakit Output)', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Kredi Kartı Alış', child: Text('Kredi Kartı Alış (Banka Output)', overflow: TextOverflow.ellipsis)),
                          ]
                        : const [
                            DropdownMenuItem(value: 'Kasa Tahsilat Fişi', child: Text('Kasa Tahsilat Fişi (Nakit Giriş)', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Kredi Kartı Satış', child: Text('Kredi Kartı Satış (Banka POS)', overflow: TextOverflow.ellipsis)),
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
                            // Reset and filter kasa/banka to the first element of the new sube
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
                          labelText: 'Tahsilat Kasası',
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
                      prefixIcon: const Icon(Icons.attach_money_rounded),
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
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: Text(
                        'BELGEYİ KAPAT / TAHSİL ET',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: () async {
                        final tutarVal = double.tryParse(tlController.text.trim()) ?? 0.0;
                        if (tutarVal <= 0) {
                          AppNotification.showWarning(context, 'Lütfen geçerli bir tutar giriniz.', title: 'Geçersiz Tutar');
                          return;
                        }

                        if (isKasa) {
                          final kasaIdVal = selectedKasa?.kasaId ?? 0;
                          if (kasaIdVal <= 0) {
                            AppNotification.showWarning(context, 'Lütfen bir tahsilat kasası seçiniz.', title: 'Kasa Seçilmedi');
                            return;
                          }
                        } else {
                          final bankaIdVal = selectedBanka?.bankaId ?? 0;
                          if (bankaIdVal <= 0) {
                            AppNotification.showWarning(context, 'Lütfen bir hesap / POS bankası seçiniz.', title: 'Banka Seçilmedi');
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
                            fatTur: belge.belgeTuru,
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
                            fatTur: belge.belgeTuru,
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
          // Search Header Card
          Container(
            padding: const EdgeInsets.all(16.0),
            color: isDark ? AppTheme.darkSurface : Colors.grey.shade100,
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Belge No veya Cari Adı ile ara...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _filter('');
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
                            final isAlis = belge.belgeTuru == 17 || belge.belgeTuru == 43 || belge.belgeTuru == 71 || belge.belgeTuru == 13 || belge.belgeTuru == 12;

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
                                                        belge.belgeTurAdi.isNotEmpty ? belge.belgeTurAdi : (isAlis ? 'Alış/Tediye' : 'Satış/Tahsilat'),
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
                                                          belge.tarih,
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
                                                            color: AppTheme.primaryBlue,
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
                                                            'Kapat',
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
}
