import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/dynamic_island_toast.dart';
import '../l10n/app_localizations.dart';

class BildirimlerView extends StatefulWidget {
  const BildirimlerView({super.key});

  @override
  State<BildirimlerView> createState() => _BildirimlerViewState();
}

class _BildirimlerViewState extends State<BildirimlerView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _allNotifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    // Fetch notifications from the actual API endpoint
    final results = await ApiService.getBildirimler();
    
    _allNotifications = results.map((item) {
      return {
        'id': item['ID'] ?? item['id'] ?? 0,
        'baslik': item['BASLIK'] ?? item['baslik'] ?? 'Bildirim',
        'icerik': item['ICERIK'] ?? item['icerik'] ?? item['MESAJ'] ?? item['mesaj'] ?? '',
        'tarih': item['TARIH'] ?? item['tarih'] ?? '',
        'tur': item['TUR'] ?? item['tur'] ?? 'bilgi',
        'okundu': (item['OKUNDU'] ?? item['okundu'] ?? 0) == 1,
      };
    }).toList();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _markAsRead(int index) {
    setState(() {
      _allNotifications[index]['okundu'] = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _allNotifications) {
        n['okundu'] = true;
      }
    });
    AppNotification.showSuccess(context, context.tr('tum_bildirimler_okundu', 'Tüm bildirimler okundu olarak işaretlendi.'), title: context.tr('basarili', 'Başarılı'));
  }

  IconData _getIcon(String tur) {
    switch (tur) {
      case 'sistem':
        return Icons.settings_suggest_rounded;
      case 'uyari':
        return Icons.warning_amber_rounded;
      case 'bilgi':
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getColor(String tur) {
    switch (tur) {
      case 'sistem':
        return AppTheme.accentPurple;
      case 'uyari':
        return AppTheme.accentOrange;
      case 'bilgi':
      default:
        return AppTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = _allNotifications.where((n) => !n['okundu']).length;
    final systemCount = _allNotifications.where((n) => n['tur'] == 'sistem').length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(context.tr('bildirimler', 'Bildirimler'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.mark_email_read_rounded, color: AppTheme.accentGreen, size: 20),
                  tooltip: context.tr('tumunu_okundu_isaretle', 'Tümünü Okundu İşaretle'),
                  onPressed: _markAllAsRead,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: _loadNotifications,
                tooltip: context.tr('yenile', 'Yenile'),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip(
                    index: 0,
                    label: context.tr('tumu', 'Tümü'),
                    count: _allNotifications.length,
                    icon: Icons.inbox_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    index: 1,
                    label: context.tr('okunmamis', 'Okunmamış'),
                    count: unreadCount,
                    icon: Icons.mark_as_unread_rounded,
                    isDark: isDark,
                    activeColor: AppTheme.accentGreen,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    index: 2,
                    label: context.tr('sistem', 'Sistem'),
                    count: systemCount,
                    icon: Icons.settings_suggest_rounded,
                    isDark: isDark,
                    activeColor: AppTheme.accentPurple,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(_allNotifications, isDark),
          _buildNotificationList(_allNotifications.where((n) => !n['okundu']).toList(), isDark),
          _buildNotificationList(_allNotifications.where((n) => n['tur'] == 'sistem').toList(), isDark),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required int index,
    required String label,
    required int count,
    required IconData icon,
    required bool isDark,
    Color activeColor = AppTheme.primaryBlue,
  }) {
    final isSelected = _tabController.index == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _tabController.animateTo(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor
                  : (isDark ? AppTheme.darkSurface : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? activeColor
                    : (isDark ? AppTheme.darkCardBorder : Colors.grey.shade300),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey.shade200 : Colors.grey.shade800),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
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

  Widget _buildNotificationList(List<Map<String, dynamic>> list, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              context.tr('bildirim_bulunamadi', 'Herhangi bir bildirim bulunamadı.'),
              style: GoogleFonts.inter(fontSize: 15, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = list[index];
          final tur = item['tur'] as String;
          final color = _getColor(tur);
          final isUnread = !item['okundu'];

          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnread
                    ? color.withValues(alpha: 0.4)
                    : (isDark ? AppTheme.darkCardBorder : Colors.grey.shade200),
                width: isUnread ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  _markAsRead(_allNotifications.indexWhere((n) => n['id'] == item['id']));
                  _showNotificationDetail(item);
                },
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Accent category bar
                      Container(
                        width: 6,
                        color: color,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(_getIcon(tur), color: color, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item['baslik'].toString(),
                                      style: GoogleFonts.outfit(
                                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (isUnread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.accentGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['icerik'].toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                  fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item['tarih'].toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNotificationDetail(Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getColor(item['tur'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.all(16),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Icon(_getIcon(item['tur'].toString()), color: color, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item['baslik'].toString(),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['icerik'].toString(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${context.tr('tarih', 'Tarih')}: ${item['tarih']}',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr('kapat', 'Kapat'), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
