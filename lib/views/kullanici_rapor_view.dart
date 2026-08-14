import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/storage/save_settings.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/baski_onizleme_dialog.dart';

// ============================================================
// Kullanıcı & Gün Sonu Raporu (Activity_KullaniciRapor.java)
// ============================================================
class KullaniciRaporView extends StatefulWidget {
  const KullaniciRaporView({super.key});

  @override
  State<KullaniciRaporView> createState() => _KullaniciRaporViewState();
}

class _KullaniciRaporViewState extends State<KullaniciRaporView> {
  String _islemKodu = '001'; // 001 = Şube Bazlı, 002 = Kullanıcı Bazlı
  int _selectedSubKulId = 0;
  DateTime _selectedDate = DateTime.now();

  GetKullaniciRaporDetay? _rapor;
  List<GetKullaniciRapor> _raporDetayList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (SaveSettings.subeList.isNotEmpty) {
      _selectedSubKulId = SaveSettings.subeId != 0 ? SaveSettings.subeId : SaveSettings.subeList.first.subeId;
    }
    _fetchRapor();
  }

  Future<void> _fetchRapor() async {
    setState(() => _isLoading = true);
    final tarihStr = DateFormat('dd.MM.yyyy').format(_selectedDate);

    final resList = await ApiService.getKullaniciRaporDetay(
      id: _selectedSubKulId,
      tarih: tarihStr,
      islemKodu: _islemKodu,
    );

    if (!mounted) return;
    setState(() {
      _rapor = resList.isNotEmpty ? resList.first : null;
      _isLoading = false;
    });
  }

  Future<void> _showDetayModal() async {
    final tarihStr = DateFormat('dd.MM.yyyy').format(_selectedDate);

    final list = await ApiService.getKullaniciRapor(
      id: _selectedSubKulId,
      tarih: tarihStr,
      islemKodu: _islemKodu,
    );

    if (!mounted) return;
    _raporDetayList = list;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kullanıcı Rapor Hareket Detayı',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              Expanded(
                child: _raporDetayList.isEmpty
                    ? Center(
                        child: Text(
                          'Detay hareketi bulunamadı.',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _raporDetayList.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final d = _raporDetayList[index];
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryBlue, size: 20),
                              ),
                              title: Text(
                                d.evrakTuru.isNotEmpty ? d.evrakTuru : 'Evrak #${d.evrakId}',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Adet: ${d.adet}  |  Kullanıcı: ${d.kullaniciAdi}', style: GoogleFonts.inter(fontSize: 12)),
                              trailing: Text(
                                '₺${d.tutar.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.accentGreen),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _yazdirRapor() async {
    final tarihStr = DateFormat('dd.MM.yyyy').format(_selectedDate);

    // Hareket listesini hazırla
    if (_raporDetayList.isEmpty) {
      _raporDetayList = await ApiService.getKullaniciRapor(
        id: _selectedSubKulId,
        tarih: tarihStr,
        islemKodu: _islemKodu,
      );
    }

    final formattedIslemler = _raporDetayList.map((d) => {
      'tur': d.evrakTuru.isNotEmpty ? d.evrakTuru : 'Evrak #${d.evrakId}',
      'cari': d.kullaniciAdi.isNotEmpty ? d.kullaniciAdi : 'Genel',
      'tutar': d.tutar,
      'adet': d.adet,
    }).toList();

    if (!mounted) return;

    BaskiOnizlemeDialog.showRapor(
      context: context,
      baslik: _islemKodu == '001' ? 'Şube Gün Sonu Raporu' : 'Kullanıcı Kasa Raporu',
      tarihAraligi: tarihStr,
      toplamSatis: _rapor?.satis ?? 0.0,
      toplamTahsilat: _rapor?.kasaTahsilat ?? 0.0,
      toplamNakit: _rapor?.nakitToplam ?? (_rapor?.kasaNet ?? 0.0),
      toplamKrediKarti: _rapor?.kartSatis ?? 0.0,
      belgeSayisi: _raporDetayList.length,
      islemler: formattedIslemler,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('kullaniciraporu', 'Kullanıcı & Gün Sonu Raporu'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Rapor Yazdır',
            onPressed: _yazdirRapor,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          // Filter Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _islemKodu,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Rapor Kapsamı',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: const [
                            DropdownMenuItem(value: '001', child: Text('Şube Bazlı Rapor', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: '002', child: Text('Kullanıcı Bazlı Rapor', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _islemKodu = val;
                              });
                              _fetchRapor();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2099),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                              _fetchRapor();
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Rapor Tarihi',
                              prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryBlue),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            child: Text(DateFormat('dd.MM.yyyy').format(_selectedDate), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: _fetchRapor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading) ...[
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ] else ...[
            // 1. Satış Özeti Card
            _buildMetricsGroupCard(
              title: 'Satış İşlemleri',
              icon: Icons.point_of_sale_rounded,
              color: AppTheme.primaryBlue,
              isDark: isDark,
              rows: [
                _metricRow('Satış Tutar', _rapor?.satis ?? 0.0, isDark),
                _metricRow('Satış İade', _rapor?.satisIade ?? 0.0, isDark),
                _metricRow('Net Satış', _rapor?.satisNet ?? 0.0, isDark, isBold: true),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Kasa Özeti Card
            _buildMetricsGroupCard(
              title: 'Kasa İşlemleri (Nakit)',
              icon: Icons.account_balance_wallet_rounded,
              color: AppTheme.accentGreen,
              isDark: isDark,
              rows: [
                _metricRow('Kasa Tahsilat', _rapor?.kasaTahsilat ?? 0.0, isDark),
                _metricRow('Kasa Tediye', _rapor?.kasaTediye ?? 0.0, isDark),
                _metricRow('Kasa Net', _rapor?.kasaNet ?? 0.0, isDark, isBold: true),
              ],
            ),
            const SizedBox(height: 14),

            // 3. Banka & POS Card
            _buildMetricsGroupCard(
              title: 'Kredi Kartı / POS',
              icon: Icons.credit_card_rounded,
              color: AppTheme.accentPurple,
              isDark: isDark,
              rows: [
                _metricRow('Kart Satış', _rapor?.kartSatis ?? 0.0, isDark),
                _metricRow('Kart Alış', _rapor?.kartAlis ?? 0.0, isDark),
                _metricRow('Kart Net', _rapor?.kartNet ?? 0.0, isDark, isBold: true),
              ],
            ),
            const SizedBox(height: 14),

            // Total Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Genel Satış Toplamı', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                      Text('₺${(_rapor?.satisToplam ?? 0.0).toStringAsFixed(2)}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Genel Nakit Toplamı', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                      Text('₺${(_rapor?.nakitToplam ?? 0.0).toStringAsFixed(2)}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Detail Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.list_alt_rounded, color: AppTheme.primaryBlue),
                label: Text(
                  'DETAYLI HAREKET LİSTESİ GÖSTER',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
                onPressed: _showDetayModal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsGroupCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required List<Widget> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: color),
              ),
            ],
          ),
          const Divider(height: 18),
          ...rows,
        ],
      ),
    );
  }

  Widget _metricRow(String label, double val, bool isDark, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 14 : 13,
              color: isDark ? (isBold ? Colors.white : Colors.white70) : (isBold ? Colors.black87 : Colors.black54),
            ),
          ),
          Text(
            '₺${val.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 15 : 14,
              color: val < 0 ? AppTheme.accentRed : (isBold ? AppTheme.primaryBlue : (isDark ? Colors.white : Colors.black87)),
            ),
          ),
        ],
      ),
    );
  }
}
