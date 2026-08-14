import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/storage/save_settings.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/barcode_scanner_view.dart';
import '../widgets/dynamic_island_toast.dart';
import 'etiket_views.dart';

class FiyatGorView extends StatefulWidget {
  const FiyatGorView({super.key});

  @override
  State<FiyatGorView> createState() => _FiyatGorViewState();
}

class _FiyatGorViewState extends State<FiyatGorView> {
  final _barcodeController = TextEditingController();
  GetFiyatGor? _foundItem;
  List<GetFiyatGor> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _akilliArama = SaveSettings.akilliArama.toLowerCase() == 'açık';

  Timer? _debounceTimer;
  int _searchSeq = 0;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _barcodeController.dispose();
    super.dispose();
  }

  void _onSearchInputChanged(String val) {
    _debounceTimer?.cancel();
    final query = val.trim();
    if (query.isEmpty) {
      setState(() {
        _foundItem = null;
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    if (_akilliArama && query.length >= 3) {
      _debounceTimer = Timer(const Duration(milliseconds: 350), () {
        _searchBarcode();
      });
    }
  }

  Future<void> _searchBarcode() async {
    _debounceTimer?.cancel();
    final query = _barcodeController.text.trim();
    if (query.isEmpty) return;

    final currentSeq = ++_searchSeq;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _foundItem = null;
      _searchResults = [];
    });

    final list = await ApiService.getFiyatGor(query);

    if (!mounted || currentSeq != _searchSeq) return;
    setState(() {
      _isLoading = false;
      if (list.isNotEmpty) {
        _searchResults = list;
        _foundItem = list.first;
      } else {
        _errorMessage = context.tr('Aranan barkod / stok bulunamadı.', 'Aranan barkod / stok bulunamadı.');
      }
    });
  }

  void _toggleAkilliArama() {
    setState(() {
      _akilliArama = !_akilliArama;
      SaveSettings.akilliArama = _akilliArama ? 'Açık' : 'Kapalı';
    });
    if (_akilliArama) {
      AppNotification.showSuccess(context, 'Akıllı Arama Açık (3 harften sonra otomatik arar)', title: 'Akıllı Arama');
    } else {
      AppNotification.showWarning(context, 'Akıllı Arama Kapalı (Barkod / Kod ile tam eşleşme)', title: 'Akıllı Arama');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showAdvancedDetails = SaveSettings.grupTur == 1 || SaveSettings.yetkiSemaKullanim != '1';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('fiyatgor', 'Fiyat Gör / Stok Sorgula'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _akilliArama ? Icons.auto_awesome : Icons.manage_search_rounded,
              color: _akilliArama ? AppTheme.accentOrange : Colors.white70,
            ),
            tooltip: _akilliArama ? 'Akıllı Arama Açık' : 'Akıllı Arama Kapalı',
            onPressed: _toggleAkilliArama,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barcode & Search Input Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _barcodeController,
                    autofocus: true,
                    onSubmitted: (_) => _searchBarcode(),
                    onChanged: _onSearchInputChanged,
                    decoration: InputDecoration(
                      labelText: _akilliArama ? 'Stok Adı, Kodu veya Barkod (Akıllı Arama)' : 'Barkod / Stok Kodu Giriniz',
                      hintText: 'Örn: 8690000000000 veya Ürün Adı',
                      prefixIcon: Icon(
                        _akilliArama ? Icons.search_rounded : Icons.qr_code_scanner_rounded,
                        color: AppTheme.primaryBlue,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_barcodeController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _barcodeController.clear();
                                setState(() {
                                  _foundItem = null;
                                  _searchResults = [];
                                  _errorMessage = null;
                                });
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
                            onPressed: _searchBarcode,
                          ),
                        ],
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: Text(
                        context.tr('BARKOD TARAYICI AÇ', 'BARKOD TARAYICI AÇ'),
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final code = await BarcodeScannerScreen.scan(
                          context,
                          title: context.tr('Fiyat Gör Barkod Tara', 'Fiyat Gör Barkod Tara'),
                        );
                        if (code != null && code.isNotEmpty) {
                          _barcodeController.text = code;
                          _searchBarcode();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.accentRed, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(color: AppTheme.accentRed, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Multiple search results selector if more than 1 item returned
            if (_searchResults.length > 1) ...[
              Text(
                'Bulunan Sonuçlar (${_searchResults.length})',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    final isSelected = item == _foundItem;
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(item.stokAdi.length > 20 ? '${item.stokAdi.substring(0, 20)}...' : item.stokAdi),
                      onSelected: (_) => setState(() => _foundItem = item),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_foundItem != null) ...[
              // Main Product Information Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _foundItem!.stokAdi,
                                style: GoogleFonts.outfit(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _buildHeaderTag('Kod: ${_foundItem!.stokKodu}'),
                                  if (_foundItem!.barkod.isNotEmpty) _buildHeaderTag('Barkod: ${_foundItem!.barkod}'),
                                  if (_foundItem!.stokGrup.isNotEmpty) _buildHeaderTag('Grup: ${_foundItem!.stokGrup}'),
                                  if (_foundItem!.stokLotAdi.isNotEmpty) _buildHeaderTag('Lot: ${_foundItem!.stokLotAdi}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Main Price & Stock Banner
              Row(
                children: [
                  // Satış Fiyatı Highlight
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                SaveSettings.textSFiyat.isNotEmpty ? SaveSettings.textSFiyat.toUpperCase() : 'SATIŞ FİYATI',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentGreen,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '%${_foundItem!.kdv.toStringAsFixed(0)} KDV',
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentGreen),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '₺${_foundItem!.satisFiyat.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.accentGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Kalan Stok Miktarı (Yetki Kontrollü)
                  if (showAdvancedDetails) ...[
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MEVCUT STOK',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${_foundItem!.kalan % 1 == 0 ? _foundItem!.kalan.toInt() : _foundItem!.kalan.toStringAsFixed(2)} ${_foundItem!.birim}',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _foundItem!.kalan > 0 ? AppTheme.accentCyan : AppTheme.accentRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // Kampanya / Dip Fiyat Badges
              if (_foundItem!.kampanyaFiyat.isNotEmpty || _foundItem!.dipFiyat > 0) ...[
                Row(
                  children: [
                    if (_foundItem!.kampanyaFiyat.isNotEmpty)
                      Expanded(
                        child: _buildBadgeCard(
                          title: 'Kampanya Fiyatı',
                          value: _foundItem!.kampanyaFiyat,
                          color: Colors.orange,
                          icon: Icons.local_offer_rounded,
                        ),
                      ),
                    if (_foundItem!.kampanyaFiyat.isNotEmpty && _foundItem!.dipFiyat > 0) const SizedBox(width: 10),
                    if (_foundItem!.dipFiyat > 0)
                      Expanded(
                        child: _buildBadgeCard(
                          title: 'Dip Fiyat',
                          value: '₺${_foundItem!.dipFiyat.toStringAsFixed(2)}',
                          color: Colors.purple,
                          icon: Icons.trending_down_rounded,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Gelişmiş Detaylar (Yetki Kontrollü Alış ve Özel Fiyatlar)
              if (showAdvancedDetails) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SaveSettings.textStokKartOzelFiyat.isNotEmpty ? SaveSettings.textStokKartOzelFiyat : 'Diğer Fiyat Seçenekleri',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildPriceRow(SaveSettings.textAFiyat.isNotEmpty ? SaveSettings.textAFiyat : 'Alış Fiyatı', '₺${_foundItem!.alisFiyat.toStringAsFixed(2)}', isBold: false),
                      if (_foundItem!.ozelFiyat1 > 0) _buildPriceRow(SaveSettings.textOFiyat1.isNotEmpty ? SaveSettings.textOFiyat1 : 'Özel Fiyat 1', '₺${_foundItem!.ozelFiyat1.toStringAsFixed(2)}'),
                      if (_foundItem!.ozelFiyat2 > 0) _buildPriceRow(SaveSettings.textOFiyat2.isNotEmpty ? SaveSettings.textOFiyat2 : 'Özel Fiyat 2', '₺${_foundItem!.ozelFiyat2.toStringAsFixed(2)}'),
                      if (_foundItem!.ozelFiyat3 > 0) _buildPriceRow(SaveSettings.textOFiyat3.isNotEmpty ? SaveSettings.textOFiyat3 : 'Özel Fiyat 3', '₺${_foundItem!.ozelFiyat3.toStringAsFixed(2)}'),
                      if (_foundItem!.ozelFiyat4 > 0) _buildPriceRow(SaveSettings.textOFiyat4.isNotEmpty ? SaveSettings.textOFiyat4 : 'Özel Fiyat 4', '₺${_foundItem!.ozelFiyat4.toStringAsFixed(2)}'),
                      if (_foundItem!.ozelFiyat5 > 0) _buildPriceRow(SaveSettings.textOFiyat5.isNotEmpty ? SaveSettings.textOFiyat5 : 'Özel Fiyat 5', '₺${_foundItem!.ozelFiyat5.toStringAsFixed(2)}'),
                      if (_foundItem!.ozelFiyat6 > 0) _buildPriceRow(SaveSettings.textOFiyat6.isNotEmpty ? SaveSettings.textOFiyat6 : 'Özel Fiyat 6', '₺${_foundItem!.ozelFiyat6.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Maliyet Paneli (Yetki Kontrollü Ortalama & Son Maliyet)
              if (showAdvancedDetails && (_foundItem!.ortalamaMaliyet > 0 || _foundItem!.sonMaliyet > 0)) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics_rounded, size: 18, color: AppTheme.primaryBlue),
                          const SizedBox(width: 8),
                          Text(
                            SaveSettings.textMaliyetler.isNotEmpty ? SaveSettings.textMaliyetler : 'Maliyet Bilgileri',
                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_foundItem!.ortalamaMaliyet > 0)
                        _buildPriceRow(SaveSettings.textOMaliyet.isNotEmpty ? SaveSettings.textOMaliyet : 'Ortalama Maliyet', '₺${_foundItem!.ortalamaMaliyet.toStringAsFixed(2)}'),
                      if (_foundItem!.sonMaliyet > 0)
                        _buildPriceRow(SaveSettings.textSMaliyet.isNotEmpty ? SaveSettings.textSMaliyet : 'Son Maliyet', '₺${_foundItem!.sonMaliyet.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              // Etiket Basımı & Aksiyon Butonları
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.print_rounded, size: 20),
                  label: Text(
                    'BU ÜRÜN İÇİN ETİKET YAZDIR',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TekliEtiketView(initialBarkod: _foundItem!.barkod),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildBadgeCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
