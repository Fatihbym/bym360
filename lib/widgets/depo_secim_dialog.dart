import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';

class DepoSecimDialog extends StatefulWidget {
  final List<GetDepo> depolar;
  final String title;

  const DepoSecimDialog({
    super.key,
    required this.depolar,
    required this.title,
  });

  static Future<GetDepo?> show(BuildContext context, List<GetDepo> depolar, {String title = 'Depo Seçimi'}) {
    return showModalBottomSheet<GetDepo>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DepoSecimDialog(depolar: depolar, title: title),
    );
  }

  @override
  State<DepoSecimDialog> createState() => _DepoSecimDialogState();
}

class _DepoSecimDialogState extends State<DepoSecimDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<GetDepo> _filteredDepolar = [];

  @override
  void initState() {
    super.initState();
    _filteredDepolar = List.from(widget.depolar);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    final q = val.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filteredDepolar = List.from(widget.depolar);
      } else {
        _filteredDepolar = widget.depolar.where((d) {
          return d.depoAdi.toLowerCase().contains(q) ||
              d.depoKodu.toLowerCase().contains(q) ||
              d.depoId.toString().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store_rounded, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(widget.title, widget.title),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      context.tr('Listeden seçim yapabilirsiniz', 'Listeden seçim yapabilirsiniz'),
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search input
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: context.tr('Depo adı veya kodu ara...', 'Depo adı veya kodu ara...'),
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Warehouse list
          Flexible(
            child: _filteredDepolar.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.store_mall_directory_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('Depo bulunamadı.', 'Depo bulunamadı.'),
                            style: GoogleFonts.inter(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filteredDepolar.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _filteredDepolar[index];
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
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                  child: const Icon(Icons.store_rounded, color: AppTheme.primaryBlue, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.displayTitle,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Kod: ${item.depoKodu.isNotEmpty ? item.depoKodu : item.depoId}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
