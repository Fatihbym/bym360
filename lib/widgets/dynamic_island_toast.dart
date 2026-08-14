import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum DynamicIslandType { success, error, warning, info, printing }

class DynamicIslandHandle {
  final void Function({String? title, String? message}) updateSuccess;
  final void Function({String? title, String? message}) updateError;
  final void Function({String? title, String? message}) updateInfo;
  final void Function(double progress, {String? status, String? message}) updateProgress;
  final void Function() dismiss;

  DynamicIslandHandle({
    required this.updateSuccess,
    required this.updateError,
    required this.updateInfo,
    required this.updateProgress,
    required this.dismiss,
  });
}

class AppNotification {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String message, {
    DynamicIslandType type = DynamicIslandType.info,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlayState = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _DynamicIslandToastWidget(
          message: message,
          title: title,
          type: type,
          duration: duration,
          onCreated: (_) {},
          onDismissed: () {
            if (_currentEntry == entry) {
              entry.remove();
              _currentEntry = null;
            }
          },
        );
      },
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  /// Yazdırma işlemi için canlı durum bildirim barı başlatır
  static DynamicIslandHandle showPrinting(
    BuildContext context, {
    String title = 'Yazıcıya Gönderiliyor...',
    String? docName,
    String? printerInfo,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlayState = Overlay.of(context, rootOverlay: true);
    final completer = Completer<_DynamicIslandToastWidgetState>();

    final subtitle = docName != null
        ? '$docName${printerInfo != null ? ' • $printerInfo' : ''}'
        : (printerInfo ?? 'Ağ / Bluetooth Yazıcı');

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _DynamicIslandToastWidget(
          message: subtitle,
          title: title,
          type: DynamicIslandType.printing,
          duration: null, // İşlem bitene kadar ekranda sabit kalır
          onCreated: (state) {
            if (!completer.isCompleted) completer.complete(state);
          },
          onDismissed: () {
            if (_currentEntry == entry) {
              entry.remove();
              _currentEntry = null;
            }
          },
        );
      },
    );

    _currentEntry = entry;
    overlayState.insert(entry);

    return DynamicIslandHandle(
      updateProgress: (double progress, {String? status, String? message}) async {
        final state = await completer.future;
        state.setProgress(progress, status: status, message: message);
      },
      updateSuccess: ({String? title, String? message}) async {
        final state = await completer.future;
        state.update(
          type: DynamicIslandType.success,
          title: title ?? 'Baskı Başarılı',
          message: message ?? 'Evrak yazıcıya iletildi',
          dismissAfter: const Duration(milliseconds: 2400),
        );
      },
      updateError: ({String? title, String? message}) async {
        final state = await completer.future;
        state.update(
          type: DynamicIslandType.error,
          title: title ?? 'Yazdırma Hatası',
          message: message ?? 'Yazıcıya ulaşılamadı',
          dismissAfter: const Duration(milliseconds: 3200),
        );
      },
      updateInfo: ({String? title, String? message}) async {
        final state = await completer.future;
        state.update(
          type: DynamicIslandType.info,
          title: title ?? 'Bilgi',
          message: message ?? '',
          dismissAfter: const Duration(milliseconds: 2200),
        );
      },
      dismiss: () {
        if (_currentEntry == entry) {
          entry.remove();
          _currentEntry = null;
        }
      },
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    String? subtitle,
  }) {
    show(context, subtitle ?? message, title: title, type: DynamicIslandType.success);
  }

  static void showError(
    BuildContext context,
    String message, {
    String? title,
    String? subtitle,
  }) {
    show(context, subtitle ?? message, title: title, type: DynamicIslandType.error);
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    String? subtitle,
  }) {
    show(context, subtitle ?? message, title: title, type: DynamicIslandType.warning);
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    String? subtitle,
  }) {
    show(context, subtitle ?? message, title: title, type: DynamicIslandType.info);
  }
}

// Global Alias for consistency
typedef DynamicIslandNotification = AppNotification;

class _DynamicIslandToastWidget extends StatefulWidget {
  final String message;
  final String? title;
  final DynamicIslandType type;
  final Duration? duration;
  final void Function(_DynamicIslandToastWidgetState) onCreated;
  final VoidCallback onDismissed;

  const _DynamicIslandToastWidget({
    required this.message,
    this.title,
    required this.type,
    this.duration,
    required this.onCreated,
    required this.onDismissed,
  });

  @override
  State<_DynamicIslandToastWidget> createState() => _DynamicIslandToastWidgetState();
}

