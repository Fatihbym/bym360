import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AtamaliSiparisView extends StatefulWidget {
  const AtamaliSiparisView({super.key});

  @override
  State<AtamaliSiparisView> createState() => _AtamaliSiparisViewState();
}

class _AtamaliSiparisViewState extends State<AtamaliSiparisView> {
  List<GetBelgeListele> _siparisler = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSiparisler();
  }

  Future<void> _loadSiparisler() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getBelgeListele(tur: 'SIPARIS');
    setState(() {
      _siparisler = list;
      _isLoading = false;
    });
  }

  Future<void> _teslimAl(GetBelgeListele siparis) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AtamaliSiparisDetailSheet(siparis: siparis),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${siparis.belgeNo} teslim alımı tamamlandı.')),
      );
      _loadSiparisler();
    }

  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Atamalı Sipariş Teslim Alma', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSiparisler,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _siparisler.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_ind_rounded,
                          size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Size atanmış teslim bekleyen sipariş bulunmamaktadır.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSiparisler,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _siparisler.length,
                    itemBuilder: (context, index) {
                      final sip = _siparisler[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shopping_bag_rounded, color: AppTheme.accentOrange),
                          ),
                          title: Text(
                            sip.belgeNo,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Müşteri: ${sip.cariAdi.isNotEmpty ? sip.cariAdi : "Bilinmeyen Müşteri"}'),
                                const SizedBox(height: 2),
                                Text('Tarih: ${sip.tarih}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₺${sip.genelToplam.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 2),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  minimumSize: const Size(60, 28),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _teslimAl(sip),
                                child: const Text('Teslim Al', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _AtamaliSiparisDetailSheet extends StatefulWidget {
  final GetBelgeListele siparis;
  const _AtamaliSiparisDetailSheet({required this.siparis});

  @override
  State<_AtamaliSiparisDetailSheet> createState() => _AtamaliSiparisDetailSheetState();
}

class _AtamaliSiparisDetailSheetState extends State<_AtamaliSiparisDetailSheet> {
  bool _isSubmitting = false;

  Future<void> _confirm() async {
    setState(() => _isSubmitting = true);
    final success = await ApiService.postAtamaliTeslimAlma(widget.siparis.belgeId, []);
    setState(() => _isSubmitting = false);

    if (mounted) {
      Navigator.pop(context, success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sipariş Teslim Alma',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),
          Text('Sipariş No: ${widget.siparis.belgeNo}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Cari Adı: ${widget.siparis.cariAdi}'),
          const SizedBox(height: 4),
          Text('Tarih: ${widget.siparis.tarih}'),
          const SizedBox(height: 4),
          Text('Toplam Tutar: ₺${widget.siparis.genelToplam.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
              onPressed: _isSubmitting ? null : _confirm,
              icon: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Icon(Icons.check_circle_rounded),
              label: Text(_isSubmitting ? 'İşleniyor...' : 'Teslim Alındı Olarak Kaydet'),
            ),
          ),
        ],
      ),
    );
  }
}
