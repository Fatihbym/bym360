import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/storage/save_settings.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_logger.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'anamenu_view.dart';

class DbListeleView extends StatefulWidget {
  final PostSuperUser? superUser;
  final String? email;
  final String? password;

  const DbListeleView({
    super.key,
    this.superUser,
    this.email,
    this.password,
  });

  @override
  State<DbListeleView> createState() => _DbListeleViewState();
}

class _DbListeleViewState extends State<DbListeleView> {
  bool _isLoading = false;
  List<DbModel> _dbList = [];

  @override
  void initState() {
    super.initState();
    if (widget.superUser != null && widget.superUser!.db.isNotEmpty) {
      _dbList = widget.superUser!.db;
    } else if (SaveSettings.superUser != null && SaveSettings.superUser!.db.isNotEmpty) {
      _dbList = SaveSettings.superUser!.db;
    } else {
      _loadDbList();
    }
  }

  Future<void> _loadDbList() async {
    setState(() => _isLoading = true);
    final email = widget.email ?? SaveSettings.superUserPosta;
    final password = widget.password ?? SaveSettings.superUserSifre;
    if (email.isNotEmpty && password.isNotEmpty) {
      final res = await ApiService.girisYap(email, password);
      if (res['success'] == true && res['user'] != null) {
        final user = res['user'] as PostSuperUser;
        if (mounted) {
          setState(() {
            _dbList = user.db;
            _isLoading = false;
          });
        }
        return;
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _selectDbAndFirma(DbModel db, Firma firma) async {
    setState(() => _isLoading = true);

    final email = widget.email ?? SaveSettings.superUserPosta;
    final password = widget.password ?? SaveSettings.superUserSifre;

    AppLogger.log('DB_SELECT', '${db.aDbAdi} - ${firma.unvan} seçildi, token üretiliyor...', level: LogLevel.info);

    final tokenResult = await ApiService.tokenUret(
      email: email,
      password: password,
      dbId: db.aId,
      firmaId: firma.aId,
      dbKulId: db.aKulId,
      apiUrl: db.apiUrl,
    );

    if (!mounted) return;

    if (tokenResult['success'] == true) {
      final token = tokenResult['token'] as String;
      final girisResult = await ApiService.getGiris(
        token: token,
        email: email,
        dbKulId: db.aKulId,
      );

      if (!mounted) return;

      if (girisResult['success'] == true) {
        setState(() => _isLoading = false);
        await _showSubeDepoSelectionModal(
          db: db,
          firma: firma,
          token: token,
          email: email,
        );
        return;
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        final msg = girisResult['message'] ?? 'Giriş parametreleri alınamadı.';
        AppLogger.loginFailed(msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentRed,
            content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
          ),
        );
        return;
      }
    } else {
      setState(() => _isLoading = false);
      final msg = tokenResult['message'] ?? 'Token üretilemedi.';
      AppLogger.loginFailed(msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.accentRed,
          content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
        ),
      );
    }
  }

  Future<void> _showSubeDepoSelectionModal({
    required DbModel db,
    required Firma firma,
    required String token,
    required String email,
  }) async {
    final subeler = SaveSettings.subeList.isNotEmpty
        ? SaveSettings.subeList
        : [
            GetSube(
              subeId: SaveSettings.subeId != 0 ? SaveSettings.subeId : 1,
              subeAdi: SaveSettings.subeAdi.isNotEmpty ? SaveSettings.subeAdi : 'Merkez Şube (001)',
              subeKodu: '001',
            ),
            GetSube(subeId: 2, subeAdi: 'Şube 2 (002)', subeKodu: '002'),
          ];
    final seenSubeler = <int>{};
    final uniqueSubeler = subeler.where((s) => seenSubeler.add(s.subeId)).toList();

    final depolar = SaveSettings.depoList.isNotEmpty
        ? SaveSettings.depoList
        : [
            GetDepo(
              depoId: SaveSettings.depoId != 0 ? SaveSettings.depoId : 1,
              depoAdi: SaveSettings.depoAdi.isNotEmpty ? SaveSettings.depoAdi : 'Ana Depo (D01)',
              depoKodu: 'D01',
              subeId: SaveSettings.subeId != 0 ? SaveSettings.subeId : 1,
            ),
            GetDepo(depoId: 2, depoAdi: 'Yedek Depo (D02)', depoKodu: 'D02', subeId: 1),
          ];
    final seenDepolar = <int>{};
    final uniqueDepolar = depolar.where((d) => seenDepolar.add(d.depoId)).toList();

    int selectedSubeId = uniqueSubeler.any((s) => s.subeId == SaveSettings.subeId)
        ? SaveSettings.subeId
        : (uniqueSubeler.isNotEmpty ? uniqueSubeler.first.subeId : 1);

    int selectedDepoId = uniqueDepolar.any((d) => d.depoId == SaveSettings.depoId)
        ? SaveSettings.depoId
        : (uniqueDepolar.isNotEmpty ? uniqueDepolar.first.depoId : 1);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final filteredDepolar = uniqueDepolar
                .where((d) => d.subeId == 0 || d.subeId == selectedSubeId)
                .toList();
            final activeDepolar = filteredDepolar.isNotEmpty ? filteredDepolar : uniqueDepolar;

            if (!activeDepolar.any((d) => d.depoId == selectedDepoId)) {
              selectedDepoId = activeDepolar.first.depoId;
            }

            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: AppTheme.primaryBlue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firma.unvan.isNotEmpty ? firma.unvan : db.aDbAdi,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Aktif Şube ve Depo Seçimi',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Şube Seçimi
                  Text(
                    'Aktif Şube',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: selectedSubeId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.store_rounded, color: AppTheme.primaryBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: uniqueSubeler.map((s) {
                      return DropdownMenuItem<int>(
                        value: s.subeId,
                        child: Text(s.displayTitle, style: GoogleFonts.inter(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedSubeId = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Depo Seçimi
                  Text(
                    'Aktif Depo',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: selectedDepoId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.warehouse_rounded, color: AppTheme.primaryBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: activeDepolar.map((d) {
                      return DropdownMenuItem<int>(
                        value: d.depoId,
                        child: Text(d.displayTitle, style: GoogleFonts.inter(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedDepoId = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Onay Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final chosenSube = uniqueSubeler.firstWhere(
                          (s) => s.subeId == selectedSubeId,
                          orElse: () => uniqueSubeler.first,
                        );
                        final chosenDepo = uniqueDepolar.firstWhere(
                          (d) => d.depoId == selectedDepoId,
                          orElse: () => uniqueDepolar.first,
                        );

                        SaveSettings.subeId = chosenSube.subeId;
                        SaveSettings.subeAdi = chosenSube.subeAdi;
                        SaveSettings.depoId = chosenDepo.depoId;
                        SaveSettings.depoAdi = chosenDepo.depoAdi;

                        await SaveSettings.saveUserSession(
                          userToken: token,
                          uId: SaveSettings.userId,
                          sId: chosenSube.subeId,
                          dId: chosenDepo.depoId,
                          uName: SaveSettings.kullaniciAdi.isNotEmpty ? SaveSettings.kullaniciAdi : email,
                        );

                        AppLogger.loginSuccess(
                          username: SaveSettings.kullaniciAdi.isNotEmpty ? SaveSettings.kullaniciAdi : email,
                          dbName: db.aDbAdi,
                          companyName: '${firma.unvan} (${chosenSube.subeAdi} - ${chosenDepo.depoAdi})',
                          token: token,
                        );

                        if (ctx.mounted) {
                          Navigator.of(ctx).pop(); // close modal
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.accentGreen,
                              content: Text(
                                '${firma.unvan} - ${chosenSube.subeAdi} (${chosenDepo.depoAdi}) seçildi.',
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                            ),
                          );

                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AnamenuView()),
                            (route) => false,
                          );
                        }
                      },
                      child: Text(
                        'Seçimi Kaydet & Devam Et',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('firmasecimi', 'Firma Seçimi'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Bağlantı kuruluyor, lütfen bekleyiniz...'),
                ],
              ),
            )
          : _dbList.isEmpty
              ? Center(
                  child: Text(
                    context.tr('Kayıtlı firma bulunamadı.', 'Kayıtlı firma bulunamadı.'),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _dbList.length,
                  itemBuilder: (context, dbIndex) {
                    final db = _dbList[dbIndex];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.storage_rounded,
                                    color: AppTheme.primaryBlue,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        db.aDbAdi.isNotEmpty ? db.aDbAdi : 'Firma #${db.aId}',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                      if (db.apiUrl.isNotEmpty)
                                        Text(
                                          db.apiUrl,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text(
                              'Şirketler / Firmalar:',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (db.firma.isEmpty)
                              InkWell(
                                onTap: () => _selectDbAndFirma(db, Firma(aId: 1, aAdi: db.aDbAdi)),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.business_rounded, color: AppTheme.primaryBlue, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          db.aDbAdi.isNotEmpty ? db.aDbAdi : 'Varsayılan Şirket',
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...db.firma.map(
                                (f) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: InkWell(
                                    onTap: () => _selectDbAndFirma(db, f),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryBlue.withValues(alpha: 0.04),
                                        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.15)),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.business_rounded, color: AppTheme.primaryBlue, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              f.unvan,
                                              style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
                                            ),
                                          ),
                                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primaryBlue),
                                        ],
                                      ),
                                    ),
                                  ),
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
}

