import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/storage/save_settings.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class IsAjandasiView extends StatefulWidget {
  const IsAjandasiView({super.key});

  @override
  State<IsAjandasiView> createState() => _IsAjandasiViewState();
}

class _IsAjandasiViewState extends State<IsAjandasiView> {
  List<GetAjanda> _ajandaList = [];
  bool _isLoading = true;
  
  DateTime _currentDate = DateTime.now();
  String _viewMode = 'DAY'; // 'DAY', 'WEEK', 'MONTH', 'ALL'
  String _statusFilter = 'HEPSI'; // 'HEPSI', 'Beklemede', 'Tamamlandı'
  GetPersonel? _selectedPersonnel;

  @override
  void initState() {
    super.initState();
    _initPersonnel();
    _loadAjanda();
  }

  void _initPersonnel() {
    if (SaveSettings.personelList.isNotEmpty) {
      _selectedPersonnel = SaveSettings.personelList.firstWhere(
        (p) => p.perId == SaveSettings.perId,
        orElse: () => SaveSettings.personelList.first,
      );
    }
  }

  Future<void> _loadAjanda() async {
    setState(() => _isLoading = true);
    final perId = _selectedPersonnel?.perId ?? SaveSettings.perId;
    final items = await ApiService.getAjanda(perId);
    if (!mounted) return;
    setState(() {
      _ajandaList = items;
      _isLoading = false;
    });
  }

  void _navigateDate(int amount) {
    setState(() {
      if (_viewMode == 'DAY') {
        _currentDate = _currentDate.add(Duration(days: amount));
      } else if (_viewMode == 'WEEK') {
        _currentDate = _currentDate.add(Duration(days: amount * 7));
      } else if (_viewMode == 'MONTH') {
        _currentDate = DateTime(_currentDate.year, _currentDate.month + amount, _currentDate.day);
      }
    });
  }

  String _getDateHeaderString() {
    if (_viewMode == 'DAY') {
      return DateFormat('dd.MM.yyyy EEEE', 'tr_TR').format(_currentDate);
    } else if (_viewMode == 'WEEK') {
      final startOfWeek = _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return '${DateFormat('dd.MM.yyyy').format(startOfWeek)} - ${DateFormat('dd.MM.yyyy').format(endOfWeek)}';
    } else if (_viewMode == 'MONTH') {
      return DateFormat('MMMM yyyy', 'tr_TR').format(_currentDate);
    } else {
      return 'Tüm Görevler';
    }
  }

  List<GetAjanda> get _filteredList {
    return _ajandaList.where((item) {
      // Status filter
      if (_statusFilter == 'Beklemede' && item.durum == 'Tamamlandı') return false;
      if (_statusFilter == 'Tamamlandı' && item.durum != 'Tamamlandı') return false;

      if (_viewMode == 'ALL') return true;

      final dt = item.dateTime;
      if (dt == null) return true;

      if (_viewMode == 'DAY') {
        return dt.year == _currentDate.year && dt.month == _currentDate.month && dt.day == _currentDate.day;
      } else if (_viewMode == 'WEEK') {
        final startOfWeek = _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final dtOnly = DateTime(dt.year, dt.month, dt.day);
        final startOnly = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final endOnly = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
        return dtOnly.isAfter(startOnly.subtract(const Duration(days: 1))) && dtOnly.isBefore(endOnly.add(const Duration(days: 1)));
      } else if (_viewMode == 'MONTH') {
        return dt.year == _currentDate.year && dt.month == _currentDate.month;
      }
      return true;
    }).toList();
  }

