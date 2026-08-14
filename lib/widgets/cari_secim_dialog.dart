import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../views/finans_views.dart';

class CariSecimDialog extends StatefulWidget {
  const CariSecimDialog({super.key});

  static Future<GetCari?> show(BuildContext context) {
    return showDialog<GetCari>(
      context: context,
      builder: (context) => const CariSecimDialog(),
    );
  }

  @override
  State<CariSecimDialog> createState() => _CariSecimDialogState();
}

class _CariSecimDialogState extends State<CariSecimDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<GetCari> _allCaris = [];
  List<GetCari> _filteredCaris = [];
  bool _isLoading = true;
  Timer? _debounceTimer;
  int _fetchSeq = 0;
  String _selectedFilter = 'TÜMÜ';

  @override
  void initState() {
    super.initState();
    _fetchCaris('');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCaris(String query) async {
    _debounceTimer?.cancel();
    final seq = ++_fetchSeq;
    setState(() => _isLoading = true);
    final results = await ApiService.getCariAra(query);
    if (mounted && seq == _fetchSeq) {
      setState(() {
        _allCaris = results;
        _applyLocalFilter();
        _isLoading = false;
      });
    }
  }

  void _onSearchInputChanged(String query) {
    _debounceTimer?.cancel();
    _applyLocalFilter();

    if (query.trim().length >= 2) {
      _debounceTimer = Timer(const Duration(milliseconds: 350), () {
        _fetchCaris(query.trim());
      });
    } else if (query.trim().isEmpty) {
      _fetchCaris('');
    }
  }

  void _applyLocalFilter() {
    final q = _searchController.text.toLowerCase().trim();
    if (q.isEmpty) {
      _filteredCaris = List.from(_allCaris);
    } else {
      _filteredCaris = _allCaris.where((c) {
        if (_selectedFilter == 'UNVAN') {
          return c.unvan.toLowerCase().contains(q) || c.displayTitle.toLowerCase().contains(q);
        } else if (_selectedFilter == 'KOD') {
          return c.cariKod.toLowerCase().contains(q) || c.cariId.toString().contains(q);
        } else if (_selectedFilter == 'YETKİLİ') {
          return c.yetkili.toLowerCase().contains(q) || c.kullaniciAdi.toLowerCase().contains(q);
        }
        return c.displayTitle.toLowerCase().contains(q) ||
            c.cariKod.toLowerCase().contains(q) ||
            c.unvan.toLowerCase().contains(q) ||
            c.yetkili.toLowerCase().contains(q) ||
            c.kullaniciAdi.toLowerCase().contains(q) ||
            c.telefon.toLowerCase().contains(q) ||
            c.gsm.toLowerCase().contains(q);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.people_alt_rounded, color: AppTheme.primaryBlue, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Cari Müşteri Seçimi', 'Cari Müşteri Seçimi'),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  context.tr('Arama yapıp listeden seçebilirsiniz', 'Arama yapıp listeden seçebilirsiniz'),
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 480,
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Arama Kutusu
            TextField(
              controller: _searchController,
              onChanged: _onSearchInputChanged,
              onSubmitted: (val) => _fetchCaris(val),
              decoration: InputDecoration(
                hintText: context.tr('Cari adı, kodu, kullanıcı veya tel ara...', 'Cari adı, kodu, kullanıcı veya tel ara...'),
                hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchInputChanged('');
                        },
                      )
                    : null,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Arama Filtre Çipleri
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['TÜMÜ', 'UNVAN', 'KOD', 'YETKİLİ'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(
                        filter,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppTheme.primaryBlue,
                        ),
                      ),
                      selectedColor: AppTheme.primaryBlue,
                      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = filter;
                          _applyLocalFilter();
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Cari Liste veya Yüklenme Ekranı
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Cari listesi yükleniyor...', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    )
                  : _filteredCaris.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off_rounded, size: 48, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                context.tr('Kayıtlı cari bulunamadı.', 'Kayıtlı cari bulunamadı.'),
                                style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _filteredCaris.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _filteredCaris[index];
                            final title = item.displayTitle;
                            final userOrAuthor = item.displayUserOrAuthor;
                            final phone = item.gsm.isNotEmpty ? item.gsm : item.telefon;
                            final isPositive = item.bakiye >= 0;

                            return Card(
                              elevation: 0,
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.15),
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.pop(context, item),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Cari Avatar / İkon
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                        child: Text(
                                          title.isNotEmpty ? title[0].toUpperCase() : 'C',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppTheme.primaryBlue,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Bilgi Kolonu
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),

                                            // Kullanıcı / Yetkili Adı Bilgisi
                                            if (userOrAuthor.isNotEmpty) ...[
                                              Row(
                                                children: [
                                                  const Icon(Icons.person_rounded, size: 14, color: AppTheme.primaryBlue),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      'Kullanıcı / Yetkili: $userOrAuthor',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppTheme.primaryBlue,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                            ],

                                            // Kodu ve Telefon
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'Kod: ${item.cariKod.isNotEmpty ? item.cariKod : item.cariId}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ),
                                                if (phone.isNotEmpty) ...[
                                                  const SizedBox(width: 8),
                                                  Icon(Icons.phone_rounded, size: 12, color: Colors.grey[600]),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    phone,
                                                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Bakiye Rozeti
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isPositive
                                              ? AppTheme.accentGreen.withValues(alpha: 0.1)
                                              : AppTheme.accentRed.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '₺${item.bakiye.toStringAsFixed(2)}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isPositive ? AppTheme.accentGreen : AppTheme.accentRed,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: Text(context.tr('YENİ CARİ EKLE', 'YENİ CARİ EKLE'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CariEkleView()),
            ).then((_) => _fetchCaris(_searchController.text));
          },
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('iptal', 'İptal'), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
