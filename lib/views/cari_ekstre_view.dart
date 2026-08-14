import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/cari_secim_dialog.dart';

class CariEkstreView extends StatefulWidget {
  final GetCari? initialCari;
  const CariEkstreView({super.key, this.initialCari});

  @override
  State<CariEkstreView> createState() => _CariEkstreViewState();
}

class _CariEkstreViewState extends State<CariEkstreView> {
  GetCari? _selectedCari;
  List<GetCariHesapEkstre> _ekstreList = [];
  bool _isLoading = false;
  double _toplamBakiye = 0.0;
  double _toplamBorc = 0.0;
  double _toplamAlacak = 0.0;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.initialCari != null) {
      _selectedCari = widget.initialCari;
      _loadEkstre();
    }
  }

  Future<void> _loadEkstre() async {
    if (_selectedCari == null) return;
    setState(() => _isLoading = true);

    final t1 = DateFormat('yyyy-MM-dd').format(_startDate);
    final t2 = DateFormat('yyyy-MM-dd').format(_endDate);

    final list = await ApiService.getCariHesapEkstre(
      cariId: _selectedCari!.cariId,
      tarih1: t1,
      tarih2: t2,
    );
    final bakiye = await ApiService.getCariBakiye(_selectedCari!.cariId);

    double tBorc = 0;
    double tAlacak = 0;
    for (var e in list) {
      tBorc += e.borc;
      tAlacak += e.alacak;
    }

    if (!mounted) return;
    setState(() {
      _ekstreList = list;
      _toplamBakiye = bakiye;
      _toplamBorc = tBorc;
      _toplamAlacak = tAlacak;
      _isLoading = false;
    });
  }

  void _selectCariDialog() async {
    final selected = await CariSecimDialog.show(context);
    if (selected != null) {
      setState(() {
        _selectedCari = selected;
      });
      _loadEkstre();
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadEkstre();
    }
  }

  String _formatDate(DateTime dt) {
    return DateFormat('dd.MM.yyyy').format(dt);
  }

  void _showEkstreDetailDialog(GetCariHesapEkstre item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hareket Detayı',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedCari != null) ...[
              _buildDetailRow('Cari Müşteri', _selectedCari!.displayTitle),
              _buildDetailRow('Cari Kod', _selectedCari!.cariKod),
              const Divider(),
            ],
            _buildDetailRow('İşlem Türü', item.displayTitle),
            if (item.evrakNo.isNotEmpty) _buildDetailRow('Belge No', item.evrakNo),
            _buildDetailRow('Tarih', item.tarih),
            if (item.aciklama.isNotEmpty) _buildDetailRow('Açıklama', item.aciklama),
            if (item.yerAdi.isNotEmpty) _buildDetailRow('Hesap / Yer', item.yerAdi),
            const Divider(),
            _buildDetailRow(
              'Borç Tutarı',
              '₺${item.borc.toStringAsFixed(2)}',
              valueColor: item.borc > 0 ? AppTheme.accentRed : Colors.black87,
            ),
            _buildDetailRow(
              'Alacak Tutarı',
              '₺${item.alacak.toStringAsFixed(2)}',
              valueColor: item.alacak > 0 ? AppTheme.accentGreen : Colors.black87,
            ),
            _buildDetailRow(
              'Yürüyen Bakiye',
              '₺${item.bakiye.toStringAsFixed(2)} ${item.bakiyeTur}',
              valueColor: AppTheme.primaryBlue,
              isBold: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cari Hesap Ekstresi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_rounded),
            onPressed: _selectCariDialog,
            tooltip: 'Cari Seç',
          ),
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            onPressed: _pickDateRange,
            tooltip: 'Tarih Aralığı Seç',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadEkstre,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Cari Başlık Kartı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.primaryBlue.withValues(alpha: 0.08),
              border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkCardBorder : Colors.grey.withValues(alpha: 0.2))),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCari != null ? _selectedCari!.displayTitle : 'Henüz Cari Seçilmedi',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.primaryBlue),
                          ),
                          if (_selectedCari != null) ...[
                            if (_selectedCari!.displayUserOrAuthor.isNotEmpty)
                              Text(
                                'Kullanıcı / Yetkili: ${_selectedCari!.displayUserOrAuthor}',
                                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                              ),
                            Text(
                              'Kod: ${_selectedCari!.cariKod} | Tel: ${_selectedCari!.gsm.isNotEmpty ? _selectedCari!.gsm : _selectedCari!.telefon}',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _selectCariDialog,
                      icon: const Icon(Icons.person_search, size: 16),
                      label: Text(_selectedCari == null ? 'Cari Seç' : 'Değiştir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Özet Bakiye Kartları
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Text('TOP. BORÇ', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.accentRed, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            FittedBox(
                              child: Text('₺${_toplamBorc.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.accentRed)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Text('TOP. ALACAK', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.accentGreen, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            FittedBox(
                              child: Text('₺${_toplamAlacak.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.accentGreen)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _toplamBakiye >= 0 ? AppTheme.accentGreen.withValues(alpha: 0.15) : AppTheme.accentRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _toplamBakiye >= 0 ? AppTheme.accentGreen.withValues(alpha: 0.4) : AppTheme.accentRed.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text('NET BAKİYE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            FittedBox(
                              child: Text(
                                '₺${_toplamBakiye.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _toplamBakiye >= 0 ? AppTheme.accentGreen : AppTheme.accentRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tarih Aralığı Bilgi Çubuğu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppTheme.darkSurface : Colors.grey.withValues(alpha: 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: _pickDateRange,
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_rounded, size: 16, color: AppTheme.primaryBlue),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_ekstreList.length} Hareket Kaydı',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Hareket Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedCari == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_search_rounded, size: 56, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text('Ekstre görüntülemek için lütfen müşteri seçiniz.', style: GoogleFonts.inter(color: Colors.grey)),
                          ],
                        ),
                      )
                    : _ekstreList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text('Seçilen tarih aralığında hesap hareketi bulunamadı.', style: GoogleFonts.inter(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _ekstreList.length,
                            separatorBuilder: (c, i) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _ekstreList[index];
                              final isDevir = index == 0 && (item.islemTuru.contains('Devir') || item.tarih.contains('Devir'));
                              final isBorc = item.borc > 0;

                              return Material(
                                color: isDark ? AppTheme.darkSurface : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () => _showEkstreDetailDialog(item),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isDevir
                                        ? Colors.orange.shade100
                                        : isBorc
                                            ? Colors.red.shade100
                                            : Colors.green.shade100,
                                    child: Icon(
                                      isDevir
                                          ? Icons.history_toggle_off_rounded
                                          : isBorc
                                              ? Icons.arrow_upward_rounded
                                              : Icons.arrow_downward_rounded,
                                      color: isDevir
                                          ? Colors.orange.shade800
                                          : isBorc
                                              ? Colors.red
                                              : Colors.green,
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    item.displayTitle,
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tarih: ${item.tarih}',
                                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                                        ),
                                        if (item.aciklama.isNotEmpty)
                                          Text(
                                            item.aciklama,
                                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        isBorc
                                            ? '₺${item.borc.toStringAsFixed(2)}'
                                            : item.alacak > 0
                                                ? '₺${item.alacak.toStringAsFixed(2)}'
                                                : '₺${item.tutar.toStringAsFixed(2)}',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isBorc ? AppTheme.accentRed : AppTheme.accentGreen,
                                        ),
                                      ),
                                      Text(
                                        'Bak: ₺${item.bakiye.toStringAsFixed(2)} ${item.bakiyeTur}',
                                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
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
}
