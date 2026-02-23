import 'dart:async';

import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AppToastType { info, success, warning, error }

final class AppToast {
  static OverlayEntry? _activeEntry;

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }

    _activeEntry?.remove();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _ToastOverlay(
          message: trimmed,
          type: type,
          duration: duration,
          onDismissed: () {
            if (_activeEntry == entry) {
              _activeEntry = null;
            }
            if (entry.mounted) {
              entry.remove();
            }
          },
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    _activeEntry?.remove();
    _activeEntry = null;
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 180),
    vsync: this,
  );

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      );

  Timer? _timer;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_isClosing) {
      return;
    }

    _isClosing = true;
    _timer?.cancel();

    if (mounted) {
      await _controller.reverse();
    }

    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final style = _ToastStyle.forType(widget.type);
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: style.textColor,
      fontWeight: FontWeight.w600,
      height: 1.3,
    );

    return Positioned.fill(
      child: IgnorePointer(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SlideTransition(
                position: _slide,
                child: FadeTransition(
                  opacity: _opacity,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Material(
                      color: Colors.transparent,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: style.backgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: style.borderColor),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x29000000),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                style.icon,
                                size: 20,
                                color: style.iconColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.message,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: textStyle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastStyle {
  const _ToastStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final IconData icon;

  factory _ToastStyle.forType(AppToastType type) {
    return switch (type) {
      AppToastType.info => const _ToastStyle(
        backgroundColor: Color(0xFFF4F8FF),
        borderColor: Color(0xFFB7CCFF),
        iconColor: Color(0xFF2853C8),
        textColor: Color(0xFF1A2F66),
        icon: Icons.info_outline_rounded,
      ),
      AppToastType.success => const _ToastStyle(
        backgroundColor: Color(0xFFEDF8F2),
        borderColor: Color(0xFF9ED3BE),
        iconColor: AppColors.accentGreen,
        textColor: Color(0xFF1B5B43),
        icon: Icons.check_circle_outline_rounded,
      ),
      AppToastType.warning => const _ToastStyle(
        backgroundColor: Color(0xFFFFF6E8),
        borderColor: Color(0xFFFFCF8A),
        iconColor: AppColors.primaryStrong,
        textColor: Color(0xFF7C4A1A),
        icon: Icons.warning_amber_rounded,
      ),
      AppToastType.error => const _ToastStyle(
        backgroundColor: Color(0xFFFDEDEE),
        borderColor: Color(0xFFF2B4BC),
        iconColor: AppColors.accentRed,
        textColor: Color(0xFF7A202E),
        icon: Icons.error_outline_rounded,
      ),
    };
  }
}
