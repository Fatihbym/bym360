import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart';

class CariEkleView extends StatefulWidget {
  const CariEkleView({super.key});

  @override
  State<CariEkleView> createState() => _CariEkleViewState();
}

class _CariEkleViewState extends State<CariEkleView> {
  final _kodController = TextEditingController();
  final _adController = TextEditingController();
  final _telController = TextEditingController();
  final _gsmController = TextEditingController();
  final _adresController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _kodController.dispose();
    _adController.dispose();
    _telController.dispose();
    _gsmController.dispose();
    _adresController.dispose();
    super.dispose();
  }

  Future<void> _saveCari() async {
    final kod = _kodController.text.trim();
    final ad = _adController.text.trim();

    if (ad.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen cari adını / unvanını giriniz.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await ApiService.cariEkle(
      cariKod: kod.isNotEmpty ? kod : 'CARI_${DateTime.now().millisecondsSinceEpoch}',
      cariAd: ad,
      cariAdres: _adresController.text.trim(),
      cariTel: _telController.text.trim(),
      cariGsm: _gsmController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeni Cari Kartı başarıyla oluşturuldu!'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cari kartı oluşturulurken hata oluştu. Lütfen tekrar deneyin.'),
          backgroundColor: AppTheme.accentRed,
        ),
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
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _kodController,
                  decoration: const InputDecoration(
                    labelText: 'Cari Kodu (Opsiyonel)',
                    prefixIcon: Icon(Icons.badge_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _adController,
                  decoration: const InputDecoration(
                    labelText: 'Cari Adı / Unvanı *',
                    prefixIcon: Icon(Icons.business_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _telController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Sabit Telefon',
                          prefixIcon: Icon(Icons.phone_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _gsmController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'GSM / Cep',
                          prefixIcon: Icon(Icons.smartphone_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _adresController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Adres',
                    prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveCari,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _isSaving ? 'KAYDEDİLİYOR...' : 'CARİ KARTINI KAYDET',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
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
