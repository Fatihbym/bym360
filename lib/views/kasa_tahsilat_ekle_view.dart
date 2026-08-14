import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/storage/save_settings.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/baski_onizleme_dialog.dart';
import '../widgets/cari_secim_dialog.dart';

class KasaTahsilatEkleView extends StatefulWidget {
  const KasaTahsilatEkleView({super.key});

  @override
  State<KasaTahsilatEkleView> createState() => _KasaTahsilatEkleViewState();
}

class _KasaTahsilatEkleViewState extends State<KasaTahsilatEkleView> {
  GetCari? _selectedCari;
  double? _cariBakiye;
  bool _isLoadingBakiye = false;
  bool _isLoadingNo = true;
  bool _isSaving = false;

  final TextEditingController _belgeNoController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final String _selectedIslemTuru = 'Kasa Tahsilat Fişi (29)';
  
  GetSube? _selectedSube;
  GetSubeKasa? _selectedKasa;
  List<GetSubeKasa> _availableKasalar = [];

  void _previewMakbuz() {
    final tutarVal = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    BaskiOnizlemeDialog.showTahsilat(
      context: context,
      makbuzNo: _belgeNoController.text.isNotEmpty ? _belgeNoController.text : '#${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      cariAdi: _selectedCari?.cariAd ?? 'Genel Cari',
      islemTuru: 'Nakit Kasa Tahsilatı',
      tutar: tutarVal,
      kasaBankaAdi: _selectedKasa?.kasaAdi ?? 'Merkez Kasa',
      aciklama: _descController.text.trim(),
      tarih: _formatDate(_selectedDate),
    );
  }

  @override
  void initState() {
    super.initState();
    _initSubeAndKasa();
    _autoFetchBelgeNo();
  }

  List<GetSube> get _subeOptions {
    if (SaveSettings.subeList.isNotEmpty) {
      return SaveSettings.subeList;
    }
    return [
      GetSube(
        subeId: SaveSettings.subeId,
        subeAdi: SaveSettings.subeAdi.isNotEmpty ? SaveSettings.subeAdi : 'Merkez Şube',
        subeKodu: SaveSettings.subeKodu.isNotEmpty ? SaveSettings.subeKodu : '01',
      )
    ];
  }

  void _initSubeAndKasa() {
    final subeler = _subeOptions;
    _selectedSube = subeler.firstWhere(
      (s) => s.subeId == SaveSettings.subeId,
      orElse: () => subeler.first,
    );
    _updateKasalarForSube();
  }

  void _updateKasalarForSube() {
    final subeId = _selectedSube?.subeId ?? SaveSettings.subeId;
    if (SaveSettings.subeKasaList.isNotEmpty) {
      _availableKasalar = SaveSettings.subeKasaList.where((k) => k.subeId == subeId || k.subeId == 0).toList();
    }
    if (_availableKasalar.isEmpty && SaveSettings.subeKasaList.isNotEmpty) {
      _availableKasalar = SaveSettings.subeKasaList;
    }
    if (_availableKasalar.isNotEmpty) {
      _selectedKasa = _availableKasalar.firstWhere(
        (k) => k.kasaId == SaveSettings.kasaId,
        orElse: () => _availableKasalar.first,
      );
    }
  }