class _DynamicIslandToastWidgetState extends State<_DynamicIslandToastWidget> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _rotateController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  late DynamicIslandType _type;
  late String _message;
  late String? _title;
  double _progress = 0.2;
  Timer? _dismissTimer;
  Timer? _autoProgressTimer;

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    _message = widget.message;
    _title = widget.title;

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _slideAnimation = Tween<double>(begin: -80.0, end: 0.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeIn),
    );

    _entryController.forward();
    widget.onCreated(this);

    if (_type == DynamicIslandType.printing) {
      _startAutoProgress();
    } else if (widget.duration != null) {
      _scheduleDismiss(widget.duration!);
    }
  }

  void _startAutoProgress() {
    _autoProgressTimer?.cancel();
    _autoProgressTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted || _type != DynamicIslandType.printing) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_progress < 0.90) {
          _progress += 0.04;
        }
      });
    });
  }

  void setProgress(double progress, {String? status, String? message}) {
    if (!mounted) return;
    setState(() {
      _progress = progress.clamp(0.0, 1.0);
      if (message != null) _message = message;
    });
  }

  void update({
    required DynamicIslandType type,
    required String title,
    required String message,
    Duration? dismissAfter,
  }) {
    if (!mounted) return;
    _autoProgressTimer?.cancel();
    setState(() {
      _type = type;
      _title = title;
      _message = message;
      if (type == DynamicIslandType.success) {
        _progress = 1.0;
      }
    });

    if (dismissAfter != null) {
      _scheduleDismiss(dismissAfter);
    }
  }

  void _scheduleDismiss(Duration delay) {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(delay, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    _autoProgressTimer?.cancel();
    await _entryController.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _autoProgressTimer?.cancel();
    _dismissTimer?.cancel();
    _entryController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (_type) {
      case DynamicIslandType.printing:
        return const Color(0xFF38BDF8); // Cyan Blue
      case DynamicIslandType.success:
        return const Color(0xFF10B981); // Yeşil
      case DynamicIslandType.error:
        return const Color(0xFFEF4444); // Kırmızı
      case DynamicIslandType.warning:
      case DynamicIslandType.info:
        return const Color(0xFFF59E0B); // Sarı / Amber
    }
  }

  IconData get _iconData {
    switch (_type) {
      case DynamicIslandType.printing:
        return Icons.print_rounded;
      case DynamicIslandType.success:
        return Icons.check_circle_rounded;
      case DynamicIslandType.error:
        return Icons.error_rounded;
      case DynamicIslandType.warning:
        return Icons.help_outline_rounded;
      case DynamicIslandType.info:
        return Icons.notifications_active_rounded;
    }
  }

  String get _defaultTitle {
    switch (_type) {
      case DynamicIslandType.printing:
        return 'Yazıcıya Gönderiliyor...';
      case DynamicIslandType.success:
        return 'Başarılı';
      case DynamicIslandType.error:
        return 'Hata / Uyarı';
      case DynamicIslandType.warning:
        return 'Bilgilendirme';
      case DynamicIslandType.info:
        return 'Bildirim';
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final color = _accentColor;
    final isPrinting = _type == DynamicIslandType.printing;

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: Listenable.merge([_entryController, _rotateController]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                child: GestureDetector(
                  onVerticalDragEnd: (details) {
                    if (!isPrinting && details.primaryVelocity != null && details.primaryVelocity! < 0) {
                      _dismiss();
                    }
                  },
                  onTap: () {
                    if (!isPrinting) {
                      _dismiss();
                    }
                  },
                  child: CustomPaint(
                    foregroundPainter: _AnimatedRotatingBorderPainter(
                      animation: _rotateController,
                      color: color,
                      borderRadius: 30.0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.95), // Obsidian Dark Glass
                        borderRadius: BorderRadius.circular(30), // Dynamic Island Pill Radius
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Dynamic Island Left Glow Badge
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: color.withValues(alpha: 0.5), width: 1.0),
                                ),
                                child: isPrinting
                                    ? SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor: AlwaysStoppedAnimation<Color>(color),
                                        ),
                                      )
                                    : Icon(_iconData, color: color, size: 22),
                              ),
                              const SizedBox(width: 12),
                              // Message Text
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _title ?? _defaultTitle,
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                              letterSpacing: 0.3,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isPrinting) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '%${(_progress * 100).toInt()}',
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _message,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.95),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Close / Slide up hint
                              if (!isPrinting)
                                Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  color: Colors.white.withValues(alpha: 0.4),
                                  size: 20,
                                ),
                            ],
                          ),
                          // Sadece yazdırma işlemi devam ederken ince progress bar
                          if (isPrinting) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 3,
                                backgroundColor: Colors.white.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// Ince (1.0px) ve etrafında dönen ışıklı kenarlık CustomPainter
// ============================================================
class _AnimatedRotatingBorderPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final double borderRadius;

  _AnimatedRotatingBorderPainter({
    required this.animation,
    required this.color,
    required this.borderRadius,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final rotationAngle = animation.value * 2 * math.pi;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 // Ince estetik çizgi
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.15),
          color.withValues(alpha: 0.95),
          color,
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.15),
        ],
        stops: const [0.0, 0.4, 0.5, 0.65, 1.0],
        transform: GradientRotation(rotationAngle),
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedRotatingBorderPainter oldDelegate) => true;
}
