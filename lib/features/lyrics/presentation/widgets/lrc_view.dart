import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/features/lyrics/domain/models/lyric_line.dart';
import 'package:orbitune/features/lyrics/presentation/providers/lyrics_provider.dart';

/// Real-time animated synchronized lyrics view with auto-scroll and tap-to-seek
class LrcView extends ConsumerStatefulWidget {
  final List<LyricLine> lines;
  final int activeIndex;
  final double fontSize;
  final Color? activeColor;
  final EdgeInsets? padding;

  const LrcView({
    super.key,
    required this.lines,
    required this.activeIndex,
    this.fontSize = 20.0,
    this.activeColor,
    this.padding,
  });

  @override
  ConsumerState<LrcView> createState() => _LrcViewState();
}

class _LrcViewState extends ConsumerState<LrcView> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _itemKeys = [];
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    _rebuildKeys();
  }

  @override
  void didUpdateWidget(covariant LrcView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lines.length != widget.lines.length) {
      _rebuildKeys();
    }
    if (oldWidget.activeIndex != widget.activeIndex && !_isUserScrolling) {
      _scrollToActiveLine();
    }
  }

  void _rebuildKeys() {
    _itemKeys.clear();
    for (int i = 0; i < widget.lines.length; i++) {
      _itemKeys.add(GlobalKey());
    }
  }

  void _scrollToActiveLine() {
    final state = ref.read(lyricsProvider);
    if (!state.isAutoScrollEnabled) return;

    if (widget.activeIndex < 0 || widget.activeIndex >= _itemKeys.length) return;
    final key = _itemKeys[widget.activeIndex];
    final context = key.currentContext;

    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.35, // Position active line slightly above center
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lyricsState = ref.watch(lyricsProvider);
    final activeColor = widget.activeColor ?? AppColors.accentGreen;

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification &&
                notification.dragDetails != null) {
              _isUserScrolling = true;
              ref.read(lyricsProvider.notifier).pauseAutoScroll();
            }
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            itemCount: widget.lines.length,
            itemBuilder: (context, index) {
              final line = widget.lines[index];
              final isActive = index == widget.activeIndex;
              final isPast = index < widget.activeIndex;

              return Padding(
                key: index < _itemKeys.length ? _itemKeys[index] : null,
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _isUserScrolling = false;
                    ref.read(lyricsProvider.notifier).seekToLine(index);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontSize: isActive ? widget.fontSize + 2 : widget.fontSize,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      fontFamily: AppTypography.fontFamilyBody,
                      color: isActive
                          ? Colors.white
                          : (isPast
                              ? AppColors.textMuted.withValues(alpha: 0.45)
                              : AppColors.textSecondary.withValues(alpha: 0.65)),
                      letterSpacing: -0.2,
                      height: 1.4,
                      shadows: isActive
                          ? [
                              Shadow(
                                color: activeColor.withValues(alpha: 0.6),
                                blurRadius: 18.0,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      line.text.isEmpty ? '♪' : line.text,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Floating "Resume Auto-Scroll" Button when paused
        if (!lyricsState.isAutoScrollEnabled)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ExpressiveCard(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _isUserScrolling = false;
                  ref.read(lyricsProvider.notifier).resumeAutoScroll();
                  _scrollToActiveLine();
                },
                borderRadius: AppConstants.roundedLarge,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceElevated.withValues(alpha: 0.9),
                    borderRadius: AppConstants.roundedLarge,
                    border: Border.all(
                      color: activeColor.withValues(alpha: 0.5),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 12.0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.arrowDownCircle,
                        size: 16,
                        color: activeColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Resume Auto-Scroll',
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