  Future<void> _autoFetchBelgeNo() async {
    setState(() => _isLoadingNo = true);
    final no = await ApiService.getBelgeNo('KT');
    if (!mounted) return;
    setState(() {
      if (no.isNotEmpty) {
        _belgeNoController.text = no;
      } else {
        _belgeNoController.text = 'KT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      }
      _isLoadingNo = false;
    });
  }

  @override
  void dispose() {
    _belgeNoController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectCari() async {
    final cari = await CariSecimDialog.show(context);
    if (cari != null) {
      setState(() {
        _selectedCari = cari;
        _cariBakiye = null;
        _isLoadingBakiye = true;
      });

      try {
        final bakiye = await ApiService.getCariBakiye(cari.cariId);
        if (mounted) {
          setState(() {
            _cariBakiye = bakiye;
            _isLoadingBakiye = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _cariBakiye = cari.bakiye;
            _isLoadingBakiye = false;
          });
        }
      }
    }
  }

  void _generateAutoDescription() {
    if (_selectedCari != null) {
      _descController.text = '${_selectedCari!.cariAd} - Yapılan Tahsilat İşlemi';
    } else {
      _descController.text = 'Nakit Kasa Tahsilat İşlemi';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day.$month.${dt.year}';
  }

  Future<void> _saveTahsilat() async {
    if (_selectedCari == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir cari müşteri seçiniz.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final tutarStr = _amountController.text.replaceAll(',', '.').trim();
    final tutar = double.tryParse(tutarStr);
    if (tutar == null || tutar <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tahsilat tutarı 0 olamaz.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await ApiService.kasaTahsil(
      subeId: _selectedSube?.subeId ?? SaveSettings.subeId,
      cariId: _selectedCari!.cariId,
      kasaId: _selectedKasa?.kasaId ?? SaveSettings.kasaId,
      tutar: tutar,
      tarih: _formatDate(_selectedDate),
      aciklama: _descController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kasa tahsilatı başarıyla kaydedildi!'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tahsilat kaydı başarısız oldu. Lütfen tekrar deneyin.'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nakit Kasa Tahsilatı Ekle', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Makbuz Önizle & Yazdır',
            onPressed: _previewMakbuz,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Cari Seçim Kartı
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cari Müşteri Seçimi',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        ElevatedButton.icon(
                          onPressed: _selectCari,
                          icon: const Icon(Icons.person_search_rounded, size: 18),
                          label: Text(_selectedCari == null ? 'Cari Seç' : 'Değiştir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (_selectedCari == null)
                      Text(
                        'Henüz cari seçilmedi. Lütfen yukarıdaki butona basarak müşteri seçiniz.',
                        style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                      )
                    else ...[
                      Text(
                        _selectedCari!.displayTitle,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.primaryBlue),
                      ),
                      if (_selectedCari!.displayUserOrAuthor.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.account_circle_rounded, size: 16, color: AppTheme.primaryBlue),
                            const SizedBox(width: 4),
                            Text(
                              'Yetkili: ${_selectedCari!.displayUserOrAuthor}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryBlue),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Cari Kod: ${_selectedCari!.cariKod.isNotEmpty ? _selectedCari!.cariKod : _selectedCari!.cariId}',
                            style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                          ),
                          if (_selectedCari!.gsm.isNotEmpty || _selectedCari!.telefon.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Text(
                              'Tel: ${_selectedCari!.gsm.isNotEmpty ? _selectedCari!.gsm : _selectedCari!.telefon}',
                              style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('GÜNCEL BAKİYE: ', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                          if (_isLoadingBakiye)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Text(
                              '₺${(_cariBakiye ?? 0.0).toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: (_cariBakiye ?? 0) >= 0 ? AppTheme.accentGreen : AppTheme.accentRed,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Form Kartı
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Belge Numarası
                    TextField(
                      controller: _belgeNoController,
                      decoration: InputDecoration(
                        labelText: 'Belge / Fiş Numarası',
                        prefixIcon: const Icon(Icons.numbers_rounded),
                        suffixIcon: _isLoadingNo
                            ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                            : IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _autoFetchBelgeNo),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // İşlem Türü
                    DropdownButtonFormField<String>(
                      initialValue: _selectedIslemTuru,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'Kasa Tahsilat Fişi (29)',
                          child: Text('Kasa Tahsilat Fişi (29)', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (val) {},
                      decoration: const InputDecoration(
                        labelText: 'İşlem Türü',
                        prefixIcon: Icon(Icons.receipt_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // İşlem Şubesi Seçimi
                    DropdownButtonFormField<GetSube>(
                      initialValue: _selectedSube,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'İşlem Şubesi',
                        prefixIcon: Icon(Icons.storefront_rounded, color: AppTheme.primaryBlue),
                      ),
                      items: _subeOptions.map((s) {
                        return DropdownMenuItem<GetSube>(
                          value: s,
                          child: Text(s.subeAdi, style: GoogleFonts.inter(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSube = val;
                            _updateKasalarForSube();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Kasa Seçimi
                    if (_availableKasalar.isNotEmpty) ...[
                      DropdownButtonFormField<GetSubeKasa>(
                        initialValue: _selectedKasa,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Kasa Hesabı',
                          prefixIcon: Icon(Icons.point_of_sale_rounded, color: AppTheme.accentGreen),
                        ),
                        items: _availableKasalar.map((k) {
                          return DropdownMenuItem<GetSubeKasa>(
                            value: k,
                            child: Text(k.kasaAdi, style: GoogleFonts.inter(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedKasa = val);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Tarih Seçimi
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'İşlem Tarihi',
                          prefixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDate(_selectedDate), style: GoogleFonts.inter(fontSize: 16)),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tutar Alanı
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentGreen),
                      decoration: const InputDecoration(
                        labelText: 'Tahsilat Tutarı (₺)',
                        prefixIcon: Icon(Icons.payments_rounded, color: AppTheme.accentGreen),
                        suffixText: 'TL',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fiş Açıklaması & Otomatik Oluştur Butonu
                    TextField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Fiş / Makbuz Açıklaması',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _generateAutoDescription,
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: Text('Otomatik Açıklama Oluştur', style: GoogleFonts.inter(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Kaydet Butonu
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveTahsilat,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _isSaving ? 'KAYDEDİLİYOR...' : 'KASA TAHSİLATINI KAYDET',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