  void _showAjandaFormModal({GetAjanda? ajandaItem}) {
    final isEditing = ajandaItem != null;
    DateTime selectedDate = ajandaItem?.dateTime ?? _currentDate;
    final planSaatiCtrl = TextEditingController(text: ajandaItem?.saat.toString() ?? '8');
    final gorevNotuCtrl = TextEditingController(text: ajandaItem?.notlar ?? '');
    final durumNotuCtrl = TextEditingController(text: ajandaItem?.sonuc ?? '');
    String selectedDurum = ajandaItem?.durum.isNotEmpty == true ? ajandaItem!.durum : 'Beklemede';
    GetPersonel? formPersonnel = _selectedPersonnel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                        Icon(
                          isEditing ? Icons.edit_calendar_rounded : Icons.add_task_rounded,
                          color: AppTheme.primaryBlue,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'Görev Notunu Güncelle' : 'Yeni Görev Kaydı Ekle',
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
                const SizedBox(height: 12),

                // Personel Seçimi (Yetkili kullanıcılar için)
                if (SaveSettings.personelList.isNotEmpty && !isEditing) ...[
                  DropdownButtonFormField<GetPersonel>(
                    initialValue: formPersonnel,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Sorumlu Personel',
                      prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primaryBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: SaveSettings.personelList.map((p) {
                      return DropdownMenuItem<GetPersonel>(
                        value: p,
                        child: Text(p.displayTitle, style: GoogleFonts.inter(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => formPersonnel = val);
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Görev Tarihi
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Görev Tarihi',
                      prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd.MM.yyyy').format(selectedDate), style: GoogleFonts.inter(fontSize: 15)),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Plan Saati (Saat Cinsinden)
                TextField(
                  controller: planSaatiCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Planlanan Saat (Örn: 8, 14)',
                    prefixIcon: const Icon(Icons.access_time_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Görev Notu / Açıklama
                TextField(
                  controller: gorevNotuCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Görev Notu / Açıklaması',
                    prefixIcon: const Icon(Icons.note_alt_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Görev Durumu (Beklemede / Tamamlandı)
                DropdownButtonFormField<String>(
                  initialValue: selectedDurum,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Görev Durumu',
                    prefixIcon: const Icon(Icons.task_alt_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Beklemede', child: Text('Beklemede (Devam Ediyor)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Tamamlandı', child: Text('Tamamlandı', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedDurum = val);
                  },
                ),
                const SizedBox(height: 12),

                // Durum Notu / Sonuç
                TextField(
                  controller: durumNotuCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Durum Notu / Sonuç Açıklaması',
                    prefixIcon: const Icon(Icons.comment_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                // Kaydet / Güncelle Butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEditing ? AppTheme.accentOrange : AppTheme.accentGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(isEditing ? Icons.update_rounded : Icons.check_circle_rounded),
                    label: Text(
                      isEditing ? 'GÖREVİ GÜNCELLE' : 'GÖREVİ KAYDET',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () async {
                      if (gorevNotuCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lütfen görev notunu giriniz.')),
                        );
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(context);
                      final perId = formPersonnel?.perId ?? SaveSettings.perId;
                      final tarihStr = DateFormat('yyyy-MM-dd').format(selectedDate);
                      final saatVal = int.tryParse(planSaatiCtrl.text.trim()) ?? 8;

                      bool success = false;
                      if (isEditing) {
                        success = await ApiService.updateAjanda(
                          perId: ajandaItem.perId != 0 ? ajandaItem.perId : perId,
                          sira: ajandaItem.sira,
                          tarih: tarihStr,
                          saat: saatVal,
                          yer: 'AJANDA',
                          notlar: gorevNotuCtrl.text.trim(),
                          durum: selectedDurum,
                          sonuc: durumNotuCtrl.text.trim(),
                        );
                      } else {
                        success = await ApiService.addAjanda(
                          perId: perId,
                          tarih: tarihStr,
                          saat: saatVal,
                          yer: 'AJANDA',
                          notlar: gorevNotuCtrl.text.trim(),
                          durum: selectedDurum,
                          sonuc: durumNotuCtrl.text.trim(),
                        );
                      }

                      nav.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Görev Başarıyla Kaydedildi' : 'İşlem Başarısız'),
                          backgroundColor: success ? AppTheme.accentGreen : AppTheme.accentRed,
                        ),
                      );
                      _loadAjanda();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAjandaTask(GetAjanda item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görevi Sil'),
        content: Text('"${item.notlar}" görevini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService.deleteAjanda(item.perId, item.sira);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Görev Silindi' : 'Görev silinirken bir hata oluştu'),
          backgroundColor: success ? AppTheme.accentGreen : AppTheme.accentRed,
        ),
      );
      _loadAjanda();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredList;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('isajandasi', 'İş Ajandası & Takvim'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAjandaFormModal(),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: Text('GÖREV EKLE', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Personel Seçimi Paneli (Yetkili kullanıcılar için)
          if (SaveSettings.personelList.isNotEmpty && (SaveSettings.grupTur == 1 || SaveSettings.personelList.length > 1))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? AppTheme.darkSurface : Colors.grey.shade100,
              child: Row(
                children: [
                  const Icon(Icons.account_circle_rounded, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<GetPersonel>(
                        value: _selectedPersonnel,
                        isExpanded: true,
                        items: SaveSettings.personelList.map((p) {
                          return DropdownMenuItem<GetPersonel>(
                            value: p,
                            child: Text(p.displayTitle, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedPersonnel = val);
                            _loadAjanda();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // View Mode Selector Bar (Day / Week / Month / All)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppTheme.darkSurface : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildViewChip('GÜNLÜK', 'DAY'),
                _buildViewChip('HAFTALIK', 'WEEK'),
                _buildViewChip('AYLIK', 'MONTH'),
                _buildViewChip('TÜMÜ', 'ALL'),
              ],
            ),
          ),

          // Date Navigator Header
          if (_viewMode != 'ALL')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBorder : Colors.blue.shade50,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                    onPressed: () => _navigateDate(-1),
                  ),
                  Text(
                    _getDateHeaderString(),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    onPressed: () => _navigateDate(1),
                  ),
                ],
              ),
            ),

          // Status Filter Chips (Tümü / Beklemede / Tamamlandı)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildStatusFilterChip('Tümü', 'HEPSI'),
                const SizedBox(width: 8),
                _buildStatusFilterChip('Beklemede', 'Beklemede'),
                const SizedBox(width: 8),
                _buildStatusFilterChip('Tamamlandı', 'Tamamlandı'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tasks List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Seçili filtrelerde kayıtlı bir ajanda görevi bulunamadı.',
                              style: GoogleFonts.inter(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isCompleted = item.durum == 'Tamamlandı';

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCompleted
                                    ? AppTheme.accentGreen.withValues(alpha: 0.4)
                                    : AppTheme.accentOrange.withValues(alpha: 0.4),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? AppTheme.accentGreen.withValues(alpha: 0.1)
                                      : AppTheme.accentOrange.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCompleted ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                                  color: isCompleted ? AppTheme.accentGreen : AppTheme.accentOrange,
                                ),
                              ),
                              title: Text(
                                item.notlar.isNotEmpty ? item.notlar : 'Görev #${item.sira}',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.event_rounded, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${item.tarih} - Saat: ${item.saat}:00',
                                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        if (item.perAd.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Text('• ${item.perAd}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                                        ],
                                      ],
                                    ),
                                    if (item.sonuc.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Sonuç: ${item.sonuc}',
                                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryBlue, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryBlue, size: 20),
                                    onPressed: () => _showAjandaFormModal(ajandaItem: item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentRed, size: 20),
                                    onPressed: () => _deleteAjandaTask(item),
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
    );
  }

  Widget _buildViewChip(String label, String mode) {
    final isSelected = _viewMode == mode;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
      selectedColor: AppTheme.primaryBlue,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      onSelected: (_) => setState(() => _viewMode = mode),
    );
  }

  Widget _buildStatusFilterChip(String label, String filter) {
    final isSelected = _statusFilter == filter;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label, style: GoogleFonts.inter(fontSize: 12)),
      selectedColor: AppTheme.accentOrange,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      onSelected: (_) => setState(() => _statusFilter = filter),
    );
  }
}
