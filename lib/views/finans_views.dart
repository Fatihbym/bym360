import 'package:flutter/material.dart';
import '../core/storage/save_settings.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/cari_secim_dialog.dart';
import 'cari_ekstre_view.dart';
import 'kasa_tahsilat_ekle_view.dart';

// ============================================================
// Banka Tahsilat Ekle View (Activity_BankaTahsilatEkle)
// ============================================================
class BankaTahsilatEkleView extends StatefulWidget {
  const BankaTahsilatEkleView({super.key});

  @override
  State<BankaTahsilatEkleView> createState() => _BankaTahsilatEkleViewState();
}

class _BankaTahsilatEkleViewState extends State<BankaTahsilatEkleView> {
  GetCari? _selectedCari;
  double? _cariBakiye;
  bool _isLoadingBakiye = false;
  bool _isLoadingNo = true;
  bool _isSaving = false;

  final TextEditingController _belgeNoController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final String _selectedIslemTuru = 'Kredi Kartı Satış (65)';

  GetSube? _selectedSube;
  GetSubeBanka? _selectedBanka;
  List<GetSubeBanka> _availableBankalar = [];

  @override
  void initState() {
    super.initState();
    _initSubeAndBanka();
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

  void _initSubeAndBanka() {
    final subeler = _subeOptions;
    _selectedSube = subeler.firstWhere(
      (s) => s.subeId == SaveSettings.subeId,
      orElse: () => subeler.first,
    );
    _updateBankalarForSube();
  }

  void _updateBankalarForSube() {
    final subeId = _selectedSube?.subeId ?? SaveSettings.subeId;
    if (SaveSettings.subeBankaList.isNotEmpty) {
      _availableBankalar = SaveSettings.subeBankaList.where((b) => b.subeId == subeId || b.subeId == 0).toList();
    }
    if (_availableBankalar.isEmpty && SaveSettings.subeBankaList.isNotEmpty) {
      _availableBankalar = SaveSettings.subeBankaList;
    }
    if (_availableBankalar.isNotEmpty) {
      _selectedBanka = _availableBankalar.firstWhere(
        (b) => b.bankaId == SaveSettings.bankaId,
        orElse: () => _availableBankalar.first,
      );
    }
  }

  Future<void> _autoFetchBelgeNo() async {
    setState(() => _isLoadingNo = true);
    final no = await ApiService.getBelgeNo('BT');
    if (!mounted) return;
    setState(() {
      if (no.isNotEmpty) {
        _belgeNoController.text = no;
      } else {
        _belgeNoController.text = 'BT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
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
      _descController.text = '${_selectedCari!.cariAd} - Yapılan Banka Tahsilatı';
    } else {
      _descController.text = 'Banka Tahsilat İşlemi';
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
          content: Text('Geçerli bir tahsilat tutarı giriniz.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await ApiService.bankaTahsil(
      subeId: _selectedSube?.subeId ?? SaveSettings.subeId,
      cariId: _selectedCari!.cariId,
      bankaId: _selectedBanka?.bankaId ?? SaveSettings.bankaId,
      tutar: tutar,
      tarih: _formatDate(_selectedDate),
      aciklama: _descController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Banka tahsilatı başarıyla kaydedildi!'),
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
        title: const Text('Banka Tahsilatı Ekle'),
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
                        const Text(
                          'Cari Müşteri Seçimi',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      const Text(
                        'Henüz cari seçilmedi. Lütfen yukarıdaki butona basarak müşteri seçiniz.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      )
                    else ...[
                      Text(
                        _selectedCari!.displayTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.primaryBlue),
                      ),
                      if (_selectedCari!.displayUserOrAuthor.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.account_circle_rounded, size: 16, color: AppTheme.primaryBlue),
                            const SizedBox(width: 4),
                            Text(
                              'Kullanıcı / Yetkili: ${_selectedCari!.displayUserOrAuthor}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryBlue),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Cari Kod: ${_selectedCari!.cariKod.isNotEmpty ? _selectedCari!.cariKod : _selectedCari!.cariId}',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          if (_selectedCari!.gsm.isNotEmpty || _selectedCari!.telefon.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Text(
                              'Tel: ${_selectedCari!.gsm.isNotEmpty ? _selectedCari!.gsm : _selectedCari!.telefon}',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('GÜNCEL BAKİYE: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          if (_isLoadingBakiye)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Text(
                              '₺${(_cariBakiye ?? 0.0).toStringAsFixed(2)}',
                              style: TextStyle(
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
                        labelText: 'Belge / Dekont Numarası',
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
                          value: 'Kredi Kartı Satış (65)',
                          child: Text('Kredi Kartı Satış (65)', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'Banka Havale / EFT',
                          child: Text('Banka Havale / EFT', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (val) {},
                      decoration: const InputDecoration(
                        labelText: 'İşlem Türü',
                        prefixIcon: Icon(Icons.account_balance_rounded),
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
                          child: Text(s.subeAdi, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSube = val;
                            _updateBankalarForSube();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Banka Hesabı Seçimi
                    if (_availableBankalar.isNotEmpty) ...[
                      DropdownButtonFormField<GetSubeBanka>(
                        initialValue: _selectedBanka,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Banka Hesabı',
                          prefixIcon: Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryBlue),
                        ),
                        items: _availableBankalar.map((b) {
                          return DropdownMenuItem<GetSubeBanka>(
                            value: b,
                            child: Text(b.bankaAdi, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedBanka = val);
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
                            Text(_formatDate(_selectedDate), style: const TextStyle(fontSize: 16)),
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
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      decoration: const InputDecoration(
                        labelText: 'Tahsilat Tutarı (₺)',
                        prefixIcon: Icon(Icons.attach_money_rounded, color: AppTheme.primaryBlue),
                        suffixText: 'TL',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fiş Açıklaması & Otomatik Oluştur Butonu
                    TextField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Fiş / Dekont Açıklaması',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _generateAutoDescription,
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('Otomatik Açıklama Oluştur', style: TextStyle(fontSize: 12)),
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
                          _isSaving ? 'KAYDEDİLİYOR...' : 'BANKA TAHSİLATINI KAYDET',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
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

// ============================================================
// Tahsilat Listele View (Activity_TahsilatListele)
// ============================================================
class TahsilatListeleView extends StatefulWidget {
  final int initialIndex;
  const TahsilatListeleView({super.key, this.initialIndex = 0});

  @override
  State<TahsilatListeleView> createState() => _TahsilatListeleViewState();
}

class _TahsilatListeleViewState extends State<TahsilatListeleView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<GetTahsilatListe> _kasaList = [];
  List<GetTahsilatListe> _bankaList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialIndex.clamp(0, 2));
    _loadTahsilat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTahsilat() async {
    setState(() => _isLoading = true);
    final kasa = await ApiService.getKasaTahsilListe(gunLimit: 30);
    final banka = await ApiService.getBankaTahsilListe(gunLimit: 30);
    if (mounted) {
      setState(() {
        _kasaList = kasa;
        _bankaList = banka;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTahsilat(GetTahsilatListe item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tahsilat Silme Onayı'),
        content: Text('${item.cariAdi} için ${item.tutar.toStringAsFixed(2)} TL tutarındaki tahsilatı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İPTAL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SİL'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final isKasa = item.tur.toUpperCase() == 'KASA';
      final success = await ApiService.tahsilatSil(isKasa ? 1 : 2, item.tahsilatId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tahsilat kaydı başarıyla silindi.')),
          );
          _loadTahsilat();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tahsilat silinirken bir hata oluştu.'), backgroundColor: AppTheme.accentRed),
          );
        }
      }
    }
  }

  Widget _buildList(List<GetTahsilatListe> items) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTahsilat,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Henüz tahsilat kaydı bulunmamaktadır.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTahsilat,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isKasa = item.tur.toUpperCase() == 'KASA';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isKasa ? AppTheme.accentGreen.withValues(alpha: 0.1) : AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isKasa ? Icons.payments_rounded : Icons.account_balance_rounded,
                  color: isKasa ? AppTheme.accentGreen : AppTheme.primaryBlue,
                ),
              ),
              title: Text(item.cariAdi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Text(
                '${item.tarih}\n${item.aciklama.isNotEmpty ? item.aciklama : (isKasa ? "Nakit Kasa Tahsilatı" : "Banka Tahsilatı")}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₺${item.tutar.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isKasa ? AppTheme.accentGreen : AppTheme.primaryBlue,
                        ),
                      ),
                      Text(
                        item.tur.toUpperCase(),
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentRed),
                    onPressed: () => _deleteTahsilat(item),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openCreateTahsilat() {
    final currentIndex = _tabController.index;
    if (currentIndex == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const KasaTahsilatEkleView())).then((_) => _loadTahsilat());
    } else if (currentIndex == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const BankaTahsilatEkleView())).then((_) => _loadTahsilat());
    } else {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tahsilat Türü Seçiniz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.payments_rounded, color: AppTheme.accentGreen),
                title: const Text('Kasa Tahsilat Ekle (Nakit)', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const KasaTahsilatEkleView())).then((_) => _loadTahsilat());
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.account_balance_rounded, color: AppTheme.primaryBlue),
                title: const Text('Banka Tahsilat Ekle (Kredi Kartı/EFT)', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BankaTahsilatEkleView())).then((_) => _loadTahsilat());
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allList = [..._kasaList, ..._bankaList];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tahsilat Geçmişi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'TÜMÜ'),
            Tab(text: 'KASA'),
            Tab(text: 'BANKA'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTahsilat,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTahsilat,
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('YENİ TAHSİLAT EKLE', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(allList),
          _buildList(_kasaList),
          _buildList(_bankaList),
        ],
      ),
    );
  }
}

// ============================================================
// Cari Hareket Ekstre View (Wrapper around CariEkstreView)
// ============================================================
class CariHareketEkstreView extends StatelessWidget {
  const CariHareketEkstreView({super.key});

  @override
  Widget build(BuildContext context) {
    return const CariEkstreView();
  }
}

// ============================================================
// Yeni Cari Kart Ekle View (Activity_CariEkle)
// ============================================================
class CariEkleView extends StatefulWidget {
  const CariEkleView({super.key});

  @override
  State<CariEkleView> createState() => _CariEkleViewState();
}

class _CariEkleViewState extends State<CariEkleView> {
  final _kodCtrl = TextEditingController();
  final _adCtrl = TextEditingController();
  final _adresCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _gsmCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _kodCtrl.dispose();
    _adCtrl.dispose();
    _adresCtrl.dispose();
    _telCtrl.dispose();
    _gsmCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCari() async {
    final kod = _kodCtrl.text.trim();
    final ad = _adCtrl.text.trim();
    final adres = _adresCtrl.text.trim();
    final tel = _telCtrl.text.trim();
    final gsm = _gsmCtrl.text.trim();

    if (kod.isEmpty || ad.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen Cari Kodu ve Cari Unvanını giriniz.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final res = await ApiService.cariEkle(
      cariKod: kod,
      cariAd: ad,
      cariAdres: adres,
      cariTel: tel,
      cariGsm: gsm,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cari Kaydı Oluşturuldu: $ad'), backgroundColor: AppTheme.accentGreen),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cari kaydedilirken bir hata oluştu.'), backgroundColor: AppTheme.accentRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Cari Kart Oluştur'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cari Kimlik Bilgileri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _kodCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cari Kodu *',
                    prefixIcon: Icon(Icons.qr_code_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _adCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cari Unvanı / Adı *',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _gsmCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'GSM / Cep Telefonu',
                    prefixIcon: Icon(Icons.smartphone_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _telCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Sabit Telefon',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _adresCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Fatura / Sevk Adresi',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveCari,
                    icon: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_rounded),
                    label: Text(_isSaving ? 'KAYDEDİLİYOR...' : 'CARİ KARTINI KAYDET', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
