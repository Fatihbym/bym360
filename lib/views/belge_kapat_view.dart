import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/storage/save_settings.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/baski_onizleme_dialog.dart';

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

    if (SaveSettings.subeKasaList.isNotEmpty) {
      selectedKasa = SaveSettings.subeKasaList.first;
    }
    if (SaveSettings.subeBankaList.isNotEmpty) {
      selectedBanka = SaveSettings.subeBankaList.first;
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isKasa = selectedOdemeTuru.contains('Kasa');

          return Padding(
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Belge & Cari Özet Bilgisi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Belge No: ${belge.belgeNo} (${belge.belgeTurAdi})',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryBlue),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cari: ${belge.cariAdi.isNotEmpty ? belge.cariAdi : "Tanımsız"} | Tarih: ${belge.tarih}',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kapatılacak Tutar: ₺${belge.genelToplam.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.accentGreen),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

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
                        if (val != null) setModalState(() => selectedSube = val);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Kasa veya Banka Seçimi
                  if (isKasa && SaveSettings.subeKasaList.isNotEmpty) ...[
                    DropdownButtonFormField<GetSubeKasa>(
                      initialValue: selectedKasa,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Tahsilat Kasası',
                        prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: SaveSettings.subeKasaList.map((k) {
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
                  ] else if (!isKasa && SaveSettings.subeBankaList.isNotEmpty) ...[
                    DropdownButtonFormField<GetSubeBanka>(
                      initialValue: selectedBanka,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Hesap / POS Bankası',
                        prefixIcon: const Icon(Icons.account_balance_rounded, color: AppTheme.primaryBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: SaveSettings.subeBankaList.map((b) {
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lütfen geçerli bir tutar giriniz.')),
                          );
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(context);
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
                            cariId: 0,
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
                            cariId: 0,
                            fisAciklama: aciklamaController.text.trim(),
                            tarih: tarihStr,
                          );
                        }

                        if (!success) {
                          // Fallback to direct belgeKapat API if specific tahsil endpoint yields false
                          success = await ApiService.belgeKapat(belge.belgeId);
                        }

                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(success ? '${belge.belgeNo} Başarıyla Kapatıldı' : 'İşlem Başarısız'),
                            backgroundColor: success ? AppTheme.accentGreen : AppTheme.accentRed,
                            action: success
                                ? SnackBarAction(
                                    label: 'Fiş Yazdır',
                                    textColor: Colors.white,
                                    onPressed: () {
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
                                  )
                                : null,
                          ),
                        );
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
                                  backgroundColor: AppTheme.accentPurple.withValues(alpha: 0.15),
                                  child: const Icon(Icons.receipt_long_rounded, color: AppTheme.accentPurple, size: 22),
                                ),
                                title: Text(
                                  belge.belgeNo.isNotEmpty ? belge.belgeNo : 'Belge #${belge.belgeId}',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Cari: ${belge.cariAdi.isNotEmpty ? belge.cariAdi : "Tanımsız"}\nTarih: ${belge.tarih}',
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                ),
                                isThreeLine: true,
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₺${belge.genelToplam.toStringAsFixed(2)}',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        minimumSize: const Size(60, 30),
                                        backgroundColor: AppTheme.accentGreen,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => _showBelgeKapatModal(belge),
                                      child: Text('Kapat', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
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
